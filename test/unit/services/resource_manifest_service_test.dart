import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:dungen_manager/services/resource_manifest_service.dart';

void main() {
  late Directory tempDir;
  late ResourceManifestService manifest;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('manifest_test_');
    manifest = ResourceManifestService(tempDir.path);
  });

  tearDown(() async {
    await tempDir.delete(recursive: true);
  });

  Future<File> _createFile(String name, List<int> bytes) async {
    final file = File(p.join(tempDir.path, name));
    await file.writeAsBytes(bytes);
    return file;
  }

  // ── needsUpload – neue Datei ───────────────────────────────────────────────

  group('needsUpload – neue Datei', () {
    test('gibt true zurück wenn Datei noch nie hochgeladen wurde', () async {
      final file = await _createFile('bild.jpg', [1, 2, 3]);
      expect(await manifest.needsUpload('bild.jpg', file), isTrue);
    });
  });

  // ── markUploaded + needsUpload ────────────────────────────────────────────

  group('markUploaded + needsUpload', () {
    test('nach markUploaded gibt needsUpload false zurück', () async {
      final file = await _createFile('karte.png', [10, 20, 30]);
      await manifest.markUploaded('karte.png', file);
      expect(await manifest.needsUpload('karte.png', file), isFalse);
    });

    test('nach Dateiänderung gibt needsUpload true zurück', () async {
      final file = await _createFile('karte.png', [10, 20, 30]);
      await manifest.markUploaded('karte.png', file);

      // Datei verändern (andere Größe)
      await file.writeAsBytes([10, 20, 30, 40, 50]);

      expect(await manifest.needsUpload('karte.png', file), isTrue);
    });

    test('verschiedene Dateien werden unabhängig verfolgt', () async {
      final a = await _createFile('a.jpg', [1]);
      final b = await _createFile('b.jpg', [2, 3]);

      await manifest.markUploaded('a.jpg', a);
      // b wurde nie hochgeladen

      expect(await manifest.needsUpload('a.jpg', a), isFalse);
      expect(await manifest.needsUpload('b.jpg', b), isTrue);
    });
  });

  // ── Persistenz ────────────────────────────────────────────────────────────

  group('Persistenz', () {
    test('Manifest wird auf Disk gespeichert und korrekt geladen', () async {
      final file = await _createFile('welt.jpg', [5, 6, 7]);
      await manifest.markUploaded('welt.jpg', file);

      // Neues Manifest-Objekt auf gleichem Verzeichnis — simuliert App-Neustart
      final manifest2 = ResourceManifestService(tempDir.path);
      expect(await manifest2.needsUpload('welt.jpg', file), isFalse);
    });

    test('korruptes Manifest startet sauber', () async {
      // Korruptes JSON schreiben
      final manifestFile = File(p.join(tempDir.path, '.manifest.json'));
      await manifestFile.writeAsString('{ KAPUTT }');

      final fresh = ResourceManifestService(tempDir.path);
      final file = await _createFile('x.png', [1]);

      // Kein Crash — behandelt als leer (alles muss hochgeladen werden)
      expect(await fresh.needsUpload('x.png', file), isTrue);
    });
  });

  // ── removeEntry ───────────────────────────────────────────────────────────

  group('removeEntry', () {
    test('entfernte Datei wird wieder als "neu" erkannt', () async {
      final file = await _createFile('alt.jpg', [9]);
      await manifest.markUploaded('alt.jpg', file);

      await manifest.removeEntry('alt.jpg');

      expect(await manifest.needsUpload('alt.jpg', file), isTrue);
    });

    test('removeEntry auf unbekannte Datei wirft keinen Fehler', () async {
      await expectLater(
        manifest.removeEntry('existiert_nicht.jpg'),
        completes,
      );
    });
  });

  // ── Manifest-Datei wird nicht synced ─────────────────────────────────────

  group('Manifest-Datei', () {
    test('Manifest-Datei beginnt mit Punkt (wird vom Sync übersprungen)', () async {
      final file = await _createFile('x.png', [1]);
      await manifest.markUploaded('x.png', file);

      final manifestFile = File(p.join(tempDir.path, '.manifest.json'));
      expect(manifestFile.existsSync(), isTrue);
      expect(manifestFile.path.split(Platform.pathSeparator).last.startsWith('.'), isTrue);
    });
  });
}
