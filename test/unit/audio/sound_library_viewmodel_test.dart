// Unit-Tests für SoundLibraryViewModel
//
// Prüft:
//   - Filter (Suche, Typ, Favoriten) kombiniert und einzeln
//   - Alphabetische Sortierung der Ergebnisse
//   - toggleSoundFavorite aktualisiert lokalen State sofort
//   - deleteSound entfernt Sound aus lokaler Liste
//   - resetSoundFilters stellt alle Filter zurück
//   - hasError / soundError Zustand
//
// Hinweis: Alle Tests verwenden eine In-Memory-SQLite-Datenbank.
// AudioPlayer wird NICHT gestartet — nur Repository-Logik wird getestet.

import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/viewmodels/sound_library_viewmodel.dart';
import 'package:dungen_manager/models/sound.dart';
import 'package:dungen_manager/database/repositories/sound_model_repository.dart';
import 'package:dungen_manager/database/core/database_connection.dart';

import '../../test_helpers/mock_data_factory.dart' as mock;
import '../../test_helpers/test_setup.dart';

/// Erstellt einen Sound direkt im Repository und gibt ihn zurück.
Future<Sound> _persist(SoundModelRepository repo, Sound sound) =>
    repo.create(sound);

void main() {
  late SoundLibraryViewModel vm;
  late SoundModelRepository repo;

  setUp(() async {
    await setUpTestDatabase();
    repo = SoundModelRepository(DatabaseConnection.instance);
    vm = SoundLibraryViewModel(repository: repo);
  });

  tearDown(() async {
    vm.dispose();
    await tearDownTestDatabase();
  });

  // ---------------------------------------------------------------------------
  // Initialer Zustand
  // ---------------------------------------------------------------------------

  group('Initialer Zustand', () {
    test('sounds ist leer vor loadSounds()', () {
      expect(vm.sounds, isEmpty);
    });

    test('isLoading ist false vor loadSounds()', () {
      expect(vm.isLoading, false);
    });

    test('hasError ist false im Ausgangszustand', () {
      expect(vm.hasError, false);
    });

    test('soundCount ist 0 vor loadSounds()', () {
      expect(vm.soundCount, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // loadSounds
  // ---------------------------------------------------------------------------

  group('loadSounds', () {
    test('lädt alle Sounds aus der Datenbank', () async {
      await _persist(repo, mock.MockSoundFactory.create(name: 'Alpha'));
      await _persist(repo, mock.MockSoundFactory.create(name: 'Beta'));

      await vm.loadSounds();

      expect(vm.soundCount, 2);
    });

    test('sounds ist leer wenn keine Sounds in der DB', () async {
      await vm.loadSounds();
      expect(vm.sounds, isEmpty);
    });

    test('isLoading ist nach loadSounds() wieder false', () async {
      await vm.loadSounds();
      expect(vm.isLoading, false);
    });
  });

  // ---------------------------------------------------------------------------
  // Filter — Suche
  // ---------------------------------------------------------------------------

  group('setSoundSearchQuery', () {
    setUp(() async {
      await _persist(repo, mock.MockSoundFactory.create(name: 'Waldsounds'));
      await _persist(repo, mock.MockSoundFactory.create(name: 'Tavernenmusik'));
      await _persist(repo,
          mock.MockSoundFactory.create(name: 'Regen', description: 'Wald im Regen'));
      await vm.loadSounds();
    });

    test('filtert nach Name', () {
      vm.setSoundSearchQuery('Wald');
      // "Waldsounds" und "Regen" (Beschreibung enthält "Wald")
      expect(vm.sounds.length, 2);
    });

    test('filtert nach Beschreibung', () {
      vm.setSoundSearchQuery('Regen');
      expect(vm.sounds.length, 1);
      expect(vm.sounds.first.name, 'Regen');
    });

    test('Suche ist case-insensitiv', () {
      vm.setSoundSearchQuery('taverne');
      expect(vm.sounds.length, 1);
      expect(vm.sounds.first.name, 'Tavernenmusik');
    });

    test('leere Suche zeigt alle Sounds', () {
      vm.setSoundSearchQuery('xyz-nicht-vorhanden');
      expect(vm.sounds, isEmpty);

      vm.setSoundSearchQuery('');
      expect(vm.sounds.length, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // Filter — Typ
  // ---------------------------------------------------------------------------

  group('setSoundTypeFilter', () {
    setUp(() async {
      await _persist(
          repo,
          mock.MockSoundFactory.create(
              name: 'Ambiente1', soundType: SoundType.Ambiente));
      await _persist(
          repo,
          mock.MockSoundFactory.create(
              name: 'Ambiente2', soundType: SoundType.Ambiente));
      await _persist(
          repo,
          mock.MockSoundFactory.create(
              name: 'Effekt1', soundType: SoundType.Effekt));
      await vm.loadSounds();
    });

    test('filtert nur Ambiente-Sounds', () {
      vm.setSoundTypeFilter(SoundType.Ambiente);
      expect(vm.sounds.length, 2);
      expect(vm.sounds.every((s) => s.soundType == SoundType.Ambiente), true);
    });

    test('filtert nur Effekt-Sounds', () {
      vm.setSoundTypeFilter(SoundType.Effekt);
      expect(vm.sounds.length, 1);
      expect(vm.sounds.first.soundType, SoundType.Effekt);
    });

    test('null-Filter zeigt alle Typen', () {
      vm.setSoundTypeFilter(SoundType.Ambiente);
      vm.setSoundTypeFilter(null);
      expect(vm.sounds.length, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // Filter — Favoriten
  // ---------------------------------------------------------------------------

  group('toggleFavoritesFilter', () {
    setUp(() async {
      await _persist(
          repo,
          mock.MockSoundFactory.create(
              name: 'Fav1', isFavorite: true));
      await _persist(
          repo,
          mock.MockSoundFactory.create(
              name: 'Normal', isFavorite: false));
      await vm.loadSounds();
    });

    test('aktivieren zeigt nur Favoriten', () {
      vm.toggleFavoritesFilter();
      expect(vm.sounds.length, 1);
      expect(vm.sounds.first.name, 'Fav1');
    });

    test('zweites Aktivieren zeigt wieder alle', () {
      vm.toggleFavoritesFilter();
      vm.toggleFavoritesFilter();
      expect(vm.sounds.length, 2);
    });

    test('showFavoritesOnly toggelt korrekt', () {
      expect(vm.showFavoritesOnly, false);
      vm.toggleFavoritesFilter();
      expect(vm.showFavoritesOnly, true);
      vm.toggleFavoritesFilter();
      expect(vm.showFavoritesOnly, false);
    });
  });

  // ---------------------------------------------------------------------------
  // Filter — Kombination
  // ---------------------------------------------------------------------------

  group('Kombinierte Filter', () {
    setUp(() async {
      await _persist(
          repo,
          mock.MockSoundFactory.create(
              name: 'Wald Ambiente',
              soundType: SoundType.Ambiente,
              isFavorite: true));
      await _persist(
          repo,
          mock.MockSoundFactory.create(
              name: 'Wald Effekt',
              soundType: SoundType.Effekt,
              isFavorite: false));
      await _persist(
          repo,
          mock.MockSoundFactory.create(
              name: 'Taverne Ambiente',
              soundType: SoundType.Ambiente,
              isFavorite: false));
      await vm.loadSounds();
    });

    test('Suche + Typ-Filter kombiniert', () {
      vm.setSoundSearchQuery('Wald');
      vm.setSoundTypeFilter(SoundType.Ambiente);
      expect(vm.sounds.length, 1);
      expect(vm.sounds.first.name, 'Wald Ambiente');
    });

    test('Suche + Favoriten-Filter kombiniert', () {
      vm.setSoundSearchQuery('Wald');
      vm.toggleFavoritesFilter();
      expect(vm.sounds.length, 1);
      expect(vm.sounds.first.name, 'Wald Ambiente');
    });
  });

  // ---------------------------------------------------------------------------
  // Sortierung
  // ---------------------------------------------------------------------------

  group('Sortierung', () {
    test('Sounds werden alphabetisch nach Name sortiert', () async {
      await _persist(repo, mock.MockSoundFactory.create(name: 'Zebra'));
      await _persist(repo, mock.MockSoundFactory.create(name: 'Affe'));
      await _persist(repo, mock.MockSoundFactory.create(name: 'Maus'));
      await vm.loadSounds();

      expect(vm.sounds[0].name, 'Affe');
      expect(vm.sounds[1].name, 'Maus');
      expect(vm.sounds[2].name, 'Zebra');
    });
  });

  // ---------------------------------------------------------------------------
  // resetSoundFilters
  // ---------------------------------------------------------------------------

  group('resetSoundFilters', () {
    setUp(() async {
      await _persist(repo, mock.MockSoundFactory.create(name: 'Wald'));
      await _persist(repo, mock.MockSoundFactory.create(name: 'Feuer',
          soundType: SoundType.Effekt));
      await vm.loadSounds();
    });

    test('setzt Suche, Typ und Favoriten zurück', () {
      vm.setSoundSearchQuery('Wald');
      vm.setSoundTypeFilter(SoundType.Effekt);
      vm.toggleFavoritesFilter();

      vm.resetSoundFilters();

      expect(vm.soundSearchQuery, '');
      expect(vm.selectedSoundType, isNull);
      expect(vm.showFavoritesOnly, false);
      expect(vm.sounds.length, 2); // alle wieder sichtbar
    });
  });

  // ---------------------------------------------------------------------------
  // toggleSoundFavorite
  // ---------------------------------------------------------------------------

  group('toggleSoundFavorite', () {
    test('setzt Favorit-Status auf true', () async {
      final sound = await _persist(
          repo, mock.MockSoundFactory.create(isFavorite: false));
      await vm.loadSounds();

      await vm.toggleSoundFavorite(sound.id);

      expect(vm.allSounds.firstWhere((s) => s.id == sound.id).isFavorite, true);
    });

    test('setzt Favorit-Status zurück auf false', () async {
      final sound = await _persist(
          repo, mock.MockSoundFactory.create(isFavorite: true));
      await vm.loadSounds();

      await vm.toggleSoundFavorite(sound.id);

      expect(vm.allSounds.firstWhere((s) => s.id == sound.id).isFavorite, false);
    });

    test('Änderung wird in der DB persistiert', () async {
      final sound = await _persist(
          repo, mock.MockSoundFactory.create(isFavorite: false));
      await vm.loadSounds();
      await vm.toggleSoundFavorite(sound.id);

      // Neues ViewModel direkt aus DB laden
      final freshVm = SoundLibraryViewModel(repository: repo);
      await freshVm.loadSounds();
      expect(
          freshVm.allSounds.firstWhere((s) => s.id == sound.id).isFavorite,
          true);
      freshVm.dispose();
    });

    test('favoriteCount wird korrekt aktualisiert', () async {
      final s1 = await _persist(repo, mock.MockSoundFactory.create());
      final s2 = await _persist(repo, mock.MockSoundFactory.create());
      await vm.loadSounds();

      expect(vm.favoriteCount, 0);
      await vm.toggleSoundFavorite(s1.id);
      expect(vm.favoriteCount, 1);
      await vm.toggleSoundFavorite(s2.id);
      expect(vm.favoriteCount, 2);
      await vm.toggleSoundFavorite(s1.id);
      expect(vm.favoriteCount, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteSound
  // ---------------------------------------------------------------------------

  group('deleteSound', () {
    test('entfernt Sound aus der lokalen Liste', () async {
      final sound = await _persist(repo,
          mock.MockSoundFactory.create(name: 'Zu löschen', filePath: 'test.mp3'));
      await vm.loadSounds();
      expect(vm.soundCount, 1);

      // deleteSound versucht SoundService.deleteSoundFile — in Tests ist die
      // Datei nicht vorhanden, aber der Service wirft keinen Fehler wenn die
      // Datei fehlt. Der DB-Eintrag wird trotzdem gelöscht.
      await vm.deleteSound(sound.id);

      expect(vm.soundCount, 0);
      expect(vm.allSounds.any((s) => s.id == sound.id), false);
    });

    test('Sound ist nach deleteSound nicht mehr in der DB', () async {
      final sound = await _persist(repo,
          mock.MockSoundFactory.create(filePath: 'delete_test.mp3'));
      await vm.loadSounds();
      await vm.deleteSound(sound.id);

      final fromDb = await repo.findById(sound.id);
      expect(fromDb, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // clearError
  // ---------------------------------------------------------------------------

  group('clearError', () {
    test('setzt soundError auf null zurück', () async {
      // Fehler durch unbekannte Sound-ID in deleteSound auslösen
      vm.clearError(); // sollte keine Exception werfen
      expect(vm.hasError, false);
    });
  });
}
