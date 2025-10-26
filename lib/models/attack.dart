import 'package:uuid/uuid.dart';

var uuid = const Uuid();

class Attack {
  final String id;
  final String name;
  final int attackBonus;
  final String damageDice;
  final int damageBonus;
  final String damageType;
  final String? description;
  final String? range; // z.B. "Nahkampf", "Fernkampf (30/120)"
  final bool isProficient;
  final String? abilityUsed; // "STR", "DEX", "CON", "INT", "WIS", "CHA"

  Attack({
    String? id,
    required this.name,
    required this.attackBonus,
    required this.damageDice,
    this.damageBonus = 0,
    required this.damageType,
    this.description,
    this.range,
    this.isProficient = true,
    this.abilityUsed,
  }) : id = id ?? uuid.v4();

  // Factory-Constructor für leeren Angriff
  factory Attack.empty() {
    return Attack(
      name: '',
      attackBonus: 0,
      damageDice: '1W6',
      damageType: 'Stichschaden',
      isProficient: true,
    );
  }

  // Factory-Constructor aus Text-Format (für Abwärtskompatibilität)
  factory Attack.fromString(String attackString) {
    // Parser für Format: "Schwerthieb: +4 (1W8+2) Hiebschaden"
    final regex = RegExp(r'^(.+?):\s*([+-]?\d+)\s*\(([^)]+)\)\s*(.+)$');
    final match = regex.firstMatch(attackString);
    
    if (match != null) {
      final name = match.group(1)!.trim();
      final attackBonus = int.tryParse(match.group(2)!) ?? 0;
      final damagePart = match.group(3)!.trim();
      final damageType = match.group(4)!.trim();
      
      // Parse damage wie "1W8+2" oder "2W6"
      final damageRegex = RegExp(r'^(\d+)W(\d+)(?:\s*([+-]\s*\d+))?$');
      final damageMatch = damageRegex.firstMatch(damagePart);
      
      String damageDice = '1W6';
      int damageBonus = 0;
      
      if (damageMatch != null) {
        final diceCount = damageMatch.group(1)!;
        final diceType = damageMatch.group(2)!;
        final bonusPart = damageMatch.group(3)?.replaceAll(' ', '') ?? '';
        
        damageDice = '${diceCount}W$diceType';
        damageBonus = int.tryParse(bonusPart) ?? 0;
      }
      
      return Attack(
        name: name,
        attackBonus: attackBonus,
        damageDice: damageDice,
        damageBonus: damageBonus,
        damageType: damageType,
      );
    }
    
    // Fallback: Einfacher Angriff mit geparstem Namen
    return Attack(
      name: attackString,
      attackBonus: 0,
      damageDice: '1W6',
      damageType: 'Schaden',
    );
  }

  // Konvertierung zu Text-Format (für Abwärtskompatibilität)
  String toFormattedString() {
    final bonus = attackBonus >= 0 ? '+$attackBonus' : '$attackBonus';
    final totalDamage = damageBonus != 0 ? '$damageDice+$damageBonus' : damageDice;
    return '$name: $bonus ($totalDamage) $damageType';
  }

  // Berechne totalen Schaden
  String get totalDamage {
    if (damageBonus != 0) {
      return '$damageDice+$damageBonus';
    }
    return damageDice;
  }

  // Berechne formatierten Angriffsbonus
  String get formattedAttackBonus {
    return attackBonus >= 0 ? '+$attackBonus' : '$attackBonus';
  }

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
      id: map['id'],
      name: map['name'] ?? '',
      attackBonus: map['attack_bonus'] ?? 0,
      damageDice: map['damage_dice'] ?? '1W6',
      damageBonus: map['damage_bonus'] ?? 0,
      damageType: map['damage_type'] ?? 'Schaden',
      description: map['description'],
      range: map['range'],
      isProficient: (map['is_proficient'] ?? 1) == 1,
      abilityUsed: map['ability_used'],
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
  String toString() {
    return toFormattedString();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Attack && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// Helper-Klasse für das Parsen und Konvertieren
class AttackHelper {
  // Konvertiere String-Liste zu Attack-Liste
  static List<Attack> parseAttacksFromString(String attacksString) {
    if (attacksString.trim().isEmpty) return [];
    
    final lines = attacksString.split('\n');
    final attacks = <Attack>[];
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty) {
        try {
          attacks.add(Attack.fromString(trimmedLine));
        } catch (e) {
          // Bei Fehlern den rohen Text als Angriffsnamen verwenden
          attacks.add(Attack(
            name: trimmedLine,
            attackBonus: 0,
            damageDice: '1W6',
            damageType: 'Schaden',
          ));
        }
      }
    }
    
    return attacks;
  }

  // Konvertiere Attack-Liste zu String
  static String attacksToString(List<Attack> attacks) {
    if (attacks.isEmpty) return '';
    
    return attacks
        .map((attack) => attack.toFormattedString())
        .join('\n');
  }

  // Liste der gängigen Schadensarten
  static const List<String> commonDamageTypes = [
    'Stichschaden',
    'Hiebschaden', 
    'Wuchtschaden',
    'Feuerschaden',
    'Kälteschaden',
    'Elektrizitätsschaden',
    'Säureschaden',
    'Giftschaden',
    'Psychischer Schaden',
    'Strahlungsschaden',
    'Nekrotischer Schaden',
    'Lichtschaden',
    'Kraftschaden',
    'Donnerschaden',
  ];

  // Liste der gängigen Würfel
  static const List<String> commonDice = [
    '1W2',
    '1W4', 
    '1W6',
    '1W8',
    '1W10',
    '1W12',
    '2W4',
    '2W6',
    '2W8',
    '2W10',
    '2W12',
    '3W6',
    '3W8',
    '4W6',
    '4W8',
    '6W6',
    '8W6',
  ];

  // Liste der Fähigkeiten
  static const List<String> abilities = [
    'STR',
    'DEX', 
    'CON',
    'INT',
    'WIS',
    'CHA',
  ];

  // Liste der Reichweiten
  static const List<String> commonRanges = [
    'Nahkampf',
    'Fernkampf (30/120)',
    'Fernkampf (60/240)',
    'Fernkampf (80/320)',
    'Fernkampf (100/400)',
    'Berührung',
    'Selbst',
  ];
}
