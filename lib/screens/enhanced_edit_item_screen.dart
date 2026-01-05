import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/edit_item_viewmodel.dart';
import '../models/item.dart';
import '../theme/dnd_theme.dart';

/// Enhanced Item Edit Screen mit Provider-Pattern und modernem D&D Design
class EnhancedEditItemScreen extends StatefulWidget {
  final Item? item;

  const EnhancedEditItemScreen({
    super.key,
    this.item,
  });

  @override
  State<EnhancedEditItemScreen> createState() => _EnhancedEditItemScreenState();
}

class _EnhancedEditItemScreenState extends State<EnhancedEditItemScreen> {
  late EditItemViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _propertiesController = TextEditingController();
  final _costController = TextEditingController();
  final _weightController = TextEditingController();
  final _damageController = TextEditingController();
  
  // Neue Controller für erweiterte Optionen
  final _acFormulaController = TextEditingController();
  final _strengthController = TextEditingController();
  final _rarityController = TextEditingController();
  final _maxDurabilityController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = EditItemViewModel();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.initialize(widget.item);
      _populateFields();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _propertiesController.dispose();
    _costController.dispose();
    _weightController.dispose();
    _damageController.dispose();
    _acFormulaController.dispose();
    _strengthController.dispose();
    _rarityController.dispose();
    _maxDurabilityController.dispose();
    super.dispose();
  }

  void _populateFields() {
    final item = _viewModel.item;
    
    if (item != null) {
      _nameController.text = item!.name;
      _descriptionController.text = item!.description;
      _propertiesController.text = item!.properties ?? '';
      _costController.text = item!.cost.toString();
      _weightController.text = item!.weight.toString();
      _damageController.text = item!.damage ?? '';
      _acFormulaController.text = item!.acFormula ?? '';
      _strengthController.text = item!.strengthRequirement?.toString() ?? '';
      _rarityController.text = item!.rarity ?? '';
      _maxDurabilityController.text = item!.maxDurability?.toString() ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EditItemViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: SafeArea(
          child: Consumer<EditItemViewModel>(
            builder: (context, viewModel, child) {
              return Column(
                children: [
                  _buildHeader(context, viewModel),
                  Expanded(
                    child: _buildForm(context, viewModel),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EditItemViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DnDTheme.dungeonBlack,
            DnDTheme.stoneGrey.withValues(alpha: 0.3),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
            ),
            child: IconButton(
              onPressed: () => _handleBackNavigation(viewModel),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
                size: 20,
              ),
              padding: const EdgeInsets.all(DnDTheme.sm),
            ),
          ),
          const SizedBox(width: DnDTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.item != null ? 'Item bearbeiten' : 'Neues Item',
                  style: DnDTheme.headline2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (viewModel.item != null) ...[
                  const SizedBox(height: DnDTheme.xs),
                  Text(
                    viewModel.item!.name,
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white70,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (viewModel.hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DnDTheme.md,
                vertical: DnDTheme.xs,
              ),
              decoration: BoxDecoration(
                color: DnDTheme.warningOrange,
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                boxShadow: [
                  BoxShadow(
                    color: DnDTheme.warningOrange.withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.edit,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: DnDTheme.xs),
                  const Text(
                    'Bearbeitet',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildForm(BuildContext context, EditItemViewModel viewModel) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(DnDTheme.lg),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          _buildBasicInfoSection(context, viewModel),
          const SizedBox(height: DnDTheme.xl),
          _buildDetailsSection(context, viewModel),
            const SizedBox(height: DnDTheme.xl),
            _buildAdvancedOptionsSection(context, viewModel),
            const SizedBox(height: DnDTheme.xl),
            _buildPropertiesSection(context, viewModel),
            const SizedBox(height: DnDTheme.xl),
            _buildActionButtons(context, viewModel),
            const SizedBox(height: DnDTheme.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DnDTheme.lg),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(DnDTheme.sm),
            decoration: BoxDecoration(
              color: DnDTheme.ancientGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              color: DnDTheme.ancientGold,
              size: 20,
            ),
          ),
          const SizedBox(width: DnDTheme.md),
          Text(
            title,
            style: DnDTheme.headline3.copyWith(
              color: DnDTheme.ancientGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, EditItemViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusLarge),
        border: Border.all(
          color: DnDTheme.ancientGold.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              title: 'Grundlegende Informationen',
              icon: Icons.info_outline,
            ),
            TextFormField(
              controller: _nameController,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'z.B. Langschwert +1',
                labelStyle: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
                hintStyle: DnDTheme.bodyText2.copyWith(
                  color: Colors.white38,
                ),
                prefixIcon: Icon(
                  Icons.shopping_bag_outlined,
                  color: DnDTheme.ancientGold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey,
                contentPadding: const EdgeInsets.all(DnDTheme.md),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name ist erforderlich';
                }
                if (value.trim().length < 2) {
                  return 'Name muss mindestens 2 Zeichen lang sein';
                }
                return null;
              },
              onChanged: (value) => viewModel.updateName(value),
            ),
            const SizedBox(height: DnDTheme.lg),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'Beschreibe das Item...',
                labelStyle: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
                hintStyle: DnDTheme.bodyText2.copyWith(
                  color: Colors.white38,
                ),
                prefixIcon: Icon(
                  Icons.description_outlined,
                  color: DnDTheme.ancientGold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey,
                contentPadding: const EdgeInsets.all(DnDTheme.md),
              ),
              onChanged: (value) => viewModel.updateDescription(value),
            ),
            const SizedBox(height: DnDTheme.lg),
            DropdownButtonFormField<ItemType>(
              value: viewModel.item?.itemType,
              dropdownColor: DnDTheme.stoneGrey,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Item Typ',
                labelStyle: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
                prefixIcon: Icon(
                  Icons.category_outlined,
                  color: DnDTheme.ancientGold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey,
                contentPadding: const EdgeInsets.all(DnDTheme.md),
              ),
              items: ItemType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(
                        _getItemTypeIcon(type),
                        color: DnDTheme.ancientGold,
                        size: 20,
                      ),
                      const SizedBox(width: DnDTheme.md),
                      Text(_getItemTypeDisplayName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  viewModel.updateType(value);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, EditItemViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusLarge),
        border: Border.all(
          color: DnDTheme.arcaneBlue.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              title: 'Details',
              icon: Icons.tune_outlined,
            ),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Wert (Gold)',
                      hintText: '0',
                      labelStyle: DnDTheme.bodyText2.copyWith(
                        color: DnDTheme.arcaneBlue,
                      ),
                      hintStyle: DnDTheme.bodyText2.copyWith(
                        color: Colors.white38,
                      ),
                      prefixIcon: Icon(
                        Icons.monetization_on_outlined,
                        color: DnDTheme.arcaneBlue,
                      ),
                      suffixText: 'gp',
                      suffixStyle: DnDTheme.bodyText2.copyWith(
                        color: DnDTheme.arcaneBlue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: DnDTheme.slateGrey,
                      contentPadding: const EdgeInsets.all(DnDTheme.md),
                    ),
                    onChanged: (value) {
                      final cost = double.tryParse(value) ?? 0.0;
                      viewModel.updateValue(cost);
                    },
                  ),
                ),
                const SizedBox(width: DnDTheme.lg),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Gewicht (lbs)',
                      hintText: '0.0',
                      labelStyle: DnDTheme.bodyText2.copyWith(
                        color: DnDTheme.arcaneBlue,
                      ),
                      hintStyle: DnDTheme.bodyText2.copyWith(
                        color: Colors.white38,
                      ),
                      prefixIcon: Icon(
                        Icons.scale_outlined,
                        color: DnDTheme.arcaneBlue,
                      ),
                      suffixText: 'lbs',
                      suffixStyle: DnDTheme.bodyText2.copyWith(
                        color: DnDTheme.arcaneBlue,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: DnDTheme.slateGrey,
                      contentPadding: const EdgeInsets.all(DnDTheme.md),
                    ),
                    onChanged: (value) {
                      final weight = double.tryParse(value) ?? 0.0;
                      viewModel.updateWeight(weight);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedOptionsSection(BuildContext context, EditItemViewModel viewModel) {
    final itemType = viewModel.item?.itemType ?? ItemType.Weapon;
    
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusLarge),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              title: 'Erweiterte Optionen',
              icon: Icons.auto_awesome_outlined,
            ),
            
            // Typspezifische Felder basierend auf Item-Typ
            if (itemType == ItemType.Weapon) ...[
              _buildWeaponSpecificFields(viewModel),
            ] else if (itemType == ItemType.Armor || itemType == ItemType.Shield) ...[
              _buildArmorSpecificFields(viewModel),
            ] else if (itemType == ItemType.MagicItem) ...[
              _buildMagicItemSpecificFields(viewModel),
            ],
            
            // Magische Eigenschaften (für alle Typen)
            const SizedBox(height: DnDTheme.lg),
            _buildMagicPropertiesSection(viewModel),
            
            // Haltbarkeit (für alle Typen)
            const SizedBox(height: DnDTheme.lg),
            _buildDurabilitySection(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildWeaponSpecificFields(EditItemViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(DnDTheme.md),
          decoration: BoxDecoration(
            color: DnDTheme.errorRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
            border: Border.all(
              color: DnDTheme.errorRed.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.gavel,
                color: DnDTheme.errorRed,
                size: 20,
              ),
              const SizedBox(width: DnDTheme.md),
              Text(
                'Waffen-spezifische Optionen',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.errorRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DnDTheme.md),
        TextFormField(
          controller: _damageController,
          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Schadenswurf',
            hintText: 'z.B. 1d8, 2d6+3',
            labelStyle: DnDTheme.bodyText2.copyWith(color: DnDTheme.errorRed),
            hintStyle: DnDTheme.bodyText2.copyWith(color: Colors.white38),
            prefixIcon: Icon(Icons.casino_outlined, color: DnDTheme.errorRed),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: DnDTheme.slateGrey,
            contentPadding: const EdgeInsets.all(DnDTheme.md),
          ),
          onChanged: (value) => viewModel.updateDamage(value),
        ),
      ],
    );
  }

  Widget _buildArmorSpecificFields(EditItemViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(DnDTheme.md),
          decoration: BoxDecoration(
            color: DnDTheme.arcaneBlue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
            border: Border.all(
              color: DnDTheme.arcaneBlue.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.shield,
                color: DnDTheme.arcaneBlue,
                size: 20,
              ),
              const SizedBox(width: DnDTheme.md),
              Text(
                'Rüstungs-spezifische Optionen',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.arcaneBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DnDTheme.md),
        TextFormField(
          controller: _acFormulaController,
          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Rüstungsklasse (AC)',
            hintText: 'z.B. 12 + Dex',
            labelStyle: DnDTheme.bodyText2.copyWith(color: DnDTheme.arcaneBlue),
            hintStyle: DnDTheme.bodyText2.copyWith(color: Colors.white38),
            prefixIcon: Icon(Icons.security, color: DnDTheme.arcaneBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: DnDTheme.slateGrey,
            contentPadding: const EdgeInsets.all(DnDTheme.md),
          ),
          onChanged: (value) => viewModel.updateAcFormula(value),
        ),
        const SizedBox(height: DnDTheme.md),
        TextFormField(
          controller: _strengthController,
          keyboardType: TextInputType.number,
          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Stärkeanforderung',
            hintText: '0',
            labelStyle: DnDTheme.bodyText2.copyWith(color: DnDTheme.arcaneBlue),
            hintStyle: DnDTheme.bodyText2.copyWith(color: Colors.white38),
            prefixIcon: Icon(Icons.fitness_center, color: DnDTheme.arcaneBlue),
            suffixText: 'STR',
            suffixStyle: DnDTheme.bodyText2.copyWith(color: DnDTheme.arcaneBlue),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: DnDTheme.slateGrey,
            contentPadding: const EdgeInsets.all(DnDTheme.md),
          ),
          onChanged: (value) {
            final strength = int.tryParse(value);
            viewModel.updateStrengthRequirement(strength);
          },
        ),
        const SizedBox(height: DnDTheme.md),
        CheckboxListTile(
          title: Text(
            'Nachteil auf Verstecken (Stealth)',
            style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
          ),
          subtitle: Text(
            'Das Item verursacht Nachteil auf Stealth-Checks',
            style: DnDTheme.bodyText2.copyWith(color: Colors.white54, fontSize: 12),
          ),
          value: viewModel.item?.stealthDisadvantage ?? false,
          onChanged: (value) => viewModel.updateStealthDisadvantage(value),
          activeColor: DnDTheme.arcaneBlue,
          checkColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildMagicItemSpecificFields(EditItemViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(DnDTheme.md),
          decoration: BoxDecoration(
            color: DnDTheme.ancientGold.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
            border: Border.all(
              color: DnDTheme.ancientGold.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: DnDTheme.ancientGold,
                size: 20,
              ),
              const SizedBox(width: DnDTheme.md),
              Text(
                'Magische Eigenschaften',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DnDTheme.md),
        TextFormField(
          controller: _rarityController,
          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Seltenheit',
            hintText: 'z.B. Uncommon, Rare, Very Rare, Legendary',
            labelStyle: DnDTheme.bodyText2.copyWith(color: DnDTheme.ancientGold),
            hintStyle: DnDTheme.bodyText2.copyWith(color: Colors.white38),
            prefixIcon: Icon(Icons.stars, color: DnDTheme.ancientGold),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: DnDTheme.slateGrey,
            contentPadding: const EdgeInsets.all(DnDTheme.md),
          ),
          onChanged: (value) => viewModel.updateRarity(value),
        ),
      ],
    );
  }

  Widget _buildMagicPropertiesSection(EditItemViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(DnDTheme.md),
          decoration: BoxDecoration(
            color: DnDTheme.mysticalPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
            border: Border.all(
              color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.auto_fix_high,
                color: DnDTheme.mysticalPurple,
                size: 20,
              ),
              const SizedBox(width: DnDTheme.md),
              Text(
                'Magische Anforderung',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.mysticalPurple,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DnDTheme.md),
        CheckboxListTile(
          title: Text(
            'Attunement erforderlich',
            style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
          ),
          subtitle: Text(
            'Das Item erfordert eine kurze Ruhephase zur Bindung',
            style: DnDTheme.bodyText2.copyWith(color: Colors.white54, fontSize: 12),
          ),
          value: viewModel.item?.requiresAttunement ?? false,
          onChanged: (value) => viewModel.updateRequiresAttunement(value),
          activeColor: DnDTheme.mysticalPurple,
          checkColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildDurabilitySection(EditItemViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(DnDTheme.md),
          decoration: BoxDecoration(
            color: DnDTheme.emeraldGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
            border: Border.all(
              color: DnDTheme.emeraldGreen.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.build_circle,
                color: DnDTheme.emeraldGreen,
                size: 20,
              ),
              const SizedBox(width: DnDTheme.md),
              Text(
                'Haltbarkeit',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.emeraldGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: DnDTheme.md),
        CheckboxListTile(
          title: Text(
            'Haltbarkeit aktivieren',
            style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
          ),
          subtitle: Text(
            'Das Item hat eine begrenzte Haltbarkeit',
            style: DnDTheme.bodyText2.copyWith(color: Colors.white54, fontSize: 12),
          ),
          value: viewModel.item?.hasDurability ?? false,
          onChanged: (value) => viewModel.updateHasDurability(value),
          activeColor: DnDTheme.emeraldGreen,
          checkColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (viewModel.item?.hasDurability == true) ...[
          const SizedBox(height: DnDTheme.md),
          TextFormField(
            controller: _maxDurabilityController,
            keyboardType: TextInputType.number,
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Maximale Haltbarkeit',
              hintText: '0',
              labelStyle: DnDTheme.bodyText2.copyWith(color: DnDTheme.emeraldGreen),
              hintStyle: DnDTheme.bodyText2.copyWith(color: Colors.white38),
              prefixIcon: Icon(Icons.battery_charging_full, color: DnDTheme.emeraldGreen),
              suffixText: 'HP',
              suffixStyle: DnDTheme.bodyText2.copyWith(color: DnDTheme.emeraldGreen),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: DnDTheme.slateGrey,
              contentPadding: const EdgeInsets.all(DnDTheme.md),
            ),
            onChanged: (value) {
              final durability = int.tryParse(value);
              viewModel.updateMaxDurability(durability);
            },
          ),
          const SizedBox(height: DnDTheme.md),
          CheckboxListTile(
            title: Text(
              'Reparierbar',
              style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
            ),
            subtitle: Text(
              'Das Item kann repariert werden',
              style: DnDTheme.bodyText2.copyWith(color: Colors.white54, fontSize: 12),
            ),
            value: viewModel.item?.isRepairable ?? false,
            onChanged: (value) => viewModel.updateIsRepairable(value),
            activeColor: DnDTheme.emeraldGreen,
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ],
    );
  }

  Widget _buildPropertiesSection(BuildContext context, EditItemViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusLarge),
        border: Border.all(
          color: DnDTheme.emeraldGreen.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.xl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
              title: 'Eigenschaften',
              icon: Icons.edit_note_outlined,
            ),
            TextFormField(
              controller: _propertiesController,
              maxLines: 4,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Spezielle Eigenschaften',
                hintText: 'z.B. Magische Boni, Spezialfähigkeiten...',
                labelStyle: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.emeraldGreen,
                ),
                hintStyle: DnDTheme.bodyText2.copyWith(
                  color: Colors.white38,
                ),
                prefixIcon: Icon(
                  Icons.star_outline,
                  color: DnDTheme.emeraldGreen,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey,
                contentPadding: const EdgeInsets.all(DnDTheme.md),
              ),
              onChanged: (value) => viewModel.updateProperties(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EditItemViewModel viewModel) {
    return Column(
      children: [
        if (viewModel.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(DnDTheme.lg),
            margin: const EdgeInsets.only(bottom: DnDTheme.lg),
            decoration: BoxDecoration(
              color: DnDTheme.errorRed.withValues(alpha: 0.2),
              border: Border.all(color: DnDTheme.errorRed, width: 2),
              borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
              boxShadow: [
                BoxShadow(
                  color: DnDTheme.errorRed.withValues(alpha: 0.3),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: DnDTheme.errorRed,
                  size: 24,
                ),
                const SizedBox(width: DnDTheme.md),
                Expanded(
                  child: Text(
                    viewModel.errorMessage!,
                    style: DnDTheme.bodyText1.copyWith(
                      color: DnDTheme.errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(
              child: _buildPrimaryButton(
                onPressed: viewModel.isLoading ? null : () => _handleSave(viewModel),
                label: 'SPEICHERN',
                icon: Icons.save,
                color: DnDTheme.successGreen,
                isLoading: viewModel.isLoading,
              ),
            ),
            const SizedBox(width: DnDTheme.lg),
            Expanded(
              child: _buildSecondaryButton(
                onPressed: viewModel.isLoading ? null : () => _handleCancel(viewModel),
                label: 'ABBRECHEN',
                icon: Icons.close,
              ),
            ),
          ],
        ),
        if (viewModel.item != null) ...[
          const SizedBox(height: DnDTheme.lg),
          SizedBox(
            width: double.infinity,
            child: _buildDangerButton(
              onPressed: viewModel.isLoading ? null : () => _handleDelete(viewModel),
              label: 'ITEM LÖSCHEN',
              icon: Icons.delete_forever,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPrimaryButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    required Color color,
    bool isLoading = false,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: DnDTheme.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        ),
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.4),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon),
                const SizedBox(width: DnDTheme.md),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSecondaryButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white70,
        side: BorderSide(
          color: Colors.white54,
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(vertical: DnDTheme.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: DnDTheme.md),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: DnDTheme.errorRed,
        side: BorderSide(
          color: DnDTheme.errorRed,
          width: 2,
        ),
        padding: const EdgeInsets.symmetric(vertical: DnDTheme.lg),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: DnDTheme.md),
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getItemTypeIcon(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return Icons.gavel;
      case ItemType.Armor:
        return Icons.shield;
      case ItemType.Shield:
        return Icons.shield_outlined;
      case ItemType.Consumable:
        return Icons.restaurant;
      case ItemType.Tool:
        return Icons.build;
      case ItemType.Material:
        return Icons.science;
      case ItemType.Component:
        return Icons.category;
      case ItemType.MagicItem:
        return Icons.auto_awesome;
      case ItemType.Scroll:
        return Icons.description;
      case ItemType.Potion:
        return Icons.local_drink;
      case ItemType.Treasure:
        return Icons.diamond;
      case ItemType.Currency:
        return Icons.monetization_on;
      case ItemType.AdventuringGear:
        return Icons.inventory_2;
      case ItemType.SPELL_WEAPON:
        return Icons.flare;
    }
  }

  String _getItemTypeDisplayName(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return 'Waffe';
      case ItemType.Armor:
        return 'Rüstung';
      case ItemType.Shield:
        return 'Schild';
      case ItemType.Consumable:
        return 'Verbrauchsgut';
      case ItemType.Tool:
        return 'Werkzeug';
      case ItemType.Material:
        return 'Material';
      case ItemType.Component:
        return 'Komponente';
      case ItemType.MagicItem:
        return 'Magisches Item';
      case ItemType.Scroll:
        return 'Schriftrolle';
      case ItemType.Potion:
        return 'Trank';
      case ItemType.Treasure:
        return 'Schatz';
      case ItemType.Currency:
        return 'Währung';
      case ItemType.AdventuringGear:
        return 'Ausrüstung';
      case ItemType.SPELL_WEAPON:
        return 'Spruch als Waffe';
    }
  }

  void _handleSave(EditItemViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await viewModel.saveItem();
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _handleCancel(EditItemViewModel viewModel) async {
    if (viewModel.hasUnsavedChanges) {
      final shouldLeave = await _showUnsavedChangesDialog(viewModel);
      if (shouldLeave == true && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleDelete(EditItemViewModel viewModel) async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed == true && mounted) {
      final success = await viewModel.deleteItem();
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  void _handleBackNavigation(EditItemViewModel viewModel) async {
    if (viewModel.hasUnsavedChanges) {
      final shouldLeave = await _showUnsavedChangesDialog(viewModel);
      if (shouldLeave == true && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showUnsavedChangesDialog(EditItemViewModel viewModel) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_outlined,
              color: DnDTheme.warningOrange,
              size: 28,
            ),
            const SizedBox(width: DnDTheme.md),
            const Text(
              'Ungespeicherte Änderungen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Sie haben ungespeicherte Änderungen. Möchten Sie wirklich gehen?',
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: DnDTheme.warningOrange,
            ),
            child: const Text('VERLASSEN'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Row(
          children: [
            Icon(
              Icons.delete_forever,
              color: DnDTheme.errorRed,
              size: 28,
            ),
            const SizedBox(width: DnDTheme.md),
            const Text(
              'Löschen bestätigen',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Text(
          'Möchten Sie dieses Item wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: DnDTheme.errorRed,
            ),
            child: const Text('LÖSCHEN'),
          ),
        ],
      ),
    );
  }
}
