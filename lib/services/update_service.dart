/// Update Service für automatische Updates von GitHub Releases
///
/// Unterstützt Windows und Linux mit automatischem Download und Entpacken.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/app_version.dart';

/// GitHub Repository Konfiguration
class GitHubConfig {
  static const String owner = 'Emperator400';
  static const String repo = 'DungenManager';
  static const String baseUrl = 'https://api.github.com';

  /// API URL für neuestes Release
  static String get latestReleaseUrl =>
      '$baseUrl/repos/$owner/$repo/releases/latest';
}

/// Status des Update-Prozesses
enum UpdateStatus {
  idle,
  checking,
  updateAvailable,
  noUpdate,
  downloading,
  extracting,
  ready,
  error,
}

/// Ergebnis eines Update-Checks
class UpdateCheckResult {
  final bool hasUpdate;
  final AppVersion? latestVersion;
  final AppVersion? currentVersion;
  final String? errorMessage;

  const UpdateCheckResult({
    required this.hasUpdate,
    this.latestVersion,
    this.currentVersion,
    this.errorMessage,
  });
}

/// Hauptservice für das Update-System
class UpdateService {
  static final UpdateService _instance = UpdateService._internal();
  factory UpdateService() => _instance;
  UpdateService._internal();

  String _currentVersionString = '0.0.0';
  bool _versionLoaded = false;

  final _statusController = StreamController<UpdateStatus>.broadcast();
  Stream<UpdateStatus> get statusStream => _statusController.stream;

  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  UpdateStatus _currentStatus = UpdateStatus.idle;
  UpdateStatus get currentStatus => _currentStatus;

  http.Client? _httpClient;
  String? _extractedPath;
  String? _lastError;

  int _downloadedBytes = 0;
  int _totalBytes = 0;
  int get downloadedBytes => _downloadedBytes;
  int get totalBytes => _totalBytes;

  // Stall-detection: snapshot of _downloadedBytes from last watchdog tick
  int _stallSnapshot = 0;
  Timer? _stallWatchdog;

  AppVersion get currentVersion => AppVersion(
        version: _currentVersionString,
        tagName: 'v$_currentVersionString',
        releaseNotes: '',
        downloadUrl: '',
        publishedAt: DateTime.now(),
      );

  Future<void> _ensureVersionLoaded() async {
    if (_versionLoaded) return;
    final info = await PackageInfo.fromPlatform();
    _currentVersionString = info.version;
    _versionLoaded = true;
  }

  void _setStatus(UpdateStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  void _setProgress(double progress) {
    _progressController.add(progress);
  }

  // ── Error messages ──────────────────────────────────────────────────────────

  String _friendlyError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout')) {
      return 'Verbindungs-Timeout — bitte Internetverbindung prüfen';
    }
    if (msg.contains('socketexception') || msg.contains('no address')) {
      return 'Keine Internetverbindung';
    }
    if (msg.contains('403')) {
      return 'GitHub API Rate-Limit erreicht — bitte später erneut versuchen';
    }
    if (msg.contains('404')) {
      return 'Release nicht gefunden';
    }
    if (msg.contains('http ')) {
      return 'Server-Fehler — bitte später erneut versuchen';
    }
    if (msg.contains('filesystemexception') || msg.contains('permission')) {
      return 'Dateizugriff verweigert — bitte App-Berechtigungen prüfen';
    }
    if (msg.contains('cancelled') || msg.contains('canceled')) {
      return 'Download abgebrochen';
    }
    return 'Unbekannter Fehler — bitte später erneut versuchen';
  }

  // ── Update-Check ────────────────────────────────────────────────────────────

  /// Prüft auf GitHub ob eine neue Version verfügbar ist.
  ///
  /// [includePrereleases]: wenn false (Standard), werden Pre-Releases ignoriert.
  Future<UpdateCheckResult> checkForUpdate({bool includePrereleases = false}) async {
    await _ensureVersionLoaded();
    _setStatus(UpdateStatus.checking);
    _lastError = null;

    try {
      final response = await http
          .get(
            Uri.parse(GitHubConfig.latestReleaseUrl),
            headers: {
              'Accept': 'application/vnd.github.v3+json',
              'User-Agent': 'DungenManager-Update-Check',
            },
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final latestVersion = _parseGitHubRelease(data);

      if (latestVersion == null) {
        throw Exception('Release-Informationen konnten nicht gelesen werden');
      }

      // Pre-Release-Filter
      if (!includePrereleases && latestVersion.isPrerelease) {
        _setStatus(UpdateStatus.noUpdate);
        return UpdateCheckResult(
          hasUpdate: false,
          latestVersion: latestVersion,
          currentVersion: currentVersion,
        );
      }

      final hasUpdate = currentVersion.isOlderThan(latestVersion);
      _setStatus(hasUpdate ? UpdateStatus.updateAvailable : UpdateStatus.noUpdate);

      return UpdateCheckResult(
        hasUpdate: hasUpdate,
        latestVersion: latestVersion,
        currentVersion: currentVersion,
      );
    } catch (e) {
      _lastError = _friendlyError(e);
      _setStatus(UpdateStatus.error);
      return UpdateCheckResult(hasUpdate: false, errorMessage: _lastError);
    }
  }

  AppVersion? _parseGitHubRelease(Map<String, dynamic> data) {
    try {
      final tagName = data['tag_name'] as String;
      final version = AppVersion.parseVersionFromTag(tagName);
      final body = data['body'] as String? ?? '';

      final assets = data['assets'] as List<dynamic>;
      String? downloadUrl;

      final platformSuffix = _getPlatformAssetSuffix();
      for (final asset in assets) {
        final name = (asset['name'] as String).toLowerCase();
        if (name.contains(platformSuffix)) {
          downloadUrl = asset['browser_download_url'] as String;
          break;
        }
      }

      if (downloadUrl == null) {
        debugPrint('⚠️ Kein passendes Asset für Plattform: $platformSuffix — versuche erstes ZIP');
        for (final asset in assets) {
          final name = (asset['name'] as String).toLowerCase();
          if (name.endsWith('.zip')) {
            downloadUrl = asset['browser_download_url'] as String;
            break;
          }
        }
      }

      return AppVersion(
        version: version,
        tagName: tagName,
        releaseNotes: body,
        downloadUrl: downloadUrl ?? '',
        publishedAt: DateTime.parse(data['published_at'] as String),
        isPrerelease: data['prerelease'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('❌ Fehler beim Parsen des Releases: $e');
      return null;
    }
  }

  String _getPlatformAssetSuffix() {
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    if (Platform.isMacOS) return 'macos';
    return 'unknown';
  }

  // ── Download ────────────────────────────────────────────────────────────────

  /// Lädt das Update herunter.
  ///
  /// Ein Watchdog-Timer bricht den Download ab wenn 45 Sekunden lang kein
  /// Fortschritt messbar ist (z.B. bei getrennter Verbindung).
  Future<String?> downloadUpdate(AppVersion version) async {
    if (version.downloadUrl.isEmpty) {
      _lastError = 'Keine Download-URL verfügbar';
      _setStatus(UpdateStatus.error);
      return null;
    }

    _setStatus(UpdateStatus.downloading);
    _setProgress(0.0);
    _downloadedBytes = 0;
    _totalBytes = 0;
    _stallSnapshot = 0;

    _httpClient?.close();
    _httpClient = http.Client();
    _startStallWatchdog();

    IOSink? sink;
    File? zipFile;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final updateDir = Directory(p.join(appDir.path, 'DungenManager', 'updates'));
      if (!await updateDir.exists()) {
        await updateDir.create(recursive: true);
      }

      final fileName = 'dungen_manager_${version.tagName}.zip';
      final filePath = p.join(updateDir.path, fileName);
      zipFile = File(filePath);

      final request = http.Request('GET', Uri.parse(version.downloadUrl));
      final response = await _httpClient!.send(request).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Verbindungs-Timeout'),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      _totalBytes = response.contentLength ?? 0;
      sink = zipFile.openWrite();

      await for (final chunk in response.stream) {
        sink.add(chunk);
        _downloadedBytes += chunk.length;
        if (_totalBytes > 0) {
          _setProgress(_downloadedBytes / _totalBytes);
        }
      }

      await sink.close();
      sink = null;
      _cancelStallWatchdog();

      _setStatus(UpdateStatus.extracting);
      _setProgress(0.0);

      final extractedPath = await _extractUpdate(zipFile);

      // ZIP nach erfolgreichem Entpacken löschen
      if (extractedPath != null) {
        try {
          await zipFile.delete();
        } catch (e) {
          debugPrint('⚠️ ZIP konnte nicht gelöscht werden: $e');
        }
        _extractedPath = extractedPath;
        _setStatus(UpdateStatus.ready);
        return extractedPath;
      }

      return null;
    } catch (e) {
      await sink?.close();
      _cancelStallWatchdog();
      // Unvollständige ZIP löschen
      try {
        if (zipFile != null && await zipFile.exists()) await zipFile.delete();
      } catch (_) {}
      _lastError = _friendlyError(e);
      _setStatus(UpdateStatus.error);
      return null;
    } finally {
      _httpClient?.close();
      _httpClient = null;
    }
  }

  void _startStallWatchdog() {
    _stallWatchdog?.cancel();
    _stallSnapshot = _downloadedBytes;
    _stallWatchdog = Timer.periodic(const Duration(seconds: 45), (t) {
      if (_currentStatus != UpdateStatus.downloading) {
        t.cancel();
        return;
      }
      if (_downloadedBytes == _stallSnapshot) {
        debugPrint('⚠️ Download-Stall erkannt — breche ab');
        t.cancel();
        // Schließt den HTTP-Client → stream wirft eine Exception
        _httpClient?.close();
      } else {
        _stallSnapshot = _downloadedBytes;
      }
    });
  }

  void _cancelStallWatchdog() {
    _stallWatchdog?.cancel();
    _stallWatchdog = null;
  }

  /// Bricht einen laufenden Download sofort ab.
  void cancelDownload() {
    _cancelStallWatchdog();
    _httpClient?.close();
    _httpClient = null;
    _setStatus(UpdateStatus.idle);
    _setProgress(0.0);
    _downloadedBytes = 0;
    _totalBytes = 0;
  }

  // ── Extraktion ──────────────────────────────────────────────────────────────

  /// Entpackt das heruntergeladene ZIP-Archiv (streaming, ohne RAM-Spike).
  Future<String?> _extractUpdate(File zipFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final extractDir = Directory(
        p.join(appDir.path, 'DungenManager', 'updates', 'extracted'),
      );

      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // InputFileStream liest das ZIP vom Disk in Chunks — kein vollständiges
      // Einlesen in den Heap wie bei readAsBytes().
      final inputStream = InputFileStream(zipFile.path);
      final archive = ZipDecoder().decodeBuffer(inputStream);

      var extracted = 0;
      final total = archive.length;

      for (final file in archive) {
        final filePath = p.join(extractDir.path, file.name);
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }
        extracted++;
        _setProgress(extracted / total);
      }

      await inputStream.close();
      debugPrint('✅ Update entpackt nach: ${extractDir.path}');
      return extractDir.path;
    } catch (e) {
      debugPrint('❌ Fehler beim Entpacken: $e');
      _lastError = _friendlyError(e);
      _setStatus(UpdateStatus.error);
      return null;
    }
  }

  // ── Installation ────────────────────────────────────────────────────────────

  /// Installiert das Update und startet die App neu (nur Windows).
  ///
  /// Erstellt ein PowerShell-Skript das nach dem App-Exit die Dateien kopiert
  /// und die App neu startet.
  Future<bool> applyUpdateAndRestart() async {
    if (_extractedPath == null) {
      _lastError = 'Kein entpacktes Update gefunden';
      _setStatus(UpdateStatus.error);
      return false;
    }

    if (!Platform.isWindows) {
      _lastError = 'Automatische Installation wird nur auf Windows unterstützt';
      _setStatus(UpdateStatus.error);
      return false;
    }

    try {
      final exePath = Platform.resolvedExecutable;
      final installDir = File(exePath).parent.path;
      final exeName = p.basename(exePath);
      final extractedPath = _extractedPath!;

      final tempDir = await getTemporaryDirectory();
      final scriptPath = p.join(tempDir.path, 'dungenmanager_update.ps1');

      // Single-Quotes escapen (PowerShell: '' = literales ')
      final sqSource = "'${extractedPath.replaceAll("'", "''")}'";
      final sqTarget = "'${installDir.replaceAll("'", "''")}'";
      final sqExe = "'${exeName.replaceAll("'", "''")}'";

      final script = r'''
$logFile = "$env:TEMP\dungenmanager_update_log.txt"
try {
  Start-Sleep -Seconds 5

  $sourceDir = ''' +
          sqSource +
          r'''
  $targetDir = ''' +
          sqTarget +
          r'''
  $exeName   = ''' +
          sqExe +
          r'''

  $topFiles = Get-ChildItem -Path "$sourceDir" -File -ErrorAction SilentlyContinue
  $subDirs  = Get-ChildItem -Path "$sourceDir" -Directory -ErrorAction SilentlyContinue
  if ($subDirs.Count -eq 1 -and $topFiles.Count -eq 0) {
    $sourceDir = $subDirs[0].FullName
  }

  Copy-Item -Path "$sourceDir\*" -Destination "$targetDir" -Recurse -Force
  Start-Process -FilePath "$targetDir\$exeName"
} catch {
  $_ | Out-File -FilePath $logFile -Encoding UTF8 -Append
} finally {
  Remove-Item -Path $MyInvocation.MyCommand.Path -Force -ErrorAction SilentlyContinue
}
''';

      await File(scriptPath).writeAsString(script);

      await Process.start(
        'powershell.exe',
        [
          '-ExecutionPolicy', 'Bypass',
          '-NonInteractive',
          '-WindowStyle', 'Hidden',
          '-File', scriptPath,
        ],
        mode: ProcessStartMode.detached,
      );

      exit(0);
    } catch (e) {
      _lastError = 'Fehler beim Installieren: ${_friendlyError(e)}';
      _setStatus(UpdateStatus.error);
      debugPrint('❌ Fehler beim Anwenden des Updates: $e');
      return false;
    }
  }

  // ── Hilfsmethoden ───────────────────────────────────────────────────────────

  Future<bool> openExtractedFolder() async {
    if (_extractedPath == null) return false;
    try {
      final uri = Uri.file(_extractedPath!);
      if (await canLaunchUrl(uri)) return await launchUrl(uri);
      return false;
    } catch (e) {
      debugPrint('❌ Fehler beim Öffnen des Ordners: $e');
      return false;
    }
  }

  Future<bool> openReleasesPage() async {
    const url = 'https://github.com/${GitHubConfig.owner}/${GitHubConfig.repo}/releases';
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint('❌ Fehler beim Öffnen der Releases-Seite: $e');
      return false;
    }
  }

  String? get lastError => _lastError;
  String? get extractedPath => _extractedPath;

  void reset() {
    _cancelStallWatchdog();
    _setStatus(UpdateStatus.idle);
    _setProgress(0.0);
    _lastError = null;
  }

  Future<void> cleanup() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final updateDir = Directory(p.join(appDir.path, 'DungenManager', 'updates'));
      if (await updateDir.exists()) {
        await updateDir.delete(recursive: true);
        debugPrint('🗑️ Update-Dateien bereinigt');
      }
    } catch (e) {
      debugPrint('⚠️ Fehler beim Bereinigen: $e');
    }
  }

  void dispose() {
    _cancelStallWatchdog();
    _statusController.close();
    _progressController.close();
  }
}
