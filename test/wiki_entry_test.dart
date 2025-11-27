// 1. Dart Core
import 'dart:async';

// 2. Externe Packages
import 'package:flutter_test/flutter_test.dart';

// 3. Eigene Projekte (absolute Pfade)
import 'package:dungen_manager/models/wiki_entry.dart';
import 'package:dungen_manager/models/map_location.dart';

void main() {
  group('WikiEntry Tests', () {
    test('WikiEntry creation with required fields', () {
      final now = DateTime.now();
      final entry = WikiEntry(
        id: 'test_id_1',
        title: 'Test Entry',
        content: 'Test content',
        entryType: WikiEntryType.Person,
        tags: [],
        createdAt: now,
        updatedAt: now,
        childIds: [],
        isMarkdown: false,
        isFavorite: false,
      );

      expect(entry.title, equals('Test Entry'));
      expect(entry.content, equals('Test content'));
      expect(entry.entryType, equals(WikiEntryType.Person));
      expect(entry.tags, isEmpty);
      expect(entry.location, isNull);
      expect(entry.campaignId, isNull);
      expect(entry.isGlobal, isTrue);
    });

    test('WikiEntry creation with all fields', () {
      final location = MapLocation(
        latitude: 50.0,
        longitude: 10.0,
        mapId: 'test_map',
        zoomLevel: 10,
        markerType: 'city',
      );

      final entry = WikiEntry.create(
        title: 'Complete Entry',
        content: 'Complete content',
        entryType: WikiEntryType.Place,
        location: location,
        tags: ['test', 'complete'],
        campaignId: 'campaign_123',
      );

      expect(entry.title, equals('Complete Entry'));
      expect(entry.hasLocation, isTrue);
      expect(entry.hasTags, isTrue);
      expect(entry.isGlobal, isFalse);
      expect(entry.belongsToCampaign('campaign_123'), isTrue);
      expect(entry.belongsToCampaign('other_campaign'), isFalse);
    });

    test('WikiEntry toMap and fromMap', () {
      final location = MapLocation(
        latitude: 45.0,
        longitude: 9.0,
        mapId: 'faerun',
        markerType: 'dungeon',
      );

      final original = WikiEntry.create(
        title: 'Map Test',
        content: 'Test content with map',
        entryType: WikiEntryType.Lore,
        location: location,
        tags: ['lore', 'test'],
        campaignId: 'campaign_456',
      );

      final map = original.toMap();
      final restored = WikiEntry.fromMap(map);

      expect(restored.id, equals(original.id));
      expect(restored.title, equals(original.title));
      expect(restored.content, equals(original.content));
      expect(restored.entryType, equals(original.entryType));
      expect(restored.location?.latitude, equals(location.latitude));
      expect(restored.location?.longitude, equals(location.longitude));
      expect(restored.location?.mapId, equals(location.mapId));
      expect(restored.tags, equals(original.tags));
      expect(restored.campaignId, equals(original.campaignId));
    });

    test('WikiEntry tag management', () {
      final entry = WikiEntry.create(
        title: 'Tag Test',
        content: 'Testing tags',
        entryType: WikiEntryType.Lore,
      );

      // Add tags
      final withTag1 = entry.addTag('adventure');
      expect(withTag1.tags, contains('adventure'));
      expect(withTag1.tags.length, equals(1));

      final withTag2 = withTag1.addTag('campaign');
      expect(withTag2.tags, contains('adventure'));
      expect(withTag2.tags, contains('campaign'));
      expect(withTag2.tags.length, equals(2));

      // Try to add duplicate tag
      final withDuplicate = withTag2.addTag('adventure');
      expect(withDuplicate.tags.length, equals(2)); // Should not increase

      // Remove tag
      final withoutTag = withDuplicate.removeTag('adventure');
      expect(withoutTag.tags, isNot(contains('adventure')));
      expect(withoutTag.tags, contains('campaign'));
      expect(withoutTag.tags.length, equals(1));

      // Try to remove non-existent tag
      final noChange = withoutTag.removeTag('nonexistent');
      expect(noChange.tags.length, equals(1)); // Should not change
    });

    test('WikiEntry copyWith', () {
      final original = WikiEntry.create(
        title: 'Original',
        content: 'Original content',
        entryType: WikiEntryType.Person,
        tags: ['original'],
      );

      // Warte kurz um Zeitunterschied zu gewährleisten
      Future.delayed(const Duration(milliseconds: 1));
      
      final updated = original.copyWith(
        title: 'Updated',
        content: 'Updated content',
      );

      expect(updated.title, equals('Updated'));
      expect(updated.content, equals('Updated content'));
      expect(updated.entryType, equals(original.entryType));
      expect(updated.tags, equals(original.tags));
      expect(updated.id, equals(original.id));
      // updatedAt wird immer auf jetzt gesetzt, also sollte es nach original sein
      expect(updated.updatedAt.isAtSameMomentAs(original.updatedAt) || updated.updatedAt.isAfter(original.updatedAt), isTrue);
    });
  });

  group('MapLocation Tests', () {
    test('MapLocation creation', () {
      final location = MapLocation(
        latitude: 51.5074,
        longitude: -0.1278,
        mapId: 'london',
        zoomLevel: 12,
        markerType: 'city',
      );

      expect(location.latitude, equals(51.5074));
      expect(location.longitude, equals(-0.1278));
      expect(location.mapId, equals('london'));
      expect(location.zoomLevel, equals(12));
      expect(location.markerType, equals('city'));
    });

    test('MapLocation JSON serialization', () {
      final original = MapLocation(
        latitude: 48.8566,
        longitude: 2.3522,
        mapId: 'paris',
        markerType: 'capital',
      );

      final jsonString = original.toJsonString();
      final restored = MapLocation.fromJsonString(jsonString);

      expect(restored.latitude, equals(original.latitude));
      expect(restored.longitude, equals(original.longitude));
      expect(restored.mapId, equals(original.mapId));
      expect(restored.markerType, equals(original.markerType));
    });

    test('MapLocation copyWith', () {
      final original = MapLocation(
        latitude: 40.7128,
        longitude: -74.0060,
        mapId: 'new_york',
        zoomLevel: 10,
      );

      final updated = original.copyWith(
        zoomLevel: 15,
        markerType: 'metropolis',
      );

      expect(updated.latitude, equals(original.latitude));
      expect(updated.longitude, equals(original.longitude));
      expect(updated.mapId, equals(original.mapId));
      expect(updated.zoomLevel, equals(15));
      expect(updated.markerType, equals('metropolis'));
    });

    test('MapLocation equality', () {
      final location1 = MapLocation(
        latitude: 35.6762,
        longitude: 139.6503,
        mapId: 'tokyo',
        zoomLevel: 12,
        markerType: 'city',
      );

      final location2 = MapLocation(
        latitude: 35.6762,
        longitude: 139.6503,
        mapId: 'tokyo',
        zoomLevel: 12,
        markerType: 'city',
      );

      final location3 = MapLocation(
        latitude: 35.6762,
        longitude: 139.6503,
        mapId: 'tokyo',
        zoomLevel: 15, // Different zoom level
        markerType: 'city',
      );

      expect(location1, equals(location2));
      expect(location1, isNot(equals(location3)));
    });
  });
}
