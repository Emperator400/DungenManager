// lib/models/item_effect.dart
import 'package:uuid/uuid.dart';

var uuid = const Uuid();

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

  ItemEffect({
    String? id,
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
  }) : id = id ?? uuid.v4();

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
      id: map['id'],
      itemId: map['item_id'],
      name: map['name'],
      description: map['description'],
      effectType: EffectType.values.firstWhere((e) => e.toString() == map['effect_type']),
      value: map['value'],
      duration: EffectDuration.values.firstWhere((e) => e.toString() == map['duration']),
      durationValue: map['duration_value'],
      requiresConcentration: map['requires_concentration'] == 1,
      requiresAttunement: map['requires_attunement'] == 1,
      maxCharges: map['max_charges'],
      currentCharges: map['current_charges'],
      lastUsed: map['last_used'] != null ? DateTime.parse(map['last_used']) : null,
      isActive: map['is_active'] == 1,
      activatedAt: map['activated_at'] != null ? DateTime.parse(map['activated_at']) : null,
      targetCharacterId: map['target_character_id'],
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

  // Prüft, ob der Effekt verwendet werden kann
  bool get canUse => currentCharges > 0 && !isActive;

  // Prüft, ob der Effekt abgelaufen ist
  bool get isExpired {
    if (!isActive || activatedAt == null) return false;
    
    switch (duration) {
      case EffectDuration.instant:
        return true; // Sofortige Effekte sind sofort "abgelaufen"
      case EffectDuration.shortRest:
        // Nach kurzer Ausruhen abgelaufen
        return DateTime.now().difference(activatedAt!).inMinutes > 60;
      case EffectDuration.longRest:
        // Nach langem Ausruhen abgelaufen
        return DateTime.now().difference(activatedAt!).inHours > 8;
      case EffectDuration.oneHour:
        return DateTime.now().difference(activatedAt!).inHours > 1;
      case EffectDuration.eightHours:
        return DateTime.now().difference(activatedAt!).inHours > 8;
      case EffectDuration.twentyFourHours:
        return DateTime.now().difference(activatedAt!).inHours > 24;
      case EffectDuration.concentration:
        // Konzentration wird manuell beendet
        return false;
      case EffectDuration.permanent:
        return false; // Permanent nie abgelaufen
      case EffectDuration.custom:
        if (durationValue != null) {
          return DateTime.now().difference(activatedAt!).inMinutes > durationValue!;
        }
        return false;
      default:
        return false;
    }
  }

  // Gibt die verbleibende Dauer als lesbaren String zurück
  String get remainingDuration {
    if (!isActive || activatedAt == null) return 'Nicht aktiv';
    
    final now = DateTime.now();
    final difference = now.difference(activatedAt!);
    
    switch (duration) {
      case EffectDuration.instant:
        return 'Sofort';
      case EffectDuration.shortRest:
        final remaining = 60 - difference.inMinutes;
        return remaining > 0 ? '$remaining Min (Kurz)' : 'Abgelaufen';
      case EffectDuration.longRest:
        final remaining = 480 - difference.inMinutes; // 8 Stunden
        return remaining > 0 ? '${(remaining / 60).floor()}h ${remaining % 60}min (Lang)' : 'Abgelaufen';
      case EffectDuration.oneHour:
        final remaining = 60 - difference.inMinutes;
        return remaining > 0 ? '$remaining Min' : 'Abgelaufen';
      case EffectDuration.eightHours:
        final remaining = 480 - difference.inMinutes;
        return remaining > 0 ? '${(remaining / 60).floor()}h ${remaining % 60}min' : 'Abgelaufen';
      case EffectDuration.twentyFourHours:
        final remaining = 1440 - difference.inMinutes; // 24 Stunden
        return remaining > 0 ? '${(remaining / 60).floor()}h' : 'Abgelaufen';
      case EffectDuration.concentration:
        return 'Konzentration';
      case EffectDuration.permanent:
        return 'Permanent';
      case EffectDuration.custom:
        if (durationValue != null) {
          final remaining = durationValue! - difference.inMinutes;
          return remaining > 0 ? '$remaining Min' : 'Abgelaufen';
        }
        return 'Unbekannt';
      default:
        return 'Unbekannt';
    }
  }

  // Gibt einen lesbaren Namen für den Effekttyp zurück
  String get effectTypeName {
    switch (effectType) {
      case EffectType.strengthBonus:
        return 'Stärke-Bonus';
      case EffectType.dexterityBonus:
        return 'Geschicklichkeits-Bonus';
      case EffectType.constitutionBonus:
        return 'Konstitutions-Bonus';
      case EffectType.intelligenceBonus:
        return 'Intelligenz-Bonus';
      case EffectType.wisdomBonus:
        return 'Weisheits-Bonus';
      case EffectType.charismaBonus:
        return 'Charisma-Bonus';
      case EffectType.armorClassBonus:
        return 'Rüstungsklassen-Bonus';
      case EffectType.attackBonus:
        return 'Angriffs-Bonus';
      case EffectType.damageBonus:
        return 'Schadens-Bonus';
      case EffectType.savingThrowBonus:
        return 'Rettungswurf-Bonus';
      case EffectType.healHitPoints:
        return 'Heilung';
      case EffectType.temporaryHitPoints:
        return 'Temporäre TP';
      case EffectType.removeConditions:
        return 'Zustände entfernen';
      case EffectType.resistance:
        return 'Resistenz';
      case EffectType.immunity:
        return 'Immunität';
      case EffectType.advantage:
        return 'Vorteil';
      case EffectType.disadvantage:
        return 'Nachteil';
      case EffectType.custom:
        return 'Benutzerdefiniert';
    }
  }

  // Gibt einen lesbaren String für die Dauer zurück
  String get durationName {
    switch (duration) {
      case EffectDuration.instant:
        return 'Sofort';
      case EffectDuration.shortRest:
        return 'Bis zum Kurz-Ausruhen';
      case EffectDuration.longRest:
        return 'Bis zum Lang-Ausruhen';
      case EffectDuration.oneHour:
        return '1 Stunde';
      case EffectDuration.eightHours:
        return '8 Stunden';
      case EffectDuration.twentyFourHours:
        return '24 Stunden';
      case EffectDuration.concentration:
        return 'Konzentration';
      case EffectDuration.permanent:
        return 'Permanent';
      case EffectDuration.custom:
        return durationValue != null ? '$durationValue Minuten' : 'Benutzerdefiniert';
    }
  }

  // Gibt einen formatierten Wert-String zurück
  String get formattedValue {
    switch (effectType) {
      case EffectType.healHitPoints:
      case EffectType.temporaryHitPoints:
        return '$value TP';
      case EffectType.removeConditions:
        return '$value Zustände';
      case EffectType.resistance:
      case EffectType.immunity:
        return value > 0 ? 'Schadenstyp $value' : 'Alle Schadenstypen';
      case EffectType.advantage:
      case EffectType.disadvantage:
        return value > 0 ? 'Bei $value Würfen' : 'Bei 1 Wurf';
      default:
        // Bei Bonus-Effekten
        return value >= 0 ? '+$value' : '$value';
    }
  }
}

// Hilfsklasse für aktive Effekte auf einem Charakter
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

  ActiveEffect({
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
      id: map['id'],
      characterId: map['character_id'],
      itemEffectId: map['item_effect_id'],
      sourceItemName: map['source_item_name'],
      effectName: map['effect_name'],
      description: map['description'],
      effectType: EffectType.values.firstWhere((e) => e.toString() == map['effect_type']),
      value: map['value'],
      startedAt: DateTime.parse(map['started_at']),
      expiresAt: map['expires_at'] != null ? DateTime.parse(map['expires_at']) : null,
      requiresConcentration: map['requires_concentration'] == 1,
    );
  }

  bool get isActive {
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt!);
  }

  String get timeRemaining {
    if (expiresAt == null) return 'Permanent';
    
    final now = DateTime.now();
    final difference = expiresAt!.difference(now);
    
    if (difference.isNegative) return 'Abgelaufen';
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}min';
    } else {
      return '${difference.inMinutes}min';
    }
  }
}
