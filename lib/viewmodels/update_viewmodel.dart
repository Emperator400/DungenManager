/// ViewModel für das Update-System
library;

import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../models/app_version.dart';
import '../services/update_service.dart';

class UpdateViewModel extends ChangeNotifier {
  final UpdateService _updateService;

  UpdateViewModel({UpdateService? updateService})
      : _updateService = updateService ?? UpdateService() {
    // Streams sofort abonnieren — kein separater init()-Aufruf nötig.
    _statusSubscription = _updateService.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });
    _progressSubscription = _updateService.progressStream.listen((progress) {
      _progress = progress;
      notifyListeners();
    });
  }

  // ── State ───────────────────────────────────────────────────────────────────

  UpdateStatus _status = UpdateStatus.idle;
  UpdateStatus get status => _status;

  double _progress = 0.0;
  double get progress => _progress;

  AppVersion? _availableUpdate;
  AppVersion? get availableUpdate => _availableUpdate;

  AppVersion get currentVersion => _updateService.currentVersion;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  String? get extractedPath => _updateService.extractedPath;

  String get downloadedMb =>
      '${(_updateService.downloadedBytes / 1048576).toStringAsFixed(1)} MB';

  String get totalMb => _updateService.totalBytes > 0
      ? '${(_updateService.totalBytes / 1048576).toStringAsFixed(1)} MB'
      : '...';

  bool get isTotalSizeKnown => _updateService.totalBytes > 0;

  StreamSubscription<UpdateStatus>? _statusSubscription;
  StreamSubscription<double>? _progressSubscription;

  bool get hasUpdateAvailable => _status == UpdateStatus.updateAvailable;
  bool get isChecking => _status == UpdateStatus.checking;
  bool get isDownloading => _status == UpdateStatus.downloading;
  bool get isExtracting => _status == UpdateStatus.extracting;
  bool get isReady => _status == UpdateStatus.ready;
  bool get hasError => _status == UpdateStatus.error;

  bool _isBackingUp = false;
  bool get isBackingUp => _isBackingUp;

  bool _userNotified = false;
  bool get userNotified => _userNotified;

  /// Ob die App auf Windows läuft (für UI-Unterscheidung im Dialog).
  bool get isWindows => Platform.isWindows;

  // ── init() — no-op für Rückwärtskompatibilität ────────────────────────────

  /// Kein Aufruf mehr nötig — Streams werden im Konstruktor gestartet.
  /// Bleibt als no-op erhalten damit bestehende Aufrufer nicht angepasst werden müssen.
  void init() {}

  // ── Rate Limiting ───────────────────────────────────────────────────────────

  /// Gibt true zurück wenn der letzte Check weniger als 1 Stunde zurückliegt.
  Future<bool> _shouldSkipCheck() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File(
        path.join(appDir.path, 'DungenManager', 'last_update_check.txt'),
      );
      if (!await file.exists()) return false;
      final lastCheck = DateTime.tryParse((await file.readAsString()).trim());
      if (lastCheck == null) return false;
      return DateTime.now().difference(lastCheck) < const Duration(hours: 1);
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveCheckTime() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final file = File(
        path.join(appDir.path, 'DungenManager', 'last_update_check.txt'),
      );
      await file.parent.create(recursive: true);
      await file.writeAsString(DateTime.now().toIso8601String());
    } catch (_) {}
  }

  // ── checkForUpdate ──────────────────────────────────────────────────────────

  /// Prüft auf Updates.
  ///
  /// [force]: ignoriert den 1-Stunden-Throttle (z.B. für manuellen Check).
  /// [includePrereleases]: bietet auch Pre-Releases als Update an.
  Future<bool> checkForUpdate({
    bool force = false,
    bool includePrereleases = false,
  }) async {
    if (_status == UpdateStatus.checking) return false;

    if (!force && await _shouldSkipCheck()) {
      debugPrint('ℹ️ Update-Check übersprungen (< 1 Stunde seit letztem Check)');
      return _availableUpdate != null;
    }

    _errorMessage = null;

    final result = await _updateService.checkForUpdate(
      includePrereleases: includePrereleases,
    );
    await _saveCheckTime();

    if (result.hasUpdate && result.latestVersion != null) {
      _availableUpdate = result.latestVersion;
      return true;
    } else if (result.errorMessage != null) {
      _errorMessage = result.errorMessage;
    }

    return false;
  }

  // ── Backup ──────────────────────────────────────────────────────────────────

  Future<bool> _backupOldData() async {
    try {
      _isBackingUp = true;
      notifyListeners();

      final documentsDir = await getApplicationDocumentsDirectory();
      final dmDir = path.join(documentsDir.path, 'DungenManager');

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('.', '_');
      final backupPath = path.join(dmDir, 'backups', 'backup_$timestamp');
      final backupDir = Directory(backupPath);

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      // Sichere Nutzdaten-Ordner
      for (final folder in ['saves', 'sounds', 'images']) {
        final sourceDir = Directory(path.join(dmDir, folder));
        if (!await sourceDir.exists()) continue;
        final targetDir = Directory(path.join(backupPath, folder));
        await targetDir.create(recursive: true);
        await for (final entity in sourceDir.list(recursive: true)) {
          if (entity is File) {
            final rel = path.relative(entity.path, from: sourceDir.path);
            final target = File(path.join(targetDir.path, rel));
            await target.parent.create(recursive: true);
            await entity.copy(target.path);
          }
        }
      }

      // Fallback: Nutzdateien aus dem Install-Verzeichnis sichern.
      // Platform.resolvedExecutable ist der Pfad zur laufenden .exe —
      // damit treffen wir immer das richtige Verzeichnis, unabhängig vom CWD.
      final installDir = Directory(File(Platform.resolvedExecutable).parent.path);
      final fallbackDir = Directory(path.join(backupPath, 'install_dir_data'));
      await for (final entity in installDir.list()) {
        if (entity is File) {
          final ext = path.extension(entity.path).toLowerCase();
          if (['.db', '.sqlite', '.json', '.png', '.jpg', '.jpeg', '.mp3', '.wav']
              .contains(ext)) {
            if (!await fallbackDir.exists()) {
              await fallbackDir.create(recursive: true);
            }
            await entity.copy(
              path.join(fallbackDir.path, path.basename(entity.path)),
            );
          }
        }
      }

      debugPrint('✅ Backup erstellt: $backupPath');
      return true;
    } catch (e) {
      debugPrint('⚠️ Backup-Fehler: $e');
      return false;
    } finally {
      _isBackingUp = false;
      notifyListeners();
    }
  }

  // ── Download / Install ──────────────────────────────────────────────────────

  Future<bool> downloadUpdate() async {
    if (_availableUpdate == null) {
      _errorMessage = 'Kein Update verfügbar';
      notifyListeners();
      return false;
    }

    await _backupOldData();

    final extractedPath = await _updateService.downloadUpdate(_availableUpdate!);

    if (extractedPath != null) {
      return true;
    } else {
      _errorMessage = _updateService.lastError;
      notifyListeners();
      return false;
    }
  }

  /// Bricht einen laufenden Download ab.
  void cancelDownload() {
    _updateService.cancelDownload();
  }

  Future<bool> installAndRestart() async {
    return _updateService.applyUpdateAndRestart();
  }

  Future<bool> openExtractedFolder() async {
    return _updateService.openExtractedFolder();
  }

  Future<bool> openReleasesPage() async {
    return _updateService.openReleasesPage();
  }

  void markUserNotified() {
    _userNotified = true;
  }

  Future<bool> retryDownload() async {
    _errorMessage = null;
    notifyListeners();
    return downloadUpdate();
  }

  void reset() {
    _updateService.reset();
    _status = UpdateStatus.idle;
    _progress = 0.0;
    _availableUpdate = null;
    _errorMessage = null;
    _userNotified = false;
    notifyListeners();
  }

  Future<void> cleanup() async {
    await _updateService.cleanup();
  }

  @override
  void dispose() {
    _statusSubscription?.cancel();
    _progressSubscription?.cancel();
    super.dispose();
  }
}
