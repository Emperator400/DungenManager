import 'package:dungen_manager/models/creature.dart';

/// Extension Methoden für Creature Model
extension CreatureExtension on Creature {
  /// Erstellt ein Creature aus einem OfficialMonster
  static Creature fromOfficialMonster({
    required String officialMonsterId,
    required String name,
    required int maxHp,
    required int armorClass,
    required String speed,
    required int strength,
    required int dexterity,
    required int constitution,
    required int intelligence,
    required int wisdom,
    required int charisma,
    String? size,
    String? type,
    String? subtype,
    String? alignment,
    int? challengeRating,
    String? specialAbilities,
    String? legendaryActions,
    String? description,
    String version = '1.0',
  }) {
    return Creature(
      id: officialMonsterId,
      name: name,
      maxHp: maxHp,
      armorClass: armorClass,
      speed: speed,
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
      wisdom: wisdom,
      charisma: charisma,
      size: size,
      type: type,
      subtype: subtype,
      alignment: alignment,
      challengeRating: challengeRating,
      specialAbilities: specialAbilities,
      legendaryActions: legendaryActions,
      description: description,
      sourceType: 'official',
      sourceId: officialMonsterId,
      isCustom: false,
      isFavorite: false,
      version: version,
    );
  }
}
