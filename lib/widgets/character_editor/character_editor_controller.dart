import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../database/database_helper.dart';
import '../../../models/creature.dart';
import '../../../models/player_character.dart';
import '../../../models/inventory_item.dart';
import '../../../models/official_monster.dart';
import '../../../game_data/game_data.dart';
import '../../../game_data/dnd_models.dart';
import '../../../game_data/dnd_logic.dart';
import '../../../models/attack.dart';

enum CharacterType { player, npc, monster }

class CharacterEditorController {
  final CharacterType characterType;
  final String? campaignId;
  final Creature? creatureToEdit;
  final PlayerCharacter? pcToEdit;
  
  final dbHelper = DatabaseHelper.instance;
  
  // Basis-Info Controllers
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController playerNameController; // Nur für PCs
  
  // Kampf-Stats Controllers
  late TextEditingController hpController;
  late TextEditingController acController;
  late TextEditingController speedController;
  late TextEditingController initBonusController;
  late TextEditingController levelController; // Nur für PCs
  late TextEditingController crController; // Nur für NPCs/Monster
  
  // Attribute Controllers
  late TextEditingController strController;
  late TextEditingController dexController;
  late TextEditingController conController;
  late TextEditingController intController;
  late TextEditingController wisController;
  late TextEditingController chaController;
  
  // Fähigkeiten Controllers
  late TextEditingController attacksController; // Nur für NPCs/Monster
  late TextEditingController specialAbilitiesController; // Nur für NPCs/Monster
  late TextEditingController legendaryActionsController; // Nur für NPCs/Monster
  
  // PC-spezifische Felder
  DndClass? selectedClass;
  DndRace? selectedRace;
  late Set<String> proficientSkills;
  String? imagePath;
  
  // NPC/Monster-spezifische Felder
  String selectedSize = 'Medium';
  String selectedType = 'Humanoid';
  String? selectedSubtype;
  String selectedAlignment = 'True Neutral';
  double gold = 0.0;
  List<DisplayInventoryItem> inventory = [];
  bool isLoadingInventory = false;
  
  // Strukturierte Angriffsverwaltung
  List<Attack> attackList = [];

  CharacterEditorController({
    required this.characterType,
    this.campaignId,
    this.creatureToEdit,
    this.pcToEdit,
  });

  void initializeControllers() {
    // Alle Controller initialisieren, um LateInitializationError zu vermeiden
    crController = TextEditingController(text: '0.25');
    attacksController = TextEditingController(text: '');
    specialAbilitiesController = TextEditingController(text: '');
    legendaryActionsController = TextEditingController(text: '');
    levelController = TextEditingController(text: '1');
    playerNameController = TextEditingController(text: '');
    descriptionController = TextEditingController(text: '');
    
    // proficientSkills für alle Charaktertypen initialisieren
    proficientSkills = {};
    attackList = [];
    
    // Basis-Daten initialisieren
    if (characterType == CharacterType.player) {
      _initializePlayerData();
    } else {
      _initializeCreatureData();
    }
  }

  void _initializePlayerData() {
    final pc = pcToEdit;
    nameController = TextEditingController(text: pc?.name ?? '');
    playerNameController = TextEditingController(text: pc?.playerName ?? '');
    levelController = TextEditingController(text: pc?.level.toString() ?? '1');
    hpController = TextEditingController(text: pc?.maxHp.toString() ?? '10');
    acController = TextEditingController(text: pc?.armorClass.toString() ?? '10');
    speedController = TextEditingController(text: '30ft');
    initBonusController = TextEditingController(text: pc?.initiativeBonus.toString() ?? '0');
    strController = TextEditingController(text: pc?.strength.toString() ?? '10');
    dexController = TextEditingController(text: pc?.dexterity.toString() ?? '10');
    conController = TextEditingController(text: pc?.constitution.toString() ?? '10');
    intController = TextEditingController(text: pc?.intelligence.toString() ?? '10');
    wisController = TextEditingController(text: pc?.wisdom.toString() ?? '10');
    chaController = TextEditingController(text: pc?.charisma.toString() ?? '10');
    proficientSkills = pc?.proficientSkills.toSet() ?? {};
    imagePath = pc?.imagePath;
    attackList = pc?.attackList ?? [];
    
    if (pc != null) {
      selectedClass = allDndClasses.firstWhere((c) => c.name == pc.className, orElse: () => allDndClasses.first);
      selectedRace = allDndRaces.firstWhere((r) => r.name == pc.raceName, orElse: () => allDndRaces.first);
    }
  }

  void _initializeCreatureData() {
    final creature = creatureToEdit;
    nameController = TextEditingController(text: creature?.name ?? '');
    descriptionController = TextEditingController(text: creature?.description ?? '');
    hpController = TextEditingController(text: creature?.maxHp.toString() ?? '10');
    acController = TextEditingController(text: creature?.armorClass.toString() ?? '10');
    speedController = TextEditingController(text: creature?.speed ?? '30ft');
    initBonusController = TextEditingController(text: creature?.initiativeBonus.toString() ?? '0');
    crController = TextEditingController(text: creature?.challengeRating?.toString() ?? '0.25');
    strController = TextEditingController(text: creature?.strength.toString() ?? '10');
    dexController = TextEditingController(text: creature?.dexterity.toString() ?? '10');
    conController = TextEditingController(text: creature?.constitution.toString() ?? '10');
    intController = TextEditingController(text: creature?.intelligence.toString() ?? '10');
    wisController = TextEditingController(text: creature?.wisdom.toString() ?? '10');
    chaController = TextEditingController(text: creature?.charisma.toString() ?? '10');
    attacksController = TextEditingController(text: creature?.attacks ?? '');
    specialAbilitiesController = TextEditingController(text: creature?.specialAbilities ?? '');
    legendaryActionsController = TextEditingController(text: creature?.legendaryActions ?? '');
    selectedSize = creature?.size ?? 'Medium';
    selectedType = creature?.type ?? 'Humanoid';
    selectedSubtype = creature?.subtype;
    selectedAlignment = creature?.alignment ?? 'True Neutral';
    gold = creature?.gold ?? 0.0;
    attackList = creature?.attackList ?? [];
  }

  Future<void> loadInventory() async {
    // Für neue Charaktere (ohne ID) kein Inventar laden
    if (characterType == CharacterType.player) {
      if (pcToEdit == null) {
        inventory = [];
        return;
      }
    } else {
      if (creatureToEdit == null) {
        inventory = [];
        return;
      }
    }
    
    isLoadingInventory = true;
    try {
      final ownerId = characterType == CharacterType.player 
          ? pcToEdit!.id 
          : creatureToEdit!.id;
      final inventoryItems = await dbHelper.getDisplayInventoryForOwner(ownerId);
      inventory = inventoryItems;
    } catch (e) {
      throw Exception('Fehler beim Laden des Inventars: $e');
    } finally {
      isLoadingInventory = false;
    }
  }

  Future<void> saveForm() async {
    if (characterType == CharacterType.player) {
      await savePlayerCharacter();
    } else {
      await saveCreature();
    }
  }

  Future<void> savePlayerCharacter() async {
    if (selectedClass == null || selectedRace == null) {
      throw Exception('Klasse und Rasse müssen ausgewählt werden');
    }
    
    if (campaignId == null) {
      throw Exception('Campaign ID ist erforderlich für Player Characters');
    }
    
    final dexScore = int.tryParse(dexController.text) ?? 10;
    final pc = PlayerCharacter(
      id: pcToEdit?.id,
      campaignId: campaignId!,
      name: nameController.text,
      playerName: playerNameController.text,
      className: selectedClass!.name,
      raceName: selectedRace!.name,
      level: int.tryParse(levelController.text) ?? 1,
      maxHp: int.tryParse(hpController.text) ?? 10,
      armorClass: int.tryParse(acController.text) ?? 10,
      initiativeBonus: getModifier(dexScore),
      imagePath: imagePath,
      strength: int.tryParse(strController.text) ?? 10,
      dexterity: dexScore,
      constitution: int.tryParse(conController.text) ?? 10,
      intelligence: int.tryParse(intController.text) ?? 10,
      wisdom: int.tryParse(wisController.text) ?? 10,
      charisma: int.tryParse(chaController.text) ?? 10,
      proficientSkills: proficientSkills.toList(),
      // D&D-Klassifikation für Player Characters
      size: selectedSize.isNotEmpty ? selectedSize : null,
      type: selectedType.isNotEmpty ? selectedType : null,
      subtype: selectedSubtype?.isNotEmpty == true ? selectedSubtype : null,
      alignment: selectedAlignment.isNotEmpty ? selectedAlignment : null,
      // Beschreibung und Fähigkeiten
      description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
      specialAbilities: specialAbilitiesController.text.isNotEmpty ? specialAbilitiesController.text : null,
      attacks: attacksController.text.isNotEmpty ? attacksController.text : null,
      // Strukturierte Angriffe
      attackList: attackList,
      // Währung
      gold: gold,
      silver: 0.0, // Könnte später erweitert werden
      copper: 0.0, // Könnte später erweitert werden
      // Erweiterte Felder
      sourceType: 'custom',
      sourceId: null,
      isFavorite: false,
      version: '1.0',
    );

    if (pcToEdit != null) {
      await dbHelper.updatePlayerCharacter(pc);
    } else {
      await dbHelper.insertPlayerCharacter(pc);
    }
  }

  Future<void> saveCreature() async {
    final strength = int.tryParse(strController.text) ?? 10;
    final dexterity = int.tryParse(dexController.text) ?? 10;
    final initiativeBonus = int.tryParse(initBonusController.text) ?? 0;
    
    final creature = Creature(
      id: creatureToEdit?.id,
      name: nameController.text,
      maxHp: int.tryParse(hpController.text) ?? 10,
      currentHp: int.tryParse(hpController.text) ?? 10,
      armorClass: int.tryParse(acController.text) ?? 10,
      speed: speedController.text,
      attacks: attacksController.text,
      initiativeBonus: initiativeBonus,
      strength: strength,
      dexterity: dexterity,
      constitution: int.tryParse(conController.text) ?? 10,
      intelligence: int.tryParse(intController.text) ?? 10,
      wisdom: int.tryParse(wisController.text) ?? 10,
      charisma: int.tryParse(chaController.text) ?? 10,
      gold: gold,
      silver: 0.0,
      copper: 0.0,
      size: selectedSize,
      type: selectedType,
      subtype: selectedSubtype?.isNotEmpty == true ? selectedSubtype! : null,
      alignment: selectedAlignment,
      challengeRating: (double.tryParse(crController.text) ?? 0.25).round(),
      specialAbilities: specialAbilitiesController.text.isNotEmpty ? specialAbilitiesController.text : null,
      legendaryActions: legendaryActionsController.text.isNotEmpty ? legendaryActionsController.text : null,
      description: descriptionController.text.isNotEmpty ? descriptionController.text : null,
      isCustom: true,
      sourceType: 'custom',
      // Strukturierte Angriffe
      attackList: attackList,
    );

    if (creatureToEdit != null) {
      await dbHelper.updateCreature(creature);
    } else {
      await dbHelper.insertCreature(creature);
    }
  }

  void importFromOfficialMonster(OfficialMonster monster) {
    nameController.text = monster.name;
    hpController.text = monster.hitPoints.toString();
    acController.text = monster.armorClass;
    speedController.text = monster.speed;
    strController.text = monster.strength.toString();
    dexController.text = monster.dexterity.toString();
    conController.text = monster.constitution.toString();
    intController.text = monster.intelligence.toString();
    wisController.text = monster.wisdom.toString();
    chaController.text = monster.charisma.toString();
    crController.text = monster.challengeRating.toString();
    selectedSize = monster.size;
    selectedType = monster.type;
    selectedSubtype = monster.subtype;
    selectedAlignment = monster.alignment;
    attacksController.text = monster.actions.map((a) => '${a.name}: ${a.description}').join('\n');
    specialAbilitiesController.text = monster.specialAbilities.isNotEmpty 
        ? monster.specialAbilities.map((a) => '${a.name}: ${a.description}').join('\n\n')
        : '';
    legendaryActionsController.text = (monster.legendaryActions?.isNotEmpty == true)
        ? monster.legendaryActions!.map((a) => '${a.name}: ${a.description}').join('\n\n')
        : '';
    initBonusController.text = '0';
  }

  void toggleSkill(String skillName) {
    if (proficientSkills.contains(skillName)) {
      proficientSkills.remove(skillName);
    } else {
      proficientSkills.add(skillName);
    }
  }

  void updateAttacks(List<Attack> attacks) {
    attackList = attacks;
    // Synchronisiere mit Legacy-String für Abwärtskompatibilität
    attacksController.text = attacks.map((attack) => 
        '${attack.name}: ${attack.description} (Schaden: ${attack.totalDamage})'
    ).join('\n');
  }

  void dispose() {
    // Alle Controller disposen
    nameController.dispose();
    descriptionController.dispose();
    playerNameController.dispose();
    hpController.dispose();
    acController.dispose();
    speedController.dispose();
    initBonusController.dispose();
    levelController.dispose();
    crController.dispose();
    strController.dispose();
    dexController.dispose();
    conController.dispose();
    intController.dispose();
    wisController.dispose();
    chaController.dispose();
    attacksController.dispose();
    specialAbilitiesController.dispose();
    legendaryActionsController.dispose();
  }

  // Validation helper
  String? validateRequired(String? value) {
    return value?.isEmpty == true ? 'Pflichtfeld' : null;
  }

  String? validateNumber(String? value) {
    if (value?.isEmpty == true) return 'Pflichtfeld';
    if (int.tryParse(value!) == null) return 'Bitte eine gültige Zahl eingeben';
    return null;
  }
}
