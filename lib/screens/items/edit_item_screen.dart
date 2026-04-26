import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/edit_item_viewmodel.dart';
import '../../models/item.dart';
import '../../theme/app_theme.dart';

class EditItemScreen extends StatefulWidget {
  final Item? item;

  const EditItemScreen({super.key, this.item});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  late EditItemViewModel _viewModel;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _propertiesController = TextEditingController();
  final _costController = TextEditingController();
  final _weightController = TextEditingController();
  final _damageController = TextEditingController();
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
      _nameController.text = item.name;
      _descriptionController.text = item.description;
      _propertiesController.text = item.properties ?? '';
      _costController.text = item.cost.toString();
      _weightController.text = item.weight.toString();
      _damageController.text = item.damage ?? '';
      _acFormulaController.text = item.acFormula ?? '';
      _strengthController.text = item.strengthRequirement?.toString() ?? '';
      _rarityController.text = item.rarity ?? '';
      _maxDurabilityController.text = item.maxDurability?.toString() ?? '';
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
                  Expanded(child: _buildForm(context, viewModel)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, EditItemViewModel viewModel) {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.bgPanel,
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
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => _handleBackNavigation(viewModel),
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
              padding: const EdgeInsets.all(8),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  viewModel.item != null ? 'Item bearbeiten' : 'Neues Item',
                  style: const TextStyle(
                    fontSize: 22,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (viewModel.item != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    viewModel.item!.name,
                    style: const TextStyle(fontSize: 14, color: Colors.white70),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (viewModel.hasUnsavedChanges)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEA580C),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEA580C).withValues(alpha: 0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text(
                    'Bearbeitet',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBasicInfoSection(context, viewModel),
            const SizedBox(height: 32),
            _buildDetailsSection(context, viewModel),
            const SizedBox(height: 32),
            _buildAdvancedOptionsSection(context, viewModel),
            const SizedBox(height: 32),
            _buildPropertiesSection(context, viewModel),
            const SizedBox(height: 32),
            _buildActionButtons(context, viewModel),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle({required String title, required IconData icon}) {
    final C = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: C.amber.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: C.amber, size: 20),
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: TextStyle(fontSize: 18, color: C.amber, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(BuildContext context, EditItemViewModel viewModel) {
    final C = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.amber.withValues(alpha: 0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title: 'Grundlegende Informationen', icon: Icons.info_outline),
            TextFormField(
              controller: _nameController,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Item Name',
                hintText: 'z.B. Langschwert +1',
                labelStyle: TextStyle(fontSize: 14, color: C.amber),
                hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
                prefixIcon: Icon(Icons.shopping_bag_outlined, color: C.amber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: C.bgHover,
                contentPadding: const EdgeInsets.all(16),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Name ist erforderlich';
                if (value.trim().length < 2) return 'Name muss mindestens 2 Zeichen lang sein';
                return null;
              },
              onChanged: (value) => viewModel.updateName(value),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'Beschreibe das Item...',
                labelStyle: TextStyle(fontSize: 14, color: C.amber),
                hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
                prefixIcon: Icon(Icons.description_outlined, color: C.amber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: C.bgHover,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) => viewModel.updateDescription(value),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<ItemType>(
              value: viewModel.item?.itemType,
              dropdownColor: C.bgPanel,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Item Typ',
                labelStyle: TextStyle(fontSize: 14, color: C.amber),
                prefixIcon: Icon(Icons.category_outlined, color: C.amber),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: C.bgHover,
                contentPadding: const EdgeInsets.all(16),
              ),
              items: ItemType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Row(
                    children: [
                      Icon(_getItemTypeIcon(type), color: C.amber, size: 20),
                      const SizedBox(width: 16),
                      Text(_getItemTypeDisplayName(type)),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) viewModel.updateType(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailsSection(BuildContext context, EditItemViewModel viewModel) {
    final C = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.accent.withValues(alpha: 0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title: 'Details', icon: Icons.tune_outlined),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _costController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Wert (Gold)',
                      hintText: '0',
                      labelStyle: TextStyle(fontSize: 14, color: C.accent),
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
                      prefixIcon: Icon(Icons.monetization_on_outlined, color: C.accent),
                      suffixText: 'gp',
                      suffixStyle: TextStyle(fontSize: 14, color: C.accent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: C.bgHover,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (value) => viewModel.updateValue(double.tryParse(value) ?? 0.0),
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: TextFormField(
                    controller: _weightController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Gewicht (lbs)',
                      hintText: '0.0',
                      labelStyle: TextStyle(fontSize: 14, color: C.accent),
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
                      prefixIcon: Icon(Icons.scale_outlined, color: C.accent),
                      suffixText: 'lbs',
                      suffixStyle: TextStyle(fontSize: 14, color: C.accent),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: C.bgHover,
                      contentPadding: const EdgeInsets.all(16),
                    ),
                    onChanged: (value) => viewModel.updateWeight(double.tryParse(value) ?? 0.0),
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
    final C = context.appColors;
    final itemType = viewModel.item?.itemType ?? ItemType.Weapon;

    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title: 'Erweiterte Optionen', icon: Icons.auto_awesome_outlined),
            if (itemType == ItemType.Weapon) _buildWeaponSpecificFields(viewModel),
            if (itemType == ItemType.Armor || itemType == ItemType.Shield)
              _buildArmorSpecificFields(viewModel),
            if (itemType == ItemType.MagicItem) _buildMagicItemSpecificFields(viewModel),
            const SizedBox(height: 24),
            _buildMagicPropertiesSection(viewModel),
            const SizedBox(height: 24),
            _buildDurabilitySection(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildWeaponSpecificFields(EditItemViewModel viewModel) {
    final C = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.red.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.red.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.gavel, color: C.red, size: 20),
              const SizedBox(width: 16),
              Text(
                'Waffen-spezifische Optionen',
                style: TextStyle(fontSize: 14, color: C.red, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _damageController,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Schadenswurf',
            hintText: 'z.B. 1d8, 2d6+3',
            labelStyle: TextStyle(fontSize: 14, color: C.red),
            hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
            prefixIcon: Icon(Icons.casino_outlined, color: C.red),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: C.bgHover,
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) => viewModel.updateDamage(value),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: viewModel.item?.damageType,
          dropdownColor: C.bgPanel,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Schadenstyp',
            labelStyle: TextStyle(fontSize: 14, color: C.red),
            prefixIcon: Icon(Icons.whatshot_outlined, color: C.red),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: C.bgHover,
            contentPadding: const EdgeInsets.all(16),
          ),
          hint: const Text(
            'Schadenstyp auswählen...',
            style: TextStyle(fontSize: 14, color: Colors.white38),
          ),
          items: const [
            DropdownMenuItem(value: 'Slashing', child: Text('Hiebschaden (Slashing)')),
            DropdownMenuItem(value: 'Piercing', child: Text('Stichschaden (Piercing)')),
            DropdownMenuItem(value: 'Bludgeoning', child: Text('Wuchtschaden (Bludgeoning)')),
            DropdownMenuItem(value: 'Fire', child: Text('Feuerschaden')),
            DropdownMenuItem(value: 'Cold', child: Text('Kälteschaden')),
            DropdownMenuItem(value: 'Lightning', child: Text('Blitzschaden')),
            DropdownMenuItem(value: 'Thunder', child: Text('Donnerschaden')),
            DropdownMenuItem(value: 'Poison', child: Text('Giftschaden')),
            DropdownMenuItem(value: 'Acid', child: Text('Säureschaden')),
            DropdownMenuItem(value: 'Necrotic', child: Text('Nekrotischer Schaden')),
            DropdownMenuItem(value: 'Radiant', child: Text('Strahlender Schaden')),
            DropdownMenuItem(value: 'Psychic', child: Text('Psychischer Schaden')),
            DropdownMenuItem(value: 'Force', child: Text('Magischer Schaden')),
          ],
          onChanged: (value) => viewModel.updateDamageType(value),
        ),
      ],
    );
  }

  Widget _buildArmorSpecificFields(EditItemViewModel viewModel) {
    final C = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.accent.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.shield, color: C.accent, size: 20),
              const SizedBox(width: 16),
              Text(
                'Rüstungs-spezifische Optionen',
                style: TextStyle(fontSize: 14, color: C.accent, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: viewModel.item?.armorCategory != null
              ? viewModel.item!.armorCategory!.name
              : null,
          dropdownColor: C.bgPanel,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Rüstungskategorie',
            labelStyle: TextStyle(fontSize: 14, color: C.accent),
            prefixIcon: Icon(Icons.category, color: C.accent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: C.bgHover,
            contentPadding: const EdgeInsets.all(16),
          ),
          hint: const Text(
            'Kategorie auswählen...',
            style: TextStyle(fontSize: 14, color: Colors.white38),
          ),
          items: const [
            DropdownMenuItem(value: 'Light', child: Text('Leichte Rüstung')),
            DropdownMenuItem(value: 'Medium', child: Text('Mittlere Rüstung')),
            DropdownMenuItem(value: 'Heavy', child: Text('Schwere Rüstung')),
          ],
          onChanged: (value) {
            if (value == null) {
              viewModel.updateArmorCategory(null);
            } else {
              final category = ArmorCategory.values.firstWhere(
                (c) => c.name == value,
                orElse: () => ArmorCategory.Light,
              );
              viewModel.updateArmorCategory(category);
            }
          },
        ),
        const SizedBox(height: 8),
        if (viewModel.item?.armorCategory != null)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getArmorCategoryColor(viewModel.item!.armorCategory!).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color:
                    _getArmorCategoryColor(viewModel.item!.armorCategory!).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: _getArmorCategoryColor(viewModel.item!.armorCategory!),
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _getArmorCategoryDexInfo(viewModel.item!.armorCategory!),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _acFormulaController,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Rüstungsklasse (AC)',
            hintText: 'z.B. 12 + Dex',
            labelStyle: TextStyle(fontSize: 14, color: C.accent),
            hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
            prefixIcon: Icon(Icons.security, color: C.accent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: C.bgHover,
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) => viewModel.updateAcFormula(value),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _strengthController,
          keyboardType: TextInputType.number,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Stärkeanforderung',
            hintText: '0',
            labelStyle: TextStyle(fontSize: 14, color: C.accent),
            hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
            prefixIcon: Icon(Icons.fitness_center, color: C.accent),
            suffixText: 'STR',
            suffixStyle: TextStyle(fontSize: 14, color: C.accent),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: C.bgHover,
            contentPadding: const EdgeInsets.all(16),
          ),
          onChanged: (value) => viewModel.updateStrengthRequirement(int.tryParse(value)),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text(
            'Nachteil auf Verstecken (Stealth)',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          subtitle: const Text(
            'Das Item verursacht Nachteil auf Stealth-Checks',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          value: viewModel.item?.stealthDisadvantage ?? false,
          onChanged: (value) => viewModel.updateStealthDisadvantage(value),
          activeColor: C.accent,
          checkColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Color _getArmorCategoryColor(ArmorCategory category) {
    return switch (category) {
      ArmorCategory.Light => const Color(0xFF22C55E),
      ArmorCategory.Medium => const Color(0xFFEA580C),
      ArmorCategory.Heavy => const Color(0xFFEF4444),
    };
  }

  String _getArmorCategoryDexInfo(ArmorCategory category) {
    return switch (category) {
      ArmorCategory.Light => 'Leichte Rüstung: Volle Dexterity-Bonus auf AC anrechenbar',
      ArmorCategory.Medium => 'Mittlere Rüstung: Dexterity-Bonus auf AC, maximal +2',
      ArmorCategory.Heavy => 'Schwere Rüstung: Kein Dexterity-Bonus auf AC',
    };
  }

  Widget _buildMagicItemSpecificFields(EditItemViewModel viewModel) {
    final C = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.amber.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: C.amber, size: 20),
              const SizedBox(width: 16),
              Text(
                'Magische Eigenschaften',
                style: TextStyle(fontSize: 14, color: C.amber, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _rarityController,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Seltenheit',
            hintText: 'z.B. Uncommon, Rare, Very Rare, Legendary',
            labelStyle: TextStyle(fontSize: 14, color: C.amber),
            hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
            prefixIcon: Icon(Icons.stars, color: C.amber),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            filled: true,
            fillColor: C.bgHover,
            contentPadding: const EdgeInsets.all(16),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.auto_fix_high, color: Color(0xFF7C3AED), size: 20),
              SizedBox(width: 16),
              Text(
                'Magische Anforderung',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF7C3AED),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text(
            'Attunement erforderlich',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          subtitle: const Text(
            'Das Item erfordert eine kurze Ruhephase zur Bindung',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          value: viewModel.item?.requiresAttunement ?? false,
          onChanged: (value) => viewModel.updateRequiresAttunement(value),
          activeColor: const Color(0xFF7C3AED),
          checkColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
      ],
    );
  }

  Widget _buildDurabilitySection(EditItemViewModel viewModel) {
    final C = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: C.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: C.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(Icons.build_circle, color: C.green, size: 20),
              const SizedBox(width: 16),
              Text(
                'Haltbarkeit',
                style: TextStyle(fontSize: 14, color: C.green, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        CheckboxListTile(
          title: const Text(
            'Haltbarkeit aktivieren',
            style: TextStyle(fontSize: 14, color: Colors.white70),
          ),
          subtitle: const Text(
            'Das Item hat eine begrenzte Haltbarkeit',
            style: TextStyle(fontSize: 12, color: Colors.white54),
          ),
          value: viewModel.item?.hasDurability ?? false,
          onChanged: (value) => viewModel.updateHasDurability(value),
          activeColor: C.green,
          checkColor: Colors.white,
          contentPadding: EdgeInsets.zero,
          controlAffinity: ListTileControlAffinity.leading,
        ),
        if (viewModel.item?.hasDurability == true) ...[
          const SizedBox(height: 16),
          TextFormField(
            controller: _maxDurabilityController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16, color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Maximale Haltbarkeit',
              hintText: '0',
              labelStyle: TextStyle(fontSize: 14, color: C.green),
              hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
              prefixIcon: Icon(Icons.battery_charging_full, color: C.green),
              suffixText: 'HP',
              suffixStyle: TextStyle(fontSize: 14, color: C.green),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: C.bgHover,
              contentPadding: const EdgeInsets.all(16),
            ),
            onChanged: (value) => viewModel.updateMaxDurability(int.tryParse(value)),
          ),
          const SizedBox(height: 16),
          CheckboxListTile(
            title: const Text(
              'Reparierbar',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            subtitle: const Text(
              'Das Item kann repariert werden',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
            value: viewModel.item?.isRepairable ?? false,
            onChanged: (value) => viewModel.updateIsRepairable(value),
            activeColor: C.green,
            checkColor: Colors.white,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ],
    );
  }

  Widget _buildPropertiesSection(BuildContext context, EditItemViewModel viewModel) {
    final C = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: C.green.withValues(alpha: 0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(title: 'Eigenschaften', icon: Icons.edit_note_outlined),
            TextFormField(
              controller: _propertiesController,
              maxLines: 4,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Spezielle Eigenschaften',
                hintText: 'z.B. Magische Boni, Spezialfähigkeiten...',
                labelStyle: TextStyle(fontSize: 14, color: C.green),
                hintStyle: const TextStyle(fontSize: 14, color: Colors.white38),
                prefixIcon: Icon(Icons.star_outline, color: C.green),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: C.bgHover,
                contentPadding: const EdgeInsets.all(16),
              ),
              onChanged: (value) => viewModel.updateProperties(value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, EditItemViewModel viewModel) {
    final C = context.appColors;
    return Column(
      children: [
        if (viewModel.errorMessage != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: C.red.withValues(alpha: 0.2),
              border: Border.all(color: C.red, width: 2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: C.red, size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    viewModel.errorMessage!,
                    style: TextStyle(
                      fontSize: 16,
                      color: C.red,
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
                color: C.green,
                isLoading: viewModel.isLoading,
              ),
            ),
            const SizedBox(width: 24),
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
          const SizedBox(height: 24),
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
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.4),
      ),
      child: isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon),
                const SizedBox(width: 16),
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
        side: const BorderSide(color: Colors.white54, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildDangerButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
  }) {
    final C = context.appColors;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: C.red,
        side: BorderSide(color: C.red, width: 2),
        padding: const EdgeInsets.symmetric(vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  IconData _getItemTypeIcon(ItemType type) {
    return switch (type) {
      ItemType.Weapon => Icons.gavel,
      ItemType.Armor => Icons.shield,
      ItemType.Shield => Icons.shield_outlined,
      ItemType.Consumable => Icons.restaurant,
      ItemType.Tool => Icons.build,
      ItemType.Material => Icons.science,
      ItemType.Component => Icons.category,
      ItemType.MagicItem => Icons.auto_awesome,
      ItemType.Scroll => Icons.description,
      ItemType.Potion => Icons.local_drink,
      ItemType.Treasure => Icons.diamond,
      ItemType.Currency => Icons.monetization_on,
      ItemType.AdventuringGear => Icons.inventory_2,
      ItemType.SPELL_WEAPON => Icons.flare,
    };
  }

  String _getItemTypeDisplayName(ItemType type) {
    return switch (type) {
      ItemType.Weapon => 'Waffe',
      ItemType.Armor => 'Rüstung',
      ItemType.Shield => 'Schild',
      ItemType.Consumable => 'Verbrauchsgut',
      ItemType.Tool => 'Werkzeug',
      ItemType.Material => 'Material',
      ItemType.Component => 'Komponente',
      ItemType.MagicItem => 'Magisches Item',
      ItemType.Scroll => 'Schriftrolle',
      ItemType.Potion => 'Trank',
      ItemType.Treasure => 'Schatz',
      ItemType.Currency => 'Währung',
      ItemType.AdventuringGear => 'Ausrüstung',
      ItemType.SPELL_WEAPON => 'Spruch als Waffe',
    };
  }

  void _handleSave(EditItemViewModel viewModel) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await viewModel.saveItem();
      if (success && mounted) Navigator.of(context).pop(true);
    }
  }

  void _handleCancel(EditItemViewModel viewModel) async {
    if (viewModel.hasUnsavedChanges) {
      final shouldLeave = await _showUnsavedChangesDialog();
      if (shouldLeave == true && mounted) Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  void _handleDelete(EditItemViewModel viewModel) async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed == true && mounted) {
      final success = await viewModel.deleteItem();
      if (success && mounted) Navigator.of(context).pop(true);
    }
  }

  void _handleBackNavigation(EditItemViewModel viewModel) async {
    if (viewModel.hasUnsavedChanges) {
      final shouldLeave = await _showUnsavedChangesDialog();
      if (shouldLeave == true && mounted) Navigator.of(context).pop();
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showUnsavedChangesDialog() {
    final C = context.appColors;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Row(
          children: [
            const Icon(Icons.warning_amber_outlined, color: Color(0xFFEA580C), size: 28),
            const SizedBox(width: 16),
            const Text(
              'Ungespeicherte Änderungen',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Sie haben ungespeicherte Änderungen. Möchten Sie wirklich gehen?',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Color(0xFFEA580C)),
            child: const Text('VERLASSEN'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    final C = context.appColors;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: C.red, size: 28),
            const SizedBox(width: 16),
            const Text(
              'Löschen bestätigen',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Text(
          'Möchten Sie dieses Item wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            style: TextButton.styleFrom(foregroundColor: Colors.white70),
            child: const Text('ABBRECHEN'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: C.red),
            child: const Text('LÖSCHEN'),
          ),
        ],
      ),
    );
  }
}
