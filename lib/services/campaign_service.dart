// Dart Core
import 'dart:async';

// Eigene Projekte
import '../models/campaign.dart';
import '../database/repositories/campaign_model_repository.dart';
import '../database/core/database_connection.dart';
import 'exceptions/service_exceptions.dart';

/// Service für Campaign Business Logic
/// 
/// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
/// 
/// Bietet alle CRUD-Operationen für Kampagnen und
/// kapselt die Datenbankzugriffe mit Validierung.
/// Verwendet spezifische Exceptions und ServiceResult Pattern.
class CampaignService {
  final CampaignModelRepository _campaignRepository;

  CampaignService({
    CampaignModelRepository? campaignRepository,
  }) : _campaignRepository = campaignRepository ?? CampaignModelRepository(DatabaseConnection.instance);

  // ========== CRUD OPERATIONS ==========

  /// Holt alle Kampagnen aus der Datenbank über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<ServiceResult<List<Campaign>>> getAllCampaigns() async {
    return performServiceOperation('getAllCampaigns', () async {
      return await _campaignRepository.findAll();
    });
  }

  /// Holt eine Kampagne per ID über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<ServiceResult<Campaign?>> getCampaignById(String id) async {
    return performServiceOperation('getCampaignById', () async {
      return await _campaignRepository.findById(id);
    });
  }

  /// Erstellt eine neue Kampagne über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<ServiceResult<Campaign>> createCampaign(Campaign campaign) async {
    return performServiceOperation('createCampaign', () async {
      // Validierung
      if (!campaign.isValid) {
        throw ValidationException.fromErrors(
          campaign.validationErrors,
          operation: 'createCampaign',
        );
      }

      return await _campaignRepository.create(campaign);
    });
  }

  /// Aktualisiert eine Kampagne über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<ServiceResult<Campaign>> updateCampaign(Campaign campaign) async {
    return performServiceOperation('updateCampaign', () async {
      // Validierung
      if (!campaign.isValid) {
        throw ValidationException.fromErrors(
          campaign.validationErrors,
          operation: 'updateCampaign',
        );
      }

      final updatedCampaign = await _campaignRepository.update(campaign);
      if (updatedCampaign == null) {
        throw DatabaseException(
          'Kampagne nicht gefunden oder konnte nicht aktualisiert werden',
          operation: 'updateCampaign',
        );
      }
      return updatedCampaign;
    });
  }

  /// Löscht eine Kampagne über neues Repository
  Future<ServiceResult<void>> deleteCampaign(String id) async {
    return performServiceOperation('deleteCampaign', () async {
      final exists = await campaignExists(id);
      if (!exists) {
        throw ResourceNotFoundException.forId('Campaign', id, operation: 'deleteCampaign');
      }
      
      await _campaignRepository.delete(id);
    });
  }

  // ========== STATUS OPERATIONS ==========

  /// Aktualisiert den Status einer Kampagne
  Future<ServiceResult<void>> updateCampaignStatus(
    String campaignId, 
    CampaignStatus status,
  ) async {
    return performServiceOperation('updateCampaignStatus', () async {
      final campaign = await _getCampaignOrThrow(campaignId);

      final updatedCampaign = campaign.copyWith(
        status: status,
        updatedAt: DateTime.now(),
        // Timestamps für Status-Wechsel
        startedAt: status == CampaignStatus.active && campaign.startedAt == null 
            ? DateTime.now() 
            : campaign.startedAt,
        completedAt: status == CampaignStatus.completed && campaign.completedAt == null 
            ? DateTime.now() 
            : campaign.completedAt,
      );

      await updateCampaign(updatedCampaign);
    });
  }

  // ========== PLAYER MANAGEMENT ==========

  /// Fügt einen Player zu einer Kampagne hinzu
  Future<ServiceResult<void>> addPlayerToCampaign(
    String campaignId, 
    String playerId,
  ) async {
    return performServiceOperation('addPlayerToCampaign', () async {
      final campaign = await _getCampaignOrThrow(campaignId);

      // Prüfe ob Player bereits existiert
      if (campaign.playerCharacterIds.contains(playerId)) {
        throw BusinessException(
          'Player bereits in Kampagne vorhanden',
          operation: 'addPlayerToCampaign',
        );
      }

      final updatedPlayerIds = [...campaign.playerCharacterIds, playerId];
      final updatedCampaign = campaign.copyWith(
        playerCharacterIds: updatedPlayerIds,
        updatedAt: DateTime.now(),
      );

      await updateCampaign(updatedCampaign);
    });
  }

  /// Entfernt einen Player aus einer Kampagne
  Future<ServiceResult<void>> removePlayerFromCampaign(
    String campaignId, 
    String playerId,
  ) async {
    return performServiceOperation('removePlayerFromCampaign', () async {
      final campaign = await _getCampaignOrThrow(campaignId);

      if (!campaign.playerCharacterIds.contains(playerId)) {
        throw BusinessException(
          'Player nicht in Kampagne vorhanden',
          operation: 'removePlayerFromCampaign',
        );
      }

      final updatedPlayerIds = campaign.playerCharacterIds
          .where((id) => id != playerId)
          .toList();
      final updatedCampaign = campaign.copyWith(
        playerCharacterIds: updatedPlayerIds,
        updatedAt: DateTime.now(),
      );

      await updateCampaign(updatedCampaign);
    });
  }

  // ========== QUEST MANAGEMENT ==========

  /// Fügt eine Quest zu einer Kampagne hinzu
  Future<ServiceResult<void>> addQuestToCampaign(
    String campaignId, 
    String questId,
  ) async {
    return performServiceOperation('addQuestToCampaign', () async {
      final campaign = await _getCampaignOrThrow(campaignId);

      if (campaign.questIds.contains(questId)) {
        throw BusinessException(
          'Quest bereits in Kampagne vorhanden',
          operation: 'addQuestToCampaign',
        );
      }

      final updatedQuestIds = [...campaign.questIds, questId];
      final updatedCampaign = campaign.copyWith(
        questIds: updatedQuestIds,
        updatedAt: DateTime.now(),
      );

      await updateCampaign(updatedCampaign);
    });
  }

  /// Entfernt eine Quest aus einer Kampagne
  Future<ServiceResult<void>> removeQuestFromCampaign(
    String campaignId, 
    String questId,
  ) async {
    return performServiceOperation('removeQuestFromCampaign', () async {
      final campaign = await _getCampaignOrThrow(campaignId);

      if (!campaign.questIds.contains(questId)) {
        throw BusinessException(
          'Quest nicht in Kampagne vorhanden',
          operation: 'removeQuestFromCampaign',
        );
      }

      final updatedQuestIds = campaign.questIds
          .where((id) => id != questId)
          .toList();
      final updatedCampaign = campaign.copyWith(
        questIds: updatedQuestIds,
        updatedAt: DateTime.now(),
      );

      await updateCampaign(updatedCampaign);
    });
  }

  // ========== WIKI MANAGEMENT ==========

  /// Fügt einen Wiki-Eintrag zu einer Kampagne hinzu
  Future<ServiceResult<void>> addWikiEntryToCampaign(
    String campaignId, 
    String wikiEntryId,
  ) async {
    return performServiceOperation('addWikiEntryToCampaign', () async {
      final campaign = await _getCampaignOrThrow(campaignId);

      if (campaign.wikiEntryIds.contains(wikiEntryId)) {
        throw BusinessException(
          'Wiki-Eintrag bereits in Kampagne vorhanden',
          operation: 'addWikiEntryToCampaign',
        );
      }

      final updatedWikiEntryIds = [...campaign.wikiEntryIds, wikiEntryId];
      final updatedCampaign = campaign.copyWith(
        wikiEntryIds: updatedWikiEntryIds,
        updatedAt: DateTime.now(),
      );

      await updateCampaign(updatedCampaign);
    });
  }

  /// Entfernt einen Wiki-Eintrag aus einer Kampagne
  Future<ServiceResult<void>> removeWikiEntryFromCampaign(
    String campaignId, 
    String wikiEntryId,
  ) async {
    return performServiceOperation('removeWikiEntryFromCampaign', () async {
      final campaign = await _getCampaignOrThrow(campaignId);

      if (!campaign.wikiEntryIds.contains(wikiEntryId)) {
        throw BusinessException(
          'Wiki-Eintrag nicht in Kampagne vorhanden',
          operation: 'removeWikiEntryFromCampaign',
        );
      }

      final updatedWikiEntryIds = campaign.wikiEntryIds
          .where((id) => id != wikiEntryId)
          .toList();
      final updatedCampaign = campaign.copyWith(
        wikiEntryIds: updatedWikiEntryIds,
        updatedAt: DateTime.now(),
      );

      await updateCampaign(updatedCampaign);
    });
  }

  // ========== SESSION MANAGEMENT ==========

  /// Fügt eine Session zu einer Kampagne hinzu
  Future<ServiceResult<void>> addSessionToCampaign(
    String campaignId, 
    String sessionId,
  ) async {
    return performServiceOperation('addSessionToCampaign', () async {
      final campaign = await _getCampaignOrThrow(campaignId);

      if (campaign.sessionIds.contains(sessionId)) {
        throw BusinessException(
          'Session bereits in Kampagne vorhanden',
          operation: 'addSessionToCampaign',
        );
      }

      final updatedSessionIds = [...campaign.sessionIds, sessionId];
      final updatedCampaign = campaign.copyWith(
        sessionIds: updatedSessionIds,
        updatedAt: DateTime.now(),
      );

      await updateCampaign(updatedCampaign);
    });
  }

  /// Entfernt eine Session aus einer Kampagne
  Future<ServiceResult<void>> removeSessionFromCampaign(
    String campaignId, 
    String sessionId,
  ) async {
    return performServiceOperation('removeSessionFromCampaign', () async {
      final campaign = await _getCampaignOrThrow(campaignId);

      if (!campaign.sessionIds.contains(sessionId)) {
        throw BusinessException(
          'Session nicht in Kampagne vorhanden',
          operation: 'removeSessionFromCampaign',
        );
      }

      final updatedSessionIds = campaign.sessionIds
          .where((id) => id != sessionId)
          .toList();
      final updatedCampaign = campaign.copyWith(
        sessionIds: updatedSessionIds,
        updatedAt: DateTime.now(),
      );

      await updateCampaign(updatedCampaign);
    });
  }

  // ========== SETTINGS MANAGEMENT ==========

  /// Aktualisiert die Kampagnen-Einstellungen
  Future<ServiceResult<void>> updateCampaignSettings(
    String campaignId, 
    CampaignSettings settings,
  ) async {
    return performServiceOperation('updateCampaignSettings', () async {
      final campaign = await _getCampaignOrThrow(campaignId);

      final updatedCampaign = campaign.copyWith(
        settings: settings,
        updatedAt: DateTime.now(),
      );

      await updateCampaign(updatedCampaign);
    });
  }

  // ========== UTILITY METHODS ==========

  /// Toggle Favorite Status (verwendet isPublic als Favorite)
  Future<ServiceResult<void>> toggleFavorite(String campaignId) async {
    return performServiceOperation('toggleFavorite', () async {
      final campaign = await _getCampaignOrThrow(campaignId);

      final updatedSettings = campaign.settings.copyWith(
        isPublic: !campaign.settings.isPublic,
      );
      final updatedCampaign = campaign.copyWith(
        settings: updatedSettings,
        updatedAt: DateTime.now(),
      );

      await updateCampaign(updatedCampaign);
    });
  }

  /// Prüft ob eine Kampagne existiert
  Future<bool> campaignExists(String id) async {
    try {
      final result = await getCampaignById(id);
      return result.data != null;
    } catch (e) {
      return false;
    }
  }

  /// Holt Kampagnen für einen bestimmten Dungeon Master
  Future<ServiceResult<List<Campaign>>> getCampaignsByDM(
    String dungeonMasterId,
  ) async {
    return performServiceOperation('getCampaignsByDM', () async {
      final allCampaignsResult = await getAllCampaigns();
      if (!allCampaignsResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Kampagnen',
          operation: 'getCampaignsByDM',
        );
      }

      return allCampaignsResult.data!
          .where((campaign) => campaign.dungeonMasterId == dungeonMasterId)
          .toList();
    });
  }

  /// Holt aktive Kampagnen
  Future<ServiceResult<List<Campaign>>> getActiveCampaigns() async {
    return performServiceOperation('getActiveCampaigns', () async {
      final allCampaignsResult = await getAllCampaigns();
      if (!allCampaignsResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Kampagnen',
          operation: 'getActiveCampaigns',
        );
      }

      return allCampaignsResult.data!
          .where((campaign) => campaign.status == CampaignStatus.active)
          .toList();
    });
  }

  /// Holt abgeschlossene Kampagnen
  Future<ServiceResult<List<Campaign>>> getCompletedCampaigns() async {
    return performServiceOperation('getCompletedCampaigns', () async {
      final allCampaignsResult = await getAllCampaigns();
      if (!allCampaignsResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Kampagnen',
          operation: 'getCompletedCampaigns',
        );
      }

      return allCampaignsResult.data!
          .where((campaign) => campaign.status == CampaignStatus.completed)
          .toList();
    });
  }

  /// Sucht Kampagnen nach Titel oder Beschreibung
  Future<ServiceResult<List<Campaign>>> searchCampaigns(String query) async {
    return performServiceOperation('searchCampaigns', () async {
      if (query.trim().isEmpty) {
        throw ValidationException(
          'Suchbegriff darf nicht leer sein',
          operation: 'searchCampaigns',
        );
      }

      final allCampaignsResult = await getAllCampaigns();
      if (!allCampaignsResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Kampagnen',
          operation: 'searchCampaigns',
        );
      }

      final queryLower = query.toLowerCase();
      return allCampaignsResult.data!.where((campaign) {
        return campaign.title.toLowerCase().contains(queryLower) ||
               campaign.description.toLowerCase().contains(queryLower);
      }).toList();
    });
  }

  /// Holt Kampagnen nach Status
  Future<ServiceResult<List<Campaign>>> getCampaignsByStatus(
    CampaignStatus status,
  ) async {
    return performServiceOperation('getCampaignsByStatus', () async {
      final allCampaignsResult = await getAllCampaigns();
      if (!allCampaignsResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Kampagnen',
          operation: 'getCampaignsByStatus',
        );
      }

      return allCampaignsResult.data!
          .where((campaign) => campaign.status == status)
          .toList();
    });
  }

  /// Holt Kampagnen nach Typ
  Future<ServiceResult<List<Campaign>>> getCampaignsByType(
    CampaignType type,
  ) async {
    return performServiceOperation('getCampaignsByType', () async {
      final allCampaignsResult = await getAllCampaigns();
      if (!allCampaignsResult.isSuccess) {
        throw DatabaseException(
          'Fehler beim Laden aller Kampagnen',
          operation: 'getCampaignsByType',
        );
      }

      return allCampaignsResult.data!
          .where((campaign) => campaign.type == type)
          .toList();
    });
  }

  // ========== STATISTICS METHODS ==========

  /// Dupliziert eine Kampagne über neues Repository
  /// 
  /// HINWEIS: Verwendet jetzt das neue CampaignModelRepository
  Future<ServiceResult<Campaign>> duplicateCampaign(String campaignId) async {
    return performServiceOperation('duplicateCampaign', () async {
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
        status: CampaignStatus.planning,
        type: originalCampaign.type,
        settings: originalCampaign.settings,
      );

      return await _campaignRepository.create(duplicatedCampaign);
    });
  }

  /// Holt die Anzahl der Helden für eine Kampagne (Legacy-Methode für ViewModel-Kompatibilität)
  Future<int> getHeroCount(String campaignId) async {
    try {
      final campaign = await _getCampaignOrThrow(campaignId);
      return campaign.playerCharacterIds.length;
    } catch (e) {
      return 0;
    }
  }

  /// Holt die Anzahl der Sessions für eine Kampagne (Legacy-Methode für ViewModel-Kompatibilität)
  Future<int> getSessionCount(String campaignId) async {
    try {
      final campaign = await _getCampaignOrThrow(campaignId);
      return campaign.sessionIds.length;
    } catch (e) {
      return 0;
    }
  }

  /// Holt die Anzahl der Quests für eine Kampagne (Legacy-Methode für ViewModel-Kompatibilität)
  Future<int> getQuestCount(String campaignId) async {
    try {
      final campaign = await _getCampaignOrThrow(campaignId);
      return campaign.questIds.length;
    } catch (e) {
      return 0;
    }
  }

  /// Holt das Datum der letzten Aktivität für eine Kampagne (Legacy-Methode für ViewModel-Kompatibilität)
  Future<DateTime?> getLastActiveDate(String campaignId) async {
    try {
      final campaign = await _getCampaignOrThrow(campaignId);
      return campaign.updatedAt;
    } catch (e) {
      return null;
    }
  }

  // ========== PRIVATE HELPER METHODS ==========

  /// Holt eine Kampagne oder wirft Exception
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
