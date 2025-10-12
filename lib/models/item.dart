// lib/models/item.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

// Enum für die verschiedenen Item-Typen
enum ItemType { Weapon, Armor, AdventuringGear, Treasure, MagicItem }

class Item {
  final String id;
  final String name;
  final String description;
  final ItemType itemType;

  // Allgemeine Eigenschaften
  final double weight;
  final double cost; // in Goldmünzen

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

  Item({
    String? id,
    required this.name,
    this.description = '',
    required this.itemType,
    this.weight = 0.0,
    this.cost = 0.0,
    this.damage,
    this.properties,
    this.acFormula,
    this.strengthRequirement,
    this.stealthDisadvantage,
    this.rarity,
    this.requiresAttunement,
  }) : id = id ?? uuid.v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'itemType': itemType.toString(),
      'weight': weight,
      'cost': cost,
      'damage': damage,
      'properties': properties,
      'acFormula': acFormula,
      'strengthRequirement': strengthRequirement,
      'stealthDisadvantage': stealthDisadvantage == true ? 1 : 0,
      'rarity': rarity,
      'requiresAttunement': requiresAttunement == true ? 1 : 0,
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
      damage: map['damage'],
      properties: map['properties'],
      acFormula: map['acFormula'],
      strengthRequirement: map['strengthRequirement'],
      stealthDisadvantage: map['stealthDisadvantage'] == 1,
      rarity: map['rarity'],
      requiresAttunement: map['requiresAttunement'] == 1,
    );
  }
}