import 'base_entity.dart';
import '../../models/item.dart';

/// Item Entity für die neue Datenbankarchitektur
/// Implementiert BaseEntity für konsistente Struktur und Typ-Sicherheit
class ItemEntity extends BaseEntity {
  // Core Felder
  String _id;
  final String name;
  final String description;
  final ItemType itemType;
  final double weight;
  final double cost; // Goldmünzen
  final String imageUrl;

  // Waffen-Eigenschaften
  final String? damage;
  final String? damageType; // Schadenstyp: Hiebschaden, Stichschaden, Feuerschaden, etc.
  final String? properties;

  // Rüstungs-Eigenschaften
  final String? acFormula;
  final int? strengthRequirement;
  final bool? stealthDisadvantage;

  // Magische Eigenschaften
  final String? rarity;
  final bool? requiresAttunement;

  // Durability-Felder
  final bool? hasDurability;
  final int? maxDurability;
  final bool? isRepairable;

  // Spell-spezifische Eigenschaften
  final String? spellId;
  final bool? isSpell;
  final int? spellLevel;
  final String? spellSchool;
  final bool? isCantrip;
  final int? maxCastsPerDay;
  final bool? requiresConcentration;

  // Metadaten
  final String? officialItemId;
  final String sourceType;
  final String? sourceId;
  final bool isCustom;
  final bool isFavorite;
  final String version;

  // Konstruktor
  ItemEntity({
    required String id,
    required this.name,
    this.description = '',
    required this.itemType,
    this.weight = 0.0,
    this.cost = 0.0,
    this.imageUrl = '',
    this.damage,
    this.damageType,
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
    this.officialItemId,
    this.sourceType = 'custom',
    this.sourceId,
    this.isCustom = true,
    this.isFavorite = false,
    this.version = '1.0',
  }) : _id = id;

  /// Factory für Datenbank-Erstellung
  factory ItemEntity.fromMap(Map<String, dynamic> map) {
    return ItemEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      itemType: _parseItemType(map['item_type'] as String?),
      weight: (map['weight'] as num?)?.toDouble() ?? 0.0,
      cost: (map['cost'] as num?)?.toDouble() ?? 0.0,
      imageUrl: map['image_url'] as String? ?? '',
      damage: map['damage'] as String?,
      damageType: map['damage_type'] as String?,
      properties: map['properties'] as String?,
      acFormula: map['ac_formula'] as String?,
      strengthRequirement: map['strength_requirement'] as int?,
      stealthDisadvantage: map['stealth_disadvantage'] as bool?,
      rarity: map['rarity'] as String?,
      requiresAttunement: map['requires_attunement'] as bool?,
      hasDurability: map['has_durability'] as bool?,
      maxDurability: map['max_durability'] as int?,
      isRepairable: map['is_repairable'] as bool?,
      spellId: map['spell_id'] as String?,
      isSpell: map['is_spell'] as bool?,
      spellLevel: map['spell_level'] as int?,
      spellSchool: map['spell_school'] as String?,
      isCantrip: map['is_cantrip'] as bool?,
      maxCastsPerDay: map['max_casts_per_day'] as int?,
      requiresConcentration: map['requires_concentration'] as bool?,
      officialItemId: map['officialItemId'] as String?,
      sourceType: map['sourceType'] as String? ?? 'custom',
      sourceId: map['sourceId'] as String?,
      isCustom: map['isCustom'] as bool? ?? true,
      isFavorite: map['isFavorite'] as bool? ?? false,
      version: map['version'] as String? ?? '1.0',
    );
  }

  /// Factory von Item Model
  factory ItemEntity.fromModel(Item item) {
    return ItemEntity(
      id: item.id,
      name: item.name,
      description: item.description,
      itemType: item.itemType,
      weight: item.weight,
      cost: item.cost,
      imageUrl: item.imageUrl,
      damage: item.damage,
      damageType: item.damageType,
      properties: item.properties,
      acFormula: item.acFormula,
      strengthRequirement: item.strengthRequirement,
      stealthDisadvantage: item.stealthDisadvantage,
      rarity: item.rarity,
      requiresAttunement: item.requiresAttunement,
      hasDurability: item.hasDurability,
      maxDurability: item.maxDurability,
      isRepairable: item.isRepairable,
      spellId: item.spellId,
      isSpell: item.isSpell,
      spellLevel: item.spellLevel,
      spellSchool: item.spellSchool,
      isCantrip: item.isCantrip,
      maxCastsPerDay: item.maxCastsPerDay,
      requiresConcentration: item.requiresConcentration,
      // Entity-spezifische Felder mit Standardwerten
      officialItemId: null,
      sourceType: 'custom',
      sourceId: null,
      isCustom: true,
      isFavorite: false,
      version: '1.0',
    );
  }

  /// Hilfsmethode zum Parsen von ItemType
  static ItemType _parseItemType(String? itemTypeString) {
    if (itemTypeString == null) return ItemType.Weapon;
    
    try {
      return ItemType.values.firstWhere(
        (type) => type.toString() == 'ItemType.$itemTypeString',
        orElse: () => ItemType.Weapon,
      );
    } catch (e) {
      return ItemType.Weapon;
    }
  }

  /// ID Getter aus BaseEntity
  @override
  String get id => _id;
  
  /// ID Setter aus BaseEntity
  @override
  set id(String value) => _id = value;
  
  /// Metadata Getter aus BaseEntity
  @override
  Map<String, dynamic> get metadata => {
    'entityType': 'Item',
    'tableName': tableName,
    'itemType': itemType.toString(),
    'rarity': rarity,
    'isSpell': isSpell,
    'sourceType': sourceType,
  };
  
  /// Validierung Getter aus BaseEntity
  @override
  bool get isValid {
    return name.isNotEmpty && 
           description.isNotEmpty &&
           weight >= 0 &&
           cost >= 0;
  }
  
  /// Validation Errors Getter aus BaseEntity
  @override
  List<String> get validationErrors {
    final errors = <String>[];
    if (name.isEmpty) errors.add('Name darf nicht leer sein');
    if (description.isEmpty) errors.add('Beschreibung darf nicht leer sein');
    if (weight < 0) errors.add('Gewicht darf nicht negativ sein');
    if (cost < 0) errors.add('Kosten dürfen nicht negativ sein');
    return errors;
  }

  /// Konvertierung zu Map für Datenbank
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
      'damage_type': damageType,
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
      'officialItemId': officialItemId,
      'sourceType': sourceType,
      'sourceId': sourceId,
      'isCustom': isCustom,
      'isFavorite': isFavorite,
      'version': version,
    };
  }

  /// Konvertierung zurück zum Item Model
  Item toModel() {
    return Item(
      id: id,
      name: name,
      description: description,
      itemType: itemType,
      weight: weight,
      cost: cost,
      imageUrl: imageUrl,
      damage: damage,
      damageType: damageType,
      properties: properties,
      acFormula: acFormula,
      strengthRequirement: strengthRequirement,
      stealthDisadvantage: stealthDisadvantage,
      rarity: rarity,
      requiresAttunement: requiresAttunement,
      hasDurability: hasDurability,
      maxDurability: maxDurability,
      isRepairable: isRepairable,
      spellId: spellId,
      isSpell: isSpell,
      spellLevel: spellLevel,
      spellSchool: spellSchool,
      isCantrip: isCantrip,
      maxCastsPerDay: maxCastsPerDay,
      requiresConcentration: requiresConcentration,
    );
  }

  /// Kopie mit geänderten Werten erstellen
  ItemEntity copyWith({
    String? id,
    String? name,
    String? description,
    ItemType? itemType,
    double? weight,
    double? cost,
    String? imageUrl,
    String? damage,
    String? damageType,
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
    String? officialItemId,
    String? sourceType,
    String? sourceId,
    bool? isCustom,
    bool? isFavorite,
    String? version,
  }) {
    return ItemEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      itemType: itemType ?? this.itemType,
      weight: weight ?? this.weight,
      cost: cost ?? this.cost,
      imageUrl: imageUrl ?? this.imageUrl,
      damage: damage ?? this.damage,
      damageType: damageType ?? this.damageType,
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
      officialItemId: officialItemId ?? this.officialItemId,
      sourceType: sourceType ?? this.sourceType,
      sourceId: sourceId ?? this.sourceId,
      isCustom: isCustom ?? this.isCustom,
      isFavorite: isFavorite ?? this.isFavorite,
      version: version ?? this.version,
    );
  }

  /// Datenbank-Tabellenname
  static const String tableName = 'items';

  /// Erstelle Tabelle SQL
  static String createTableSql() {
    return '''
      CREATE TABLE $tableName (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        item_type TEXT NOT NULL,
        weight REAL DEFAULT 0.0,
        cost REAL DEFAULT 0.0,
        image_url TEXT DEFAULT '',
        damage TEXT,
        damage_type TEXT,
        properties TEXT,
        ac_formula TEXT,
        strength_requirement INTEGER,
        stealth_disadvantage INTEGER,
        rarity TEXT,
        requires_attunement INTEGER,
        has_durability INTEGER,
        max_durability INTEGER,
        is_repairable INTEGER,
        spell_id TEXT,
        is_spell INTEGER DEFAULT 0,
        spell_level INTEGER,
        spell_school TEXT,
        is_cantrip INTEGER DEFAULT 0,
        max_casts_per_day INTEGER,
        requires_concentration INTEGER DEFAULT 0,
        officialItemId TEXT,
        sourceType TEXT DEFAULT 'custom',
        sourceId TEXT,
        isCustom INTEGER DEFAULT 1,
        isFavorite INTEGER DEFAULT 0,
        version TEXT DEFAULT '1.0'
      )
    ''';
  }

  @override
  String toString() {
    return 'ItemEntity(id: $id, name: $name, type: $itemType, rarity: $rarity)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemEntity &&
           other.id == id &&
           other.name == name &&
           other.itemType == itemType;
  }

  @override
  int get hashCode {
    return id.hashCode ^
           name.hashCode ^
           itemType.hashCode;
  }
}
