import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/player_character.dart';
import '../viewmodels/edit_pc_viewmodel.dart';
import '../theme/dnd_theme.dart';
import '../game_data/game_data.dart';
import '../game_data/dnd_logic.dart';
import '../game_data/dnd_models.dart';
import 'add_item_from_library_screen.dart';

/// Enhanced Edit PC Screen mit Provider-Pattern und modernem D&D Design
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

  @override
  void initState() {
    super.initState();
    _viewModel = EditPCViewModel();
    _tabController = TabController(length: 3, vsync: this);
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Initialisieren: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditPCViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: DnDTheme.dungeonBlack,
        appBar: AppBar(
          title: Text(
            _viewModel.isEdit ? 'Held bearbeiten' : 'Neuen Held erstellen',
            style: DnDTheme.headline2.copyWith(
              color: DnDTheme.ancientGold,
            ),
          ),
          backgroundColor: DnDTheme.stoneGrey,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.only(right: DnDTheme.sm),
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.successGreen,
                width: 2,
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
            tabs: const [
              Tab(icon: Icon(Icons.person), text: 'Stammdaten'),
              Tab(icon: Icon(Icons.fitness_center), text: 'Attribute'),
              Tab(icon: Icon(Icons.inventory), text: 'Inventar'),
            ],
          ),
        ),
        body: Consumer<EditPCViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.error != null) {
              return _buildErrorWidget(viewModel.error!);
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _buildBasicInfoTab(),
                _buildAttributesTab(),
                _buildInventoryTab(),
              ],
            );
          },
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(DnDTheme.lg),
          decoration: DnDTheme.getDungeonWallDecoration(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: DnDTheme.errorRed,
                size: 48,
              ),
              const SizedBox(height: DnDTheme.md),
              Text(
                'Fehler',
                style: DnDTheme.headline3.copyWith(
                  color: DnDTheme.errorRed,
                ),
              ),
              const SizedBox(height: DnDTheme.sm),
              Text(
                error,
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: DnDTheme.md),
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
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(DnDTheme.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Character Info Section
                _buildSectionHeader('Charakter-Informationen', Icons.person),
                const SizedBox(height: DnDTheme.sm),
                _buildCharacterCard(),
                const SizedBox(height: DnDTheme.lg),

                // Class & Race Section
                _buildSectionHeader('Klasse & Rasse', Icons.category),
                const SizedBox(height: DnDTheme.sm),
                _buildClassRaceCard(),
                const SizedBox(height: DnDTheme.lg),

                // Combat Stats Section
                _buildSectionHeader('Kampfwerte', Icons.security),
                const SizedBox(height: DnDTheme.sm),
                _buildCombatStatsCard(),
                const SizedBox(height: DnDTheme.lg),

                // Skills Section
                _buildSectionHeader('Fertigkeiten', Icons.build),
                const SizedBox(height: DnDTheme.sm),
                _buildSkillsCard(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: DnDTheme.ancientGold,
            size: 24,
          ),
          const SizedBox(width: DnDTheme.sm),
          Text(
            title,
            style: DnDTheme.headline3.copyWith(
              color: DnDTheme.ancientGold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterCard() {
    return Container(
      decoration: DnDTheme.getDungeonWallDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.md),
        child: Column(
          children: [
            _buildTextField(
              'Name des Charakters',
              _viewModel.name,
              (value) => _viewModel.updateName(value),
              validator: _viewModel.validateName,
              icon: Icons.person,
            ),
            const SizedBox(height: DnDTheme.md),
            _buildTextField(
              'Name des Spielers',
              _viewModel.playerName,
              (value) => _viewModel.updatePlayerName(value),
              validator: _viewModel.validatePlayerName,
              icon: Icons.person_outline,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassRaceCard() {
    return Container(
      decoration: DnDTheme.getDungeonWallDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.md),
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
            const SizedBox(height: DnDTheme.md),
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
      ),
    );
  }

  Widget _buildCombatStatsCard() {
    return Container(
      decoration: DnDTheme.getDungeonWallDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.md),
        child: Column(
          children: [
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
                const SizedBox(width: DnDTheme.md),
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
            const SizedBox(height: DnDTheme.md),
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
                const SizedBox(width: DnDTheme.md),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(DnDTheme.md),
                    decoration: BoxDecoration(
                      gradient: DnDTheme.getMysticalGradient(
                        startColor: DnDTheme.slateGrey,
                        endColor: DnDTheme.stoneGrey,
                      ),
                      borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                      border: Border.all(
                        color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.flash_on,
                              color: DnDTheme.ancientGold,
                              size: 16,
                            ),
                            const SizedBox(width: DnDTheme.xs),
                            Text(
                              'Initiative-Bonus',
                              style: DnDTheme.bodyText2.copyWith(
                                color: DnDTheme.ancientGold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '+${_viewModel.initiativeBonus}',
                          style: DnDTheme.headline3.copyWith(
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
          ],
        ),
      ),
    );
  }

  Widget _buildSkillsCard() {
    return Container(
      decoration: DnDTheme.getDungeonWallDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.md),
        child: Column(
          children: allDndSkills.map((skill) {
            final bonus = _viewModel.getSkillBonusString(skill);
            final isProficient = _viewModel.proficientSkills.contains(skill.name);
            
            return Container(
              margin: const EdgeInsets.only(bottom: DnDTheme.sm),
              decoration: BoxDecoration(
                gradient: DnDTheme.getMysticalGradient(
                  startColor: DnDTheme.slateGrey,
                  endColor: DnDTheme.stoneGrey,
                ),
                borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                border: Border.all(
                  color: isProficient 
                      ? DnDTheme.successGreen.withValues(alpha: 0.5)
                      : DnDTheme.mysticalPurple.withValues(alpha: 0.3),
                ),
              ),
              child: ListTile(
                leading: Container(
                  decoration: BoxDecoration(
                    color: isProficient ? DnDTheme.successGreen : DnDTheme.slateGrey,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DnDTheme.ancientGold,
                      width: 2,
                    ),
                  ),
                  child: isProficient
                      ? Icon(Icons.check, color: Colors.white, size: 20)
                      : Icon(Icons.check_box_outline_blank, color: Colors.white70, size: 20),
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
        ),
      ),
    );
  }

  Widget _buildAttributesTab() {
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(DnDTheme.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionHeader('Attributspunkte', Icons.fitness_center),
              const SizedBox(height: DnDTheme.sm),
              ...[
                ('Stärke', viewModel.strength, Icons.fitness_center, Colors.red),
                ('Geschicklichkeit', viewModel.dexterity, Icons.flash_on, Colors.green),
                ('Konstitution', viewModel.constitution, Icons.favorite, Colors.orange),
                ('Intelligenz', viewModel.intelligence, Icons.school, Colors.blue),
                ('Weisheit', viewModel.wisdom, Icons.psychology, Colors.purple),
                ('Charisma', viewModel.charisma, Icons.people, Colors.pink),
              ].map((data) => _buildAbilityScoreCard(
                data.$1,
                data.$2,
                data.$3,
                data.$4,
              )).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAbilityScoreCard(String name, int value, IconData icon, Color color) {
    final modifierString = getModifierString(value);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      decoration: DnDTheme.getDungeonWallDecoration(),
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.md),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.8),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DnDTheme.ancientGold,
                  width: 2,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(width: DnDTheme.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: DnDTheme.bodyText1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        'Modifikator: ',
                        style: DnDTheme.bodyText2.copyWith(
                          color: Colors.white70,
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
            ),
            Container(
              width: 80,
              child: TextFormField(
                initialValue: value.toString(),
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                    borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                    borderSide: BorderSide(
                      color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                    borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                  ),
                  filled: true,
                  fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                ),
                style: DnDTheme.bodyText1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                onChanged: (newValue) {
                  final newValueInt = int.tryParse(newValue);
                  if (newValueInt != null && newValueInt >= 1 && newValueInt <= 20) {
                    switch (name) {
                      case 'Stärke':
                        _viewModel.updateStrength(newValueInt);
                        break;
                      case 'Geschicklichkeit':
                        _viewModel.updateDexterity(newValueInt);
                        break;
                      case 'Konstitution':
                        _viewModel.updateConstitution(newValueInt);
                        break;
                      case 'Intelligenz':
                        _viewModel.updateIntelligence(newValueInt);
                        break;
                      case 'Weisheit':
                        _viewModel.updateWisdom(newValueInt);
                        break;
                      case 'Charisma':
                        _viewModel.updateCharisma(newValueInt);
                        break;
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTab() {
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        if (!viewModel.isEdit) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(DnDTheme.lg),
              decoration: DnDTheme.getDungeonWallDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 64,
                    color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: DnDTheme.md),
                  Text(
                    'Inventar-Verwaltung',
                    style: DnDTheme.headline3.copyWith(
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
            // Add Item Button
            Padding(
              padding: const EdgeInsets.all(DnDTheme.md),
              child: Container(
                decoration: DnDTheme.getMysticalBorder(
                  borderColor: DnDTheme.arcaneBlue,
                  width: 2,
                ),
                child: ElevatedButton.icon(
                  onPressed: _addItemFromLibrary,
                  icon: const Icon(Icons.add),
                  label: const Text('Gegenstand aus Bibliothek hinzufügen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DnDTheme.arcaneBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(DnDTheme.md),
                  ),
                ),
              ),
            ),
            // Inventory List
            Expanded(
              child: viewModel.inventory.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(DnDTheme.lg),
                        decoration: DnDTheme.getDungeonWallDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: DnDTheme.md),
                            Text(
                              'Inventar ist leer',
                              style: DnDTheme.bodyText1.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(DnDTheme.sm),
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

  Widget _buildInventoryItemCard(dynamic displayItem) {
    // This is a simplified version - in a real implementation,
    // we'd need to properly type the DisplayInventoryItem
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.sm),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
        ),
      ),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: DnDTheme.arcaneBlue,
            shape: BoxShape.circle,
            border: Border.all(
              color: DnDTheme.ancientGold,
              width: 2,
            ),
          ),
          child: const Icon(Icons.inventory, color: Colors.white, size: 20),
        ),
        title: Text(
          'Gegenstand', // Placeholder
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          'Beschreibung...', // Placeholder
          style: DnDTheme.bodyText2.copyWith(
            color: Colors.white70,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DnDTheme.sm,
                vertical: DnDTheme.xs,
              ),
              decoration: BoxDecoration(
                color: DnDTheme.ancientGold,
                borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              ),
              child: Text(
                'x1', // Placeholder
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.dungeonBlack,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: DnDTheme.xs),
            Container(
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.errorRed,
                width: 2,
              ),
              child: IconButton(
                icon: const Icon(Icons.delete, color: DnDTheme.errorRed),
                onPressed: () => _showDeleteItemDialog(displayItem),
                tooltip: 'Löschen',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    String value,
    Function(String) onChanged, {
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
        ),
      ),
      child: TextFormField(
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

  Widget _buildNumberField(
    String label,
    String value,
    Function(String) onChanged, {
    String? Function(String?)? validator,
    IconData? icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
        ),
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
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
        ),
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
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              item.toString().split('.').last, // Get the enum name
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        validator: validator,
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isSaving) {
          return Container(
            decoration: DnDTheme.getMysticalBorder(
              borderColor: DnDTheme.ancientGold,
              width: 3,
            ),
            child: const FloatingActionButton(
              onPressed: null,
              backgroundColor: DnDTheme.successGreen,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
          );
        }

        return Container(
          decoration: DnDTheme.getMysticalBorder(
            borderColor: DnDTheme.successGreen,
            width: 3,
          ),
          child: FloatingActionButton.extended(
            onPressed: _saveCharacter,
            backgroundColor: DnDTheme.successGreen,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.save),
            label: const Text('Speichern'),
          ),
        );
      },
    );
  }

  Future<void> _saveCharacter() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bitte fülle alle Pflichtfelder aus'),
          backgroundColor: DnDTheme.errorRed,
        ),
      );
      return;
    }

    try {
      await _viewModel.saveCharacter();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _viewModel.isEdit 
                  ? 'Charakter erfolgreich aktualisiert'
                  : 'Neuer Charakter erstellt',
            ),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _addItemFromLibrary() async {
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (ctx) => AddItemFromLibraryScreen(
            ownerId: _viewModel.pcToEdit!.id,
          ),
        ),
      );
      // Reload inventory after returning
      if (mounted && _viewModel.pcToEdit != null) {
        await _viewModel.initialize(widget.campaignId, _viewModel.pcToEdit);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
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
          style: DnDTheme.headline3.copyWith(
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
                // Placeholder for delete functionality
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Gegenstand gelöscht'),
                      backgroundColor: DnDTheme.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Löschen: $e'),
                      backgroundColor: DnDTheme.errorRed,
                    ),
                  );
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
