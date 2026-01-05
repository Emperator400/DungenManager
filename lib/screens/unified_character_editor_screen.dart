import 'package:flutter/material.dart';
import '../models/creature.dart';
import '../models/player_character.dart';
import '../widgets/character_editor/enhanced_character_editor_controller.dart'
    show EnhancedCharacterEditorController;
import '../widgets/character_editor/character_editor_controller.dart'
    show CharacterType;
import '../viewmodels/character_editor_viewmodel.dart';
import '../widgets/character_editor/character_tab_manager.dart';
import '../widgets/character_editor/character_inventory_handler.dart';
import '../screens/enhanced_official_monsters_screen.dart';
import '../models/official_monster.dart';
import '../theme/dnd_theme.dart';

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
  
  late EnhancedCharacterEditorController _controller;
  late CharacterTabManager _tabManager;
  late CharacterInventoryHandler _inventoryHandler;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeComponents();
  }

  void _initializeComponents() {
    // ViewModel erstellen
    final viewModel = CharacterEditorViewModel();
    
    // Vorhandene Character laden (falls vorhanden)
    if (widget.pcToEdit != null) {
      viewModel.initWithPlayerCharacter(widget.pcToEdit!.id);
    } else if (widget.creatureToEdit != null) {
      viewModel.initWithCreature(widget.creatureToEdit!.id);
    } else {
      // Neuen Character vorbereiten - ViewModel ist schon im richtigen Zustand
      // Die initialen Werte werden vom Controller geladen
    }
    
    // Controller initialisieren
    _controller = EnhancedCharacterEditorController(
      characterType: widget.characterType,
      campaignId: widget.campaignId,
      viewModel: viewModel,
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
    setState(() {
      _isLoading = true;
    });
    try {
      await _controller.loadInventory();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Inventars: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
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
        builder: (ctx) => const EnhancedOfficialMonstersScreen(),
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
      backgroundColor: DnDTheme.dungeonBlack,
      appBar: AppBar(
        title: Text(
          _tabManager.getScreenTitle(),
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: DnDTheme.ancientGold,
          unselectedLabelColor: DnDTheme.mysticalPurple.withOpacity(0.7),
          indicatorColor: DnDTheme.ancientGold,
          indicatorWeight: 3,
          tabs: _tabManager.getTabs(),
        ),
        actions: [
          if (widget.characterType != CharacterType.player)
            Container(
              margin: const EdgeInsets.only(right: DnDTheme.sm),
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.arcaneBlue,
                width: 2,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.download,
                  color: DnDTheme.arcaneBlue,
                ),
                onPressed: _importFromOfficialMonster,
                tooltip: 'Aus offiziellem Monster importieren',
              ),
            ),
          Container(
            margin: const EdgeInsets.only(right: DnDTheme.sm),
            decoration: DnDTheme.getMysticalBorder(
              borderColor: DnDTheme.successGreen,
              width: 2,
            ),
            child: IconButton(
              icon: Icon(
                Icons.save,
                color: DnDTheme.successGreen,
              ),
              onPressed: _saveForm,
              tooltip: 'Speichern',
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(DnDTheme.ancientGold),
              ),
            )
          : Container(
              decoration: BoxDecoration(
                gradient: DnDTheme.getMysticalGradient(
                  startColor: DnDTheme.dungeonBlack,
                  endColor: DnDTheme.stoneGrey,
                ),
              ),
              child: TabBarView(
                controller: _tabController,
                children: _buildTabViews(),
              ),
            ),
    );
  }

  List<Widget> _buildTabViews() {
    return _tabManager.getTabViews();
  }

}
