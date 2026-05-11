import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../database/core/database_connection.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../game_data/dnd_logic.dart';
import '../../game_data/dnd_models.dart';
import '../../game_data/game_data.dart';
import '../../models/player_character.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/edit_pc_viewmodel.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/forms/form_field_widget.dart';
import '../../widgets/ui_components/inventory/unified_character_inventory_widget.dart';
import '../../widgets/ui_components/stats/attributes_section_widget.dart';
import '../../widgets/ui_components/stats/combat_stats_widget.dart';
import '../items/add_item_screen.dart';

const Map<String, Color> _klasseColor = {
  'Barbar': Color(0xFFC93A3A), 'Barde': Color(0xFF7C3AED),
  'Kleriker': Color(0xFFD4890A), 'Druide': Color(0xFF1A7F4B),
  'Kämpfer': Color(0xFF6B6B66), 'Mönch': Color(0xFF0891B2),
  'Paladin': Color(0xFF2F6FEB), 'Waldläufer': Color(0xFF065F46),
  'Schurke': Color(0xFF4A4A4A), 'Zauberer': Color(0xFFBE185D),
  'Hexenmeister': Color(0xFF4A235A), 'Magier': Color(0xFF1B4F72),
};

const _attrColors = [
  Color(0xFFC93A3A), // STÄ
  Color(0xFF1A7F4B), // GES
  Color(0xFFD4890A), // KON
  Color(0xFF2F6FEB), // INT
  Color(0xFF7C3AED), // WEI
  Color(0xFFBE185D), // CHA
];

int _abilityVal(EditPCViewModel vm, Ability ability) => switch (ability) {
      Ability.strength => vm.strength,
      Ability.dexterity => vm.dexterity,
      Ability.constitution => vm.constitution,
      Ability.intelligence => vm.intelligence,
      Ability.wisdom => vm.wisdom,
      Ability.charisma => vm.charisma,
    };

String _abilityAbbr(Ability ability) => switch (ability) {
      Ability.strength => 'STÄ',
      Ability.dexterity => 'GES',
      Ability.constitution => 'KON',
      Ability.intelligence => 'INT',
      Ability.wisdom => 'WEI',
      Ability.charisma => 'CHA',
    };

class EditPCScreen extends StatefulWidget {
  const EditPCScreen({
    required this.campaignId,
    super.key,
    this.pcToEdit,
  });

  final String campaignId;
  final PlayerCharacter? pcToEdit;

  @override
  State<EditPCScreen> createState() => _EditPCScreenState();
}

class _EditPCScreenState extends State<EditPCScreen>
    with SingleTickerProviderStateMixin {
  late EditPCViewModel _viewModel;
  late TabController _tabController;
  bool _isInitialized = false;

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
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _initializeViewModel() async {
    try {
      await _viewModel.initialize(widget.campaignId, widget.pcToEdit);
      if (mounted) setState(() => _isInitialized = true);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler beim Initialisieren: $e');
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return ChangeNotifierProvider<EditPCViewModel>.value(
      value: _viewModel,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) Navigator.of(context).pop();
        },
        child: Scaffold(
          backgroundColor: ctx.appColors.bg,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(52),
            child: Consumer<EditPCViewModel>(
              builder: (context, vm, _) => AnimatedBuilder(
                animation: _tabController,
                builder: (context, _) => _TopBar(
                  vm: vm,
                  tabIndex: _tabController.index,
                  onTabTap: _tabController.animateTo,
                  onBack: () async {
                    final pop = await _onWillPop();
                    if (pop && mounted) Navigator.of(context).pop();
                  },
                  onSave: _saveCharacter,
                ),
              ),
            ),
          ),
          body: Consumer<EditPCViewModel>(
            builder: (context, vm, _) {
              if (vm.error != null) return _buildErrorState(vm);
              return TabBarView(
                key: ValueKey<bool>(_isInitialized),
                controller: _tabController,
                children: [
                  _buildStammdatenTab(vm),
                  _buildAttributeTab(vm),
                  _buildDnDTab(vm),
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

  Widget _buildErrorState(EditPCViewModel vm) {
    final C = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline, color: C.red, size: 64),
          const SizedBox(height: 16),
          Text('Fehler', style: TextStyle(color: C.red, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(vm.error!, style: const TextStyle(color: Colors.white70), textAlign: TextAlign.center),
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

  // ── TAB: STAMMDATEN ─────────────────────────────────────────────────────────

  Widget _buildStammdatenTab(EditPCViewModel vm) {
    return LayoutBuilder(builder: (context, constraints) {
      final C = context.appColors;
      final isWide = constraints.maxWidth >= 600;

      final left = <Widget>[
        _EditorCard(title: 'Charakter', C: C, children: [
          FormFieldWidget(label: 'Name des Charakters', value: vm.name, onChanged: vm.updateName, icon: Icons.person),
          const SizedBox(height: 12),
          if (vm.availablePlayers.isNotEmpty) ...[
            _PlayerPickerField(vm: vm, C: C),
            const SizedBox(height: 12),
          ],
          FormFieldWidget(label: 'Name des Spielers', value: vm.playerName, onChanged: vm.updatePlayerName, icon: Icons.person_outline),
        ]),
        const SizedBox(height: 12),
        _EditorCard(title: 'Klasse & Rasse', C: C, children: [
          DropdownFormFieldWidget<DndClass>(
            label: 'Klasse', value: vm.selectedClass, items: allDndClasses,
            onChanged: vm.updateClass, icon: Icons.shield, itemLabelBuilder: (c) => c.name,
          ),
          const SizedBox(height: 12),
          DropdownFormFieldWidget<DndRace>(
            label: 'Rasse', value: vm.selectedRace, items: allDndRaces,
            onChanged: vm.updateRace, icon: Icons.public, itemLabelBuilder: (r) => r.name,
          ),
        ]),
        const SizedBox(height: 12),
        _buildSkillsCard(vm, C),
      ];

      final right = <Widget>[
        _buildCombatStatsCard(vm, C),
        const SizedBox(height: 12),
        _buildSavingThrowsCard(vm, C),
        const SizedBox(height: 12),
        _EditorCard(title: 'Währung', C: C, children: [
          CurrencyWidget(gold: vm.gold, silver: vm.silver, copper: vm.copper),
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

  Widget _buildSkillsCard(EditPCViewModel vm, AppColorsExtension C) {
    return _EditorCard(
      title: 'Fertigkeiten',
      C: C,
      children: allDndSkills.map((skill) {
        final isProficient = vm.proficientSkills.contains(skill.name);
        final abilityValue = _abilityVal(vm, skill.ability);
        final mod = getModifier(abilityValue);
        final bonus = isProficient ? mod + vm.proficiencyBonus : mod;
        final bonusStr = bonus >= 0 ? '+$bonus' : '$bonus';

        return InkWell(
          onTap: () => vm.toggleSkillProficiency(skill.name),
          borderRadius: BorderRadius.circular(5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: Row(children: [
              Container(
                width: 14, height: 14,
                decoration: BoxDecoration(
                  color: isProficient ? C.accent : Colors.transparent,
                  border: Border.all(color: isProficient ? C.accent : C.border, width: 1.5),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: isProficient ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(skill.name, style: TextStyle(color: C.text, fontSize: 12))),
              Text(_abilityAbbr(skill.ability), style: TextStyle(color: C.textSoft, fontSize: 10)),
              const SizedBox(width: 8),
              SizedBox(
                width: 28,
                child: Text(
                  bonusStr,
                  textAlign: TextAlign.right,
                  style: TextStyle(color: bonus >= 0 ? C.green : C.red, fontWeight: FontWeight.w600, fontSize: 11),
                ),
              ),
            ]),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCombatStatsCard(EditPCViewModel vm, AppColorsExtension C) {
    final effectiveAc = vm.effectiveArmorClassSync;
    final hasEquipBonus = effectiveAc != vm.armorClass;

    return _EditorCard(title: 'Kampfwerte', C: C, children: [
      Row(children: [
        Expanded(child: _NumField(label: 'Stufe', value: vm.level, icon: Icons.star, onChanged: vm.updateLevel)),
        const SizedBox(width: 8),
        Expanded(child: _NumField(label: 'Max HP', value: vm.maxHp, icon: Icons.favorite, onChanged: vm.updateMaxHp)),
        const SizedBox(width: 8),
        Expanded(child: _NumField(label: 'Basis-AC', value: vm.armorClass, icon: Icons.security, onChanged: vm.updateArmorClass)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: _StatDisplay(
          label: 'ÜBUNGSBONUS', value: '+${vm.proficiencyBonus}',
          sub: 'auto. berechnet', valueColor: C.accent, C: C,
        )),
        const SizedBox(width: 8),
        Expanded(child: _StatDisplay(
          label: 'INITIATIVE',
          value: vm.initiativeBonus >= 0 ? '+${vm.initiativeBonus}' : '${vm.initiativeBonus}',
          sub: 'aus GES-Mod', valueColor: C.amber, C: C,
        )),
      ]),
      if (vm.isEdit && hasEquipBonus) ...[
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: C.accent.withValues(alpha: 0.1),
            border: Border.all(color: C.accent.withValues(alpha: 0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Icon(Icons.shield, color: C.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Effektive Rüstungsklasse', style: TextStyle(color: C.textMid, fontSize: 11)),
              Text('$effectiveAc', style: TextStyle(color: C.accent, fontWeight: FontWeight.bold, fontSize: 22)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: C.bgHover, borderRadius: BorderRadius.circular(6)),
              child: Text(
                'Dex ${vm.dexterityModifier >= 0 ? '+' : ''}${vm.dexterityModifier}',
                style: TextStyle(color: C.amber, fontSize: 12),
              ),
            ),
          ]),
        ),
      ],
      const SizedBox(height: 12),
      _buildHitDiceRow(vm, C),
    ]);
  }

  Widget _buildHitDiceRow(EditPCViewModel vm, AppColorsExtension C) {
    const purple = Color(0xFF7C3AED);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: purple.withValues(alpha: 0.08),
        border: Border.all(color: purple.withValues(alpha: 0.25)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: purple.withValues(alpha: 0.2),
            border: Border.all(color: purple.withValues(alpha: 0.5), width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(child: Text(vm.hitDice, style: const TextStyle(color: purple, fontWeight: FontWeight.bold, fontSize: 14))),
        ),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Stufe ${vm.level} × ${vm.hitDice}', style: TextStyle(color: C.text, fontSize: 13)),
          const SizedBox(height: 2),
          Text('Für Kurzrast verwenden', style: TextStyle(color: C.textSoft, fontSize: 11)),
        ]),
      ]),
    );
  }

  Widget _buildSavingThrowsCard(EditPCViewModel vm, AppColorsExtension C) {
    final throws = [
      ('Stärke', 'strength', Icons.fitness_center, C.red, vm.strength),
      ('Geschicklichkeit', 'dexterity', Icons.directions_run, C.green, vm.dexterity),
      ('Konstitution', 'constitution', Icons.favorite, C.amber, vm.constitution),
      ('Intelligenz', 'intelligence', Icons.psychology, C.accent, vm.intelligence),
      ('Weisheit', 'wisdom', Icons.visibility, C.accent, vm.wisdom),
      ('Charisma', 'charisma', Icons.star, C.amber, vm.charisma),
    ];

    return _EditorCard(
      title: 'Rettungswürfe',
      C: C,
      children: throws.map((t) {
        final (name, key, icon, color, abilityVal) = t;
        final isProficient = vm.savingThrowProficiencies.contains(key);
        final total = getModifier(abilityVal) + (isProficient ? vm.proficiencyBonus : 0);
        final bonusStr = total >= 0 ? '+$total' : '$total';

        return Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: InkWell(
            onTap: () => vm.toggleSavingThrowProficiency(key),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
              decoration: BoxDecoration(
                color: isProficient ? color.withValues(alpha: 0.12) : Colors.transparent,
                border: Border.all(color: isProficient ? color.withValues(alpha: 0.4) : Colors.transparent),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(children: [
                Icon(icon, color: isProficient ? color : Colors.white38, size: 20),
                const SizedBox(width: 10),
                Expanded(child: Text(name, style: TextStyle(
                  color: isProficient ? Colors.white : Colors.white70,
                  fontWeight: isProficient ? FontWeight.w600 : FontWeight.normal,
                ))),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(color: C.bgHover, borderRadius: BorderRadius.circular(6)),
                  child: Text(bonusStr, style: TextStyle(
                    color: isProficient ? color : C.amber,
                    fontWeight: FontWeight.bold, fontSize: 14,
                  )),
                ),
                const SizedBox(width: 10),
                Icon(
                  isProficient ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isProficient ? color : Colors.white38, size: 22,
                ),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── TAB: ATTRIBUTE ──────────────────────────────────────────────────────────

  Widget _buildAttributeTab(EditPCViewModel vm) {
    return LayoutBuilder(builder: (context, constraints) {
      final C = context.appColors;
      final isWide = constraints.maxWidth >= 600;
      final values = [vm.strength, vm.dexterity, vm.constitution, vm.intelligence, vm.wisdom, vm.charisma];
      final pointsUsed = values.fold(0, (sum, v) => sum + (v - 8).clamp(0, 99));
      const attrLabels = ['Stärke', 'Geschicklichkeit', 'Konstitution', 'Intelligenz', 'Weisheit', 'Charisma'];

      final left = <Widget>[
        _EditorCard(title: 'Attributspunkte', C: C, children: [
          AttributesSectionWidget(
            strength: vm.strength, dexterity: vm.dexterity,
            constitution: vm.constitution, intelligence: vm.intelligence,
            wisdom: vm.wisdom, charisma: vm.charisma,
            onStrengthChanged: vm.updateStrength, onDexterityChanged: vm.updateDexterity,
            onConstitutionChanged: vm.updateConstitution, onIntelligenceChanged: vm.updateIntelligence,
            onWisdomChanged: vm.updateWisdom, onCharismaChanged: vm.updateCharisma,
            useSectionCard: false, title: '',
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(color: C.bgHover, border: Border.all(color: C.border), borderRadius: BorderRadius.circular(7)),
            child: Text('Punktekauf: $pointsUsed / 27 Punkte verwendet', style: TextStyle(fontSize: 11, color: C.textSoft)),
          ),
        ]),
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
                Container(width: 6, height: 6, decoration: BoxDecoration(color: _attrColors[i], shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Expanded(child: Text(attrLabels[i], style: TextStyle(color: C.textMid, fontSize: 12))),
                Text('${values[i]}', style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(width: 8),
                SizedBox(
                  width: 36,
                  child: Text(
                    getModifier(values[i]) >= 0 ? '+${getModifier(values[i])}' : '${getModifier(values[i])}',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: getModifier(values[i]) >= 0 ? C.green : C.red,
                      fontWeight: FontWeight.bold, fontSize: 13,
                    ),
                  ),
                ),
              ]),
            ),
            if (i < 5) const SizedBox(height: 6),
          ],
        ]),
        const SizedBox(height: 12),
        _EditorCard(title: 'Trefferwürfel', C: C, children: [
          Row(children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.5), width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: Text(vm.hitDice, style: const TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.bold, fontSize: 18))),
            ),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Stufe ${vm.level} × ${vm.hitDice}', style: TextStyle(color: C.text, fontSize: 13)),
              const SizedBox(height: 4),
              Text('Für Kurzrast verwenden', style: TextStyle(color: C.textSoft, fontSize: 11)),
            ]),
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

  // ── TAB: D&D DETAILS ────────────────────────────────────────────────────────

  Widget _buildDnDTab(EditPCViewModel vm) {
    return LayoutBuilder(builder: (context, constraints) {
      final C = context.appColors;
      final isWide = constraints.maxWidth >= 600;

      final left = <Widget>[
        _EditorCard(title: 'Grunddaten', C: C, children: [
          Row(children: [
            Expanded(child: FormFieldWidget(label: 'Größe', value: vm.size, onChanged: vm.updateSize, icon: Icons.straighten)),
            const SizedBox(width: 12),
            Expanded(child: FormFieldWidget(label: 'Typ', value: vm.type, onChanged: vm.updateType, icon: Icons.category)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: FormFieldWidget(
              label: 'Subtyp', value: vm.subtype ?? '',
              onChanged: (v) => vm.updateSubtype(v.isEmpty ? null : v), icon: Icons.layers,
            )),
            const SizedBox(width: 12),
            Expanded(child: FormFieldWidget(label: 'Ausrichtung', value: vm.alignment, onChanged: vm.updateAlignment, icon: Icons.compass_calibration)),
          ]),
        ]),
        const SizedBox(height: 12),
        _EditorCard(title: 'Beschreibung', C: C, children: [
          FormFieldWidget(
            label: 'Hintergrundgeschichte & Beschreibung',
            value: vm.description, onChanged: vm.updateDescription,
            icon: Icons.description, maxLines: 5,
          ),
        ]),
      ];

      final right = <Widget>[
        _EditorCard(title: 'Spezielle Fähigkeiten', C: C, children: [
          FormFieldWidget(
            label: 'Klassenfähigkeiten, Rassenmerkmale...',
            value: vm.specialAbilities ?? '',
            onChanged: (v) => vm.updateSpecialAbilities(v.isEmpty ? null : v),
            icon: Icons.auto_awesome, maxLines: 4,
          ),
        ]),
        const SizedBox(height: 12),
        _EditorCard(title: 'Angriffe', C: C, children: [
          FormFieldWidget(
            label: 'Angriffe und Schadenswürfel...',
            value: vm.attacks, onChanged: vm.updateAttacks,
            icon: Icons.gavel, maxLines: 4,
          ),
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

  // ── TAB: INVENTAR ───────────────────────────────────────────────────────────

  Widget _buildInventarTab(EditPCViewModel vm) {
    final C = context.appColors;
    if (!vm.isEdit) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Inventar & Ausrüstung', style: TextStyle(color: C.amber, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              'Speichere den Charakter zuerst,\nbevor du Inventar verwalten kannst.',
              style: TextStyle(color: Colors.white70), textAlign: TextAlign.center,
            ),
          ]),
        ),
      );
    }
    return UnifiedCharacterInventoryWidget(
      inventoryItems: vm.inventory,
      equipmentMap: vm.equipmentMap,
      gold: vm.gold.toInt(), silver: vm.silver.toInt(), copper: vm.copper.toInt(),
      onEquipItem: (slot, item) async {
        try {
          await vm.equipItem(slot, item);
          await _saveWithoutNavigation();
          if (mounted) SnackBarHelper.showSuccess(context, '${item.item.name} ausgerüstet');
        } catch (e) {
          if (mounted) SnackBarHelper.showError(context, e.toString());
        }
      },
      onUnequipItem: (slot) async {
        try {
          await vm.unequipItem(slot);
          await _saveWithoutNavigation();
          if (mounted) SnackBarHelper.showSuccess(context, 'Item abgelegt');
        } catch (e) {
          if (mounted) SnackBarHelper.showError(context, e.toString());
        }
      },
      onAddItem: _addItemFromLibrary,
      onDeleteItem: (item) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        try {
          await _viewModel.removeInventoryItem(item.inventoryItem.id);
          if (mounted) SnackBarHelper.showSuccess(context, '${item.item.name} gelöscht');
        } catch (e) {
          if (mounted) SnackBarHelper.showError(context, 'Fehler: $e');
        }
      },
    );
  }

  // ── SAVE / NAVIGATION ───────────────────────────────────────────────────────

  List<String> _validateRequired() {
    final errors = <String>[];
    if (_viewModel.name.isEmpty) errors.add('Name des Charakters');
    if (_viewModel.playerName.isEmpty) errors.add('Name des Spielers');
    if (_viewModel.selectedClass == null) errors.add('Klasse');
    if (_viewModel.selectedRace == null) errors.add('Rasse');
    if (_viewModel.level < 1) errors.add('Stufe (min. 1)');
    if (_viewModel.maxHp < 1) errors.add('Max. HP (min. 1)');
    if (_viewModel.armorClass < 1) errors.add('Rüstungsklasse (min. 1)');
    return errors;
  }

  Future<void> _saveWithoutNavigation() async {
    FocusScope.of(context).unfocus();
    final errors = _validateRequired();
    if (errors.isNotEmpty) {
      if (mounted) SnackBarHelper.showError(context, 'Pflichtfelder:\n${errors.map((e) => '• $e').join('\n')}');
      return;
    }
    try {
      await _viewModel.saveCharacter();
      if (mounted) SnackBarHelper.showSuccess(context, 'Gespeichert');
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler: $e');
    }
  }

  Future<void> _saveCharacter() async {
    FocusScope.of(context).unfocus();
    final errors = _validateRequired();
    if (errors.isNotEmpty) {
      if (mounted) SnackBarHelper.showError(context, 'Pflichtfelder:\n${errors.map((e) => '• $e').join('\n')}');
      return;
    }
    try {
      await _viewModel.saveCharacter();
      if (mounted) {
        SnackBarHelper.showSuccess(context, _viewModel.isEdit ? 'Charakter aktualisiert' : 'Charakter erstellt');
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler: $e');
    }
  }

  Future<bool> _onWillPop() async {
    if (!_viewModel.isEdit) return true;
    final C = context.appColors;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text('Ungespeicherte Änderungen', style: TextStyle(color: C.amber, fontSize: 18, fontWeight: FontWeight.bold)),
        content: const Text('Möchtest du wirklich ohne Speichern gehen?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Abbrechen', style: TextStyle(color: Color(0xFF7C3AED)))),
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

  Future<void> _addItemFromLibrary() async {
    if (_viewModel.pcToEdit == null) {
      SnackBarHelper.showError(context, 'Bitte speichere den Charakter zuerst.');
      return;
    }
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => AddItemFromLibraryScreen(characterId: _viewModel.pcToEdit!.id)),
      );
      if (mounted && _viewModel.pcToEdit != null) {
        await _viewModel.initialize(widget.campaignId, _viewModel.pcToEdit);
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler: $e');
    }
  }
}

// ── PRIVATE WIDGETS ──────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.vm,
    required this.tabIndex,
    required this.onTabTap,
    required this.onBack,
    required this.onSave,
  });

  final EditPCViewModel vm;
  final int tabIndex;
  final ValueChanged<int> onTabTap;
  final VoidCallback onBack;
  final VoidCallback onSave;

  static const _tabs = [
    (Icons.person, 'Stammdaten'),
    (Icons.fitness_center, 'Attribute'),
    (Icons.category, 'D&D Details'),
    (Icons.inventory_2, 'Inventar'),
  ];

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final className = vm.selectedClass?.name ?? '';
    final classColor = _klasseColor[className] ?? C.accent;
    final charName = vm.name.isEmpty ? 'Held' : vm.name;

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
                  color: classColor.withValues(alpha: 0.18),
                  border: Border.all(color: classColor.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(child: Text(
                  charName[0].toUpperCase(),
                  style: TextStyle(color: classColor, fontWeight: FontWeight.bold, fontSize: 13),
                )),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(charName, style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13, height: 1.1)),
                  Text(
                    'Lvl ${vm.level} $className · ${vm.selectedRace?.name ?? ''}',
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
                        for (int i = 0; i < _tabs.length; i++)
                          _TabBtn(
                            icon: _tabs[i].$1, label: _tabs[i].$2,
                            isActive: tabIndex == i,
                            onTap: () => onTabTap(i), C: C,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _SaveBtn(isSaving: vm.isSaving, onSave: onSave, C: C),
            ]),
          ),
        ),
      ),
    );
  }
}

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
  const _SaveBtn({required this.isSaving, required this.onSave, required this.C});
  final bool isSaving;
  final VoidCallback onSave;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSaving ? null : onSave,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(7)),
        child: isSaving
            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.save, size: 13, color: Colors.white),
                SizedBox(width: 5),
                Text('Speichern', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
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
            Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textMid, letterSpacing: 0.4)),
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

class _PlayerPickerField extends StatelessWidget {
  const _PlayerPickerField({required this.vm, required this.C});
  final EditPCViewModel vm;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.group_outlined, size: 16, color: C.textMid),
            const SizedBox(width: 6),
            Text('Spieler zuordnen', style: TextStyle(color: C.textMid, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: C.bgHover,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: C.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: vm.playerId,
              isExpanded: true,
              dropdownColor: C.bgPanel,
              style: TextStyle(color: C.text, fontSize: 14),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Kein Spieler', style: TextStyle(color: C.textSoft)),
                ),
                ...vm.availablePlayers.map((p) => DropdownMenuItem<String?>(
                      value: p.id,
                      child: Text(p.name, style: TextStyle(color: C.text)),
                    )),
              ],
              onChanged: vm.updatePlayerId,
            ),
          ),
        ),
      ],
    );
  }
}
