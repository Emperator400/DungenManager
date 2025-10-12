// lib/game_data/dnd_logic.dart

// Berechnet den Modifikator für einen gegebenen Attributswert.
int getModifier(int score) {
  return ((score - 10) / 2).floor();
}

// Stellt den Modifikator als String dar (z.B. "+2", "-1").
String getModifierString(int score) {
  final modifier = getModifier(score);
  if (modifier >= 0) {
    return "+$modifier";
  }
  return modifier.toString();
}

// Berechnet den Übungsbonus basierend auf dem Level.
int getProficiencyBonus(int level) {
  if (level < 5) return 2;
  if (level < 9) return 3;
  if (level < 13) return 4;
  if (level < 17) return 5;
  return 6;
}