// lib/viewmodels/campaign_viewmodel.dart
import 'package:flutter/foundation.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';
import '../services/campaign_service_locator.dart';

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
  final CampaignService _campaignService;
  
  CampaignViewModel() : _campaignService = CampaignServiceLocator.campaignService {
    // Automatisch Kampagnen beim Erstellen laden
    _initializeCampaigns();
  }

  /// Initialisiert die Kampagnenliste
  Future<void> _initializeCampaigns() async {
    try {
      _setLoading(true);
      _setError(null);
      
      debugPrint('CampaignViewModel: _initializeCampaigns() - Loading campaigns');
      final result = await _campaignService.getAllCampaigns();
      debugPrint('CampaignViewModel: _initializeCampaigns() - Result: ${result.isSuccess}, campaigns: ${result.data?.length ?? 0}');
      
      if (result.isSuccess && result.data != null) {
        _campaigns = result.data!;
        debugPrint('CampaignViewModel: _initializeCampaigns() - Loaded ${_campaigns.length} campaigns');
        notifyListeners();
      } else {
        debugPrint('CampaignViewModel: _initializeCampaigns() - Error: ${result.userMessage}');
        _setError(result.userMessage ?? 'Unbekannter Fehler beim Laden der Kampagnen');
      }
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
  Future<void> loadCampaigns() async {
    debugPrint('CampaignViewModel: loadCampaigns() called');
    _setLoading(true);
    _setError(null);
    
    try {
      debugPrint('CampaignViewModel: Calling getAllCampaigns()');
      final result = await _campaignService.getAllCampaigns();
      debugPrint('CampaignViewModel: getAllCampaigns() result - success: ${result.isSuccess}, data count: ${result.data?.length ?? 0}');
      if (result.isSuccess && result.data != null) {
        _campaigns = result.data!;
        debugPrint('CampaignViewModel: Updated _campaigns with ${_campaigns.length} campaigns');
        notifyListeners();
        debugPrint('CampaignViewModel: notifyListeners() called');
      } else {
        debugPrint('CampaignViewModel: Error in result - ${result.userMessage}');
        _setError(result.userMessage);
      }
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
      
      debugPrint('CampaignViewModel: Calling createCampaign service');
      final result = await _campaignService.createCampaign(campaign);
      debugPrint('CampaignViewModel: createCampaign result - success: ${result.isSuccess}, data: ${result.data?.title}');
      if (result.isSuccess && result.data != null) {
        _campaigns.insert(0, result.data!);
        debugPrint('CampaignViewModel: Added campaign to list, total campaigns: ${_campaigns.length}');
        
        // Automatisch auswählen
        await selectCampaign(result.data!);
        
        notifyListeners();
        debugPrint('CampaignViewModel: notifyListeners() called after create');
      } else {
        debugPrint('CampaignViewModel: createCampaign failed - ${result.userMessage}');
        _setError(result.userMessage);
      }
    } catch (e) {
      debugPrint('CampaignViewModel: Exception in createCampaign - $e');
      _setError('Fehler beim Erstellen der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> updateCampaign(Campaign campaign) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final result = await _campaignService.updateCampaign(campaign);
      if (result.isSuccess && result.data != null) {
        final updatedCampaign = result.data!;
        
        final index = _campaigns.indexWhere((c) => c.id == campaign.id);
        if (index != -1) {
          _campaigns[index] = updatedCampaign;
          
          // Aktualisiere auch die Auswahl
          if (_selectedCampaign?.id == campaign.id) {
            _selectedCampaign = updatedCampaign;
          }
        }
        
        notifyListeners();
      } else {
        _setError(result.userMessage);
      }
    } catch (e) {
      _setError('Fehler beim Aktualisieren der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> deleteCampaign(Campaign campaign) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final result = await _campaignService.deleteCampaign(campaign.id!);
      if (result.isSuccess) {
        _campaigns.removeWhere((c) => c.id == campaign.id);
        
        // Auswahl zurücksetzen wenn gelöschte Kampagne ausgewählt war
        if (_selectedCampaign?.id == campaign.id) {
          _selectedCampaign = _campaigns.isNotEmpty ? _campaigns.first : null;
        }
        
        notifyListeners();
      } else {
        _setError(result.userMessage);
      }
    } catch (e) {
      _setError('Fehler beim Löschen der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }
  
  Future<void> duplicateCampaign(Campaign campaign) async {
    _setLoading(true);
    _setError(null);
    
    try {
      final result = await _campaignService.duplicateCampaign(campaign.id!);
      if (result.isSuccess && result.data != null) {
        _campaigns.insert(0, result.data!);
        
        // Duplizierte Kampagne auswählen
        await selectCampaign(result.data!);
        
        notifyListeners();
      } else {
        _setError(result.userMessage);
      }
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
  
  Future<void> toggleFavorite(Campaign campaign) async {
    try {
      // Toggle favorite status (placeholder implementation)
      // In einer echten Implementierung würde dies die Datenbank aktualisieren
      final index = _campaigns.indexWhere((c) => c.id == campaign.id);
      if (index != -1) {
        // Hier würde der Favoriten-Status umgeschaltet
        // Da das Campaign Model noch kein favorite flag hat, ist dies ein Placeholder
        notifyListeners();
      }
    } catch (e) {
      _setError('Fehler beim Umschalten des Favoriten-Status: $e');
    }
  }
  
  // Statistics helpers
  Future<int> getHeroCount(String campaignId) async {
    return await _campaignService.getHeroCount(campaignId);
  }
  
  Future<int> getSessionCount(String campaignId) async {
    return await _campaignService.getSessionCount(campaignId);
  }
  
  Future<int> getQuestCount(String campaignId) async {
    return await _campaignService.getQuestCount(campaignId);
  }
  
  Future<DateTime?> getLastActiveDate(String campaignId) async {
    return await _campaignService.getLastActiveDate(campaignId);
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
        // Placeholder - müsste im Campaign Model ergänzt werden
        result = 0;
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
        result = 0;
        break;
      case CampaignSortOption.npcs:
        // Placeholder für NPC-Sortierung
        result = 0;
        break;
      case CampaignSortOption.items:
        // Placeholder für Item-Sortierung
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
