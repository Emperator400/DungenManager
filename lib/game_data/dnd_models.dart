// lib/game_data/dnd_models.dart

// Wir definieren die 6 Hauptattribute als Enum für Typsicherheit
enum Ability { strength, dexterity, constitution, intelligence, wisdom, charisma }

// Definition einer D&D-Klasse
class DndClass {
  final String name;
  final int hitDie; // z.B. 6 für Zauberer, 10 für Kämpfer
  final List<Ability> savingThrowProficiencies;

  const DndClass({
    required this.name,
    required this.hitDie,
    required this.savingThrowProficiencies,
  });
}

// Definition einer D&D-Rasse
class DndRace {
  final String name;
  // z.B. Berghüterzwerg: {Ability.strength: 2, Ability.constitution: 2}
  final Map<Ability, int> abilityScoreBonuses;

  const DndRace({
    required this.name,
    required this.abilityScoreBonuses,
  });
}

class DndSkill {
  final String name;
  final Ability ability; // Das Attribut, auf dem die Fähigkeit basiert

  const DndSkill({required this.name, required this.ability});
}