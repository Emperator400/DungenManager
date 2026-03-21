// lib/viewmodels/campaign_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/campaign.dart';
import '../services/uuid_service.dart';
import '../services/session_service.dart';
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
  final SessionService? _sessionService;
  
  CampaignViewModel({
    CampaignModelRepository? campaignRepo,
    PlayerCharacterModelRepository? characterRepo,
    SessionService? sessionService,
  }) : _campaignRepo = campaignRepo,
       _characterRepo = characterRepo,
       _sessionService = sessionService {
    debugPrint('🏗️ [CampaignViewModel] Konstruktor aufgerufen');
    // Nicht mehr im Konstruktor initialisieren - das führt zu Problemen bei Hot Restart
    // _initializeCampaigns();
  }

  /// Initialisiert die Kampagnenliste
  Future<void> _initializeCampaigns() async {
    try {
      debugPrint('🔄 [CampaignViewModel] _initializeCampaigns() gestartet');
      _setLoading(true);
      _setError(null);
      
      if (_campaignRepo != null) {
        debugPrint('📊 [CampaignViewModel] Repository verfügbar, lade Kampagnen...');
        _campaigns = await _campaignRepo!.findAll();
        debugPrint('✅ [CampaignViewModel] ${_campaigns.length} Kampagnen geladen');
        
        // Invalidate cache
        _invalidateFilteredCache();
      } else {
        debugPrint('⚠️ [CampaignViewModel] CampaignModelRepository nicht verfügbar');
        _campaigns = [];
      }
      
      notifyListeners();
      
    } catch (e, stackTrace) {
      debugPrint('❌ [CampaignViewModel] Exception in _initializeCampaigns(): $e');
      debugPrint('❌ [CampaignViewModel] StackTrace: $stackTrace');
      _setError('Ausnahme beim Laden der Kampagnen: $e');
      
      // Setze eine leere Liste, damit die App nicht abstürzt
      _campaigns = [];
      _invalidateFilteredCache();
      notifyListeners();
    } finally {
      _setLoading(false);
      debugPrint('🏁 [CampaignViewModel] _initializeCampaigns() abgeschlossen');
    }
  }

  // State
  List<Campaign> _campaigns = [];
  List<Campaign> get campaigns => _campaigns;
  
  // Dynamische Statistiken für Kampagnen
  Map<String, Map<String, int>> _campaignStats = {};
  Map<String, Map<String, int>> get campaignStats => _campaignStats;
  
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
  
  // Cached filtered campaigns to prevent memory leaks
  List<Campaign>? _cachedFilteredCampaigns;
  bool _isCacheValid = false;
  
  List<Campaign> get filteredCampaigns {
    if (_isCacheValid && _cachedFilteredCampaigns != null) {
      return _cachedFilteredCampaigns!;
    }
    
    debugPrint('🔍 [CampaignViewModel] Berechne gefilterte Kampagnen (Cache-Miss)');
    
    final filtered = <Campaign>[];
    
    // Search filter
    if (_searchQuery.isEmpty) {
      filtered.addAll(_campaigns);
    } else {
      final query = _searchQuery.toLowerCase();
      for (final campaign in _campaigns) {
        if (campaign.title.toLowerCase().contains(query) ||
            campaign.description.toLowerCase().contains(query)) {
          filtered.add(campaign);
        }
      }
    }
    
    // Sorting
    if (filtered.length > 1) {
      filtered.sort((a, b) => _compareCampaigns(a, b));
    }
    
    _cachedFilteredCampaigns = filtered;
    _isCacheValid = true;
    
    return filtered;
  }
  
  void _invalidateFilteredCache() {
    _cachedFilteredCampaigns = null;
    _isCacheValid = false;
  }
  
  // Methods
  
  /// Loads all campaigns
  Future<void> loadCampaigns() async {
    debugPrint('🔄 [CampaignViewModel] loadCampaigns() aufgerufen');
    _setLoading(true);
    _setError(null);
    
    try {
      if (_campaignRepo != null) {
        debugPrint('📊 [CampaignViewModel] Rufe findAll() auf...');
        _campaigns = await _campaignRepo!.findAll();
        debugPrint('✅ [CampaignViewModel] ${_campaigns.length} Kampagnen geladen');
        
        // Lade Statistiken für alle Kampagnen
        await loadCampaignStats();
        
        _invalidateFilteredCache();
      } else {
        debugPrint('⚠️ [CampaignViewModel] CampaignModelRepository nicht verfügbar');
        throw Exception('CampaignModelRepository nicht verfügbar');
      }
      
      notifyListeners();
      debugPrint('🔔 [CampaignViewModel] notifyListeners() aufgerufen');
      
    } catch (e, stackTrace) {
      debugPrint('❌ [CampaignViewModel] Exception in loadCampaigns(): $e');
      debugPrint('❌ [CampaignViewModel] StackTrace: $stackTrace');
      _setError('Fehler beim Laden der Kampagnen: $e');
      
      // Setze eine leere Liste, damit die App nicht abstürzt
      _campaigns = [];
      _invalidateFilteredCache();
      notifyListeners();
    } finally {
      _setLoading(false);
      debugPrint('🏁 [CampaignViewModel] loadCampaigns() abgeschlossen');
    }
  }
  
  /// Lädt Statistiken für alle Kampagnen aus der Datenbank
  Future<void> loadCampaignStats() async {
    if (_campaignRepo == null) return;
    
    try {
      debugPrint('📊 [CampaignViewModel] Lade Kampagnen-Statistiken...');
      _campaignStats = await _campaignRepo!.loadAllCampaignStats();
      debugPrint('✅ [CampaignViewModel] Statistiken für ${_campaignStats.length} Kampagnen geladen');
    } catch (e) {
      debugPrint('❌ [CampaignViewModel] Fehler beim Laden der Statistiken: $e');
      _campaignStats = {};
    }
  }
  
  /// Holt die Statistiken für eine bestimmte Kampagne
  Map<String, int> getStatsForCampaign(String campaignId) {
    return _campaignStats[campaignId] ?? {'heroCount': 0, 'sessionCount': 0, 'questCount': 0};
  }
  
  Future<void> selectCampaign(Campaign campaign) async {
    _selectedCampaign = campaign;
    notifyListeners();
  }
  
  /// Creates a new campaign
  Future<void> createCampaign({
    required String title,
    required String description,
  }) async {
    debugPrint('🔄 [CampaignViewModel] createCampaign() aufgerufen: $title');
    _setLoading(true);
    _setError(null);
    
    try {
      final campaign = Campaign.create(
        title: title,
        description: description,
      );
      
      if (_campaignRepo != null) {
        final savedCampaign = await _campaignRepo!.create(campaign);
        debugPrint('✅ [CampaignViewModel] Kampagne gespeichert: ${savedCampaign.title}');
        _campaigns.insert(0, savedCampaign);
        _invalidateFilteredCache();
      } else {
        throw Exception('CampaignModelRepository nicht verfügbar');
      }
      
      notifyListeners();
      debugPrint('🔔 [CampaignViewModel] notifyListeners() nach createCampaign()');
      
    } catch (e) {
      debugPrint('❌ [CampaignViewModel] Exception in createCampaign(): $e');
      _setError('Fehler beim Erstellen der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Updates a campaign
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
        
        // Update selection as well
        if (_selectedCampaign?.id == campaign.id) {
          _selectedCampaign = updatedCampaign;
        }
        
        _invalidateFilteredCache();
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Aktualisieren der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Deletes a campaign
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
      
      // Reset selection if deleted campaign was selected
      if (_selectedCampaign?.id == campaign.id) {
        _selectedCampaign = _campaigns.isNotEmpty ? _campaigns.first : null;
      }
      
      _invalidateFilteredCache();
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Löschen der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  /// Duplicates a campaign
  Future<void> duplicateCampaign(Campaign campaign) async {
    _setLoading(true);
    _setError(null);
    
    try {
      // Create a copy of campaign with new UUID
      final duplicatedCampaign = campaign.copyWith(
        id: UuidService().generateId(),
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
      
      // Select duplicated campaign
      await selectCampaign(savedCampaign);
      
      _invalidateFilteredCache();
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
    _invalidateFilteredCache();
    notifyListeners();
  }
  
  void toggleSortOrder() {
    _ascendingOrder = !_ascendingOrder;
    _invalidateFilteredCache();
    notifyListeners();
  }
  
  void setSearchQuery(String query) {
    _searchQuery = query;
    _invalidateFilteredCache();
    notifyListeners();
  }
  
  void clearSearch() {
    _searchQuery = '';
    _invalidateFilteredCache();
    notifyListeners();
  }
  
  // Filter methods for enhanced filter chips
  void searchCampaigns(String query) {
    setSearchQuery(query);
  }
  
  void setSortAscending(bool ascending) {
    _ascendingOrder = ascending;
    _invalidateFilteredCache();
    notifyListeners();
  }
  
  bool get sortAscending => _ascendingOrder;
  
  void refresh() {
    loadCampaigns();
  }
  
  void clearError() {
    _setError(null);
  }
  
  /// Toggles favorite/archive status of a campaign
  Future<void> toggleFavorite(Campaign campaign) async {
    try {
      if (_campaignRepo != null) {
        // Campaign has no isActive field - we simulate it via title prefix
        final newStatus = !campaign.title.startsWith('[ARCHIVIERT] ');
        final updatedTitle = newStatus 
            ? campaign.title 
            : '[ARCHIVIERT] ${campaign.title.replaceFirst('[ARCHIVIERT] ', '')}';
        
        final updatedCampaign = await _campaignRepo!.update(
          campaign.copyWith(title: updatedTitle),
        );
        
        // Update local list
        final index = _campaigns.indexWhere((c) => c.id == campaign.id);
        if (index != -1) {
          _campaigns[index] = updatedCampaign;
          if (_selectedCampaign?.id == campaign.id) {
            _selectedCampaign = updatedCampaign;
          }
          
          _invalidateFilteredCache();
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
  
  /// Gets the number of heroes for a campaign
  Future<int> getHeroCount(String campaignId) async {
    try {
      if (_characterRepo != null) {
        final characters = await _characterRepo!.findByCampaign(campaignId);
        return characters.length;
      } else {
        debugPrint('⚠️ [CampaignViewModel] PlayerCharacterModelRepository nicht verfügbar');
        return 0;
      }
    } catch (e) {
      debugPrint('❌ [CampaignViewModel] Fehler beim Ermitteln der Hero-Count: $e');
      return 0;
    }
  }
  
  Future<int> getSessionCount(String campaignId) async {
    // Placeholder - Session Repository would be used here
    // TODO: Implement when SessionModelRepository is available
    return 0;
  }
  
  Future<int> getQuestCount(String campaignId) async {
    // Placeholder - Quest Repository would be used here
    // TODO: Implement when QuestModelRepository is available
    return 0;
  }
  
  Future<DateTime?> getLastActiveDate(String campaignId) async {
    // Placeholder - would return last session-activity
    // TODO: Implement when SessionModelRepository is available
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
        // Placeholder for Monster sorting
        // TODO: Implement when CreatureModelRepository is available
        result = 0;
        break;
      case CampaignSortOption.npcs:
        // Placeholder for NPC sorting
        // TODO: Implement when CreatureModelRepository is available
        result = 0;
        break;
      case CampaignSortOption.items:
        // Placeholder for Item sorting
        // TODO: Implement when ItemModelRepository is available
        result = 0;
        break;
      case CampaignSortOption.spells:
        // Placeholder for Spell sorting
        result = 0;
        break;
    }
    
    return _ascendingOrder ? result : -result;
  }
  
  @override
  void dispose() {
    debugPrint('🗑️ [CampaignViewModel] dispose() aufgerufen');
    super.dispose();
  }
}