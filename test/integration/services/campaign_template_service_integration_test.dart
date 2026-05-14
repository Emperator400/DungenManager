// Integration-Tests für das Kampagnen-Vorlagen-System.
//
// Abgedeckt:
//   • CampaignService.createCopyFromTemplate()  — Deep-Copy + ID-Remapping
//   • CampaignTemplateExportImportService        — Export-Format + Import-Round-Trip

import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:dungen_manager/database/core/database_connection.dart';
import 'package:dungen_manager/database/repositories/campaign_model_repository.dart';
import 'package:dungen_manager/database/repositories/ort_model_repository.dart';
import 'package:dungen_manager/database/repositories/quest_model_repository.dart';
import 'package:dungen_manager/database/repositories/session_model_repository.dart';
import 'package:dungen_manager/database/repositories/scene_model_repository.dart';
import 'package:dungen_manager/database/repositories/wiki_entry_model_repository.dart';
import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/models/ort.dart';
import 'package:dungen_manager/models/quest.dart';
import 'package:dungen_manager/models/scene.dart';
import 'package:dungen_manager/models/session.dart';
import 'package:dungen_manager/models/wiki_entry.dart';
import 'package:dungen_manager/services/campaign_service.dart';
import 'package:dungen_manager/services/campaign_template_export_import_service.dart';
import 'package:dungen_manager/services/uuid_service.dart';

import '../../test_helpers/test_setup.dart';

// ── Fixture-Helfer ────────────────────────────────────────────────────────────

Campaign _makeTemplate({String? id, String title = 'Test-Vorlage'}) {
  final now = DateTime.now();
  return Campaign(
    id: id ?? UuidService().generateId(),
    title: title,
    description: 'Beschreibung',
    isTemplate: true,
    createdAt: now,
    updatedAt: now,
  );
}

Ort _makeOrt(String campaignId, {String? id, List<String> connectedOrtIds = const []}) {
  final now = DateTime.now();
  return Ort(
    id: id ?? UuidService().generateId(),
    campaignId: campaignId,
    name: 'Ort ${id ?? "X"}',
    createdAt: now,
    updatedAt: now,
    connectedOrtIds: connectedOrtIds,
    lastVisitedAt: DateTime.now(),
    memory: 'Erinnerung',
  );
}

Quest _makeQuest(String campaignId, {String? id, List<String> linkedWikiEntryIds = const []}) {
  final now = DateTime.now();
  return Quest(
    id: id ?? UuidService().generateId(),
    title: 'Quest ${id ?? "X"}',
    description: 'Beschreibung',
    campaignId: campaignId,
    createdAt: now,
    updatedAt: now,
    status: QuestStatus.completed,
    completedAt: now,
    linkedWikiEntryIds: linkedWikiEntryIds,
  );
}

WikiEntry _makeWiki(String campaignId, {String? id, String? parentId, List<String> childIds = const []}) {
  final now = DateTime.now();
  return WikiEntry(
    id: id ?? UuidService().generateId(),
    title: 'Wiki ${id ?? "X"}',
    content: 'Inhalt',
    entryType: WikiEntryType.Lore,
    tags: const [],
    createdAt: now,
    updatedAt: now,
    campaignId: campaignId,
    parentId: parentId,
    childIds: childIds,
    isMarkdown: false,
    isFavorite: true,
  );
}

Session _makeSession(String campaignId, {String? id}) {
  return Session(
    id: id,
    campaignId: campaignId,
    title: 'Session ${id ?? "X"}',
    characterTrackingIds: ['hero-1', 'hero-2'],
    questProgressIds: ['qp-1'],
    activeSceneId: 'old-scene',
    startedAt: DateTime.now(),
    completedAt: DateTime.now(),
  );
}

Scene _makeScene(String sessionId, {
  String? id,
  List<String> linkedQuestIds = const [],
  List<String> linkedWikiEntryIds = const [],
}) {
  return Scene(
    id: id,
    sessionId: sessionId,
    orderIndex: 0,
    name: 'Szene ${id ?? "X"}',
    linkedQuestIds: linkedQuestIds,
    linkedWikiEntryIds: linkedWikiEntryIds,
    linkedEncounterId: 'enc-old',
    linkedCharacterIds: ['char-1'],
  );
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  late CampaignModelRepository campaignRepo;
  late OrtModelRepository ortRepo;
  late QuestModelRepository questRepo;
  late SessionModelRepository sessionRepo;
  late SceneModelRepository sceneRepo;
  late WikiEntryModelRepository wikiRepo;
  late CampaignService campaignService;
  late CampaignTemplateExportImportService exportImportService;

  setUp(() async {
    await setUpTestDatabase();
    final db = DatabaseConnection.instance;
    campaignRepo = CampaignModelRepository(db);
    ortRepo = OrtModelRepository(db);
    questRepo = QuestModelRepository(db);
    sessionRepo = SessionModelRepository(db);
    sceneRepo = SceneModelRepository(db);
    wikiRepo = WikiEntryModelRepository(db);
    campaignService = CampaignService(
      campaignRepository: campaignRepo,
      ortRepository: ortRepo,
      questRepository: questRepo,
      sessionRepository: sessionRepo,
      sceneRepository: sceneRepo,
      wikiRepository: wikiRepo,
    );
    exportImportService = CampaignTemplateExportImportService(
      campaignRepository: campaignRepo,
      ortRepository: ortRepo,
      questRepository: questRepo,
      sessionRepository: sessionRepo,
      sceneRepository: sceneRepo,
      wikiRepository: wikiRepo,
    );
  });

  tearDown(() async => tearDownTestDatabase());

  // ── createCopyFromTemplate ────────────────────────────────────────────────

  group('CampaignService.createCopyFromTemplate', () {
    test('lehnt Nicht-Vorlage ab', () async {
      final notATemplate = await campaignRepo.create(
        _makeTemplate().copyWith(isTemplate: false),
      );

      final result = await campaignService.createCopyFromTemplate(notATemplate, title: 'Kopie');

      expect(result.isSuccess, false);
    });

    test('erstellt Kopie mit neuer ID und korrekten Metadaten', () async {
      final template = await campaignRepo.create(_makeTemplate(title: 'Meine Vorlage'));

      final result = await campaignService.createCopyFromTemplate(template, title: 'Gruppe Alpha');

      expect(result.isSuccess, true);
      final copy = result.data!;
      expect(copy.id, isNot(template.id));
      expect(copy.title, 'Gruppe Alpha');
      expect(copy.isTemplate, false);
      expect(copy.templateId, template.id);
      expect(copy.status, CampaignStatus.planning);
    });

    test('kopiert WikiEntries mit neuen IDs und isFavorite = false', () async {
      final template = await campaignRepo.create(_makeTemplate());
      await wikiRepo.create(_makeWiki(template.id));
      await wikiRepo.create(_makeWiki(template.id));

      final copy = (await campaignService.createCopyFromTemplate(template, title: 'Kopie')).data!;

      final templateWiki = await wikiRepo.findByCampaign(template.id);
      final copyWiki = await wikiRepo.findByCampaign(copy.id);
      expect(copyWiki.length, 2);

      final templateIds = templateWiki.map((w) => w.id).toSet();
      for (final w in copyWiki) {
        expect(templateIds, isNot(contains(w.id)));
        expect(w.isFavorite, false);
      }
    });

    test('remappt WikiEntry parentId und childIds', () async {
      final template = await campaignRepo.create(_makeTemplate());
      final parentId = UuidService().generateId();
      final childId = UuidService().generateId();
      await wikiRepo.create(_makeWiki(template.id, id: parentId, childIds: [childId]));
      await wikiRepo.create(_makeWiki(template.id, id: childId, parentId: parentId));

      final copy = (await campaignService.createCopyFromTemplate(template, title: 'Kopie')).data!;

      final copyWiki = await wikiRepo.findByCampaign(copy.id);
      final parent = copyWiki.firstWhere((w) => w.parentId == null);
      final child = copyWiki.firstWhere((w) => w.parentId != null);

      // parentId und childIds zeigen auf neue IDs
      expect(parent.childIds, contains(child.id));
      expect(child.parentId, parent.id);
      // alte IDs dürfen nicht auftauchen
      expect(parent.childIds, isNot(contains(childId)));
      expect(child.parentId, isNot(childId));
    });

    test('kopiert Quests mit zurückgesetztem Status', () async {
      final template = await campaignRepo.create(_makeTemplate());
      final wiki = await wikiRepo.create(_makeWiki(template.id));
      final quest = await questRepo.create(_makeQuest(template.id, linkedWikiEntryIds: [wiki.id]));

      final copy = (await campaignService.createCopyFromTemplate(template, title: 'Kopie')).data!;

      final copyQuests = await questRepo.findByCampaign(copy.id);
      expect(copyQuests.length, 1);
      final q = copyQuests.first;
      expect(q.id, isNot(quest.id));
      expect(q.status, QuestStatus.active);
      expect(q.completedAt, isNull);

      // linkedWikiEntryIds zeigt auf neue Wiki-ID
      final copyWiki = await wikiRepo.findByCampaign(copy.id);
      expect(q.linkedWikiEntryIds, contains(copyWiki.first.id));
      expect(q.linkedWikiEntryIds, isNot(contains(wiki.id)));
    });

    test('remappt Ort.connectedOrtIds und löscht Runtime-State', () async {
      final template = await campaignRepo.create(_makeTemplate());
      final idA = UuidService().generateId();
      final idB = UuidService().generateId();
      await ortRepo.create(_makeOrt(template.id, id: idA, connectedOrtIds: [idB]));
      await ortRepo.create(_makeOrt(template.id, id: idB, connectedOrtIds: [idA]));

      final copy = (await campaignService.createCopyFromTemplate(template, title: 'Kopie')).data!;

      final copyOrte = await ortRepo.findByCampaign(copy.id);
      final newIds = copyOrte.map((o) => o.id).toSet();
      expect(copyOrte.length, 2);

      for (final o in copyOrte) {
        expect(o.lastVisitedAt, isNull);
        expect(o.memory, isNull);
        for (final connId in o.connectedOrtIds) {
          expect(newIds, contains(connId));
          expect(connId, isNot(idA));
          expect(connId, isNot(idB));
        }
      }
    });

    test('kopiert Sessions mit gecleartem Runtime-State', () async {
      final template = await campaignRepo.create(_makeTemplate());
      final session = await sessionRepo.create(_makeSession(template.id));

      final copy = (await campaignService.createCopyFromTemplate(template, title: 'Kopie')).data!;

      final copySessions = await sessionRepo.findByCampaign(copy.id);
      expect(copySessions.length, 1);
      final s = copySessions.first;
      expect(s.id, isNot(session.id));
      expect(s.characterTrackingIds, isEmpty);
      expect(s.questProgressIds, isEmpty);
      expect(s.activeSceneId, isNull);
      expect(s.startedAt, isNull);
      expect(s.completedAt, isNull);
    });

    test('remappt Scene.linkedQuestIds und löscht Encounter/Character-Links', () async {
      final template = await campaignRepo.create(_makeTemplate());
      final quest = await questRepo.create(_makeQuest(template.id));
      final wiki = await wikiRepo.create(_makeWiki(template.id));
      final session = await sessionRepo.create(_makeSession(template.id));
      await sceneRepo.create(_makeScene(
        session.id,
        linkedQuestIds: [quest.id],
        linkedWikiEntryIds: [wiki.id],
      ));

      final copy = (await campaignService.createCopyFromTemplate(template, title: 'Kopie')).data!;

      final copySessions = await sessionRepo.findByCampaign(copy.id);
      final copyScenes = await sceneRepo.findBySession(copySessions.first.id);
      expect(copyScenes.length, 1);

      final sc = copyScenes.first;
      expect(sc.linkedEncounterId, isNull);
      expect(sc.linkedCharacterIds, isEmpty);

      final copyQuests = await questRepo.findByCampaign(copy.id);
      final copyWiki = await wikiRepo.findByCampaign(copy.id);
      expect(sc.linkedQuestIds, contains(copyQuests.first.id));
      expect(sc.linkedWikiEntryIds, contains(copyWiki.first.id));
      expect(sc.linkedQuestIds, isNot(contains(quest.id)));
      expect(sc.linkedWikiEntryIds, isNot(contains(wiki.id)));
    });

    test('Originalvorlage bleibt nach dem Kopieren unverändert', () async {
      final template = await campaignRepo.create(_makeTemplate());
      final ortId = UuidService().generateId();
      await ortRepo.create(_makeOrt(template.id, id: ortId));
      await questRepo.create(_makeQuest(template.id));
      await wikiRepo.create(_makeWiki(template.id));

      await campaignService.createCopyFromTemplate(template, title: 'Kopie');

      final originalOrte = await ortRepo.findByCampaign(template.id);
      expect(originalOrte.length, 1);
      expect(originalOrte.first.id, ortId);

      final originalTemplate = await campaignRepo.findById(template.id);
      expect(originalTemplate!.isTemplate, true);
    });
  });

  // ── CampaignTemplateExportImportService ──────────────────────────────────

  group('CampaignTemplateExportImportService', () {
    Future<Campaign> _buildFullTemplate() async {
      final template = await campaignRepo.create(_makeTemplate(title: 'Export-Vorlage'));
      final wiki = await wikiRepo.create(_makeWiki(template.id));
      await questRepo.create(_makeQuest(template.id, linkedWikiEntryIds: [wiki.id]));
      await ortRepo.create(_makeOrt(template.id, id: UuidService().generateId()));
      final session = await sessionRepo.create(_makeSession(template.id));
      await sceneRepo.create(_makeScene(session.id));
      return template;
    }

    test('exportTemplate erstellt eine Datei', () async {
      final template = await _buildFullTemplate();

      final result = await exportImportService.exportTemplate(template.id);

      expect(result.isSuccess, true);
      final file = File(result.data!);
      expect(file.existsSync(), true);
      await file.delete();
    });

    test('exportierte Datei enthält valides JSON mit korrektem Format-Schlüssel', () async {
      final template = await _buildFullTemplate();
      final file = File((await exportImportService.exportTemplate(template.id)).data!);

      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(json['format'], 'dungenmanager_campaign_template');
      expect(json['version'], '1.0');
      expect(json['exportedAt'], isA<String>());

      await file.delete();
    });

    test('exportierte JSON enthält alle Entitäten', () async {
      final template = await _buildFullTemplate();
      final file = File((await exportImportService.exportTemplate(template.id)).data!);

      final json = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect((json['campaign'] as Map).isNotEmpty, true);
      expect((json['wikiEntries'] as List).length, 1);
      expect((json['quests'] as List).length, 1);
      expect((json['orte'] as List).length, 1);
      expect((json['sessions'] as List).length, 1);
      expect((json['scenes'] as List).length, 1);

      await file.delete();
    });

    test('Import-Round-Trip: neue Kampagne mit neuen IDs und isTemplate = true', () async {
      final template = await _buildFullTemplate();
      final file = File((await exportImportService.exportTemplate(template.id)).data!);
      final content = await file.readAsString();

      final imported = await exportImportService.parseAndSaveForTesting(content);

      expect(imported.id, isNot(template.id));
      expect(imported.title, template.title);
      expect(imported.isTemplate, true);

      // Alle Orte haben neue IDs
      final importedOrte = await ortRepo.findByCampaign(imported.id);
      final originalOrte = await ortRepo.findByCampaign(template.id);
      final originalOrtIds = originalOrte.map((o) => o.id).toSet();
      expect(importedOrte.length, originalOrte.length);
      for (final o in importedOrte) {
        expect(originalOrtIds, isNot(contains(o.id)));
      }

      await file.delete();
    });

    test('Import-Round-Trip: Quest-Status wird zurückgesetzt und Cross-References remappt', () async {
      final template = await campaignRepo.create(_makeTemplate());
      final questId = UuidService().generateId();
      final quest = await questRepo.create(_makeQuest(template.id, id: questId));
      final session = await sessionRepo.create(_makeSession(template.id));
      await sceneRepo.create(_makeScene(session.id, linkedQuestIds: [quest.id]));

      final file = File((await exportImportService.exportTemplate(template.id)).data!);
      final imported = await exportImportService.parseAndSaveForTesting(
        await file.readAsString(),
      );

      // Quest-Status zurückgesetzt
      final importedQuests = await questRepo.findByCampaign(imported.id);
      for (final q in importedQuests) {
        expect(q.status, QuestStatus.active);
        expect(q.completedAt, isNull);
      }

      // Scene.linkedQuestIds zeigt auf neue IDs
      final importedSessions = await sessionRepo.findByCampaign(imported.id);
      final importedScenes = await sceneRepo.findBySession(importedSessions.first.id);
      final importedQuestIds = importedQuests.map((q) => q.id).toSet();
      for (final sc in importedScenes) {
        for (final qid in sc.linkedQuestIds) {
          expect(importedQuestIds, contains(qid));
          expect(qid, isNot(questId));
        }
      }

      await file.delete();
    });
  });
}
