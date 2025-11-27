import '../utils/model_parsing_helper.dart';

enum EffectType {
  // Attribut-Effekte
  strengthBonus,
  dexterityBonus,
  constitutionBonus,
  intelligenceBonus,
  wisdomBonus,
  charismaBonus,
  
  // Kampfeffekte
  armorClassBonus,
  attackBonus,
  damageBonus,
  savingThrowBonus,
  
  // Heilungseffekte
  healHitPoints,
  temporaryHitPoints,
  removeConditions,
  
  // temporäre Effekte
  resistance,
  immunity,
  advantage,
  disadvantage,
  
  // Sonstige Effekte
  custom,
}

enum EffectDuration {
  instant,        // Sofortiger Effekt
  shortRest,      // Bis zum kurzen Ausruhen
  longRest,        // Bis zum langen Ausruhen
  oneHour,         // 1 Stunde
  eightHours,      // 8 Stunden
  twentyFourHours,  // 24 Stunden
  permanent,       // Permanent
  concentration,   // Solange konzentriert
  custom,          // Benutzerdefinierte Dauer
}

class ItemEffect {
  final String id;
  final String itemId; // Referenz zum Item
  final String name;
  final String description;
  final EffectType effectType;
  final int value; // Effekt-Stärke (z.B. +2 STR, 1d8 Heilung)
  final EffectDuration duration;
  final int? durationValue; // Für benutzerdefinierte Dauer in Minuten/Runden
  final bool requiresConcentration;
  final bool requiresAttunement;
  final int maxCharges; // Maximale Aufladungen
  final int currentCharges; // Aktuelle Aufladungen
  final DateTime? lastUsed; // Zuletzt verwendet
  final bool isActive; // Ob der Effekt gerade aktiv ist
  final DateTime? activatedAt; // Wann der Effekt aktiviert wurde
  final String? targetCharacterId; // Ziel des Effekts

  const ItemEffect({
    required this.id,
    required this.itemId,
    required this.name,
    required this.description,
    required this.effectType,
    required this.value,
    required this.duration,
    this.durationValue,
    this.requiresConcentration = false,
    this.requiresAttunement = false,
    this.maxCharges = 1,
    this.currentCharges = 1,
    this.lastUsed,
    this.isActive = false,
    this.activatedAt,
    this.targetCharacterId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'item_id': itemId,
      'name': name,
      'description': description,
      'effect_type': effectType.toString(),
      'value': value,
      'duration': duration.toString(),
      'duration_value': durationValue,
      'requires_concentration': requiresConcentration ? 1 : 0,
      'requires_attunement': requiresAttunement ? 1 : 0,
      'max_charges': maxCharges,
      'current_charges': currentCharges,
      'last_used': lastUsed?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'activated_at': activatedAt?.toIso8601String(),
      'target_character_id': targetCharacterId,
    };
  }

  factory ItemEffect.fromMap(Map<String, dynamic> map) {
    return ItemEffect(
      id: ModelParsingHelper.safeId(map, 'id'),
      itemId: ModelParsingHelper.safeString(map, 'item_id', ''),
      name: ModelParsingHelper.safeString(map, 'name', ''),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      effectType: EffectType.values.firstWhere(
        (e) => e.toString() == ModelParsingHelper.safeString(map, 'effect_type', ''),
        orElse: () => EffectType.custom,
      ),
      value: ModelParsingHelper.safeInt(map, 'value', 0),
      duration: EffectDuration.values.firstWhere(
        (e) => e.toString() == ModelParsingHelper.safeString(map, 'duration', ''),
        orElse: () => EffectDuration.custom,
      ),
      durationValue: ModelParsingHelper.safeIntOrNull(map, 'duration_value', null),
      requiresConcentration: ModelParsingHelper.safeBool(map, 'requires_concentration', false),
      requiresAttunement: ModelParsingHelper.safeBool(map, 'requires_attunement', false),
      maxCharges: ModelParsingHelper.safeInt(map, 'max_charges', 1),
      currentCharges: ModelParsingHelper.safeInt(map, 'current_charges', 1),
      lastUsed: DateTime.tryParse(ModelParsingHelper.safeString(map, 'last_used', '')),
      isActive: ModelParsingHelper.safeBool(map, 'is_active', false),
      activatedAt: DateTime.tryParse(ModelParsingHelper.safeString(map, 'activated_at', '')),
      targetCharacterId: ModelParsingHelper.safeStringOrNull(map, 'target_character_id', null),
    );
  }

  ItemEffect copyWith({
    String? id,
    String? itemId,
    String? name,
    String? description,
    EffectType? effectType,
    int? value,
    EffectDuration? duration,
    int? durationValue,
    bool? requiresConcentration,
    bool? requiresAttunement,
    int? maxCharges,
    int? currentCharges,
    DateTime? lastUsed,
    bool? isActive,
    DateTime? activatedAt,
    String? targetCharacterId,
  }) {
    return ItemEffect(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      description: description ?? this.description,
      effectType: effectType ?? this.effectType,
      value: value ?? this.value,
      duration: duration ?? this.duration,
      durationValue: durationValue ?? this.durationValue,
      requiresConcentration: requiresConcentration ?? this.requiresConcentration,
      requiresAttunement: requiresAttunement ?? this.requiresAttunement,
      maxCharges: maxCharges ?? this.maxCharges,
      currentCharges: currentCharges ?? this.currentCharges,
      lastUsed: lastUsed ?? this.lastUsed,
      isActive: isActive ?? this.isActive,
      activatedAt: activatedAt ?? this.activatedAt,
      targetCharacterId: targetCharacterId ?? this.targetCharacterId,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ItemEffect && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ItemEffect(id: $id, name: $name, type: $effectType)';
}

class ActiveEffect {
  final String id;
  final String characterId;
  final String itemEffectId;
  final String sourceItemName;
  final String effectName;
  final String description;
  final EffectType effectType;
  final int value;
  final DateTime startedAt;
  final DateTime? expiresAt;
  final bool requiresConcentration;

  const ActiveEffect({
    required this.id,
    required this.characterId,
    required this.itemEffectId,
    required this.sourceItemName,
    required this.effectName,
    required this.description,
    required this.effectType,
    required this.value,
    required this.startedAt,
    this.expiresAt,
    this.requiresConcentration = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'character_id': characterId,
      'item_effect_id': itemEffectId,
      'source_item_name': sourceItemName,
      'effect_name': effectName,
      'description': description,
      'effect_type': effectType.toString(),
      'value': value,
      'started_at': startedAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'requires_concentration': requiresConcentration ? 1 : 0,
    };
  }

  factory ActiveEffect.fromMap(Map<String, dynamic> map) {
    return ActiveEffect(
      id: ModelParsingHelper.safeId(map, 'id'),
      characterId: ModelParsingHelper.safeString(map, 'character_id', ''),
      itemEffectId: ModelParsingHelper.safeString(map, 'item_effect_id', ''),
      sourceItemName: ModelParsingHelper.safeString(map, 'source_item_name', ''),
      effectName: ModelParsingHelper.safeString(map, 'effect_name', ''),
      description: ModelParsingHelper.safeString(map, 'description', ''),
      effectType: EffectType.values.firstWhere(
        (e) => e.toString() == ModelParsingHelper.safeString(map, 'effect_type', ''),
        orElse: () => EffectType.custom,
      ),
      value: ModelParsingHelper.safeInt(map, 'value', 0),
      startedAt: DateTime.tryParse(ModelParsingHelper.safeString(map, 'started_at', '')) ?? DateTime.now(),
      expiresAt: DateTime.tryParse(ModelParsingHelper.safeString(map, 'expires_at', '')),
      requiresConcentration: ModelParsingHelper.safeBool(map, 'requires_concentration', false),
    );
  }

  ActiveEffect copyWith({
    String? id,
    String? characterId,
    String? itemEffectId,
    String? sourceItemName,
    String? effectName,
    String? description,
    EffectType? effectType,
    int? value,
    DateTime? startedAt,
    DateTime? expiresAt,
    bool? requiresConcentration,
  }) {
    return ActiveEffect(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      itemEffectId: itemEffectId ?? this.itemEffectId,
      sourceItemName: sourceItemName ?? this.sourceItemName,
      effectName: effectName ?? this.effectName,
      description: description ?? this.description,
      effectType: effectType ?? this.effectType,
      value: value ?? this.value,
      startedAt: startedAt ?? this.startedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      requiresConcentration: requiresConcentration ?? this.requiresConcentration,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveEffect && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'ActiveEffect(id: $id, effectName: $effectName, character: $characterId)';
}
