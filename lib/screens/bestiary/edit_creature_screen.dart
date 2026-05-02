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

// ── Tab definitions ───────────────────────────────────────────────────────────

const _kTabs = [
  (Icons.pets,           'Grunddaten'),
  (Icons.fitness_center, 'Attribute'),
  (Icons.category,       'Fähigkeiten'),
  (Icons.inventory,      'Inventar'),
];

const _kAmber = Color(0xFFD97706);

// ── Screen ────────────────────────────────────────────────────────────────────

class EditCreatureScreen extends StatefulWidget {
  const EditCreatureScreen({super.key, this.creature});

  final Creature? creature;

  @override
  State<EditCreatureScreen> createState() => _EditCreatureScreenState();
}

class _EditCreatureScreenState extends State<EditCreatureScreen>
    with SingleTickerProviderStateMixin {
  late EditCreatureViewModel _viewModel;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _viewModel = EditCreatureViewModel();
    _tabController = TabController(length: _kTabs.length, vsync: this);
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
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler beim Initialisieren: $e');
    }
  }

  Future<void> _importFromOfficialMonster() async {
    final monster = await Navigator.of(context).push<OfficialMonster>(
      MaterialPageRoute(builder: (ctx) => const OfficialMonstersScreen()),
    );
    if (monster == null || !mounted) return;

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
    if (monster.legendaryActions != null &&
        monster.legendaryActions!.isNotEmpty) {
      _viewModel.updateLegendaryActions(
        monster.legendaryActions!
            .map((a) => '${a.name}: ${a.description}')
            .join('\n\n'),
      );
    }
    if (monster.actions.isNotEmpty) {
      _viewModel.updateAttacks(
        monster.actions.map((a) => '${a.name}: ${a.description}').join('\n\n'),
      );
    }

    SnackBarHelper.showSuccess(context, '${monster.name} wurde importiert');
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

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
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Consumer<EditCreatureViewModel>(
              builder: (context, vm, _) => AnimatedBuilder(
                animation: _tabController,
                builder: (_, __) => _buildTopBar(C, vm),
              ),
            ),
          ),
          body: _buildBody(),
        ),
      ),
    );
  }

  // ── Top Bar ───────────────────────────────────────────────────────────────

  Widget _buildTopBar(AppColorsExtension C, EditCreatureViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                // Back
                _IconBtn(icon: Icons.arrow_back, color: C.textMid, onTap: _onBackPressed),
                Container(
                  width: 1, height: 18, color: C.border,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                ),
                // Avatar
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: _kAmber.withValues(alpha: 0.18),
                    border: Border.all(color: _kAmber.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: const Center(
                    child: Icon(Icons.pets, size: 14, color: _kAmber),
                  ),
                ),
                const SizedBox(width: 8),
                // Name + subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      vm.name.isEmpty
                          ? (vm.isEditing ? 'Kreatur bearbeiten' : 'Neue Kreatur')
                          : vm.name,
                      style: TextStyle(
                          color: C.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          height: 1.1),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      vm.isEditing ? 'Kreatur bearbeiten' : 'Neue Kreatur',
                      style: TextStyle(
                          color: C.textSoft, fontSize: 10, height: 1.1),
                    ),
                  ],
                ),
                Container(
                  width: 1, height: 18, color: C.border,
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                ),
                // Tab buttons (center)
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (int i = 0; i < _kTabs.length; i++)
                            _TabBtn(
                              icon: _kTabs[i].$1,
                              label: _kTabs[i].$2,
                              isActive: _tabController.index == i,
                              onTap: () => _tabController.animateTo(i),
                              C: C,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Import + Save
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _IconBtn(
                      icon: Icons.download_outlined,
                      color: C.accent,
                      onTap: _importFromOfficialMonster,
                    ),
                    const SizedBox(width: 8),
                    _SaveBtn(
                      isSaving: vm.isSaving,
                      canSave: vm.canSave,
                      onSave: _saveCreature,
                      C: C,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────

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

  // ── Tab: Grunddaten ───────────────────────────────────────────────────────

  Widget _buildBasicInfoTab() => Consumer<EditCreatureViewModel>(
        builder: (context, viewModel, child) => Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitleWidget(
                    title: 'Grundinformationen', icon: Icons.pets),
                const SizedBox(height: 16),
                BasicInfoSection(
                  name: viewModel.name,
                  description: viewModel.description,
                  speed: viewModel.speed,
                  onNameChanged: viewModel.updateName,
                  onDescriptionChanged: viewModel.updateDescription,
                  onSpeedChanged: viewModel.updateSpeed,
                ),
                const SizedBox(height: 24),
                const SectionTitleWidget(
                    title: 'Kreatureigenschaften', icon: Icons.category),
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
                const SizedBox(height: 24),
                const SectionTitleWidget(
                    title: 'Kampfwerte', icon: Icons.security),
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

  // ── Tab: Attribute ────────────────────────────────────────────────────────

  Widget _buildAttributesTab() => Consumer<EditCreatureViewModel>(
        builder: (context, viewModel, child) => SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
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

  // ── Tab: Fähigkeiten ──────────────────────────────────────────────────────

  Widget _buildAbilitiesTab() => Consumer<EditCreatureViewModel>(
        builder: (context, viewModel, child) => SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitleWidget(
                  title: 'Angriffe & Fähigkeiten', icon: Icons.auto_awesome),
              const SizedBox(height: 16),
              AbilitiesSection(
                attacks: viewModel.attacks,
                specialAbilities: viewModel.specialAbilities,
                legendaryActions: viewModel.legendaryActions,
                onAttacksChanged: viewModel.updateAttacks,
                onSpecialAbilitiesChanged: viewModel.updateSpecialAbilities,
                onLegendaryActionsChanged: viewModel.updateLegendaryActions,
              ),
              const SizedBox(height: 24),
              const SectionTitleWidget(
                  title: 'Währung', icon: Icons.monetization_on),
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

  // ── Tab: Inventar ─────────────────────────────────────────────────────────

  Widget _buildInventoryTab() => Consumer<EditCreatureViewModel>(
        builder: (context, viewModel, child) => CreatureInventoryWidget(
          mapItems: viewModel.inventory,
          onAddItem: () =>
              CreatureItemDialogs.showAddItemDialog(context, viewModel),
          onRemoveItem: (index) => viewModel.removeInventoryItem(index),
          onEditItem: (index, item) =>
              CreatureItemDialogs.showEditItemDialog(context, viewModel, index),
          showAddButton: true,
        ),
      );

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _onBackPressed() async {
    final shouldPop = await _onWillPop();
    if (shouldPop && mounted) Navigator.of(context).pop();
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
          'Pflichtfelder:\n${errors.map((e) => '• $e').join('\n')}',
        );
      }
      return;
    }

    try {
      final success = await _viewModel.saveCreature();
      if (success && mounted) {
        SnackBarHelper.showSuccess(
          context,
          _viewModel.isEditing
              ? 'Kreatur erfolgreich aktualisiert'
              : 'Neue Kreatur erstellt',
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

// ── _TabBtn ───────────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  const _TabBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.C,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive ? C.bgHover : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isActive ? C.accent : C.textSoft),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isActive ? C.text : C.textMid,
                fontSize: 12,
                fontWeight:
                    isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── _SaveBtn ──────────────────────────────────────────────────────────────────

class _SaveBtn extends StatelessWidget {
  const _SaveBtn({
    required this.isSaving,
    required this.canSave,
    required this.onSave,
    required this.C,
  });

  final bool isSaving;
  final bool canSave;
  final VoidCallback onSave;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: (isSaving || !canSave) ? null : onSave,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: canSave ? C.green : C.bgHover,
          borderRadius: BorderRadius.circular(7),
        ),
        child: isSaving
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.save,
                      size: 13,
                      color: canSave ? Colors.white : C.textSoft),
                  const SizedBox(width: 5),
                  Text(
                    'Speichern',
                    style: TextStyle(
                      color: canSave ? Colors.white : C.textSoft,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── _IconBtn ──────────────────────────────────────────────────────────────────

class _IconBtn extends StatelessWidget {
  const _IconBtn({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 30,
        height: 30,
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
