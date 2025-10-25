import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/creature.dart';
import '../models/player_character.dart';
import '../models/item.dart';
import '../models/inventory_item.dart';
import '../models/official_monster.dart';
import '../game_data/game_data.dart';
import '../game_data/dnd_models.dart';
import '../game_data/dnd_logic.dart';
import 'official_monsters_screen.dart';
import 'item_library_screen.dart';
import 'add_item_from_library_screen.dart';
import '../widgets/character_editor/attributes_tab_widget.dart';
import '../widgets/character_editor/abilities_tab_widget.dart';
import '../widgets/character_editor/inventory_tab_widget.dart';
import '../widgets/character_editor/character_editor_helpers.dart';

enum CharacterType { player, npc, monster }

class UnifiedCharacterEditorScreen extends StatefulWidget {
  final CharacterType characterType;
  final String? campaignId; // Nur für Player Characters benötigt
  final Creature? creatureToEdit;
  final PlayerCharacter? pcToEdit;
  
  const UnifiedCharacterEditorScreen({
    super.key,
    required this.characterType,
    this.campaignId,
    this.creatureToEdit,
    this.pcToEdit,
  });

  @override
  State<UnifiedCharacterEditorScreen> createState() => _UnifiedCharacterEditorScreenState();
}

class _UnifiedCharacterEditorScreenState extends State<UnifiedCharacterEditorScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  late TabController _tabController;
  
  // Basis-Info Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _playerNameController; // Nur für PCs
  
  // Kampf-Stats Controllers
  late TextEditingController _hpController;
  late TextEditingController _acController;
  late TextEditingController _speedController;
  late TextEditingController _initBonusController;
  late TextEditingController _levelController; // Nur für PCs
  late TextEditingController _crController; // Nur für NPCs/Monster
  
  // Attribute Controllers
  late TextEditingController _strController;
  late TextEditingController _dexController;
  late TextEditingController _conController;
  late TextEditingController _intController;
  late TextEditingController _wisController;
  late TextEditingController _chaController;
  
  // Fähigkeiten Controllers
  late TextEditingController _attacksController; // Nur für NPCs/Monster
  late TextEditingController _specialAbilitiesController; // Nur für NPCs/Monster
  late TextEditingController _legendaryActionsController; // Nur für NPCs/Monster
  
  // PC-spezifische Felder
  DndClass? _selectedClass;
  DndRace? _selectedRace;
  late Set<String> _proficientSkills;
  String? _imagePath;
  
  // NPC/Monster-spezifische Felder
  String _selectedSize = 'Medium';
  String _selectedType = 'Humanoid';
  String? _selectedSubtype;
  String _selectedAlignment = 'True Neutral';
  double _gold = 0.0;
  List<DisplayInventoryItem> _inventory = [];
  bool _isLoadingInventory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _getTabCount(), vsync: this);
    _initializeControllers();
    _loadInventory();
  }

  int _getTabCount() {
    switch (widget.characterType) {
      case CharacterType.player:
        return 3; // Basis, Attribute, Inventar
      case CharacterType.npc:
      case CharacterType.monster:
        return 4; // Basis, Attribute, Fähigkeiten, Inventar
    }
  }

  void _initializeControllers() {
    // Alle Controller initialisieren, um LateInitializationError zu vermeiden
    _crController = TextEditingController(text: '0.25');
    _attacksController = TextEditingController(text: '');
    _specialAbilitiesController = TextEditingController(text: '');
    _legendaryActionsController = TextEditingController(text: '');
    _levelController = TextEditingController(text: '1');
    _playerNameController = TextEditingController(text: '');
    _descriptionController = TextEditingController(text: '');
    
    // _proficientSkills für alle Charaktertypen initialisieren
    _proficientSkills = {};
    
    // Basis-Daten initialisieren
    if (widget.characterType == CharacterType.player) {
      final pc = widget.pcToEdit;
      _nameController = TextEditingController(text: pc?.name ?? '');
      _playerNameController = TextEditingController(text: pc?.playerName ?? '');
      _levelController = TextEditingController(text: pc?.level.toString() ?? '1');
      _hpController = TextEditingController(text: pc?.maxHp.toString() ?? '10');
      _acController = TextEditingController(text: pc?.armorClass.toString() ?? '10');
      _speedController = TextEditingController(text: '30ft');
      _initBonusController = TextEditingController(text: pc?.initiativeBonus.toString() ?? '0');
      _strController = TextEditingController(text: pc?.strength.toString() ?? '10');
      _dexController = TextEditingController(text: pc?.dexterity.toString() ?? '10');
      _conController = TextEditingController(text: pc?.constitution.toString() ?? '10');
      _intController = TextEditingController(text: pc?.intelligence.toString() ?? '10');
      _wisController = TextEditingController(text: pc?.wisdom.toString() ?? '10');
      _chaController = TextEditingController(text: pc?.charisma.toString() ?? '10');
      _proficientSkills = pc?.proficientSkills.toSet() ?? {};
      _imagePath = pc?.imagePath;
      
      if (pc != null) {
        _selectedClass = allDndClasses.firstWhere((c) => c.name == pc.className, orElse: () => allDndClasses.first);
        _selectedRace = allDndRaces.firstWhere((r) => r.name == pc.raceName, orElse: () => allDndRaces.first);
      }
    } else {
      final creature = widget.creatureToEdit;
      _nameController = TextEditingController(text: creature?.name ?? '');
      _descriptionController = TextEditingController(text: creature?.description ?? '');
      _hpController = TextEditingController(text: creature?.maxHp.toString() ?? '10');
      _acController = TextEditingController(text: creature?.armorClass.toString() ?? '10');
      _speedController = TextEditingController(text: creature?.speed ?? '30ft');
      _initBonusController = TextEditingController(text: creature?.initiativeBonus.toString() ?? '0');
      _crController = TextEditingController(text: creature?.challengeRating?.toString() ?? '0.25');
      _strController = TextEditingController(text: creature?.strength.toString() ?? '10');
      _dexController = TextEditingController(text: creature?.dexterity.toString() ?? '10');
      _conController = TextEditingController(text: creature?.constitution.toString() ?? '10');
      _intController = TextEditingController(text: creature?.intelligence.toString() ?? '10');
      _wisController = TextEditingController(text: creature?.wisdom.toString() ?? '10');
      _chaController = TextEditingController(text: creature?.charisma.toString() ?? '10');
      _attacksController = TextEditingController(text: creature?.attacks ?? '');
      _specialAbilitiesController = TextEditingController(text: creature?.specialAbilities ?? '');
      _legendaryActionsController = TextEditingController(text: creature?.legendaryActions ?? '');
      _selectedSize = creature?.size ?? 'Medium';
      _selectedType = creature?.type ?? 'Humanoid';
      _selectedSubtype = creature?.subtype;
      _selectedAlignment = creature?.alignment ?? 'True Neutral';
      _gold = creature?.gold ?? 0.0;
    }
  }

  Future<void> _loadInventory() async {
    // Für neue Charaktere (ohne ID) kein Inventar laden
    if (widget.characterType == CharacterType.player) {
      if (widget.pcToEdit == null) {
        setState(() => _inventory = []);
        return;
      }
    } else {
      if (widget.creatureToEdit == null) {
        setState(() => _inventory = []);
        return;
      }
    }
    
    setState(() => _isLoadingInventory = true);
    try {
      final ownerId = widget.characterType == CharacterType.player 
          ? widget.pcToEdit!.id 
          : widget.creatureToEdit!.id;
      final inventory = await dbHelper.getDisplayInventoryForOwner(ownerId);
      setState(() {
        _inventory = inventory;
        _isLoadingInventory = false;
      });
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Inventars: $e')),
        );
      }
      setState(() => _isLoadingInventory = false);
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState?.validate() == true) {
      try {
        if (widget.characterType == CharacterType.player) {
          await _savePlayerCharacter();
        } else {
          await _saveCreature();
        }
        
        if (mounted && context.mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Speichern: $e')),
          );
        }
      }
    }
  }

  Future<void> _savePlayerCharacter() async {
    if (_selectedClass == null || _selectedRace == null) {
      throw Exception('Klasse und Rasse müssen ausgewählt werden');
    }
    
    if (widget.campaignId == null) {
      throw Exception('Campaign ID ist erforderlich für Player Characters');
    }
    
    final dexScore = int.tryParse(_dexController.text) ?? 10;
    final pc = PlayerCharacter(
      id: widget.pcToEdit?.id,
      campaignId: widget.campaignId!,
      name: _nameController.text,
      playerName: _playerNameController.text,
      className: _selectedClass!.name,
      raceName: _selectedRace!.name,
      level: int.tryParse(_levelController.text) ?? 1,
      maxHp: int.tryParse(_hpController.text) ?? 10,
      armorClass: int.tryParse(_acController.text) ?? 10,
      initiativeBonus: getModifier(dexScore),
      imagePath: _imagePath,
      strength: int.tryParse(_strController.text) ?? 10,
      dexterity: dexScore,
      constitution: int.tryParse(_conController.text) ?? 10,
      intelligence: int.tryParse(_intController.text) ?? 10,
      wisdom: int.tryParse(_wisController.text) ?? 10,
      charisma: int.tryParse(_chaController.text) ?? 10,
      proficientSkills: _proficientSkills.toList(),
    );

    if (widget.pcToEdit != null) {
      await dbHelper.updatePlayerCharacter(pc);
    } else {
      await dbHelper.insertPlayerCharacter(pc);
    }
  }

  Future<void> _saveCreature() async {
    final strength = int.tryParse(_strController.text) ?? 10;
    final dexterity = int.tryParse(_dexController.text) ?? 10;
    final initiativeBonus = int.tryParse(_initBonusController.text) ?? 0;
    
    final creature = Creature(
      id: widget.creatureToEdit?.id,
      name: _nameController.text,
      maxHp: int.tryParse(_hpController.text) ?? 10,
      currentHp: int.tryParse(_hpController.text) ?? 10,
      armorClass: int.tryParse(_acController.text) ?? 10,
      speed: _speedController.text,
      attacks: _attacksController.text,
      initiativeBonus: initiativeBonus,
      strength: strength,
      dexterity: dexterity,
      constitution: int.tryParse(_conController.text) ?? 10,
      intelligence: int.tryParse(_intController.text) ?? 10,
      wisdom: int.tryParse(_wisController.text) ?? 10,
      charisma: int.tryParse(_chaController.text) ?? 10,
      gold: _gold,
      silver: 0.0,
      copper: 0.0,
      size: _selectedSize,
      type: _selectedType,
      subtype: _selectedSubtype?.isNotEmpty == true ? _selectedSubtype! : null,
      alignment: _selectedAlignment,
      challengeRating: (double.tryParse(_crController.text) ?? 0.25).round(),
      specialAbilities: _specialAbilitiesController.text.isNotEmpty ? _specialAbilitiesController.text : null,
      legendaryActions: _legendaryActionsController.text.isNotEmpty ? _legendaryActionsController.text : null,
      description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
      isCustom: true,
      sourceType: 'custom',
    );

    if (widget.creatureToEdit != null) {
      await dbHelper.updateCreature(creature);
    } else {
      await dbHelper.insertCreature(creature);
    }
  }

  Future<void> _importFromOfficialMonster() async {
    final selectedMonster = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const OfficialMonstersScreen(),
      ),
    );

    if (selectedMonster != null && selectedMonster is OfficialMonster && mounted) {
      setState(() {
        _nameController.text = selectedMonster.name;
        _hpController.text = selectedMonster.hitPoints.toString();
        _acController.text = selectedMonster.armorClass;
        _speedController.text = selectedMonster.speed;
        _strController.text = selectedMonster.strength.toString();
        _dexController.text = selectedMonster.dexterity.toString();
        _conController.text = selectedMonster.constitution.toString();
        _intController.text = selectedMonster.intelligence.toString();
        _wisController.text = selectedMonster.wisdom.toString();
        _chaController.text = selectedMonster.charisma.toString();
        _crController.text = selectedMonster.challengeRating.toString();
        _selectedSize = selectedMonster.size;
        _selectedType = selectedMonster.type;
        _selectedSubtype = selectedMonster.subtype;
        _selectedAlignment = selectedMonster.alignment;
        _attacksController.text = selectedMonster.actions.map((a) => '${a.name}: ${a.description}').join('\n');
        _specialAbilitiesController.text = selectedMonster.specialAbilities.isNotEmpty 
            ? selectedMonster.specialAbilities.map((a) => '${a.name}: ${a.description}').join('\n\n')
            : '';
        _legendaryActionsController.text = (selectedMonster.legendaryActions?.isNotEmpty == true)
            ? selectedMonster.legendaryActions!.map((a) => '${a.name}: ${a.description}').join('\n\n')
            : '';
        _initBonusController.text = '0';
      });
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedMonster.name} wurde importiert')),
        );
      }
    }
  }

  Future<void> _addItemFromLibrary() async {
    String? ownerId;
    
    if (widget.characterType == CharacterType.player) {
      ownerId = widget.pcToEdit?.id;
    } else {
      ownerId = widget.creatureToEdit?.id;
    }
    
    if (ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte speichern Sie zuerst den Charakter')),
      );
      return;
    }

    if (widget.characterType == CharacterType.player) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => AddItemFromLibraryScreen(ownerId: ownerId!),
        ),
      );
    } else {
      final selectedItem = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const ItemLibraryScreen(selectMode: true),
        ),
      );

      if (selectedItem != null && selectedItem is Item) {
        final inventoryItem = InventoryItem(
          ownerId: ownerId!,
          itemId: selectedItem.id,
          quantity: 1,
        );
        await dbHelper.insertInventoryItem(inventoryItem);
      }
    }
    
    _loadInventory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Alle Controller disposen
    _nameController.dispose();
    _descriptionController.dispose();
    _playerNameController.dispose();
    _hpController.dispose();
    _acController.dispose();
    _speedController.dispose();
    _initBonusController.dispose();
    _levelController.dispose();
    _crController.dispose();
    _strController.dispose();
    _dexController.dispose();
    _conController.dispose();
    _intController.dispose();
    _wisController.dispose();
    _chaController.dispose();
    _attacksController.dispose();
    _specialAbilitiesController.dispose();
    _legendaryActionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_getScreenTitle()),
        bottom: TabBar(
          controller: _tabController,
          tabs: _getTabs(),
        ),
        actions: [
          if (widget.characterType != CharacterType.player)
            IconButton(
              icon: const Icon(Icons.download),
              onPressed: _importFromOfficialMonster,
              tooltip: 'Aus offiziellem Monster importieren',
            ),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: _getTabViews(),
      ),
    );
  }

  String _getScreenTitle() {
    switch (widget.characterType) {
      case CharacterType.player:
        return widget.pcToEdit == null ? 'Neuen Helden erstellen' : 'Helden bearbeiten';
      case CharacterType.npc:
        return widget.creatureToEdit == null ? 'Neuen NSC erstellen' : 'NSC bearbeiten';
      case CharacterType.monster:
        return widget.creatureToEdit == null ? 'Neues Monster erstellen' : 'Monster bearbeiten';
    }
  }

  List<Tab> _getTabs() {
    switch (widget.characterType) {
      case CharacterType.player:
        return const [
          Tab(text: 'Basis', icon: Icon(Icons.info)),
          Tab(text: 'Attribute', icon: Icon(Icons.fitness_center)),
          Tab(text: 'Inventar', icon: Icon(Icons.inventory)),
        ];
      case CharacterType.npc:
      case CharacterType.monster:
        return const [
          Tab(text: 'Basis', icon: Icon(Icons.info)),
          Tab(text: 'Attribute', icon: Icon(Icons.fitness_center)),
          Tab(text: 'Fähigkeiten', icon: Icon(Icons.flash_on)),
          Tab(text: 'Inventar', icon: Icon(Icons.inventory)),
        ];
    }
  }

  List<Widget> _getTabViews() {
    switch (widget.characterType) {
      case CharacterType.player:
        return [
          _buildBasicInfoTabForPC(),
          _buildAttributesTabForPC(),
          _buildInventoryTab(),
        ];
      case CharacterType.npc:
      case CharacterType.monster:
        return [
          _buildBasicInfoTabForCreature(),
          _buildAttributesTabForCreature(),
          _buildAbilitiesTab(),
          _buildInventoryTab(),
        ];
    }
  }

  Widget _buildBasicInfoTabForPC() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name des Charakters *'),
              validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _playerNameController,
              decoration: const InputDecoration(labelText: 'Name des Spielers *'),
              validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<DndClass>(
              value: _selectedClass,
              decoration: const InputDecoration(labelText: 'Klasse *'),
              items: allDndClasses.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (val) => setState(() => _selectedClass = val),
              validator: (v) => v == null ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<DndRace>(
              value: _selectedRace,
              decoration: const InputDecoration(labelText: 'Rasse *'),
              items: allDndRaces.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
              onChanged: (val) => setState(() => _selectedRace = val),
              validator: (v) => v == null ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            
            _buildNumberField(_levelController, 'Stufe'),
            const SizedBox(height: 24),
            
            const Text('Kampfwerte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              children: [
                Expanded(child: _buildNumberField(_hpController, 'Maximale HP')),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(_acController, 'Rüstungsklasse')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTabForCreature() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            const Text('Kampf-Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(child: _buildNumberField(_hpController, 'Maximale HP *')),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(_acController, 'Rüstungsklasse (AC) *')),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(_initBonusController, 'Initiative-Bonus')),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: TextFormField(
                  controller: _speedController,
                  decoration: const InputDecoration(labelText: 'Bewegungsrate'),
                )),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(
                  controller: _crController,
                  decoration: const InputDecoration(labelText: 'Challenge Rating'),
                  keyboardType: TextInputType.number,
                )),
              ],
            ),
            const SizedBox(height: 16),
            
            const Text('D&D-Klassifikation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSize,
                    decoration: const InputDecoration(labelText: 'Größe'),
                    items: const [
                      DropdownMenuItem(value: 'Tiny', child: Text('Winzig')),
                      DropdownMenuItem(value: 'Small', child: Text('Klein')),
                      DropdownMenuItem(value: 'Medium', child: Text('Mittel')),
                      DropdownMenuItem(value: 'Large', child: Text('Groß')),
                      DropdownMenuItem(value: 'Huge', child: Text('Riesig')),
                      DropdownMenuItem(value: 'Gargantuan', child: Text('Gigantisch')),
                    ],
                    onChanged: (value) => setState(() => _selectedSize = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(labelText: 'Typ'),
                    items: const [
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
                      DropdownMenuItem(value: 'Undead', child: Text('Untot')),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: _selectedSubtype ?? ''),
                    decoration: const InputDecoration(labelText: 'Subtyp (optional)'),
                    onChanged: (value) => setState(() => _selectedSubtype = value?.isEmpty == true ? null : value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAlignment,
                    decoration: const InputDecoration(labelText: 'Gesinnung'),
                    items: const [
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
                    ],
                    onChanged: (value) => setState(() => _selectedAlignment = value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributesTabForPC() {
    return AttributesTabWidget(
      strController: _strController,
      dexController: _dexController,
      conController: _conController,
      intController: _intController,
      wisController: _wisController,
      chaController: _chaController,
      levelController: _levelController,
      proficientSkills: _proficientSkills,
      onSkillToggle: (skillName) {
        setState(() {
          if (_proficientSkills.contains(skillName)) {
            _proficientSkills.remove(skillName);
          } else {
            _proficientSkills.add(skillName);
          }
        });
      },
      onRebuild: () => setState(() {}),
      showSkills: true,
    );
  }

  Widget _buildAttributesTabForCreature() {
    return AttributesTabWidget(
      strController: _strController,
      dexController: _dexController,
      conController: _conController,
      intController: _intController,
      wisController: _wisController,
      chaController: _chaController,
      levelController: _levelController,
      proficientSkills: _proficientSkills,
      onSkillToggle: (skillName) {
        setState(() {
          if (_proficientSkills.contains(skillName)) {
            _proficientSkills.remove(skillName);
          } else {
            _proficientSkills.add(skillName);
          }
        });
      },
      onRebuild: () => setState(() {}),
      showSkills: false,
    );
  }

  Widget _buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAbilitiesTab() {
    return AbilitiesTabWidget(
      attacksController: _attacksController,
      specialAbilitiesController: _specialAbilitiesController,
      legendaryActionsController: _legendaryActionsController,
    );
  }

  Widget _buildModernAbilityCard({
    required String title,
    required IconData icon,
    required Color color,
    required TextEditingController controller,
    required String hintText,
    required String description,
  }) {
    final isEmpty = controller.text.trim().isEmpty;
    
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isEmpty)
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                  onPressed: () => _showAbilityTooltip(title, description),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          
          // Textfeld
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextFormField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: color.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: color, width: 2),
                ),
                alignLabelWithHint: true,
              ),
              maxLines: 6,
              keyboardType: TextInputType.multiline,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showAbilityTooltip(String title, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Verstanden"),
          ),
        ],
      ),
    );
  }

  void _showAbilitiesHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fähigkeiten & Aktionen Hilfe'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Angriffe & Aktionen:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Beschreiben Sie hier alle Angriffe und Aktionen, die die Kreatur ausführen kann.\n\n'
                'Format: "Angriffsname: +Bonus (Schaden) Beschreibung"\n'
                'Beispiel: "Schwerthieb: +4 (1W8+2) Hiegschaden"',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Spezielle Fähigkeiten:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Einzigartige Fähigkeiten wie Regeneration, Magieresistenz oder andere besondere Eigenschaften.\n\n'
                'Beispiel: "Regeneration (3/Runte). Die Kreatur heilt jede Runde 3 Schadenspunkte."',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Legendäre Aktionen:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Spezielle Aktionen für mächtige Monster (CR 10+), die außerhalb ihres normalen Zuges ausgeführt werden können.\n\n'
                'Beispiel: "Flügelschlag: Der Drache schlägt mit seinen Flügeln und verursacht 2W6 Schaden."',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Verstanden"),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return InventoryTabWidget(
      characterType: widget.characterType,
      inventory: _inventory,
      isLoadingInventory: _isLoadingInventory,
      gold: _gold,
      onGoldChanged: (value) => setState(() => _gold = value),
      onAddItem: _addItemFromLibrary,
      onLoadInventory: _loadInventory,
      onManageItem: widget.characterType == CharacterType.player ? _showManageItemDialog : (DisplayInventoryItem item) async {},
      onUpdateQuantity: _updateItemQuantity,
      onRemoveItem: _removeItem,
      pcId: widget.pcToEdit?.id,
      creatureId: widget.creatureToEdit?.id,
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
    );
  }

  Widget _buildAbilityScoreRow(String label, TextEditingController controller, String infoText) {
    void triggerRebuild() => setState(() {});
    final score = int.tryParse(controller.text) ?? 10;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey, size: 20),
            onPressed: () => _showInfoDialog(label, infoText),
            splashRadius: 20,
          ),
        ])),
        Expanded(flex: 2, child: TextFormField(
          controller: controller, textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onChanged: (_) => triggerRebuild(),
        )),
        Expanded(flex: 2, child: Center(child: Text(
          getModifierString(score),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ))),
      ]),
    );
  }

  Widget _buildAttributeField(TextEditingController controller, String label, String color) {
    final value = int.tryParse(controller.text) ?? 10;
    final modifier = ((value - 10) / 2).floor();
    final modifierText = modifier >= 0 ? '+$modifier' : '$modifier';
    
    Color avatarColor;
    switch (color) {
      case 'red': avatarColor = Colors.red; break;
      case 'green': avatarColor = Colors.green; break;
      case 'orange': avatarColor = Colors.orange; break;
      case 'blue': avatarColor = Colors.blue; break;
      case 'purple': avatarColor = Colors.purple; break;
      case 'pink': avatarColor = Colors.pink; break;
      default: avatarColor = Colors.grey;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: avatarColor,
                  child: Text(
                    value.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  modifierText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(isDense: true),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillRow(DndSkill skill) {
    final Map<Ability, TextEditingController> abilityControllers = {
      Ability.strength: _strController, Ability.dexterity: _dexController,
      Ability.constitution: _conController, Ability.intelligence: _intController,
      Ability.wisdom: _wisController, Ability.charisma: _chaController,
    };
    final score = int.tryParse(abilityControllers[skill.ability]!.text) ?? 10;
    final modifier = getModifier(score);
    final proficiencyBonus = getProficiencyBonus(int.tryParse(_levelController.text) ?? 1);
    final isProficient = _proficientSkills.contains(skill.name);
    final totalBonus = modifier + (isProficient ? proficiencyBonus : 0);
    final bonusString = totalBonus >= 0 ? "+$totalBonus" : totalBonus.toString();

    return Row(
      children: [
        Checkbox(
          value: isProficient,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _proficientSkills.add(skill.name);
              } else {
                _proficientSkills.remove(skill.name);
              }
            });
          },
        ),
        Expanded(child: Text(skill.name)),
        SizedBox(
          width: 40,
          child: Text(bonusString, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
        ),
      ],
    );
  }

  void _showInfoDialog(String title, String explanation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(explanation),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Verstanden")),
        ],
      ),
    );
  }

  Future<void> _showManageItemDialog(DisplayInventoryItem displayItem) async {
    final quantityController = TextEditingController(text: displayItem.inventoryItem.quantity.toString());
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(displayItem.item.name),
        content: TextField(
          controller: quantityController,
          decoration: const InputDecoration(labelText: "Menge"),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await dbHelper.deleteInventoryItem(displayItem.inventoryItem.id);
              if (mounted) Navigator.of(ctx).pop();
              _loadInventory();
            },
            child: const Text("Löschen", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newQuantity = int.tryParse(quantityController.text) ?? 1;
              final updatedItem = InventoryItem(
                id: displayItem.inventoryItem.id,
                ownerId: displayItem.inventoryItem.ownerId,
                itemId: displayItem.inventoryItem.itemId,
                quantity: newQuantity,
              );
              await dbHelper.updateInventoryItem(updatedItem);
              if (mounted) Navigator.of(ctx).pop();
              _loadInventory();
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );
  }

  Future<void> _removeItem(DisplayInventoryItem displayItem) async {
    try {
      await dbHelper.deleteInventoryItem(displayItem.inventoryItem.id);
      _loadInventory();

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${displayItem.item.name} wurde entfernt')),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Entfernen: $e')),
        );
      }
    }
  }

  Future<void> _updateItemQuantity(DisplayInventoryItem displayItem, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(displayItem);
      return;
    }

    try {
      final updatedItem = displayItem.inventoryItem.copyWith(quantity: newQuantity);
      await dbHelper.updateInventoryItem(updatedItem);
      _loadInventory();
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Aktualisieren: $e')),
        );
      }
    }
  }

  // NEUE METHODEN für moderne UI
  Widget _buildModernAttributeCard(String name, TextEditingController controller, Color color, String description) {
    final value = int.tryParse(controller.text) ?? 10;
    final modifier = getModifier(value);
    final modifierText = modifier >= 0 ? '+$modifier' : '$modifier';
    
    // Bestimme die Qualität des Attributwerts für visuelle Rückmeldung
    Color cardColor = Colors.white;
    Color borderColor = color.withOpacity(0.6);
    double elevation = 2.0;
    
    if (value >= 18) {
      borderColor = color.withOpacity(0.9);
      elevation = 4.0;
    } else if (value >= 14) {
      borderColor = color.withOpacity(0.7);
      elevation = 3.0;
    } else if (value <= 8) {
      borderColor = Colors.red.withOpacity(0.6);
      elevation = 1.5;
    }
    
    return Card(
      elevation: elevation,
      color: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: borderColor, width: 1.5),
      ),
      child: InkWell(
        onTap: () => _showAttributeQuickEdit(name, controller, color),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header mit Icon und Name
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: _getAttributeIcon(name),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[800],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _getAttributeShortDescription(name),
                          style: TextStyle(
                            fontSize: 9,
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Wert-Display mit visuellem Feedback
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      value.toString(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: _getValueColor(value),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        modifierText,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Quick-Buttons mit verbessertem Design
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildCompactQuickButton(
                    Icons.remove, 
                    () => _adjustAttribute(controller, -1),
                    color: Colors.red,
                  ),
                  _buildCompactQuickButton(
                    Icons.add, 
                    () => _adjustAttribute(controller, 1),
                    color: Colors.green,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getAttributeIcon(String name) {
    switch (name.toLowerCase()) {
      case 'stärke':
        return const Icon(Icons.fitness_center, color: Colors.white, size: 16);
      case 'geschicklichkeit':
        return const Icon(Icons.flash_on, color: Colors.white, size: 16);
      case 'konstitution':
        return const Icon(Icons.shield, color: Colors.white, size: 16);
      case 'intelligenz':
        return const Icon(Icons.psychology, color: Colors.white, size: 16);
      case 'weisheit':
        return const Icon(Icons.visibility, color: Colors.white, size: 16);
      case 'charisma':
        return const Icon(Icons.star, color: Colors.white, size: 16);
      default:
        return const Icon(Icons.help, color: Colors.white, size: 16);
    }
  }

  String _getAttributeShortDescription(String name) {
    switch (name.toLowerCase()) {
      case 'stärke':
        return 'Muskelkraft';
      case 'geschicklichkeit':
        return 'Reflexe & Geschick';
      case 'konstitution':
        return 'Ausdauer';
      case 'intelligenz':
        return 'Wissen';
      case 'weisheit':
        return 'Wahrnehmung';
      case 'charisma':
        return 'Persönlichkeit';
      default:
        return '';
    }
  }

  Color _getValueColor(int value) {
    if (value >= 18) return Colors.green[700]!;
    if (value >= 16) return Colors.green[600]!;
    if (value >= 14) return Colors.green[500]!;
    if (value >= 12) return Colors.blue[600]!;
    if (value >= 10) return Colors.blue[500]!;
    if (value >= 8) return Colors.orange[600]!;
    if (value >= 6) return Colors.orange[700]!;
    return Colors.red[700]!;
  }

  Widget _buildStyledQuickButton(IconData icon, VoidCallback onPressed, {required Color color, required String label}) {
    return Container(
      height: 36,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color, width: 1),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14),
            Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactQuickButton(IconData icon, VoidCallback onPressed, {required Color color}) {
    return Container(
      width: 32,
      height: 32,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.5),
          foregroundColor: color,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
            side: BorderSide(color: color, width: 1),
          ),
        ),
        child: Icon(icon, size: 16),
      ),
    );
  }

  Widget _buildQuickButton(IconData icon, VoidCallback onPressed, {double size = 20}) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          icon,
          size: size,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildModernSkillRow(DndSkill skill) {
    final Map<Ability, TextEditingController> abilityControllers = {
      Ability.strength: _strController, 
      Ability.dexterity: _dexController,
      Ability.constitution: _conController, 
      Ability.intelligence: _intController,
      Ability.wisdom: _wisController, 
      Ability.charisma: _chaController,
    };
    
    final score = int.tryParse(abilityControllers[skill.ability]!.text) ?? 10;
    final modifier = getModifier(score);
    final proficiencyBonus = getProficiencyBonus(int.tryParse(_levelController.text) ?? 1);
    final isProficient = _proficientSkills.contains(skill.name);
    final totalBonus = modifier + (isProficient ? proficiencyBonus : 0);
    final bonusString = totalBonus >= 0 ? "+$totalBonus" : totalBonus.toString();
    
    final abilityColors = {
      Ability.strength: Colors.red,
      Ability.dexterity: Colors.green,
      Ability.constitution: Colors.orange,
      Ability.intelligence: Colors.blue,
      Ability.wisdom: Colors.purple,
      Ability.charisma: Colors.pink,
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isProficient) {
              _proficientSkills.remove(skill.name);
            } else {
              _proficientSkills.add(skill.name);
            }
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Checkbox mit Fähigkeitsfarbe
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isProficient ? abilityColors[skill.ability]! : Colors.grey[300]!,
                    width: 2,
                  ),
                  color: isProficient ? abilityColors[skill.ability]!.withOpacity(0.2) : Colors.transparent,
                ),
                child: isProficient
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: abilityColors[skill.ability],
                      )
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // Fähigkeitsname und Attribut
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '(${skill.ability.name.toUpperCase()})',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bonus-Anzeige
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: totalBonus >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: totalBonus >= 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  bonusString,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: totalBonus >= 0 ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _adjustAttribute(TextEditingController controller, int adjustment) {
    final currentValue = int.tryParse(controller.text) ?? 10;
    final newValue = (currentValue + adjustment).clamp(1, 30); // D&D 5e limits
    controller.text = newValue.toString();
    setState(() {}); // Trigger rebuild to update modifiers
  }

  void _showAttributeQuickEdit(String name, TextEditingController controller, Color color) {
    final currentValue = int.tryParse(controller.text) ?? 10;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$name bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aktueller Wert: $currentValue',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEditButton(ctx, '-5', () => controller.text = (currentValue - 5).clamp(1, 30).toString()),
                _buildEditButton(ctx, '-1', () => controller.text = (currentValue - 1).clamp(1, 30).toString()),
                _buildEditButton(ctx, '+1', () => controller.text = (currentValue + 1).clamp(1, 30).toString()),
                _buildEditButton(ctx, '+5', () => controller.text = (currentValue + 5).clamp(1, 30).toString()),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: color),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {}); // Trigger rebuild
              Navigator.of(ctx).pop();
            },
            child: const Text("Übernehmen"),
          ),
        ],
      ),
    );
  }

  Widget _buildEditButton(BuildContext context, String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  void _showAttributeTooltip(String name, String description) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(name),
        content: Text(description),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Verstanden"),
          ),
        ],
      ),
    );
  }

  void _showAttributesHelpDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attribute & Fertigkeiten Hilfe'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Die 6 Hauptattribute:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Stärke (STR): Muskelkraft, Nahkampf\n'
                '• Geschicklichkeit (DEX): Reflexe, Geschick\n'
                '• Konstitution (CON): Ausdauer, HP\n'
                '• Intelligenz (INT): Wissen, Logik\n'
                '• Weisheit (WIS): Wahrnehmung, Intuition\n'
                '• Charisma (CHA): Persönlichkeit',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Modifier:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Der Modifier wird berechnet als: (Attribut - 10) / 2\n'
                'Beispiel: 16 Stärke = (16-10)/2 = +3 Modifier',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Fertigkeiten:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Markierte Fertigkeiten erhalten den Proficiency-Bonus\n'
                'dazu auf den Attribut-Modifier.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Verstanden"),
          ),
        ],
      ),
    );
  }
}

// Extension für InventoryItem copyWith
extension InventoryItemCopy on InventoryItem {
  InventoryItem copyWith({
    String? id,
    String? ownerId,
    String? itemId,
    int? quantity,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
    );
  }
}
