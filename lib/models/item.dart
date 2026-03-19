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

/// Rüstungskategorie nach D&D 5e Regeln
/// 
/// - [Light]: Leichte Rüstung (AC + voller Dexterity Modifier)
/// - [Medium]: Mittlere Rüstung (AC + Dexterity Modifier, max +2)
/// - [Heavy]: Schwere Rüstung (Feste AC, kein Dexterity Modifier)
enum ArmorCategory {
  Light,   // Leichte Rüstung: Leder, Padded, Studded Leather
  Medium,  // Mittlere Rüstung: Chain Shirt, Scale Mail, Breastplate, Half Plate
  Heavy,   // Schwere Rüstung: Ring Mail, Chain Mail, Splint, Plate
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
  final ArmorCategory? armorCategory; // Leichte, Mittlere oder Schwere Rüstung

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
    this.armorCategory,
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
      'armor_category': armorCategory?.toString().replaceAll('ArmorCategory.', ''),
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

  /// NEUE METHODE: Serialisiert für Datenbank mit konsistenten Feldnamen
  /// Diese Methode ersetzt zukünftig die Entity-Konvertierung
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'item_type': _itemTypeToString(),
      'weight': weight,
      'cost': cost,
      'image_url': imageUrl,
      'damage': damage,
      'properties': properties,
      'ac_formula': acFormula,
      'strength_requirement': strengthRequirement,
      'stealth_disadvantage': stealthDisadvantage == true ? 1 : 0,
      'armor_category': armorCategory?.toString().replaceAll('ArmorCategory.', ''),
      'rarity': rarity,
      'requires_attunement': requiresAttunement == true ? 1 : 0,
      'has_durability': hasDurability == true ? 1 : 0,
      'max_durability': maxDurability,
      'is_repairable': isRepairable == true ? 1 : 0,
      'spell_id': spellId,
      'is_spell': isSpell == true ? 1 : 0,
      'spell_level': spellLevel,
      'spell_school': spellSchool,
      'is_cantrip': isCantrip == true ? 1 : 0,
      'max_casts_per_day': maxCastsPerDay,
      'requires_concentration': requiresConcentration == true ? 1 : 0,
      'source_type': 'custom',
      'source_id': null,
      'is_custom': 1,
      'is_favorite': 0,
      'version': '1.0',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
  }

  /// NEUE METHODE: Deserialisiert von Datenbank mit konsistenten Feldnamen
  /// Diese Methode ersetzt zukünftig die Entity-Konvertierung
  factory Item.fromDatabaseMap(Map<String, dynamic> map) {
    return Item(
      id: ModelParsingHelper.safeId(map, 'id'),
      name: ModelParsingHelper.safeString(map, 'name', 'Unbenanntes Item'),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      itemType: _parseItemType(map['item_type'] as String?),
      weight: ModelParsingHelper.safeDouble(map, 'weight', 0.0),
      cost: ModelParsingHelper.safeDouble(map, 'cost', 0.0),
      imageUrl: ModelParsingHelper.safeString(map, 'image_url', ''),
      damage: ModelParsingHelper.safeStringOrNull(map, 'damage', null),
      properties: ModelParsingHelper.safeStringOrNull(map, 'properties', null),
      acFormula: ModelParsingHelper.safeStringOrNull(map, 'ac_formula', null),
      strengthRequirement: ModelParsingHelper.safeIntOrNull(map, 'strength_requirement', null),
      stealthDisadvantage: (map['stealth_disadvantage'] as int?) == 1,
      armorCategory: _parseArmorCategory(map['armor_category'] as String?),
      rarity: ModelParsingHelper.safeStringOrNull(map, 'rarity', null),
      requiresAttunement: (map['requires_attunement'] as int?) == 1,
      hasDurability: (map['has_durability'] as int?) == 1,
      maxDurability: ModelParsingHelper.safeIntOrNull(map, 'max_durability', null),
      isRepairable: (map['is_repairable'] as int?) == 1,
      spellId: ModelParsingHelper.safeStringOrNull(map, 'spell_id', null),
      isSpell: (map['is_spell'] as int?) == 1,
      spellLevel: ModelParsingHelper.safeIntOrNull(map, 'spell_level', null),
      spellSchool: ModelParsingHelper.safeStringOrNull(map, 'spell_school', null),
      isCantrip: (map['is_cantrip'] as int?) == 1,
      maxCastsPerDay: ModelParsingHelper.safeIntOrNull(map, 'max_casts_per_day', null),
      requiresConcentration: (map['requires_concentration'] as int?) == 1,
    );
  }

  /// Hilfsmethode: Konvertiert ItemType zu String für Datenbank
  String _itemTypeToString() {
    return itemType.toString().replaceAll('ItemType.', '');
  }

  /// Hilfsmethode: Parsiert ItemType aus Datenbank-String
  static ItemType _parseItemType(String? itemTypeString) {
    if (itemTypeString == null || itemTypeString.isEmpty) return ItemType.Weapon;
    
    try {
      return ItemType.values.firstWhere(
        (type) => type.toString().contains(itemTypeString),
        orElse: () => ItemType.Weapon,
      );
    } catch (e) {
      return ItemType.Weapon;
    }
  }

  /// Hilfsmethode: Parsiert ArmorCategory aus Datenbank-String
  static ArmorCategory? _parseArmorCategory(String? categoryString) {
    if (categoryString == null || categoryString.isEmpty) return null;
    
    try {
      return ArmorCategory.values.firstWhere(
        (category) => category.toString().contains(categoryString),
        orElse: () => ArmorCategory.Light,
      );
    } catch (e) {
      return null;
    }
  }

  /// Gibt den Tabellennamen für die Datenbank zurück
  static String get tableName => 'items';

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
      armorCategory: _parseArmorCategory(map['armor_category'] as String?),
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
    ArmorCategory? armorCategory,
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
      armorCategory: armorCategory ?? this.armorCategory,
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
