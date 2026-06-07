import 'package:flutter/foundation.dart';

import '../database/core/database_connection.dart';
import '../database/repositories/campaign_model_repository.dart';
import '../database/repositories/ort_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/repositories/quest_model_repository.dart';
import '../database/repositories/session_model_repository.dart';
import '../database/repositories/scene_model_repository.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../models/campaign.dart';
import '../models/map_layer.dart';
import '../models/scene.dart';
import '../models/ort.dart';
import '../models/player_character.dart';
import '../models/quest.dart';
import '../models/quest_reward.dart';
import '../models/session.dart';
import '../models/verlaufs_eintrag.dart';
import '../models/wiki_entry.dart';
export '../models/wiki_entry.dart' show WikiEntry, WikiEntryType;
import '../services/campaign_template_sync_service.dart';
import '../services/ort_service.dart';

enum DmBuchMode { vorbereitung, live }

enum DmBuchLeftTab { karte, quests, spieler, verlauf }

class DmBuchViewModel extends ChangeNotifier {
  Campaign _campaign;
  Campaign get campaign => _campaign;

  final OrtService _ortService;
  final OrtModelRepository _ortRepo;
  final QuestModelRepository _questRepo;
  final SessionModelRepository _sessionRepo;
  final SceneModelRepository _sceneRepo;
  final WikiEntryModelRepository _wikiRepo;
  final CampaignModelRepository _campaignRepo;
  final PlayerCharacterModelRepository _pcRepo;

  DmBuchViewModel({
    required Campaign campaign,
    OrtService? ortService,
    OrtModelRepository? ortRepo,
    QuestModelRepository? questRepo,
    SessionModelRepository? sessionRepo,
    SceneModelRepository? sceneRepo,
    WikiEntryModelRepository? wikiRepo,
    CampaignModelRepository? campaignRepo,
    PlayerCharacterModelRepository? pcRepo,
  })  : _campaign = campaign,
        _ortService = ortService ?? OrtService(),
        _ortRepo = ortRepo ?? OrtModelRepository(DatabaseConnection.instance),
        _questRepo = questRepo ?? QuestModelRepository(DatabaseConnection.instance),
        _sessionRepo = sessionRepo ?? SessionModelRepository(DatabaseConnection.instance),
        _sceneRepo = sceneRepo ?? SceneModelRepository(DatabaseConnection.instance),
        _wikiRepo = wikiRepo ?? WikiEntryModelRepository(DatabaseConnection.instance),
        _campaignRepo = campaignRepo ?? CampaignModelRepository(DatabaseConnection.instance),
        _pcRepo = pcRepo ?? PlayerCharacterModelRepository(DatabaseConnection.instance);

  // ── STATE ──────────────────────────────────────────────────────────────────

  DmBuchMode _mode = DmBuchMode.vorbereitung;
  DmBuchMode get mode => _mode;

  DmBuchLeftTab _leftTab = DmBuchLeftTab.karte;
  DmBuchLeftTab get leftTab => _leftTab;

  List<Ort> _orte = [];
  List<Ort> get orte => _orte.where((o) => !o.isHidden).toList();

  // Subkarten-Navigation: null = Weltkarte, String = ID des Eltern-Ortes
  final List<String?> _mapStack = [null];
  String? get currentMapParentId => _mapStack.last;
  int get mapStackDepth => _mapStack.length;

  List<Ort> get currentLevelOrte =>
      _orte.where((o) => !o.isHidden && o.parentOrtId == currentMapParentId).toList();

  bool hasChildren(String ortId) =>
      _orte.any((o) => o.parentOrtId == ortId);

  List<({String? id, String name})> get mapBreadcrumb {
    final result = <({String? id, String name})>[(id: null, name: 'Welt')];
    for (int i = 1; i < _mapStack.length; i++) {
      final ort = _orte.where((o) => o.id == _mapStack[i]).firstOrNull;
      if (ort != null) result.add((id: ort.id, name: ort.name));
    }
    return result;
  }

  void drillInto(Ort ort) {
    _mapStack.add(ort.id);
    _selectedOrt = null;
    _selectedOrtSessions = [];
    _loadCurrentLevelLayers().then((_) => notifyListeners());
    notifyListeners();
  }

  void drillTo(int depth) {
    if (depth < 0 || depth >= _mapStack.length) return;
    while (_mapStack.length > depth + 1) {
      _mapStack.removeLast();
    }
    _selectedOrt = null;
    _selectedOrtSessions = [];
    _loadCurrentLevelLayers().then((_) => notifyListeners());
    notifyListeners();
  }

  Ort? _selectedOrt;
  Ort? get selectedOrt => _selectedOrt;

  List<Session> _selectedOrtSessions = [];
  List<Session> get selectedOrtSessions => _selectedOrtSessions;

  List<Scene> _selectedOrtScenes = [];
  List<Scene> get selectedOrtScenes => _selectedOrtScenes;

  Map<String, int> _ortSceneCounts = {};
  int ortSceneCount(String ortId) => _ortSceneCounts[ortId] ?? 0;

  List<Quest> _quests = [];
  List<Quest> get quests => _quests;

  List<WikiEntry> _wikiEntries = [];
  List<WikiEntry> get wikiEntries => _wikiEntries;
  bool _isLoadingWikiEntries = false;

  List<PlayerCharacter> _characters = [];
  List<PlayerCharacter> get characters => _characters;

  // ── FOKUS-AUSWAHL ──────────────────────────────────────────────────────────

  Quest? _selectedQuest;
  Quest? get selectedQuest => _selectedQuest;

  PlayerCharacter? _selectedCharacter;
  PlayerCharacter? get selectedCharacter => _selectedCharacter;

  VerlaufsEintrag? _selectedVerlaufsEintrag;
  VerlaufsEintrag? get selectedVerlaufsEintrag => _selectedVerlaufsEintrag;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  // ── LAYER ─────────────────────────────────────────────────────────────────

  List<MapLayer> _currentLevelLayers = [];
  List<MapLayer> get currentLevelLayers => _currentLevelLayers;

  // ── INIT ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([_loadOrte(), _loadQuests(), _loadWikiEntries(), _loadCharacters()]);
      await Future.wait([_loadSceneCounts(), _loadCurrentLevelLayers()]);
    } catch (e) {
      _error = 'Fehler beim Laden: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadOrte() async {
    _orte = await _ortRepo.findByCampaign(campaign.id);
  }

  Future<void> _loadQuests() async {
    _quests = await _questRepo.findByCampaign(campaign.id);
  }

  Future<void> _loadWikiEntries() async {
    _wikiEntries = await _wikiRepo.findByCampaign(campaign.id);
  }

  Future<void> reloadWikiEntries() async {
    if (_isLoadingWikiEntries) return;
    _isLoadingWikiEntries = true;
    try {
      await _loadWikiEntries();
      notifyListeners();
    } finally {
      _isLoadingWikiEntries = false;
    }
  }

  Future<void> _loadCharacters() async {
    _characters = await _pcRepo.findByCampaign(campaign.id);
  }

  Future<void> reloadCharacters() async {
    await _loadCharacters();
    notifyListeners();
  }

  Future<void> _loadSessionsForOrt(String ortId) async {
    _selectedOrtSessions = await _sessionRepo.findByOrtId(ortId);
  }

  Future<void> _loadSceneCounts() async {
    final ortIds = _orte.map((o) => o.id).toList();
    _ortSceneCounts = await _sceneRepo.countByOrtId(ortIds);
  }

  Future<Scene?> createSceneForOrt({
    required Ort ort,
    required String name,
    required SceneType type,
  }) async {
    try {
      final scene = Scene(
        sessionId: null,
        campaignId: campaign.id,
        orderIndex: _selectedOrtScenes.length,
        name: name,
        sceneType: type,
        ortId: ort.id,
      );
      final created = await _sceneRepo.create(scene);
      _selectedOrtScenes.add(created);
      _ortSceneCounts[ort.id] = (_ortSceneCounts[ort.id] ?? 0) + 1;
      notifyListeners();
      return created;
    } catch (e) {
      debugPrint('[DmBuchViewModel] createSceneForOrt error: $e');
      return null;
    }
  }

  Future<({Ort ort, Scene scene})?> createSceneAndOrtAt({
    required double fracX,
    required double fracY,
    required String name,
    required SceneType sceneType,
    OrtType ortType = OrtType.other,
  }) async {
    try {
      final ort = await createOrt(
        name: name,
        type: ortType,
        mapX: fracX,
        mapY: fracY,
        parentOrtId: currentMapParentId,
      );
      if (ort == null) return null;
      final scene = await createSceneForOrt(ort: ort, name: name, type: sceneType);
      if (scene == null) return null;
      return (ort: ort, scene: scene);
    } catch (e) {
      debugPrint('[DmBuchViewModel] createSceneAndOrtAt error: $e');
      return null;
    }
  }

  Future<void> toggleSceneCompleted(Scene scene) async {
    try {
      final updated = await _sceneRepo.updateCompletionStatus(scene.id, !scene.isCompleted);
      if (updated == null) return;
      final idx = _selectedOrtScenes.indexWhere((s) => s.id == scene.id);
      if (idx >= 0) _selectedOrtScenes[idx] = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('[DmBuchViewModel] toggleSceneCompleted error: $e');
    }
  }

  Future<void> deleteScene(Scene scene) async {
    try {
      await _sceneRepo.delete(scene.id);
      _selectedOrtScenes.removeWhere((s) => s.id == scene.id);
      if (scene.ortId != null) {
        final cur = _ortSceneCounts[scene.ortId!] ?? 0;
        _ortSceneCounts[scene.ortId!] = (cur - 1).clamp(0, 9999);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[DmBuchViewModel] deleteScene error: $e');
    }
  }

  // ── NAVIGATION ────────────────────────────────────────────────────────────

  void setMode(DmBuchMode mode) {
    _mode = mode;
    notifyListeners();
  }

  void setLeftTab(DmBuchLeftTab tab) {
    _leftTab = tab;
    notifyListeners();
  }

  Future<void> selectOrt(Ort ort) async {
    _selectedOrt = ort;
    _selectedOrtSessions = [];
    _selectedOrtScenes = [];
    notifyListeners();
    await Future.wait([
      _loadSessionsForOrt(ort.id),
      _loadScenesForOrt(ort.id),
    ]);
    notifyListeners();
  }

  void deselectOrt() {
    _selectedOrt = null;
    _selectedOrtSessions = [];
    _selectedOrtScenes = [];
    notifyListeners();
  }

  Future<void> _loadScenesForOrt(String ortId) async {
    _selectedOrtScenes = await _sceneRepo.findByOrtId(ortId);
  }

  Future<void> reloadScenesForOrt(String ortId) async {
    await _loadScenesForOrt(ortId);
    await _loadSceneCounts();
    notifyListeners();
  }

  void selectQuest(Quest quest) {
    _selectedQuest = quest;
    notifyListeners();
  }

  void deselectQuest() {
    _selectedQuest = null;
    notifyListeners();
  }

  void selectCharacter(PlayerCharacter character) {
    _selectedCharacter = character;
    notifyListeners();
  }

  void deselectCharacter() {
    _selectedCharacter = null;
    notifyListeners();
  }

  void selectVerlaufsEintrag(VerlaufsEintrag eintrag) {
    _selectedVerlaufsEintrag = eintrag;
    notifyListeners();
  }

  Future<void> selectVerlaufsEintragOnMap(VerlaufsEintrag eintrag) async {
    _selectedVerlaufsEintrag = eintrag;
    if (eintrag.type == VerlaufsEintragType.ort && eintrag.refId != null) {
      final ort = _orte.where((o) => o.id == eintrag.refId).firstOrNull;
      if (ort != null) {
        await navigateToOrt(ort);
        return;
      }
    }
    notifyListeners();
  }

  Future<void> navigateToOrt(Ort ort) async {
    if (ort.parentOrtId == currentMapParentId) {
      _leftTab = DmBuchLeftTab.karte;
      await selectOrt(ort);
      return;
    }
    if (ort.parentOrtId != null) {
      final chain = <String>[];
      var parentId = ort.parentOrtId;
      while (parentId != null) {
        chain.insert(0, parentId);
        final parent = _orte.where((o) => o.id == parentId).firstOrNull;
        parentId = parent?.parentOrtId;
      }
      _mapStack
        ..clear()
        ..add(null)
        ..addAll(chain);
    } else {
      _mapStack
        ..clear()
        ..add(null);
    }
    _leftTab = DmBuchLeftTab.karte;
    await selectOrt(ort);
  }

  void deselectVerlaufsEintrag() {
    _selectedVerlaufsEintrag = null;
    notifyListeners();
  }

  // ── ORT PFAD ─────────────────────────────────────────────────────────────

  String ortPath(String ortId) {
    final chain = <String>[];
    var parentId = _orte.where((o) => o.id == ortId).firstOrNull?.parentOrtId;
    while (parentId != null) {
      final parent = _orte.where((o) => o.id == parentId).firstOrNull;
      if (parent == null) break;
      chain.insert(0, parent.name);
      parentId = parent.parentOrtId;
    }
    return ['Welt', ...chain].join(' › ');
  }

  // ── ORT REIHENFOLGE ───────────────────────────────────────────────────────

  Future<void> reorderOrte(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final item = _orte.removeAt(oldIndex);
    _orte.insert(newIndex, item);
    notifyListeners();
    await _ortService.reorderOrte(_orte);
  }

  // ── ORT CRUD ──────────────────────────────────────────────────────────────

  Future<Ort?> createOrtFromWikiEntry(WikiEntry entry, {String? parentOrtId}) => createOrt(
        name: entry.title,
        type: _ortTypeFromWikiEntryType(entry.entryType),
        description: entry.content,
        linkedWikiEntryIds: [entry.id],
        parentOrtId: parentOrtId,
      );

  Future<Ort?> createOrt({
    required String name,
    OrtType type = OrtType.other,
    String description = '',
    List<String> linkedWikiEntryIds = const [],
    double? mapX,
    double? mapY,
    String? parentOrtId,
  }) async {
    try {
      final base = Ort.create(
        campaignId: campaign.id,
        name: name,
        type: type,
        description: description,
        sortOrder: _orte.length,
        linkedWikiEntryIds: linkedWikiEntryIds,
        parentOrtId: parentOrtId,
      );
      final ort = (mapX != null && mapY != null)
          ? base.copyWith(mapX: mapX, mapY: mapY)
          : base;
      final saved = await _ortService.createOrt(ort);
      _orte.add(saved);
      notifyListeners();
      return saved;
    } catch (e) {
      debugPrint('[DmBuchViewModel] createOrt error: $e');
      return null;
    }
  }

  Future<void> updateOrt(Ort ort) async {
    try {
      final updated = await _ortService.updateOrt(ort);
      final idx = _orte.indexWhere((o) => o.id == ort.id);
      if (idx != -1) _orte[idx] = updated;
      if (_selectedOrt?.id == ort.id) _selectedOrt = updated;
      notifyListeners();
    } catch (e) {
      debugPrint('[DmBuchViewModel] updateOrt error: $e');
    }
  }

  Future<void> toggleOrtPositionLock(Ort ort) async {
    final updated = ort.copyWith(mapPositionLocked: !ort.mapPositionLocked);
    await updateOrt(updated);
  }

  /// Persists a node's canvas position after the user drags it.
  /// Does NOT call notifyListeners to avoid rebuilding the graph view mid-drag.
  Future<void> updateOrtPosition(String ortId, double x, double y) async {
    final idx = _orte.indexWhere((o) => o.id == ortId);
    if (idx == -1) return;
    final updated = _orte[idx].copyWith(mapX: x, mapY: y);
    _orte[idx] = updated;
    try {
      await _ortRepo.update(updated);
    } catch (e) {
      debugPrint('[DmBuchViewModel] updateOrtPosition error: $e');
    }
  }

  Future<void> deleteOrt(String ortId) async {
    try {
      await _ortService.deleteOrt(ortId);
      _orte.removeWhere((o) => o.id == ortId);
      if (_selectedOrt?.id == ortId) {
        _selectedOrt = null;
        _selectedOrtSessions = [];
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[DmBuchViewModel] deleteOrt error: $e');
    }
  }

  Future<void> markOrtVisited(Ort ort, {String? memory}) async {
    final updated = await _ortService.markVisited(ort, memory: memory);
    final idx = _orte.indexWhere((o) => o.id == ort.id);
    if (idx != -1) _orte[idx] = updated;
    if (_selectedOrt?.id == ort.id) _selectedOrt = updated;
    notifyListeners();
  }

  Future<void> saveMemory(Ort ort, String memory) async {
    final updated = await _ortService.updateMemory(ort, memory);
    final idx = _orte.indexWhere((o) => o.id == ort.id);
    if (idx != -1) _orte[idx] = updated;
    if (_selectedOrt?.id == ort.id) _selectedOrt = updated;
    notifyListeners();
  }

  // ── TEMPLATE-SYNC ─────────────────────────────────────────────────────────

  bool _isSyncing = false;
  bool get isSyncing => _isSyncing;

  /// Synchronisiert Orte, Szenen und Quests von der Vorlage in diese Kopie.
  /// Gibt eine Zusammenfassung zurück, oder null bei Fehler.
  Future<TemplateSyncResult?> syncFromTemplate() async {
    if (campaign.templateId == null) return null;
    _isSyncing = true;
    notifyListeners();
    try {
      final syncService = CampaignTemplateSyncService();
      final result = await syncService.syncFromTemplate(campaign.id, campaign.templateId!);
      await _loadOrte();
      return result;
    } catch (e) {
      debugPrint('[DmBuchViewModel] syncFromTemplate error: $e');
      return null;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ── SESSIONS FÜR ORT ─────────────────────────────────────────────────────

  Future<Session?> createSessionForOrt(Ort ort, {required String title}) async {
    try {
      final session = await _sessionRepo.create(Session(
        campaignId: campaign.id,
        title: title,
        ortId: ort.id,
      ));
      _selectedOrtSessions.insert(0, session);
      notifyListeners();
      return session;
    } catch (e) {
      debugPrint('[DmBuchViewModel] createSessionForOrt error: $e');
      return null;
    }
  }

  Future<void> deleteOrtSession(String sessionId) async {
    try {
      await _sessionRepo.delete(sessionId);
      _selectedOrtSessions.removeWhere((s) => s.id == sessionId);
      notifyListeners();
    } catch (e) {
      debugPrint('[DmBuchViewModel] deleteOrtSession error: $e');
    }
  }

  Future<void> reloadSessions() async {
    if (_selectedOrt == null) return;
    await _loadSessionsForOrt(_selectedOrt!.id);
    notifyListeners();
  }

  // ── HILFSMETHODEN ─────────────────────────────────────────────────────────

  List<Quest> get activeQuests =>
      _quests.where((q) => q.status == QuestStatus.active).toList();

  Future<void> reloadQuests() async {
    await _loadQuests();
    if (_selectedQuest != null) {
      _selectedQuest = _quests.where((q) => q.id == _selectedQuest!.id).cast<Quest?>().firstOrNull;
    }
    notifyListeners();
  }

  Future<List<Quest>> loadLibraryQuests() =>
      _questRepo.findQuestsWithoutCampaign();

  Future<void> addQuestFromLibrary(Quest libraryQuest) async {
    try {
      final copy = Quest.create(
        title: libraryQuest.title,
        description: libraryQuest.description,
        questType: libraryQuest.questType,
        difficulty: libraryQuest.difficulty,
        campaignId: campaign.id,
        location: libraryQuest.location,
        recommendedLevel: libraryQuest.recommendedLevel,
        estimatedDurationHours: libraryQuest.estimatedDurationHours,
        tags: List<String>.from(libraryQuest.tags),
        rewards: List<QuestReward>.from(libraryQuest.rewards),
        involvedNpcs: List<String>.from(libraryQuest.involvedNpcs),
        linkedWikiEntryIds: List<String>.from(libraryQuest.linkedWikiEntryIds),
      );
      final saved = await _questRepo.create(copy);
      _quests.add(saved);
      notifyListeners();
    } catch (e) {
      debugPrint('[DmBuchViewModel] addQuestFromLibrary error: $e');
    }
  }

  // ── WIKI-VERLINKUNG ───────────────────────────────────────────────────────

  OrtType _ortTypeFromWikiEntryType(WikiEntryType entryType) {
    switch (entryType) {
      case WikiEntryType.Place:    return OrtType.region;
      case WikiEntryType.Person:   return OrtType.city;
      case WikiEntryType.Faction:  return OrtType.building;
      case WikiEntryType.Magic:    return OrtType.building;
      case WikiEntryType.Quest:    return OrtType.dungeon;
      case WikiEntryType.Creature: return OrtType.wilderness;
      case WikiEntryType.Lore:
      case WikiEntryType.History:
      case WikiEntryType.Item:     return OrtType.other;
    }
  }

  Future<void> linkWikiEntry(Ort ort, String wikiEntryId) async {
    if (ort.linkedWikiEntryIds.contains(wikiEntryId)) return;
    var newType = ort.type;
    if (ort.type == OrtType.other) {
      final entry = _wikiEntries.where((w) => w.id == wikiEntryId).firstOrNull;
      if (entry != null)
        newType = _ortTypeFromWikiEntryType(entry.entryType);
    }
    final updated = ort.copyWith(
      linkedWikiEntryIds: [...ort.linkedWikiEntryIds, wikiEntryId],
      type: newType,
      updatedAt: DateTime.now(),
    );
    await _ortRepo.update(updated);
    _refreshOrt(updated);
  }

  Future<void> unlinkWikiEntry(Ort ort, String wikiEntryId) async {
    final updated = ort.copyWith(
      linkedWikiEntryIds: ort.linkedWikiEntryIds.where((id) => id != wikiEntryId).toList(),
      updatedAt: DateTime.now(),
    );
    await _ortRepo.update(updated);
    _refreshOrt(updated);
  }

  // ── ORT-VERBINDUNGEN ──────────────────────────────────────────────────────

  Future<void> connectOrte(Ort a, Ort b) async {
    if (a.id == b.id) return;
    if (!a.connectedOrtIds.contains(b.id)) {
      final updatedA = a.copyWith(
        connectedOrtIds: [...a.connectedOrtIds, b.id],
        updatedAt: DateTime.now(),
      );
      await _ortRepo.update(updatedA);
      _refreshOrt(updatedA);
    }
    if (!b.connectedOrtIds.contains(a.id)) {
      final updatedB = b.copyWith(
        connectedOrtIds: [...b.connectedOrtIds, a.id],
        updatedAt: DateTime.now(),
      );
      await _ortRepo.update(updatedB);
      _refreshOrt(updatedB);
    }
  }

  Future<void> disconnectOrte(Ort a, Ort b) async {
    final updatedA = a.copyWith(
      connectedOrtIds: a.connectedOrtIds.where((id) => id != b.id).toList(),
      updatedAt: DateTime.now(),
    );
    await _ortRepo.update(updatedA);
    _refreshOrt(updatedA);

    final updatedB = b.copyWith(
      connectedOrtIds: b.connectedOrtIds.where((id) => id != a.id).toList(),
      updatedAt: DateTime.now(),
    );
    await _ortRepo.update(updatedB);
    _refreshOrt(updatedB);
  }

  void _refreshOrt(Ort updated) {
    final idx = _orte.indexWhere((o) => o.id == updated.id);
    if (idx != -1) _orte[idx] = updated;
    if (_selectedOrt?.id == updated.id) _selectedOrt = updated;
    notifyListeners();
  }

  // ── VERLAUFSPLAN ──────────────────────────────────────────────────────────

  List<VerlaufsEintrag> get verlaufsplan => _campaign.verlaufsplan;

  Future<void> addVerlaufsEintrag(VerlaufsEintrag eintrag) async {
    final updated = _campaign.copyWith(
      verlaufsplan: [..._campaign.verlaufsplan, eintrag],
      updatedAt: DateTime.now(),
    );
    await _saveCampaign(updated);
  }

  Future<void> updateVerlaufsEintrag(VerlaufsEintrag eintrag) async {
    final list = _campaign.verlaufsplan.map((e) => e.id == eintrag.id ? eintrag : e).toList();
    final updated = _campaign.copyWith(verlaufsplan: list, updatedAt: DateTime.now());
    await _saveCampaign(updated);
  }

  Future<void> removeVerlaufsEintrag(String id) async {
    final list = _campaign.verlaufsplan.where((e) => e.id != id).toList();
    final updated = _campaign.copyWith(verlaufsplan: list, updatedAt: DateTime.now());
    await _saveCampaign(updated);
  }

  Future<void> toggleVerlaufsEintrag(String id) async {
    final list = _campaign.verlaufsplan
        .map((e) => e.id == id ? e.copyWith(isDone: !e.isDone) : e)
        .toList();
    final updated = _campaign.copyWith(verlaufsplan: list, updatedAt: DateTime.now());
    await _saveCampaign(updated);
  }

  Future<void> saveConnectionNote(String id, String note) async {
    final list = _campaign.verlaufsplan
        .map((e) => e.id == id ? e.copyWith(connectionNote: note.isEmpty ? null : note) : e)
        .toList();
    final updated = _campaign.copyWith(verlaufsplan: list, updatedAt: DateTime.now());
    await _saveCampaign(updated);
  }

  // ── VERLAUFS-GRAPHEN ─────────────────────────────────────────────────────────

  String? get verlaufsKarteImagePath => _campaign.verlaufsKarteImagePath;

  Future<void> setVerlaufsKarteImage(String? path) async {
    final updated = _campaign.copyWith(
      verlaufsKarteImagePath: path,
      updatedAt: DateTime.now(),
    );
    await _saveCampaign(updated);
  }

  String? get karteImagePath => _campaign.karteImagePath;

  Future<void> setKarteImage(String? path) async {
    final updated = _campaign.copyWith(
      karteImagePath: path,
      updatedAt: DateTime.now(),
    );
    await _saveCampaign(updated);
  }

  // Liefert das Hintergrundbild für die aktuell angezeigte Kartenebene
  String? get currentMapImagePath {
    if (currentMapParentId == null) return _campaign.karteImagePath;
    final parent = _orte.where((o) => o.id == currentMapParentId).firstOrNull;
    return parent?.mapImagePath;
  }

  // Setzt das Hintergrundbild für die aktuelle Ebene (Weltkarte oder Subkarte)
  Future<void> setCurrentLevelMapImage(String? path) async {
    if (currentMapParentId == null) {
      await setKarteImage(path);
    } else {
      final idx = _orte.indexWhere((o) => o.id == currentMapParentId);
      if (idx == -1) return;
      final updated = _orte[idx].copyWith(mapImagePath: path);
      _orte[idx] = updated;
      await _ortRepo.update(updated);
      notifyListeners();
    }
  }

  // ── LAYER-METHODEN ────────────────────────────────────────────────────────

  Future<void> _loadCurrentLevelLayers() async {
    _currentLevelLayers = await _ortService.getLayersForContext(
      _campaign.id,
      currentMapParentId,
    );
  }

  Future<void> createLayer(String name) async {
    final layer = MapLayer.create(
      campaignId: _campaign.id,
      ortId: currentMapParentId,
      name: name,
      sortOrder: _currentLevelLayers.length,
    );
    final created = await _ortService.createLayer(layer);
    _currentLevelLayers = [..._currentLevelLayers, created];
    notifyListeners();
  }

  Future<void> setLayerImage(MapLayer layer, String? path) async {
    final updated = await _ortService.updateLayer(
      layer.copyWith(imagePath: path),
    );
    _replaceLayer(updated);
    notifyListeners();
  }

  Future<void> toggleLayerVisibility(MapLayer layer) async {
    final updated = await _ortService.updateLayer(
      layer.copyWith(isVisible: !layer.isVisible),
    );
    _replaceLayer(updated);
    notifyListeners();
  }

  Future<void> deleteLayer(MapLayer layer) async {
    await _ortService.deleteLayer(layer.id);
    _currentLevelLayers =
        _currentLevelLayers.where((l) => l.id != layer.id).toList();
    notifyListeners();
  }

  void _replaceLayer(MapLayer updated) {
    final idx = _currentLevelLayers.indexWhere((l) => l.id == updated.id);
    if (idx == -1) return;
    final copy = List<MapLayer>.from(_currentLevelLayers);
    copy[idx] = updated;
    _currentLevelLayers = copy;
  }

  Future<void> addVerlaufsConnection(String fromId, String toId) async {
    final from = _campaign.verlaufsplan.where((e) => e.id == fromId).firstOrNull;
    if (from == null || from.connections.contains(toId)) return;
    await updateVerlaufsEintrag(
      from.copyWith(connections: [...from.connections, toId]),
    );
  }

  Future<void> removeVerlaufsConnection(String fromId, String toId) async {
    final from = _campaign.verlaufsplan.where((e) => e.id == fromId).firstOrNull;
    if (from == null) return;
    await updateVerlaufsEintrag(
      from.copyWith(connections: from.connections.where((id) => id != toId).toList()),
    );
  }

  // ── VERLAUFSPLAN REIHENFOLGE ──────────────────────────────────────────────

  Future<void> reorderVerlaufsplan(int oldIndex, int newIndex) async {
    if (newIndex > oldIndex) newIndex -= 1;
    final list = List<VerlaufsEintrag>.from(_campaign.verlaufsplan);
    list.insert(newIndex, list.removeAt(oldIndex));
    final updated = _campaign.copyWith(verlaufsplan: list, updatedAt: DateTime.now());
    await _saveCampaign(updated);
  }

  Future<void> _saveCampaign(Campaign updated) async {
    try {
      _campaign = await _campaignRepo.update(updated);
      // Keep selected Verlaufs entry in sync
      if (_selectedVerlaufsEintrag != null) {
        _selectedVerlaufsEintrag = _campaign.verlaufsplan
            .where((e) => e.id == _selectedVerlaufsEintrag!.id)
            .cast<VerlaufsEintrag?>()
            .firstOrNull;
      }
      notifyListeners();
    } catch (e) {
      debugPrint('[DmBuchViewModel] _saveCampaign error: $e');
    }
  }
}
