import 'package:flutter/foundation.dart';

import '../database/core/database_connection.dart';
import '../database/repositories/campaign_model_repository.dart';
import '../database/repositories/ort_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../database/repositories/quest_model_repository.dart';
import '../database/repositories/session_model_repository.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../models/campaign.dart';
import '../models/ort.dart';
import '../models/player_character.dart';
import '../models/quest.dart';
import '../models/quest_reward.dart';
import '../models/session.dart';
import '../models/verlaufs_eintrag.dart';
import '../models/wiki_entry.dart';
export '../models/wiki_entry.dart' show WikiEntry, WikiEntryType;
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
  final WikiEntryModelRepository _wikiRepo;
  final CampaignModelRepository _campaignRepo;
  final PlayerCharacterModelRepository _pcRepo;

  DmBuchViewModel({
    required Campaign campaign,
    OrtService? ortService,
    OrtModelRepository? ortRepo,
    QuestModelRepository? questRepo,
    SessionModelRepository? sessionRepo,
    WikiEntryModelRepository? wikiRepo,
    CampaignModelRepository? campaignRepo,
    PlayerCharacterModelRepository? pcRepo,
  })  : _campaign = campaign,
        _ortService = ortService ?? OrtService(),
        _ortRepo = ortRepo ?? OrtModelRepository(DatabaseConnection.instance),
        _questRepo = questRepo ?? QuestModelRepository(DatabaseConnection.instance),
        _sessionRepo = sessionRepo ?? SessionModelRepository(DatabaseConnection.instance),
        _wikiRepo = wikiRepo ?? WikiEntryModelRepository(DatabaseConnection.instance),
        _campaignRepo = campaignRepo ?? CampaignModelRepository(DatabaseConnection.instance),
        _pcRepo = pcRepo ?? PlayerCharacterModelRepository(DatabaseConnection.instance);

  // ── STATE ──────────────────────────────────────────────────────────────────

  DmBuchMode _mode = DmBuchMode.vorbereitung;
  DmBuchMode get mode => _mode;

  DmBuchLeftTab _leftTab = DmBuchLeftTab.karte;
  DmBuchLeftTab get leftTab => _leftTab;

  List<Ort> _orte = [];
  List<Ort> get orte => _orte;

  Ort? _selectedOrt;
  Ort? get selectedOrt => _selectedOrt;

  List<Session> _selectedOrtSessions = [];
  List<Session> get selectedOrtSessions => _selectedOrtSessions;

  List<Quest> _quests = [];
  List<Quest> get quests => _quests;

  List<WikiEntry> _wikiEntries = [];
  List<WikiEntry> get wikiEntries => _wikiEntries;

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

  // ── INIT ───────────────────────────────────────────────────────────────────

  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await Future.wait([_loadOrte(), _loadQuests(), _loadWikiEntries(), _loadCharacters()]);
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
    notifyListeners();
    await _loadSessionsForOrt(ort.id);
    notifyListeners();
  }

  void deselectOrt() {
    _selectedOrt = null;
    _selectedOrtSessions = [];
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

  void deselectVerlaufsEintrag() {
    _selectedVerlaufsEintrag = null;
    notifyListeners();
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

  Future<Ort?> createOrtFromWikiEntry(WikiEntry entry) => createOrt(
        name: entry.title,
        description: entry.content,
        linkedWikiEntryIds: [entry.id],
      );

  Future<Ort?> createOrt({
    required String name,
    OrtType type = OrtType.other,
    String description = '',
    List<String> linkedWikiEntryIds = const [],
    double? mapX,
    double? mapY,
  }) async {
    try {
      final base = Ort.create(
        campaignId: campaign.id,
        name: name,
        type: type,
        description: description,
        sortOrder: _orte.length,
        linkedWikiEntryIds: linkedWikiEntryIds,
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

  /// Synchronisiert Definitions-Felder (Name, Typ, Beschreibung) von der Vorlage.
  /// Gibt die Anzahl aktualisierter Orte zurück, oder null bei Fehler.
  Future<int?> syncFromTemplate() async {
    if (campaign.templateId == null) return null;
    _isSyncing = true;
    notifyListeners();
    try {
      final result = await _ortService.syncFromTemplate(campaign.templateId!);
      await _loadOrte();
      return result.updated;
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

  Future<void> linkWikiEntry(Ort ort, String wikiEntryId) async {
    if (ort.linkedWikiEntryIds.contains(wikiEntryId)) return;
    final updated = ort.copyWith(
      linkedWikiEntryIds: [...ort.linkedWikiEntryIds, wikiEntryId],
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
