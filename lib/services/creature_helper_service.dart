// Eigene Projekte
import '../models/creature.dart';
import '../models/attack.dart';
import '../utils/attack_helper.dart';

/// Service für Helper-Methoden und Konvertierungen von Creature-Objekten
class CreatureHelperService {
  const CreatureHelperService._();
  /// Formatiert Angriffe als String
  static String getFormattedAttacks(Creature creature) {
    if (creature.attackList.isNotEmpty) {
      return AttackHelper.attacksToString(creature.attackList);
    }
    return creature.attacks;
  }
  
  /// Gibt effektive Angriffsliste zurück
  static List<Attack> getEffectiveAttacks(Creature creature) {
    if (creature.attackList.isNotEmpty) {
      return creature.attackList;
    }
    // Fallback zu Legacy-String
    if (creature.attacks.isNotEmpty) {
      return AttackHelper.parseAttacksFromString(creature.attacks);
    }
    return [];
  }

  /// Erstellt eine Kopie des Creature mit angepassten Werten
  static Creature copyWith(Creature creature, {
    String? name,
    int? maxHp,
    int? currentHp,
    int? armorClass,
    String? speed,
    String? attacks,
    int? initiativeBonus,
    int? strength,
    int? dexterity,
    int? constitution,
    int? intelligence,
    int? wisdom,
    int? charisma,
    String? officialMonsterId,
    String? officialSpellIds,
    String? officialItemIds,
    String? size,
    String? type,
    String? subtype,
    String? alignment,
    int? challengeRating,
    String? specialAbilities,
    String? legendaryActions,
    bool? isCustom,
    String? description,
    List<Attack>? attackList,
    String? sourceType,
    String? sourceId,
    bool? isFavorite,
    String? version,
    double? gold,
    double? silver,
    double? copper,
  }) {
    return Creature(
      id: creature.id,
      name: name ?? creature.name,
      maxHp: maxHp ?? creature.maxHp,
      currentHp: currentHp ?? creature.currentHp,
      armorClass: armorClass ?? creature.armorClass,
      speed: speed ?? creature.speed,
      attacks: attacks ?? creature.attacks,
      initiativeBonus: initiativeBonus ?? creature.initiativeBonus,
      strength: strength ?? creature.strength,
      dexterity: dexterity ?? creature.dexterity,
      constitution: constitution ?? creature.constitution,
      intelligence: intelligence ?? creature.intelligence,
      wisdom: wisdom ?? creature.wisdom,
      charisma: charisma ?? creature.charisma,
      isPlayer: creature.isPlayer,
      inventory: creature.inventory,
      gold: gold ?? creature.gold,
      silver: silver ?? creature.silver,
      copper: copper ?? creature.copper,
      officialMonsterId: officialMonsterId ?? creature.officialMonsterId,
      officialSpellIds: officialSpellIds ?? creature.officialSpellIds,
      officialItemIds: officialItemIds ?? creature.officialItemIds,
      size: size ?? creature.size,
      type: type ?? creature.type,
      subtype: subtype ?? creature.subtype,
      alignment: alignment ?? creature.alignment,
      challengeRating: challengeRating ?? creature.challengeRating,
      specialAbilities: specialAbilities ?? creature.specialAbilities,
      legendaryActions: legendaryActions ?? creature.legendaryActions,
      isCustom: isCustom ?? creature.isCustom,
      description: description ?? creature.description,
      attackList: attackList ?? creature.attackList,
      sourceType: sourceType ?? creature.sourceType,
      sourceId: sourceId ?? creature.sourceId,
      isFavorite: isFavorite ?? creature.isFavorite,
      version: version ?? creature.version,
    );
  }

  /// Berechnet den Ability Modifier für einen Attributswert
  static int getAbilityModifier(int abilityScore) {
    return ((abilityScore - 10) / 2).floor();
  }

  /// Prüft ob das Creature bewusstlos ist
  static bool isUnconscious(Creature creature) {
    return creature.currentHp <= 0;
  }

  /// Prüft ob das Creature stabil ist (nicht mehr sterbend)
  static bool isStable(Creature creature) {
    return creature.currentHp <= 0 && 
           !creature.conditions.any((condition) => condition.name.toLowerCase().contains('dying'));
  }

  /// Gibt den Status des Creatures als lesbaren String zurück
  static String getStatusText(Creature creature) {
    if (creature.currentHp <= 0) {
      return isStable(creature) ? 'Stabil' : 'Sterbend';
    }
    
    final hpPercentage = (creature.currentHp / creature.maxHp) * 100;
    if (hpPercentage >= 75) return 'Gesund';
    if (hpPercentage >= 50) return 'Verletzt';
    if (hpPercentage >= 25) return 'Schwer verletzt';
    return 'Kritisch verletzt';
  }
}
