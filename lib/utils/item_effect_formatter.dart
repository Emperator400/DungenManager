import '../models/item_effect.dart';

/// UI-Formatter für ItemEffect
class ItemEffectFormatter {
  /// Gibt einen lesbaren Namen für den Effekttyp zurück
  static String getEffectTypeName(EffectType effectType) {
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

  /// Gibt einen lesbaren String für die Dauer zurück
  static String getDurationName(EffectDuration duration, int? durationValue) {
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

  /// Gibt einen formatierten Wert-String zurück
  static String getFormattedValue(EffectType effectType, int value) {
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

/// UI-Formatter für ActiveEffect
class ActiveEffectFormatter {
  /// Gibt die verbleibende Zeit als lesbaren String zurück
  static String getTimeRemaining(DateTime? expiresAt) {
    if (expiresAt == null) return 'Permanent';
    
    final now = DateTime.now();
    final difference = expiresAt.difference(now);
    
    if (difference.isNegative) return 'Abgelaufen';
    
    if (difference.inHours > 0) {
      return '${difference.inHours}h ${difference.inMinutes % 60}min';
    } else {
      return '${difference.inMinutes}min';
    }
  }
}
