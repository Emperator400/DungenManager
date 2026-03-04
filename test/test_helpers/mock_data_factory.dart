// Mock Data Factory für DungenManager Tests
// Dieses Modul stellt Factory-Methoden zur Erstellung von Mock-Daten bereit

import 'package:dungen_manager/models/campaign.dart';
import 'package:dungen_manager/models/player_character.dart';
import 'package:dungen_manager/models/quest.dart';
import 'package:dungen_manager/models/session.dart';
import 'package:dungen_manager/models/sound.dart';
import 'package:dungen_manager/models/inventory_item.dart';

/// Factory für Campaign Mock-Daten
class MockCampaignFactory {
  /// Erstellt einen Standard-Mock Campaign
  static Campaign create({
    String? id,
    String? title,
    String? description,
    CampaignStatus? status,
    CampaignType? type,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Campaign(
      id: id ?? 'test-campaign-${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'Test Campaign',
      description: description ?? 'Test Description',
      status: status ?? CampaignStatus.planning,
      type: type ?? CampaignType.homebrew,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Erstellt eine Liste von Mock Campaigns
  static List<Campaign> createList(int count) {
    return List.generate(count, (index) => create(
      title: 'Test Campaign $index',
      description: 'Description for campaign $index',
    ));
  }

  /// Erstellt einen Mock Campaign für einen aktiven Spielleiter-Kampagne
  static Campaign createActive() {
    return create(
      title: 'Active Campaign',
      status: CampaignStatus.active,
    );
  }

  /// Erstellt einen Mock Campaign für eine abgeschlossene Kampagne
  static Campaign createCompleted() {
    return create(
      title: 'Completed Campaign',
      status: CampaignStatus.completed,
    );
  }
}

/// Factory für PlayerCharacter Mock-Daten
class MockCharacterFactory {
  /// Erstellt einen Standard-Mock PlayerCharacter
  static PlayerCharacter create({
    String? id,
    String? campaignId,
    String? name,
    String? playerName,
    String? className,
    String? raceName,
    int? level,
    int? maxHp,
    int? armorClass,
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? charisma,
  }) {
    return PlayerCharacter(
      id: id ?? 'test-character-${DateTime.now().millisecondsSinceEpoch}',
      campaignId: campaignId ?? 'test-campaign-id',
      name: name ?? 'Test Character',
      playerName: playerName ?? 'Test Player',
      className: className ?? 'Warrior',
      raceName: raceName ?? 'Human',
      level: level ?? 1,
      maxHp: maxHp ?? 10,
      armorClass: armorClass ?? 10,
      initiativeBonus: 0,
      strength: strength ?? 10,
      dexterity: dexterity ?? 10,
      constitution: constitution ?? 10,
      intelligence: intelligence ?? 10,
      wisdom: wisdom ?? 10,
      charisma: charisma ?? 10,
      proficientSkills: const [],
      attackList: const [],
      inventory: const [],
      gold: 0,
      silver: 0,
      copper: 0,
      sourceType: 'manual',
      version: '1.0',
    );
  }

  /// Erstellt eine Liste von Mock PlayerCharacters
  static List<PlayerCharacter> createList(int count) {
    return List.generate(count, (index) => create(
      name: 'Test Character $index',
      level: index + 1,
    ));
  }

  /// Erstellt einen Mock Character mit hohen Attributen
  static PlayerCharacter createHighLevel() {
    return create(
      name: 'High Level Character',
      level: 10,
      maxHp: 100,
      armorClass: 18,
      strength: 18,
      dexterity: 16,
      constitution: 16,
    );
  }
}

/// Factory für Quest Mock-Daten
class MockQuestFactory {
  /// Erstellt einen Standard-Mock Quest
  static Quest create({
    int? id,
    String? title,
    String? description,
    QuestStatus? status,
    int? rewardXp,
    int? rewardGold,
  }) {
    return Quest(
      id: id ?? DateTime.now().millisecondsSinceEpoch,
      title: title ?? 'Test Quest',
      description: description ?? 'Test Description',
      status: status ?? QuestStatus.active,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Erstellt eine Liste von Mock Quests
  static List<Quest> createList(int count) {
    return List.generate(count, (index) => create(
      title: 'Test Quest $index',
    ));
  }

  /// Erstellt einen abgeschlossenen Quest
  static Quest createCompleted() {
    return create(
      title: 'Completed Quest',
      status: QuestStatus.completed,
    );
  }
}

/// Factory für Session Mock-Daten
class MockSessionFactory {
  /// Erstellt einen Standard-Mock Session
  static Session create({
    String? id,
    String? campaignId,
    String? title,
    String? liveNotes,
    int? inGameTimeInMinutes,
  }) {
    return Session(
      id: id ?? 'test-session-${DateTime.now().millisecondsSinceEpoch}',
      campaignId: campaignId ?? 'test-campaign-id',
      title: title ?? 'Test Session',
      liveNotes: liveNotes ?? '',
      inGameTimeInMinutes: inGameTimeInMinutes ?? 480,
    );
  }

  /// Erstellt eine Liste von Mock Sessions
  static List<Session> createList(int count) {
    return List.generate(count, (index) => create(
      title: 'Session $index',
    ));
  }
}

/// Factory für Sound Mock-Daten
class MockSoundFactory {
  /// Erstellt einen Standard-Mock Sound
  static Sound create({
    String? id,
    String? name,
    String? filePath,
    SoundType? soundType,
    String? description,
  }) {
    return Sound(
      id: id ?? 'test-sound-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Sound',
      filePath: filePath ?? '/path/to/sound.mp3',
      soundType: soundType ?? SoundType.Ambiente,
      description: description ?? '',
    );
  }

  /// Erstellt eine Liste von Mock Sounds
  static List<Sound> createList(int count) {
    return List.generate(count, (index) => create(
      name: 'Test Sound $index',
    ));
  }
}

/// Factory für InventoryItem Mock-Daten
class MockInventoryItemFactory {
  /// Erstellt einen Standard-Mock InventoryItem
  static InventoryItem create({
    String? id,
    String? characterId,
    String? itemId,
    String? name,
    String? description,
    int? quantity,
    bool? isEquipped,
  }) {
    return InventoryItem(
      id: id ?? 'test-item-${DateTime.now().millisecondsSinceEpoch}',
      characterId: characterId ?? 'test-character-id',
      itemId: itemId ?? 'test-item-ref-${DateTime.now().millisecondsSinceEpoch}',
      name: name ?? 'Test Item',
      description: description ?? 'Test Description',
      quantity: quantity ?? 1,
      isEquipped: isEquipped ?? false,
    );
  }

  /// Erstellt eine Liste von Mock InventoryItems
  static List<InventoryItem> createList(int count) {
    return List.generate(count, (index) => create(
      name: 'Test Item $index',
    ));
  }
}

/// Konstante Referenzen auf alle Factories für einfachen Zugriff
/// Verwende so:
/// MockCampaignFactory.create(...)
/// MockCharacterFactory.create(...)
/// usw.
