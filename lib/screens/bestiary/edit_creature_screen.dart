import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creature.dart';
import '../../models/official_monster.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/edit_creature_viewmodel.dart';
import '../../widgets/bestiary/edit_creature/edit_creature_screen_widgets.dart';
import '../../widgets/ui_components/feedback/confirmation_dialog.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/inventory/creature_inventory_widget.dart';
import '../../widgets/ui_components/states/loading_state_widget.dart';
import '../../widgets/ui_components/stats/attributes_section_widget.dart';
import '../bestiary/official_monsters_screen.dart';

class EditCreatureScreen extends StatefulWidget {
  const EditCreatureScreen({super.key, this.creature});

  final Creature? creature;

  @override
  State<EditCreatureScreen> createState() => _EditCreatureScreenState();
}

class _EditCreatureScreenState extends State<EditCreatureScreen>
    with SingleTickerProviderStateMixin {
  static const int _tabCount = 4;

  late EditCreatureViewModel _viewModel;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _viewModel = EditCreatureViewModel();
    _tabController = TabController(length: _tabCount, vsync: this);
    _initializeViewModel();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _initializeViewModel() async {
    try {
      await _viewModel.initialize(widget.creature);
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Initialisieren: $e');
      }
    }
  }

  Future<void> _importFromOfficialMonster() async {
    final monster = await Navigator.of(context).push<OfficialMonster>(
      MaterialPageRoute(builder: (ctx) => const OfficialMonstersScreen()),
    );
    if (monster == null || !mounted) {
      return;
    }

    _viewModel
      ..updateName(monster.name)
      ..updateSize(monster.size)
      ..updateType(monster.type)
      ..updateSubtype(monster.subtype)
      ..updateAlignment(monster.alignment)
      ..updateSpeed(monster.speed)
      ..updateMaxHp(monster.hitPoints)
      ..updateStrength(monster.strength)
      ..updateDexterity(monster.dexterity)
      ..updateConstitution(monster.constitution)
      ..updateIntelligence(monster.intelligence)
      ..updateWisdom(monster.wisdom)
      ..updateCharisma(monster.charisma);

    final acInt = int.tryParse(monster.armorClass.split(' ').first) ?? 10;
    _viewModel
      ..updateArmorClass(acInt)
      ..updateChallengeRating(monster.challengeRating.round());

    if (monster.specialAbilities.isNotEmpty) {
      _viewModel.updateSpecialAbilities(
        monster.specialAbilities.map((a) => '${a.name}: ${a.description}').join('\n\n'),
      );
    }
    if (monster.legendaryActions != null && monster.legendaryActions!.isNotEmpty) {
      _viewModel.updateLegendaryActions(
        monster.legendaryActions!.map((a) => '${a.name}: ${a.description}').join('\n\n'),
      );
    }
    if (monster.actions.isNotEmpty) {
      _viewModel.updateAttacks(
        monster.actions.map((a) => '${a.name}: ${a.description}').join('\n\n'),
      );
    }

    SnackBarHelper.showSuccess(context, '${monster.name} wurde importiert');
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return ChangeNotifierProvider<EditCreatureViewModel>.value(
      value: _viewModel,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) Navigator.of(context).pop();
        },
        child: Scaffold(
          backgroundColor: C.bg,
          body: Column(
            children: [
              _buildHeader(C),
              _buildTabBar(C),
              Expanded(child: _buildBody()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension C) {
    const amber = Color(0xFFD97706);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          bottom: false,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _iconBtn(C, Icons.arrow_back, C.textMid, _onBackPressed),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 18, color: C.border),
                  const SizedBox(width: 10),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: amber.withValues(alpha: 0.12),
                      border: Border.all(color: amber.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: const Center(child: Icon(Icons.pets, size: 14, color: amber)),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Consumer<EditCreatureViewModel>(
                      builder: (context, vm, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            vm.isEditing ? 'Kreatur bearbeiten' : 'Neue Kreatur',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (vm.name.isNotEmpty)
                            Text(
                              vm.name,
                              style: TextStyle(fontSize: 11, color: C.textSoft),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ),
                  Consumer<EditCreatureViewModel>(
                    builder: (context, vm, _) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _iconBtn(C, Icons.download_outlined, C.accent, _importFromOfficialMonster),
                        const SizedBox(width: 6),
                        if (vm.isSaving)
                          SizedBox(
                            width: 30,
                            height: 30,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: C.border),
                                borderRadius: BorderRadius.circular(7),
                                color: C.bgHover,
                              ),
                              child: Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 1.5, color: C.green),
                                ),
                              ),
                            ),
                          )
                        else
                          _iconBtn(
                            C,
                            Icons.save_outlined,
                            vm.canSave ? C.green : C.textSoft,
                            vm.canSave ? _saveCreature : null,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: C.border),
      ],
    );
  }

  Widget _buildTabBar(AppColorsExtension C) {
    const amber = Color(0xFFD97706);
    return Container(
      color: C.bgPanel,
      child: TabBar(
        controller: _tabController,
        indicatorColor: amber,
        labelColor: amber,
        unselectedLabelColor: C.textSoft,
        labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.normal),
        indicatorWeight: 3,
        tabs: const [
          Tab(icon: Icon(Icons.pets, size: 18), text: 'Grunddaten'),
          Tab(icon: Icon(Icons.fitness_center, size: 18), text: 'Attribute'),
          Tab(icon: Icon(Icons.category, size: 18), text: 'Fähigkeiten'),
          Tab(icon: Icon(Icons.inventory, size: 18), text: 'Inventar'),
        ],
      ),
    );
  }

  Widget _buildBody() => Consumer<EditCreatureViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) return const LoadingStateWidget();
          if (viewModel.error != null) {
            return CreatureErrorWidget(
              error: viewModel.error!,
              onRetry: () {
                viewModel.clearError();
                _initializeViewModel();
              },
            );
          }
          return TabBarView(
            key: ValueKey<bool>(_isInitialized),
            controller: _tabController,
            children: [
              _buildBasicInfoTab(),
              _buildAttributesTab(),
              _buildAbilitiesTab(),
              _buildInventoryTab(),
            ],
          );
        },
      );

  Widget _buildBasicInfoTab() => Consumer<EditCreatureViewModel>(
        builder: (context, viewModel, child) => Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitleWidget(title: 'Grundinformationen', icon: Icons.pets),
                const SizedBox(height: 16),
                BasicInfoSection(
                  name: viewModel.name,
                  description: viewModel.description,
                  speed: viewModel.speed,
                  onNameChanged: viewModel.updateName,
                  onDescriptionChanged: viewModel.updateDescription,
                  onSpeedChanged: viewModel.updateSpeed,
                ),
                const SizedBox(height: 32),
                const SectionTitleWidget(title: 'Kreatureigenschaften', icon: Icons.category),
                const SizedBox(height: 16),
                CreatureTypeSection(
                  type: viewModel.type,
                  subtype: viewModel.subtype,
                  size: viewModel.size,
                  alignment: viewModel.alignment,
                  onTypeChanged: viewModel.updateType,
                  onSubtypeChanged: viewModel.updateSubtype,
                  onSizeChanged: viewModel.updateSize,
                  onAlignmentChanged: viewModel.updateAlignment,
                ),
                const SizedBox(height: 32),
                const SectionTitleWidget(title: 'Kampfwerte', icon: Icons.security),
                const SizedBox(height: 16),
                CombatStatsSection(
                  maxHp: viewModel.maxHp,
                  armorClass: viewModel.armorClass,
                  challengeRating: viewModel.challengeRating,
                  onMaxHpChanged: viewModel.updateMaxHp,
                  onArmorClassChanged: viewModel.updateArmorClass,
                  onChallengeRatingChanged: viewModel.updateChallengeRating,
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildAttributesTab() => Consumer<EditCreatureViewModel>(
        builder: (context, viewModel, child) => SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: AttributesSectionWidget(
            strength: viewModel.strength,
            dexterity: viewModel.dexterity,
            constitution: viewModel.constitution,
            intelligence: viewModel.intelligence,
            wisdom: viewModel.wisdom,
            charisma: viewModel.charisma,
            onStrengthChanged: viewModel.updateStrength,
            onDexterityChanged: viewModel.updateDexterity,
            onConstitutionChanged: viewModel.updateConstitution,
            onIntelligenceChanged: viewModel.updateIntelligence,
            onWisdomChanged: viewModel.updateWisdom,
            onCharismaChanged: viewModel.updateCharisma,
            title: 'Attribute',
            icon: Icons.fitness_center,
            useSectionCard: true,
          ),
        ),
      );

  Widget _buildAbilitiesTab() => Consumer<EditCreatureViewModel>(
        builder: (context, viewModel, child) => SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitleWidget(title: 'Angriffe & Fähigkeiten', icon: Icons.auto_awesome),
              const SizedBox(height: 16),
              AbilitiesSection(
                attacks: viewModel.attacks,
                specialAbilities: viewModel.specialAbilities,
                legendaryActions: viewModel.legendaryActions,
                onAttacksChanged: viewModel.updateAttacks,
                onSpecialAbilitiesChanged: viewModel.updateSpecialAbilities,
                onLegendaryActionsChanged: viewModel.updateLegendaryActions,
              ),
              const SizedBox(height: 32),
              const SectionTitleWidget(title: 'Währung', icon: Icons.monetization_on),
              const SizedBox(height: 16),
              CurrencySection(
                gold: viewModel.gold,
                silver: viewModel.silver,
                copper: viewModel.copper,
                onGoldChanged: viewModel.updateGold,
                onSilverChanged: viewModel.updateSilver,
                onCopperChanged: viewModel.updateCopper,
              ),
            ],
          ),
        ),
      );

  Widget _buildInventoryTab() => Consumer<EditCreatureViewModel>(
        builder: (context, viewModel, child) => CreatureInventoryWidget(
          mapItems: viewModel.inventory,
          onAddItem: () => CreatureItemDialogs.showAddItemDialog(context, viewModel),
          onRemoveItem: (index) => viewModel.removeInventoryItem(index),
          onEditItem: (index, item) =>
              CreatureItemDialogs.showEditItemDialog(context, viewModel, index),
          showAddButton: true,
        ),
      );

  Widget _iconBtn(
    AppColorsExtension C,
    IconData icon,
    Color iconColor,
    VoidCallback? onTap,
  ) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            border: Border.all(color: C.border),
            borderRadius: BorderRadius.circular(7),
            color: C.bgHover,
          ),
          child: Center(child: Icon(icon, size: 16, color: iconColor)),
        ),
      );

  Future<void> _onBackPressed() async {
    final shouldPop = await _onWillPop();
    if (shouldPop && mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _saveCreature() async {
    FocusScope.of(context).unfocus();
    final errors = <String>[];
    if (_viewModel.name.trim().isEmpty) errors.add('Name der Kreatur');
    if (_viewModel.maxHp < 1) errors.add('Max. HP (muss mindestens 1 sein)');
    if (_viewModel.armorClass < 1) errors.add('Rüstungsklasse (muss mindestens 1 sein)');

    if (errors.isNotEmpty) {
      if (mounted) {
        SnackBarHelper.showError(
          context,
          'Bitte folgende Pflichtfelder ausfüllen:\n\n${errors.map((e) => '• $e').join('\n')}',
        );
      }
      return;
    }

    try {
      final success = await _viewModel.saveCreature();
      if (success && mounted) {
        SnackBarHelper.showSuccess(
          context,
          _viewModel.isEditing ? 'Kreatur erfolgreich aktualisiert' : 'Neue Kreatur erstellt',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler beim Speichern: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (!_viewModel.isEditing) return true;
    final shouldPop = await ConfirmationDialog.showWarning(
      context: context,
      title: 'Ungespeicherte Änderungen',
      message: 'Möchtest du wirklich ohne Speichern gehen?',
      confirmText: 'Verlassen',
    );
    return shouldPop ?? false;
  }
}
