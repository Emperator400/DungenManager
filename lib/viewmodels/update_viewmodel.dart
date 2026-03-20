/// ViewModel für das Update-System
/// 
/// Verwaltet den State für Update-Checks und Downloads.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_version.dart';
import '../services/update_service.dart';

/// ViewModel für Update-Funktionalität
class UpdateViewModel extends ChangeNotifier {
  final UpdateService _updateService;

  UpdateViewModel({UpdateService? updateService})
      : _updateService = updateService ?? UpdateService();

  /// Aktueller Update-Status
  UpdateStatus _status = UpdateStatus.idle;
  UpdateStatus get status => _status;

  /// Download-Fortschritt (0.0 - 1.0)
  double _progress = 0.0;
  double get progress => _progress;

  /// Verfügbare Update-Version
  AppVersion? _availableUpdate;
  AppVersion? get availableUpdate => _availableUpdate;

  /// Aktuelle Version
  AppVersion get currentVersion => _updateService.currentVersion;

  /// Letzte Fehlermeldung
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  /// Pfad zu den extrahierten Dateien
  String? get extractedPath => _updateService.extractedPath;

  /// Stream Subscriptions
  StreamSubscription<UpdateStatus>? _statusSubscription;
  StreamSubscription<double>? _progressSubscription;

  /// Ob ein Update verfügbar ist
  bool get hasUpdateAvailable => _status == UpdateStatus.updateAvailable;

  /// Ob gerade geprüft wird
  bool get isChecking => _status == UpdateStatus.checking;

  /// Ob gerade heruntergeladen wird
  bool get isDownloading => _status == UpdateStatus.downloading;

  /// Ob gerade entpackt wird
  bool get isExtracting => _status == UpdateStatus.extracting;

  /// Ob das Update bereit ist
  bool get isReady => _status == UpdateStatus.ready;

  /// Ob ein Fehler aufgetreten ist
  bool get hasError => _status == UpdateStatus.error;

  /// Ob der User bereits benachrichtigt wurde (für Auto-Check)
  bool _userNotified = false;
  bool get userNotified => _userNotified;

  /// Initialisiert das ViewModel und startet Listener
  void init() {
    _statusSubscription = _updateService.statusStream.listen((status) {
      _status = status;
      notifyListeners();
    });

    _progressSubscription = _updateService.progressStream.listen((progress) {
      _progress = progress;
      notifyListeners();
    });
  }

  /// Prüft auf Updates (automatisch beim Start)
  Future<bool> checkForUpdate({bool silent = false}) async {
    if (_status == UpdateStatus.checking) {
      return false;
    }

    _errorMessage = null;
    
    final result = await _updateService.checkForUpdate();

    if (result.hasUpdate && result.latestVersion != null) {
      _availableUpdate = result.latestVersion;
      return true;
    } else if (result.errorMessage != null) {
      _errorMessage = result.errorMessage;
    }

    return false;
  }

  /// Lädt das verfügbare Update herunter
  Future<bool> downloadUpdate() async {
    if (_availableUpdate == null) {
      _errorMessage = 'Kein Update verfügbar';
      notifyListeners();
      return false;
    }

    final path = await _updateService.downloadUpdate(_availableUpdate!);
    
    if (path != null) {
      return true;
    } else {
      _errorMessage = _updateService.lastError;
      notifyListeners();
      return false;
    }
  }

  /// Öffnet den Ordner mit dem entpackten Update
  Future<bool> openExtractedFolder() async {
    return await _updateService.openExtractedFolder();
  }

  /// Öffnet die GitHub Releases Seite
  Future<bool> openReleasesPage() async {
    return await _updateService.openReleasesPage();
  }

  /// Markiert dass der User benachrichtigt wurde
  void markUserNotified() {
    _userNotified = true;
  }

  /// Setzt den State zurück
  void reset() {
    _updateService.reset();
    _status = UpdateStatus.idle;
    _progress = 0.0;
    _availableUpdate = null;
    _errorMessage = null;
    _userNotified = false;
    notifyListeners();
  }

  /// Bereinigt temporäre Dateien
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