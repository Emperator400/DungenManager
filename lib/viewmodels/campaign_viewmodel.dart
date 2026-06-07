import 'dart:async';

import 'package:flutter/foundation.dart';

import '../database/repositories/campaign_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../models/app_user.dart';
import '../models/campaign.dart';
import '../services/campaign_service.dart';
import '../services/campaign_sync_service.dart';
import '../services/campaign_template_export_import_service.dart';
import '../services/uuid_service.dart';

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
  CampaignViewModel({
    CampaignModelRepository? campaignRepo,
    PlayerCharacterModelRepository? characterRepo,
    CampaignService? campaignService,
    CampaignTemplateExportImportService? exportImportService,
  })  : _campaignRepo = campaignRepo,
        _characterRepo = characterRepo,
        _campaignService = campaignService ?? CampaignService(),
        _exportImportService =
            exportImportService ?? CampaignTemplateExportImportService() {
    debugPrint('[CampaignViewModel] Konstruktor aufgerufen');
  }

  final CampaignModelRepository? _campaignRepo;
  final PlayerCharacterModelRepository? _characterRepo;
  final CampaignService _campaignService;
  final CampaignTemplateExportImportService _exportImportService;

  List<Campaign> _campaigns = [];
  List<Campaign> get campaigns => _campaigns;

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

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  String? _syncError;
  String? get syncError => _syncError;

  DateTime? _lastSyncedAt;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  CampaignSyncService? _syncService;
  AppUser? _syncUser;
  final Set<String> _syncedIds = {};
  final Set<String> _pendingSyncIds = {};

  bool get hasActiveFilters => _searchQuery.isNotEmpty;

  bool isSynced(String campaignId) => _syncedIds.contains(campaignId);
  bool isPendingSync(String campaignId) => _pendingSyncIds.contains(campaignId);

  List<Campaign>? _cachedFilteredCampaigns;
  bool _isCacheValid = false;

  List<Campaign> get templates => _campaigns.where((c) => c.isTemplate).toList();
  List<Campaign> get activeCampaigns => _campaigns.where((c) => !c.isTemplate).toList();

  List<Campaign> get filteredCampaigns {
    if (_isCacheValid && _cachedFilteredCampaigns != null) {
      return _cachedFilteredCampaigns!;
    }

    debugPrint('🔍 [CampaignViewModel] Berechne gefilterte Kampagnen (Cache-Miss)');

    final source = activeCampaigns;
    final filtered = <Campaign>[];

    if (_searchQuery.isEmpty) {
      filtered.addAll(source);
    } else {
      final query = _searchQuery.toLowerCase();
      for (final campaign in source) {
        if (campaign.title.toLowerCase().contains(query) ||
            campaign.description.toLowerCase().contains(query)) {
          filtered.add(campaign);
        }
      }
    }

    if (filtered.length > 1) {
      filtered.sort(_compareCampaigns);
    }

    _cachedFilteredCampaigns = filtered;
    _isCacheValid = true;

    return filtered;
  }

  List<Campaign> get filteredTemplates {
    final source = templates;
    if (_searchQuery.isEmpty) {
      return source;
    }
    final query = _searchQuery.toLowerCase();
    return source
        .where((c) =>
            c.title.toLowerCase().contains(query) ||
            c.description.toLowerCase().contains(query))
        .toList();
  }

  void _invalidateFilteredCache() {
    _cachedFilteredCampaigns = null;
    _isCacheValid = false;
  }

  Map<String, int> getStatsForCampaign(String campaignId) =>
      _campaignStats[campaignId] ?? {'heroCount': 0, 'sessionCount': 0, 'questCount': 0};

  Future<void> loadCampaigns() async {
    debugPrint('🔄 [CampaignViewModel] loadCampaigns() aufgerufen');
    _setLoading(true);
    _setError(null);

    try {
      if (_campaignRepo != null) {
        debugPrint('📊 [CampaignViewModel] Rufe findAll() auf...');
        _campaigns = await _campaignRepo!.findAll();
        debugPrint('✅ [CampaignViewModel] ${_campaigns.length} Kampagnen geladen');

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

      _campaigns = [];
      _invalidateFilteredCache();
      notifyListeners();
    } finally {
      _setLoading(false);
      debugPrint('🏁 [CampaignViewModel] loadCampaigns() abgeschlossen');
    }
  }

  Future<void> loadCampaignStats() async {
    if (_campaignRepo == null) {
      return;
    }

    try {
      debugPrint('📊 [CampaignViewModel] Lade Kampagnen-Statistiken...');
      _campaignStats = await _campaignRepo!.loadAllCampaignStats();
      debugPrint(
          '✅ [CampaignViewModel] Statistiken für ${_campaignStats.length} Kampagnen geladen');
    } catch (e) {
      debugPrint('❌ [CampaignViewModel] Fehler beim Laden der Statistiken: $e');
      _campaignStats = {};
    }
  }

  Future<void> selectCampaign(Campaign campaign) async {
    _selectedCampaign = campaign;
    notifyListeners();
  }

  Future<void> createCampaign({
    required String title,
    required String description,
    String accentColor = '#7c3aed',
    String system = 'D&D 5e',
    CampaignStatus status = CampaignStatus.planning,
  }) async {
    debugPrint('🔄 [CampaignViewModel] createCampaign() aufgerufen: $title');
    _setLoading(true);
    _setError(null);

    try {
      final campaign = Campaign.create(
        title: title,
        description: description,
        accentColor: accentColor,
        system: system,
        status: status,
      );

      if (_campaignRepo != null) {
        final savedCampaign = await _campaignRepo!.create(campaign);
        debugPrint('✅ [CampaignViewModel] Kampagne gespeichert: ${savedCampaign.title}');
        _campaigns.insert(0, savedCampaign);
        _invalidateFilteredCache();
        notifyListeners();
        debugPrint('🔔 [CampaignViewModel] notifyListeners() nach createCampaign()');
        unawaited(_autoUpload(savedCampaign));
      } else {
        throw Exception('CampaignModelRepository nicht verfügbar');
      }
    } catch (e) {
      debugPrint('❌ [CampaignViewModel] Exception in createCampaign(): $e');
      _setError('Fehler beim Erstellen der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }

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

        if (_selectedCampaign?.id == campaign.id) {
          _selectedCampaign = updatedCampaign;
        }

        _invalidateFilteredCache();
      }

      notifyListeners();
      unawaited(_autoUpload(updatedCampaign));
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
      if (_campaignRepo != null) {
        await _campaignRepo!.delete(campaign.id);
      } else {
        throw Exception('CampaignModelRepository nicht verfügbar');
      }

      _campaigns.removeWhere((c) => c.id == campaign.id);

      if (_selectedCampaign?.id == campaign.id) {
        _selectedCampaign = _campaigns.isNotEmpty ? _campaigns.first : null;
      }

      _invalidateFilteredCache();
      notifyListeners();
      unawaited(_autoDelete(campaign.id));
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

      await selectCampaign(savedCampaign);

      _invalidateFilteredCache();
      notifyListeners();
      _autoUpload(savedCampaign);
    } catch (e) {
      _setError('Fehler beim Duplizieren der Kampagne: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> createTemplate({
    required String title,
    required String description,
    String accentColor = '#7c3aed',
    String system = 'D&D 5e',
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final template = Campaign.create(
        title: title,
        description: description,
        accentColor: accentColor,
        system: system,
      ).copyWith(isTemplate: true);

      if (_campaignRepo == null) {
        throw Exception('CampaignModelRepository nicht verfügbar');
      }
      final saved = await _campaignRepo!.create(template);
      _campaigns.insert(0, saved);
      _invalidateFilteredCache();
      notifyListeners();
    } catch (e) {
      _setError('Fehler beim Erstellen der Vorlage: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<Campaign?> createCopyFromTemplate(
    Campaign template, {
    required String title,
  }) async {
    _setLoading(true);
    _setError(null);
    try {
      final result = await _campaignService.createCopyFromTemplate(template, title: title);
      if (!result.isSuccess || result.data == null) {
        _setError(result.userMessage);
        return null;
      }
      final copy = result.data!;
      _campaigns.insert(0, copy);
      _invalidateFilteredCache();
      notifyListeners();
      return copy;
    } catch (e) {
      _setError('Fehler beim Kopieren der Vorlage: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  // Gibt den Pfad zurück wenn erfolgreich, null bei Abbruch oder Fehler.
  // Bei Fehler ist [error] gesetzt; bei Abbruch bleibt [error] null.
  Future<String?> exportTemplate(String campaignId) async {
    _setError(null);
    try {
      final result = await _exportImportService.exportTemplate(campaignId);
      if (!result.isSuccess) {
        _setError(result.userMessage);
        return null;
      }
      return result.data; // null = Abbrechen, non-null = Pfad
    } catch (e) {
      _setError('Export fehlgeschlagen: $e');
      return null;
    }
  }

  Future<Campaign?> importTemplate() async {
    _setLoading(true);
    _setError(null);
    try {
      final result = await _exportImportService.importTemplate();
      if (!result.isSuccess || result.data == null) {
        _setError(result.userMessage);
        return null;
      }
      final imported = result.data!;
      _campaigns.insert(0, imported);
      _invalidateFilteredCache();
      notifyListeners();
      return imported;
    } catch (e) {
      _setError('Import fehlgeschlagen: $e');
      return null;
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

  void searchCampaigns(String query) {
    setSearchQuery(query);
  }

  void setSortAscending({required bool ascending}) {
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

  Future<void> toggleFavorite(Campaign campaign) async {
    try {
      if (_campaignRepo != null) {
        final newStatus = !campaign.title.startsWith('[ARCHIVIERT] ');
        final updatedTitle = newStatus
            ? campaign.title
            : '[ARCHIVIERT] ${campaign.title.replaceFirst('[ARCHIVIERT] ', '')}';

        final updatedCampaign = await _campaignRepo!.update(
          campaign.copyWith(title: updatedTitle),
        );

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
    final campaign = _campaigns.cast<Campaign?>().firstWhere(
      (c) => c!.id == campaignId,
      orElse: () => null,
    );
    return campaign?.sessionIds.length ?? 0;
  }

  Future<int> getQuestCount(String campaignId) async {
    final campaign = _campaigns.cast<Campaign?>().firstWhere(
      (c) => c!.id == campaignId,
      orElse: () => null,
    );
    return campaign?.questIds.length ?? 0;
  }

  Future<DateTime?> getLastActiveDate(String campaignId) async {
    final campaign = _campaigns.cast<Campaign?>().firstWhere(
      (c) => c!.id == campaignId,
      orElse: () => null,
    );
    return campaign?.updatedAt;
  }

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
        result = 0;
        break;
      case CampaignSortOption.npcs:
        result = 0;
        break;
      case CampaignSortOption.items:
        result = 0;
        break;
      case CampaignSortOption.spells:
        result = 0;
        break;
    }

    return _ascendingOrder ? result : -result;
  }

  /// Bindet den eingeloggten User und den Sync-Service ein.
  /// Wird vom ProxyProvider bei jeder Auth-Änderung aufgerufen.
  void bindCloudSync(AppUser? user, CampaignSyncService service) {
    _syncService = service;
    final wasLoggedIn = _syncUser != null;
    _syncUser = user;
    if (wasLoggedIn && user == null) {
      _syncedIds.clear();
      _pendingSyncIds.clear();
      notifyListeners();
    }
  }

  Future<void> _autoUpload(Campaign campaign) async {
    final user = _syncUser;
    final service = _syncService;
    if (user == null || service == null) return;
    _pendingSyncIds.add(campaign.id);
    notifyListeners();
    try {
      await service.uploadCampaign(campaign, user.uid);
      _pendingSyncIds.remove(campaign.id);
      _syncedIds.add(campaign.id);
    } catch (e) {
      _pendingSyncIds.remove(campaign.id);
      debugPrint('[CampaignViewModel] Auto-Upload fehlgeschlagen: $e');
    }
    notifyListeners();
  }

  Future<void> _autoDelete(String campaignId) async {
    final user = _syncUser;
    final service = _syncService;
    if (user == null || service == null) return;
    _syncedIds.remove(campaignId);
    notifyListeners();
    try {
      await service.deleteCampaign(campaignId, user.uid);
    } catch (e) {
      debugPrint('[CampaignViewModel] Auto-Delete fehlgeschlagen: $e');
    }
  }

  /// Synchronisiert lokale Kampagnen mit Firestore.
  /// Konfliktlösung: die Version mit dem neueren [updatedAt]-Zeitstempel gewinnt.
  Future<void> syncWithCloud(AppUser user, CampaignSyncService syncService) async {
    if (_isSyncing) return;
    _isSyncing = true;
    _syncError = null;
    notifyListeners();

    try {
      final cloudCampaigns = await syncService.downloadCampaigns(user.uid);

      // Cloud → Lokal: importiere neuere Cloud-Versionen
      for (final cloud in cloudCampaigns) {
        if (_campaignRepo == null) continue;
        final existing = await _campaignRepo!.findById(cloud.id);
        if (existing == null) {
          final saved = await _campaignRepo!.create(cloud);
          _campaigns.insert(0, saved);
        } else if (cloud.updatedAt.isAfter(existing.updatedAt)) {
          final saved = await _campaignRepo!.update(cloud);
          final idx = _campaigns.indexWhere((c) => c.id == cloud.id);
          if (idx != -1) _campaigns[idx] = saved;
        }
      }

      // Lokal → Cloud: lade lokale Kampagnen hoch, die neu oder neuer sind
      final cloudIds = {for (final c in cloudCampaigns) c.id: c.updatedAt};
      for (final local in _campaigns) {
        final cloudUpdated = cloudIds[local.id];
        if (cloudUpdated == null || local.updatedAt.isAfter(cloudUpdated)) {
          await syncService.uploadCampaign(local, user.uid);
        }
      }

      // Nach erfolgreichem Full-Sync alle lokalen Kampagnen als synced markieren
      for (final c in _campaigns) {
        _syncedIds.add(c.id);
      }
      _pendingSyncIds.clear();
      _invalidateFilteredCache();
      _lastSyncedAt = DateTime.now();
      debugPrint('[CampaignViewModel] Cloud-Sync abgeschlossen um $_lastSyncedAt');
    } catch (e) {
      _syncError = e.toString().replaceFirst('Exception: ', '');
      debugPrint('[CampaignViewModel] Sync-Fehler: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    debugPrint('🗑️ [CampaignViewModel] dispose() aufgerufen');
    super.dispose();
  }
}
