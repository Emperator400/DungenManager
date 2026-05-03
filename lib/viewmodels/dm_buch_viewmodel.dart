import 'package:flutter/foundation.dart';

import '../database/core/database_connection.dart';
import '../database/repositories/ort_model_repository.dart';
import '../database/repositories/quest_model_repository.dart';
import '../database/repositories/scene_model_repository.dart';
import '../database/repositories/session_model_repository.dart';
import '../models/campaign.dart';
import '../models/ort.dart';
import '../models/quest.dart';
import '../models/scene.dart';
import '../models/session.dart';
import '../services/ort_service.dart';

enum DmBuchMode { vorbereitung, live }

enum DmBuchLeftTab { karte, quests }

class DmBuchViewModel extends ChangeNotifier {
  final Campaign campaign;
  final OrtService _ortService;
  final OrtModelRepository _ortRepo;
  final QuestModelRepository _questRepo;
  final SceneModelRepository _sceneRepo;
  final SessionModelRepository _sessionRepo;

  DmBuchViewModel({
    required this.campaign,
    OrtService? ortService,
    OrtModelRepository? ortRepo,
    QuestModelRepository? questRepo,
    SceneModelRepository? sceneRepo,
    SessionModelRepository? sessionRepo,
  })  : _ortService = ortService ?? OrtService(),
        _ortRepo = ortRepo ?? OrtModelRepository(DatabaseConnection.instance),
        _questRepo = questRepo ?? QuestModelRepository(DatabaseConnection.instance),
        _sceneRepo = sceneRepo ?? SceneModelRepository(DatabaseConnection.instance),
        _sessionRepo = sessionRepo ?? SessionModelRepository(DatabaseConnection.instance);

  // ── STATE ──────────────────────────────────────────────────────────────────

  DmBuchMode _mode = DmBuchMode.vorbereitung;
  DmBuchMode get mode => _mode;

  DmBuchLeftTab _leftTab = DmBuchLeftTab.karte;
  DmBuchLeftTab get leftTab => _leftTab;

  List<Ort> _orte = [];
  List<Ort> get orte => _orte;

  Ort? _selectedOrt;
  Ort? get selectedOrt => _selectedOrt;

  List<Scene> _selectedOrtScenes = [];
  List<Scene> get selectedOrtScenes => _selectedOrtScenes;

  List<Quest> _quests = [];
  List<Quest> get quests => _quests;

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
      await Future.wait([_loadOrte(), _loadQuests()]);
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

  Future<void> _loadScenesForOrt(String ortId) async {
    _selectedOrtScenes = await _sceneRepo.findByOrtId(ortId);
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
    _selectedOrtScenes = [];
    notifyListeners();
    await _loadScenesForOrt(ort.id);
    notifyListeners();
  }

  void deselectOrt() {
    _selectedOrt = null;
    _selectedOrtScenes = [];
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

  Future<Ort?> createOrt({
    required String name,
    OrtType type = OrtType.other,
    String description = '',
  }) async {
    try {
      final ort = Ort.create(
        campaignId: campaign.id,
        name: name,
        type: type,
        description: description,
        sortOrder: _orte.length,
      );
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

  Future<void> deleteOrt(String ortId) async {
    try {
      await _ortService.deleteOrt(ortId);
      _orte.removeWhere((o) => o.id == ortId);
      if (_selectedOrt?.id == ortId) {
        _selectedOrt = null;
        _selectedOrtScenes = [];
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

  // ── SZENEN ────────────────────────────────────────────────────────────────

  Future<Scene?> createSceneForOrt(
    Ort ort, {
    required String name,
    SceneType type = SceneType.Exploration,
    String description = '',
  }) async {
    try {
      final scene = Scene(
        sessionId: '',
        orderIndex: _selectedOrtScenes.length,
        name: name,
        description: description,
        sceneType: type,
        ortId: ort.id,
      );
      final saved = await _sceneRepo.create(scene);
      _selectedOrtScenes.add(saved);
      notifyListeners();
      return saved;
    } catch (e) {
      debugPrint('[DmBuchViewModel] createSceneForOrt error: $e');
      return null;
    }
  }

  Future<void> deleteScene(String sceneId) async {
    try {
      await _sceneRepo.delete(sceneId);
      _selectedOrtScenes.removeWhere((s) => s.id == sceneId);
      notifyListeners();
    } catch (e) {
      debugPrint('[DmBuchViewModel] deleteScene error: $e');
    }
  }

  Future<void> reloadScenes() async {
    if (_selectedOrt == null) return;
    await _loadScenesForOrt(_selectedOrt!.id);
    notifyListeners();
  }

  // ── HILFSMETHODEN ─────────────────────────────────────────────────────────

  int sceneCountForOrt(String ortId) =>
      _selectedOrt?.id == ortId ? _selectedOrtScenes.length : 0;

  List<Quest> get activeQuests =>
      _quests.where((q) => q.status == QuestStatus.active).toList();

  Future<void> reloadQuests() async {
    await _loadQuests();
    notifyListeners();
  }

  // ── SESSION ───────────────────────────────────────────────────────────────

  /// Erstellt eine neue Session für diese Kampagne und gibt sie zurück.
  Future<Session?> startSession() async {
    try {
      final now = DateTime.now();
      final title =
          'Session vom ${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';
      final session = Session(
        campaignId: campaign.id,
        title: title,
        inGameTimeInMinutes: 480,
        liveNotes: '',
      );
      return await _sessionRepo.create(session);
    } catch (e) {
      debugPrint('[DmBuchViewModel] startSession error: $e');
      return null;
    }
  }
}
