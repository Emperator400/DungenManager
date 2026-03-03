import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/creature.dart';
import '../theme/dnd_theme.dart';
import '../viewmodels/edit_creature_viewmodel.dart';
import '../widgets/ui_components/stats/attributes_section_widget.dart';
import '../widgets/ui_components/inventory/creature_inventory_widget.dart';
import '../widgets/ui_components/forms/form_field_widget.dart';
import '../widgets/ui_components/cards/section_card_widget.dart';
import '../widgets/ui_components/feedback/snackbar_helper.dart';

/// Enhanced Screen zur Bearbeitung von Creatures - basierend auf Hero Creation Screen
class EnhancedEditCreatureScreen extends StatefulWidget {
  final Creature? creature;

  const EnhancedEditCreatureScreen({
    super.key,
    this.creature,
  });

  @override
  State<EnhancedEditCreatureScreen> createState() => _EnhancedEditCreatureScreenState();
}

class _EnhancedEditCreatureScreenState extends State<EnhancedEditCreatureScreen>
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
          return _buildErrorWidget(viewModel.error!);
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
                _buildSectionTitle('Grundinformationen', Icons.pets),
                const SizedBox(height: DnDTheme.md),
                _buildBasicInfoSection(),
                const SizedBox(height: DnDTheme.xl),
                _buildSectionTitle('Kreatureigenschaften', Icons.category),
                const SizedBox(height: DnDTheme.md),
                _buildCreatureTypeSection(),
                const SizedBox(height: DnDTheme.xl),
                _buildSectionTitle('Kampfwerte', Icons.security),
                const SizedBox(height: DnDTheme.md),
                _buildCombatStatsSection(),
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
              _buildSectionTitle('Angriffe & Fähigkeiten', Icons.auto_awesome),
              const SizedBox(height: DnDTheme.md),
              _buildAbilitiesSection(),
              const SizedBox(height: DnDTheme.xl),
              _buildSectionTitle('Währung', Icons.monetization_on),
              const SizedBox(height: DnDTheme.md),
              _buildCurrencySection(),
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
          onAddItem: () => _showAddItemDialog(context, viewModel),
          onRemoveItem: (index) => viewModel.removeInventoryItem(index),
          onEditItem: (index, item) => _showEditItemDialog(context, viewModel, index),
          showAddButton: true,
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

  Widget _buildAbilitiesSection() {
    return Consumer<EditCreatureViewModel>(
      builder: (context, viewModel, child) {
        return SectionCardWidget(
          title: 'Angriffe & Fähigkeiten',
          icon: Icons.auto_awesome,
          child: Column(
            children: [
              FormFieldWidget(
                label: 'Angriffe',
                value: viewModel.attacks,
                onChanged: viewModel.updateAttacks,
                icon: Icons.gavel,
                maxLines: 3,
              ),
              const SizedBox(height: DnDTheme.md),
              FormFieldWidget(
                label: 'Spezielle Fähigkeiten',
                value: viewModel.specialAbilities ?? '',
                onChanged: (value) => viewModel.updateSpecialAbilities(value.isEmpty ? null : value),
                icon: Icons.psychology,
                maxLines: 3,
              ),
              const SizedBox(height: DnDTheme.md),
              FormFieldWidget(
                label: 'Legendäre Aktionen',
                value: viewModel.legendaryActions ?? '',
                onChanged: (value) => viewModel.updateLegendaryActions(value.isEmpty ? null : value),
                icon: Icons.star,
                maxLines: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBasicInfoSection() {
    return Consumer<EditCreatureViewModel>(
      builder: (context, viewModel, child) {
        return SectionCardWidget(
          title: 'Grundinformationen',
          icon: Icons.info_outline,
          child: Column(
            children: [
              FormFieldWidget(
                label: 'Name',
                value: viewModel.name,
                onChanged: viewModel.updateName,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name ist erforderlich';
                  }
                  return null;
                },
                icon: Icons.pets,
              ),
              const SizedBox(height: DnDTheme.md),
              FormFieldWidget(
                label: 'Beschreibung',
                value: viewModel.description ?? '',
                onChanged: viewModel.updateDescription,
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: DnDTheme.md),
              FormFieldWidget(
                label: 'Geschwindigkeit',
                value: viewModel.speed,
                onChanged: viewModel.updateSpeed,
                icon: Icons.speed,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCreatureTypeSection() {
    return Consumer<EditCreatureViewModel>(
      builder: (context, viewModel, child) {
        return SectionCardWidget(
          title: 'Kreatureigenschaften',
          icon: Icons.category,
          child: Column(
            children: [
              FormFieldWidget(
                label: 'Typ',
                value: viewModel.type ?? '',
                onChanged: (value) => viewModel.updateType(value.isEmpty ? null : value),
                icon: Icons.category,
              ),
              const SizedBox(height: DnDTheme.md),
              FormFieldWidget(
                label: 'Subtyp',
                value: viewModel.subtype ?? '',
                onChanged: (value) => viewModel.updateSubtype(value.isEmpty ? null : value),
                icon: Icons.layers,
              ),
              const SizedBox(height: DnDTheme.md),
              FormFieldWidget(
                label: 'Größe',
                value: viewModel.size ?? '',
                onChanged: viewModel.updateSize,
                icon: Icons.straighten,
              ),
              const SizedBox(height: DnDTheme.md),
              FormFieldWidget(
                label: 'Ausrichtung',
                value: viewModel.alignment ?? '',
                onChanged: viewModel.updateAlignment,
                icon: Icons.compass_calibration,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCombatStatsSection() {
    return Consumer<EditCreatureViewModel>(
      builder: (context, viewModel, child) {
        return SectionCardWidget(
          title: 'Kampfwerte',
          icon: Icons.security,
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: FormFieldWidget(
                      label: 'Max. HP',
                      value: viewModel.maxHp.toString(),
                      onChanged: (value) {
                        final hp = int.tryParse(value) ?? 10;
                        viewModel.updateMaxHp(hp);
                      },
                      icon: Icons.favorite,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: DnDTheme.md),
                  Expanded(
                    child: FormFieldWidget(
                      label: 'RK',
                      value: viewModel.armorClass.toString(),
                      onChanged: (value) {
                        final ac = int.tryParse(value) ?? 10;
                        viewModel.updateArmorClass(ac);
                      },
                      icon: Icons.security,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DnDTheme.md),
              FormFieldWidget(
                label: 'Challenge Rating',
                value: viewModel.challengeRating.toString(),
                onChanged: (value) {
                  final cr = int.tryParse(value) ?? 1;
                  viewModel.updateChallengeRating(cr);
                },
                icon: Icons.star,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrencySection() {
    return Consumer<EditCreatureViewModel>(
      builder: (context, viewModel, child) {
        return SectionCardWidget(
          title: 'Währung',
          icon: Icons.monetization_on,
          child: Row(
            children: [
              Expanded(
                child: FormFieldWidget(
                  label: 'Gold',
                  value: viewModel.gold.toStringAsFixed(2),
                  onChanged: (value) {
                    final gold = double.tryParse(value) ?? 0.0;
                    viewModel.updateGold(gold);
                  },
                  icon: Icons.monetization_on,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: DnDTheme.md),
              Expanded(
                child: FormFieldWidget(
                  label: 'Silber',
                  value: viewModel.silver.toStringAsFixed(2),
                  onChanged: (value) {
                    final silver = double.tryParse(value) ?? 0.0;
                    viewModel.updateSilver(silver);
                  },
                  icon: Icons.monetization_on,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
              const SizedBox(width: DnDTheme.md),
              Expanded(
                child: FormFieldWidget(
                  label: 'Kupfer',
                  value: viewModel.copper.toStringAsFixed(2),
                  onChanged: (value) {
                    final copper = double.tryParse(value) ?? 0.0;
                    viewModel.updateCopper(copper);
                  },
                  icon: Icons.monetization_on,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ),
            ],
          ),
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

  Future<void> _showAddItemDialog(BuildContext context, EditCreatureViewModel viewModel) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final typeController = TextEditingController(text: 'item');
    final quantityController = TextEditingController(text: '1');
    final valueController = TextEditingController(text: '0.0');

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Gegenstand hinzufügen',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormFieldWidget(
                label: 'Name',
                value: '',
                onChanged: (value) => nameController.text = value,
                icon: Icons.inventory_2,
              ),
              const SizedBox(height: 12),
              FormFieldWidget(
                label: 'Beschreibung',
                value: '',
                onChanged: (value) => descriptionController.text = value,
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              FormFieldWidget(
                label: 'Typ',
                value: 'item',
                onChanged: (value) => typeController.text = value,
                icon: Icons.category,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FormFieldWidget(
                      label: 'Menge',
                      value: '1',
                      onChanged: (value) => quantityController.text = value,
                      icon: Icons.add_box,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: DnDTheme.md),
                  Expanded(
                    child: FormFieldWidget(
                      label: 'Wert (Gold)',
                      value: '0.0',
                      onChanged: (value) => valueController.text = value,
                      icon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final newItem = {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'type': typeController.text.trim(),
                  'quantity': int.tryParse(quantityController.text) ?? 1,
                  'value': double.tryParse(valueController.text) ?? 0.0,
                };
                viewModel.addInventoryItem(newItem);
                Navigator.of(dialogContext).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: DnDTheme.dungeonBlack,
            ),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditItemDialog(BuildContext context, EditCreatureViewModel viewModel, int index) {
    final inventory = viewModel.inventory;
    if (index < 0 || index >= inventory.length) return Future.value();

    final item = inventory[index];
    final nameController = TextEditingController(text: item['name'] as String? ?? '');
    final descriptionController = TextEditingController(text: item['description'] as String? ?? '');
    final typeController = TextEditingController(text: item['type'] as String? ?? 'item');
    final quantityController = TextEditingController(text: (item['quantity'] as int? ?? 1).toString());
    final valueController = TextEditingController(text: (item['value'] as double? ?? 0.0).toString());

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Gegenstand bearbeiten',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FormFieldWidget(
                label: 'Name',
                value: item['name'] as String? ?? '',
                onChanged: (value) => nameController.text = value,
                icon: Icons.inventory_2,
              ),
              const SizedBox(height: 12),
              FormFieldWidget(
                label: 'Beschreibung',
                value: item['description'] as String? ?? '',
                onChanged: (value) => descriptionController.text = value,
                icon: Icons.description,
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              FormFieldWidget(
                label: 'Typ',
                value: item['type'] as String? ?? 'item',
                onChanged: (value) => typeController.text = value,
                icon: Icons.category,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FormFieldWidget(
                      label: 'Menge',
                      value: (item['quantity'] as int? ?? 1).toString(),
                      onChanged: (value) => quantityController.text = value,
                      icon: Icons.add_box,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    ),
                  ),
                  const SizedBox(width: DnDTheme.md),
                  Expanded(
                    child: FormFieldWidget(
                      label: 'Wert (Gold)',
                      value: (item['value'] as double? ?? 0.0).toString(),
                      onChanged: (value) => valueController.text = value,
                      icon: Icons.monetization_on,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                final updatedItem = {
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'type': typeController.text.trim(),
                  'quantity': int.tryParse(quantityController.text) ?? 1,
                  'value': double.tryParse(valueController.text) ?? 0.0,
                };
                viewModel.updateInventoryItem(index, updatedItem);
                Navigator.of(dialogContext).pop();
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: DnDTheme.dungeonBlack,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }
}