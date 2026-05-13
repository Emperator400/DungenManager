/// Update Service für automatische Updates von GitHub Releases
/// 
/// Unterstützt Windows und Linux mit automatischem Download und Entpacken.
library;

import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
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
  
  /// API URL für alle Releases
  static String get allReleasesUrl => 
      '$baseUrl/repos/$owner/$repo/releases';
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

  /// Status-Controller für UI-Updates
  final _statusController = StreamController<UpdateStatus>.broadcast();
  Stream<UpdateStatus> get statusStream => _statusController.stream;
  
  /// Progress-Controller für Download-Fortschritt (0.0 - 1.0)
  final _progressController = StreamController<double>.broadcast();
  Stream<double> get progressStream => _progressController.stream;

  UpdateStatus _currentStatus = UpdateStatus.idle;
  UpdateStatus get currentStatus => _currentStatus;

  http.Client? _httpClient;
  String? _extractedPath;
  String? _lastError;

  // Download-Fortschritt in Bytes
  int _downloadedBytes = 0;
  int _totalBytes = 0;
  int get downloadedBytes => _downloadedBytes;
  int get totalBytes => _totalBytes;

  /// Gibt die aktuelle App-Version zurück (nach erstem checkForUpdate() verfügbar)
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

  /// Setzt den Status und benachrichtigt Listener
  void _setStatus(UpdateStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// Setzt den Fortschritt und benachrichtigt Listener
  void _setProgress(double progress) {
    _progressController.add(progress);
  }

  /// Prüft auf GitHub ob eine neue Version verfügbar ist
  Future<UpdateCheckResult> checkForUpdate() async {
    await _ensureVersionLoaded();
    _setStatus(UpdateStatus.checking);
    _lastError = null;

    try {
      final response = await http.get(
        Uri.parse(GitHubConfig.latestReleaseUrl),
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'DungenManager-Update-Check',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception('GitHub API Fehler: ${response.statusCode}');
      }

      final data = json.decode(response.body) as Map<String, dynamic>;
      final latestVersion = _parseGitHubRelease(data);

      if (latestVersion == null) {
        throw Exception('Konnte Release-Informationen nicht parsen');
      }

      final hasUpdate = currentVersion.isOlderThan(latestVersion);
      
      _setStatus(hasUpdate ? UpdateStatus.updateAvailable : UpdateStatus.noUpdate);
      
      return UpdateCheckResult(
        hasUpdate: hasUpdate,
        latestVersion: latestVersion,
        currentVersion: currentVersion,
      );
    } catch (e) {
      _lastError = e.toString();
      _setStatus(UpdateStatus.error);
      return UpdateCheckResult(
        hasUpdate: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Parst ein GitHub Release JSON in ein AppVersion Objekt
  AppVersion? _parseGitHubRelease(Map<String, dynamic> data) {
    try {
      final tagName = data['tag_name'] as String;
      final version = AppVersion.parseVersionFromTag(tagName);
      final body = data['body'] as String? ?? '';
      
      // Finde die passende Download-URL für die aktuelle Plattform
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
        debugPrint('⚠️ Kein passendes Asset für Plattform gefunden: $platformSuffix');
        // Fallback: Nimm das erste ZIP
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

  /// Gibt den Asset-Suffix für die aktuelle Plattform zurück
  String _getPlatformAssetSuffix() {
    if (Platform.isWindows) {
      return 'windows';
    } else if (Platform.isLinux) {
      return 'linux';
    } else if (Platform.isMacOS) {
      return 'macos';
    }
    return 'unknown';
  }

  /// Lädt das Update herunter
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

    // Alten Client abbrechen falls noch aktiv
    _httpClient?.close();
    _httpClient = http.Client();

    IOSink? sink;
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final updateDir = Directory(p.join(appDir.path, 'DungenManager', 'updates'));
      if (!await updateDir.exists()) {
        await updateDir.create(recursive: true);
      }

      final fileName = 'dungen_manager_${version.tagName}.zip';
      final filePath = p.join(updateDir.path, fileName);
      final file = File(filePath);

      final request = http.Request('GET', Uri.parse(version.downloadUrl));
      final response = await _httpClient!
          .send(request)
          .timeout(const Duration(seconds: 30), onTimeout: () {
        throw Exception('Verbindungs-Timeout — Server antwortet nicht');
      });

      if (response.statusCode != 200) {
        throw Exception('Download fehlgeschlagen: HTTP ${response.statusCode}');
      }

      _totalBytes = response.contentLength ?? 0;

      sink = file.openWrite();

      // await for propagiert Netzwerkfehler korrekt (listen().asFuture() tut das nicht)
      await for (final chunk in response.stream) {
        sink.add(chunk);
        _downloadedBytes += chunk.length;
        if (_totalBytes > 0) {
          _setProgress(_downloadedBytes / _totalBytes);
        }
      }

      await sink.close();
      sink = null;

      _setStatus(UpdateStatus.extracting);
      _setProgress(0.0);

      final extractedPath = await _extractUpdate(file);
      if (extractedPath != null) {
        _extractedPath = extractedPath;
        _setStatus(UpdateStatus.ready);
        return extractedPath;
      }

      return null;
    } catch (e) {
      await sink?.close();
      _lastError = e.toString();
      _setStatus(UpdateStatus.error);
      return null;
    } finally {
      _httpClient?.close();
      _httpClient = null;
    }
  }

  /// Entpackt das heruntergeladene ZIP-Archiv
  Future<String?> _extractUpdate(File zipFile) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final extractDir = Directory(p.join(
        appDir.path, 
        'DungenManager', 
        'updates', 
        'extracted'
      ));
      
      // Alte extrahierte Dateien löschen
      if (await extractDir.exists()) {
        await extractDir.delete(recursive: true);
      }
      await extractDir.create(recursive: true);

      // ZIP entpacken
      final bytes = await zipFile.readAsBytes();
      final archive = ZipDecoder().decodeBytes(bytes);

      var extractedFiles = 0;
      final totalFiles = archive.length;

      for (final file in archive) {
        final filePath = p.join(extractDir.path, file.name);
        
        if (file.isFile) {
          final outFile = File(filePath);
          await outFile.parent.create(recursive: true);
          await outFile.writeAsBytes(file.content as List<int>);
        } else {
          await Directory(filePath).create(recursive: true);
        }

        extractedFiles++;
        _setProgress(extractedFiles / totalFiles);
      }

      debugPrint('✅ Update entpackt nach: ${extractDir.path}');
      return extractDir.path;
    } catch (e) {
      debugPrint('❌ Fehler beim Entpacken: $e');
      _lastError = e.toString();
      _setStatus(UpdateStatus.error);
      return null;
    }
  }

  /// Installiert das Update und startet die App automatisch neu (nur Windows)
  ///
  /// Erstellt ein temporäres PowerShell-Skript, das nach dem App-Exit
  /// die neuen Dateien in das Installationsverzeichnis kopiert und die App neu startet.
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

      // Single-Quotes in Pfaden escapen (PowerShell: '' = literales ').
      // PS-Single-Quoted-Strings interpolieren keine Variablen/Sonderzeichen
      // → sicher für Pfade mit Leerzeichen, $, Backticks, etc.
      final sqSource = "'${extractedPath.replaceAll("'", "''")}'";
      final sqTarget = "'${installDir.replaceAll("'", "''")}'";
      final sqExe    = "'${exeName.replaceAll("'", "''")}'";

      // PowerShell-Skript: wartet auf App-Exit, kopiert Dateien, startet neu.
      // Fehler werden in eine Log-Datei geschrieben statt still ignoriert.
      final script = r'''
$logFile = "$env:TEMP\dungenmanager_update_log.txt"
try {
  Start-Sleep -Seconds 5

  $sourceDir = ''' + sqSource + r'''
  $targetDir = ''' + sqTarget + r'''
  $exeName   = ''' + sqExe + r'''

  # Nur in Unterordner wechseln wenn die oberste Ebene ausschließlich einen
  # Ordner enthält (ZIP-Wrapper-Struktur). Bei gemischtem Inhalt (Dateien + Ordner
  # auf oberster Ebene, z.B. Flutter-Build) bleibt sourceDir unverändert.
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

      // App beenden — das Skript übernimmt
      exit(0);
    } catch (e) {
      _lastError = 'Fehler beim Installieren: $e';
      _setStatus(UpdateStatus.error);
      debugPrint('❌ Fehler beim Anwenden des Updates: $e');
      return false;
    }
  }

  /// Öffnet das extrahierte Verzeichnis im Dateimanager
  Future<bool> openExtractedFolder() async {
    if (_extractedPath == null) {
      return false;
    }

    try {
      final uri = Uri.file(_extractedPath!);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri);
      }
      return false;
    } catch (e) {
      debugPrint('❌ Fehler beim Öffnen des Ordners: $e');
      return false;
    }
  }

  /// Öffnet die GitHub Releases Seite im Browser
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

  /// Gibt den letzten Fehler zurück
  String? get lastError => _lastError;

  /// Gibt den Pfad der extrahierten Dateien zurück
  String? get extractedPath => _extractedPath;

  /// Setzt den Service zurück
  void reset() {
    _setStatus(UpdateStatus.idle);
    _setProgress(0.0);
    _lastError = null;
  }

  /// Bereinigt temporäre Update-Dateien
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

  /// Dispose
  void dispose() {
    _statusController.close();
    _progressController.close();
  }
}