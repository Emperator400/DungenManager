import '../utils/model_parsing_helper.dart';

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

  const Item({
    required this.id,
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
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'item_type': itemType.toString(),
      'weight': weight,
      'cost': cost,
      'image_url': imageUrl,
      'damage': damage,
      'properties': properties,
      'ac_formula': acFormula,
      'strength_requirement': strengthRequirement,
      'stealth_disadvantage': stealthDisadvantage,
      'rarity': rarity,
      'requires_attunement': requiresAttunement,
      'has_durability': hasDurability,
      'max_durability': maxDurability,
      'is_repairable': isRepairable,
      'spell_id': spellId,
      'is_spell': isSpell,
      'spell_level': spellLevel,
      'spell_school': spellSchool,
      'is_cantrip': isCantrip,
      'max_casts_per_day': maxCastsPerDay,
      'requires_concentration': requiresConcentration,
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: ModelParsingHelper.safeId(map, 'id'),
      name: ModelParsingHelper.safeString(map, 'name', ''),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      itemType: ModelParsingHelper.safeEnum<ItemType>(
        map, 
        'item_type', 
        ItemType.values, 
        ItemType.Weapon,
      ),
      weight: ModelParsingHelper.safeDouble(map, 'weight', 0.0),
      cost: ModelParsingHelper.safeDouble(map, 'cost', 0.0),
      imageUrl: ModelParsingHelper.safeString(map, 'image_url', ''),
      damage: ModelParsingHelper.safeStringOrNull(map, 'damage', null),
      properties: ModelParsingHelper.safeStringOrNull(map, 'properties', null),
      acFormula: ModelParsingHelper.safeStringOrNull(map, 'ac_formula', null),
      strengthRequirement: ModelParsingHelper.safeIntOrNull(map, 'strength_requirement', null),
      stealthDisadvantage: ModelParsingHelper.safeBool(map, 'stealth_disadvantage', false) ? true : null,
      rarity: ModelParsingHelper.safeStringOrNull(map, 'rarity', null),
      requiresAttunement: ModelParsingHelper.safeBool(map, 'requires_attunement', false) ? true : null,
      hasDurability: ModelParsingHelper.safeBool(map, 'has_durability', false) ? true : null,
      maxDurability: ModelParsingHelper.safeIntOrNull(map, 'max_durability', null),
      isRepairable: ModelParsingHelper.safeBool(map, 'is_repairable', false) ? true : null,
      spellId: ModelParsingHelper.safeStringOrNull(map, 'spell_id', null),
      isSpell: ModelParsingHelper.safeBool(map, 'is_spell', false) ? true : null,
      spellLevel: ModelParsingHelper.safeIntOrNull(map, 'spell_level', null),
      spellSchool: ModelParsingHelper.safeStringOrNull(map, 'spell_school', null),
      isCantrip: ModelParsingHelper.safeBool(map, 'is_cantrip', false) ? true : null,
      maxCastsPerDay: ModelParsingHelper.safeIntOrNull(map, 'max_casts_per_day', null),
      requiresConcentration: ModelParsingHelper.safeBool(map, 'requires_concentration', false) ? true : null,
    );
  }

  Item copyWith({
    String? id,
    String? name,
    String? description,
    ItemType? itemType,
    double? weight,
    double? cost,
    String? imageUrl,
    String? damage,
    String? properties,
    String? acFormula,
    int? strengthRequirement,
    bool? stealthDisadvantage,
    String? rarity,
    bool? requiresAttunement,
    bool? hasDurability,
    int? maxDurability,
    bool? isRepairable,
    String? spellId,
    bool? isSpell,
    int? spellLevel,
    String? spellSchool,
    bool? isCantrip,
    int? maxCastsPerDay,
    bool? requiresConcentration,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      itemType: itemType ?? this.itemType,
      weight: weight ?? this.weight,
      cost: cost ?? this.cost,
      imageUrl: imageUrl ?? this.imageUrl,
      damage: damage ?? this.damage,
      properties: properties ?? this.properties,
      acFormula: acFormula ?? this.acFormula,
      strengthRequirement: strengthRequirement ?? this.strengthRequirement,
      stealthDisadvantage: stealthDisadvantage ?? this.stealthDisadvantage,
      rarity: rarity ?? this.rarity,
      requiresAttunement: requiresAttunement ?? this.requiresAttunement,
      hasDurability: hasDurability ?? this.hasDurability,
      maxDurability: maxDurability ?? this.maxDurability,
      isRepairable: isRepairable ?? this.isRepairable,
      spellId: spellId ?? this.spellId,
      isSpell: isSpell ?? this.isSpell,
      spellLevel: spellLevel ?? this.spellLevel,
      spellSchool: spellSchool ?? this.spellSchool,
      isCantrip: isCantrip ?? this.isCantrip,
      maxCastsPerDay: maxCastsPerDay ?? this.maxCastsPerDay,
      requiresConcentration: requiresConcentration ?? this.requiresConcentration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Item && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Item(id: $id, name: $name, type: $itemType)';
}
