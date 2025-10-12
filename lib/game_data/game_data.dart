// lib/game_data/game_data.dart
import 'dnd_models.dart';

// --- KLASSEN-BIBLIOTHEK ---

const DndClass barbarian = DndClass(name: "Barbar", hitDie: 12, savingThrowProficiencies: [Ability.strength, Ability.constitution]);
const DndClass bard = DndClass(name: "Barde", hitDie: 8, savingThrowProficiencies: [Ability.dexterity, Ability.charisma]);
const DndClass cleric = DndClass(name: "Kleriker", hitDie: 8, savingThrowProficiencies: [Ability.wisdom, Ability.charisma]);
const DndClass druid = DndClass(name: "Druide", hitDie: 8, savingThrowProficiencies: [Ability.intelligence, Ability.wisdom]);
const DndClass fighter = DndClass(name: "Kämpfer", hitDie: 10, savingThrowProficiencies: [Ability.strength, Ability.constitution]);
const DndClass monk = DndClass(name: "Mönch", hitDie: 8, savingThrowProficiencies: [Ability.strength, Ability.dexterity]);
const DndClass paladin = DndClass(name: "Paladin", hitDie: 10, savingThrowProficiencies: [Ability.wisdom, Ability.charisma]);
const DndClass ranger = DndClass(name: "Waldläufer", hitDie: 10, savingThrowProficiencies: [Ability.strength, Ability.dexterity]);
const DndClass rogue = DndClass(name: "Schurke", hitDie: 8, savingThrowProficiencies: [Ability.dexterity, Ability.intelligence]);
const DndClass sorcerer = DndClass(name: "Hexenmeister", hitDie: 6, savingThrowProficiencies: [Ability.constitution, Ability.charisma]);
const DndClass warlock = DndClass(name: "Paktmagier", hitDie: 8, savingThrowProficiencies: [Ability.wisdom, Ability.charisma]);
const DndClass wizard = DndClass(name: "Zauberer", hitDie: 6, savingThrowProficiencies: [Ability.intelligence, Ability.wisdom]);

// Die vollständige, globale Liste aller Klassen
const List<DndClass> allDndClasses = [
  barbarian, bard, cleric, druid, fighter, monk, paladin, 
  ranger, rogue, sorcerer, warlock, wizard,
];


// --- RASSEN-BIBLIOTHEK ---

const DndRace dwarf = DndRace(name: "Zwerg", abilityScoreBonuses: {Ability.constitution: 2});
const DndRace elf = DndRace(name: "Elf", abilityScoreBonuses: {Ability.dexterity: 2});
const DndRace halfling = DndRace(name: "Halbling", abilityScoreBonuses: {Ability.dexterity: 2});
const DndRace human = DndRace(name: "Mensch", abilityScoreBonuses: {
  Ability.strength: 1, Ability.dexterity: 1, Ability.constitution: 1,
  Ability.intelligence: 1, Ability.wisdom: 1, Ability.charisma: 1,
});
const DndRace dragonborn = DndRace(name: "Drachenblütiger", abilityScoreBonuses: {Ability.strength: 2, Ability.charisma: 1});
const DndRace gnome = DndRace(name: "Gnom", abilityScoreBonuses: {Ability.intelligence: 2});
const DndRace halfElf = DndRace(name: "Halb-Elf", abilityScoreBonuses: {Ability.charisma: 2}); // Plus zwei +1 Boni, die wir später implementieren können
const DndRace halfOrc = DndRace(name: "Halb-Ork", abilityScoreBonuses: {Ability.strength: 2, Ability.constitution: 1});
const DndRace tiefling = DndRace(name: "Tiefling", abilityScoreBonuses: {Ability.intelligence: 1, Ability.charisma: 2});

// Die vollständige, globale Liste aller Rassen
const List<DndRace> allDndRaces = [
  dwarf, elf, halfling, human, dragonborn, gnome, halfElf, halfOrc, tiefling,
];

// --- FÄHIGKEITS-BIBLIOTHEK ---
const DndSkill acrobatics = DndSkill(name: "Akrobatik", ability: Ability.dexterity);
const DndSkill animalHandling = DndSkill(name: "Umgang mit Tieren", ability: Ability.wisdom);
const DndSkill arcana = DndSkill(name: "Arkanes Wissen", ability: Ability.intelligence);
const DndSkill athletics = DndSkill(name: "Athletik", ability: Ability.strength);
const DndSkill deception = DndSkill(name: "Täuschung", ability: Ability.charisma);
const DndSkill history = DndSkill(name: "Geschichte", ability: Ability.intelligence);
const DndSkill insight = DndSkill(name: "Einschätzung", ability:  Ability.wisdom);
const DndSkill intimidation = DndSkill(name: "Einschüchterung", ability: Ability.charisma);
const DndSkill investigation = DndSkill(name: "Ermittlung", ability: Ability.intelligence);
const DndSkill medicine = DndSkill(name: "Medizin", ability: Ability.wisdom);
const DndSkill nature = DndSkill(name: "Natur", ability: Ability.intelligence);
const DndSkill perception = DndSkill(name: "Wahrnehmung", ability: Ability.wisdom);
const DndSkill performance = DndSkill(name: "Darstellung", ability: Ability.charisma);
const DndSkill persuasion = DndSkill(name: "Überredung", ability: Ability.charisma);
const DndSkill religion = DndSkill(name: "Religion", ability: Ability.intelligence);
const DndSkill sleightOfHand = DndSkill(name: "Fingerfertigkeit", ability: Ability.dexterity);
const DndSkill stealth = DndSkill(name: "Heimlichkeit", ability: Ability.dexterity);
const DndSkill survival = DndSkill(name: "Überleben", ability: Ability.wisdom);

// Die vollständige, globale Liste aller Fähigkeiten
const List<DndSkill> allDndSkills = [
  acrobatics, animalHandling, arcana, athletics, deception, history,
  insight, intimidation, investigation, medicine, nature, perception,
  performance, persuasion, religion, sleightOfHand, stealth, survival,
];

// --- ZAUBER-BIBLIOTHEK ---
// (Platzhalter, um später Zauber hinzuzufügen)


// --- AUSRÜSTUNGS-BIBLIOTHEK ---
// (Platzhalter, um später Ausrüstung hinzuzufügen)

// --- MONSTER-BIBLIOTHEK ---
// (Platzhalter, um später Monster hinzuzufügen)



