// lib/viewmodels/campaign_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/campaign.dart';
import '../services/uuid_service.dart';
import '../database/repositories/campaign_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';

enum CampaignViewMode {
  overview,
  heroes,
  sessions,
  quests,
}

enum CampaignSortOption {
  name,
  createdDate,
  lastActive,
  heroCount,
  sessionCount,
  questCount,
  alphabetical,
  monsters,
  npcs,
  items,
  spells,
}

class CampaignViewModel extends ChangeNotifier {
  final CampaignModelRepository? _campaignRepo;
  final PlayerCharacterModelRepository? _characterRepo;
  
  CampaignViewModel({
    CampaignModelRepository? campaignRepo,
    PlayerCharacterModelRepository? characterRepo,
  }) : _campaignRepo = campaignRepo,
       _characterRepo = characterRepo {
    // Automatisch Kampagnen beim Erstellen laden
    _initializeCampaigns();
  }

  /// Initialisiert die Kampagnenliste
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<void> _initializeCampaigns() async {
    try {
      _setLoading(true);
      _setError(null);
      
      debugPrint('CampaignViewModel: _initializeCampaigns() - Loading campaigns');
      
      if (_campaignRepo != null) {
        _campaigns = await _campaignRepo!.findAll();
      } else {
        debugPrint('CampaignViewModel: CampaignModelRepository nicht verfügbar');
        _campaigns = [];
      }
      
      debugPrint('CampaignViewModel: _initializeCampaigns() - Result: ${_campaigns.length} campaigns');
      debugPrint('CampaignViewModel: _initializeCampaigns() - Loaded ${_campaigns.length} campaigns');
      notifyListeners();
      
    } catch (e) {
      debugPrint('CampaignViewModel: _initializeCampaigns() - Exception: $e');
      _setError('Ausnahme beim Laden der Kampagnen: $e');
    } finally {
      _setLoading(false);
    }
  }

  // State
  List<Campaign> _campaigns = [];
  List<Campaign> get campaigns => List.unmodifiable(_campaigns);
  
  Campaign? _selectedCampaign;
  Campaign? get selectedCampaign => _selectedCampaign;
  
  CampaignViewMode _viewMode = CampaignViewMode.overview;
  CampaignViewMode get viewMode => _viewMode;
  
  CampaignSortOption _sortOption = CampaignSortOption.name;
  CampaignSortOption get sortOption => _sortOption;
  
  bool _ascendingOrder = true;
  bool get ascendingOrder => _ascendingOrder;
  
  String _searchQuery = '';
  String get searchQuery => _searchQuery;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;
  
  bool get hasActiveFilters => _searchQuery.isNotEmpty;
  
  // Filtered campaigns
  List<Campaign> get filteredCampaigns {
    final filtered = _campaigns.where((campaign) {
      // Suchfilter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!(campaign.title.toLowerCase().contains(query) ||
               campaign.description.toLowerCase().contains(query))) {
          return false;
        }
      }
      return true;
    }).toList();
    
    // Sortierung anwenden
    filtered.sort((a, b) => _compareCampaigns(a, b));
    
    return filtered;
  }
  
  // Methods
  
  /// Lädt alle Kampagnen
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<void> loadCampaigns() async {
    debugPrint('CampaignViewModel: loadCampaigns() called');
    _setLoading(true);
    _setError(null);
    
    try {
      debugPrint('CampaignViewModel: Calling findAll()');
      
      if (_campaignRepo != null) {
        _campaigns = await _campaignRepo!.findAll();
      } else {
        throw Exception('CampaignModelRepository nicht verfügbar');
      }
      
      debugPrint('CampaignViewModel: findAll() result - campaigns: ${_campaigns.length}');
      debugPrint('CampaignViewModel: Updated _campaigns with ${_campaigns.length} campaigns');
      
      notifyListeners();
      debugPrint('CampaignViewModel: notifyListeners() called');
      
    } catch (e) {
      debugPrint('CampaignViewModel: Exception in loadCampaigns() - $e');
      _setError('Fehler beim Laden der Kampagnen: $e');
    } finally {
      _setLoading(false);
      debugPrint('CampaignViewModel: loadCampaigns() completed, loading: $_isLoading');
    }
  }
  
  Future<void> selectCampaign(Campaign campaign) async {
    _selectedCampaign = campaign;
    notifyListeners();
  }
  
  /// Erstellt eine neue Kampagne
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<void> createCampaign({
    required String title,
    required String description,
  }) async {
    debugPrint('CampaignViewModel: createCampaign() called with title: $title');
    _setLoading(true);
    _setError(null);
    
    try {
      final campaign = Campaign.create(
        title: title,
        description: description,
      );
      
      debugPrint('CampaignViewModel: Calling create()');
      
      if (_campaignRepo != null) {
        final savedCampaign = await _campaignRepo!.create(campaign);
        debugPrint('CampaignViewModel: save() result - data: ${savedCampaign.title}');
        _campaigns.insert(0, savedCampaign);
      } else {
        throw Exception('CampaignModelRepository nicht verfügbar');
      }
      
      debugPrint('CampaignViewModel: Added campaign to list, total campaigns: ${_campaigns.length}');
      
      // Automatisch auswählen
      await selectCampaign(_campaigns.first);
      
      notifyListeners();
      debugPrint('CampaignViewModel: notifyListeners() called after create');
      
    } catch (e) {
      debugPrint('CampaignViewModel: Exception in createCampaign - $e');
      _setError('Fehler beim Erstellen der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Aktualisiert eine Kampagne
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<void> updateCampaign(Campaign campaign) async {
    _setLoading(true);
    _setError(null);
    
    try {
      Campaign updatedCampaign;
      
      if (_campaignRepo != null) {
        updatedCampaign = await _campaignRepo!.update(campaign);
      } else {
        throw Exception('CampaignModelRepository nicht verfügbar');
      }
      
      final index = _campaigns.indexWhere((c) => c.id == campaign.id);
      if (index != -1) {
        _campaigns[index] = updatedCampaign;
        
        // Aktualisiere auch die Auswahl
        if (_selectedCampaign?.id == campaign.id) {
          _selectedCampaign = updatedCampaign;
        }
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Aktualisieren der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Löscht eine Kampagne
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<void> deleteCampaign(Campaign campaign) async {
    _setLoading(true);
    _setError(null);
    
    try {
      if (_campaignRepo != null) {
        await _campaignRepo!.delete(campaign.id!);
      } else {
        throw Exception('CampaignModelRepository nicht verfügbar');
      }
      
      _campaigns.removeWhere((c) => c.id == campaign.id);
      
      // Auswahl zurücksetzen wenn gelöschte Kampagne ausgewählt war
      if (_selectedCampaign?.id == campaign.id) {
        _selectedCampaign = _campaigns.isNotEmpty ? _campaigns.first : null;
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Löschen der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Dupliziert eine Kampagne
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<void> duplicateCampaign(Campaign campaign) async {
    _setLoading(true);
    _setError(null);
    
    try {
      // Erstelle eine Kopie der Kampagne mit neuer UUID
      final duplicatedCampaign = campaign.copyWith(
        id: UuidService().generateId(), // Neue UUID explizit generieren
        title: '${campaign.title} (Kopie)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      Campaign savedCampaign;
      
      if (_campaignRepo != null) {
        savedCampaign = await _campaignRepo!.create(duplicatedCampaign);
      } else {
        throw Exception('CampaignModelRepository nicht verfügbar');
      }
      
      _campaigns.insert(0, savedCampaign);
      
      // Duplizierte Kampagne auswählen
      await selectCampaign(savedCampaign);
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Duplizieren der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  void setViewMode(CampaignViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }
  
  void setSortOption(CampaignSortOption option) {
    _sortOption = option;
    notifyListeners();
  }
  
  void toggleSortOrder() {
    _ascendingOrder = !_ascendingOrder;
    notifyListeners();
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }
  
  // Filter methods for enhanced filter chips
  void searchCampaigns(String query) {
    _searchQuery = query;
    notifyListeners();
  }
  
  void setSortAscending(bool ascending) {
    _ascendingOrder = ascending;
    notifyListeners();
  }
  
  bool get sortAscending => _ascendingOrder;
  
  void refresh() {
    loadCampaigns();
  }
  
  void clearError() {
    _setError(null);
  }
  
  /// Schaltet den Favoriten-/Archiv-Status einer Kampagne um
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<void> toggleFavorite(Campaign campaign) async {
    try {
      if (_campaignRepo != null) {
        // Campaign hat kein isActive Feld - wir simulieren es über title prefix
        final newStatus = !campaign.title.startsWith('[ARCHIVIERT] ');
        final updatedTitle = newStatus 
            ? campaign.title 
            : '[ARCHIVIERT] ${campaign.title.replaceFirst('[ARCHIVIERT] ', '')}';
        
        final updatedCampaign = await _campaignRepo!.update(
          campaign.copyWith(title: updatedTitle),
        );
        
        // Lokale Liste aktualisieren
        final index = _campaigns.indexWhere((c) => c.id == campaign.id);
        if (index != -1) {
          _campaigns[index] = updatedCampaign;
          if (_selectedCampaign?.id == campaign.id) {
            _selectedCampaign = updatedCampaign;
          }
        }
      } else {
        throw Exception('CampaignModelRepository nicht verfügbar');
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Umschalten des Favoriten-Status: $e');
    }
  }
  
  // Statistics helpers
  
  /// Holt die Anzahl der Helden für eine Kampagne
  /// 
  /// HINWEIS: Verwendet jetzt das neue PlayerCharacterModelRepository
  Future<int> getHeroCount(String campaignId) async {
    try {
      if (_characterRepo != null) {
        final characters = await _characterRepo!.findByCampaign(campaignId);
        return characters.length;
      } else {
        debugPrint('CampaignViewModel: PlayerCharacterModelRepository nicht verfügbar');
        return 0;
      }
    } catch (e) {
      debugPrint('CampaignViewModel: Fehler beim Ermitteln der Hero-Count: $e');
      return 0;
    }
  }
  
  Future<int> getSessionCount(String campaignId) async {
    // Placeholder - Session Repository würde hier verwendet
    // TODO: Implementieren wenn SessionModelRepository verfügbar ist
    return 0;
  }
  
  Future<int> getQuestCount(String campaignId) async {
    // Placeholder - Quest Repository würde hier verwendet
    // TODO: Implementieren wenn QuestModelRepository verfügbar ist
    return 0;
  }
  
  Future<DateTime?> getLastActiveDate(String campaignId) async {
    // Placeholder - würde letzte Session-Activity zurückgeben
    // TODO: Implementieren wenn SessionModelRepository verfügbar ist
    return null;
  }
  
  // Private helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }
  
  int _compareCampaigns(Campaign a, Campaign b) {
    int result;
    
    switch (_sortOption) {
      case CampaignSortOption.name:
        result = a.title.compareTo(b.title);
        break;
      case CampaignSortOption.createdDate:
        result = a.createdAt.compareTo(b.createdAt);
        break;
      case CampaignSortOption.lastActive:
        result = a.updatedAt.compareTo(b.updatedAt);
        break;
      case CampaignSortOption.heroCount:
        final aCount = a.playerCharacterIds.length;
        final bCount = b.playerCharacterIds.length;
        result = aCount.compareTo(bCount);
        break;
      case CampaignSortOption.sessionCount:
        final aSessionCount = a.sessionIds.length;
        final bSessionCount = b.sessionIds.length;
        result = aSessionCount.compareTo(bSessionCount);
        break;
      case CampaignSortOption.questCount:
        final aQuestCount = a.questIds.length;
        final bQuestCount = b.questIds.length;
        result = aQuestCount.compareTo(bQuestCount);
        break;
      case CampaignSortOption.alphabetical:
        result = a.title.compareTo(b.title);
        break;
      case CampaignSortOption.monsters:
        // Placeholder für Monster-Sortierung
        // TODO: Implementieren wenn CreatureModelRepository verfügbar ist
        result = 0;
        break;
      case CampaignSortOption.npcs:
        // Placeholder für NPC-Sortierung
        // TODO: Implementieren wenn CreatureModelRepository verfügbar ist
        result = 0;
        break;
      case CampaignSortOption.items:
        // Placeholder für Item-Sortierung
        // TODO: Implementieren wenn ItemModelRepository verfügbar ist
        result = 0;
        break;
      case CampaignSortOption.spells:
        // Placeholder für Spell-Sortierung
        result = 0;
        break;
    }
    
    return _ascendingOrder ? result : -result;
  }
  
  @override
  void dispose() {
    super.dispose();
  }
}
