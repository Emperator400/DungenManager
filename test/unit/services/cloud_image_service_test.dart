import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:dungen_manager/services/auth_service.dart';
import 'package:dungen_manager/services/cloud_image_service.dart';
import 'package:dungen_manager/services/resource_service.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

// CloudImageService ist nicht einfach mockbar (interne HTTP-Aufrufe).
// Wir testen ausschließlich die pure Logik ohne Netzwerk:
//   - isCloudPath
//   - downloadIfCloud für resource:// und nicht-cloud Pfade
//   - uploadIfLocal für resource:// und cloud:// Pfade (kein echter Upload)

void main() {
  setUpAll(() => ResourceService.setDirForTesting('/fake/resources'));

  // ── isCloudPath ───────────────────────────────────────────────────────────

  group('isCloudPath', () {
    test('erkennt cloud://-Präfix', () {
      expect(CloudImageService.isCloudPath('cloud://users/uid/x.jpg'), isTrue);
    });

    test('lehnt resource://-Präfix ab', () {
      expect(CloudImageService.isCloudPath('resource://x.jpg'), isFalse);
    });

    test('lehnt absoluten Pfad ab', () {
      expect(CloudImageService.isCloudPath('/home/user/img.png'), isFalse);
    });

    test('lehnt null ab', () {
      expect(CloudImageService.isCloudPath(null), isFalse);
    });
  });

  // ── downloadIfCloud – resource:// ─────────────────────────────────────────

  group('downloadIfCloud – resource://', () {
    late CloudImageService svc;

    setUp(() => svc = CloudImageService(_FakeAuth()));

    test('resource://-Pfad wird unverändert zurückgegeben (kein Download)', () async {
      const ref = 'resource://weltkarte.jpg';
      // Kein Netzwerkaufruf erwartet — würde mit FakeAuth nicht funktionieren
      expect(await svc.downloadIfCloud(ref), ref);
    });

    test('null → null', () async {
      expect(await svc.downloadIfCloud(null), isNull);
    });

    test('leerer String → null', () async {
      expect(await svc.downloadIfCloud(''), isNull);
    });

    test('absoluter Pfad → unverändert (Rückwärtskompatibilität)', () async {
      const abs = '/home/user/image.jpg';
      expect(await svc.downloadIfCloud(abs), abs);
    });
  });

  // ── uploadIfLocal – Kurzschluss-Fälle ────────────────────────────────────

  group('uploadIfLocal – Kurzschluss ohne Netzwerk', () {
    late CloudImageService svc;

    setUp(() => svc = CloudImageService(_FakeAuth()));

    test('null → null (kein Upload)', () async {
      expect(await svc.uploadIfLocal(null, 'uid', 'eid', 'cover'), isNull);
    });

    test('leerer String → null', () async {
      expect(await svc.uploadIfLocal('', 'uid', 'eid', 'cover'), isNull);
    });

    test('cloud://-Pfad → unverändert zurück (kein Re-Upload)', () async {
      const cloud = 'cloud://users/uid/media/camp_cover.jpg';
      expect(await svc.uploadIfLocal(cloud, 'uid', 'eid', 'cover'), cloud);
    });

    test('resource://-Pfad → unverändert zurück (handled by CloudResourceService)', () async {
      const ref = 'resource://karte.jpg';
      expect(await svc.uploadIfLocal(ref, 'uid', 'eid', 'karte'), ref);
    });

    test('nicht-existente Datei → null', () async {
      expect(
        await svc.uploadIfLocal('/gibt/es/nicht.jpg', 'uid', 'eid', 'cover'),
        isNull,
      );
    });
  });

  // ── Manifest-Deduplication ────────────────────────────────────────────────
  // Testet dass unveränderte Dateien nicht neu hochgeladen werden.
  // Verwendet eine minimale Subklasse die den echten Upload überschreibt.

  group('Manifest – kein Re-Upload bei unveränderter Datei', () {
    late Directory tempDir;
    late _TestableCloudImageService svc;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cloud_img_test_');
      svc = _TestableCloudImageService(tempDir.path);
    });

    tearDown(() async => tempDir.delete(recursive: true));

    test('erste Upload-Anfrage führt zu echtem Upload', () async {
      final file = await _createFile(tempDir, 'img.jpg', [1, 2, 3]);
      await svc.uploadIfLocal(file.path, 'uid1', 'eid', 'cover');
      expect(svc.uploadCount, 1);
    });

    test('zweite Upload-Anfrage ohne Änderung → kein Upload', () async {
      final file = await _createFile(tempDir, 'img.jpg', [1, 2, 3]);
      await svc.uploadIfLocal(file.path, 'uid1', 'eid', 'cover');
      await svc.uploadIfLocal(file.path, 'uid1', 'eid', 'cover');
      expect(svc.uploadCount, 1);
    });

    test('zweite Anfrage nach Dateiänderung → erneuter Upload', () async {
      final file = await _createFile(tempDir, 'img.jpg', [1, 2, 3]);
      await svc.uploadIfLocal(file.path, 'uid1', 'eid', 'cover');

      await file.writeAsBytes([1, 2, 3, 4, 5]); // geändert

      await svc.uploadIfLocal(file.path, 'uid1', 'eid', 'cover');
      expect(svc.uploadCount, 2);
    });

    test('verschiedene UIDs → jeweils eigener Upload', () async {
      final file = await _createFile(tempDir, 'img.jpg', [1, 2, 3]);
      await svc.uploadIfLocal(file.path, 'uid1', 'eid', 'cover');
      await svc.uploadIfLocal(file.path, 'uid2', 'eid', 'cover');
      expect(svc.uploadCount, 2);
    });

    test('gecachter Pfad wird korrekt zurückgegeben', () async {
      final file = await _createFile(tempDir, 'img.jpg', [1, 2, 3]);
      final first = await svc.uploadIfLocal(file.path, 'uid1', 'eid', 'cover');
      final second = await svc.uploadIfLocal(file.path, 'uid1', 'eid', 'cover');
      expect(first, isNotNull);
      expect(second, first); // gleicher Cloud-Pfad
    });

    test('Manifest überlebt Neustart (Persistenz)', () async {
      final file = await _createFile(tempDir, 'img.jpg', [1, 2, 3]);
      await svc.uploadIfLocal(file.path, 'uid1', 'eid', 'cover');

      // Neues Service-Objekt, gleiches tempDir → manifest wird neu geladen
      final svc2 = _TestableCloudImageService(tempDir.path);
      await svc2.uploadIfLocal(file.path, 'uid1', 'eid', 'cover');

      expect(svc2.uploadCount, 0); // kein Upload — aus persistiertem Manifest
    });
  });
}

// ── Helfer ────────────────────────────────────────────────────────────────────

Future<File> _createFile(Directory dir, String name, List<int> bytes) async {
  final file = File(p.join(dir.path, name));
  await file.writeAsBytes(bytes);
  return file;
}

/// Fake AuthService — nie aufgerufen in diesen Tests.
class _FakeAuth implements AuthService {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError(i.memberName.toString());
}

/// Testbare Variante von CloudImageService:
/// - Überschreibt den echten Netzwerk-Upload durch einen Zähler
/// - Speichert das Manifest im übergebenen Verzeichnis
class _TestableCloudImageService extends CloudImageService {
  int uploadCount = 0;
  final String _testDir;

  _TestableCloudImageService(this._testDir) : super(_FakeAuth());

  @override
  Future<String> get manifestPath async =>
      p.join(_testDir, '.upload_manifest.json');

  @override
  Future<void> restUpload(File file, String storagePath) async {
    uploadCount++;
  }

  @override
  Future<void> nativeUpload(File file, String storagePath) async {
    uploadCount++;
  }
}
