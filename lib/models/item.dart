// lib/models/item.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

// Enum für die verschiedenen Item-Typen
enum ItemType { 
  Weapon, 
  Armor, 
  Shield, 
  Consumable, 
  Tool, 
  Material, 
  Component, 
  MagicItem, 
  Scroll, 
  Potion,
  Treasure, 
  Currency,
  AdventuringGear,  // Behalten für Kompatibilität
  SPELL_WEAPON  // Spells als "magische Waffen"
}

class Item {
  final String id;
  final String name;
  final String description;
  final ItemType itemType;

  // Allgemeine Eigenschaften
  final double weight;
  final double cost; // in Goldmünzen
  final String imageUrl; // URL zum Item-Bild

  // Waffen-Eigenschaften
  final String? damage;
  final String? properties;

  // Rüstungs-Eigenschaften
  final String? acFormula;
  final int? strengthRequirement;
  final bool? stealthDisadvantage;

  // Magische Eigenschaften
  final String? rarity;
  final bool? requiresAttunement;

  // Optionale Durability-Felder
  final bool? hasDurability;     // Flag ob Haltbarkeit aktiv ist
  final int? maxDurability;       // Maximale Haltbarkeit (wenn aktiv)
  final bool? isRepairable;      // Ob das Item reparierbar ist

  // Spell-spezifische Eigenschaften
  final String? spellId;              // Referenz zu OfficialSpell
  final bool? isSpell;                // Spell-Flag
  final int? spellLevel;              // Spell Level
  final String? spellSchool;          // Magische Schule
  final bool? isCantrip;              // Unlimited uses
  final int? maxCastsPerDay;          // Slot-basierte Verwendung
  final bool? requiresConcentration;  // Concentration required

  Item({
    String? id,
    required this.name,
    this.description = '',
    required this.itemType,
    this.weight = 0.0,
    this.cost = 0.0,
    this.imageUrl = '',
    this.damage,
    this.properties,
    this.acFormula,
    this.strengthRequirement,
    this.stealthDisadvantage,
    this.rarity,
    this.requiresAttunement,
    this.hasDurability,
    this.maxDurability,
    this.isRepairable,
    this.spellId,
    this.isSpell = false,
    this.spellLevel,
    this.spellSchool,
    this.isCantrip = false,
    this.maxCastsPerDay,
    this.requiresConcentration = false,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'itemType': itemType.toString(),
      'weight': weight,
      'cost': cost,
      'imageUrl': imageUrl,
      'damage': damage,
      'properties': properties,
      'acFormula': acFormula,
      'strengthRequirement': strengthRequirement,
      'stealthDisadvantage': stealthDisadvantage == true ? 1 : 0,
      'rarity': rarity,
      'requiresAttunement': requiresAttunement == true ? 1 : 0,
      'hasDurability': hasDurability == true ? 1 : 0,
      'maxDurability': maxDurability,
      'isRepairable': isRepairable == true ? 1 : 0,
      'spellId': spellId,
      'isSpell': isSpell == true ? 1 : 0,
      'spellLevel': spellLevel,
      'spellSchool': spellSchool,
      'isCantrip': isCantrip == true ? 1 : 0,
      'maxCastsPerDay': maxCastsPerDay,
      'requiresConcentration': requiresConcentration == true ? 1 : 0,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      itemType: ItemType.values.firstWhere((e) => e.toString() == map['itemType']),
      weight: map['weight'],
      cost: map['cost'],
      imageUrl: map['imageUrl'] ?? '',
      damage: map['damage'],
      properties: map['properties'],
      acFormula: map['acFormula'],
      strengthRequirement: map['strengthRequirement'],
      stealthDisadvantage: map['stealthDisadvantage'] == 1,
      rarity: map['rarity'],
      requiresAttunement: map['requiresAttunement'] == 1,
      hasDurability: map['hasDurability'] == 1,
      maxDurability: map['maxDurability'],
      isRepairable: map['isRepairable'] == 1,
      spellId: map['spellId'],
      isSpell: map['isSpell'] == 1,
      spellLevel: map['spellLevel'],
      spellSchool: map['spellSchool'],
      isCantrip: map['isCantrip'] == 1,
      maxCastsPerDay: map['maxCastsPerDay'],
      requiresConcentration: map['requiresConcentration'] == 1,
    );
  }
}
