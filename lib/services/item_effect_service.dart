import '../models/item_effect.dart';

// Enums werden aus item_effect.dart importiert

/// Service für ItemEffect Business-Logik
class ItemEffectService {
  /// Prüft, ob der Effekt verwendet werden kann
  static bool canUse(ItemEffect effect) {
    return effect.currentCharges > 0 && !effect.isActive;
  }

  /// Prüft, ob der Effekt abgelaufen ist
  static bool isExpired(ItemEffect effect) {
    if (!effect.isActive || effect.activatedAt == null) return false;
    
    switch (effect.duration) {
      case EffectDuration.instant:
        return true; // Sofortige Effekte sind sofort "abgelaufen"
      case EffectDuration.shortRest:
        // Nach kurzer Ausruhen abgelaufen
        return DateTime.now().difference(effect.activatedAt!).inMinutes > 60;
      case EffectDuration.longRest:
        // Nach langem Ausruhen abgelaufen
        return DateTime.now().difference(effect.activatedAt!).inHours > 8;
      case EffectDuration.oneHour:
        return DateTime.now().difference(effect.activatedAt!).inHours > 1;
      case EffectDuration.eightHours:
        return DateTime.now().difference(effect.activatedAt!).inHours > 8;
      case EffectDuration.twentyFourHours:
        return DateTime.now().difference(effect.activatedAt!).inHours > 24;
      case EffectDuration.concentration:
        // Konzentration wird manuell beendet
        return false;
      case EffectDuration.permanent:
        return false; // Permanent nie abgelaufen
      case EffectDuration.custom:
        if (effect.durationValue != null) {
          return DateTime.now().difference(effect.activatedAt!).inMinutes > effect.durationValue!;
        }
        return false;
      default:
        return false;
    }
  }

  /// Gibt die verbleibende Dauer als lesbaren String zurück
  static String getRemainingDuration(ItemEffect effect) {
    if (!effect.isActive || effect.activatedAt == null) return 'Nicht aktiv';
    
    final now = DateTime.now();
    final difference = now.difference(effect.activatedAt!);
    
    switch (effect.duration) {
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
        if (effect.durationValue != null) {
          final remaining = effect.durationValue! - difference.inMinutes;
          return remaining > 0 ? '$remaining Min' : 'Abgelaufen';
        }
        return 'Unbekannt';
      default:
        return 'Unbekannt';
    }
  }
}
