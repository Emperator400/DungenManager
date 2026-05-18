import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

import '../database/core/database_connection.dart';
import '../database/repositories/campaign_model_repository.dart';
import '../database/repositories/ort_model_repository.dart';
import '../database/repositories/quest_model_repository.dart';
import '../database/repositories/scene_model_repository.dart';
import '../database/repositories/session_model_repository.dart';
import '../database/repositories/sound_model_repository.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../models/campaign.dart';
import '../models/ort.dart';
import '../models/quest.dart';
import '../models/scene.dart';
import '../models/session.dart';
import '../models/sound.dart';
import '../models/wiki_entry.dart';
import '../services/uuid_service.dart';
import 'exceptions/service_exceptions.dart';

class CampaignTemplateExportImportService {
  CampaignTemplateExportImportService({
    CampaignModelRepository? campaignRepository,
    OrtModelRepository? ortRepository,
    QuestModelRepository? questRepository,
    SessionModelRepository? sessionRepository,
    SceneModelRepository? sceneRepository,
    WikiEntryModelRepository? wikiRepository,
    SoundModelRepository? soundRepository,
  })  : _campaignRepository = campaignRepository ?? CampaignModelRepository(DatabaseConnection.instance),
        _ortRepository = ortRepository ?? OrtModelRepository(DatabaseConnection.instance),
        _questRepository = questRepository ?? QuestModelRepository(DatabaseConnection.instance),
        _sessionRepository = sessionRepository ?? SessionModelRepository(DatabaseConnection.instance),
        _sceneRepository = sceneRepository ?? SceneModelRepository(DatabaseConnection.instance),
        _wikiRepository = wikiRepository ?? WikiEntryModelRepository(DatabaseConnection.instance),
        _soundRepository = soundRepository ?? SoundModelRepository(DatabaseConnection.instance);

  static const _formatKey = 'dungenmanager_campaign_template';
  static const _version = '2.0';
  static const _dataFileName = 'campaign.json';
  static const _fileExtension = 'DMpack';

  final CampaignModelRepository _campaignRepository;
  final OrtModelRepository _ortRepository;
  final QuestModelRepository _questRepository;
  final SessionModelRepository _sessionRepository;
  final SceneModelRepository _sceneRepository;
  final WikiEntryModelRepository _wikiRepository;
  final SoundModelRepository _soundRepository;

  // ── Export ────────────────────────────────────────────────────────────────

  /// Exportiert eine Vorlage als .DMpack-Datei (ZIP mit JSON + eingebetteten Dateien).
  /// Gibt den Dateipfad zurück.
  // Gibt null zurück wenn der Nutzer den Speicher-Dialog abbricht.
  Future<ServiceResult<String?>> exportTemplate(String campaignId) =>
      performServiceOperation('exportTemplate', () async {
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

        final archive = Archive();

        // Serialisiere Campaign mit Dateipfaden durch ZIP-relative Pfade ersetzt
        final campaignMap = campaign.toDatabaseMap();
        campaignMap['karte_image_path'] = await _addImageToArchive(
            archive, 'files/images/karte', campaign.karteImagePath);
        campaignMap['verlaufs_karte_image_path'] = await _addImageToArchive(
            archive, 'files/images/verlauf', campaign.verlaufsKarteImagePath);

        // Orte mit Karten-Bildern
        final orteMaps = <Map<String, dynamic>>[];
        for (final o in orte) {
          final map = o.toDatabaseMap();
          map['map_image_path'] = await _addImageToArchive(
              archive, 'files/images/ort_${o.id}', o.mapImagePath);
          orteMaps.add(map);
        }

        final payload = {
          'format': _formatKey,
          'version': _version,
          'exportedAt': DateTime.now().toIso8601String(),
          'campaign': campaignMap,
          'orte': orteMaps,
          'quests': quests.map((q) => q.toDatabaseMap()).toList(),
          'sessions': sessions.map((s) => s.toDatabaseMap()).toList(),
          'scenes': allScenes.map((sc) => sc.toDatabaseMap()).toList(),
          'wikiEntries': wikiEntries.map((w) => w.toDatabaseMap()).toList(),
          'sounds': <Map<String, dynamic>>[],
        };

        final jsonBytes = utf8.encode(const JsonEncoder.withIndent('  ').convert(payload));
        archive.addFile(ArchiveFile(_dataFileName, jsonBytes.length, jsonBytes));

        final zipBytes = ZipEncoder().encode(archive);
        if (zipBytes == null) {
          throw const DatabaseException('ZIP-Kodierung fehlgeschlagen', operation: 'exportTemplate');
        }

        final safeName = campaign.title
            .replaceAll(RegExp(r'[^\w\s\-]'), '')
            .trim()
            .replaceAll(' ', '_');

        final savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Vorlage speichern',
          fileName: '${safeName}_vorlage.$_fileExtension',
          type: FileType.custom,
          allowedExtensions: [_fileExtension],
        );

        if (savePath == null) {
          return null; // Nutzer hat Abbrechen gedrückt
        }

        final file = File(savePath);
        await file.writeAsBytes(zipBytes);
        return file.path;
      });

  // ── Import ────────────────────────────────────────────────────────────────

  /// Öffnet den Datei-Picker und importiert eine .DMpack- oder .json-Datei als Vorlage.
  Future<ServiceResult<Campaign>> importTemplate() =>
      performServiceOperation('importTemplate', () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: [_fileExtension, 'json'],
        );

        if (result == null || result.files.isEmpty) {
          throw const ValidationException('Keine Datei ausgewählt', operation: 'importTemplate');
        }

        final picked = result.files.first;
        final bytes = picked.bytes != null
            ? picked.bytes!
            : picked.path != null
                ? await File(picked.path!).readAsBytes()
                : throw const ValidationException(
                    'Datei konnte nicht gelesen werden',
                    operation: 'importTemplate',
                  );

        final name = picked.name.toLowerCase();
        if (name.endsWith('.json')) {
          return _parseAndSave(utf8.decode(bytes), extractedFilesDir: null);
        }
        return _importFromDMpack(bytes);
      });

  Future<Campaign> _importFromDMpack(List<int> bytes) async {
    final Archive archive;
    try {
      archive = ZipDecoder().decodeBytes(bytes);
    } catch (_) {
      throw const ValidationException('Ungültige DMpack-Datei', operation: 'importTemplate');
    }

    final jsonEntry = archive.files.where((f) => f.isFile && f.name == _dataFileName).firstOrNull;
    if (jsonEntry == null) {
      throw const ValidationException('DMpack enthält kein campaign.json', operation: 'importTemplate');
    }

    final content = utf8.decode(jsonEntry.content as List<int>);

    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory(
        '${tempDir.path}/dmpack_${DateTime.now().millisecondsSinceEpoch}');
    await extractDir.create(recursive: true);

    for (final file in archive.files) {
      if (!file.isFile || !file.name.startsWith('files/')) {
        continue;
      }
      final dest = File('${extractDir.path}/${file.name}');
      await dest.parent.create(recursive: true);
      await dest.writeAsBytes(file.content as List<int>);
    }

    try {
      return await _parseAndSave(content, extractedFilesDir: extractDir);
    } finally {
      extractDir.delete(recursive: true).ignore();
    }
  }

  Future<Campaign> _parseAndSave(
    String jsonContent, {
    required Directory? extractedFilesDir,
  }) async {
    final Map<String, dynamic> payload;
    try {
      payload = jsonDecode(jsonContent) as Map<String, dynamic>;
    } catch (_) {
      throw const ValidationException('Ungültiges JSON-Format', operation: 'importTemplate');
    }

    if (payload['format'] != _formatKey) {
      throw ValidationException(
        'Unbekanntes Format: ${payload['format']}',
        operation: 'importTemplate',
      );
    }

    final idMap = <String, String>{};
    final campaignMap = payload['campaign'] as Map<String, dynamic>;
    final newCampaignId = UuidService().generateId();
    idMap[campaignMap['id'] as String] = newCampaignId;

    final wikiMaps = (payload['wikiEntries'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final questMaps = (payload['quests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final ortMaps = (payload['orte'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final sessionMaps = (payload['sessions'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final sceneMaps = (payload['scenes'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final soundMaps = (payload['sounds'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    for (final m in wikiMaps) {
      idMap[m['id'] as String] = UuidService().generateId();
    }
    for (final m in questMaps) {
      idMap[m['id'] as String] = UuidService().generateId();
    }
    for (final m in ortMaps) {
      idMap[m['id'] as String] = UuidService().generateId();
    }
    for (final m in sessionMaps) {
      idMap[m['id'] as String] = UuidService().generateId();
    }
    for (final m in sceneMaps) {
      idMap[m['id'] as String] = UuidService().generateId();
    }
    for (final m in soundMaps) {
      idMap[m['id'] as String] = UuidService().generateId();
    }

    final now = DateTime.now();

    // Persistentes Medienverzeichnis für importierte Dateien
    Directory? mediaDir;
    if (extractedFilesDir != null) {
      final docsDir = await getApplicationDocumentsDirectory();
      mediaDir = Directory('${docsDir.path}/dungenmanager/media/$newCampaignId');
      await mediaDir.create(recursive: true);
    }

    // ── WikiEntries ────────────────────────────────────────────────────────
    final copiedWikiIds = <String>[];
    for (final m in wikiMaps) {
      final w = WikiEntry.fromDatabaseMap(m);
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

    // ── Quests ────────────────────────────────────────────────────────────
    final copiedQuestIds = <String>[];
    for (final m in questMaps) {
      final q = Quest.fromDatabaseMap(m);
      final newId = idMap[q.id]!;
      copiedQuestIds.add(newId);
      await _questRepository.create(q.copyWith(
        id: newId,
        campaignId: newCampaignId,
        status: QuestStatus.active,
        linkedWikiEntryIds: _remapIds(q.linkedWikiEntryIds, idMap),
      ));
    }

    // ── Orte ──────────────────────────────────────────────────────────────
    for (final m in ortMaps) {
      final o = Ort.fromDatabaseMap(m);
      final mapImagePath = await _resolveImportedFile(
          m['map_image_path'] as String?, extractedFilesDir, mediaDir);
      await _ortRepository.create(o.copyWith(
        id: idMap[o.id],
        campaignId: newCampaignId,
        templateOrtId: o.id,
        connectedOrtIds: _remapIds(o.connectedOrtIds, idMap),
        parentOrtId: o.parentOrtId != null ? idMap[o.parentOrtId] : null,
        lastVisitedAt: null,
        memory: null,
        mapImagePath: mapImagePath,
      ));
    }

    // ── Sessions + Scenes ─────────────────────────────────────────────────
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
          linkedCharacterIds: [],
        ));
      }

      await _sessionRepository.create(s.copyWith(
        id: newSessionId,
        campaignId: newCampaignId,
        sceneIds: copiedSceneIds,
        characterTrackingIds: [],
        questProgressIds: [],
      ));
    }

    // ── Sounds ────────────────────────────────────────────────────────────
    for (final m in soundMaps) {
      final oldId = m['id'] as String;
      final newId = idMap[oldId]!;
      final resolvedPath = await _resolveImportedFile(
          m['file_path'] as String?, extractedFilesDir, mediaDir);
      final updatedMap = Map<String, dynamic>.from(m)
        ..['id'] = newId
        ..['file_path'] = resolvedPath ?? m['file_path'];
      await _soundRepository.create(Sound.fromDatabaseMap(updatedMap));
    }

    // ── Campaign ──────────────────────────────────────────────────────────
    final karteImagePath = await _resolveImportedFile(
        campaignMap['karte_image_path'] as String?, extractedFilesDir, mediaDir);
    final verlaufsKarteImagePath = await _resolveImportedFile(
        campaignMap['verlaufs_karte_image_path'] as String?, extractedFilesDir, mediaDir);

    final origCampaign = Campaign.fromDatabaseMap(campaignMap);
    return _campaignRepository.create(Campaign(
      id: newCampaignId,
      title: origCampaign.title,
      description: origCampaign.description,
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
      karteImagePath: karteImagePath,
      verlaufsKarteImagePath: verlaufsKarteImagePath,
    ));
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  /// Kopiert eine Datei aus dem extrahierten Temp-Verzeichnis ins persistente Medienverzeichnis.
  /// Gibt null zurück wenn der Pfad kein ZIP-relativer Pfad ist oder die Datei fehlt.
  Future<String?> _resolveImportedFile(
    String? zipRelativePath,
    Directory? extractedFilesDir,
    Directory? mediaDir,
  ) async {
    if (zipRelativePath == null ||
        !zipRelativePath.startsWith('files/') ||
        extractedFilesDir == null ||
        mediaDir == null) {
      return zipRelativePath; // absoluter Pfad (Legacy JSON) – unverändert
    }

    final srcFile = File('${extractedFilesDir.path}/$zipRelativePath');
    if (!srcFile.existsSync()) {
      return null;
    }

    final subPath = zipRelativePath.replaceFirst('files/', '');
    final destFile = File('${mediaDir.path}/$subPath');
    await destFile.parent.create(recursive: true);
    await srcFile.copy(destFile.path);
    return destFile.path;
  }

  /// Fügt ein Bild der Archive hinzu. Gibt den ZIP-internen Pfad zurück, oder null wenn fehlt.
  Future<String?> _addImageToArchive(
    Archive archive,
    String zipPathWithoutExt,
    String? filePath,
  ) async {
    if (filePath == null) {
      return null;
    }
    final zipPath = '$zipPathWithoutExt.${_ext(filePath)}';
    final added = await _addFileToArchive(archive, zipPath, filePath);
    return added ? zipPath : null;
  }

  /// Liest eine Datei vom Dateisystem und fügt sie der Archive hinzu.
  Future<bool> _addFileToArchive(Archive archive, String zipPath, String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return false;
      }
      final bytes = await file.readAsBytes();
      archive.addFile(ArchiveFile(zipPath, bytes.length, bytes));
      return true;
    } catch (e) {
      debugPrint('[DMpack] Datei übersprungen: $filePath — $e');
      return false;
    }
  }

  String _ext(String filePath) {
    final parts = filePath.split('.');
    return parts.length > 1 ? parts.last.toLowerCase() : 'bin';
  }

  List<String> _remapIds(List<String> ids, Map<String, String> idMap) =>
      ids.map((id) => idMap[id] ?? id).toList();

  @visibleForTesting
  Future<Campaign> parseAndSaveForTesting(String jsonContent) =>
      _parseAndSave(jsonContent, extractedFilesDir: null);
}
