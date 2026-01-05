import 'package:flutter/material.dart';
import '../../models/creature.dart';
import '../../models/player_character.dart';
import '../../models/official_monster.dart';
import '../../models/attack.dart';
import '../../game_data/game_data.dart';
import '../../game_data/dnd_models.dart';
import '../character_editor/character_editor_controller.dart' show CharacterType;
import '../../viewmodels/character_editor_viewmodel.dart';

/// Enhanced CharacterEditorController mit ViewModel-Integration
/// Entfernt direkte Datenbankzugriffe und Business-Logik aus UI
class EnhancedCharacterEditorController {
  final CharacterType characterType;
  final String? campaignId;
  final CharacterEditorViewModel viewModel;
  
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
  String selectedSubtype = '';
  String selectedAlignment = 'True Neutral';
  
  // Strukturierte Angriffsverwaltung
  List<Attack> attackList = [];
  
  // Inventar-bezogene Properties für TabManager Kompatibilität
  List<dynamic> get inventory => [];
  bool get isLoadingInventory => false;
  double gold = 0.0;
  
  // Properties für TabManager Kompatibilität
  PlayerCharacter? get pcToEdit => viewModel.playerCharacter;
  Creature? get creatureToEdit => viewModel.creature;

  EnhancedCharacterEditorController({
    required this.characterType,
    this.campaignId,
    required this.viewModel,
  });

  /// Initialisiert alle Controller mit Daten aus dem ViewModel
  void initializeControllers() {
    // Controller initialisieren
    _initializeTextControllers();
    
    // Daten aus ViewModel laden
    _loadDataFromViewModel();
    
    // Listener für bidirektionale Synchronisation
    _setupViewModelListeners();
  }

  void _initializeTextControllers() {
    // Alle Controller initialisieren, um LateInitializationError zu vermeiden
    nameController = TextEditingController();
    descriptionController = TextEditingController();
    playerNameController = TextEditingController();
    hpController = TextEditingController();
    acController = TextEditingController();
    speedController = TextEditingController();
    initBonusController = TextEditingController();
    levelController = TextEditingController();
    crController = TextEditingController(text: '0.25');
    strController = TextEditingController();
    dexController = TextEditingController();
    conController = TextEditingController();
    intController = TextEditingController();
    wisController = TextEditingController();
    chaController = TextEditingController();
    attacksController = TextEditingController();
    specialAbilitiesController = TextEditingController();
    legendaryActionsController = TextEditingController();
    
    proficientSkills = {};
    attackList = [];
  }

  void _loadDataFromViewModel() {
    if (viewModel.isPlayerCharacter && viewModel.playerCharacter != null) {
      _loadPlayerCharacterData(viewModel.playerCharacter!);
    } else if (!viewModel.isPlayerCharacter && viewModel.creature != null) {
      _loadCreatureData(viewModel.creature!);
    } else {
      _loadDefaultData();
    }
  }

  void _loadPlayerCharacterData(PlayerCharacter pc) {
    nameController.text = pc.name;
    playerNameController.text = pc.playerName;
    levelController.text = pc.level.toString();
    hpController.text = pc.maxHp.toString();
    acController.text = pc.armorClass.toString();
    speedController.text = '30ft'; // Default值
    initBonusController.text = pc.initiativeBonus.toString();
    strController.text = pc.strength.toString();
    dexController.text = pc.dexterity.toString();
    conController.text = pc.constitution.toString();
    intController.text = pc.intelligence.toString();
    wisController.text = pc.wisdom.toString();
    chaController.text = pc.charisma.toString();
    descriptionController.text = pc.description ?? '';
    proficientSkills = pc.proficientSkills.toSet();
    imagePath = pc.imagePath;
    attackList = pc.attackList;
    
    // Klasse und Rasse finden
    try {
      selectedClass = allDndClasses.firstWhere((c) => c.name == pc.className);
    } catch (e) {
      selectedClass = allDndClasses.first;
    }
    
    try {
      selectedRace = allDndRaces.firstWhere((r) => r.name == pc.raceName);
    } catch (e) {
      selectedRace = allDndRaces.first;
    }
    
    // D&D Klassifikation
    selectedSize = pc.size ?? 'Medium';
    selectedType = pc.type ?? 'Humanoid';
    selectedSubtype = pc.subtype ?? '';
    selectedAlignment = pc.alignment ?? 'True Neutral';
  }

  void _loadCreatureData(Creature creature) {
    nameController.text = creature.name;
    descriptionController.text = creature.description ?? '';
    hpController.text = creature.maxHp.toString();
    acController.text = creature.armorClass.toString();
    speedController.text = creature.speed;
    initBonusController.text = creature.initiativeBonus.toString();
    crController.text = creature.challengeRating.toString();
    strController.text = creature.strength.toString();
    dexController.text = creature.dexterity.toString();
    conController.text = creature.constitution.toString();
    intController.text = creature.intelligence.toString();
    wisController.text = creature.wisdom.toString();
    chaController.text = creature.charisma.toString();
    attacksController.text = creature.attacks ?? '';
    specialAbilitiesController.text = creature.specialAbilities ?? '';
    legendaryActionsController.text = creature.legendaryActions ?? '';
    selectedSize = creature.size ?? 'Medium';
    selectedType = creature.type ?? 'Humanoid';
    selectedSubtype = creature.subtype ?? '';
    selectedAlignment = creature.alignment ?? 'True Neutral';
    attackList = creature.attackList;
  }

  void _loadDefaultData() {
    // Standardwerte für neue Charaktere
    nameController.text = '';
    descriptionController.text = '';
    playerNameController.text = '';
    hpController.text = '10';
    acController.text = '10';
    speedController.text = '30ft';
    initBonusController.text = '0';
    levelController.text = '1';
    crController.text = '0.25';
    strController.text = '10';
    dexController.text = '10';
    conController.text = '10';
    intController.text = '10';
    wisController.text = '10';
    chaController.text = '10';
    attacksController.text = '';
    specialAbilitiesController.text = '';
    legendaryActionsController.text = '';
    
    selectedClass = allDndClasses.first;
    selectedRace = allDndRaces.first;
    proficientSkills = {};
    attackList = [];
  }

  void _setupViewModelListeners() {
    // ViewModel Changes zu Controller synchronisieren
    viewModel.addListener(_syncWithViewModel);
  }

  void _syncWithViewModel() {
    // Wenn sich ViewModel-Daten ändern, Controller aktualisieren
    if (viewModel.isPlayerCharacter && viewModel.playerCharacter != null) {
      _syncPlayerCharacterControllers();
    } else if (!viewModel.isPlayerCharacter && viewModel.creature != null) {
      _syncCreatureControllers();
    }
  }

  void _syncPlayerCharacterControllers() {
    final pc = viewModel.playerCharacter!;
    if (nameController.text != pc.name) nameController.text = pc.name;
    if (playerNameController.text != pc.playerName) playerNameController.text = pc.playerName;
    if (hpController.text != pc.maxHp.toString()) hpController.text = pc.maxHp.toString();
    if (acController.text != pc.armorClass.toString()) acController.text = pc.armorClass.toString();
    if (initBonusController.text != pc.initiativeBonus.toString()) {
      initBonusController.text = pc.initiativeBonus.toString();
    }
  }

  void _syncCreatureControllers() {
    final creature = viewModel.creature!;
    if (nameController.text != creature.name) nameController.text = creature.name;
    if (hpController.text != creature.maxHp.toString()) hpController.text = creature.maxHp.toString();
    if (acController.text != creature.armorClass.toString()) acController.text = creature.armorClass.toString();
    if (initBonusController.text != creature.initiativeBonus.toString()) {
      initBonusController.text = creature.initiativeBonus.toString();
    }
  }

  /// Speichert die aktuellen Formulardaten über das ViewModel
  Future<void> saveForm() async {
    try {
      // Formulardaten sammeln
      final characterData = _collectFormData();
      
      // Über ViewModel speichern
      if (characterType == CharacterType.player) {
        await viewModel.savePlayerCharacter(characterData, campaignId!);
      } else {
        await viewModel.saveCreature(characterData);
      }
    } catch (e) {
      throw Exception('Fehler beim Speichern: $e');
    }
  }

  Map<String, dynamic> _collectFormData() {
    final baseData = {
      'name': nameController.text.isNotEmpty ? nameController.text : 'Unbenannt',
      'description': descriptionController.text.isNotEmpty ? descriptionController.text : null,
      'maxHp': int.tryParse(hpController.text) ?? 10,
      'armorClass': int.tryParse(acController.text) ?? 10,
      'speed': speedController.text.isNotEmpty ? speedController.text : '30ft',
      'initiativeBonus': int.tryParse(initBonusController.text) ?? 0,
      'strength': int.tryParse(strController.text) ?? 10,
      'dexterity': int.tryParse(dexController.text) ?? 10,
      'constitution': int.tryParse(conController.text) ?? 10,
      'intelligence': int.tryParse(intController.text) ?? 10,
      'wisdom': int.tryParse(wisController.text) ?? 10,
      'charisma': int.tryParse(chaController.text) ?? 10,
      'attackList': attackList,
      // FEHLENDE FELDER HINZUFÜGEN:
      'attacks': characterType == CharacterType.player 
          ? '' // PCs haben keine Legacy-Attack-Strings
          : attacksController.text, // Nur für NPCs/Monster
      'specialAbilities': characterType == CharacterType.player
          ? null // PCs haben keine Special Abilities
          : specialAbilitiesController.text, // Nur für NPCs/Monster
    };

    if (characterType == CharacterType.player) {
      return {
        ...baseData,
        'playerName': playerNameController.text.isNotEmpty ? playerNameController.text : 'Unbekannt',
        'level': int.tryParse(levelController.text) ?? 1,
        'className': selectedClass?.name,
        'raceName': selectedRace?.name,
        'proficientSkills': proficientSkills.toList(),
        'imagePath': imagePath?.isNotEmpty == true ? imagePath : null,
        'size': selectedSize,
        'type': selectedType,
        'subtype': selectedSubtype.isNotEmpty ? selectedSubtype : null,
        'alignment': selectedAlignment,
        // Explizit für PCs setzen:
        'specialAbilities': null,
        'attacks': '',
      };
    } else {
      return {
        ...baseData,
        'challengeRating': double.tryParse(crController.text) ?? 0.25,
        'attacks': attacksController.text,
        'specialAbilities': specialAbilitiesController.text.isNotEmpty 
            ? specialAbilitiesController.text 
            : null,
        'legendaryActions': legendaryActionsController.text.isNotEmpty 
            ? legendaryActionsController.text 
            : null,
        'size': selectedSize,
        'type': selectedType,
        'subtype': selectedSubtype.isNotEmpty ? selectedSubtype : null,
        'alignment': selectedAlignment,
      };
    }
  }

  /// Importiert Daten von einem Official Monster
  void importFromOfficialMonster(OfficialMonster monster) {
    nameController.text = monster.name;
    hpController.text = monster.hitPoints.toString();
    acController.text = monster.armorClass ?? '10';
    speedController.text = monster.speed ?? '30ft';
    strController.text = monster.strength.toString();
    dexController.text = monster.dexterity.toString();
    conController.text = monster.constitution.toString();
    intController.text = monster.intelligence.toString();
    wisController.text = monster.wisdom.toString();
    chaController.text = monster.charisma.toString();
    crController.text = monster.challengeRating.toString();
    selectedSize = monster.size;
    selectedType = monster.type;
    selectedSubtype = monster.subtype ?? '';
    selectedAlignment = monster.alignment ?? 'True Neutral';
    
    // Actions und Special Abilities formatieren
    attacksController.text = monster.actions.map((a) => '${a.name}: ${a.description}').join('\n');
    specialAbilitiesController.text = monster.specialAbilities.isNotEmpty 
        ? monster.specialAbilities.map((a) => '${a.name}: ${a.description}').join('\n\n')
        : '';
    legendaryActionsController.text = (monster.legendaryActions?.isNotEmpty == true)
        ? monster.legendaryActions!.map((a) => '${a.name}: ${a.description}').join('\n\n')
        : '';
    
    initBonusController.text = '0';
  }

  /// Toggle für Skill-Proficiency
  void toggleSkill(String skillName) {
    if (proficientSkills.contains(skillName)) {
      proficientSkills.remove(skillName);
    } else {
      proficientSkills.add(skillName);
    }
  }

  /// Berechnet die maximalen HP basierend auf Klasse, Level und Constitution
  int calculateMaxHp() {
    final level = int.tryParse(levelController.text) ?? 1;
    final con = int.tryParse(conController.text) ?? 10;
    final conModifier = getModifier(con);
    final hitDie = selectedClass?.hitDie ?? 8;
    
    // HP = HitDie + ConModifier (Level 1)
    // Für höhere Level: HP = HitDie + (Level-1) * ((HitDie+1)/2 + ConModifier)
    if (level == 1) {
      return hitDie + conModifier;
    } else {
      final averageRoll = (hitDie + 1) ~/ 2;
      return hitDie + (level - 1) * (averageRoll + conModifier);
    }
  }

  /// Aktualisiert den HP-Controller mit berechneten Werten
  void updateCalculatedHp() {
    final calculatedHp = calculateMaxHp();
    if (hpController.text.isEmpty || int.tryParse(hpController.text) == 10) {
      hpController.text = calculatedHp.toString();
    }
  }

  /// Aktualisiert die Angriffsliste
  void updateAttacks(List<Attack> attacks) {
    attackList = attacks;
    
    // Synchronisiere mit Legacy-String für Abwärtskompatibilität
    if (characterType != CharacterType.player) {
      attacksController.text = attacks.map((attack) => 
          '${attack.name}: ${attack.description} (Schaden: ${attack.totalDamage})'
      ).join('\n');
    }
  }

  /// Validierung für erforderliche Felder
  String? validateRequired(String? value) {
    return value?.isEmpty == true ? 'Pflichtfeld' : null;
  }

  /// Validierung für Zahlenfelder
  String? validateNumber(String? value) {
    if (value?.isEmpty == true) return 'Pflichtfeld';
    if (int.tryParse(value!) == null) return 'Bitte eine gültige Zahl eingeben';
    return null;
  }

  /// Validierung für Dezimalzahlen (CR)
  String? validateDecimal(String? value) {
    if (value?.isEmpty == true) return 'Pflichtfeld';
    if (double.tryParse(value!) == null) return 'Bitte eine gültige Zahl eingeben';
    return null;
  }

  /// D&D Stat modifier helper
  int getModifier(int score) {
    return (score - 10) ~/ 2;
  }

  /// Berechnet den Initiative-Bonus basierend auf DEX
  int calculateInitiativeBonus() {
    final dex = int.tryParse(dexController.text) ?? 10;
    return getModifier(dex);
  }

  /// Prüft, ob das Formular gültig ist
  bool isFormValid() {
    // Basis-Validierung
    if (nameController.text.trim().isEmpty) return false;
    if (validateNumber(hpController.text) != null) return false;
    if (validateNumber(acController.text) != null) return false;
    
    // Attribut-Validierung
    if (validateNumber(strController.text) != null) return false;
    if (validateNumber(dexController.text) != null) return false;
    if (validateNumber(conController.text) != null) return false;
    if (validateNumber(intController.text) != null) return false;
    if (validateNumber(wisController.text) != null) return false;
    if (validateNumber(chaController.text) != null) return false;
    
    // Charakter-spezifische Validierung
    if (characterType == CharacterType.player) {
      if (selectedClass == null || selectedRace == null) return false;
      if (validateNumber(levelController.text) != null) return false;
      if (playerNameController.text.trim().isEmpty) return false;
    } else {
      if (validateDecimal(crController.text) != null) return false;
    }
    
    return true;
  }

  /// Setzt das Character-Image
  void setImagePath(String? path) {
    imagePath = path;
  }

  /// Load Inventar für Kompatibilität mit TabManager
  Future<void> loadInventory() async {
    // Placeholder - Implementierung erfolgt über ViewModel
    // Diese Methode existiert nur für API-Kompatibilität
  }

  /// Dispose aller Controller
  void dispose() {
    viewModel.removeListener(_syncWithViewModel);
    
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
}
