import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/ort.dart';

void main() {
  group('OrtType', () {
    test('Alle Typen haben ein Label', () {
      for (final type in OrtType.values) {
        expect(type.label, isNotEmpty, reason: 'OrtType.$type hat kein Label');
      }
    });

    test('region hat Label "Region"', () {
      expect(OrtType.region.label, equals('Region'));
    });

    test('Alle erwarteten Typen sind vorhanden', () {
      final expected = {
        OrtType.dungeon,
        OrtType.city,
        OrtType.building,
        OrtType.wilderness,
        OrtType.region,
        OrtType.other,
      };
      expect(OrtType.values.toSet(), equals(expected));
    });

    test('Labels sind eindeutig', () {
      final labels = OrtType.values.map((t) => t.label).toList();
      expect(labels.toSet().length, equals(labels.length));
    });
  });

  group('Ort.create()', () {
    test('Erstellt einen Ort mit Standard-Typ "other"', () {
      final ort = Ort.create(campaignId: 'c1', name: 'Testort');
      expect(ort.type, equals(OrtType.other));
    });

    test('Erstellt einen Ort vom Typ "region"', () {
      final ort = Ort.create(
        campaignId: 'c1',
        name: 'Nordland',
        type: OrtType.region,
      );
      expect(ort.type, equals(OrtType.region));
      expect(ort.name, equals('Nordland'));
    });

    test('ID ist eine nicht-leere UUID-Zeichenkette', () {
      final ort = Ort.create(campaignId: 'c1', name: 'X');
      expect(ort.id, isNotEmpty);
      expect(ort.id, isA<String>());
    });

    test('Zwei Orte haben unterschiedliche IDs', () {
      final a = Ort.create(campaignId: 'c1', name: 'A');
      final b = Ort.create(campaignId: 'c1', name: 'B');
      expect(a.id, isNot(equals(b.id)));
    });
  });

  group('Ort.fromDatabaseMap()', () {
    Map<String, dynamic> baseMap({String type = 'other'}) => {
          'id': 'test-id-123',
          'campaign_id': 'campaign-1',
          'name': 'Testort',
          'type': type,
          'description': '',
          'sort_order': 0,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
          'linked_wiki_entry_ids': null,
          'connected_ort_ids': null,
          'last_visited_at': null,
          'memory': null,
          'template_ort_id': null,
          'map_x': null,
          'map_y': null,
          'parent_ort_id': null,
          'map_image_path': null,
          'map_position_locked': 0,
        };

    test('Liest OrtType.region aus der Datenbank', () {
      final ort = Ort.fromDatabaseMap(baseMap(type: 'region'));
      expect(ort.type, equals(OrtType.region));
    });

    test('Unbekannter Typ fällt auf "other" zurück', () {
      final ort = Ort.fromDatabaseMap(baseMap(type: 'unknown_xyz'));
      expect(ort.type, equals(OrtType.other));
    });

    test('Alle Typen können deserialisiert werden', () {
      for (final type in OrtType.values) {
        final typeName = type.toString().split('.').last;
        final ort = Ort.fromDatabaseMap(baseMap(type: typeName));
        expect(ort.type, equals(type));
      }
    });
  });

  group('Ort.copyWith()', () {
    test('copyWith ändert nur den angegebenen Typ', () {
      final original = Ort.create(campaignId: 'c1', name: 'Burg', type: OrtType.building);
      final copy = original.copyWith(type: OrtType.region);

      expect(copy.type, equals(OrtType.region));
      expect(copy.name, equals('Burg'));
      expect(copy.id, equals(original.id));
    });
  });

  group('Ort Getter', () {
    test('hasBeenVisited ist false ohne lastVisitedAt', () {
      final ort = Ort.create(campaignId: 'c1', name: 'X');
      expect(ort.hasBeenVisited, isFalse);
    });

    test('isOnMap ist false ohne mapX/mapY', () {
      final ort = Ort.create(campaignId: 'c1', name: 'X');
      expect(ort.isOnMap, isFalse);
    });

    test('isOnMap ist true wenn mapX und mapY gesetzt sind', () {
      final ort = Ort.create(campaignId: 'c1', name: 'X').copyWith(
        mapX: 100.0,
        mapY: 200.0,
      );
      expect(ort.isOnMap, isTrue);
    });
  });
}
