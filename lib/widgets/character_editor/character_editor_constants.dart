import 'package:flutter/material.dart';

class CharacterEditorConstants {
  // Größen-Optionen
  static const List<DropdownMenuItem<String>> sizeOptions = [
    DropdownMenuItem(value: 'Tiny', child: Text('Winzig')),
    DropdownMenuItem(value: 'Small', child: Text('Klein')),
    DropdownMenuItem(value: 'Medium', child: Text('Mittel')),
    DropdownMenuItem(value: 'Large', child: Text('Groß')),
    DropdownMenuItem(value: 'Huge', child: Text('Riesig')),
    DropdownMenuItem(value: 'Gargantuan', child: Text('Gigantisch')),
  ];

  // Typ-Optionen für Player Characters
  static const List<DropdownMenuItem<String>> typeOptionsForPC = [
    DropdownMenuItem(value: 'Humanoid', child: Text('Humanoid')),
    DropdownMenuItem(value: 'Beast', child: Text('Tier')),
    DropdownMenuItem(value: 'Dragon', child: Text('Drache')),
    DropdownMenuItem(value: 'Elemental', child: Text('Elementar')),
    DropdownMenuItem(value: 'Fey', child: Text('Feenwesen')),
    DropdownMenuItem(value: 'Fiend', child: Text('Teufel/Dämon')),
    DropdownMenuItem(value: 'Celestial', child: Text('Himmelswesen')),
    DropdownMenuItem(value: 'Construct', child: Text('Konstrukt')),
    DropdownMenuItem(value: 'Undead', child: Text('Untot')),
  ];

  // Typ-Optionen für Creatures/Monster
  static const List<DropdownMenuItem<String>> typeOptions = [
    DropdownMenuItem(value: 'Aberration', child: Text('Aberration')),
    DropdownMenuItem(value: 'Beast', child: Text('Tier')),
    DropdownMenuItem(value: 'Celestial', child: Text('Himmelswesen')),
    DropdownMenuItem(value: 'Construct', child: Text('Konstrukt')),
    DropdownMenuItem(value: 'Dragon', child: Text('Drache')),
    DropdownMenuItem(value: 'Elemental', child: Text('Elementar')),
    DropdownMenuItem(value: 'Fey', child: Text('Feenwesen')),
    DropdownMenuItem(value: 'Fiend', child: Text('Teufel/Dämon')),
    DropdownMenuItem(value: 'Giant', child: Text('Riese')),
    DropdownMenuItem(value: 'Humanoid', child: Text('Humanoid')),
    DropdownMenuItem(value: 'humanoid (goblinoid)', child: Text('Humanoid (Goblinoid)')),
    DropdownMenuItem(value: 'humanoid (orc)', child: Text('Humanoid (Ork)')),
    DropdownMenuItem(value: 'Monstrosity', child: Text('Monstrosität')),
    DropdownMenuItem(value: 'Ooze', child: Text('Schleim')),
    DropdownMenuItem(value: 'Plant', child: Text('Pflanze')),
    DropdownMenuItem(value: 'undead', child: Text('Untot')),
  ];

  // Gesinnungs-Optionen
  static const List<DropdownMenuItem<String>> alignmentOptions = [
    DropdownMenuItem(value: 'Lawful Good', child: Text('Gesetzmäßig Gut')),
    DropdownMenuItem(value: 'Neutral Good', child: Text('Neutral Gut')),
    DropdownMenuItem(value: 'Chaotic Good', child: Text('Chaotisch Gut')),
    DropdownMenuItem(value: 'Lawful Neutral', child: Text('Gesetzmäßig Neutral')),
    DropdownMenuItem(value: 'True Neutral', child: Text('Wahrhaft Neutral')),
    DropdownMenuItem(value: 'Chaotic Neutral', child: Text('Chaotisch Neutral')),
    DropdownMenuItem(value: 'Lawful Evil', child: Text('Gesetzmäßig Böse')),
    DropdownMenuItem(value: 'neutral evil', child: Text('Neutral Böse')),
    DropdownMenuItem(value: 'Chaotic Evil', child: Text('Chaotisch Böse')),
    DropdownMenuItem(value: 'Unaligned', child: Text('Nicht ausgerichtet')),
  ];

  // Standard-Werte
  static const String defaultSize = 'Medium';
  static const String defaultType = 'Humanoid';
  static const String defaultAlignment = 'True Neutral';
  static const double defaultCR = 0.25;
  static const int defaultLevel = 1;
  static const int defaultHP = 10;
  static const int defaultAC = 10;
  static const int defaultSpeed = 30;
  static const String defaultSpeedUnit = 'ft';
  static const int defaultInitiativeBonus = 0;
  static const int defaultAttribute = 10;
  static const double defaultGold = 0.0;

  // Text-Konstanten
  static const String pcNewTitle = 'Neuen Helden erstellen';
  static const String pcEditTitle = 'Helden bearbeiten';
  static const String npcNewTitle = 'Neuen NSC erstellen';
  static const String npcEditTitle = 'NSC bearbeiten';
  static const String monsterNewTitle = 'Neues Monster erstellen';
  static const String monsterEditTitle = 'Monster bearbeiten';

  static const String basisTabLabel = 'Basis';
  static const String attributesTabLabel = 'Attribute';
  static const String attacksTabLabel = 'Angriffe';
  static const String inventoryTabLabel = 'Inventar';

  // Validierungs-Nachrichten
  static const String requiredFieldError = 'Pflichtfeld';
  static const String numberFieldError = 'Bitte eine gültige Zahl eingeben';
  static const String classRaceRequiredError = 'Klasse und Rasse müssen ausgewählt werden';
  static const String campaignIdRequiredError = 'Campaign ID ist erforderlich für Player Characters';

  // Helper-Methoden für Standard-Werte
  static String getScreenTitle(bool isEdit, String characterType) {
    switch (characterType) {
      case 'player':
        return isEdit ? pcEditTitle : pcNewTitle;
      case 'npc':
        return isEdit ? npcEditTitle : npcNewTitle;
      case 'monster':
        return isEdit ? monsterEditTitle : monsterNewTitle;
      default:
        return 'Charakter bearbeiten';
    }
  }

  static List<DropdownMenuItem<String>> getTypeOptionsForCharacterType(String characterType) {
    switch (characterType.toLowerCase()) {
      case 'player':
        return typeOptionsForPC;
      case 'npc':
      case 'monster':
      default:
        return typeOptions;
    }
  }
}
