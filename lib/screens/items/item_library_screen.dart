import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/item.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';
import '../../viewmodels/item_library_viewmodel.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/shared/app_icon.dart';
import 'edit_item_screen.dart';

// ── TYPE CONFIG ────────────────────────────────────────────────────────────────

class _TC {
  const _TC({required this.color, required this.lightBg, required this.darkBg, required this.dot});
  final Color color;
  final Color lightBg;
  final Color darkBg;
  final Color dot;
  Color bg(bool isDark) => isDark ? darkBg : lightBg;
}

const Map<ItemType, _TC> _tc = {
  ItemType.Weapon:          _TC(color: Color(0xFFc93a3a), lightBg: Color(0xFFfdf0f0), darkBg: Color(0xFF2a1212), dot: Color(0xFFc93a3a)),
  ItemType.Armor:           _TC(color: Color(0xFF1B4F72), lightBg: Color(0xFFeef3fd), darkBg: Color(0xFF0a1828), dot: Color(0xFF2f6feb)),
  ItemType.Shield:          _TC(color: Color(0xFF1a7f4b), lightBg: Color(0xFFeaf4ee), darkBg: Color(0xFF0f2a1c), dot: Color(0xFF1a7f4b)),
  ItemType.Consumable:      _TC(color: Color(0xFFb45309), lightBg: Color(0xFFfdf6ec), darkBg: Color(0xFF2a1f08), dot: Color(0xFFb45309)),
  ItemType.Tool:            _TC(color: Color(0xFF6b6b66), lightBg: Color(0xFFf0f0ed), darkBg: Color(0xFF232320), dot: Color(0xFF6b6b66)),
  ItemType.Material:        _TC(color: Color(0xFF065f46), lightBg: Color(0xFFecfdf5), darkBg: Color(0xFF071a14), dot: Color(0xFF065f46)),
  ItemType.Component:       _TC(color: Color(0xFF7c3aed), lightBg: Color(0xFFf3effe), darkBg: Color(0xFF1e1330), dot: Color(0xFF7c3aed)),
  ItemType.MagicItem:       _TC(color: Color(0xFFbe185d), lightBg: Color(0xFFfdf0f7), darkBg: Color(0xFF2a0f1c), dot: Color(0xFFbe185d)),
  ItemType.Scroll:          _TC(color: Color(0xFF0891b2), lightBg: Color(0xFFecfbff), darkBg: Color(0xFF0a1f28), dot: Color(0xFF0891b2)),
  ItemType.Potion:          _TC(color: Color(0xFF7c3aed), lightBg: Color(0xFFf3effe), darkBg: Color(0xFF1e1330), dot: Color(0xFF7c3aed)),
  ItemType.Treasure:        _TC(color: Color(0xFFd4890a), lightBg: Color(0xFFfdf6ec), darkBg: Color(0xFF2a1f08), dot: Color(0xFFd4890a)),
  ItemType.Currency:        _TC(color: Color(0xFFd4890a), lightBg: Color(0xFFfdf6ec), darkBg: Color(0xFF2a1f08), dot: Color(0xFFd4890a)),
  ItemType.AdventuringGear: _TC(color: Color(0xFF2f6feb), lightBg: Color(0xFFeef3fd), darkBg: Color(0xFF1a2540), dot: Color(0xFF2f6feb)),
  ItemType.SPELL_WEAPON:    _TC(color: Color(0xFFbe185d), lightBg: Color(0xFFfdf0f7), darkBg: Color(0xFF2a0f1c), dot: Color(0xFFbe185d)),
};

_TC _cfg(ItemType type) => _tc[type] ?? _tc[ItemType.AdventuringGear]!;

String _typeName(ItemType type) => switch (type) {
  ItemType.Weapon          => 'Waffe',
  ItemType.Armor           => 'Rüstung',
  ItemType.Shield          => 'Schild',
  ItemType.Consumable      => 'Verbrauchsgut',
  ItemType.Tool            => 'Werkzeug',
  ItemType.Material        => 'Material',
  ItemType.Component       => 'Komponente',
  ItemType.MagicItem       => 'Magisches Item',
  ItemType.Scroll          => 'Schriftrolle',
  ItemType.Potion          => 'Trank',
  ItemType.Treasure        => 'Schatz',
  ItemType.Currency        => 'Währung',
  ItemType.AdventuringGear => 'Ausrüstung',
  ItemType.SPELL_WEAPON    => 'Spruch als Waffe',
};

// ── SCREEN ────────────────────────────────────────────────────────────────────

class ItemLibraryScreen extends StatefulWidget {
  final bool selectMode;

  const ItemLibraryScreen({super.key, this.selectMode = false});

  @override
  State<ItemLibraryScreen> createState() => _ItemLibraryScreenState();
}

class _ItemLibraryScreenState extends State<ItemLibraryScreen> {
  late final ItemLibraryViewModel _vm;
  final _searchCtrl = TextEditingController();
  Item? _selectedItem;

  @override
  void initState() {
    super.initState();
    _vm = ItemLibraryViewModel();
    _vm.loadItems().then((_) {
      if (mounted && _vm.filteredItems.isNotEmpty) {
        setState(() => _selectedItem = _vm.filteredItems.first);
      }
    });
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _vm.dispose();
    super.dispose();
  }

  void _onSearchChanged() => _vm.setSearchQuery(_searchCtrl.text);

  Future<void> _openEditor([Item? item]) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => EditItemScreen(item: item)),
    );
    if (!mounted) return;
    await _vm.loadItems();
    if (mounted) {
      setState(() {
        // keep selection if item still exists, otherwise select first
        if (_selectedItem != null) {
          _selectedItem = _vm.items
              .where((i) => i.id == _selectedItem!.id)
              .firstOrNull;
        }
        _selectedItem ??= _vm.filteredItems.firstOrNull;
      });
    }
  }

  Future<void> _deleteItem(Item item) async {
    final C = context.appColors;
    final confirmed = await showDialog<bool>(
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
              Text('Item löschen',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text)),
              const SizedBox(height: 10),
              Text('"${item.name}" wirklich löschen?',
                  style: TextStyle(fontSize: 13, color: C.textMid)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Abbrechen', style: TextStyle(color: C.textMid, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(backgroundColor: C.red),
                    child: const Text('Löschen', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await _vm.deleteItem(item.id);
      if (mounted) {
        setState(() => _selectedItem = _vm.filteredItems.firstOrNull);
        SnackBarHelper.showSuccess(context, '${item.name} gelöscht');
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final isDark = context.watch<ThemeNotifier>().isDark;

    return ChangeNotifierProvider<ItemLibraryViewModel>.value(
      value: _vm,
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: _buildTopBar(context, C, isDark),
        body: Row(
          children: [
            SizedBox(
              width: 340,
              child: _buildLeftPane(context, C, isDark),
            ),
            VerticalDivider(width: 1, thickness: 1, color: C.border),
            Expanded(child: _buildRightPane(context, C, isDark)),
          ],
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildTopBar(
      BuildContext context, AppColorsExtension C, bool isDark) {
    final notifier = context.watch<ThemeNotifier>();
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
                    // Back
                    if (Navigator.canPop(context)) ...[
                      _IconBtn(C: C, icon: AppIconName.back,
                          onTap: () => Navigator.of(context).pop()),
                      const SizedBox(width: 4),
                      Container(width: 1, height: 18, color: C.border),
                      const SizedBox(width: 10),
                    ],
                    // Icon + Title
                    AppIcon(AppIconName.sword, size: 16, color: C.accent),
                    const SizedBox(width: 8),
                    Text(
                      widget.selectMode ? 'Gegenstand wählen' : 'Ausrüstungskammer',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
                    ),
                    const Spacer(),
                    // Count
                    Consumer<ItemLibraryViewModel>(
                      builder: (_, vm, __) => Text(
                        '${vm.filteredItems.length} Items',
                        style: TextStyle(fontSize: 12, color: C.textSoft),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Theme toggle
                    _IconBtn(
                      C: C,
                      icon: notifier.isDark ? AppIconName.sun : AppIconName.moon,
                      onTap: notifier.toggle,
                    ),
                    if (!widget.selectMode) ...[
                      const SizedBox(width: 8),
                      // Neues Item button
                      _NewItemBtn(C: C, onTap: () => _openEditor()),
                    ],
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

  // ── LEFT PANE ─────────────────────────────────────────────────────────────────

  Widget _buildLeftPane(
      BuildContext context, AppColorsExtension C, bool isDark) {
    return Consumer<ItemLibraryViewModel>(
      builder: (_, vm, __) {
        // Types that have at least one item
        final presentTypes = ItemType.values
            .where((t) => vm.items.any((i) => i.itemType == t))
            .toList();

        return Container(
          color: C.bgPanel,
          child: Column(
            children: [
              // ── Search ───────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: _SearchField(C: C, ctrl: _searchCtrl),
              ),

              // ── Type Filter Chips ─────────────────────
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  children: [
                    _TypeChip(
                      label: 'Alle',
                      isActive: vm.selectedType == null,
                      color: C.accent,
                      dot: C.accent,
                      onTap: () => vm.setTypeFilter(null),
                    ),
                    ...presentTypes.map((t) {
                      final cfg = _cfg(t);
                      final isActive = vm.selectedType == t.name;
                      return _TypeChip(
                        label: _typeName(t),
                        isActive: isActive,
                        color: cfg.color,
                        dot: cfg.dot,
                        activeBg: cfg.bg(isDark),
                        onTap: () => vm.setTypeFilter(isActive ? null : t.name),
                      );
                    }),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: C.border),

              // ── Item List ─────────────────────────────
              Expanded(
                child: vm.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: C.accent, strokeWidth: 2))
                    : vm.filteredItems.isEmpty
                        ? _EmptyList(C: C, hasSearch: vm.hasActiveFilters)
                        : ListView.builder(
                            itemCount: vm.filteredItems.length,
                            itemBuilder: (_, i) {
                              final item = vm.filteredItems[i];
                              final isSelected = _selectedItem?.id == item.id;
                              return _ItemRow(
                                item: item,
                                isSelected: isSelected,
                                isDark: isDark,
                                C: C,
                                onTap: widget.selectMode
                                    ? () => Navigator.of(context).pop(item)
                                    : () => setState(
                                        () => _selectedItem = item),
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── RIGHT PANE ────────────────────────────────────────────────────────────────

  Widget _buildRightPane(
      BuildContext context, AppColorsExtension C, bool isDark) {
    final item = _selectedItem;
    if (item == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIconName.sword, size: 32, color: C.border),
            const SizedBox(height: 10),
            Text('Item auswählen', style: TextStyle(fontSize: 14, color: C.textSoft)),
          ],
        ),
      );
    }
    return _ItemDetail(
      key: ValueKey(item.id),
      item: item,
      C: C,
      isDark: isDark,
      onEdit: () => _openEditor(item),
      onDelete: () => _deleteItem(item),
    );
  }
}

// ── ITEM ROW ──────────────────────────────────────────────────────────────────

class _ItemRow extends StatefulWidget {
  const _ItemRow({
    required this.item,
    required this.isSelected,
    required this.isDark,
    required this.C,
    required this.onTap,
  });

  final Item item;
  final bool isSelected;
  final bool isDark;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  State<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends State<_ItemRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final C = widget.C;
    final cfg = _cfg(item.itemType);
    final sel = widget.isSelected;

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
              bottom: BorderSide(color: C.border),
              left: BorderSide(
                color: sel ? cfg.dot : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              // Avatar
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cfg.dot.withValues(alpha: 0.15),
                  border: Border.all(color: cfg.dot.withValues(alpha: 0.28)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cfg.dot,
                    ),
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
                      item.name,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: sel ? FontWeight.w500 : FontWeight.w400,
                        color: C.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        _TypBadge(type: item.itemType, isDark: widget.isDark, small: true),
                        if (item.cost > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${item.cost % 1 == 0 ? item.cost.toInt() : item.cost.toStringAsFixed(1)} GP',
                            style: TextStyle(fontSize: 10, color: C.textSoft),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Attunement marker
              if (item.requiresAttunement == true)
                Text('✦', style: TextStyle(fontSize: 10, color: const Color(0xFFbe185d))),
            ],
          ),
        ),
      ),
    );
  }
}

// ── ITEM DETAIL ───────────────────────────────────────────────────────────────

class _ItemDetail extends StatelessWidget {
  const _ItemDetail({
    super.key,
    required this.item,
    required this.C,
    required this.isDark,
    required this.onEdit,
    required this.onDelete,
  });

  final Item item;
  final AppColorsExtension C;
  final bool isDark;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg(item.itemType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: cfg.bg(isDark),
              border: Border.all(color: cfg.dot.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cfg.dot.withValues(alpha: 0.15),
                    border: Border.all(color: cfg.dot.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      item.name.isNotEmpty ? item.name[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: cfg.dot,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: C.text)),
                      const SizedBox(height: 4),
                      _TypBadge(type: item.itemType, isDark: isDark),
                    ],
                  ),
                ),
                // Actions
                _EditBtn(C: C, onTap: onEdit),
                const SizedBox(width: 6),
                _DeleteBtn(C: C, onTap: onDelete),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Description ───────────────────────────────
          if (item.description.isNotEmpty) ...[
            _SectionLabel('Beschreibung', C),
            const SizedBox(height: 6),
            Text(
              item.description,
              style: TextStyle(fontSize: 13, color: C.textMid, height: 1.6),
            ),
            const SizedBox(height: 14),
          ],

          // ── Stats Grid ────────────────────────────────
          _buildStatsGrid(),
          const SizedBox(height: 14),

          // ── Properties ───────────────────────────────
          if (item.properties != null && item.properties!.isNotEmpty) ...[
            _SectionLabel('Eigenschaften', C),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: C.bgPanel,
                border: Border.all(color: C.border),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                item.properties!,
                style: TextStyle(fontSize: 13, color: C.textMid, height: 1.5),
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Badges ───────────────────────────────────
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              if (item.requiresAttunement == true)
                _Badge(
                  label: '✦ Attunement',
                  color: const Color(0xFFbe185d),
                  bg: isDark ? const Color(0xFF2a0f1c) : const Color(0xFFfdf0f7),
                ),
              if (item.hasDurability == true)
                _Badge(
                  label: '⏱ Haltbarkeit',
                  color: C.amber,
                  bg: C.bgPanel,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    final stats = <_StatEntry>[
      if (item.cost > 0)
        _StatEntry(
          label: 'Wert',
          value:
              '${item.cost % 1 == 0 ? item.cost.toInt() : item.cost.toStringAsFixed(1)} GP',
        ),
      if (item.weight > 0)
        _StatEntry(label: 'Gewicht', value: '${item.weight} lbs'),
      if (item.damage != null && item.damage!.isNotEmpty)
        _StatEntry(label: 'Schaden', value: item.damage!),
      if (item.damageType != null && item.damageType!.isNotEmpty)
        _StatEntry(label: 'Schadenstyp', value: item.damageType!),
      if (item.acFormula != null && item.acFormula!.isNotEmpty)
        _StatEntry(label: 'Rüstungsklasse', value: item.acFormula!),
      if (item.rarity != null && item.rarity!.isNotEmpty)
        _StatEntry(label: 'Seltenheit', value: item.rarity!),
    ];

    if (stats.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3,
      ),
      itemCount: stats.length,
      itemBuilder: (_, i) => _StatTile(entry: stats[i], C: C),
    );
  }
}

// ── SUB-WIDGETS ───────────────────────────────────────────────────────────────

class _TypBadge extends StatelessWidget {
  const _TypBadge({required this.type, required this.isDark, this.small = false});

  final ItemType type;
  final bool isDark;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: cfg.bg(isDark),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: cfg.dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _typeName(type),
            style: TextStyle(
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: cfg.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.dot,
    required this.onTap,
    this.activeBg,
  });

  final String label;
  final bool isActive;
  final Color color;
  final Color dot;
  final Color? activeBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: isActive ? (activeBg ?? color.withValues(alpha: 0.15)) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: isActive ? dot : context.appColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? color : context.appColors.textMid,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.C, required this.ctrl});

  final AppColorsExtension C;
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontSize: 12, color: C.text),
      decoration: InputDecoration(
        hintText: 'Ausrüstung suchen…',
        hintStyle: TextStyle(fontSize: 12, color: C.textSoft),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: AppIcon(AppIconName.search, size: 13, color: C.textSoft),
        ),
        filled: true,
        fillColor: C.bgHover,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.accent),
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.C, required this.hasSearch});

  final AppColorsExtension C;
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(AppIconName.sword, size: 28, color: C.border),
          const SizedBox(height: 10),
          Text(
            hasSearch ? 'Keine Items gefunden' : 'Keine Items vorhanden',
            style: TextStyle(fontSize: 13, color: C.textSoft),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.C);

  final String text;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: C.textSoft,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _StatEntry {
  const _StatEntry({required this.label, required this.value});

  final String label;
  final String value;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.entry, required this.C});

  final _StatEntry entry;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(entry.label, style: TextStyle(fontSize: 10, color: C.textSoft)),
          const SizedBox(height: 2),
          Text(entry.value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600, color: C.text)),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.bg});

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w500)),
    );
  }
}

class _EditBtn extends StatefulWidget {
  const _EditBtn({required this.C, required this.onTap});

  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  State<_EditBtn> createState() => _EditBtnState();
}

class _EditBtnState extends State<_EditBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final C = widget.C;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? C.bgHover : C.bgPanel,
            border: Border.all(color: C.border),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(AppIconName.edit, size: 11, color: C.textMid),
              const SizedBox(width: 5),
              Text('Bearbeiten',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: C.textMid)),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteBtn extends StatefulWidget {
  const _DeleteBtn({required this.C, required this.onTap});

  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  State<_DeleteBtn> createState() => _DeleteBtnState();
}

class _DeleteBtnState extends State<_DeleteBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final C = widget.C;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _hovered ? C.redSoft : Colors.transparent,
            border: Border.all(
              color: _hovered ? C.red.withValues(alpha: 0.3) : Colors.transparent,
            ),
            borderRadius: BorderRadius.circular(7),
          ),
          child: AppIcon(AppIconName.trash, size: 13, color: C.red),
        ),
      ),
    );
  }
}

class _NewItemBtn extends StatelessWidget {
  const _NewItemBtn({required this.C, required this.onTap});

  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: C.accent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(AppIconName.plus, size: 13, color: Colors.white),
            const SizedBox(width: 5),
            const Text('Neues Item',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  const _IconBtn({required this.C, required this.icon, required this.onTap});

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
                color: _hovered ? widget.C.border : Colors.transparent),
            borderRadius: BorderRadius.circular(7),
          ),
          child: Center(
            child: AppIcon(widget.icon, size: 14, color: widget.C.textMid),
          ),
        ),
      ),
    );
  }
}
