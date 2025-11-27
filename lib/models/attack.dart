import '../utils/model_parsing_helper.dart';

// Extension für Legacy-Kompatibilität und UI-Helper-Funktionen
extension AttackExtension on Attack {
  /// Berechne totalen Schaden
  String get totalDamage {
    if (damageBonus != 0) {
      return '$damageDice+$damageBonus';
    }
    return damageDice;
  }

  /// Berechne formatierten Angriffsbonus
  String get formattedAttackBonus {
    return attackBonus >= 0 ? '+$attackBonus' : '$attackBonus';
  }

  /// Konvertiere zu Text-Format (für Abwärtskompatibilität)
  String toFormattedString() {
    final bonus = attackBonus >= 0 ? '+$attackBonus' : '$attackBonus';
    final totalDamage = this.totalDamage;
    return '$name: $bonus ($totalDamage) $damageType';
  }
}

class Attack {
  final String id;
  final String name;
  final int attackBonus;
  final String damageDice;
  final int damageBonus;
  final String damageType;
  final String? description;
  final String? range;
  final bool isProficient;
  final String? abilityUsed;

  const Attack({
    required this.id,
    required this.name,
    required this.attackBonus,
    required this.damageDice,
    this.damageBonus = 0,
    required this.damageType,
    this.description,
    this.range,
    this.isProficient = true,
    this.abilityUsed,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'attack_bonus': attackBonus,
      'damage_dice': damageDice,
      'damage_bonus': damageBonus,
      'damage_type': damageType,
      'description': description,
      'range': range,
      'is_proficient': isProficient ? 1 : 0,
      'ability_used': abilityUsed,
    };
  }

  factory Attack.fromMap(Map<String, dynamic> map) {
    return Attack(
      id: ModelParsingHelper.safeId(map, 'id'),
      name: ModelParsingHelper.safeString(map, 'name', ''),
      attackBonus: ModelParsingHelper.safeInt(map, 'attack_bonus', 0),
      damageDice: ModelParsingHelper.safeString(map, 'damage_dice', '1W6'),
      damageBonus: ModelParsingHelper.safeInt(map, 'damage_bonus', 0),
      damageType: ModelParsingHelper.safeString(map, 'damage_type', 'Schaden'),
      description: ModelParsingHelper.safeStringOrNull(map, 'description', null),
      range: ModelParsingHelper.safeStringOrNull(map, 'range', null),
      isProficient: ModelParsingHelper.safeBool(map, 'is_proficient', true),
      abilityUsed: ModelParsingHelper.safeStringOrNull(map, 'ability_used', null),
    );
  }

  Attack copyWith({
    String? id,
    String? name,
    int? attackBonus,
    String? damageDice,
    int? damageBonus,
    String? damageType,
    String? description,
    String? range,
    bool? isProficient,
    String? abilityUsed,
  }) {
    return Attack(
      id: id ?? this.id,
      name: name ?? this.name,
      attackBonus: attackBonus ?? this.attackBonus,
      damageDice: damageDice ?? this.damageDice,
      damageBonus: damageBonus ?? this.damageBonus,
      damageType: damageType ?? this.damageType,
      description: description ?? this.description,
      range: range ?? this.range,
      isProficient: isProficient ?? this.isProficient,
      abilityUsed: abilityUsed ?? this.abilityUsed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attack && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Attack(id: $id, name: $name)';
}
