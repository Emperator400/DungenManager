import 'dart:async';

import '../database/core/database_connection.dart';
import '../database/repositories/campaign_model_repository.dart';
import '../database/repositories/ort_model_repository.dart';
import '../database/repositories/quest_model_repository.dart';
import '../database/repositories/scene_model_repository.dart';
import '../database/repositories/session_model_repository.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../models/campaign.dart';
import '../models/quest.dart';
import '../services/uuid_service.dart';
import 'exceptions/service_exceptions.dart';

class CampaignService {
  final CampaignModelRepository _campaignRepository;
  final OrtModelRepository _ortRepository;
  final QuestModelRepository _questRepository;
  final SessionModelRepository _sessionRepository;
  final SceneModelRepository _sceneRepository;
  final WikiEntryModelRepository _wikiRepository;

  CampaignService({
    CampaignModelRepository? campaignRepository,
    OrtModelRepository? ortRepository,
    QuestModelRepository? questRepository,
    SessionModelRepository? sessionRepository,
    SceneModelRepository? sceneRepository,
    WikiEntryModelRepository? wikiRepository,
  })  : _campaignRepository = campaignRepository ?? CampaignModelRepository(DatabaseConnection.instance),
        _ortRepository = ortRepository ?? OrtModelRepository(DatabaseConnection.instance),
        _questRepository = questRepository ?? QuestModelRepository(DatabaseConnection.instance),
        _sessionRepository = sessionRepository ?? SessionModelRepository(DatabaseConnection.instance),
        _sceneRepository = sceneRepository ?? SceneModelRepository(DatabaseConnection.instance),
        _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance);

  Future<ServiceResult<List<Campaign>>> getAllCampaigns() async =>
      performServiceOperation('getAllCampaigns', () async => _campaignRepository.findAll());

  Future<ServiceResult<Campaign?>> getCampaignById(String id) async =>
      performServiceOperation('getCampaignById', () async => _campaignRepository.findById(id));

  Future<ServiceResult<Campaign>> createCampaign(Campaign campaign) async =>
      performServiceOperation('createCampaign', () async {
        if (!campaign.isValid) {
          throw ValidationException.fromErrors(
            campaign.validationErrors,
            operation: 'createCampaign',
          );
        }
        return _campaignRepository.create(campaign);
      });

  Future<ServiceResult<Campaign>> updateCampaign(Campaign campaign) async =>
      performServiceOperation('updateCampaign', () async {
        if (!campaign.isValid) {
          throw ValidationException.fromErrors(
            campaign.validationErrors,
            operation: 'updateCampaign',
          );
        }
        return _campaignRepository.update(campaign);
      });

  Future<ServiceResult<void>> deleteCampaign(String id) async =>
      performServiceOperation('deleteCampaign', () async {
        final exists = await campaignExists(id);
        if (!exists) {
          throw ResourceNotFoundException.forId('Campaign', id, operation: 'deleteCampaign');
        }
        await _campaignRepository.delete(id);
      });

  Future<ServiceResult<void>> updateCampaignStatus(
    String campaignId,
    CampaignStatus status,
  ) async =>
      performServiceOperation('updateCampaignStatus', () async {
        final campaign = await _getCampaignOrThrow(campaignId);
        final updatedCampaign = campaign.copyWith(
          status: status,
          updatedAt: DateTime.now(),
          startedAt: status == CampaignStatus.active && campaign.startedAt == null
              ? DateTime.now()
              : campaign.startedAt,
          completedAt: status == CampaignStatus.completed && campaign.completedAt == null
              ? DateTime.now()
              : campaign.completedAt,
        );
        await updateCampaign(updatedCampaign);
      });

  Future<ServiceResult<void>> addPlayerToCampaign(
    String campaignId,
    String playerId,
  ) async =>
      performServiceOperation('addPlayerToCampaign', () async {
        final campaign = await _getCampaignOrThrow(campaignId);
        if (campaign.playerCharacterIds.contains(playerId)) {
          throw const BusinessException(
            'Player bereits in Kampagne vorhanden',
            operation: 'addPlayerToCampaign',
          );
        }
        await updateCampaign(campaign.copyWith(
          playerCharacterIds: [...campaign.playerCharacterIds, playerId],
          updatedAt: DateTime.now(),
        ));
      });

  Future<ServiceResult<void>> removePlayerFromCampaign(
    String campaignId,
    String playerId,
  ) async =>
      performServiceOperation('removePlayerFromCampaign', () async {
        final campaign = await _getCampaignOrThrow(campaignId);
        if (!campaign.playerCharacterIds.contains(playerId)) {
          throw const BusinessException(
            'Player nicht in Kampagne vorhanden',
            operation: 'removePlayerFromCampaign',
          );
        }
        await updateCampaign(campaign.copyWith(
          playerCharacterIds: campaign.playerCharacterIds
              .where((id) => id != playerId)
              .toList(),
          updatedAt: DateTime.now(),
        ));
      });

  Future<ServiceResult<void>> addQuestToCampaign(
    String campaignId,
    String questId,
  ) async =>
      performServiceOperation('addQuestToCampaign', () async {
        final campaign = await _getCampaignOrThrow(campaignId);
        if (campaign.questIds.contains(questId)) {
          throw const BusinessException(
            'Quest bereits in Kampagne vorhanden',
            operation: 'addQuestToCampaign',
          );
        }
        await updateCampaign(campaign.copyWith(
          questIds: [...campaign.questIds, questId],
          updatedAt: DateTime.now(),
        ));
      });

  Future<ServiceResult<void>> removeQuestFromCampaign(
    String campaignId,
    String questId,
  ) async =>
      performServiceOperation('removeQuestFromCampaign', () async {
        final campaign = await _getCampaignOrThrow(campaignId);
        if (!campaign.questIds.contains(questId)) {
          throw const BusinessException(
            'Quest nicht in Kampagne vorhanden',
            operation: 'removeQuestFromCampaign',
          );
        }
        await updateCampaign(campaign.copyWith(
          questIds: campaign.questIds.where((id) => id != questId).toList(),
          updatedAt: DateTime.now(),
        ));
      });

  Future<ServiceResult<void>> addWikiEntryToCampaign(
    String campaignId,
    String wikiEntryId,
  ) async =>
      performServiceOperation('addWikiEntryToCampaign', () async {
        final campaign = await _getCampaignOrThrow(campaignId);
        if (campaign.wikiEntryIds.contains(wikiEntryId)) {
          throw const BusinessException(
            'Wiki-Eintrag bereits in Kampagne vorhanden',
            operation: 'addWikiEntryToCampaign',
          );
        }
        await updateCampaign(campaign.copyWith(
          wikiEntryIds: [...campaign.wikiEntryIds, wikiEntryId],
          updatedAt: DateTime.now(),
        ));
      });

  Future<ServiceResult<void>> removeWikiEntryFromCampaign(
    String campaignId,
    String wikiEntryId,
  ) async =>
      performServiceOperation('removeWikiEntryFromCampaign', () async {
        final campaign = await _getCampaignOrThrow(campaignId);
        if (!campaign.wikiEntryIds.contains(wikiEntryId)) {
          throw const BusinessException(
            'Wiki-Eintrag nicht in Kampagne vorhanden',
            operation: 'removeWikiEntryFromCampaign',
          );
        }
        await updateCampaign(campaign.copyWith(
          wikiEntryIds: campaign.wikiEntryIds.where((id) => id != wikiEntryId).toList(),
          updatedAt: DateTime.now(),
        ));
      });

  Future<ServiceResult<void>> addSessionToCampaign(
    String campaignId,
    String sessionId,
  ) async =>
      performServiceOperation('addSessionToCampaign', () async {
        final campaign = await _getCampaignOrThrow(campaignId);
        if (campaign.sessionIds.contains(sessionId)) {
          throw const BusinessException(
            'Session bereits in Kampagne vorhanden',
            operation: 'addSessionToCampaign',
          );
        }
        await updateCampaign(campaign.copyWith(
          sessionIds: [...campaign.sessionIds, sessionId],
          updatedAt: DateTime.now(),
        ));
      });

  Future<ServiceResult<void>> removeSessionFromCampaign(
    String campaignId,
    String sessionId,
  ) async =>
      performServiceOperation('removeSessionFromCampaign', () async {
        final campaign = await _getCampaignOrThrow(campaignId);
        if (!campaign.sessionIds.contains(sessionId)) {
          throw const BusinessException(
            'Session nicht in Kampagne vorhanden',
            operation: 'removeSessionFromCampaign',
          );
        }
        await updateCampaign(campaign.copyWith(
          sessionIds: campaign.sessionIds.where((id) => id != sessionId).toList(),
          updatedAt: DateTime.now(),
        ));
      });

  Future<ServiceResult<void>> updateCampaignSettings(
    String campaignId,
    CampaignSettings settings,
  ) async =>
      performServiceOperation('updateCampaignSettings', () async {
        final campaign = await _getCampaignOrThrow(campaignId);
        await updateCampaign(campaign.copyWith(
          settings: settings,
          updatedAt: DateTime.now(),
        ));
      });

  Future<ServiceResult<void>> toggleFavorite(String campaignId) async =>
      performServiceOperation('toggleFavorite', () async {
        final campaign = await _getCampaignOrThrow(campaignId);
        final updatedSettings = campaign.settings.copyWith(
          isPublic: !campaign.settings.isPublic,
        );
        await updateCampaign(campaign.copyWith(
          settings: updatedSettings,
          updatedAt: DateTime.now(),
        ));
      });

  Future<bool> campaignExists(String id) async {
    try {
      final result = await getCampaignById(id);
      return result.data != null;
    } catch (e) {
      return false;
    }
  }

  Future<ServiceResult<List<Campaign>>> getCampaignsByDM(
    String dungeonMasterId,
  ) async =>
      performServiceOperation('getCampaignsByDM', () async {
        final allCampaignsResult = await getAllCampaigns();
        if (!allCampaignsResult.isSuccess) {
          throw const DatabaseException(
            'Fehler beim Laden aller Kampagnen',
            operation: 'getCampaignsByDM',
          );
        }
        return allCampaignsResult.data!
            .where((campaign) => campaign.dungeonMasterId == dungeonMasterId)
            .toList();
      });

  Future<ServiceResult<List<Campaign>>> getActiveCampaigns() async =>
      performServiceOperation('getActiveCampaigns', () async {
        final allCampaignsResult = await getAllCampaigns();
        if (!allCampaignsResult.isSuccess) {
          throw const DatabaseException(
            'Fehler beim Laden aller Kampagnen',
            operation: 'getActiveCampaigns',
          );
        }
        return allCampaignsResult.data!
            .where((campaign) => campaign.status == CampaignStatus.active)
            .toList();
      });

  Future<ServiceResult<List<Campaign>>> getCompletedCampaigns() async =>
      performServiceOperation('getCompletedCampaigns', () async {
        final allCampaignsResult = await getAllCampaigns();
        if (!allCampaignsResult.isSuccess) {
          throw const DatabaseException(
            'Fehler beim Laden aller Kampagnen',
            operation: 'getCompletedCampaigns',
          );
        }
        return allCampaignsResult.data!
            .where((campaign) => campaign.status == CampaignStatus.completed)
            .toList();
      });

  Future<ServiceResult<List<Campaign>>> searchCampaigns(String query) async =>
      performServiceOperation('searchCampaigns', () async {
        if (query.trim().isEmpty) {
          throw const ValidationException(
            'Suchbegriff darf nicht leer sein',
            operation: 'searchCampaigns',
          );
        }
        final allCampaignsResult = await getAllCampaigns();
        if (!allCampaignsResult.isSuccess) {
          throw const DatabaseException(
            'Fehler beim Laden aller Kampagnen',
            operation: 'searchCampaigns',
          );
        }
        final queryLower = query.toLowerCase();
        return allCampaignsResult.data!.where((campaign) =>
            campaign.title.toLowerCase().contains(queryLower) ||
            campaign.description.toLowerCase().contains(queryLower)).toList();
      });

  Future<ServiceResult<List<Campaign>>> getCampaignsByStatus(
    CampaignStatus status,
  ) async =>
      performServiceOperation('getCampaignsByStatus', () async {
        final allCampaignsResult = await getAllCampaigns();
        if (!allCampaignsResult.isSuccess) {
          throw const DatabaseException(
            'Fehler beim Laden aller Kampagnen',
            operation: 'getCampaignsByStatus',
          );
        }
        return allCampaignsResult.data!
            .where((campaign) => campaign.status == status)
            .toList();
      });

  Future<ServiceResult<List<Campaign>>> getCampaignsByType(
    CampaignType type,
  ) async =>
      performServiceOperation('getCampaignsByType', () async {
        final allCampaignsResult = await getAllCampaigns();
        if (!allCampaignsResult.isSuccess) {
          throw const DatabaseException(
            'Fehler beim Laden aller Kampagnen',
            operation: 'getCampaignsByType',
          );
        }
        return allCampaignsResult.data!
            .where((campaign) => campaign.type == type)
            .toList();
      });

  Future<ServiceResult<Campaign>> duplicateCampaign(String campaignId) async =>
      performServiceOperation('duplicateCampaign', () async {
        final originalCampaignResult = await getCampaignById(campaignId);
        if (!originalCampaignResult.isSuccess || originalCampaignResult.data == null) {
          throw ResourceNotFoundException.forId(
            'Campaign',
            campaignId,
            operation: 'duplicateCampaign',
          );
        }
        final originalCampaign = originalCampaignResult.data!;
        final duplicatedCampaign = Campaign.create(
          title: '${originalCampaign.title} (Kopie)',
          description: originalCampaign.description,
          type: originalCampaign.type,
          settings: originalCampaign.settings,
        );
        return _campaignRepository.create(duplicatedCampaign);
      });

  Future<int> getHeroCount(String campaignId) async {
    try {
      final campaign = await _getCampaignOrThrow(campaignId);
      return campaign.playerCharacterIds.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getSessionCount(String campaignId) async {
    try {
      final campaign = await _getCampaignOrThrow(campaignId);
      return campaign.sessionIds.length;
    } catch (e) {
      return 0;
    }
  }

  Future<int> getQuestCount(String campaignId) async {
    try {
      final campaign = await _getCampaignOrThrow(campaignId);
      return campaign.questIds.length;
    } catch (e) {
      return 0;
    }
  }

  Future<DateTime?> getLastActiveDate(String campaignId) async {
    try {
      final campaign = await _getCampaignOrThrow(campaignId);
      return campaign.updatedAt;
    } catch (e) {
      return null;
    }
  }

  Future<ServiceResult<List<Campaign>>> getTemplates() async =>
      performServiceOperation('getTemplates', () async {
        final all = await _campaignRepository.findAll();
        return all.where((c) => c.isTemplate).toList();
      });

  Future<ServiceResult<Campaign>> createCopyFromTemplate(
    Campaign template, {
    required String title,
  }) async =>
      performServiceOperation('createCopyFromTemplate', () async {
        if (!template.isTemplate) {
          throw const ValidationException(
            'Nur Vorlagen können kopiert werden',
            operation: 'createCopyFromTemplate',
          );
        }

        final idMap = <String, String>{};
        final newCampaignId = UuidService().generateId();
        final now = DateTime.now();

        // Create campaign stub first so session FK (campaignId → campaigns.id) is satisfied.
        // IDs will be backfilled via update() after all children are created.
        final newCampaign = await _campaignRepository.create(Campaign(
          id: newCampaignId,
          title: title,
          description: template.description,
          type: template.type,
          createdAt: now,
          updatedAt: now,
          settings: template.settings,
          accentColor: template.accentColor,
          system: template.system,
          templateId: template.id,
          verlaufsplan: template.verlaufsplan,
          verlaufsKarteImagePath: template.verlaufsKarteImagePath,
          karteImagePath: template.karteImagePath,
        ));

        final wikiEntries = await _wikiRepository.findByCampaign(template.id);
        for (final w in wikiEntries) {
          idMap[w.id] = UuidService().generateId();
        }
        final copiedWikiIds = <String>[];
        for (final w in wikiEntries) {
          final newId = idMap[w.id]!;
          copiedWikiIds.add(newId);
          await _wikiRepository.create(w.copyWith(
            id: newId,
            campaignId: newCampaignId,
            parentId: w.parentId != null ? idMap[w.parentId] : null,
            childIds: _remapIds(w.childIds, idMap),
            isFavorite: false,
          ));
        }

        final quests = await _questRepository.findByCampaign(template.id);
        for (final q in quests) {
          idMap[q.id] = UuidService().generateId();
        }
        final copiedQuestIds = <String>[];
        for (final q in quests) {
          final newId = idMap[q.id]!;
          copiedQuestIds.add(newId);
          await _questRepository.create(q.copyWith(
            id: newId,
            campaignId: newCampaignId,
            status: QuestStatus.active,
            linkedWikiEntryIds: _remapIds(q.linkedWikiEntryIds, idMap),
          ));
        }

        final orte = await _ortRepository.findByCampaign(template.id);
        for (final o in orte) {
          idMap[o.id] = UuidService().generateId();
        }
        for (final o in orte) {
          await _ortRepository.create(o.copyWith(
            id: idMap[o.id],
            campaignId: newCampaignId,
            templateOrtId: o.id,
            connectedOrtIds: _remapIds(o.connectedOrtIds, idMap),
            parentOrtId: o.parentOrtId != null ? idMap[o.parentOrtId] : null,
            lastVisitedAt: null,
            memory: null,
          ));
        }

        final sessions = await _sessionRepository.findByCampaign(template.id);
        for (final s in sessions) {
          idMap[s.id] = UuidService().generateId();
        }
        final copiedSessionIds = <String>[];
        for (final s in sessions) {
          final newSessionId = idMap[s.id]!;
          copiedSessionIds.add(newSessionId);

          final scenes = await _sceneRepository.findBySession(s.id);
          for (final sc in scenes) {
            idMap[sc.id] = UuidService().generateId();
          }
          final copiedSceneIds = <String>[];
          for (final sc in scenes) {
            final newSceneId = idMap[sc.id]!;
            copiedSceneIds.add(newSceneId);
            await _sceneRepository.create(sc.copyWith(
              id: newSceneId,
              sessionId: newSessionId,
              linkedQuestIds: _remapIds(sc.linkedQuestIds, idMap),
              linkedWikiEntryIds: _remapIds(sc.linkedWikiEntryIds, idMap),
              linkedCharacterIds: [],
            ));
          }

          await _sessionRepository.create(s.copyWith(
            id: newSessionId,
            campaignId: newCampaignId,
            sceneIds: copiedSceneIds,
            characterTrackingIds: [],
            questProgressIds: [],
            ortId: s.ortId != null ? idMap[s.ortId!] : null,
          ));
        }

        // Backfill collected child IDs into the campaign record.
        return _campaignRepository.update(newCampaign.copyWith(
          sessionIds: copiedSessionIds,
          questIds: copiedQuestIds,
          wikiEntryIds: copiedWikiIds,
        ));
      });

  List<String> _remapIds(List<String> ids, Map<String, String> idMap) =>
      ids.map((id) => idMap[id] ?? id).toList();

  Future<Campaign> _getCampaignOrThrow(String campaignId) async {
    final result = await getCampaignById(campaignId);
    if (!result.isSuccess || result.data == null) {
      throw ResourceNotFoundException.forId(
        'Campaign',
        campaignId,
        operation: '_getCampaignOrThrow',
      );
    }
    return result.data!;
  }
}
