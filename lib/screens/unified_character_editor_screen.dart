import 'package:flutter/material.dart';
import '../models/creature.dart';
import '../models/player_character.dart';
import '../widgets/character_editor/character_editor_controller.dart'
    show CharacterEditorController, CharacterType;
import '../widgets/character_editor/character_tab_manager.dart';
import '../widgets/character_editor/character_inventory_handler.dart';
import '../screens/official_monsters_screen.dart';
import '../models/official_monster.dart';

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

class _UnifiedCharacterEditorScreenState extends State<UnifiedCharacterEditorScreen> 
    with TickerProviderStateMixin {
  
  late CharacterEditorController _controller;
  late CharacterTabManager _tabManager;
  late CharacterInventoryHandler _inventoryHandler;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  void _initializeComponents() {
    // Controller initialisieren
    _controller = CharacterEditorController(
      characterType: widget.characterType,
      campaignId: widget.campaignId,
      creatureToEdit: widget.creatureToEdit,
      pcToEdit: widget.pcToEdit,
    );
    _controller.initializeControllers();

    // Inventory Handler initialisieren (vor Tab Manager)
    _inventoryHandler = CharacterInventoryHandler(
      controller: _controller,
      context: context,
      onInventoryChanged: () => setState(() {}),
    );

    // Tab Manager initialisieren
    _tabManager = CharacterTabManager(
      controller: _controller,
      vsync: this,
      onStateChanged: () => setState(() {}),
      formKey: _formKey,
      inventoryHandler: _inventoryHandler,
    );

    // Tab Controller erstellen
    _tabController = _tabManager.createTabController();

    // Inventar laden
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    try {
      await _controller.loadInventory();
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Inventars: $e')),
        );
      }
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState?.validate() == true) {
      try {
        await _controller.saveForm();
        
        if (mounted && context.mounted) {
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Speichern: $e')),
          );
        }
      }
    }
  }

  Future<void> _importFromOfficialMonster() async {
    final selectedMonster = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const OfficialMonstersScreen(),
      ),
    );

    if (selectedMonster != null && selectedMonster is OfficialMonster && mounted) {
      _controller.importFromOfficialMonster(selectedMonster);
      setState(() {});
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedMonster.name} wurde importiert')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_tabManager.getScreenTitle()),
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabManager.getTabs(),
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
        children: _buildTabViews(),
      ),
    );
  }

  List<Widget> _buildTabViews() {
    return _tabManager.getTabViews();
  }

}
