class EquipBonusFormatter {
  static String getBonusSummary({
    int? strengthBonus,
    int? dexterityBonus,
    int? constitutionBonus,
    int? intelligenceBonus,
    int? wisdomBonus,
    int? charismaBonus,
    int? armorClassBonus,
    int? attackBonus,
    int? damageBonus,
    int? savingThrowBonus,
  }) {
    final bonuses = <String>[];
    
    if (strengthBonus != null && strengthBonus != 0) {
      bonuses.add('ST ${strengthBonus > 0 ? "+$strengthBonus" : strengthBonus}');
    }
    if (dexterityBonus != null && dexterityBonus != 0) {
      bonuses.add('GE ${dexterityBonus > 0 ? "+$dexterityBonus" : dexterityBonus}');
    }
    if (constitutionBonus != null && constitutionBonus != 0) {
      bonuses.add('KO ${constitutionBonus > 0 ? "+$constitutionBonus" : constitutionBonus}');
    }
    if (intelligenceBonus != null && intelligenceBonus != 0) {
      bonuses.add('IN ${intelligenceBonus > 0 ? "+$intelligenceBonus" : intelligenceBonus}');
    }
    if (wisdomBonus != null && wisdomBonus != 0) {
      bonuses.add('WE ${wisdomBonus > 0 ? "+$wisdomBonus" : wisdomBonus}');
    }
    if (charismaBonus != null && charismaBonus != 0) {
      bonuses.add('CH ${charismaBonus > 0 ? "+$charismaBonus" : charismaBonus}');
    }
    if (armorClassBonus != null && armorClassBonus != 0) {
      bonuses.add('RK ${armorClassBonus > 0 ? "+$armorClassBonus" : armorClassBonus}');
    }
    if (attackBonus != null && attackBonus != 0) {
      bonuses.add('Angriff ${attackBonus > 0 ? "+$attackBonus" : attackBonus}');
    }
    if (damageBonus != null && damageBonus != 0) {
      bonuses.add('Schaden ${damageBonus > 0 ? "+$damageBonus" : damageBonus}');
    }
    if (savingThrowBonus != null && savingThrowBonus != 0) {
      bonuses.add('Rettungswürfe ${savingThrowBonus > 0 ? "+$savingThrowBonus" : savingThrowBonus}');
    }
    
    return bonuses.isNotEmpty ? bonuses.join(', ') : 'Keine Boni';
  }
}
