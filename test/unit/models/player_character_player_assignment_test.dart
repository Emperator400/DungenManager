import 'package:flutter_test/flutter_test.dart';
import 'package:dungen_manager/models/player_character.dart';

/// Tests für die Player-Helden-Zuordnung.
///
/// Deckt das Refactoring ab, bei dem Helden primär einem Spieler gehören
/// und optional (ausleihweise) einer Kampagne zugewiesen sind.
void main() {
  group('PlayerCharacter Player-Zuordnung', () {
    test('campaignId ist standardmäßig null', () {
      final hero = PlayerCharacter.create(
        name: 'Aiko',
        playerName: 'Anna',
        className: 'Waldläuferin',
        raceName: 'Elf',
      );
      expect(hero.campaignId, isNull);
    });

    test('playerId kann gesetzt werden', () {
      final hero = PlayerCharacter.create(
        name: 'Björn',
        playerName: 'Bob',
        className: 'Barbar',
        raceName: 'Mensch',
        playerId: 'player-uuid-123',
      );
      expect(hero.playerId, equals('player-uuid-123'));
    });

    test('Held kann einer Kampagne zugewiesen werden (Ausleihen)', () {
      final hero = PlayerCharacter.create(
        name: 'Celia',
        playerName: 'Clara',
        className: 'Klerikerin',
        raceName: 'Zwerg',
        playerId: 'player-uuid-456',
      );

      final lent = hero.copyWith(campaignId: 'campaign-uuid-789');

      expect(lent.campaignId, equals('campaign-uuid-789'));
      expect(lent.playerId, equals('player-uuid-456'));
      expect(lent.id, equals(hero.id));
    });

    test('Held kann aus Kampagne abgezogen werden (Rückgabe)', () {
      final hero = PlayerCharacter.create(
        name: 'Daran',
        playerName: 'David',
        className: 'Magier',
        raceName: 'Elf',
        playerId: 'player-uuid-abc',
      ).copyWith(campaignId: 'campaign-uuid-xyz');

      // Abziehen: campaignId auf null setzen
      final returned = hero.copyWith(campaignId: null);

      expect(returned.campaignId, isNull);
      expect(returned.playerId, equals('player-uuid-abc'));
    });

    test('copyWith mit campaignId null setzt die ID wirklich auf null', () {
      final hero = PlayerCharacter.create(
        name: 'Emil',
        playerName: 'Eva',
        className: 'Schurke',
        raceName: 'Halbork',
      ).copyWith(campaignId: 'some-campaign');

      expect(hero.campaignId, equals('some-campaign'));

      final withdrawn = hero.copyWith(campaignId: null);
      expect(withdrawn.campaignId, isNull);
    });

    test('Held ohne Spieler und ohne Kampagne ist gültig', () {
      final hero = PlayerCharacter.create(
        name: 'Freier Held',
        playerName: 'Unbekannt',
        className: 'Paladin',
        raceName: 'Mensch',
      );
      expect(hero.playerId, isNull);
      expect(hero.campaignId, isNull);
      expect(hero.name, equals('Freier Held'));
    });

    test('Serialisierung: player_id wird in toDatabaseMap geschrieben', () {
      final hero = PlayerCharacter.create(
        name: 'Franz',
        playerName: 'Fred',
        className: 'Barbar',
        raceName: 'Mensch',
        playerId: 'my-player-id',
      );
      final map = hero.toDatabaseMap();
      expect(map['player_id'], equals('my-player-id'));
    });

    test('Serialisierung: campaign_id ist null ohne Kampagne', () {
      final hero = PlayerCharacter.create(
        name: 'Greta',
        playerName: 'Georg',
        className: 'Druide',
        raceName: 'Halbelf',
      );
      final map = hero.toDatabaseMap();
      expect(map['campaign_id'], isNull);
    });

    test('fromDatabaseMap liest player_id korrekt', () {
      final map = {
        'id': 'hero-id-1',
        'campaign_id': null,
        'name': 'Heinz',
        'player_name': 'Hans',
        'class_name': 'Krieger',
        'race_name': 'Mensch',
        'level': 1,
        'max_hp': 10,
        'current_hp': 10,
        'armor_class': 10,
        'initiative_bonus': 0,
        'image_path': null,
        'strength': 10,
        'dexterity': 10,
        'constitution': 10,
        'intelligence': 10,
        'wisdom': 10,
        'charisma': 10,
        'proficient_skills': null,
        'saving_throw_proficiencies': null,
        'special_abilities': null,
        'attacks': '',
        'attack_list': null,
        'inventory': null,
        'equipment': null,
        'size': null,
        'type': null,
        'subtype': null,
        'alignment': null,
        'description': null,
        'gold': 0.0,
        'silver': 0.0,
        'copper': 0.0,
        'source_type': 'custom',
        'source_id': null,
        'is_favorite': 0,
        'version': '1.0',
        'proficiency_bonus': 2,
        'speed': 30,
        'passive_perception': 10,
        'spell_slots': null,
        'spell_save_dc': 8,
        'spell_attack_bonus': 0,
        'hit_dice': 'd8',
        'hit_dice_count': 1,
        'hit_dice_remaining': 1,
        'player_id': 'test-player-id-99',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final hero = PlayerCharacter.fromDatabaseMap(map);
      expect(hero.playerId, equals('test-player-id-99'));
      expect(hero.campaignId, isNull);
    });
  });
}
