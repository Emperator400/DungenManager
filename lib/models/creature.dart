// lib/models/creature.dart
import 'package:uuid/uuid.dart';
import 'condition.dart';
import 'inventory_item.dart';

var uuid = const Uuid();

class Creature {
  final String id;
  final String name;
  final int maxHp;
  final int armorClass;
  final String speed;
  final String attacks;
  final int initiativeBonus;
  
  // Temporäre Kampf-Werte
  int currentHp;
  int? initiative;
  List<Condition> conditions = [];
  final bool isPlayer;

  // Felder für die 6 Hauptattribute
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;

  // Inventar für Spieler-Charaktere
  final List<DisplayInventoryItem> inventory;
  
  // Gold und Währung für NPCs/Monster
  final double gold;
  final double silver;
  final double copper;

  // NEU: Integration mit offiziellen D&D-Daten
  final String? officialMonsterId; // Verknüpfung zu offiziellem Monster
  final String? officialSpellIds;   // IDs der bekannten Zauber (kommagetrennt)
  final String? officialItemIds;    // IDs der bekannten Gegenstände (kommagetrennt)
  final String? size;              // Größe (Tiny, Small, Medium, Large, Huge, Gargantuan)
  final String? type;              // Typ (Humanoid, Beast, Dragon, etc.)
  final String? subtype;           // Subtyp
  final String? alignment;         // Gesinnung
  final int? challengeRating;      // Schwierigkeitsgrad
  final String? specialAbilities;  // Spezielle Fähigkeiten
  final String? legendaryActions;  // Legendäre Aktionen
  final bool isCustom;            // Ob es ein benutzerdefiniertes Monster ist
  final String? description;       // Beschreibung des Monsters/NPCs

  // NEU: Felder für Unified Bestiarum
  final String sourceType;        // 'custom', 'official', 'hybrid'
  final String? sourceId;         // Verweis auf Original-Quelle
  final bool isFavorite;          // Ob das Monster favorisiert ist
  final String version;           // Version des Monsters

  Creature({
    String? id,
    required this.name,
    required this.maxHp,
    required this.currentHp,
    this.armorClass = 10,
    this.speed = "30ft",
    this.attacks = "",
    this.initiativeBonus = 0,
    this.isPlayer = false,
    // Standardwerte für Monster
    this.strength = 10,
    this.dexterity = 10,
    this.constitution = 10,
    this.intelligence = 10,
    this.wisdom = 10,
    this.charisma = 10,
    // Standardmäßig ein leeres Inventar
    this.inventory = const [],
    // Gold und Währung
    this.gold = 0.0,
    this.silver = 0.0,
    this.copper = 0.0,
    // NEU: D&D-Integration
    this.officialMonsterId,
    this.officialSpellIds,
    this.officialItemIds,
    this.size,
    this.type,
    this.subtype,
    this.alignment,
    this.challengeRating,
    this.specialAbilities,
    this.legendaryActions,
    this.isCustom = true,
    this.description,
    // NEU: Felder für Unified Bestiarum
    this.sourceType = 'custom',
    this.sourceId,
    this.isFavorite = false,
    this.version = '1.0',
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'maxHp': maxHp,
      'armorClass': armorClass,
      'speed': speed,
      'attacks': attacks,
      'initiativeBonus': initiativeBonus,
      'strength': strength,
      'dexterity': dexterity,
      'constitution': constitution,
      'intelligence': intelligence,
      'wisdom': wisdom,
      'charisma': charisma,
      'isPlayer': isPlayer ? 1 : 0,
      'gold': gold,
      'silver': silver,
      'copper': copper,
      'official_monster_id': officialMonsterId,
      'official_spell_ids': officialSpellIds,
      'official_item_ids': officialItemIds,
      'size': size,
      'type': type,
      'subtype': subtype,
      'alignment': alignment,
      'challenge_rating': challengeRating,
      'special_abilities': specialAbilities,
      'legendary_actions': legendaryActions,
      'is_custom': isCustom ? 1 : 0,
      'description': description,
      // NEU: Felder für Unified Bestiarum
      'source_type': sourceType,
      'source_id': sourceId,
      'is_favorite': isFavorite ? 1 : 0,
      'version': version,
    };
  }

  factory Creature.fromMap(Map<String, dynamic> map) {
    return Creature(
      id: map['id'],
      name: map['name'],
      maxHp: map['maxHp'],
      currentHp: map['currentHp'] ?? map['maxHp'],
      armorClass: map['armorClass'] ?? 10,
      speed: map['speed'] ?? "30ft",
      attacks: map['attacks'] ?? "",
      initiativeBonus: map['initiativeBonus'] ?? 0,
      strength: map['strength'] ?? 10,
      dexterity: map['dexterity'] ?? 10,
      constitution: map['constitution'] ?? 10,
      intelligence: map['intelligence'] ?? 10,
      wisdom: map['wisdom'] ?? 10,
      charisma: map['charisma'] ?? 10,
      isPlayer: (map['isPlayer'] ?? 0) == 1,
      gold: (map['gold'] ?? 0.0).toDouble(),
      silver: (map['silver'] ?? 0.0).toDouble(),
      copper: (map['copper'] ?? 0.0).toDouble(),
      officialMonsterId: map['official_monster_id'],
      officialSpellIds: map['official_spell_ids'],
      officialItemIds: map['official_item_ids'],
      size: map['size'],
      type: map['type'],
      subtype: map['subtype'],
      alignment: map['alignment'],
      challengeRating: map['challenge_rating'],
      specialAbilities: map['special_abilities'],
      legendaryActions: map['legendary_actions'],
      isCustom: (map['is_custom'] ?? 1) == 1,
      description: map['description'],
      // NEU: Felder für Unified Bestiarum
      sourceType: map['source_type'] ?? 'custom',
      sourceId: map['source_id'],
      isFavorite: (map['is_favorite'] ?? 0) == 1,
      version: map['version'] ?? '1.0',
    );
  }

  // NEU: Factory-Methode zur einfachen Erstellung aus offiziellem Monster
  factory Creature.fromOfficialMonster({
    required String officialMonsterId,
    required String name,
    required int maxHp,
    required int armorClass,
    required String speed,
    required int strength,
    required int dexterity,
    required int constitution,
    required int intelligence,
    required int wisdom,
    required int charisma,
    String? size,
    String? type,
    String? subtype,
    String? alignment,
    int? challengeRating,
    String? specialAbilities,
    String? legendaryActions,
    String? description,
    String? attacks,
  }) {
    return Creature(
      officialMonsterId: officialMonsterId,
      name: name,
      maxHp: maxHp,
      currentHp: maxHp,
      armorClass: armorClass,
      speed: speed,
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
      wisdom: wisdom,
      charisma: charisma,
      size: size,
      type: type,
      subtype: subtype,
      alignment: alignment,
      challengeRating: challengeRating,
      specialAbilities: specialAbilities,
      legendaryActions: legendaryActions,
      description: description,
      attacks: attacks ?? "",
      isCustom: false,
      // NEU: Felder für Unified Bestiarum
      sourceType: 'official',
      sourceId: officialMonsterId,
      isFavorite: false,
      version: '1.0',
    );
  }

  // NEU: CopyWith-Methode für einfache Anpassungen
  Creature copyWith({
    String? name,
    int? maxHp,
    int? currentHp,
    int? armorClass,
    String? speed,
    String? attacks,
    int? initiativeBonus,
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? charisma,
    String? officialMonsterId,
    String? officialSpellIds,
    String? officialItemIds,
    String? size,
    String? type,
    String? subtype,
    String? alignment,
    int? challengeRating,
    String? specialAbilities,
    String? legendaryActions,
    bool? isCustom,
    String? description,
    // NEU: Felder für Unified Bestiarum
    String? sourceType,
    String? sourceId,
    bool? isFavorite,
    String? version,
  }) {
    return Creature(
      id: id,
      name: name ?? this.name,
      maxHp: maxHp ?? this.maxHp,
      currentHp: currentHp ?? this.currentHp,
      armorClass: armorClass ?? this.armorClass,
      speed: speed ?? this.speed,
      attacks: attacks ?? this.attacks,
      initiativeBonus: initiativeBonus ?? this.initiativeBonus,
      strength: strength ?? this.strength,
      dexterity: dexterity ?? this.dexterity,
      constitution: constitution ?? this.constitution,
      intelligence: intelligence ?? this.intelligence,
      wisdom: wisdom ?? this.wisdom,
      charisma: charisma ?? this.charisma,
      isPlayer: isPlayer,
      inventory: inventory,
      officialMonsterId: officialMonsterId ?? this.officialMonsterId,
      officialSpellIds: officialSpellIds ?? this.officialSpellIds,
      officialItemIds: officialItemIds ?? this.officialItemIds,
      size: size ?? this.size,
      type: type ?? this.type,
      subtype: subtype ?? this.subtype,
      alignment: alignment ?? this.alignment,
      challengeRating: challengeRating ?? this.challengeRating,
      specialAbilities: specialAbilities ?? this.specialAbilities,
      legendaryActions: legendaryActions ?? this.legendaryActions,
      isCustom: isCustom ?? this.isCustom,
      description: description ?? this.description,
      // NEU: Felder für Unified Bestiarum
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      isFavorite: isFavorite ?? this.isFavorite,
      version: version ?? this.version,
    );
  }
}
