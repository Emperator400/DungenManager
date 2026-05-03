import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../game_data/dnd_logic.dart';
import '../../models/creature.dart';
import '../../models/official_monster.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/edit_creature_viewmodel.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/forms/form_field_widget.dart';
import '../../widgets/ui_components/inventory/creature_inventory_widget.dart';
import '../../widgets/ui_components/stats/attributes_section_widget.dart';
import '../bestiary/official_monsters_screen.dart';

// ── CONSTANTS ─────────────────────────────────────────────────────────────────

const _kTabs = [
  (Icons.pets,           'Grunddaten'),
  (Icons.fitness_center, 'Attribute'),
  (Icons.auto_awesome,   'Fähigkeiten'),
  (Icons.inventory,      'Inventar'),
];

const _kAmber = Color(0xFFD97706);

const _attrColors = [
  Color(0xFFC93A3A), // STÄ
  Color(0xFF1A7F4B), // GES
  Color(0xFFD4890A), // KON
  Color(0xFF2F6FEB), // INT
  Color(0xFF7C3AED), // WEI
  Color(0xFFBE185D), // CHA
];

const _attrLabels = [
  'Stärke', 'Geschicklichkeit', 'Konstitution',
  'Intelligenz', 'Weisheit', 'Charisma',
];

// ── SCREEN ────────────────────────────────────────────────────────────────────

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
    if (monster.legendaryActions != null && monster.legendaryActions!.isNotEmpty) {
      _viewModel.updateLegendaryActions(
        monster.legendaryActions!.map((a) => '${a.name}: ${a.description}').join('\n\n'),
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
          backgroundColor: context.appColors.bg,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Consumer<EditCreatureViewModel>(
              builder: (context, vm, _) => AnimatedBuilder(
                animation: _tabController,
                builder: (_, __) => _TopBar(
                  vm: vm,
                  tabIndex: _tabController.index,
                  onTabTap: _tabController.animateTo,
                  onBack: () async {
                    final pop = await _onWillPop();
                    if (pop && mounted) Navigator.of(context).pop();
                  },
                  onSave: _saveCreature,
                  onImport: _importFromOfficialMonster,
                ),
              ),
            ),
          ),
          body: Consumer<EditCreatureViewModel>(
            builder: (context, vm, _) {
              if (vm.error != null) return _buildErrorState(vm);
              return TabBarView(
                key: ValueKey<bool>(_isInitialized),
                controller: _tabController,
                children: [
                  _buildGrunddatenTab(vm),
                  _buildAttributeTab(vm),
                  _buildFaehigkeitenTab(vm),
                  _buildInventarTab(vm),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  // ── ERROR STATE ─────────────────────────────────────────────────────────────

  Widget _buildErrorState(EditCreatureViewModel vm) {
    final C = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: C.red, size: 64),
          const SizedBox(height: 16),
          Text('Fehler', style: TextStyle(color: C.red, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(vm.error!, style: TextStyle(color: C.textMid), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () { vm.clearError(); _initializeViewModel(); },
            icon: const Icon(Icons.refresh),
            label: const Text('Erneut versuchen'),
            style: ElevatedButton.styleFrom(backgroundColor: C.accent, foregroundColor: Colors.white),
          ),
        ]),
      ),
    );
  }

  // ── TAB: GRUNDDATEN ─────────────────────────────────────────────────────────

  Widget _buildGrunddatenTab(EditCreatureViewModel vm) {
    return LayoutBuilder(builder: (context, constraints) {
      final C = context.appColors;
      final isWide = constraints.maxWidth >= 600;

      final left = <Widget>[
        _EditorCard(title: 'Kreatur', C: C, children: [
          FormFieldWidget(
            label: 'Name',
            value: vm.name,
            onChanged: vm.updateName,
            icon: Icons.pets,
          ),
          const SizedBox(height: 12),
          FormFieldWidget(
            label: 'Beschreibung',
            value: vm.description ?? '',
            onChanged: vm.updateDescription,
            icon: Icons.description,
            maxLines: 3,
          ),
        ]),
        const SizedBox(height: 12),
        _EditorCard(title: 'Typ & Herkunft', C: C, children: [
          Row(children: [
            Expanded(child: FormFieldWidget(
              label: 'Größe',
              value: vm.size ?? '',
              onChanged: vm.updateSize,
              icon: Icons.straighten,
            )),
            const SizedBox(width: 12),
            Expanded(child: FormFieldWidget(
              label: 'Typ',
              value: vm.type ?? '',
              onChanged: vm.updateType,
              icon: Icons.category,
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FormFieldWidget(
              label: 'Subtyp',
              value: vm.subtype ?? '',
              onChanged: (v) => vm.updateSubtype(v.isEmpty ? null : v),
              icon: Icons.layers,
            )),
            const SizedBox(width: 12),
            Expanded(child: FormFieldWidget(
              label: 'Ausrichtung',
              value: vm.alignment ?? '',
              onChanged: vm.updateAlignment,
              icon: Icons.compass_calibration,
            )),
          ]),
        ]),
      ];

      final right = <Widget>[
        _EditorCard(title: 'Kampfwerte', C: C, children: [
          Row(children: [
            Expanded(child: _NumField(
              label: 'Max HP',
              value: vm.maxHp,
              icon: Icons.favorite,
              onChanged: vm.updateMaxHp,
            )),
            const SizedBox(width: 8),
            Expanded(child: _NumField(
              label: 'Rüstungsklasse',
              value: vm.armorClass,
              icon: Icons.security,
              onChanged: vm.updateArmorClass,
            )),
            const SizedBox(width: 8),
            Expanded(child: _NumField(
              label: 'Herausforderung',
              value: vm.challengeRating,
              icon: Icons.star,
              onChanged: (v) => vm.updateChallengeRating(v),
            )),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _StatDisplay(
              label: 'INITIATIVE',
              value: vm.initiativeBonus >= 0
                  ? '+${vm.initiativeBonus}'
                  : '${vm.initiativeBonus}',
              sub: 'aus GES-Mod',
              valueColor: _kAmber,
              C: C,
            )),
            const SizedBox(width: 8),
            Expanded(child: _StatDisplay(
              label: 'HERAUSFORDERUNG',
              value: 'CR ${vm.challengeRating}',
              sub: 'Challenge Rating',
              valueColor: C.red,
              C: C,
            )),
          ]),
        ]),
        const SizedBox(height: 12),
        _EditorCard(title: 'Bewegung', C: C, children: [
          FormFieldWidget(
            label: 'Geschwindigkeit',
            value: vm.speed,
            onChanged: vm.updateSpeed,
            icon: Icons.directions_run,
          ),
        ]),
        const SizedBox(height: 12),
        _buildCurrencyCard(vm, C),
      ];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(children: left)),
                const SizedBox(width: 12),
                Expanded(child: Column(children: right)),
              ])
            : Column(children: [...left, const SizedBox(height: 12), ...right]),
      );
    });
  }

  // ── TAB: ATTRIBUTE ──────────────────────────────────────────────────────────

  Widget _buildAttributeTab(EditCreatureViewModel vm) {
    return LayoutBuilder(builder: (context, constraints) {
      final C = context.appColors;
      final isWide = constraints.maxWidth >= 600;

      final left = <Widget>[
        _EditorCard(title: 'Attributspunkte', C: C, children: [
          AttributesSectionWidget(
            strength: vm.strength,
            dexterity: vm.dexterity,
            constitution: vm.constitution,
            intelligence: vm.intelligence,
            wisdom: vm.wisdom,
            charisma: vm.charisma,
            onStrengthChanged: vm.updateStrength,
            onDexterityChanged: vm.updateDexterity,
            onConstitutionChanged: vm.updateConstitution,
            onIntelligenceChanged: vm.updateIntelligence,
            onWisdomChanged: vm.updateWisdom,
            onCharismaChanged: vm.updateCharisma,
            useSectionCard: false,
            title: '',
          ),
        ]),
      ];

      final values = [
        vm.strength, vm.dexterity, vm.constitution,
        vm.intelligence, vm.wisdom, vm.charisma,
      ];

      final right = <Widget>[
        _EditorCard(title: 'Modifier Übersicht', C: C, children: [
          for (int i = 0; i < 6; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: _attrColors[i].withValues(alpha: 0.08),
                border: Border.all(color: _attrColors[i].withValues(alpha: 0.18)),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(children: [
                Container(
                  width: 6, height: 6,
                  decoration: BoxDecoration(color: _attrColors[i], shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(_attrLabels[i], style: TextStyle(color: C.textMid, fontSize: 12))),
                Text('${values[i]}', style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    getModifier(values[i]) >= 0 ? '+${getModifier(values[i])}' : '${getModifier(values[i])}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: getModifier(values[i]) >= 0 ? C.green : C.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ]),
            ),
            if (i < 5) const SizedBox(height: 6),
          ],
        ]),
        const SizedBox(height: 12),
        _EditorCard(title: 'Initiative', C: C, children: [
          Row(children: [
            Expanded(child: _NumField(
              label: 'Initiative Bonus',
              value: vm.initiativeBonus,
              icon: Icons.speed,
              onChanged: vm.updateInitiativeBonus,
            )),
            const SizedBox(width: 12),
            Expanded(child: _StatDisplay(
              label: 'GESAMT',
              value: vm.initiativeBonus >= 0 ? '+${vm.initiativeBonus}' : '${vm.initiativeBonus}',
              sub: 'Initiative',
              valueColor: _kAmber,
              C: C,
            )),
          ]),
        ]),
      ];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(children: left)),
                const SizedBox(width: 12),
                Expanded(child: Column(children: right)),
              ])
            : Column(children: [...left, const SizedBox(height: 12), ...right]),
      );
    });
  }

  // ── TAB: FÄHIGKEITEN ────────────────────────────────────────────────────────

  Widget _buildFaehigkeitenTab(EditCreatureViewModel vm) {
    return LayoutBuilder(builder: (context, constraints) {
      final C = context.appColors;
      final isWide = constraints.maxWidth >= 600;

      final left = <Widget>[
        _EditorCard(title: 'Angriffe', C: C, children: [
          FormFieldWidget(
            label: 'Angriffe & Schadenswürfel',
            value: vm.attacks,
            onChanged: vm.updateAttacks,
            icon: Icons.gavel,
            maxLines: 5,
          ),
        ]),
        const SizedBox(height: 12),
        _EditorCard(title: 'Spezielle Fähigkeiten', C: C, children: [
          FormFieldWidget(
            label: 'Passive Fähigkeiten, Resistenzen...',
            value: vm.specialAbilities ?? '',
            onChanged: (v) => vm.updateSpecialAbilities(v.isEmpty ? null : v),
            icon: Icons.auto_awesome,
            maxLines: 5,
          ),
        ]),
      ];

      final right = <Widget>[
        _EditorCard(title: 'Legendäre Aktionen', C: C, children: [
          FormFieldWidget(
            label: 'Legendäre Aktionen & Reaktionen',
            value: vm.legendaryActions ?? '',
            onChanged: (v) => vm.updateLegendaryActions(v.isEmpty ? null : v),
            icon: Icons.star,
            maxLines: 5,
          ),
        ]),
        const SizedBox(height: 12),
        _buildCurrencyCard(vm, C),
      ];

      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: isWide
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(child: Column(children: left)),
                const SizedBox(width: 12),
                Expanded(child: Column(children: right)),
              ])
            : Column(children: [...left, const SizedBox(height: 12), ...right]),
      );
    });
  }

  // ── TAB: INVENTAR ───────────────────────────────────────────────────────────

  Widget _buildInventarTab(EditCreatureViewModel vm) {
    final C = context.appColors;
    if (!vm.isEditing) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: _kAmber.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('Inventar', style: TextStyle(color: C.amber, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              'Speichere die Kreatur zuerst,\nbevor du Inventar verwalten kannst.',
              style: TextStyle(color: C.textMid),
              textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
    }
    return CreatureInventoryWidget(
      mapItems: vm.inventory,
      onAddItem: () => _showAddItemDialog(vm),
      onRemoveItem: (index) => vm.removeInventoryItem(index),
      onEditItem: (index, item) => _showEditItemDialog(vm, index),
      showAddButton: true,
    );
  }

  // ── SHARED WIDGETS ──────────────────────────────────────────────────────────

  Widget _buildCurrencyCard(EditCreatureViewModel vm, AppColorsExtension C) {
    return _EditorCard(title: 'Währung', C: C, children: [
      Row(children: [
        Expanded(child: _NumDoubleField(label: 'Gold', value: vm.gold, icon: Icons.monetization_on, color: _kAmber, onChanged: vm.updateGold)),
        const SizedBox(width: 8),
        Expanded(child: _NumDoubleField(label: 'Silber', value: vm.silver, icon: Icons.monetization_on, color: C.textMid, onChanged: vm.updateSilver)),
        const SizedBox(width: 8),
        Expanded(child: _NumDoubleField(label: 'Kupfer', value: vm.copper, icon: Icons.monetization_on, color: C.textSoft, onChanged: vm.updateCopper)),
      ]),
    ]);
  }

  // ── ITEM DIALOGS ────────────────────────────────────────────────────────────

  void _showAddItemDialog(EditCreatureViewModel vm) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final C = context.appColors;

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Item hinzufügen',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
              const SizedBox(height: 14),
              _dialogField(ctx, nameCtrl, 'Name', 'z.B. Schwert'),
              const SizedBox(height: 10),
              _dialogField(ctx, descCtrl, 'Beschreibung (optional)', '', maxLines: 3),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Abbrechen', style: TextStyle(color: C.textMid, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isNotEmpty) {
                        vm.addInventoryItem({'name': nameCtrl.text.trim(), 'description': descCtrl.text.trim()});
                        Navigator.of(ctx).pop();
                      }
                    },
                    style: FilledButton.styleFrom(backgroundColor: C.accent),
                    child: const Text('Hinzufügen', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditItemDialog(EditCreatureViewModel vm, int index) {
    final item = vm.inventory[index];
    final nameCtrl = TextEditingController(text: item['name']?.toString() ?? '');
    final descCtrl = TextEditingController(text: item['description']?.toString() ?? '');
    final C = context.appColors;

    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Item bearbeiten',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
              const SizedBox(height: 14),
              _dialogField(ctx, nameCtrl, 'Name', 'z.B. Schwert'),
              const SizedBox(height: 10),
              _dialogField(ctx, descCtrl, 'Beschreibung (optional)', '', maxLines: 3),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('Abbrechen', style: TextStyle(color: C.textMid, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      if (nameCtrl.text.trim().isNotEmpty) {
                        vm.updateInventoryItem(index, {
                          'name': nameCtrl.text.trim(),
                          'description': descCtrl.text.trim(),
                        });
                        Navigator.of(ctx).pop();
                      }
                    },
                    style: FilledButton.styleFrom(backgroundColor: C.accent),
                    child: const Text('Speichern', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dialogField(
    BuildContext ctx,
    TextEditingController ctrl,
    String label,
    String hint, {
    int maxLines = 1,
  }) {
    final C = ctx.appColors;
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: TextStyle(fontSize: 13, color: C.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(fontSize: 12, color: C.textMid),
        hintStyle: TextStyle(fontSize: 12, color: C.textSoft),
        filled: true,
        fillColor: C.bgHover,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: C.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: C.accent)),
      ),
    );
  }

  // ── SAVE / NAVIGATION ───────────────────────────────────────────────────────

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
          _viewModel.isEditing ? 'Kreatur aktualisiert' : 'Neue Kreatur erstellt',
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler beim Speichern: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (!_viewModel.isEditing) return true;
    final C = context.appColors;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text('Ungespeicherte Änderungen',
            style: TextStyle(color: C.amber, fontSize: 18, fontWeight: FontWeight.bold)),
        content: Text('Möchtest du wirklich ohne Speichern gehen?',
            style: TextStyle(color: C.textMid)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Abbrechen', style: TextStyle(color: C.accent)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: C.red, foregroundColor: Colors.white),
            child: const Text('Verlassen'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}

// ── TOP BAR ───────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.vm,
    required this.tabIndex,
    required this.onTabTap,
    required this.onBack,
    required this.onSave,
    required this.onImport,
  });

  final EditCreatureViewModel vm;
  final int tabIndex;
  final ValueChanged<int> onTabTap;
  final VoidCallback onBack;
  final VoidCallback onSave;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final creatureName = vm.name.isEmpty ? (vm.isEditing ? 'Kreatur bearbeiten' : 'Neue Kreatur') : vm.name;

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
            child: Row(children: [
              _IconBtn(icon: Icons.arrow_back, color: C.textMid, onTap: onBack),
              Container(width: 1, height: 18, color: C.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
              Container(
                width: 28, height: 28,
                decoration: BoxDecoration(
                  color: _kAmber.withValues(alpha: 0.18),
                  border: Border.all(color: _kAmber.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: const Center(child: Icon(Icons.pets, size: 14, color: _kAmber)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(creatureName,
                      style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13, height: 1.1),
                      overflow: TextOverflow.ellipsis),
                  Text(
                    vm.isEditing ? 'Kreatur bearbeiten' : 'Neue Kreatur',
                    style: TextStyle(color: C.textSoft, fontSize: 10, height: 1.1),
                  ),
                ],
              ),
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
                            isActive: tabIndex == i,
                            onTap: () => onTabTap(i),
                            C: C,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _IconBtn(icon: Icons.download_outlined, color: C.accent, onTap: onImport),
              const SizedBox(width: 8),
              _SaveBtn(isSaving: vm.isSaving, canSave: vm.canSave, onSave: onSave, C: C),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── PRIVATE WIDGETS ───────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.icon, required this.label, required this.isActive, required this.onTap, required this.C});

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
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: isActive ? C.accent : C.textSoft),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            color: isActive ? C.text : C.textMid,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
          )),
        ]),
      ),
    );
  }
}

class _SaveBtn extends StatelessWidget {
  const _SaveBtn({required this.isSaving, required this.canSave, required this.onSave, required this.C});

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
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.save, size: 13, color: canSave ? Colors.white : C.textSoft),
                const SizedBox(width: 5),
                Text('Speichern', style: TextStyle(
                  color: canSave ? Colors.white : C.textSoft,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                )),
              ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 30, height: 30, child: Icon(icon, size: 18, color: color)),
    );
  }
}

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.title, required this.C, required this.children});

  final String title;
  final AppColorsExtension C;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title.toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textMid, letterSpacing: 0.4)),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _NumField extends StatelessWidget {
  const _NumField({required this.label, required this.value, required this.icon, required this.onChanged});

  final String label;
  final int value;
  final IconData icon;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return FormFieldWidget(
      label: label,
      value: value.toString(),
      onChanged: (v) => onChanged(int.tryParse(v) ?? value),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      icon: icon,
    );
  }
}

class _NumDoubleField extends StatelessWidget {
  const _NumDoubleField({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return TextField(
      controller: TextEditingController(text: value == 0 ? '' : value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
      style: TextStyle(fontSize: 13, color: C.text),
      onChanged: (v) => onChanged(double.tryParse(v) ?? value),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 12, color: C.textMid),
        prefixIcon: Icon(icon, size: 14, color: color),
        filled: true,
        fillColor: C.bgHover,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: C.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: C.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7), borderSide: BorderSide(color: C.accent)),
      ),
    );
  }
}

class _StatDisplay extends StatelessWidget {
  const _StatDisplay({required this.label, required this.value, required this.sub, required this.valueColor, required this.C});

  final String label;
  final String value;
  final String sub;
  final Color valueColor;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: C.bgHover, border: Border.all(color: C.border), borderRadius: BorderRadius.circular(7)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(fontSize: 10, color: C.textSoft, letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: valueColor)),
        Text(sub, style: TextStyle(fontSize: 10, color: C.textSoft)),
      ]),
    );
  }
}
