import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creature.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/edit_creature_viewmodel.dart';
import '../../widgets/ui_components/stats/attributes_section_widget.dart';
import '../../widgets/ui_components/inventory/creature_inventory_widget.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/bestiary/edit_creature/edit_creature_screen_widgets.dart';

/// Enhanced Screen zur Bearbeitung von Creatures - basierend auf Hero Creation Screen
class EditCreatureScreen extends StatefulWidget {
  final Creature? creature;

  const EditCreatureScreen({
    super.key,
    this.creature,
  });

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
    return ChangeNotifierProvider<EditCreatureViewModel>.value(
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
        _viewModel.isEditing ? 'Kreatur bearbeiten' : 'Neue Kreatur erstellen',
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
          Tab(icon: Icon(Icons.pets), text: ' Grunddaten'),
          Tab(icon: Icon(Icons.fitness_center), text: ' Attribute'),
          Tab(icon: Icon(Icons.category), text: ' Fähigkeiten'),
          Tab(icon: Icon(Icons.inventory), text: ' Inventar'),
        ],
      ),
    );
  }

  // ============================================================================

  Widget _buildBody() {
    return Consumer<EditCreatureViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return Center(
            child: CircularProgressIndicator(
              color: DnDTheme.ancientGold,
            ),
          );
        }

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
  }

  // ============================================================================

  Widget _buildBasicInfoTab() {
    return Consumer<EditCreatureViewModel>(
      builder: (context, viewModel, child) {
        return Form(
          key: _formKey,
          child: SingleChildScrollView(
            controller: _scrollController,
            padding: const EdgeInsets.all(DnDTheme.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionTitleWidget(title: 'Grundinformationen', icon: Icons.pets),
                const SizedBox(height: DnDTheme.md),
                BasicInfoSection(
                  name: viewModel.name,
                  description: viewModel.description,
                  speed: viewModel.speed,
                  onNameChanged: viewModel.updateName,
                  onDescriptionChanged: viewModel.updateDescription,
                  onSpeedChanged: viewModel.updateSpeed,
                ),
                const SizedBox(height: DnDTheme.xl),
                const SectionTitleWidget(title: 'Kreatureigenschaften', icon: Icons.category),
                const SizedBox(height: DnDTheme.md),
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
                const SizedBox(height: DnDTheme.xl),
                const SectionTitleWidget(title: 'Kampfwerte', icon: Icons.security),
                const SizedBox(height: DnDTheme.md),
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
        );
      },
    );
  }

  Widget _buildAttributesTab() {
    return Consumer<EditCreatureViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(DnDTheme.lg),
          child: _buildAttributeSection(),
        );
      },
    );
  }

  Widget _buildAbilitiesTab() {
    return Consumer<EditCreatureViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(DnDTheme.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionTitleWidget(title: 'Angriffe & Fähigkeiten', icon: Icons.auto_awesome),
              const SizedBox(height: DnDTheme.md),
              AbilitiesSection(
                attacks: viewModel.attacks,
                specialAbilities: viewModel.specialAbilities,
                legendaryActions: viewModel.legendaryActions,
                onAttacksChanged: viewModel.updateAttacks,
                onSpecialAbilitiesChanged: viewModel.updateSpecialAbilities,
                onLegendaryActionsChanged: viewModel.updateLegendaryActions,
              ),
              const SizedBox(height: DnDTheme.xl),
              const SectionTitleWidget(title: 'Währung', icon: Icons.monetization_on),
              const SizedBox(height: DnDTheme.md),
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
        );
      },
    );
  }

  Widget _buildInventoryTab() {
    return Consumer<EditCreatureViewModel>(
      builder: (context, viewModel, child) {
        return CreatureInventoryWidget(
          mapItems: viewModel.inventory,
          onAddItem: () => CreatureItemDialogs.showAddItemDialog(context, viewModel),
          onRemoveItem: (index) => viewModel.removeInventoryItem(index),
          onEditItem: (index, item) => CreatureItemDialogs.showEditItemDialog(context, viewModel, index),
          showAddButton: true,
        );
      },
    );
  }

  // ============================================================================

  Widget _buildAttributeSection() {
    return Consumer<EditCreatureViewModel>(
      builder: (context, viewModel, child) {
        return AttributesSectionWidget(
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
        );
      },
    );
  }

  // ============================================================================

  Widget _buildFloatingActionButton() {
    return Consumer<EditCreatureViewModel>(
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
          onPressed: viewModel.canSave ? _saveCreature : null,
          backgroundColor: DnDTheme.successGreen,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.save),
          label: const Text('Speichern'),
        );
      },
    );
  }

  // ============================================================================

  Future<void> _saveCreature() async {
    FocusScope.of(context).unfocus();
    
    // Sammle alle Validierungsfehler
    final errors = <String>[];
    
    // Prüfe Name
    if (_viewModel.name.trim().isEmpty) {
      errors.add('Name der Kreatur');
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
      if (mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Speichern: $e');
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_viewModel.isEditing) {
      return true;
    }
    
    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Ungespeicherte Änderungen',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Text(
          'Möchtest du wirklich ohne Speichern gehen?',
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
}