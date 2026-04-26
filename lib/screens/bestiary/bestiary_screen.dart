import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creature.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';
import '../../viewmodels/bestiary_viewmodel.dart';
import '../../widgets/ui_components/feedback/confirmation_dialog.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/shared/app_icon.dart';
import 'edit_creature_screen.dart';

// ── Type colors ───────────────────────────────────────────────────────────────

const Map<String, Color> _typColors = {
  'Beast':       Color(0xFF1a7f4b),
  'Dragon':      Color(0xFFc93a3a),
  'Humanoid':    Color(0xFF2f6feb),
  'Undead':      Color(0xFF4A235A),
  'Fiend':       Color(0xFF7c3aed),
  'Celestial':   Color(0xFFd4890a),
  'Construct':   Color(0xFF6b6b66),
  'Elemental':   Color(0xFF0891b2),
  'Fey':         Color(0xFFbe185d),
  'Giant':       Color(0xFF065f46),
  'Monstrosity': Color(0xFFb45309),
  'Ooze':        Color(0xFF065f46),
  'Plant':       Color(0xFF1a7f4b),
  'Aberration':  Color(0xFF4A235A),
};

Color _typColor(String? type) =>
    _typColors[type] ?? const Color(0xFF6b6b66);

String _crDisplay(int? cr) => cr == null ? '—' : cr.toString();

// ── Filter enum ───────────────────────────────────────────────────────────────

enum _Filter { all, custom, official, favorites }

// ── BestiaryScreen ────────────────────────────────────────────────────────────

class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> {
  late BestiaryViewModel _vm;
  final _searchCtrl = TextEditingController();
  String? _selectedId;
  _Filter _filter = _Filter.all;

  @override
  void initState() {
    super.initState();
    _vm = BestiaryViewModel();
    _vm.addListener(_onVmChanged);
    _searchCtrl.addListener(() => setState(() {}));
    _vm.loadCreatures();
  }

  @override
  void dispose() {
    _vm.removeListener(_onVmChanged);
    _vm.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    setState(() {
      final list = _filteredList();
      if (_selectedId == null && list.isNotEmpty) {
        _selectedId = list.first.id;
      } else if (_selectedId != null &&
          !list.any((c) => c.id == _selectedId)) {
        _selectedId = list.isNotEmpty ? list.first.id : null;
      }
    });
  }

  List<Creature> _filteredList() {
    final q = _searchCtrl.text.toLowerCase();
    return _vm.allCreatures.where((c) {
      final matchSearch = q.isEmpty ||
          c.name.toLowerCase().contains(q) ||
          (c.type?.toLowerCase().contains(q) ?? false);
      final matchFilter = switch (_filter) {
        _Filter.all      => true,
        _Filter.custom   => c.sourceType == 'custom',
        _Filter.official => c.sourceType == 'official',
        _Filter.favorites => c.isFavorite,
      };
      return matchSearch && matchFilter;
    }).toList();
  }

  Future<void> _openEditor([Creature? creature]) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => EditCreatureScreen(creature: creature),
      ),
    );
    await _vm.loadCreatures();
  }

  Future<void> _deleteCreature(Creature creature) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Kreatur löschen',
      message: '"${creature.name}" wird dauerhaft gelöscht.',
      confirmText: 'Löschen',
      isDangerous: true,
    );
    if (confirmed != true || !mounted) return;
    try {
      await _vm.deleteCreature(creature.id);
      if (mounted) {
        SnackBarHelper.showSuccess(context, '${creature.name} gelöscht');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  Future<void> _toggleFavorite(Creature creature) async {
    try {
      await _vm.toggleFavorite(creature);
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Fehler: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final filtered = _filteredList();
    final selected = filtered.cast<Creature?>().firstWhere(
      (c) => c!.id == _selectedId,
      orElse: () => null,
    );

    return ChangeNotifierProvider<BestiaryViewModel>.value(
      value: _vm,
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: _buildTopBar(context, C, filtered.length),
        body: Row(
          children: [
            SizedBox(
              width: 340,
              child: _buildLeftPane(context, C, filtered, selected),
            ),
            VerticalDivider(width: 1, thickness: 1, color: C.border),
            Expanded(child: _buildRightPane(context, C, selected)),
          ],
        ),
      ),
    );
  }

  // ── TopBar ──────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildTopBar(
      BuildContext context, AppColorsExtension C, int count) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        height: 48,
        color: C.bgPanel,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      _IconBtn(C: C, icon: AppIconName.back,
                          onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 4),
                      Container(width: 1, height: 18, color: C.border),
                      const SizedBox(width: 10),
                    ],
                    AppIcon(AppIconName.sword, size: 16, color: C.accent),
                    const SizedBox(width: 8),
                    Text('Bestiarium',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: C.text)),
                    const SizedBox(width: 8),
                    Text('$count',
                        style: TextStyle(fontSize: 12, color: C.textSoft)),
                    const Spacer(),
                    _IconBtn(
                      C: C,
                      icon: AppIconName.moon,
                      onTap: () {},
                      builder: (_) {
                        final notifier = context.watch<ThemeNotifier>();
                        return _IconBtn(
                          C: C,
                          icon: notifier.isDark
                              ? AppIconName.sun
                              : AppIconName.moon,
                          onTap: notifier.toggle,
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => _openEditor(),
                      icon: AppIcon(AppIconName.plus, size: 12,
                          color: Colors.white),
                      label: const Text('Neue Kreatur'),
                      style: FilledButton.styleFrom(
                        backgroundColor: C.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(7)),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: C.border),
          ],
        ),
      ),
    );
  }

  // ── Left pane ───────────────────────────────────────────────────────────────

  Widget _buildLeftPane(
    BuildContext context,
    AppColorsExtension C,
    List<Creature> list,
    Creature? selected,
  ) {
    return Container(
      color: C.bgPanel,
      child: Column(
        children: [
          // Search + filter
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            child: Column(
              children: [
                _SearchField(ctrl: _searchCtrl, C: C),
                const SizedBox(height: 8),
                _buildFilterTabs(C),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: C.border),
          // List
          Expanded(
            child: _vm.isLoading
                ? Center(
                    child: CircularProgressIndicator(
                        color: C.accent, strokeWidth: 2))
                : list.isEmpty
                    ? _EmptyList(C: C)
                    : ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (_, i) {
                          final c = list[i];
                          return _CreatureRow(
                            creature: c,
                            isSelected: c.id == _selectedId,
                            C: C,
                            onTap: () =>
                                setState(() => _selectedId = c.id),
                            onFavorite: () => _toggleFavorite(c),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs(AppColorsExtension C) {
    const tabs = [
      (_Filter.all,      'Alle'),
      (_Filter.custom,   'Eigene'),
      (_Filter.official, 'Offiziell'),
      (_Filter.favorites,'Favoriten'),
    ];
    return Row(
      children: tabs.map((t) {
        final active = _filter == t.$1;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _filter = t.$1),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(vertical: 5),
              decoration: BoxDecoration(
                color: active ? C.accent : Colors.transparent,
                border: Border.all(
                    color: active ? C.accent : C.border),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                t.$2,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: active ? Colors.white : C.textMid,
                ),
              ),
            ),
          ),
        );
      }).expand((w) => [w, const SizedBox(width: 4)]).toList()
        ..removeLast(),
    );
  }

  // ── Right pane ──────────────────────────────────────────────────────────────

  Widget _buildRightPane(
      BuildContext context, AppColorsExtension C, Creature? selected) {
    if (selected == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIconName.sword, size: 32, color: C.border),
            const SizedBox(height: 10),
            Text('Kreatur auswählen',
                style: TextStyle(fontSize: 14, color: C.textSoft)),
          ],
        ),
      );
    }
    return _CreatureDetail(
      key: ValueKey(selected.id),
      creature: selected,
      C: C,
      onEdit: () => _openEditor(selected),
      onDelete: () => _deleteCreature(selected),
    );
  }
}

// ── _CreatureRow ──────────────────────────────────────────────────────────────

class _CreatureRow extends StatefulWidget {
  const _CreatureRow({
    required this.creature,
    required this.isSelected,
    required this.C,
    required this.onTap,
    required this.onFavorite,
  });

  final Creature creature;
  final bool isSelected;
  final AppColorsExtension C;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  State<_CreatureRow> createState() => _CreatureRowState();
}

class _CreatureRowState extends State<_CreatureRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final c = widget.creature;
    final C = widget.C;
    final sel = widget.isSelected;
    final farbe = _typColor(c.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: sel
                ? C.bgActive
                : _hovered
                    ? C.bgHover
                    : Colors.transparent,
            border: Border(
              left: BorderSide(
                  color: sel ? farbe : Colors.transparent, width: 3),
              bottom: BorderSide(color: C.border, width: 1),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(11, 10, 14, 10),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: farbe.withValues(alpha: 0.12),
                  border: Border.all(
                      color: farbe.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: farbe),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              // Name + badge
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: sel
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: C.text),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _TypBadge(
                            type: c.type,
                            isDark: isDark),
                        const SizedBox(width: 6),
                        Text('CR ${_crDisplay(c.challengeRating)}',
                            style: TextStyle(
                                fontSize: 10, color: C.textSoft)),
                      ],
                    ),
                  ],
                ),
              ),
              // HP / AC / Favorite
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      _StatMini(
                          label: 'HP',
                          value: c.maxHp.toString(),
                          color: C.red),
                      const SizedBox(width: 10),
                      _StatMini(
                          label: 'AC',
                          value: c.armorClass.toString(),
                          color: C.accent),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: widget.onFavorite,
                        child: AppIcon(
                          AppIconName.star,
                          size: 14,
                          color: c.isFavorite ? C.amber : C.textSoft,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── _CreatureDetail ───────────────────────────────────────────────────────────

class _CreatureDetail extends StatelessWidget {
  const _CreatureDetail({
    super.key,
    required this.creature,
    required this.C,
    required this.onEdit,
    required this.onDelete,
  });

  final Creature creature;
  final AppColorsExtension C;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final c = creature;
    final farbe = _typColor(c.type);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: farbe.withValues(alpha: isDark ? 0.1 : 0.07),
              border: Border.all(
                  color: farbe.withValues(alpha: 0.25)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: farbe.withValues(alpha: 0.18),
                    border: Border.all(
                        color: farbe.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      c.name.isNotEmpty
                          ? c.name[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: farbe),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: C.text)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _TypBadge(type: c.type, isDark: isDark),
                          if (c.size != null)
                            Text(c.size!,
                                style: TextStyle(
                                    fontSize: 10, color: C.textSoft)),
                          if (c.alignment != null) ...[
                            Text('·',
                                style: TextStyle(
                                    fontSize: 10, color: C.textSoft)),
                            Text(c.alignment!,
                                style: TextStyle(
                                    fontSize: 10, color: C.textSoft)),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Edit button
                GestureDetector(
                  onTap: onEdit,
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: C.bgPanel,
                        border: Border.all(color: C.border),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Row(
                        children: [
                          AppIcon(AppIconName.edit, size: 11,
                              color: C.textMid),
                          const SizedBox(width: 5),
                          Text('Bearbeiten',
                              style: TextStyle(
                                  fontSize: 11, color: C.textMid)),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Combat stats ─────────────────────────────────────────
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                      label: 'HP',
                      value: c.maxHp.toString(),
                      color: C.red,
                      icon: AppIconName.heart,
                      C: C)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatCard(
                      label: 'RK (AC)',
                      value: c.armorClass.toString(),
                      color: C.accent,
                      icon: AppIconName.shield,
                      C: C)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatCard(
                      label: 'CR',
                      value: _crDisplay(c.challengeRating),
                      color: C.amber,
                      icon: AppIconName.star,
                      C: C)),
            ],
          ),
          const SizedBox(height: 14),

          // ── Attributes ───────────────────────────────────────────
          _SectionLabel('Attribute', C),
          const SizedBox(height: 8),
          Row(
            children: [
              _AttrCell(key: const ValueKey('STR'), abbr: 'STÄ', label: 'Stärke',       value: c.strength,     C: C),
              _AttrCell(key: const ValueKey('DEX'), abbr: 'GES', label: 'Geschick',      value: c.dexterity,    C: C),
              _AttrCell(key: const ValueKey('CON'), abbr: 'KON', label: 'Konstitution',  value: c.constitution,  C: C),
              _AttrCell(key: const ValueKey('INT'), abbr: 'INT', label: 'Intelligenz',   value: c.intelligence, C: C),
              _AttrCell(key: const ValueKey('WIS'), abbr: 'WEI', label: 'Weisheit',      value: c.wisdom,       C: C),
              _AttrCell(key: const ValueKey('CHA'), abbr: 'CHA', label: 'Charisma',      value: c.charisma,     C: C),
            ],
          ),
          const SizedBox(height: 14),

          // ── Text sections ─────────────────────────────────────────
          if (c.specialAbilities != null &&
              c.specialAbilities!.isNotEmpty) ...[
            _SectionLabel('Fähigkeiten & Sinne', C),
            const SizedBox(height: 6),
            _TextCard(text: c.specialAbilities!, C: C),
            const SizedBox(height: 12),
          ],
          if (c.attacks.isNotEmpty) ...[
            _SectionLabel('Angriffe', C),
            const SizedBox(height: 6),
            _TextCard(text: c.attacks, C: C),
            const SizedBox(height: 12),
          ],
          if (c.legendaryActions != null &&
              c.legendaryActions!.isNotEmpty) ...[
            _SectionLabel('Besondere Eigenschaften', C),
            const SizedBox(height: 6),
            _TextCard(text: c.legendaryActions!, C: C),
            const SizedBox(height: 12),
          ],
          if (c.description != null && c.description!.isNotEmpty) ...[
            _SectionLabel('Beschreibung', C),
            const SizedBox(height: 6),
            _TextCard(text: c.description!, C: C),
            const SizedBox(height: 12),
          ],

          // ── Delete ───────────────────────────────────────────────
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: onDelete,
              icon: AppIcon(AppIconName.trash, size: 12, color: C.red),
              label: const Text('Löschen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.red,
                side: BorderSide(color: C.red.withValues(alpha: 0.4)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
                textStyle: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Small helpers ─────────────────────────────────────────────────────────────

class _TypBadge extends StatelessWidget {
  const _TypBadge({required this.type, required this.isDark});

  final String? type;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final farbe = _typColor(type);
    final label = type ?? '—';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: farbe.withValues(alpha: isDark ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
                color: farbe, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: farbe)),
        ],
      ),
    );
  }
}

class _StatMini extends StatelessWidget {
  const _StatMini(
      {required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: color)),
        Text(label,
            style: const TextStyle(fontSize: 9, color: Color(0xFF9f9f98))),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.C,
  });

  final String label;
  final String value;
  final Color color;
  final AppIconName icon;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppIcon(icon, size: 11, color: color),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(fontSize: 10, color: C.textSoft)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color)),
        ],
      ),
    );
  }
}

class _AttrCell extends StatelessWidget {
  const _AttrCell({
    super.key,
    required this.abbr,
    required this.label,
    required this.value,
    required this.C,
  });

  final String abbr;
  final String label;
  final int value;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final mod = (value - 10) ~/ 2;
    final modStr = mod >= 0 ? '+$mod' : '$mod';
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: C.bgPanel,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Column(
          children: [
            Text(abbr,
                style:
                    TextStyle(fontSize: 9, color: C.textSoft)),
            const SizedBox(height: 2),
            Text('$value',
                style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: C.text)),
            Text(modStr,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: mod >= 0 ? C.green : C.red)),
          ],
        ),
      ),
    );
  }
}

class _TextCard extends StatelessWidget {
  const _TextCard({required this.text, required this.C});

  final String text;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 12, color: C.textMid, height: 1.6),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label, this.C);

  final String label;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: C.textSoft,
          letterSpacing: 0.4),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.ctrl, required this.C});

  final TextEditingController ctrl;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      decoration: BoxDecoration(
        color: C.bgHover,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          const SizedBox(width: 10),
          AppIcon(AppIconName.search, size: 13, color: C.textSoft),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl,
              style: TextStyle(fontSize: 12, color: C.text),
              decoration: InputDecoration(
                hintText: 'Kreaturen suchen...',
                hintStyle: TextStyle(fontSize: 12, color: C.textSoft),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (ctrl.text.isNotEmpty) ...[
            GestureDetector(
              onTap: ctrl.clear,
              child: AppIcon(AppIconName.close, size: 12, color: C.textSoft),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.C});

  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIconName.sword, size: 28, color: C.border),
          const SizedBox(height: 10),
          Text('Keine Kreaturen gefunden',
              style: TextStyle(fontSize: 13, color: C.textSoft)),
        ],
      ),
    );
  }
}

// ── _IconBtn ──────────────────────────────────────────────────────────────────

class _IconBtn extends StatefulWidget {
  const _IconBtn({
    required this.C,
    required this.icon,
    required this.onTap,
    this.builder,
  });

  final AppColorsExtension C;
  final AppIconName icon;
  final VoidCallback onTap;
  final Widget Function(BuildContext)? builder;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    if (widget.builder != null) return widget.builder!(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _hovered ? widget.C.bgHover : Colors.transparent,
            border: Border.all(
                color: _hovered ? widget.C.border : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child:
                AppIcon(widget.icon, size: 14, color: widget.C.textMid),
          ),
        ),
      ),
    );
  }
}
