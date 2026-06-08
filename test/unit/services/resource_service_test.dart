import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:dungen_manager/services/resource_service.dart';

void main() {
  const fakeDir = '/fake/resources';

  setUpAll(() => ResourceService.setDirForTesting(fakeDir));

  // ── isResourceRef ─────────────────────────────────────────────────────────

  group('isResourceRef', () {
    test('erkennt resource://-Präfix', () {
      expect(ResourceService.isResourceRef('resource://karte.jpg'), isTrue);
    });

    test('lehnt absoluten Pfad ab', () {
      expect(ResourceService.isResourceRef('/home/user/karte.jpg'), isFalse);
    });

    test('lehnt cloud://-Präfix ab', () {
      expect(ResourceService.isResourceRef('cloud://uid/media/x.jpg'), isFalse);
    });

    test('lehnt null ab', () {
      expect(ResourceService.isResourceRef(null), isFalse);
    });

    test('lehnt leeren String ab', () {
      expect(ResourceService.isResourceRef(''), isFalse);
    });
  });

  // ── filenameFromRef ───────────────────────────────────────────────────────

  group('filenameFromRef', () {
    test('extrahiert Dateinamen', () {
      expect(
        ResourceService.filenameFromRef('resource://weltkarte.jpg'),
        'weltkarte.jpg',
      );
    });

    test('funktioniert mit Unterordner-ähnlichem Namen', () {
      expect(
        ResourceService.filenameFromRef('resource://dungeon_v2.png'),
        'dungeon_v2.png',
      );
    });
  });

  // ── resolveLocalPath ──────────────────────────────────────────────────────

  group('resolveLocalPath', () {
    test('löst resource://-Ref zu absolutem Pfad auf', () {
      final result = ResourceService.resolveLocalPath('resource://karte.jpg');
      expect(result, p.join(fakeDir, 'karte.jpg'));
    });

    test('gibt absoluten Pfad unverändert zurück (Rückwärtskompatibilität)', () {
      const absPath = '/users/dm/images/dungeon.png';
      expect(ResourceService.resolveLocalPath(absPath), absPath);
    });

    test('gibt Windows-absoluten Pfad unverändert zurück', () {
      const winPath = r'C:\Users\dm\dungeon.png';
      expect(ResourceService.resolveLocalPath(winPath), winPath);
    });

    test('gibt null für cloud://-Pfade zurück', () {
      expect(
        ResourceService.resolveLocalPath('cloud://uid/media/x.jpg'),
        isNull,
      );
    });

    test('gibt null für null zurück', () {
      expect(ResourceService.resolveLocalPath(null), isNull);
    });

    test('gibt null für leeren String zurück', () {
      expect(ResourceService.resolveLocalPath(''), isNull);
    });
  });

  // ── fileExists ────────────────────────────────────────────────────────────

  group('fileExists', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('res_test_');
      ResourceService.setDirForTesting(tempDir.path);
    });

    tearDown(() async {
      ResourceService.setDirForTesting(fakeDir);
      await tempDir.delete(recursive: true);
    });

    test('gibt true zurück wenn Datei existiert', () async {
      final file = File(p.join(tempDir.path, 'test.png'));
      await file.writeAsBytes([1, 2, 3]);
      expect(ResourceService.fileExists('resource://test.png'), isTrue);
    });

    test('gibt false zurück wenn Datei fehlt', () {
      expect(ResourceService.fileExists('resource://fehlt.png'), isFalse);
    });

    test('gibt false für null zurück', () {
      expect(ResourceService.fileExists(null), isFalse);
    });

    test('gibt false für cloud://-Pfad zurück (nicht lokal auflösbar)', () {
      expect(ResourceService.fileExists('cloud://uid/x.jpg'), isFalse);
    });
  });

  // ── isImageFile ───────────────────────────────────────────────────────────

  group('isImageFile', () {
    test('erkennt .jpg', () => expect(ResourceService.isImageFile('foto.jpg'), isTrue));
    test('erkennt .jpeg', () => expect(ResourceService.isImageFile('foto.jpeg'), isTrue));
    test('erkennt .png', () => expect(ResourceService.isImageFile('karte.png'), isTrue));
    test('erkennt .webp', () => expect(ResourceService.isImageFile('bild.webp'), isTrue));
    test('lehnt .mp3 ab', () => expect(ResourceService.isImageFile('musik.mp3'), isFalse));
    test('lehnt .txt ab', () => expect(ResourceService.isImageFile('notiz.txt'), isFalse));
    test('Gross-/Kleinschreibung egal', () {
      expect(ResourceService.isImageFile('KARTE.JPG'), isTrue);
    });
  });
}
