import '../models/attack.dart';

class AttackFormatter {
  /// Konvertiert einen Angriff zu Text-Format
  /// Format: "Schwerthieb: +4 (1W8+2) Hiebschaden"
  static String toFormattedString(Attack attack) {
    final bonus = attack.attackBonus >= 0 ? '+${attack.attackBonus}' : '${attack.attackBonus}';
    final totalDamage = attack.damageBonus != 0 ? '${attack.damageDice}+${attack.damageBonus}' : attack.damageDice;
    return '${attack.name}: $bonus ($totalDamage) ${attack.damageType}';
  }

  /// Konvertiert Attack-Liste zu String
  static String attacksToString(List<Attack> attacks) {
    if (attacks.isEmpty) return '';
    
    return attacks
        .map((attack) => toFormattedString(attack))
        .join('\n');
  }

  /// Berechne totalen Schaden
  static String getTotalDamage(Attack attack) {
    if (attack.damageBonus != 0) {
      return '${attack.damageDice}+${attack.damageBonus}';
    }
    return attack.damageDice;
  }

  /// Berechne formatierten Angriffsbonus
  static String getFormattedAttackBonus(Attack attack) {
    return attack.attackBonus >= 0 ? '+${attack.attackBonus}' : '${attack.attackBonus}';
  }
}
