import 'package:flutter/foundation.dart';

import '../database/core/database_connection.dart';
import '../database/repositories/ort_model_repository.dart';
import '../database/repositories/quest_model_repository.dart';
import '../database/repositories/scene_model_repository.dart';
import '../models/ort.dart';
import '../models/quest.dart';
import '../models/scene.dart';
import '../services/uuid_service.dart';

/// Synchronisiert Definitions-Felder einer Kopie mit ihrer Vorlage.
///
/// Einbahnstraße: Template → Kopie. Zustandsfelder (lastVisitedAt, memory,
/// isCompleted, Quest-status) werden NIE überschrieben.
class CampaignTemplateSyncService {
  CampaignTemplateSyncService({
    OrtModelRepository? ortRepository,
    SceneModelRepository? sceneRepository,
    QuestModelRepository? questRepository,
  })  : _ortRepo = ortRepository ?? OrtModelRepository(DatabaseConnection.instance),
        _sceneRepo = sceneRepository ?? SceneModelRepository(DatabaseConnection.instance),
        _questRepo = questRepository ?? QuestModelRepository(DatabaseConnection.instance);

  final OrtModelRepository _ortRepo;
  final SceneModelRepository _sceneRepo;
  final QuestModelRepository _questRepo;

  /// Synchronisiert die Kopie [copyCampaignId] mit der Vorlage [templateCampaignId].
  Future<TemplateSyncResult> syncFromTemplate(
    String copyCampaignId,
    String templateCampaignId,
  ) async {
    int updatedOrte = 0, addedOrte = 0, hiddenOrte = 0;
    int updatedScenes = 0, addedScenes = 0;
    int updatedQuests = 0, addedQuests = 0;

    // ── Orte ─────────────────────────────────────────────────────────────────
    final templateOrte = await _ortRepo.findByCampaign(templateCampaignId);
    final copyOrte     = await _ortRepo.findByCampaign(copyCampaignId);
    final templateOrtIds = templateOrte.map((o) => o.id).toSet();

    for (final tOrt in templateOrte) {
      final cOrt = copyOrte.where((o) => o.templateOrtId == tOrt.id).firstOrNull;
      if (cOrt != null) {
        await _ortRepo.update(cOrt.copyWith(
          name: tOrt.name,
          type: tOrt.type,
          description: tOrt.description,
          isHidden: false,
          updatedAt: DateTime.now(),
        ));
        updatedOrte++;

        final (su, sa) = await _syncScenesForOrt(tOrt.id, cOrt.id);
        updatedScenes += su;
        addedScenes += sa;
      } else {
        await _ortRepo.create(Ort.create(
          campaignId: copyCampaignId,
          name: tOrt.name,
          type: tOrt.type,
          description: tOrt.description,
          sortOrder: tOrt.sortOrder,
          templateOrtId: tOrt.id,
        ));
        addedOrte++;
      }
    }

    // Orte die in der Vorlage nicht mehr existieren → ausblenden
    for (final cOrt in copyOrte) {
      if (cOrt.templateOrtId != null && !templateOrtIds.contains(cOrt.templateOrtId)) {
        await _ortRepo.update(cOrt.copyWith(isHidden: true));
        hiddenOrte++;
      }
    }

    // ── Quests ────────────────────────────────────────────────────────────────
    final templateQuests = await _questRepo.findByCampaign(templateCampaignId);
    final copyQuests     = await _questRepo.findByCampaign(copyCampaignId);

    for (final tQuest in templateQuests) {
      final cQuest = copyQuests.where((q) => q.templateQuestId == tQuest.id).firstOrNull;
      if (cQuest != null) {
        await _questRepo.update(cQuest.copyWith(
          title: tQuest.title,
          description: tQuest.description,
          questType: tQuest.questType,
          difficulty: tQuest.difficulty,
          rewards: tQuest.rewards,
          updatedAt: DateTime.now(),
        ));
        updatedQuests++;
      } else {
        await _questRepo.create(tQuest.copyWith(
          id: UuidService().generateId(),
          campaignId: copyCampaignId,
          status: QuestStatus.active,
          templateQuestId: tQuest.id,
          updatedAt: DateTime.now(),
        ));
        addedQuests++;
      }
    }

    debugPrint(
      '[TemplateSyncService] Orte: +$addedOrte ~$updatedOrte 🚫$hiddenOrte | '
      'Szenen: +$addedScenes ~$updatedScenes | Quests: +$addedQuests ~$updatedQuests',
    );

    return TemplateSyncResult(
      updatedOrte: updatedOrte,
      addedOrte: addedOrte,
      hiddenOrte: hiddenOrte,
      updatedScenes: updatedScenes,
      addedScenes: addedScenes,
      updatedQuests: updatedQuests,
      addedQuests: addedQuests,
    );
  }

  // ── Szenen-Sync pro Ort ───────────────────────────────────────────────────

  Future<(int, int)> _syncScenesForOrt(String templateOrtId, String copyOrtId) async {
    final templateScenes = await _sceneRepo.findByOrtId(templateOrtId);
    final copyScenes     = await _sceneRepo.findByOrtId(copyOrtId);
    int updated = 0, added = 0;

    for (final tScene in templateScenes) {
      final cScene = copyScenes.where((s) => s.templateSceneId == tScene.id).firstOrNull;
      if (cScene != null) {
        await _sceneRepo.update(cScene.copyWith(
          name: tScene.name,
          description: tScene.description,
          sceneType: tScene.sceneType,
          estimatedDuration: tScene.estimatedDuration,
          complexity: tScene.complexity,
          updatedAt: DateTime.now(),
        ));
        updated++;
      } else {
        await _sceneRepo.create(Scene(
          orderIndex: tScene.orderIndex,
          name: tScene.name,
          description: tScene.description,
          sceneType: tScene.sceneType,
          estimatedDuration: tScene.estimatedDuration,
          complexity: tScene.complexity,
          ortId: copyOrtId,
          templateSceneId: tScene.id,
        ));
        added++;
      }
    }

    return (updated, added);
  }
}

class TemplateSyncResult {
  final int updatedOrte;
  final int addedOrte;
  final int hiddenOrte;
  final int updatedScenes;
  final int addedScenes;
  final int updatedQuests;
  final int addedQuests;

  const TemplateSyncResult({
    required this.updatedOrte,
    required this.addedOrte,
    required this.hiddenOrte,
    required this.updatedScenes,
    required this.addedScenes,
    required this.updatedQuests,
    required this.addedQuests,
  });

  int get totalChanges => updatedOrte + addedOrte + hiddenOrte + updatedScenes + addedScenes + updatedQuests + addedQuests;

  String get summary {
    final parts = <String>[];
    if (addedOrte > 0) parts.add('$addedOrte Orte hinzugefügt');
    if (updatedOrte > 0) parts.add('$updatedOrte Orte aktualisiert');
    if (hiddenOrte > 0) parts.add('$hiddenOrte Orte ausgeblendet');
    if (addedScenes > 0) parts.add('$addedScenes Szenen hinzugefügt');
    if (updatedScenes > 0) parts.add('$updatedScenes Szenen aktualisiert');
    if (addedQuests > 0) parts.add('$addedQuests Quests hinzugefügt');
    if (updatedQuests > 0) parts.add('$updatedQuests Quests aktualisiert');
    if (parts.isEmpty) return 'Alles aktuell – keine Änderungen';
    return parts.join(', ');
  }
}
