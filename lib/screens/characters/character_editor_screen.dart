import 'package:flutter/material.dart';
import '../../models/creature.dart';
import '../../models/official_monster.dart';
import '../../models/player_character.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/character_editor_viewmodel.dart';
import '../../widgets/character_editor/character_editor_controller.dart' show CharacterType;
import '../../widgets/character_editor/character_inventory_handler.dart';
import '../../widgets/character_editor/character_tab_manager.dart';
import '../../widgets/character_editor/enhanced_character_editor_controller.dart'
    show EnhancedCharacterEditorController;
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/states/loading_state_widget.dart';
import '../bestiary/official_monsters_screen.dart';

class UnifiedCharacterEditorScreen extends StatefulWidget {
  const UnifiedCharacterEditorScreen({
    super.key,
    required this.characterType,
    this.campaignId,
    this.creatureToEdit,
    this.pcToEdit,
  });

  final CharacterType characterType;
  final String? campaignId;
  final Creature? creatureToEdit;
  final PlayerCharacter? pcToEdit;

  @override
  State<UnifiedCharacterEditorScreen> createState() =>
      _UnifiedCharacterEditorScreenState();
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
    final viewModel = CharacterEditorViewModel();
    if (widget.pcToEdit != null) {
      viewModel.initWithPlayerCharacter(widget.pcToEdit!.id);
    } else if (widget.creatureToEdit != null) {
      viewModel.initWithCreature(widget.creatureToEdit!.id);
    }

    _controller = EnhancedCharacterEditorController(
      characterType: widget.characterType,
      campaignId: widget.campaignId,
      viewModel: viewModel,
    );
    _controller.initializeControllers();

    _inventoryHandler = CharacterInventoryHandler(
      controller: _controller,
      context: context,
      onInventoryChanged: () => setState(() {}),
    );

    _tabManager = CharacterTabManager(
      controller: _controller,
      vsync: this,
      onStateChanged: () => setState(() {}),
      formKey: _formKey,
      inventoryHandler: _inventoryHandler,
    );

    _tabController = _tabManager.createTabController();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _isLoading = true);
    try {
      await _controller.loadInventory();
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler beim Laden des Inventars: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState?.validate() == true) {
      try {
        await _controller.saveForm();
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        if (mounted) SnackBarHelper.showError(context, 'Fehler beim Speichern: $e');
      }
    }
  }

  Future<void> _importFromOfficialMonster() async {
    final selectedMonster = await Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const OfficialMonstersScreen()),
    );
    if (selectedMonster != null && selectedMonster is OfficialMonster && mounted) {
      _controller.importFromOfficialMonster(selectedMonster);
      setState(() {});
      SnackBarHelper.showSuccess(context, '${selectedMonster.name} wurde importiert');
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
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bgPanel,
        title: Text(
          _tabManager.getScreenTitle(),
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: C.amber),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: C.amber,
          unselectedLabelColor: C.textMid,
          indicatorColor: C.amber,
          indicatorWeight: 3,
          tabs: _tabManager.getTabs(),
        ),
        actions: [
          if (widget.characterType != CharacterType.player)
            IconButton(
              icon: Icon(Icons.download, color: C.accent),
              onPressed: _importFromOfficialMonster,
              tooltip: 'Aus offiziellem Monster importieren',
            ),
          IconButton(
            icon: Icon(Icons.save, color: C.green),
            onPressed: _saveForm,
            tooltip: 'Speichern',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingStateWidget()
          : TabBarView(
              controller: _tabController,
              children: _tabManager.getTabViews(),
            ),
    );
  }
}
