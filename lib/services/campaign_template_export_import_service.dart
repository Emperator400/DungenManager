import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../models/campaign.dart';
import '../models/ort.dart';
import '../models/quest.dart';
import '../models/session.dart';
import '../models/scene.dart';
import '../models/wiki_entry.dart';
import '../database/repositories/campaign_model_repository.dart';
import '../database/repositories/ort_model_repository.dart';
import '../database/repositories/quest_model_repository.dart';
import '../database/repositories/session_model_repository.dart';
import '../database/repositories/scene_model_repository.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../database/core/database_connection.dart';
import '../services/uuid_service.dart';
import 'exceptions/service_exceptions.dart';

class CampaignTemplateExportImportService {
  static const _formatKey = 'dungenmanager_campaign_template';
  static const _version = '1.0';

  final CampaignModelRepository _campaignRepository;
  final OrtModelRepository _ortRepository;
  final QuestModelRepository _questRepository;
  final SessionModelRepository _sessionRepository;
  final SceneModelRepository _sceneRepository;
  final WikiEntryModelRepository _wikiRepository;

  CampaignTemplateExportImportService({
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

  // ── Export ────────────────────────────────────────────────────────────────

  /// Exportiert eine Vorlage als .campaign.json-Datei.
  /// Gibt den Dateipfad zurück — die UI kann darüber einen Share-Dialog öffnen.
  Future<ServiceResult<String>> exportTemplate(String campaignId) async {
    return performServiceOperation('exportTemplate', () async {
      final campaign = await _campaignRepository.findById(campaignId);
      if (campaign == null) {
        throw ResourceNotFoundException.forId('Campaign', campaignId, operation: 'exportTemplate');
      }

      final orte = await _ortRepository.findByCampaign(campaignId);
      final quests = await _questRepository.findByCampaign(campaignId);
      final wikiEntries = await _wikiRepository.findByCampaign(campaignId);

      final sessions = await _sessionRepository.findByCampaign(campaignId);
      final allScenes = <Scene>[];
      for (final s in sessions) {
        allScenes.addAll(await _sceneRepository.findBySession(s.id));
      }

      final payload = {
        'format': _formatKey,
        'version': _version,
        'exportedAt': DateTime.now().toIso8601String(),
        'campaign': campaign.toDatabaseMap(),
        'orte': orte.map((o) => o.toDatabaseMap()).toList(),
        'quests': quests.map((q) => q.toDatabaseMap()).toList(),
        'sessions': sessions.map((s) => s.toDatabaseMap()).toList(),
        'scenes': allScenes.map((sc) => sc.toDatabaseMap()).toList(),
        'wikiEntries': wikiEntries.map((w) => w.toDatabaseMap()).toList(),
      };

      final json = const JsonEncoder.withIndent('  ').convert(payload);
      final bytes = utf8.encode(json);

      final dir = await getApplicationDocumentsDirectory();
      final safeName = campaign.title.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
      final fileName = '${safeName}_vorlage.campaign.json';
      final file = File('${dir.path}/$fileName');
      await file.writeAsBytes(bytes);

      return file.path;
    });
  }

  // ── Import ────────────────────────────────────────────────────────────────

  /// Öffnet den Datei-Picker und importiert eine .campaign.json als Vorlage.
  Future<ServiceResult<Campaign>> importTemplate() async {
    return performServiceOperation('importTemplate', () async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        throw ValidationException('Keine Datei ausgewählt', operation: 'importTemplate');
      }

      final fileBytes = result.files.first.bytes;
      if (fileBytes == null) {
        throw ValidationException('Datei konnte nicht gelesen werden', operation: 'importTemplate');
      }

      final content = utf8.decode(fileBytes);
      return await _parseAndSave(content);
    });
  }

  Future<Campaign> _parseAndSave(String jsonContent) async {
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(jsonContent) as Map<String, dynamic>;
    } catch (_) {
      throw ValidationException('Ungültiges JSON-Format', operation: 'importTemplate');
    }

    if (payload['format'] != _formatKey) {
      throw ValidationException(
        'Unbekanntes Format: ${payload['format']}',
        operation: 'importTemplate',
      );
    }

    final idMap = <String, String>{};

    final wikiMaps = (payload['wikiEntries'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final questMaps = (payload['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final ortMaps = (payload['orte'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final sessionMaps = (payload['sessions'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final sceneMaps = (payload['scenes'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final campaignMap = payload['campaign'] as Map<String, dynamic>;

    // ── Phase 1: Alle neuen IDs vorbelegen ───────────────────────────────────
    final newCampaignId = UuidService().generateId();
    idMap[campaignMap['id'] as String] = newCampaignId;
    for (final m in wikiMaps) idMap[m['id'] as String] = UuidService().generateId();
    for (final m in questMaps) idMap[m['id'] as String] = UuidService().generateId();
    for (final m in ortMaps) idMap[m['id'] as String] = UuidService().generateId();
    for (final m in sessionMaps) idMap[m['id'] as String] = UuidService().generateId();
    for (final m in sceneMaps) idMap[m['id'] as String] = UuidService().generateId();

    final now = DateTime.now();

    // ── Phase 2: Speichern mit remappten IDs ─────────────────────────────────

    // WikiEntries
    final copiedWikiIds = <String>[];
    for (final m in wikiMaps) {
      final w = WikiEntry.fromDatabaseMap(m);
      final newId = idMap[w.id]!;
      copiedWikiIds.add(newId);
      await _wikiRepository.create(w.copyWith(
        id: newId,
        campaignId: newCampaignId,
        parentId: w.parentId != null ? idMap[w.parentId!] : null,
        childIds: _remapIds(w.childIds, idMap),
        isFavorite: false,
      ));
    }

    // Quests
    final copiedQuestIds = <String>[];
    for (final m in questMaps) {
      final q = Quest.fromDatabaseMap(m);
      final newId = idMap[q.id]!;
      copiedQuestIds.add(newId);
      await _questRepository.create(q.copyWith(
        id: newId,
        campaignId: newCampaignId,
        status: QuestStatus.active,
        completedAt: null,
        linkedWikiEntryIds: _remapIds(q.linkedWikiEntryIds, idMap),
      ));
    }

    // Orte
    for (final m in ortMaps) {
      final o = Ort.fromDatabaseMap(m);
      await _ortRepository.create(o.copyWith(
        id: idMap[o.id]!,
        campaignId: newCampaignId,
        templateOrtId: o.id,
        connectedOrtIds: _remapIds(o.connectedOrtIds, idMap),
        parentOrtId: o.parentOrtId != null ? idMap[o.parentOrtId!] : null,
        lastVisitedAt: null,
        memory: null,
      ));
    }

    // Sessions + Scenes
    final copiedSessionIds = <String>[];
    for (final sm in sessionMaps) {
      final s = Session.fromDatabaseMap(sm);
      final newSessionId = idMap[s.id]!;
      copiedSessionIds.add(newSessionId);

      final sessionScenes = sceneMaps
          .where((sc) => (sc['session_id'] ?? sc['sessionId']) == s.id)
          .toList();

      final copiedSceneIds = <String>[];
      for (final scm in sessionScenes) {
        final sc = Scene.fromDatabaseMap(scm);
        final newSceneId = idMap[sc.id]!;
        copiedSceneIds.add(newSceneId);
        await _sceneRepository.create(sc.copyWith(
          id: newSceneId,
          sessionId: newSessionId,
          linkedQuestIds: _remapIds(sc.linkedQuestIds, idMap),
          linkedWikiEntryIds: _remapIds(sc.linkedWikiEntryIds, idMap),
          linkedEncounterId: null,
          linkedCharacterIds: [],
        ));
      }

      await _sessionRepository.create(s.copyWith(
        id: newSessionId,
        campaignId: newCampaignId,
        sceneIds: copiedSceneIds,
        activeSceneId: null,
        characterTrackingIds: [],
        questProgressIds: [],
        startedAt: null,
        completedAt: null,
      ));
    }

    // Campaign
    final origCampaign = Campaign.fromDatabaseMap(campaignMap);
    return await _campaignRepository.create(Campaign(
      id: newCampaignId,
      title: origCampaign.title,
      description: origCampaign.description,
      status: CampaignStatus.planning,
      type: origCampaign.type,
      createdAt: now,
      updatedAt: now,
      settings: origCampaign.settings,
      accentColor: origCampaign.accentColor,
      system: origCampaign.system,
      isTemplate: true,
      sessionIds: copiedSessionIds,
      questIds: copiedQuestIds,
      wikiEntryIds: copiedWikiIds,
      verlaufsplan: origCampaign.verlaufsplan,
      karteImagePath: null,
      verlaufsKarteImagePath: null,
    ));
  }

  List<String> _remapIds(List<String> ids, Map<String, String> idMap) =>
      ids.map((id) => idMap[id] ?? id).toList();

  @visibleForTesting
  Future<Campaign> parseAndSaveForTesting(String jsonContent) =>
      _parseAndSave(jsonContent);
}
