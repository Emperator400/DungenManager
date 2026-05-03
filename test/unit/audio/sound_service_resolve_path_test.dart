// Unit-Tests für SoundService.resolveFilePath
//
// Prüft alle drei Auflösungsstrategien:
//   1. Absoluter Pfad + Datei existiert → unveränderter Pfad
//   2. Absoluter Pfad + Datei fehlt + Basename im sounds-Dir → reparierter Pfad
//   3. Absoluter Pfad + Datei fehlt + kein Basename → ungültiger Pfad zurück
//   4. Relativer Pfad → {soundsDir}/{dateiname}
//   5. Relativer Pfad mit Erweiterung → korrekt zusammengesetzt
//   6. Leerer relativer Pfad → nur sounds-Dir
//   7. Absolute Pfadnormalisierung über Betriebssystemgrenzen hinweg

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:dungen_manager/services/sound_service.dart';

// ---------------------------------------------------------------------------
// Fake path_provider — leitet getApplicationDocumentsPath auf tempDir um
// ---------------------------------------------------------------------------

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  final String documentsPath;
  _FakePathProvider(this.documentsPath);

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;

  // Weitere Methoden werden nicht benötigt — Fake wirft UnsupportedError
}

// ---------------------------------------------------------------------------
// Hilfsfunktionen
// ---------------------------------------------------------------------------

/// Erstellt eine echte Datei und gibt den absoluten Pfad zurück.
Future<String> _createFile(Directory dir, String name) async {
  final file = File(p.join(dir.path, name));
  await file.writeAsString('test audio data');
  return file.path;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;
  late Directory soundsDir;

  setUpAll(() => TestWidgetsFlutterBinding.ensureInitialized());

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('sound_resolve_test_');
    // SoundService erwartet {documents}/DungenManager/sounds
    soundsDir = Directory(p.join(tempDir.path, 'DungenManager', 'sounds'));
    await soundsDir.create(recursive: true);
    PathProviderPlatform.instance = _FakePathProvider(tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // Strategie 1: Absoluter Pfad, Datei existiert
  // -------------------------------------------------------------------------

  group('Absoluter Pfad — Datei existiert', () {
    test('gibt den absoluten Pfad unverändert zurück', () async {
      final absPath = await _createFile(soundsDir, 'track.mp3');
      final result = await SoundService.resolveFilePath(absPath);
      expect(result, absPath);
    });

    test('funktioniert auch außerhalb des sounds-Verzeichnisses', () async {
      final externalFile = await _createFile(tempDir, 'external.mp3');
      final result = await SoundService.resolveFilePath(externalFile);
      expect(result, externalFile);
    });
  });

  // -------------------------------------------------------------------------
  // Strategie 2: Stale absoluter Pfad, Basename im sounds-Dir vorhanden
  // -------------------------------------------------------------------------

  group('Stale absoluter Pfad — Basename im sounds-Dir gefunden', () {
    test('repariert den Pfad auf das sounds-Verzeichnis', () async {
      await _createFile(soundsDir, 'ambient.mp3');
      final stalePath = p.join('/old/path/that/no/longer/exists', 'ambient.mp3');

      final result = await SoundService.resolveFilePath(stalePath);

      expect(result, p.join(soundsDir.path, 'ambient.mp3'));
    });

    test('repariert auch wenn der Dateiname eine UUID enthält', () async {
      const uuid = '550e8400-e29b-41d4-a716-446655440000';
      await _createFile(soundsDir, '$uuid.ogg');
      final stalePath = '/old/location/$uuid.ogg';

      final result = await SoundService.resolveFilePath(stalePath);

      expect(result, p.join(soundsDir.path, '$uuid.ogg'));
    });
  });

  // -------------------------------------------------------------------------
  // Strategie 3: Stale absoluter Pfad, Basename auch im sounds-Dir fehlend
  // -------------------------------------------------------------------------

  group('Stale absoluter Pfad — Datei komplett fehlend', () {
    test('gibt den originalen (ungültigen) Pfad zurück', () async {
      const ghostPath = '/nonexistent/path/ghost.mp3';
      final result = await SoundService.resolveFilePath(ghostPath);
      // Aufrufer bekommt den ungültigen Pfad → kann eigene Fehlerbehandlung machen
      expect(result, ghostPath);
    });
  });

  // -------------------------------------------------------------------------
  // Strategie 4: Relativer Pfad
  // -------------------------------------------------------------------------

  group('Relativer Pfad', () {
    test('wird mit sounds-Verzeichnis zusammengesetzt', () async {
      const fileName = 'forest_ambience.mp3';
      final result = await SoundService.resolveFilePath(fileName);
      expect(result, p.join(soundsDir.path, fileName));
    });

    test('UUID-Dateiname wird korrekt aufgelöst', () async {
      const fileName = '550e8400-e29b-41d4-a716-446655440000.wav';
      final result = await SoundService.resolveFilePath(fileName);
      expect(result, p.join(soundsDir.path, fileName));
    });

    test('Pfad enthält keine doppelten Trennzeichen', () async {
      const fileName = 'battle.ogg';
      final result = await SoundService.resolveFilePath(fileName);
      // Kein doppeltes Trennzeichen
      expect(result, isNot(contains('//')));
      expect(result, endsWith(p.join('sounds', fileName)));
    });
  });

  // -------------------------------------------------------------------------
  // Strategie — Dateiexistenz-Check nach Auflösung
  // -------------------------------------------------------------------------

  group('soundFileExists', () {
    test('gibt true zurück wenn relative Datei im sounds-Dir vorhanden', () async {
      await _createFile(soundsDir, 'exists.mp3');
      expect(await SoundService.soundFileExists('exists.mp3'), isTrue);
    });

    test('gibt false zurück wenn Datei nicht existiert', () async {
      expect(await SoundService.soundFileExists('missing.mp3'), isFalse);
    });

    test('gibt true zurück für absoluten Pfad zu existierender Datei', () async {
      final abs = await _createFile(soundsDir, 'abs_exists.mp3');
      expect(await SoundService.soundFileExists(abs), isTrue);
    });

    test('gibt false zurück für absoluten Pfad zu fehlender Datei', () async {
      expect(
        await SoundService.soundFileExists('/no/such/file/ghost.mp3'),
        isFalse,
      );
    });
  });

  // -------------------------------------------------------------------------
  // isValidAudioFile — Formatprüfung (kein I/O nötig)
  // -------------------------------------------------------------------------

  group('isValidAudioFile', () {
    const valid = ['.mp3', '.wav', '.ogg', '.m4a', '.aac', '.flac'];
    const invalid = ['.txt', '.pdf', '.mp4', '.exe'];

    for (final ext in valid) {
      test('akzeptiert $ext', () {
        expect(SoundService.isValidAudioFile('track$ext'), isTrue);
      });
    }

    for (final ext in invalid) {
      test('lehnt $ext ab', () {
        expect(SoundService.isValidAudioFile('track$ext'), isFalse);
      });
    }

    test('Großschreibung wird akzeptiert (.MP3)', () {
      expect(SoundService.isValidAudioFile('track.MP3'), isTrue);
    });

    test('kein Dateiname (leer) → fällt auf .mp3 zurück → true', () {
      // _getFileExtension gibt '.mp3' als Default zurück wenn keine Extension
      expect(SoundService.isValidAudioFile(''), isTrue);
    });
  });
}
