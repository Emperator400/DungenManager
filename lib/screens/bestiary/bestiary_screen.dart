import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/creature.dart';
import '../../theme/app_theme.dart';
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

const List<(String, Color)> _attrDefs = [
  ('STÄ', Color(0xFFC93A3A)),
  ('GES', Color(0xFF1A7F4B)),
  ('KON', Color(0xFFD4890A)),
  ('INT', Color(0xFF2F6FEB)),
  ('WEI', Color(0xFF7C3AED)),
  ('CHA', Color(0xFFBE185D)),
];

const List<String> _attrLabels = [
  'Stärke', 'Geschicklichkeit', 'Konstitution',
  'Intelligenz', 'Weisheit', 'Charisma',
];

Color _typColor(String? type) => _typColors[type] ?? const Color(0xFF6b6b66);
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
        _Filter.all       => true,
        _Filter.custom    => c.sourceType == 'custom',
        _Filter.official  => c.sourceType == 'official',
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
      if (mounted) SnackBarHelper.showSuccess(context, '${creature.name} gelöscht');
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler: $e');
    }
  }

  Future<void> _toggleFavorite(Creature creature) async {
    try {
      await _vm.toggleFavorite(creature);
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler: $e');
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
                            onTap: () => setState(() => _selectedId = c.id),
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
      (_Filter.all,       'Alle'),
      (_Filter.custom,    'Eigene'),
      (_Filter.official,  'Offiziell'),
      (_Filter.favorites, 'Favoriten'),
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
                border: Border.all(color: active ? C.accent : C.border),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: farbe.withValues(alpha: 0.12),
                  border: Border.all(color: farbe.withValues(alpha: 0.3)),
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
                          fontWeight:
                              sel ? FontWeight.w500 : FontWeight.w400,
                          color: C.text),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        _TypBadge(type: c.type, isDark: isDark),
                        const SizedBox(width: 6),
                        Text('CR ${_crDisplay(c.challengeRating)}',
                            style:
                                TextStyle(fontSize: 10, color: C.textSoft)),
                      ],
                    ),
                  ],
                ),
              ),
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

class _CreatureDetail extends StatefulWidget {
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
  State<_CreatureDetail> createState() => _CreatureDetailState();
}

class _CreatureDetailState extends State<_CreatureDetail>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _tabs = [
    (Icons.grid_view_rounded, 'Überblick'),
    (Icons.gavel,             'Aktionen'),
    (Icons.info_outline,      'Details'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.creature;
    final C = widget.C;
    final farbe = _typColor(c.type);

    return Column(
      children: [
        _buildSubHeader(c, C, farbe),
        Divider(height: 1, thickness: 1, color: C.border),
        Expanded(
          child: AnimatedBuilder(
            animation: _tabController,
            builder: (_, __) => TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(c, C),
                _buildActionsTab(c, C),
                _buildDetailsTab(c, C),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Sub-Header ───────────────────────────────────────────────────────────────

  Widget _buildSubHeader(
      Creature c, AppColorsExtension C, Color farbe) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: C.bgPanel,
      child: Row(
        children: [
          // Avatar
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: farbe.withValues(alpha: 0.18),
              border: Border.all(color: farbe.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                c.name.isNotEmpty ? c.name[0].toUpperCase() : '?',
                style: TextStyle(
                    color: farbe,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Name + meta
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(c.name,
                  style: TextStyle(
                      color: C.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      height: 1.1)),
              Text(
                '${c.type ?? '—'} · CR ${_crDisplay(c.challengeRating)}',
                style: TextStyle(
                    color: C.textSoft, fontSize: 10, height: 1.1),
              ),
            ],
          ),
          Container(
              width: 1, height: 18, color: C.border,
              margin: const EdgeInsets.symmetric(horizontal: 12)),
          // Tabs
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < _tabs.length; i++)
                    _TabBtn(
                      icon: _tabs[i].$1,
                      label: _tabs[i].$2,
                      isActive: _tabController.index == i,
                      onTap: () => _tabController.animateTo(i),
                      C: C,
                    ),
                ],
              ),
            ),
          ),
          // Edit button
          GestureDetector(
            onTap: widget.onEdit,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: C.border),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon(AppIconName.edit, size: 11, color: C.textMid),
                  const SizedBox(width: 5),
                  Text('Bearbeiten',
                      style: TextStyle(fontSize: 11, color: C.textMid)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab: Überblick ────────────────────────────────────────────────────────────

  Widget _buildOverviewTab(Creature c, AppColorsExtension C) {
    final attrValues = [
      c.strength, c.dexterity, c.constitution,
      c.intelligence, c.wisdom, c.charisma,
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat row
          Row(
            children: [
              Expanded(
                  child: _StatDisplay(
                      label: 'HP',
                      value: c.maxHp.toString(),
                      sub: 'Trefferpunkte',
                      valueColor: C.red,
                      C: C)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatDisplay(
                      label: 'RK',
                      value: c.armorClass.toString(),
                      sub: 'Rüstungsklasse',
                      valueColor: C.accent,
                      C: C)),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatDisplay(
                      label: 'CR',
                      value: _crDisplay(c.challengeRating),
                      sub: 'Herausforderung',
                      valueColor: C.amber,
                      C: C)),
            ],
          ),
          const SizedBox(height: 14),
          // Attributes
          _EditorCard(
            title: 'Attribute',
            C: C,
            children: [
              for (int i = 0; i < 6; i++) ...[
                _AttrRow(
                  abbr: _attrDefs[i].$1,
                  label: _attrLabels[i],
                  value: attrValues[i],
                  color: _attrDefs[i].$2,
                  C: C,
                ),
                if (i < 5) const SizedBox(height: 4),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ── Tab: Aktionen ─────────────────────────────────────────────────────────────

  Widget _buildActionsTab(Creature c, AppColorsExtension C) {
    final hasAbilities = c.specialAbilities?.isNotEmpty == true;
    final hasAttacks = c.attacks.isNotEmpty;
    final hasLegendary = c.legendaryActions?.isNotEmpty == true;

    if (!hasAbilities && !hasAttacks && !hasLegendary) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIconName.sword, size: 28, color: C.border),
            const SizedBox(height: 10),
            Text('Keine Aktionen definiert',
                style: TextStyle(fontSize: 13, color: C.textSoft)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (hasAbilities) ...[
            _EditorCard(
              title: 'Fähigkeiten & Sinne',
              C: C,
              children: [
                Text(c.specialAbilities!,
                    style: TextStyle(
                        fontSize: 12, color: C.textMid, height: 1.6)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (hasAttacks) ...[
            _EditorCard(
              title: 'Angriffe',
              C: C,
              children: [
                Text(c.attacks,
                    style: TextStyle(
                        fontSize: 12, color: C.textMid, height: 1.6)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (hasLegendary)
            _EditorCard(
              title: 'Besondere Eigenschaften',
              C: C,
              children: [
                Text(c.legendaryActions!,
                    style: TextStyle(
                        fontSize: 12, color: C.textMid, height: 1.6)),
              ],
            ),
        ],
      ),
    );
  }

  // ── Tab: Details ──────────────────────────────────────────────────────────────

  Widget _buildDetailsTab(Creature c, AppColorsExtension C) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EditorCard(
            title: 'Metadaten',
            C: C,
            children: [
              _MetaRow('Typ', c.type ?? '—', C),
              if (c.size != null) ...[
                const SizedBox(height: 8),
                _MetaRow('Größe', c.size!, C),
              ],
              if (c.alignment != null) ...[
                const SizedBox(height: 8),
                _MetaRow('Gesinnung', c.alignment!, C),
              ],
              const SizedBox(height: 8),
              _MetaRow(
                'Quelle',
                c.sourceType == 'custom' ? 'Eigene Kreatur' : 'Offiziell (SRD)',
                C,
              ),
            ],
          ),
          if (c.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            _EditorCard(
              title: 'Beschreibung',
              C: C,
              children: [
                Text(c.description!,
                    style: TextStyle(
                        fontSize: 12, color: C.textMid, height: 1.6)),
              ],
            ),
          ],
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: widget.onDelete,
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
              decoration:
                  BoxDecoration(color: farbe, shape: BoxShape.circle)),
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
            style:
                const TextStyle(fontSize: 9, color: Color(0xFF9f9f98))),
      ],
    );
  }
}

// ── _StatDisplay ──────────────────────────────────────────────────────────────

class _StatDisplay extends StatelessWidget {
  const _StatDisplay({
    required this.label,
    required this.value,
    required this.sub,
    required this.valueColor,
    required this.C,
  });

  final String label;
  final String value;
  final String sub;
  final Color valueColor;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 10,
                  color: C.textSoft,
                  letterSpacing: 0.4)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: valueColor)),
          Text(sub,
              style: TextStyle(fontSize: 10, color: C.textSoft)),
        ],
      ),
    );
  }
}

// ── _AttrRow ──────────────────────────────────────────────────────────────────

class _AttrRow extends StatelessWidget {
  const _AttrRow({
    required this.abbr,
    required this.label,
    required this.value,
    required this.color,
    required this.C,
  });

  final String abbr;
  final String label;
  final int value;
  final Color color;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final mod = (value - 10) ~/ 2;
    final modStr = mod >= 0 ? '+$mod' : '$mod';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.18)),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Container(
              width: 6,
              height: 6,
              decoration:
                  BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Text(abbr,
              style: TextStyle(
                  color: C.textSoft,
                  fontSize: 10,
                  fontWeight: FontWeight.w500)),
          const SizedBox(width: 6),
          Expanded(
              child: Text(label,
                  style: TextStyle(color: C.textMid, fontSize: 12))),
          Text('$value',
              style: TextStyle(
                  color: C.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          const SizedBox(width: 8),
          SizedBox(
            width: 36,
            child: Text(
              modStr,
              textAlign: TextAlign.right,
              style: TextStyle(
                  color: mod >= 0 ? C.green : C.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── _EditorCard ───────────────────────────────────────────────────────────────

class _EditorCard extends StatelessWidget {
  const _EditorCard(
      {required this.title, required this.C, required this.children});

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
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: C.textMid,
                    letterSpacing: 0.4)),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

// ── _TabBtn ───────────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  const _TabBtn({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    required this.C,
  });

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
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive ? C.bgHover : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: isActive ? C.accent : C.textSoft),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  color: isActive ? C.text : C.textMid,
                  fontSize: 12,
                  fontWeight: isActive
                      ? FontWeight.w500
                      : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}

// ── _MetaRow ──────────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  const _MetaRow(this.label, this.value, this.C);

  final String label;
  final String value;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: C.textSoft, fontSize: 12)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                color: C.textMid,
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── _SearchField ──────────────────────────────────────────────────────────────

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
                hintStyle:
                    TextStyle(fontSize: 12, color: C.textSoft),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (ctrl.text.isNotEmpty) ...[
            GestureDetector(
              onTap: ctrl.clear,
              child: AppIcon(AppIconName.close,
                  size: 12, color: C.textSoft),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

// ── _EmptyList ────────────────────────────────────────────────────────────────

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
  });

  final AppColorsExtension C;
  final AppIconName icon;
  final VoidCallback onTap;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
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
                color: _hovered
                    ? widget.C.border
                    : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: AppIcon(widget.icon,
                size: 14, color: widget.C.textMid),
          ),
        ),
      ),
    );
  }
}
