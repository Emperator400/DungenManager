import '../models/attack.dart';

class AttackParserService {
  /// Parst einen Angriff aus einem Text-Format
  /// Format: "Schwerthieb: +4 (1W8+2) Hiebschaden"
  static Attack parseFromString(String attackString) {
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
        id: '', // Muss vom Aufrufer gesetzt werden
        name: name,
        attackBonus: attackBonus,
        damageDice: damageDice,
        damageBonus: damageBonus,
        damageType: damageType,
      );
    }
    
    // Fallback: Einfacher Angriff mit geparstem Namen
    return Attack(
      id: '', // Muss vom Aufrufer gesetzt werden
      name: attackString,
      attackBonus: 0,
      damageDice: '1W6',
      damageType: 'Schaden',
    );
  }

  /// Konvertiert String-Liste zu Attack-Liste
  static List<Attack> parseAttacksFromString(String attacksString) {
    if (attacksString.trim().isEmpty) return [];
    
    final lines = attacksString.split('\n');
    final attacks = <Attack>[];
    
    for (final line in lines) {
      final trimmedLine = line.trim();
      if (trimmedLine.isNotEmpty) {
        try {
          final attack = parseFromString(trimmedLine);
          attacks.add(attack);
        } catch (e) {
          // Bei Fehlern den rohen Text als Angriffsnamen verwenden
          attacks.add(Attack(
            id: '', // Muss vom Aufrufer gesetzt werden
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
}
