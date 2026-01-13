import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../game_data/dnd_logic.dart';
import '../game_data/dnd_models.dart';
import '../game_data/game_data.dart';
import '../models/player_character.dart';
import '../models/inventory_item.dart';
import '../theme/dnd_theme.dart';
import '../viewmodels/edit_pc_viewmodel.dart';
import '../widgets/ui_components/feedback/snackbar_helper.dart';
import '../widgets/ui_components/forms/form_field_widget.dart';
import '../widgets/ui_components/stats/ability_score_widget.dart';
import '../widgets/ui_components/skills/skill_list_widget.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/player_character_model_repository.dart';

import 'add_item_from_library_screen.dart';

/// Enhanced Edit PC Screen mit Provider-Pattern und modernem, uebersichtlichem D&D Design
class EnhancedEditPCScreen extends StatefulWidget {
  final String campaignId;
  final PlayerCharacter? pcToEdit;

  const EnhancedEditPCScreen({
    super.key,
    required this.campaignId,
    this.pcToEdit,
  });

  @override
  State<EnhancedEditPCScreen> createState() => _EnhancedEditPCScreenState();
}

class _EnhancedEditPCScreenState extends State<EnhancedEditPCScreen>
    with SingleTickerProviderStateMixin {
  static const int _tabCount = 4;
  static const int _minAbilityScore = 1;
  static const int _maxAbilityScore = 20;
  static const Duration _debounceDelay = Duration(milliseconds: 300);

  late EditPCViewModel _viewModel;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isInitialized = false;
  String _skillSearchQuery = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _viewModel = EditPCViewModel(
      pcRepository: PlayerCharacterModelRepository(DatabaseConnection.instance),
    );
    _tabController = TabController(length: _tabCount, vsync: this);
    _initializeViewModel();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _initializeViewModel() async {
    try {
      await _viewModel.initialize(widget.campaignId, widget.pcToEdit);
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Initialisieren: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditPCViewModel>.value(
      value: _viewModel,
      child: WillPopScope(
        onWillPop: _onWillPop,
        child: Scaffold(
          backgroundColor: DnDTheme.dungeonBlack,
          appBar: _buildAppBar(),
          body: _buildBody(),
          floatingActionButton: _buildFloatingActionButton(),
        ),
      ),
    );
  }

  // ============================================================================

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _viewModel.isEdit ? 'Held bearbeiten' : 'Neuen Held erstellen',
        style: DnDTheme.headline2.copyWith(
          color: DnDTheme.ancientGold,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: DnDTheme.stoneGrey,
      foregroundColor: Colors.white,
      elevation: 2,
      centerTitle: true,
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: DnDTheme.ancientGold,
        labelColor: DnDTheme.ancientGold,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.person), text: ' Stammdaten'),
          Tab(icon: Icon(Icons.fitness_center), text: ' Attribute'),
          Tab(icon: Icon(Icons.category), text: ' D&D Details'),
          Tab(icon: Icon(Icons.inventory), text: ' Inventar'),
        ],
      ),
    );
  }

  // ============================================================================

  Widget _buildBody() {
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.error != null) {
          return _buildErrorWidget(viewModel.error!);
        }

        return TabBarView(
          key: ValueKey<bool>(_isInitialized),
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildAttributesTab(),
            _buildDnDDetailsTab(),
            _buildInventoryTab(),
          ],
        );
      },
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(DnDTheme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: DnDTheme.errorRed,
              size: 64,
            ),
            const SizedBox(height: DnDTheme.lg),
            Text(
              'Fehler',
              style: DnDTheme.headline2.copyWith(
                color: DnDTheme.errorRed,
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              error,
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DnDTheme.xl),
            ElevatedButton.icon(
              onPressed: () {
                _viewModel.clearError();
                _initializeViewModel();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.arcaneBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: DnDTheme.lg,
                  vertical: DnDTheme.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================

  Widget _buildBasicInfoTab() {
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(DnDTheme.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionTitle('Charakter-Informationen', Icons.person),
                const SizedBox(height: DnDTheme.md),
                _buildCharacterCard(),
                const SizedBox(height: DnDTheme.xl),
                _buildSectionTitle('Klasse & Rasse', Icons.category),
                const SizedBox(height: DnDTheme.md),
                _buildClassRaceCard(),
                const SizedBox(height: DnDTheme.xl),
                _buildSectionTitle('Kampfwerte', Icons.security),
                const SizedBox(height: DnDTheme.md),
                _buildCombatStatsCard(),
                const SizedBox(height: DnDTheme.xl),
                _buildSectionTitle('Fertigkeiten', Icons.build),
                const SizedBox(height: DnDTheme.md),
                _buildSkillsCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAttributesTab() {
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Attributspunkte', Icons.fitness_center),
              const SizedBox(height: 8),
              _buildAbilityGrid(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDnDDetailsTab() {
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(DnDTheme.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('D&D Grunddaten', Icons.category),
              const SizedBox(height: DnDTheme.md),
              _buildDnDBasicCard(),
              const SizedBox(height: DnDTheme.xl),
              _buildSectionTitle('Erweiterte Informationen', Icons.psychology),
              const SizedBox(height: DnDTheme.md),
              _buildDnDAdvancedCard(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInventoryTab() {
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.isEdit) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(DnDTheme.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: DnDTheme.lg),
                  Text(
                    'Inventar-Verwaltung',
                    style: DnDTheme.headline2.copyWith(
                      color: DnDTheme.ancientGold,
                    ),
                  ),
                  const SizedBox(height: DnDTheme.sm),
                  Text(
                    'Speichere den Charakter zuerst,\nmoechtest du Gegenstaende hinzufuegen kannst.',
                    style: DnDTheme.bodyText1.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(DnDTheme.lg),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addItemFromLibrary,
                  icon: const Icon(Icons.add),
                  label: const Text('Gegenstand aus Bibliothek hinzufuegen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DnDTheme.arcaneBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: DnDTheme.lg,
                      vertical: DnDTheme.md,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: viewModel.inventory.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(DnDTheme.xl),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 80,
                              color: DnDTheme.mysticalPurple.withValues(alpha: 0.4),
                            ),
                            const SizedBox(height: DnDTheme.lg),
                            Text(
                              'Inventar ist leer',
                              style: DnDTheme.bodyText1.copyWith(
                                color: Colors.white60,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(DnDTheme.md),
                      itemCount: viewModel.inventory.length,
                      itemBuilder: (context, index) {
                        final displayItem = viewModel.inventory[index];
                        return _buildInventoryItemCard(displayItem);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================================

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: DnDTheme.ancientGold,
          size: 22,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard() {
    return FormSectionWidget(
      title: 'Charakter-Informationen',
      icon: Icons.person,
      backgroundColor: DnDTheme.slateGrey,
      borderRadius: DnDTheme.radiusMedium,
      children: [
        FormFieldWidget(
          label: 'Name des Charakters',
          value: _viewModel.name,
          onChanged: (value) => _viewModel.updateName(value),
          validator: _viewModel.validateName,
          icon: Icons.person,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          label: 'Name des Spielers',
          value: _viewModel.playerName,
          onChanged: (value) => _viewModel.updatePlayerName(value),
          validator: _viewModel.validatePlayerName,
          icon: Icons.person_outline,
        ),
      ],
    );
  }

  Widget _buildClassRaceCard() {
    return FormSectionWidget(
      title: 'Klasse & Rasse',
      icon: Icons.category,
      backgroundColor: DnDTheme.slateGrey,
      borderRadius: DnDTheme.radiusMedium,
      children: [
        DropdownFormFieldWidget<DndClass>(
          label: 'Klasse',
          value: _viewModel.selectedClass,
          items: allDndClasses,
          onChanged: (value) => _viewModel.updateClass(value),
          validator: _viewModel.validateClass,
          icon: Icons.shield,
          itemLabelBuilder: (dndClass) => dndClass.name,
        ),
        const SizedBox(height: 16),
        DropdownFormFieldWidget<DndRace>(
          label: 'Rasse',
          value: _viewModel.selectedRace,
          items: allDndRaces,
          onChanged: (value) => _viewModel.updateRace(value),
          validator: _viewModel.validateRace,
          icon: Icons.public,
          itemLabelBuilder: (dndRace) => dndRace.name,
        ),
      ],
    );
  }

  Widget _buildCombatStatsCard() {
    return FormSectionWidget(
      title: 'Kampfwerte',
      icon: Icons.security,
      backgroundColor: DnDTheme.slateGrey,
      borderRadius: DnDTheme.radiusMedium,
      children: [
        Row(
          children: [
            Expanded(
              child: FormFieldWidget(
                label: 'Stufe',
                value: _viewModel.level.toString(),
                onChanged: (value) => _viewModel.updateLevel(int.tryParse(value) ?? 1),
                validator: _viewModel.validateNumber,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                icon: Icons.star,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormFieldWidget(
                label: 'Max. HP',
                value: _viewModel.maxHp.toString(),
                onChanged: (value) => _viewModel.updateMaxHp(int.tryParse(value) ?? 10),
                validator: _viewModel.validateNumber,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                icon: Icons.favorite,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FormFieldWidget(
                label: 'Ruestungsklasse',
                value: _viewModel.armorClass.toString(),
                onChanged: (value) => _viewModel.updateArmorClass(int.tryParse(value) ?? 10),
                validator: _viewModel.validateNumber,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                icon: Icons.security,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DnDTheme.stoneGrey,
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.flash_on,
                          color: DnDTheme.ancientGold,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Initiative-Bonus',
                          style: DnDTheme.bodyText1.copyWith(
                            color: DnDTheme.ancientGold,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '+${_viewModel.initiativeBonus}',
                      style: DnDTheme.headline2.copyWith(
                        color: DnDTheme.ancientGold,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DnDTheme.stoneGrey,
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: DnDTheme.ancientGold,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Währung',
                    style: DnDTheme.headline3.copyWith(
                      color: DnDTheme.ancientGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CurrencyWidget(
                gold: _viewModel.gold,
                silver: _viewModel.silver,
                copper: _viewModel.copper,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAbilityGrid() {
    return AbilityScoreGrid(
      strength: _viewModel.strength,
      dexterity: _viewModel.dexterity,
      constitution: _viewModel.constitution,
      intelligence: _viewModel.intelligence,
      wisdom: _viewModel.wisdom,
      charisma: _viewModel.charisma,
      onStrengthChanged: (value) => _viewModel.updateStrength(value),
      onDexterityChanged: (value) => _viewModel.updateDexterity(value),
      onConstitutionChanged: (value) => _viewModel.updateConstitution(value),
      onIntelligenceChanged: (value) => _viewModel.updateIntelligence(value),
      onWisdomChanged: (value) => _viewModel.updateWisdom(value),
      onCharismaChanged: (value) => _viewModel.updateCharisma(value),
    );
  }

  Widget _buildAbilityScoreCard(
    String name,
    int value,
    IconData icon,
    Color color, {
    required Function(int) updateAbility,
  }) {
    final modifierString = getModifierString(value);
    
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: DnDTheme.sm),
          Text(
            name,
            style: DnDTheme.bodyText1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DnDTheme.md),
          Container(
            width: 60,
            height: 50,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: DnDTheme.stoneGrey,
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              border: Border.all(
                color: DnDTheme.ancientGold,
                width: 2,
              ),
            ),
            child: TextFormField(
              initialValue: value.toString(),
              textAlign: TextAlign.center,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: DnDTheme.headline2.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
              onChanged: (newValue) {
                final newValueInt = int.tryParse(newValue);
                if (newValueInt != null && newValueInt >= _minAbilityScore && newValueInt <= _maxAbilityScore) {
                  updateAbility(newValueInt);
                }
              },
            ),
          ),
          const SizedBox(height: DnDTheme.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Modifikator: ',
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white60,
                ),
              ),
              Text(
                modifierString,
                style: DnDTheme.bodyText1.copyWith(
                  color: DnDTheme.ancientGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsCard() {
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        Map<Ability, List<DndSkill>> skillsByAbility = {
          Ability.strength: allDndSkills.where((s) => s.ability == Ability.strength).toList(),
          Ability.dexterity: allDndSkills.where((s) => s.ability == Ability.dexterity).toList(),
          Ability.intelligence: allDndSkills.where((s) => s.ability == Ability.intelligence).toList(),
          Ability.wisdom: allDndSkills.where((s) => s.ability == Ability.wisdom).toList(),
          Ability.charisma: allDndSkills.where((s) => s.ability == Ability.charisma).toList(),
        };

        Map<String, String> skillBonuses = {};
        for (var skill in allDndSkills) {
          skillBonuses[skill.name] = viewModel.getSkillBonusString(skill);
        }

        return FormSectionWidget(
          title: 'Fertigkeiten',
          icon: Icons.build,
          backgroundColor: DnDTheme.slateGrey,
          borderRadius: DnDTheme.radiusMedium,
          children: [
            SkillSelectionWithSearch(
              skillsByAbility: skillsByAbility,
              skillBonuses: skillBonuses,
              proficientSkills: viewModel.proficientSkills,
              onSkillToggle: (skillName) => viewModel.toggleSkillProficiency(skillName),
              searchQuery: _skillSearchQuery,
              onSearchChanged: (query) {
                _debounce?.cancel();
                _debounce = Timer(_debounceDelay, () {
                  if (mounted) {
                    setState(() {
                      _skillSearchQuery = query.toLowerCase();
                    });
                  }
                });
              },
            ),
          ],
        );
      },
    );
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDelay, () {
      if (mounted) {
        setState(() {
          _skillSearchQuery = query.toLowerCase();
        });
      }
    });
  }

  IconData _getAbilityIcon(Ability ability) {
    switch (ability) {
      case Ability.strength:
        return Icons.fitness_center;
      case Ability.dexterity:
        return Icons.flash_on;
      case Ability.constitution:
        return Icons.favorite;
      case Ability.intelligence:
        return Icons.school;
      case Ability.wisdom:
        return Icons.psychology;
      case Ability.charisma:
        return Icons.people;
    }
  }

  String _getAbilityName(Ability ability) {
    switch (ability) {
      case Ability.strength:
        return 'Staerke';
      case Ability.dexterity:
        return 'Geschicklichkeit';
      case Ability.constitution:
        return 'Konstitution';
      case Ability.intelligence:
        return 'Intelligenz';
      case Ability.wisdom:
        return 'Weisheit';
      case Ability.charisma:
        return 'Charisma';
    }
  }

  Widget _buildDnDBasicCard() {
    return FormSectionWidget(
      title: 'D&D Grunddaten',
      icon: Icons.category,
      backgroundColor: DnDTheme.slateGrey,
      borderRadius: DnDTheme.radiusMedium,
      children: [
        Row(
          children: [
            Expanded(
              child: FormFieldWidget(
                label: 'Groesse',
                value: _viewModel.size,
                onChanged: (value) => _viewModel.updateSize(value),
                icon: Icons.straighten,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormFieldWidget(
                label: 'Typ',
                value: _viewModel.type,
                onChanged: (value) => _viewModel.updateType(value),
                icon: Icons.category,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: FormFieldWidget(
                label: 'Subtyp',
                value: _viewModel.subtype ?? '',
                onChanged: (value) => _viewModel.updateSubtype(value.isEmpty ? null : value),
                icon: Icons.layers,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FormFieldWidget(
                label: 'Ausrichtung',
                value: _viewModel.alignment,
                onChanged: (value) => _viewModel.updateAlignment(value),
                icon: Icons.compass_calibration,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDnDAdvancedCard() {
    return FormSectionWidget(
      title: 'Erweiterte Informationen',
      icon: Icons.psychology,
      backgroundColor: DnDTheme.slateGrey,
      borderRadius: DnDTheme.radiusMedium,
      children: [
        FormFieldWidget(
          label: 'Beschreibung',
          value: _viewModel.description,
          onChanged: (value) => _viewModel.updateDescription(value),
          icon: Icons.description,
          maxLines: 4,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          label: 'Spezielle Faehigkeiten',
          value: _viewModel.specialAbilities ?? '',
          onChanged: (value) => _viewModel.updateSpecialAbilities(value.isEmpty ? null : value),
          icon: Icons.auto_awesome,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        FormFieldWidget(
          label: 'Angriffe',
          value: _viewModel.attacks,
          onChanged: (value) => _viewModel.updateAttacks(value),
          icon: Icons.gavel,
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildInventoryItemCard(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;
    
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: ListTile(
        leading: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DnDTheme.arcaneBlue,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.inventory, color: Colors.white, size: 24),
        ),
        title: Text(
          item.name,
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          item.description.isNotEmpty 
              ? item.description 
              : '${item.itemType.name} • ${item.weight} Pfund',
          style: DnDTheme.bodyText2.copyWith(
            color: Colors.white60,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (invItem.quantity > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DnDTheme.md,
                  vertical: DnDTheme.xs,
                ),
                decoration: BoxDecoration(
                  color: DnDTheme.ancientGold,
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                ),
                child: Text(
                  'x${invItem.quantity}',
                  style: DnDTheme.bodyText2.copyWith(
                    color: DnDTheme.dungeonBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: DnDTheme.sm),
            ],
            IconButton(
              icon: const Icon(Icons.delete, color: DnDTheme.errorRed),
              onPressed: () => _showDeleteItemDialog(displayItem),
              tooltip: 'Loeschen',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================================

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged, {
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: TextFormField(
        key: ValueKey<String>('$_isInitialized-$label'),
        initialValue: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: DnDTheme.bodyText2.copyWith(
            color: DnDTheme.ancientGold,
          ),
          prefixIcon: icon != null ? Icon(icon, color: DnDTheme.ancientGold) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(DnDTheme.md),
        ),
        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildMultilineField(
    String label,
    String value,
    Function(String) onChanged, {
    IconData? icon,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: TextFormField(
        key: ValueKey<String>('$_isInitialized-$label'),
        initialValue: value,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: DnDTheme.bodyText2.copyWith(
            color: DnDTheme.ancientGold,
          ),
          prefixIcon: icon != null ? Icon(icon, color: DnDTheme.ancientGold) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(DnDTheme.md),
        ),
        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    String value,
    Function(String) onChanged, {
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: TextFormField(
        initialValue: value,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          labelText: label,
          labelStyle: DnDTheme.bodyText2.copyWith(
            color: DnDTheme.ancientGold,
          ),
          prefixIcon: icon != null ? Icon(icon, color: DnDTheme.ancientGold) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(DnDTheme.md),
        ),
        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildDropdownField<T>(
    String label,
    T? value,
    List<T> items,
    Function(T?) onChanged, {
    String? Function(T?)? validator,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: DropdownButtonFormField<T>(
        value: value,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: DnDTheme.bodyText2.copyWith(
            color: DnDTheme.ancientGold,
          ),
          prefixIcon: icon != null ? Icon(icon, color: DnDTheme.ancientGold) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(DnDTheme.md),
        ),
        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
        items: items.map((item) {
          String displayName = '';
          
          if (item is DndClass) {
            displayName = item.name;
          } else if (item is DndRace) {
            displayName = item.name;
          } else {
            displayName = item.toString();
          }
          
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              displayName,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  // ============================================================================

  Widget _buildFloatingActionButton() {
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isSaving) {
          return FloatingActionButton(
            onPressed: null,
            backgroundColor: DnDTheme.successGreen,
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 3,
            ),
          );
        }

        return FloatingActionButton.extended(
          onPressed: _saveCharacter,
          backgroundColor: DnDTheme.successGreen,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.save),
          label: const Text('Speichern'),
        );
      },
    );
  }

  // ============================================================================

  Future<void> _saveCharacter() async {
    // Keyboard dismissen
    FocusScope.of(context).unfocus();
    
    // Sammle alle Validierungsfehler
    final errors = <String>[];
    
    // Prüfe Name des Charakters
    if (_viewModel.name.isEmpty) {
      errors.add('Name des Charakters');
    }
    
    // Prüfe Name des Spielers
    if (_viewModel.playerName.isEmpty) {
      errors.add('Name des Spielers');
    }
    
    // Prüfe Klasse
    if (_viewModel.selectedClass == null) {
      errors.add('Klasse');
    }
    
    // Prüfe Rasse
    if (_viewModel.selectedRace == null) {
      errors.add('Rasse');
    }
    
    // Prüfe Stufe
    if (_viewModel.level < 1) {
      errors.add('Stufe (muss mindestens 1 sein)');
    }
    
    // Prüfe Max. HP
    if (_viewModel.maxHp < 1) {
      errors.add('Max. HP (muss mindestens 1 sein)');
    }
    
    // Prüfe Rüstungsklasse
    if (_viewModel.armorClass < 1) {
      errors.add('Rüstungsklasse (muss mindestens 1 sein)');
    }
    
    // Zeige Fehler an, wenn welche vorhanden sind
    if (errors.isNotEmpty) {
      final errorMessage = 'Bitte folgende Pflichtfelder ausfüllen:\n\n${errors.map((e) => '• $e').join('\n')}';
      if (mounted) {
        SnackBarHelper.showError(context, errorMessage);
      }
      return;
    }

    try {
      await _viewModel.saveCharacter();
      
      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          _viewModel.isEdit 
              ? 'Charakter erfolgreich aktualisiert'
              : 'Neuer Charakter erstellt',
        );
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Speichern: $e');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_viewModel.isEdit) {
      return true;
    }
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Ungespeicherte Aenderungen',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Text(
          'Moechtest du wirklich ohne Speichern gehen?',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );
    
    return shouldPop ?? false;
  }

  Future<void> _addItemFromLibrary() async {
    if (_viewModel.pcToEdit == null) {
      SnackBarHelper.showError(
        context,
        'Bitte speichere den Charakter zuerst, bevor du Gegenstaende hinzufuegst.'
      );
      return;
    }

    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => AddItemFromLibraryScreen(
            characterId: _viewModel.pcToEdit!.id,
          ),
        ),
      );
      if (mounted && _viewModel.pcToEdit != null) {
        await _viewModel.initialize(widget.campaignId, _viewModel.pcToEdit);
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  void _showDeleteItemDialog(DisplayInventoryItem displayItem) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: DnDTheme.stoneGrey,
          title: Text(
            '${displayItem.item.name} loeschen',
            style: DnDTheme.headline2.copyWith(
              color: DnDTheme.ancientGold,
            ),
          ),
          content: Text(
            'Moechtest du "${displayItem.item.name}" wirklich loeschen?',
            style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Abbrechen',
                style: DnDTheme.bodyText1.copyWith(
                  color: DnDTheme.mysticalPurple,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await Future.delayed(const Duration(milliseconds: 100));
                if (!mounted) return;
                try {
                  await _viewModel.removeInventoryItem(displayItem.inventoryItem.id);
                  if (mounted) {
                    SnackBarHelper.showSuccess(context, '${displayItem.item.name} geloescht');
                  }
                } catch (e) {
                  if (mounted) {
                    SnackBarHelper.showError(context, 'Fehler beim Loeschen: $e');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.errorRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Loeschen'),
            ),
          ],
        );
      },
    );
  }
}
