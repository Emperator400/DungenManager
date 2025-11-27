import 'package:flutter/foundation.dart';
import '../models/campaign.dart';
import '../services/exceptions/service_exceptions.dart';
import '../services/campaign_service_locator.dart';

/// ViewModel für die Campaign-Bearbeitung mit Provider-Pattern
class EditCampaignViewModel extends ChangeNotifier {
  // State Management
  Campaign? _campaign;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasUnsavedChanges = false;

  // Getter
  Campaign? get campaign => _campaign;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  bool get isEditing => _campaign != null;
  bool get canSave => _campaign != null && _hasValidCampaign();

  /// Initialisiert das ViewModel mit einer Campaign oder erstellt eine neue
  Future<void> initialize(Campaign? campaign) async {
    try {
      _setLoading(true);
      _clearError();
      
      if (campaign != null) {
        _campaign = campaign;
      } else {
        _campaign = Campaign.create(
          title: '',
          description: '',
        );
      }
      
      _resetUnsavedChanges();
      notifyListeners();
    } catch (e) {
      _setError('Initialisierung fehlgeschlagen: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Speichert die aktuelle Campaign
  Future<bool> saveCampaign() async {
    if (_campaign == null || !_hasValidCampaign()) {
      _setError('Ungültige Campaign-Daten');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      
      final campaignService = CampaignServiceLocator.campaignService;
      
      if (_campaign!.id == null || _campaign!.id!.isEmpty) {
        // Neue Kampagne erstellen
        final result = await campaignService.createCampaign(_campaign!);
        if (result.isSuccess && result.data != null) {
          _campaign = result.data;
          _resetUnsavedChanges();
          return true;
        } else {
          _setError(result.userMessage ?? 'Fehler beim Erstellen der Kampagne');
          return false;
        }
      } else {
        // Bestehende Kampagne aktualisieren
        final result = await campaignService.updateCampaign(_campaign!);
        if (result.isSuccess && result.data != null) {
          _campaign = result.data;
          _resetUnsavedChanges();
          return true;
        } else {
          _setError(result.userMessage ?? 'Fehler beim Aktualisieren der Kampagne');
          return false;
        }
      }
    } catch (e) {
      if (e is ServiceException) {
        _setError(e.message);
      } else {
        _setError('Speichern fehlgeschlagen: ${e.toString()}');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Löscht die aktuelle Campaign
  Future<bool> deleteCampaign() async {
    if (_campaign == null) {
      _setError('Keine Campaign zum Löschen vorhanden');
      return false;
    }

    try {
      _setLoading(true);
      _clearError();
      
      final campaignService = CampaignServiceLocator.campaignService;
      final result = await campaignService.deleteCampaign(_campaign!.id!);
      
      if (result.isSuccess) {
        return true;
      } else {
        _setError(result.userMessage ?? 'Fehler beim Löschen der Kampagne');
        return false;
      }
    } catch (e) {
      if (e is ServiceException) {
        _setError(e.message);
      } else {
        _setError('Löschen fehlgeschlagen: ${e.toString()}');
      }
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Dupliziert die aktuelle Campaign
  Future<void> duplicateCampaign() async {
    if (_campaign == null) return;

    try {
      final duplicatedCampaign = Campaign.create(
        title: '${_campaign!.title} (Kopie)',
        description: _campaign!.description,
        dungeonMasterId: _campaign!.dungeonMasterId,
      );
      
      _campaign = duplicatedCampaign;
      _markAsUnsaved();
      notifyListeners();
    } catch (e) {
      _setError('Duplizieren fehlgeschlagen: ${e.toString()}');
    }
  }

  // Update-Methoden für einzelne Felder
  void updateTitle(String title) {
    if (_campaign?.title != title) {
      _campaign = _campaign?.copyWith(title: title, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateDescription(String description) {
    if (_campaign?.description != description) {
      _campaign = _campaign?.copyWith(description: description, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateDungeonMasterId(String? dungeonMasterId) {
    if (_campaign?.dungeonMasterId != dungeonMasterId) {
      _campaign = _campaign?.copyWith(dungeonMasterId: dungeonMasterId, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateStatus(CampaignStatus status) {
    if (_campaign?.status != status) {
      _campaign = _campaign?.copyWith(status: status, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updateType(CampaignType type) {
    if (_campaign?.type != type) {
      _campaign = _campaign?.copyWith(type: type, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void updatePlayerCharacterIds(List<String> playerCharacterIds) {
    if (_campaign?.playerCharacterIds != playerCharacterIds) {
      _campaign = _campaign?.copyWith(playerCharacterIds: playerCharacterIds, updatedAt: DateTime.now());
      _markAsUnsaved();
      notifyListeners();
    }
  }

  void addPlayer(String playerId) {
    if (_campaign == null) return;
    
    final currentPlayers = List<String>.from(_campaign!.playerCharacterIds);
    if (!currentPlayers.contains(playerId)) {
      currentPlayers.add(playerId);
      updatePlayerCharacterIds(currentPlayers);
    }
  }

  void removePlayer(String playerId) {
    if (_campaign == null) return;
    
    final currentPlayers = List<String>.from(_campaign!.playerCharacterIds);
    currentPlayers.remove(playerId);
    updatePlayerCharacterIds(currentPlayers);
  }

  /// Setzt die Änderungen zurück
  void resetChanges() async {
    if (_campaign != null && isEditing) {
      // In einer echten Implementierung würden wir die Original-Daten neu laden
      _clearError();
      _resetUnsavedChanges();
      notifyListeners();
    }
  }

  /// Löscht die Fehlermeldung
  void clearError() {
    _clearError();
    notifyListeners();
  }

  // Private Helper-Methoden
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void _markAsUnsaved() {
    _hasUnsavedChanges = true;
  }

  void _resetUnsavedChanges() {
    _hasUnsavedChanges = false;
  }

  bool _hasValidCampaign() {
    if (_campaign == null) return false;
    
    // Grundlegende Validierung
    return _campaign!.title.trim().isNotEmpty && 
           _campaign!.description.trim().isNotEmpty;
  }

  /// Simuliert eine Datenbankoperation
  Future<void> _simulateDatabaseOperation() async {
    // Simuliere Netzwerkverzögerung
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
