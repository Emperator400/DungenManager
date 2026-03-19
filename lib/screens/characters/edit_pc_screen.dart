import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../game_data/dnd_models.dart';
import '../../game_data/dnd_logic.dart';
import '../../game_data/game_data.dart';
import '../../models/player_character.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/edit_pc_viewmodel.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/forms/form_field_widget.dart';
import '../../widgets/ui_components/stats/attributes_section_widget.dart';
import '../../widgets/ui_components/stats/ability_score_widget.dart';
import '../../widgets/ui_components/skills/skill_list_widget.dart';
import '../../widgets/ui_components/inventory/unified_character_inventory_widget.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/player_character_model_repository.dart';

import '../items/add_item_screen.dart';

/// Enhanced Edit PC Screen mit Provider-Pattern und modernem, uebersichtlichem D&D Design
class EditPCScreen extends StatefulWidget {
  final String campaignId;
  final PlayerCharacter? pcToEdit;

  const EditPCScreen({
    super.key,
    required this.campaignId,
    this.pcToEdit,
  });

  @override
  State<EditPCScreen> createState() => _EditPCScreenState();
}

class _EditPCScreenState extends State<EditPCScreen>
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
    // Zeige Charakternamen wenn vorhanden, sonst Standard-Titel
    final titleText = _viewModel.isEdit && _viewModel.name.isNotEmpty
        ? _viewModel.name
        : (_viewModel.isEdit ? 'Held bearbeiten' : 'Neuen Held erstellen');
    
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () async {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      title: Text(
        titleText,
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
          Tab(icon: Icon(Icons.inventory_2), text: ' Inventar & Ausrüstung'),
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
            _buildUnifiedInventoryTab(),
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
                const SizedBox(height: DnDTheme.xl),
                _buildSectionTitle('Rettungswürfe', Icons.shield),
                const SizedBox(height: DnDTheme.md),
                _buildSavingThrowsSection(viewModel),
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
              _buildAbilityGrid(),
            ],
          ),
        );
      },
    );
  }

  /// Baut die Rettungswürfe-Sektion
  Widget _buildSavingThrowsSection(EditPCViewModel viewModel) {
    return FormSectionWidget(
      title: 'Rettungswürfe',
      icon: Icons.shield,
      backgroundColor: DnDTheme.slateGrey,
      borderRadius: DnDTheme.radiusMedium,
      children: [
        Text(
          'Wähle die Rettungswürfe, in denen der Charakter proficient ist.',
          style: DnDTheme.bodyText2.copyWith(
            color: Colors.white70,
            fontStyle: FontStyle.italic,
          ),
        ),
        const SizedBox(height: DnDTheme.md),
        _buildSavingThrowRow(
          viewModel: viewModel,
          name: 'Stärke',
          abilityValue: viewModel.strength,
          abilityKey: 'strength',
          icon: Icons.fitness_center,
          color: Colors.red,
        ),
        _buildSavingThrowRow(
          viewModel: viewModel,
          name: 'Geschicklichkeit',
          abilityValue: viewModel.dexterity,
          abilityKey: 'dexterity',
          icon: Icons.directions_run,
          color: Colors.green,
        ),
        _buildSavingThrowRow(
          viewModel: viewModel,
          name: 'Konstitution',
          abilityValue: viewModel.constitution,
          abilityKey: 'constitution',
          icon: Icons.favorite,
          color: Colors.orange,
        ),
        _buildSavingThrowRow(
          viewModel: viewModel,
          name: 'Intelligenz',
          abilityValue: viewModel.intelligence,
          abilityKey: 'intelligence',
          icon: Icons.psychology,
          color: Colors.blue,
        ),
        _buildSavingThrowRow(
          viewModel: viewModel,
          name: 'Weisheit',
          abilityValue: viewModel.wisdom,
          abilityKey: 'wisdom',
          icon: Icons.visibility,
          color: Colors.purple,
        ),
        _buildSavingThrowRow(
          viewModel: viewModel,
          name: 'Charisma',
          abilityValue: viewModel.charisma,
          abilityKey: 'charisma',
          icon: Icons.star,
          color: DnDTheme.ancientGold,
        ),
      ],
    );
  }

  /// Baut eine einzelne Zeile für einen Rettungswurf
  Widget _buildSavingThrowRow({
    required EditPCViewModel viewModel,
    required String name,
    required int abilityValue,
    required String abilityKey,
    required IconData icon,
    required Color color,
  }) {
    final isProficient = viewModel.savingThrowProficiencies.contains(abilityKey);
    final modifier = getModifier(abilityValue);
    final totalBonus = modifier + (isProficient ? viewModel.proficiencyBonus : 0);
    final bonusString = totalBonus >= 0 ? '+$totalBonus' : totalBonus.toString();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () => viewModel.toggleSavingThrowProficiency(abilityKey),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isProficient 
                ? color.withValues(alpha: 0.15)
                : DnDTheme.stoneGrey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            border: Border.all(
              color: isProficient ? color : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isProficient ? color : Colors.white54,
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  style: DnDTheme.bodyText1.copyWith(
                    color: isProficient ? Colors.white : Colors.white70,
                    fontWeight: isProficient ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
              // Modifier anzeigen
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: DnDTheme.stoneGrey,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  bonusString,
                  style: DnDTheme.headline3.copyWith(
                    color: isProficient ? color : DnDTheme.ancientGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Checkbox
              Icon(
                isProficient ? Icons.check_box : Icons.check_box_outline_blank,
                color: isProficient ? color : Colors.white54,
                size: 24,
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildUnifiedInventoryTab() {
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
                    'Inventar & Ausrüstung',
                    style: DnDTheme.headline2.copyWith(
                      color: DnDTheme.ancientGold,
                    ),
                  ),
                  const SizedBox(height: DnDTheme.sm),
                  Text(
                    'Speichere den Charakter zuerst,\nbevor du Inventar und Ausrüstung verwalten kannst.',
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

        return UnifiedCharacterInventoryWidget(
          inventoryItems: viewModel.inventory,
          equipmentMap: viewModel.equipmentMap,
          gold: viewModel.gold.toInt(),
          silver: viewModel.silver?.toInt(),
          copper: viewModel.copper?.toInt(),
          onEquipItem: (slot, displayItem) async {
            try {
              await viewModel.equipItem(slot, displayItem);
              // Automatisch speichern nach dem Ausrüsten
              await _saveWithoutNavigation();
              if (mounted) {
                SnackBarHelper.showSuccess(context, '${displayItem.item.name} ausgerüstet und gespeichert');
              }
            } catch (e) {
              if (mounted) {
                SnackBarHelper.showError(context, e.toString());
              }
            }
          },
          onUnequipItem: (slot) async {
            try {
              await viewModel.unequipItem(slot);
              // Automatisch speichern nach dem Ablegen
              await _saveWithoutNavigation();
              if (mounted) {
                SnackBarHelper.showSuccess(context, 'Item abgelegt und gespeichert');
              }
            } catch (e) {
              if (mounted) {
                SnackBarHelper.showError(context, e.toString());
              }
            }
          },
          onAddItem: _addItemFromLibrary,
          onDeleteItem: (displayItem) async {
            await Future.delayed(const Duration(milliseconds: 100));
            if (!mounted) return;
            try {
              await _viewModel.removeInventoryItem(displayItem.inventoryItem.id);
              if (mounted) {
                SnackBarHelper.showSuccess(context, '${displayItem.item.name} gelöscht');
              }
            } catch (e) {
              if (mounted) {
                SnackBarHelper.showError(context, 'Fehler beim Löschen: $e');
              }
            }
          },
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
    return Consumer<EditPCViewModel>(
      builder: (context, viewModel, child) {
        // Berechne effektive AC
        final effectiveAc = viewModel.effectiveArmorClassSync;
        final hasEquipmentBonus = effectiveAc != viewModel.armorClass;
        
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
            // Proficiency Bonus (Übungsbonus)
            Row(
              children: [
                Expanded(
                  child: FormFieldWidget(
                    label: 'Übungsbonus',
                    value: _viewModel.hasProficiencyBonusOverride 
                        ? _viewModel.proficiencyBonus.toString()
                        : '',
                    onChanged: (value) {
                      final bonus = int.tryParse(value);
                      if (bonus != null && bonus > 0) {
                        _viewModel.updateProficiencyBonus(bonus);
                      } else if (value.isEmpty) {
                        _viewModel.resetProficiencyBonusToAuto();
                      }
                    },
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    icon: Icons.add_circle_outline,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CombatStatChip(
                    label: 'Aktuell',
                    value: '+${_viewModel.proficiencyBonus}',
                    icon: Icons.auto_awesome,
                    color: _viewModel.hasProficiencyBonusOverride 
                        ? DnDTheme.mysticalPurple 
                        : DnDTheme.successGreen,
                  ),
                ),
              ],
            ),
            // Info-Text für automatische Berechnung
            if (!_viewModel.hasProficiencyBonusOverride)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 14,
                      color: Colors.white54,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Wird automatisch basierend auf dem Level berechnet. Gib einen Wert ein, um ihn manuell zu überschreiben.',
                        style: DnDTheme.bodyText2.copyWith(
                          color: Colors.white54,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FormFieldWidget(
                    label: 'Basis-AC',
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
                  child: CombatStatChip(
                    label: 'Initiative',
                    value: _viewModel.initiativeBonus >= 0 
                        ? '+${_viewModel.initiativeBonus}' 
                        : '${_viewModel.initiativeBonus}',
                    icon: Icons.flash_on,
                    color: DnDTheme.ancientGold,
                  ),
                ),
              ],
            ),
            // Zeige effektive AC wenn Ausrüstung getragen wird
            if (viewModel.isEdit && hasEquipmentBonus) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DnDTheme.arcaneBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                  border: Border.all(
                    color: DnDTheme.arcaneBlue.withValues(alpha: 0.5),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.shield,
                      color: DnDTheme.arcaneBlue,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Effektive Rüstungsklasse',
                            style: DnDTheme.bodyText2.copyWith(
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$effectiveAc',
                            style: DnDTheme.headline1.copyWith(
                              color: DnDTheme.arcaneBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 28,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Zeige Dex Modifier
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DnDTheme.stoneGrey,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Dex ${viewModel.dexterityModifier >= 0 ? '+' : ''}${viewModel.dexterityModifier}',
                        style: DnDTheme.bodyText2.copyWith(
                          color: DnDTheme.ancientGold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
      },
    );
  }

  Widget _buildAbilityGrid() {
    return AttributesSectionWidget(
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
      title: 'Attributspunkte',
      icon: Icons.fitness_center,
      useSectionCard: true,
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

  Future<void> _saveWithoutNavigation() async {
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
          'Charakter automatisch gespeichert',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Speichern: $e');
      }
    }
  }

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
  

}
