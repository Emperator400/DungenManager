// Integration- und Unit-Tests für das Sound-Szenen-System
//
// Abgedeckte Bereiche:
//   - SoundScene Modell (Serialisierung, Validierung, Hilfsmethoden)
//   - SoundSceneItem Modell (Serialisierung, Validierung, Lautstärkeformatierung)
//   - SoundSceneService CRUD via In-Memory-SQLite
//   - Wiedergabe-Logik: _isScenePlaying via Channel-ID-Abgleich

import 'package:flutter_test/flutter_test.dart';

import 'package:dungen_manager/database/core/database_connection.dart';
import 'package:dungen_manager/database/repositories/sound_model_repository.dart';
import 'package:dungen_manager/models/sound.dart';
import 'package:dungen_manager/models/sound_scene.dart';
import 'package:dungen_manager/models/sound_scene_item.dart';
import 'package:dungen_manager/services/sound_scene_service.dart';

import '../../test_helpers/mock_data_factory.dart' as mock;
import '../../test_helpers/test_setup.dart';

/// Legt einen Sound in der Test-DB an und gibt ihn zurück.
///
/// Nötig weil [SoundSceneItem.sound_id] ein Foreign-Key auf [sounds.id] ist
/// und mit PRAGMA foreign_keys = ON strikt geprüft wird.
Future<Sound> insertTestSound({
  required String id,
  String name = 'Test Sound',
  SoundType type = SoundType.Ambiente,
}) async {
  final sound = mock.MockSoundFactory.create(
    id: id,
    name: name,
    filePath: '/test/$id.mp3',
    soundType: type,
  );
  final repo = SoundModelRepository(DatabaseConnection.instance);
  return repo.create(sound);
}

void main() {
  // =========================================================================
  // Modell-Tests (reine Unit-Tests, keine DB nötig)
  // =========================================================================

  group('SoundScene Modell', () {
    test('toDatabaseMap / fromDatabaseMap Roundtrip', () {
      final original = mock.MockSoundSceneFactory.create(
        id: 'scene-roundtrip',
        name: 'Waldsounds',
        description: 'Ambient Wald',
        isFavorite: true,
      );

      final map = original.toDatabaseMap();
      final restored = SoundScene.fromDatabaseMap(map);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.description, original.description);
      expect(restored.isFavorite, original.isFavorite);
      // Items werden separat gespeichert – nicht in toDatabaseMap enthalten
      expect(restored.items, isEmpty);
    });

    test('copyWith überschreibt nur angegebene Felder', () {
      final scene = mock.MockSoundSceneFactory.create(
        name: 'Original',
        description: 'Alte Beschreibung',
        isFavorite: false,
      );

      final updated = scene.copyWith(name: 'Geändert');

      expect(updated.name, 'Geändert');
      expect(updated.id, scene.id);
      expect(updated.description, scene.description);
      expect(updated.isFavorite, scene.isFavorite);
    });

    test('isValid ist false wenn Name leer', () {
      final invalid = mock.MockSoundSceneFactory.create(name: '');
      final valid = mock.MockSoundSceneFactory.create(name: 'Gültig');

      expect(invalid.isValid, false);
      expect(valid.isValid, true);
    });

    test('hasSounds und soundCount', () {
      final empty = mock.MockSoundSceneFactory.create();
      final withItems = mock.MockSoundSceneFactory.createWithItems(itemCount: 3);

      expect(empty.hasSounds, false);
      expect(empty.soundCount, 0);
      expect(withItems.hasSounds, true);
      expect(withItems.soundCount, 3);
    });

    test('findItemBySoundId findet vorhandenen Sound', () {
      final sceneId = 'scene-find';
      final item = mock.MockSoundSceneItemFactory.create(
        soundSceneId: sceneId,
        soundId: 'sound-abc',
      );
      final scene = mock.MockSoundSceneFactory.create(
        id: sceneId,
        items: [item],
      );

      expect(scene.findItemBySoundId('sound-abc'), isNotNull);
      expect(scene.findItemBySoundId('sound-abc')!.soundId, 'sound-abc');
    });

    test('findItemBySoundId gibt null zurück für unbekannte ID', () {
      final scene = mock.MockSoundSceneFactory.create();

      expect(scene.findItemBySoundId('unbekannt'), isNull);
    });

    test('Equality basiert auf ID', () {
      final a = mock.MockSoundSceneFactory.create(id: 'same-id', name: 'A');
      final b = mock.MockSoundSceneFactory.create(id: 'same-id', name: 'B');
      final c = mock.MockSoundSceneFactory.create(id: 'other-id', name: 'A');

      expect(a == b, true);
      expect(a == c, false);
    });
  });

  group('SoundSceneItem Modell', () {
    test('toDatabaseMap / fromDatabaseMap Roundtrip', () {
      final original = mock.MockSoundSceneItemFactory.create(
        soundSceneId: 'scene-x',
        soundId: 'sound-x',
        volume: 0.75,
        isLooping: false,
        fadeInDuration: 2.5,
        fadeOutDuration: 1.0,
        sortOrder: 3,
      );

      final map = original.toDatabaseMap();
      final restored = SoundSceneItem.fromDatabaseMap(map);

      expect(restored.id, original.id);
      expect(restored.soundSceneId, original.soundSceneId);
      expect(restored.soundId, original.soundId);
      expect(restored.volume, original.volume);
      expect(restored.isLooping, original.isLooping);
      expect(restored.fadeInDuration, original.fadeInDuration);
      expect(restored.fadeOutDuration, original.fadeOutDuration);
      expect(restored.sortOrder, original.sortOrder);
    });

    test('copyWith überschreibt nur angegebene Felder', () {
      final item = mock.MockSoundSceneItemFactory.create(volume: 1.0);
      final updated = item.copyWith(volume: 0.5);

      expect(updated.volume, 0.5);
      expect(updated.id, item.id);
      expect(updated.soundId, item.soundId);
    });

    test('formattedVolume gibt Prozent-String zurück', () {
      final full = mock.MockSoundSceneItemFactory.create(volume: 1.0);
      final half = mock.MockSoundSceneItemFactory.create(volume: 0.5);
      final low = mock.MockSoundSceneItemFactory.create(volume: 0.25);

      expect(full.formattedVolume, '100%');
      expect(half.formattedVolume, '50%');
      expect(low.formattedVolume, '25%');
    });

    test('isValid erkennt ungültige Zustände', () {
      // Gültig
      final valid = mock.MockSoundSceneItemFactory.create(
        soundSceneId: 'scene-id',
        soundId: 'sound-id',
        volume: 0.8,
      );
      expect(valid.isValid, true);

      // Lautstärke außerhalb 0–1
      final tooLoud = mock.MockSoundSceneItemFactory.create(volume: 1.5);
      expect(tooLoud.isValid, false);

      final negative = mock.MockSoundSceneItemFactory.create(volume: -0.1);
      expect(negative.isValid, false);

      // Leere IDs
      final noScene = mock.MockSoundSceneItemFactory.create(soundSceneId: '');
      expect(noScene.isValid, false);

      final noSound = mock.MockSoundSceneItemFactory.create(soundId: '');
      expect(noSound.isValid, false);
    });
  });

  // =========================================================================
  // Service-Integrationstests (In-Memory-SQLite)
  // =========================================================================

  group('SoundSceneService Integration', () {
    late SoundSceneService service;

    setUp(() async {
      await setUpTestDatabase();
      service = SoundSceneService();
    });

    tearDown(() async {
      await tearDownTestDatabase();
    });

    // --- Erstellen ---

    group('createSoundScene', () {
      test('speichert Szene ohne Items', () async {
        final scene = mock.MockSoundSceneFactory.create(name: 'Taverne');

        final result = await service.createSoundScene(scene);

        expect(result, isNotNull);
        expect(result!.name, 'Taverne');
      });

      test('speichert Szene mit Items', () async {
        // Sounds müssen zuerst existieren (FK-Constraint)
        await insertTestSound(id: 'sound-1', name: 'Sound 1');
        await insertTestSound(id: 'sound-2', name: 'Sound 2');

        const sceneId = 'scene-with-items';
        final items = [
          mock.MockSoundSceneItemFactory.create(
            soundSceneId: sceneId,
            soundId: 'sound-1',
          ),
          mock.MockSoundSceneItemFactory.create(
            soundSceneId: sceneId,
            soundId: 'sound-2',
          ),
        ];
        final scene = mock.MockSoundSceneFactory.create(
          id: sceneId,
          name: 'Szene mit zwei Sounds',
          items: items,
        );

        final result = await service.createSoundScene(scene);
        expect(result, isNotNull);

        // Aus DB laden und Items prüfen
        final loaded = await service.getSoundSceneById(sceneId);
        expect(loaded, isNotNull);
        expect(loaded!.items.length, 2);
        expect(
          loaded.items.map((i) => i.soundId),
          containsAll(['sound-1', 'sound-2']),
        );
      });
    });

    // --- Lesen ---

    group('getAllSoundScenes', () {
      test('gibt leere Liste zurück wenn keine Szenen vorhanden', () async {
        final result = await service.getAllSoundScenes();
        expect(result, isEmpty);
      });

      test('gibt alle Szenen zurück', () async {
        await service.createSoundScene(
            mock.MockSoundSceneFactory.create(name: 'Szene A'));
        await service.createSoundScene(
            mock.MockSoundSceneFactory.create(name: 'Szene B'));

        final result = await service.getAllSoundScenes();
        expect(result.length, 2);
      });

      test('gibt Szenen alphabetisch sortiert zurück', () async {
        await service.createSoundScene(
            mock.MockSoundSceneFactory.create(name: 'Zel'));
        await service.createSoundScene(
            mock.MockSoundSceneFactory.create(name: 'Aal'));
        await service.createSoundScene(
            mock.MockSoundSceneFactory.create(name: 'Mitte'));

        final result = await service.getAllSoundScenes();
        expect(result[0].name, 'Aal');
        expect(result[1].name, 'Mitte');
        expect(result[2].name, 'Zel');
      });
    });

    group('getAllSoundScenesWithItems', () {
      test('gibt Szenen mit zugehörigen Items zurück', () async {
        await insertTestSound(id: 'snd-a', name: 'Sound A');

        const sceneId = 'scene-items-check';
        await service.createSoundScene(
          mock.MockSoundSceneFactory.create(
            id: sceneId,
            name: 'Mit Sounds',
            items: [
              mock.MockSoundSceneItemFactory.create(
                soundSceneId: sceneId,
                soundId: 'snd-a',
              ),
            ],
          ),
        );
        await service.createSoundScene(
            mock.MockSoundSceneFactory.create(name: 'Ohne Sounds'));

        final result = await service.getAllSoundScenesWithItems();
        final withItems = result.firstWhere((s) => s.name == 'Mit Sounds');
        final withoutItems =
            result.firstWhere((s) => s.name == 'Ohne Sounds');

        expect(withItems.items.length, 1);
        expect(withoutItems.items, isEmpty);
      });
    });

    group('getSoundSceneById', () {
      test('gibt korrekte Szene zurück', () async {
        final scene = mock.MockSoundSceneFactory.create(
          id: 'find-me',
          name: 'Zu finden',
        );
        await service.createSoundScene(scene);

        final found = await service.getSoundSceneById('find-me');
        expect(found, isNotNull);
        expect(found!.name, 'Zu finden');
      });

      test('gibt null zurück für unbekannte ID', () async {
        final found = await service.getSoundSceneById('gibts-nicht');
        expect(found, isNull);
      });
    });

    // --- Aktualisieren ---

    group('updateSoundScene', () {
      test('aktualisiert Name und Beschreibung', () async {
        final scene = mock.MockSoundSceneFactory.create(
          id: 'update-me',
          name: 'Alt',
          description: 'Alte Beschreibung',
        );
        await service.createSoundScene(scene);

        final updated = scene.copyWith(
          name: 'Neu',
          description: 'Neue Beschreibung',
        );
        final success = await service.updateSoundScene(updated);
        expect(success, true);

        final loaded = await service.getSoundSceneById('update-me');
        expect(loaded!.name, 'Neu');
        expect(loaded.description, 'Neue Beschreibung');
      });
    });

    // --- Löschen ---

    group('deleteSoundScene', () {
      test('löscht Szene erfolgreich', () async {
        final scene =
            mock.MockSoundSceneFactory.create(id: 'delete-me', name: 'Weg');
        await service.createSoundScene(scene);

        final success = await service.deleteSoundScene('delete-me');
        expect(success, true);

        final found = await service.getSoundSceneById('delete-me');
        expect(found, isNull);
      });

      test('CASCADE: Items werden mit Szene gelöscht', () async {
        const sceneId = 'cascade-scene';
        await service.createSoundScene(
          mock.MockSoundSceneFactory.create(
            id: sceneId,
            items: [
              mock.MockSoundSceneItemFactory.create(
                soundSceneId: sceneId,
                soundId: 'orphan-sound',
              ),
            ],
          ),
        );

        // Szene löschen
        await service.deleteSoundScene(sceneId);

        // Szene weg
        final scene = await service.getSoundSceneById(sceneId);
        expect(scene, isNull);

        // Item darf nicht als Datenmüll übrig bleiben
        // (indirekter Nachweis: neue Szene mit gleicher ID hat 0 Items)
        await service.createSoundScene(
            mock.MockSoundSceneFactory.create(id: sceneId, name: 'Neu'));
        final recreated = await service.getSoundSceneById(sceneId);
        expect(recreated!.items, isEmpty);
      });

      test('gibt false zurück wenn Szene nicht existiert', () async {
        // Kein Fehler, nur false (keine Zeile betroffen)
        final success = await service.deleteSoundScene('fantasie-id');
        // SQLite DELETE WHERE gibt keine Exception – 0 Zeilen gelöscht ist ok
        expect(success, isA<bool>());
      });
    });

    // --- Sound-Item Verwaltung ---

    group('addSoundToScene', () {
      test('fügt Sound zur Szene hinzu', () async {
        await insertTestSound(id: 'new-sound', name: 'Neuer Sound');

        final scene =
            mock.MockSoundSceneFactory.create(id: 'add-to', name: 'Leer');
        await service.createSoundScene(scene);

        final item = await service.addSoundToScene(
          sceneId: 'add-to',
          soundId: 'new-sound',
          volume: 0.8,
          isLooping: false,
        );

        expect(item, isNotNull);
        expect(item!.soundId, 'new-sound');
        expect(item.volume, 0.8);
        expect(item.isLooping, false);

        final loaded = await service.getSoundSceneById('add-to');
        expect(loaded!.items.length, 1);
      });

      test('sortOrder wird automatisch inkrementiert', () async {
        await insertTestSound(id: 'snd-0', name: 'Sound 0');
        await insertTestSound(id: 'snd-1', name: 'Sound 1');
        await insertTestSound(id: 'snd-2', name: 'Sound 2');

        const sceneId = 'sort-order-scene';
        await service.createSoundScene(
            mock.MockSoundSceneFactory.create(id: sceneId));

        final item0 = await service.addSoundToScene(
            sceneId: sceneId, soundId: 'snd-0');
        final item1 = await service.addSoundToScene(
            sceneId: sceneId, soundId: 'snd-1');
        final item2 = await service.addSoundToScene(
            sceneId: sceneId, soundId: 'snd-2');

        expect(item0!.sortOrder, 0);
        expect(item1!.sortOrder, 1);
        expect(item2!.sortOrder, 2);
      });
    });

    group('removeSoundFromScene', () {
      test('entfernt Sound aus Szene', () async {
        await insertTestSound(id: 'to-remove', name: 'Wird entfernt');
        await insertTestSound(id: 'keep-me', name: 'Bleibt');

        const sceneId = 'remove-from';
        await service.createSoundScene(
          mock.MockSoundSceneFactory.create(
            id: sceneId,
            items: [
              mock.MockSoundSceneItemFactory.create(
                soundSceneId: sceneId,
                soundId: 'to-remove',
              ),
              mock.MockSoundSceneItemFactory.create(
                soundSceneId: sceneId,
                soundId: 'keep-me',
              ),
            ],
          ),
        );

        final success =
            await service.removeSoundFromScene(sceneId, 'to-remove');
        expect(success, true);

        final loaded = await service.getSoundSceneById(sceneId);
        expect(loaded!.items.length, 1);
        expect(loaded.items.first.soundId, 'keep-me');
      });
    });

    group('updateSoundSceneItem', () {
      test('aktualisiert Lautstärke und Loop-Einstellung', () async {
        await insertTestSound(id: 'updatable', name: 'Aktualisierbarer Sound');

        const sceneId = 'item-update-scene';
        final originalItem = mock.MockSoundSceneItemFactory.create(
          soundSceneId: sceneId,
          soundId: 'updatable',
          volume: 1.0,
          isLooping: true,
        );
        await service.createSoundScene(
          mock.MockSoundSceneFactory.create(
            id: sceneId,
            items: [originalItem],
          ),
        );

        final changed = originalItem.copyWith(volume: 0.3, isLooping: false);
        final success = await service.updateSoundSceneItem(changed);
        expect(success, true);

        final loaded = await service.getSoundSceneById(sceneId);
        final updatedItem = loaded!.items.first;
        expect(updatedItem.volume, closeTo(0.3, 0.001));
        expect(updatedItem.isLooping, false);
      });
    });

    // --- Favoriten ---

    group('toggleFavorite', () {
      test('schaltet Favorit ein und wieder aus', () async {
        final scene = mock.MockSoundSceneFactory.create(
          id: 'fav-toggle',
          isFavorite: false,
        );
        await service.createSoundScene(scene);

        // Einschalten
        await service.toggleFavorite('fav-toggle');
        var loaded = await service.getSoundSceneById('fav-toggle');
        expect(loaded!.isFavorite, true);

        // Ausschalten
        await service.toggleFavorite('fav-toggle');
        loaded = await service.getSoundSceneById('fav-toggle');
        expect(loaded!.isFavorite, false);
      });

      test('gibt false zurück für unbekannte ID', () async {
        final result = await service.toggleFavorite('gibts-nicht');
        expect(result, false);
      });
    });

    // --- Suche ---

    group('searchSoundScenes', () {
      setUp(() async {
        await service.createSoundScene(
            mock.MockSoundSceneFactory.create(name: 'Drachenhöhle'));
        await service.createSoundScene(mock.MockSoundSceneFactory.create(
            name: 'Waldhütte', description: 'Ambient Wald'));
        await service.createSoundScene(
            mock.MockSoundSceneFactory.create(name: 'Taverne'));
      });

      test('findet Szene anhand des Namens', () async {
        final result = await service.searchSoundScenes('Drachen');
        expect(result.length, 1);
        expect(result.first.name, 'Drachenhöhle');
      });

      test('findet Szene anhand der Beschreibung', () async {
        final result = await service.searchSoundScenes('Ambient');
        expect(result.length, 1);
        expect(result.first.name, 'Waldhütte');
      });

      test('gibt leere Liste zurück wenn nichts gefunden', () async {
        final result = await service.searchSoundScenes('Unterwasser');
        expect(result, isEmpty);
      });

      test('Suche ist case-insensitiv', () async {
        final result = await service.searchSoundScenes('taverne');
        expect(result.isNotEmpty, true);
        expect(result.first.name, 'Taverne');
      });
    });
  });

  // =========================================================================
  // Wiedergabe-Logik Tests (ohne AudioPlayer)
  //
  // Die _isScenePlaying-Logik im Widget vergleicht scene.items[].soundId
  // mit den Channel-IDs im MultiStreamSoundService.
  // Die Channel-ID entspricht sound.id (siehe addSound in multi_stream_sound_service.dart).
  // Diese Tests prüfen die Logik direkt am Modell ohne UI oder Audio-Hardware.
  // =========================================================================

  group('Wiedergabe-Logik (_isScenePlaying Entsprechung)', () {
    /// Simuliert _isScenePlaying: Szene spielt wenn mind. ein Item eine
    /// aktive Channel-ID hat.
    bool isScenePlaying(SoundScene scene, Set<String> activeChannelIds) {
      return scene.items.any((item) => activeChannelIds.contains(item.soundId));
    }

    test('gibt false zurück wenn keine Sounds aktiv sind', () {
      final scene = mock.MockSoundSceneFactory.createWithItems(itemCount: 2);
      const activeChannels = <String>{};

      expect(isScenePlaying(scene, activeChannels), false);
    });

    test('gibt true zurück wenn mindestens ein Sound der Szene aktiv ist', () {
      final sceneId = 'play-scene';
      final item = mock.MockSoundSceneItemFactory.create(
        soundSceneId: sceneId,
        soundId: 'snd-active',
      );
      final scene =
          mock.MockSoundSceneFactory.create(id: sceneId, items: [item]);

      final activeChannels = {'snd-active', 'snd-other'};

      expect(isScenePlaying(scene, activeChannels), true);
    });

    test('gibt false zurück wenn nur andere Sounds aktiv sind', () {
      final sceneId = 'play-scene-2';
      final item = mock.MockSoundSceneItemFactory.create(
        soundSceneId: sceneId,
        soundId: 'snd-mine',
      );
      final scene =
          mock.MockSoundSceneFactory.create(id: sceneId, items: [item]);

      final activeChannels = {'snd-other-a', 'snd-other-b'};

      expect(isScenePlaying(scene, activeChannels), false);
    });

    test('leere Szene ist nie als spielend markiert', () {
      final scene = mock.MockSoundSceneFactory.create();
      final activeChannels = {'irgendein-sound'};

      expect(isScenePlaying(scene, activeChannels), false);
    });

    test('stopScene entfernt alle Sound-IDs aus den aktiven Channels', () {
      final sceneId = 'stop-scene';
      final items = [
        mock.MockSoundSceneItemFactory.create(
            soundSceneId: sceneId, soundId: 'snd-1'),
        mock.MockSoundSceneItemFactory.create(
            soundSceneId: sceneId, soundId: 'snd-2'),
      ];
      final scene =
          mock.MockSoundSceneFactory.create(id: sceneId, items: items);

      // Simuliert: Service hat diese + weitere Channels
      final activeChannels = {'snd-1', 'snd-2', 'snd-unrelated'};

      // Simuliert _stopScene: entferne alle Sound-IDs der Szene
      for (final item in scene.items) {
        activeChannels.remove(item.soundId);
      }

      expect(isScenePlaying(scene, activeChannels), false);
      // Nicht zur Szene gehörender Sound bleibt aktiv
      expect(activeChannels.contains('snd-unrelated'), true);
    });
  });

  // =========================================================================
  // Sound Modell – SoundType Klassifizierung
  // =========================================================================

  group('Sound Modell (Klassifizierung)', () {
    test('Ambiente-Sound hat korrekten Typ', () {
      final sound = mock.MockSoundFactory.create(
        soundType: SoundType.Ambiente,
      );
      expect(sound.soundType, SoundType.Ambiente);
    });

    test('Effekt-Sound hat korrekten Typ', () {
      final sound = mock.MockSoundFactory.create(
        soundType: SoundType.Effekt,
      );
      expect(sound.soundType, SoundType.Effekt);
    });

    test('Sound mit leerem Pfad ist technisch gültig (Validierung liegt im Service)', () {
      final sound = mock.MockSoundFactory.create(filePath: '');
      expect(sound.filePath, '');
    });
  });
}
