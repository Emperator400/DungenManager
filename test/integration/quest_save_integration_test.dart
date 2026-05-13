import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/quest.dart';
import 'package:dungen_manager/database/repositories/quest_model_repository.dart';
import 'package:dungen_manager/database/core/database_connection.dart';
import '../test_helpers/test_setup.dart';

/// Integration-Test für Quest CRUD über QuestModelRepository.
///
/// Deckt den Kernbug ab, bei dem alte Quests mit UUID-String-IDs
/// als id=0 geladen wurden und deshalb nicht gespeichert werden konnten.
void main() {
  group('Quest Save Integration Tests', () {
    late QuestModelRepository repo;

    setUp(() async {
      await setUpTestDatabase();
      repo = QuestModelRepository(DatabaseConnection.instance);
    });

    tearDown(() async {
      await tearDownTestDatabase();
    });

    test('Quest.create() erzeugt eine gültige String-UUID', () {
      final quest = Quest.create(title: 'Test', description: 'Beschreibung');
      expect(quest.id, isNotEmpty);
      expect(quest.id, isA<String>());
      // UUID-Format: 8-4-4-4-12 Zeichen mit Bindestrichen
      expect(quest.id.length, greaterThan(10));
    });

    test('Speichert einen neuen Quest und liest ihn zurück', () async {
      final quest = Quest.create(
        title: 'Die Höhle des Drachen',
        description: 'Erkundet die gefährliche Drachenhöhle',
        questType: QuestType.main,
        difficulty: QuestDifficulty.hard,
      );

      final saved = await repo.create(quest);

      expect(saved.id, equals(quest.id));
      expect(saved.title, equals('Die Höhle des Drachen'));
      expect(saved.questType, equals(QuestType.main));
      expect(saved.difficulty, equals(QuestDifficulty.hard));
    });

    test('Aktualisiert einen bestehenden Quest', () async {
      final quest = Quest.create(
        title: 'Altes Abenteuer',
        description: 'Irgendwas passiert',
        status: QuestStatus.active,
      );
      await repo.create(quest);

      final updated = quest.copyWith(
        title: 'Neues Abenteuer',
        status: QuestStatus.completed,
        updatedAt: DateTime.now(),
      );
      final saved = await repo.update(updated);

      expect(saved.title, equals('Neues Abenteuer'));
      expect(saved.status, equals(QuestStatus.completed));
    });

    test('Löscht einen Quest erfolgreich', () async {
      final quest = Quest.create(title: 'Zu löschen', description: 'x');
      await repo.create(quest);

      await repo.delete(quest.id);

      final found = await repo.findById(quest.id);
      expect(found, isNull);
    });

    test('Mehrere Quests können gleichzeitig existieren', () async {
      for (int i = 0; i < 5; i++) {
        await repo.create(Quest.create(
          title: 'Quest $i',
          description: 'Beschreibung $i',
        ));
      }

      final all = await repo.findAll();
      expect(all.length, equals(5));
    });

    test('findById mit UUID-String-ID funktioniert korrekt', () async {
      final quest = Quest.create(title: 'Gesuchte Quest', description: 'y');
      await repo.create(quest);

      final found = await repo.findById(quest.id);

      expect(found, isNotNull);
      expect(found!.id, equals(quest.id));
      expect(found.title, equals('Gesuchte Quest'));
    });

    test('Update ändert nur den angegebenen Quest (nicht andere)', () async {
      final q1 = await repo.create(Quest.create(title: 'Quest A', description: 'a'));
      final q2 = await repo.create(Quest.create(title: 'Quest B', description: 'b'));

      await repo.update(q1.copyWith(title: 'Quest A (geändert)', updatedAt: DateTime.now()));

      final reloaded2 = await repo.findById(q2.id);
      expect(reloaded2!.title, equals('Quest B'));
    });

    test('Quest-Status-Wechsel bleibt nach Reload erhalten', () async {
      final quest = await repo.create(Quest.create(
        title: 'Status-Test',
        description: 'z',
        status: QuestStatus.active,
      ));

      await repo.update(quest.copyWith(
        status: QuestStatus.completed,
        completedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final reloaded = await repo.findById(quest.id);
      expect(reloaded!.status, equals(QuestStatus.completed));
    });

    test('Favorit-Status bleibt nach Reload erhalten', () async {
      final quest = await repo.create(Quest.create(
        title: 'Favorit-Test',
        description: 'z',
        isFavorite: false,
      ));

      await repo.update(quest.copyWith(
        isFavorite: true,
        updatedAt: DateTime.now(),
      ));

      final reloaded = await repo.findById(quest.id);
      expect(reloaded!.isFavorite, isTrue);
    });

    test('Quest-Serialisierung: fromDatabaseMap liest String-ID korrekt', () {
      // Simuliert das Laden eines alten Quests mit UUID als String aus der DB
      final map = {
        'id': 'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        'title': 'Alter Quest',
        'description': 'Aus altem DB-Format',
        'status': 'active',
        'quest_type': 'side',
        'difficulty': 'medium',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'is_favorite': 0,
        'campaign_id': null,
        'location': null,
        'recommended_level': null,
        'estimated_duration_hours': null,
        'tags': null,
        'rewards': null,
        'involved_npcs': null,
        'linked_wiki_entry_ids': null,
        'completed_at': null,
      };

      final quest = Quest.fromDatabaseMap(map);

      // Früher: int.tryParse('a1b2c3d4-...') = 0 → Bug
      // Jetzt: String bleibt String → korrekt
      expect(quest.id, equals('a1b2c3d4-e5f6-7890-abcd-ef1234567890'));
      expect(quest.title, equals('Alter Quest'));
    });

    test('Zwei verschiedene Quests haben unterschiedliche IDs', () {
      final q1 = Quest.create(title: 'A', description: 'x');
      final q2 = Quest.create(title: 'B', description: 'y');
      expect(q1.id, isNot(equals(q2.id)));
    });
  });
}
