import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/edit_item_viewmodel.dart';

class EditItemScreen extends StatefulWidget {
  const EditItemScreen({super.key, this.item});

  final Item? item;

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
  Widget build(BuildContext context) => ChangeNotifierProvider<EditItemViewModel>.value(
    value: _viewModel,
    child: Consumer<EditItemViewModel>(
      builder: (context, vm, _) => Scaffold(
        backgroundColor: context.appColors.bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: _TopBar(
            vm: vm,
            onBack: () => _handleBackNavigation(vm),
            onSave: vm.isLoading ? null : () => _handleSave(vm),
          ),
        ),
        body: SafeArea(child: _buildBody(context, vm)),
      ),
    ),
  );

  Widget _buildBody(BuildContext context, EditItemViewModel vm) => LayoutBuilder(
    builder: (context, constraints) {
      final C = context.appColors;
      final isWide = constraints.maxWidth >= 600;
      final itemType = vm.item?.itemType ?? ItemType.Weapon;

      final basicCard = _EditorCard(title: 'Grundlegende Informationen', C: C, children: [
        _ThemedField(
          controller: _nameController,
          label: 'Item Name',
          hint: 'z.B. Langschwert +1',
          icon: Icons.shopping_bag_outlined,
          C: C,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Name ist erforderlich';
            }
            if (v.trim().length < 2) {
              return 'Name muss mindestens 2 Zeichen lang sein';
            }
            return null;
          },
          onChanged: vm.updateName,
        ),
        const SizedBox(height: 10),
        _ThemedField(
          controller: _descriptionController,
          label: 'Beschreibung',
          hint: 'Beschreibe das Item...',
          icon: Icons.description_outlined,
          maxLines: 3,
          C: C,
          onChanged: vm.updateDescription,
        ),
        const SizedBox(height: 10),
        _ThemedDropdown<ItemType>(
          label: 'Item Typ',
          selectedValue: vm.item?.itemType,
          icon: Icons.category_outlined,
          C: C,
          items: ItemType.values.map((t) => DropdownMenuItem(
            value: t,
            child: Row(children: [
              Icon(_getItemTypeIcon(t), color: C.textSoft, size: 16),
              const SizedBox(width: 8),
              Text(_getItemTypeDisplayName(t), style: TextStyle(color: C.text, fontSize: 14)),
            ]),
          )).toList(),
          onChanged: (v) {
            if (v != null) {
              vm.updateType(v);
            }
          },
        ),
      ]);

      final detailsCard = _EditorCard(title: 'Details', C: C, children: [
        Row(children: [
          Expanded(child: _ThemedField(
            controller: _costController,
            label: 'Wert (gp)',
            hint: '0',
            icon: Icons.monetization_on_outlined,
            suffix: 'gp',
            keyboardType: TextInputType.number,
            C: C,
            onChanged: (v) => vm.updateValue(double.tryParse(v) ?? 0.0),
          )),
          const SizedBox(width: 8),
          Expanded(child: _ThemedField(
            controller: _weightController,
            label: 'Gewicht (lbs)',
            hint: '0.0',
            icon: Icons.scale_outlined,
            suffix: 'lbs',
            keyboardType: TextInputType.number,
            C: C,
            onChanged: (v) => vm.updateWeight(double.tryParse(v) ?? 0.0),
          )),
        ]),
      ]);

      final advancedCard = _EditorCard(title: 'Erweiterte Optionen', C: C, children: [
        if (itemType == ItemType.Weapon) ...[
          _buildWeaponFields(vm, C),
          const SizedBox(height: 12),
        ],
        if (itemType == ItemType.Armor || itemType == ItemType.Shield) ...[
          _buildArmorFields(vm, C),
          const SizedBox(height: 12),
        ],
        if (itemType == ItemType.MagicItem) ...[
          _buildMagicItemFields(vm, C),
          const SizedBox(height: 12),
        ],
        _buildMagicPropertiesSection(vm, C),
        const SizedBox(height: 12),
        _buildDurabilitySection(vm, C),
      ]);

      final propertiesCard = _EditorCard(title: 'Eigenschaften', C: C, children: [
        _ThemedField(
          controller: _propertiesController,
          label: 'Spezielle Eigenschaften',
          hint: 'z.B. Magische Boni, Spezialfähigkeiten...',
          icon: Icons.star_outline,
          maxLines: 4,
          C: C,
          onChanged: vm.updateProperties,
        ),
      ]);

      final actionsWidget = _buildActionButtons(context, vm, C);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: isWide
              ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(children: [
                    basicCard,
                    const SizedBox(height: 12),
                    detailsCard,
                    const SizedBox(height: 12),
                    propertiesCard,
                  ])),
                  const SizedBox(width: 12),
                  Expanded(child: Column(children: [
                    advancedCard,
                    const SizedBox(height: 12),
                    actionsWidget,
                  ])),
                ])
              : Column(children: [
                  basicCard,
                  const SizedBox(height: 12),
                  detailsCard,
                  const SizedBox(height: 12),
                  advancedCard,
                  const SizedBox(height: 12),
                  propertiesCard,
                  const SizedBox(height: 12),
                  actionsWidget,
                  const SizedBox(height: 16),
                ]),
        ),
      );
    },
  );

  // ── TYPE-SPECIFIC FIELDS ─────────────────────────────────────────────────────

  Widget _buildWeaponFields(EditItemViewModel vm, AppColorsExtension C) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('WAFFE', style: TextStyle(fontSize: 10, color: C.textSoft, letterSpacing: 0.8, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _ThemedField(
        controller: _damageController,
        label: 'Schadenswurf',
        hint: 'z.B. 1d8, 2d6+3',
        icon: Icons.casino_outlined,
        C: C,
        onChanged: vm.updateDamage,
      ),
      const SizedBox(height: 8),
      _ThemedDropdown<String>(
        label: 'Schadenstyp',
        selectedValue: vm.item?.damageType,
        icon: Icons.whatshot_outlined,
        hint: 'Schadenstyp auswählen...',
        C: C,
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
        onChanged: vm.updateDamageType,
      ),
    ],
  );

  Widget _buildArmorFields(EditItemViewModel vm, AppColorsExtension C) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('RÜSTUNG', style: TextStyle(fontSize: 10, color: C.textSoft, letterSpacing: 0.8, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _ThemedDropdown<String>(
        label: 'Rüstungskategorie',
        selectedValue: vm.item?.armorCategory?.name,
        icon: Icons.category,
        hint: 'Kategorie auswählen...',
        C: C,
        items: const [
          DropdownMenuItem(value: 'Light', child: Text('Leichte Rüstung')),
          DropdownMenuItem(value: 'Medium', child: Text('Mittlere Rüstung')),
          DropdownMenuItem(value: 'Heavy', child: Text('Schwere Rüstung')),
        ],
        onChanged: (v) {
          if (v == null) {
            vm.updateArmorCategory(null);
          } else {
            final cat = ArmorCategory.values.firstWhere(
              (c) => c.name == v,
              orElse: () => ArmorCategory.Light,
            );
            vm.updateArmorCategory(cat);
          }
        },
      ),
      if (vm.item?.armorCategory != null) ...[
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: C.bgHover,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: C.border),
          ),
          child: Row(children: [
            Icon(Icons.info_outline, color: C.textSoft, size: 14),
            const SizedBox(width: 6),
            Expanded(child: Text(
              _getArmorCategoryDexInfo(vm.item!.armorCategory!),
              style: TextStyle(fontSize: 11, color: C.textSoft),
            )),
          ]),
        ),
      ],
      const SizedBox(height: 8),
      _ThemedField(
        controller: _acFormulaController,
        label: 'Rüstungsklasse (AC)',
        hint: 'z.B. 12 + Dex',
        icon: Icons.security,
        C: C,
        onChanged: vm.updateAcFormula,
      ),
      const SizedBox(height: 8),
      _ThemedField(
        controller: _strengthController,
        label: 'Stärkeanforderung',
        hint: '0',
        icon: Icons.fitness_center,
        suffix: 'STR',
        keyboardType: TextInputType.number,
        C: C,
        onChanged: (v) => vm.updateStrengthRequirement(int.tryParse(v)),
      ),
      const SizedBox(height: 4),
      _CheckRow(
        label: 'Nachteil auf Verstecken (Stealth)',
        subtitle: 'Verursacht Nachteil auf Stealth-Checks',
        value: vm.item?.stealthDisadvantage ?? false,
        onToggle: () => vm.updateStealthDisadvantage(!(vm.item?.stealthDisadvantage ?? false)),
        C: C,
      ),
    ],
  );

  Widget _buildMagicItemFields(EditItemViewModel vm, AppColorsExtension C) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('MAGISCHES ITEM', style: TextStyle(fontSize: 10, color: C.textSoft, letterSpacing: 0.8, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _ThemedField(
        controller: _rarityController,
        label: 'Seltenheit',
        hint: 'z.B. Uncommon, Rare, Very Rare, Legendary',
        icon: Icons.stars,
        C: C,
        onChanged: vm.updateRarity,
      ),
    ],
  );

  Widget _buildMagicPropertiesSection(EditItemViewModel vm, AppColorsExtension C) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('MAGISCHE ANFORDERUNG', style: TextStyle(fontSize: 10, color: C.textSoft, letterSpacing: 0.8, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _CheckRow(
        label: 'Attunement erforderlich',
        subtitle: 'Item erfordert eine kurze Ruhephase zur Bindung',
        value: vm.item?.requiresAttunement ?? false,
        onToggle: () => vm.updateRequiresAttunement(!(vm.item?.requiresAttunement ?? false)),
        C: C,
      ),
    ],
  );

  Widget _buildDurabilitySection(EditItemViewModel vm, AppColorsExtension C) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('HALTBARKEIT', style: TextStyle(fontSize: 10, color: C.textSoft, letterSpacing: 0.8, fontWeight: FontWeight.w600)),
      const SizedBox(height: 8),
      _CheckRow(
        label: 'Haltbarkeit aktivieren',
        subtitle: 'Das Item hat eine begrenzte Haltbarkeit',
        value: vm.item?.hasDurability ?? false,
        onToggle: () => vm.updateHasDurability(!(vm.item?.hasDurability ?? false)),
        C: C,
      ),
      if (vm.item?.hasDurability ?? false) ...[
        const SizedBox(height: 8),
        _ThemedField(
          controller: _maxDurabilityController,
          label: 'Maximale Haltbarkeit',
          hint: '0',
          icon: Icons.battery_charging_full,
          suffix: 'HP',
          keyboardType: TextInputType.number,
          C: C,
          onChanged: (v) => vm.updateMaxDurability(int.tryParse(v)),
        ),
        const SizedBox(height: 4),
        _CheckRow(
          label: 'Reparierbar',
          subtitle: 'Das Item kann repariert werden',
          value: vm.item?.isRepairable ?? false,
          onToggle: () => vm.updateIsRepairable(!(vm.item?.isRepairable ?? false)),
          C: C,
        ),
      ],
    ],
  );

  // ── ACTIONS ───────────────────────────────────────────────────────────────────

  Widget _buildActionButtons(BuildContext context, EditItemViewModel vm, AppColorsExtension C) =>
    Column(children: [
      if (vm.errorMessage != null) ...[
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(10),
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: C.red.withValues(alpha: 0.12),
            border: Border.all(color: C.red.withValues(alpha: 0.4)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.error_outline, color: C.red, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text(vm.errorMessage!, style: TextStyle(color: C.red, fontSize: 13))),
          ]),
        ),
      ],
      Row(children: [
        Expanded(child: _SaveBtn(
          label: 'Speichern',
          icon: Icons.save,
          color: C.green,
          isLoading: vm.isLoading,
          onPressed: vm.isLoading ? null : () => _handleSave(vm),
          C: C,
        )),
        const SizedBox(width: 8),
        Expanded(child: _OutlineBtn(
          label: 'Abbrechen',
          icon: Icons.close,
          onPressed: vm.isLoading ? null : () => _handleCancel(vm),
          C: C,
        )),
      ]),
      if (vm.item != null) ...[
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: _OutlineBtn(
            label: 'Item löschen',
            icon: Icons.delete_forever,
            color: C.red,
            onPressed: vm.isLoading ? null : () => _handleDelete(vm),
            C: C,
          ),
        ),
      ],
    ]);

  // ── HELPERS ───────────────────────────────────────────────────────────────────

  String _getArmorCategoryDexInfo(ArmorCategory category) => switch (category) {
    ArmorCategory.Light => 'Leichte Rüstung: Voller Dexterity-Bonus auf AC',
    ArmorCategory.Medium => 'Mittlere Rüstung: Dexterity-Bonus auf AC, maximal +2',
    ArmorCategory.Heavy => 'Schwere Rüstung: Kein Dexterity-Bonus auf AC',
  };

  IconData _getItemTypeIcon(ItemType type) => switch (type) {
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

  String _getItemTypeDisplayName(ItemType type) => switch (type) {
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

  // ── NAVIGATION HANDLERS ───────────────────────────────────────────────────────

  Future<void> _handleSave(EditItemViewModel vm) async {
    if (_formKey.currentState?.validate() ?? false) {
      final success = await vm.saveItem();
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _handleCancel(EditItemViewModel vm) async {
    if (vm.hasUnsavedChanges) {
      final shouldLeave = await _showUnsavedChangesDialog();
      if ((shouldLeave ?? false) && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handleDelete(EditItemViewModel vm) async {
    final confirmed = await _showDeleteConfirmationDialog();
    if (confirmed ?? false) {
      final success = await vm.deleteItem();
      if (success && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _handleBackNavigation(EditItemViewModel vm) async {
    if (vm.hasUnsavedChanges) {
      final shouldLeave = await _showUnsavedChangesDialog();
      if ((shouldLeave ?? false) && mounted) {
        Navigator.of(context).pop();
      }
    } else {
      Navigator.of(context).pop();
    }
  }

  Future<bool?> _showUnsavedChangesDialog() {
    final C = context.appColors;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Row(children: [
          Icon(Icons.warning_amber_outlined, color: C.amber, size: 24),
          const SizedBox(width: 12),
          Text('Ungespeicherte Änderungen',
              style: TextStyle(color: C.text, fontSize: 17, fontWeight: FontWeight.w600)),
        ]),
        content: Text(
          'Sie haben ungespeicherte Änderungen. Möchten Sie wirklich gehen?',
          style: TextStyle(fontSize: 14, color: C.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: C.textMid),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: C.amber),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _showDeleteConfirmationDialog() {
    final C = context.appColors;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Row(children: [
          Icon(Icons.delete_forever, color: C.red, size: 24),
          const SizedBox(width: 12),
          Text('Löschen bestätigen',
              style: TextStyle(color: C.text, fontSize: 17, fontWeight: FontWeight.w600)),
        ]),
        content: Text(
          'Möchten Sie dieses Item wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(fontSize: 14, color: C.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            style: TextButton.styleFrom(foregroundColor: C.textMid),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: C.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

// ── TOP BAR ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({required this.vm, required this.onBack, required this.onSave});

  final EditItemViewModel vm;
  final VoidCallback onBack;
  final VoidCallback? onSave;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Row(children: [
        const SizedBox(width: 4),
        _IconBtn(icon: Icons.arrow_back_ios_new, onTap: onBack, C: C),
        const SizedBox(width: 8),
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: C.amber.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(6),
          ),
          alignment: Alignment.center,
          child: Icon(Icons.inventory_2_outlined, color: C.amber, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(
          vm.item == null ? 'Neues Item' : 'Item bearbeiten',
          style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 15),
          overflow: TextOverflow.ellipsis,
        )),
        if (vm.hasUnsavedChanges) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: C.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: C.amber.withValues(alpha: 0.3)),
            ),
            child: Text('Bearbeitet',
                style: TextStyle(color: C.amber, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
          const SizedBox(width: 8),
        ],
        if (onSave != null)
          GestureDetector(
            onTap: onSave,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: C.accent,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: const Text(
                'Speichern',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        const SizedBox(width: 4),
      ]),
    );
  }
}

// ── PRIVATE WIDGETS ───────────────────────────────────────────────────────────

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.title, required this.C, required this.children});

  final String title;
  final AppColorsExtension C;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: C.bgPanel,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: C.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(
        title.toUpperCase(),
        style: TextStyle(fontSize: 10, color: C.textSoft, letterSpacing: 1, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 10),
      ...children,
    ]),
  );
}

class _ThemedField extends StatelessWidget {
  const _ThemedField({
    required this.controller,
    required this.label,
    required this.icon,
    required this.C,
    required this.onChanged,
    this.hint,
    this.suffix,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? suffix;
  final IconData icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final AppColorsExtension C;
  final void Function(String) onChanged;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    keyboardType: keyboardType,
    style: TextStyle(fontSize: 14, color: C.text),
    decoration: InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(fontSize: 12, color: C.textSoft),
      hintStyle: TextStyle(fontSize: 13, color: C.textSoft.withValues(alpha: 0.5)),
      prefixIcon: Icon(icon, color: C.textSoft, size: 18),
      suffixText: suffix,
      suffixStyle: TextStyle(fontSize: 12, color: C.textSoft),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: C.accent)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: C.red)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: C.red)),
      filled: true,
      fillColor: C.bgHover,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
    validator: validator,
    onChanged: onChanged,
  );
}

class _ThemedDropdown<T> extends StatelessWidget {
  const _ThemedDropdown({
    required this.label,
    required this.selectedValue,
    required this.icon,
    required this.C,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final String label;
  final T? selectedValue;
  final String? hint;
  final IconData icon;
  final AppColorsExtension C;
  final List<DropdownMenuItem<T>> items;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    initialValue: selectedValue,
    dropdownColor: C.bgPanel,
    style: TextStyle(fontSize: 14, color: C.text),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(fontSize: 12, color: C.textSoft),
      prefixIcon: Icon(icon, color: C.textSoft, size: 18),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: C.border)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: C.border)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6), borderSide: BorderSide(color: C.accent)),
      filled: true,
      fillColor: C.bgHover,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      isDense: true,
    ),
    hint: hint != null
        ? Text(hint!, style: TextStyle(color: C.textSoft.withValues(alpha: 0.6), fontSize: 13))
        : null,
    items: items,
    onChanged: onChanged,
  );
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.label,
    required this.value,
    required this.onToggle,
    required this.C,
    this.subtitle,
  });

  final String label;
  final String? subtitle;
  final bool value;
  final VoidCallback onToggle;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onToggle,
    borderRadius: BorderRadius.circular(6),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: value ? C.accent : Colors.transparent,
            border: Border.all(color: value ? C.accent : C.border, width: 1.5),
            borderRadius: BorderRadius.circular(3),
          ),
          child: value ? const Icon(Icons.check, size: 11, color: Colors.white) : null,
        ),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: C.text, fontSize: 13)),
          if (subtitle != null)
            Text(subtitle!, style: TextStyle(color: C.textSoft, fontSize: 11)),
        ])),
      ]),
    ),
  );
}

class _SaveBtn extends StatelessWidget {
  const _SaveBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.C,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final AppColorsExtension C;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onPressed,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: onPressed != null ? color : C.bgHover,
        borderRadius: BorderRadius.circular(6),
      ),
      alignment: Alignment.center,
      child: isLoading
          ? SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(color: C.text, strokeWidth: 2))
          : Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ]),
    ),
  );
}

class _OutlineBtn extends StatelessWidget {
  const _OutlineBtn({
    required this.label,
    required this.icon,
    required this.C,
    required this.onPressed,
    this.color,
  });

  final String label;
  final IconData icon;
  final AppColorsExtension C;
  final VoidCallback? onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final clr = color ?? C.textMid;
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: clr.withValues(alpha: onPressed != null ? 0.5 : 0.2)),
        ),
        alignment: Alignment.center,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: onPressed != null ? clr : C.textSoft, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: onPressed != null ? clr : C.textSoft,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap, required this.C});

  final IconData icon;
  final VoidCallback onTap;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: SizedBox(
      width: 36,
      height: 36,
      child: Icon(icon, color: C.textMid, size: 18),
    ),
  );
}
