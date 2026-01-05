import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../game_data/dnd_logic.dart';
import '../game_data/dnd_models.dart';
import '../game_data/game_data.dart';
import '../models/player_character.dart';
import '../theme/dnd_theme.dart';
import '../viewmodels/edit_pc_viewmodel.dart';
import '../widgets/ui_components/feedback/snackbar_helper.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/player_character_model_repository.dart';

import 'add_item_from_library_screen.dart';

/// Enhanced Edit PC Screen mit Provider-Pattern und modernem, übersichtlichem D&D Design
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
  late EditPCViewModel _viewModel;
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isInitialized = false;
  String _skillSearchQuery = '';

  @override
  void initState() {
    super.initState();
    _viewModel = EditPCViewModel(
      pcRepository: PlayerCharacterModelRepository(DatabaseConnection.instance),
    );
    _tabController = TabController(length: 4, vsync: this);
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
      child: Scaffold(
        backgroundColor: DnDTheme.dungeonBlack,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(),
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
      actions: [
        Container(
          margin: const EdgeInsets.only(right: DnDTheme.sm),
          decoration: BoxDecoration(
            color: DnDTheme.successGreen,
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          ),
          child: IconButton(
            icon: const Icon(Icons.save),
            tooltip: 'Speichern',
            onPressed: _saveCharacter,
          ),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: DnDTheme.ancientGold,
        labelColor: DnDTheme.ancientGold,
        unselectedLabelColor: Colors.white70,
        labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        tabs: const [
          Tab(icon: Icon(Icons.person), text: 'Stammdaten'),
          Tab(icon: Icon(Icons.fitness_center), text: 'Attribute'),
          Tab(icon: Icon(Icons.category), text: 'D&D Details'),
          Tab(icon: Icon(Icons.inventory), text: 'Inventar'),
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
          padding: const EdgeInsets.all(DnDTheme.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Attributspunkte', Icons.fitness_center),
              const SizedBox(height: DnDTheme.md),
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
                    'Speichere den Charakter zuerst,\numit du Gegenstände hinzufügen kannst.',
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
                  label: const Text('Gegenstand aus Bibliothek hinzufügen'),
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
          size: 28,
        ),
        const SizedBox(width: DnDTheme.sm),
        Text(
          title,
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildCharacterCard() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: Column(
        children: [
          _buildTextField(
            'Name des Charakters',
            _viewModel.name,
            (value) => _viewModel.updateName(value),
            validator: _viewModel.validateName,
            icon: Icons.person,
          ),
          const SizedBox(height: DnDTheme.lg),
          _buildTextField(
            'Name des Spielers',
            _viewModel.playerName,
            (value) => _viewModel.updatePlayerName(value),
            validator: _viewModel.validatePlayerName,
            icon: Icons.person_outline,
          ),
        ],
      ),
    );
  }

  Widget _buildClassRaceCard() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: Column(
        children: [
          _buildDropdownField<DndClass>(
            'Klasse',
            _viewModel.selectedClass,
            allDndClasses,
            (value) => _viewModel.updateClass(value),
            validator: _viewModel.validateClass,
            icon: Icons.shield,
          ),
          const SizedBox(height: DnDTheme.lg),
          _buildDropdownField<DndRace>(
            'Rasse',
            _viewModel.selectedRace,
            allDndRaces,
            (value) => _viewModel.updateRace(value),
            validator: _viewModel.validateRace,
            icon: Icons.public,
          ),
        ],
      ),
    );
  }

  Widget _buildCombatStatsCard() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Kampfwerte',
            style: DnDTheme.headline3.copyWith(
              color: DnDTheme.ancientGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DnDTheme.lg),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  'Stufe',
                  _viewModel.level.toString(),
                  (value) => _viewModel.updateLevel(int.tryParse(value) ?? 1),
                  validator: _viewModel.validateNumber,
                  icon: Icons.star,
                ),
              ),
              const SizedBox(width: DnDTheme.lg),
              Expanded(
                child: _buildNumberField(
                  'Max. HP',
                  _viewModel.maxHp.toString(),
                  (value) => _viewModel.updateMaxHp(int.tryParse(value) ?? 10),
                  validator: _viewModel.validateNumber,
                  icon: Icons.favorite,
                ),
              ),
            ],
          ),
          const SizedBox(height: DnDTheme.lg),
          Row(
            children: [
              Expanded(
                child: _buildNumberField(
                  'Rüstungsklasse',
                  _viewModel.armorClass.toString(),
                  (value) => _viewModel.updateArmorClass(int.tryParse(value) ?? 10),
                  validator: _viewModel.validateNumber,
                  icon: Icons.security,
                ),
              ),
              const SizedBox(width: DnDTheme.lg),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(DnDTheme.lg),
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
                          const SizedBox(width: DnDTheme.sm),
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
          const SizedBox(height: DnDTheme.xl),
          Text(
            'Währung',
            style: DnDTheme.headline3.copyWith(
              color: DnDTheme.ancientGold,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: DnDTheme.lg),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Gold',
                  _viewModel.gold.toString(),
                  (value) => _viewModel.updateGold(double.tryParse(value) ?? 0.0),
                  icon: Icons.monetization_on,
                ),
              ),
              const SizedBox(width: DnDTheme.lg),
              Expanded(
                child: _buildTextField(
                  'Silber',
                  _viewModel.silver.toString(),
                  (value) => _viewModel.updateSilver(double.tryParse(value) ?? 0.0),
                  icon: Icons.monetization_on,
                ),
              ),
              const SizedBox(width: DnDTheme.lg),
              Expanded(
                child: _buildTextField(
                  'Kupfer',
                  _viewModel.copper.toString(),
                  (value) => _viewModel.updateCopper(double.tryParse(value) ?? 0.0),
                  icon: Icons.monetization_on,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAbilityGrid() {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: DnDTheme.md,
      crossAxisSpacing: DnDTheme.md,
      children: [
        _buildAbilityScoreCard(
          'Stärke',
          _viewModel.strength,
          Icons.fitness_center,
          Colors.red,
          updateAbility: (value) => _viewModel.updateStrength(value),
        ),
        _buildAbilityScoreCard(
          'Geschicklichkeit',
          _viewModel.dexterity,
          Icons.flash_on,
          Colors.green,
          updateAbility: (value) => _viewModel.updateDexterity(value),
        ),
        _buildAbilityScoreCard(
          'Konstitution',
          _viewModel.constitution,
          Icons.favorite,
          Colors.orange,
          updateAbility: (value) => _viewModel.updateConstitution(value),
        ),
        _buildAbilityScoreCard(
          'Intelligenz',
          _viewModel.intelligence,
          Icons.school,
          Colors.blue,
          updateAbility: (value) => _viewModel.updateIntelligence(value),
        ),
        _buildAbilityScoreCard(
          'Weisheit',
          _viewModel.wisdom,
          Icons.psychology,
          Colors.purple,
          updateAbility: (value) => _viewModel.updateWisdom(value),
        ),
        _buildAbilityScoreCard(
          'Charisma',
          _viewModel.charisma,
          Icons.people,
          Colors.pink,
          updateAbility: (value) => _viewModel.updateCharisma(value),
        ),
      ],
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
                if (newValueInt != null && newValueInt >= 1 && newValueInt <= 20) {
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
        Container searchField = Container(
          padding: const EdgeInsets.all(DnDTheme.md),
          decoration: BoxDecoration(
            color: DnDTheme.slateGrey,
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          ),
          child: TextField(
            onChanged: (value) {
              setState(() {
                _skillSearchQuery = value.toLowerCase();
              });
            },
            decoration: InputDecoration(
              hintText: 'Fertigkeiten durchsuchen...',
              hintStyle: DnDTheme.bodyText2.copyWith(
                color: Colors.white60,
              ),
              prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(DnDTheme.md),
            ),
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          ),
        );

        Map<Ability, List<DndSkill>> skillsByAbility = {
          Ability.strength: allDndSkills.where((s) => s.ability == Ability.strength).toList(),
          Ability.dexterity: allDndSkills.where((s) => s.ability == Ability.dexterity).toList(),
          Ability.intelligence: allDndSkills.where((s) => s.ability == Ability.intelligence).toList(),
          Ability.wisdom: allDndSkills.where((s) => s.ability == Ability.wisdom).toList(),
          Ability.charisma: allDndSkills.where((s) => s.ability == Ability.charisma).toList(),
        };

        List<MapEntry<Ability, List<DndSkill>>> filteredSections = skillsByAbility.entries
            .where((entry) {
              if (_skillSearchQuery.isEmpty) return true;
              return entry.value.any((skill) =>
                  skill.name.toLowerCase().contains(_skillSearchQuery));
            })
            .toList();

        return Container(
          padding: const EdgeInsets.all(DnDTheme.lg),
          decoration: BoxDecoration(
            color: DnDTheme.slateGrey,
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          ),
          child: Column(
            children: [
              searchField,
              const SizedBox(height: DnDTheme.lg),
              ...filteredSections.map((entry) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DnDTheme.md,
                        vertical: DnDTheme.sm,
                      ),
                      decoration: BoxDecoration(
                        color: DnDTheme.stoneGrey,
                        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getAbilityIcon(entry.key),
                            color: DnDTheme.ancientGold,
                            size: 20,
                          ),
                          const SizedBox(width: DnDTheme.sm),
                          Text(
                            _getAbilityName(entry.key),
                            style: DnDTheme.bodyText1.copyWith(
                              color: DnDTheme.ancientGold,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: DnDTheme.sm),
                    ...entry.value.map((skill) {
                      final bonus = _viewModel.getSkillBonusString(skill);
                      final isProficient = _viewModel.proficientSkills.contains(skill.name);
                      final matchesSearch = _skillSearchQuery.isEmpty ||
                          skill.name.toLowerCase().contains(_skillSearchQuery);

                      if (!matchesSearch) return const SizedBox.shrink();

                      return Container(
                        margin: const EdgeInsets.only(bottom: DnDTheme.xs),
                        decoration: BoxDecoration(
                          color: isProficient 
                              ? DnDTheme.successGreen.withValues(alpha: 0.2)
                              : DnDTheme.stoneGrey,
                          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isProficient ? DnDTheme.successGreen : DnDTheme.slateGrey,
                              shape: BoxShape.circle,
                            ),
                            child: isProficient
                                ? Icon(Icons.check, color: Colors.white, size: 20)
                                : Icon(Icons.check_box_outline_blank, color: Colors.white60, size: 20),
                          ),
                          title: Text(
                            skill.name,
                            style: DnDTheme.bodyText1.copyWith(
                              color: Colors.white,
                              fontWeight: isProficient ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: DnDTheme.sm,
                              vertical: DnDTheme.xs,
                            ),
                            decoration: BoxDecoration(
                              color: DnDTheme.ancientGold,
                              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                            ),
                            child: Text(
                              bonus,
                              style: DnDTheme.bodyText2.copyWith(
                                color: DnDTheme.dungeonBlack,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          onTap: () => _viewModel.toggleSkillProficiency(skill.name),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: DnDTheme.md),
                  ],
                );
              }).toList(),
            ],
          ),
        );
      },
    );
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
        return 'Stärke';
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
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Größe',
                  _viewModel.size,
                  (value) => _viewModel.updateSize(value),
                  icon: Icons.straighten,
                ),
              ),
              const SizedBox(width: DnDTheme.lg),
              Expanded(
                child: _buildTextField(
                  'Typ',
                  _viewModel.type,
                  (value) => _viewModel.updateType(value),
                  icon: Icons.category,
                ),
              ),
            ],
          ),
          const SizedBox(height: DnDTheme.lg),
          Row(
            children: [
              Expanded(
                child: _buildTextField(
                  'Subtyp',
                  _viewModel.subtype ?? '',
                  (value) => _viewModel.updateSubtype(value.isEmpty ? null : value),
                  icon: Icons.layers,
                ),
              ),
              const SizedBox(width: DnDTheme.lg),
              Expanded(
                child: _buildTextField(
                  'Ausrichtung',
                  _viewModel.alignment,
                  (value) => _viewModel.updateAlignment(value),
                  icon: Icons.compass_calibration,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDnDAdvancedCard() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: Column(
        children: [
          _buildMultilineField(
            'Beschreibung',
            _viewModel.description,
            (value) => _viewModel.updateDescription(value),
            icon: Icons.description,
            maxLines: 4,
          ),
          const SizedBox(height: DnDTheme.lg),
          _buildMultilineField(
            'Spezielle Fähigkeiten',
            _viewModel.specialAbilities ?? '',
            (value) => _viewModel.updateSpecialAbilities(value.isEmpty ? null : value),
            icon: Icons.auto_awesome,
            maxLines: 3,
          ),
          const SizedBox(height: DnDTheme.lg),
          _buildMultilineField(
            'Angriffe',
            _viewModel.attacks,
            (value) => _viewModel.updateAttacks(value),
            icon: Icons.gavel,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryItemCard(dynamic displayItem) {
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
          'Gegenstand',
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Beschreibung...',
          style: DnDTheme.bodyText2.copyWith(
            color: Colors.white60,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                'x1',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.dungeonBlack,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: DnDTheme.sm),
            IconButton(
              icon: const Icon(Icons.delete, color: DnDTheme.errorRed),
              onPressed: () => _showDeleteItemDialog(displayItem),
              tooltip: 'Löschen',
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
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Bitte fülle alle Pflichtfelder aus');
      }
      return;
    }

    try {
      await _viewModel.saveCharacter();
      
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (mounted) {
        SnackBarHelper.showSuccess(
          context,
          _viewModel.isEdit 
              ? 'Charakter erfolgreich aktualisiert'
              : 'Neuer Charakter erstellt',
        );
        await Future.delayed(const Duration(milliseconds: 500));
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

  Future<void> _addItemFromLibrary() async {
    if (_viewModel.pcToEdit == null) {
      SnackBarHelper.showError(
        context,
        'Bitte speichere den Charakter zuerst, bevor du Gegenstände hinzufügst.'
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

  void _showDeleteItemDialog(dynamic displayItem) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Gegenstand löschen',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Text(
          'Möchtest du diesen Gegenstand wirklich löschen?',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                if (mounted) {
                  SnackBarHelper.showSuccess(context, 'Gegenstand gelöscht');
                }
              } catch (e) {
                if (mounted) {
                  SnackBarHelper.showError(context, 'Fehler beim Löschen: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
