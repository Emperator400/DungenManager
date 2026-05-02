import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/wiki_entry.dart';
import '../../theme/app_colors_map.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';
import '../../viewmodels/wiki_viewmodel.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/shared/app_icon.dart';

// ── TYPE CONFIG HELPERS ────────────────────────────────────────────────────────

const _typeLabels = <WikiEntryType, String>{
  WikiEntryType.Person:   'NPC',
  WikiEntryType.Place:    'Ort',
  WikiEntryType.Lore:     'Lore',
  WikiEntryType.Faction:  'Fraktion',
  WikiEntryType.Magic:    'Magie',
  WikiEntryType.History:  'Geschichte',
  WikiEntryType.Item:     'Gegenstand',
  WikiEntryType.Quest:    'Quest',
  WikiEntryType.Creature: 'Kreatur',
};

String _label(WikiEntryType t) => _typeLabels[t] ?? t.name;
TypeColorConfig _cfg(WikiEntryType t) => AppTypeColors.of(_label(t));

// ── SCREEN ────────────────────────────────────────────────────────────────────

class LoreKeeperScreen extends StatefulWidget {
  const LoreKeeperScreen({super.key});

  @override
  State<LoreKeeperScreen> createState() => _LoreKeeperScreenState();
}

class _LoreKeeperScreenState extends State<LoreKeeperScreen> {
  final _searchCtrl = TextEditingController();
  String? _expandedId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WikiViewModel>().loadEntries();
    });
    _searchCtrl.addListener(
      () => context.read<WikiViewModel>().searchEntriesLocal(_searchCtrl.text),
    );
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleExpand(String id) =>
      setState(() => _expandedId = _expandedId == id ? null : id);

  void _showEditor(WikiEntry? entry) {
    final vm = context.read<WikiViewModel>();
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'close',
      barrierColor: Colors.black.withValues(alpha: 0.35),
      transitionDuration: const Duration(milliseconds: 260),
      pageBuilder: (ctx, _, __) => _EditorLeiste(
        entry: entry,
        vm: vm,
        onClose: () => Navigator.of(ctx).pop(),
      ),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: child,
      ),
    );
  }

  Future<void> _deleteEntry(WikiEntry entry) async {
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
              Text('Eintrag löschen',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: C.text)),
              const SizedBox(height: 10),
              Text('"${entry.title}" wirklich löschen?',
                  style: TextStyle(fontSize: 13, color: C.textMid)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(false),
                    child: Text('Abbrechen',
                        style: TextStyle(color: C.textMid, fontSize: 13)),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(backgroundColor: C.red),
                    child:
                        const Text('Löschen', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed != true || !mounted) return;
    final vm = context.read<WikiViewModel>();
    try {
      await vm.deleteEntry(entry.id);
      if (mounted) {
        setState(() {
          if (_expandedId == entry.id) _expandedId = null;
        });
        SnackBarHelper.showSuccess(context, '${entry.title} gelöscht');
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final isDark = context.watch<ThemeNotifier>().isDark;

    return Scaffold(
      backgroundColor: C.bg,
      body: Column(
        children: [
          _buildTopBar(context, C),
          _buildSearch(context, C),
          _buildTypeFilter(context, C, isDark),
          Expanded(child: _buildContent(context, C, isDark)),
        ],
      ),
      floatingActionButton: FilledButton.icon(
        onPressed: () => _showEditor(null),
        icon: AppIcon(AppIconName.plus, size: 14, color: Colors.white),
        label: const Text('Neuer Eintrag'),
        style: FilledButton.styleFrom(
          backgroundColor: C.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────────

  Widget _buildTopBar(BuildContext context, AppColorsExtension C) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SafeArea(
          bottom: false,
          child: SizedBox(
            height: 48,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _IconBtn(
                    C: C,
                    icon: AppIconName.back,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  Container(width: 1, height: 18, color: C.border),
                  const SizedBox(width: 10),
                  AppIcon(AppIconName.book, size: 16, color: C.accent),
                  const SizedBox(width: 7),
                  Text('Lore Keeper',
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: C.text)),
                  const SizedBox(width: 8),
                  Consumer<WikiViewModel>(
                    builder: (_, vm, __) => Text(
                      '${vm.filteredEntries.length} Einträge',
                      style: TextStyle(fontSize: 12, color: C.textSoft),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: C.border),
      ],
    );
  }

  // ── SEARCH ────────────────────────────────────────────────────────────────────

  Widget _buildSearch(BuildContext context, AppColorsExtension C) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: TextField(
        controller: _searchCtrl,
        style: TextStyle(fontSize: 13, color: C.text),
        decoration: InputDecoration(
          hintText: 'Wiki-Einträge durchsuchen...',
          hintStyle: TextStyle(fontSize: 13, color: C.textSoft),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(10),
            child: AppIcon(AppIconName.search, size: 14, color: C.textSoft),
          ),
          suffixIcon: Consumer<WikiViewModel>(
            builder: (_, vm, __) => vm.searchQuery.isNotEmpty
                ? GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      vm.searchEntriesLocal('');
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: AppIcon(AppIconName.close, size: 13,
                          color: C.textSoft),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          filled: true,
          fillColor: C.bgPanel,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: C.accent),
          ),
        ),
      ),
    );
  }

  // ── TYPE FILTER ───────────────────────────────────────────────────────────────

  Widget _buildTypeFilter(
      BuildContext context, AppColorsExtension C, bool isDark) {
    return Consumer<WikiViewModel>(
      builder: (_, vm, __) {
        final counts = vm.entryTypeCounts;
        return Container(
          height: 44,
          margin: const EdgeInsets.only(top: 10),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _TypeChip(
                label: 'Alle',
                count: vm.allEntries.length,
                isActive: vm.selectedType == null,
                color: C.accent,
                dot: C.accent,
                activeBg: C.accentSoft,
                C: C,
                onTap: () => vm.setTypeFilter(null),
              ),
              const SizedBox(width: 5),
              ...WikiEntryType.values.map((type) {
                final count = counts[type] ?? 0;
                if (count == 0) return const SizedBox.shrink();
                final cfg = _cfg(type);
                final isActive = vm.selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: _TypeChip(
                    label: _label(type),
                    count: count,
                    isActive: isActive,
                    color: cfg.color,
                    dot: cfg.dot,
                    activeBg: isDark ? cfg.bgDark : cfg.bgLight,
                    C: C,
                    onTap: () =>
                        vm.setTypeFilter(isActive ? null : type),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  // ── CONTENT ───────────────────────────────────────────────────────────────────

  Widget _buildContent(
      BuildContext context, AppColorsExtension C, bool isDark) {
    return Consumer<WikiViewModel>(
      builder: (_, vm, __) {
        if (vm.isLoading) {
          return Center(
              child: CircularProgressIndicator(color: C.accent, strokeWidth: 2));
        }

        if (vm.error != null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(AppIconName.error, size: 32, color: C.red),
                const SizedBox(height: 12),
                Text('Fehler beim Laden',
                    style: TextStyle(fontSize: 14, color: C.text)),
                const SizedBox(height: 6),
                Text(vm.error!,
                    style: TextStyle(fontSize: 12, color: C.textSoft)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: () {
                    vm
                      ..clearError()
                      ..refresh();
                  },
                  icon: AppIcon(AppIconName.refresh, size: 13, color: C.textMid),
                  label: Text('Erneut versuchen',
                      style: TextStyle(color: C.textMid)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: C.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7)),
                  ),
                ),
              ],
            ),
          );
        }

        final entries = vm.filteredEntries;

        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppIcon(AppIconName.book, size: 36, color: C.border),
                const SizedBox(height: 12),
                Text(
                  vm.hasActiveFilters
                      ? 'Keine Einträge gefunden'
                      : 'Dein Wiki ist noch leer',
                  style: TextStyle(fontSize: 14, color: C.textSoft),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: _buildGridRows(entries, C, isDark),
        );
      },
    );
  }

  // ── CUSTOM GRID (supports span-2 for expanded cards) ─────────────────────────

  List<Widget> _buildGridRows(
      List<WikiEntry> entries, AppColorsExtension C, bool isDark) {
    final rows = <Widget>[];
    int i = 0;

    while (i < entries.length) {
      final entry = entries[i];
      final isExpanded = _expandedId == entry.id;

      if (isExpanded) {
        rows.add(_WikiKarte(
          entry: entry,
          expanded: true,
          isDark: isDark,
          C: C,
          onToggle: () => _toggleExpand(entry.id),
          onEdit: () => _showEditor(entry),
          onDelete: () => _deleteEntry(entry),
        ));
        i++;
      } else {
        final hasNext = i + 1 < entries.length;
        final next = hasNext ? entries[i + 1] : null;
        final nextExpanded = next != null && _expandedId == next.id;

        if (next != null && !nextExpanded) {
          rows.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _WikiKarte(
                  entry: entry,
                  expanded: false,
                  isDark: isDark,
                  C: C,
                  onToggle: () => _toggleExpand(entry.id),
                  onEdit: () => _showEditor(entry),
                  onDelete: () => _deleteEntry(entry),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WikiKarte(
                  entry: next,
                  expanded: false,
                  isDark: isDark,
                  C: C,
                  onToggle: () => _toggleExpand(next.id),
                  onEdit: () => _showEditor(next),
                  onDelete: () => _deleteEntry(next),
                ),
              ),
            ],
          ));
          i += 2;
        } else {
          // Either last item (no pair) or next is expanded → show alone
          rows.add(Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _WikiKarte(
                  entry: entry,
                  expanded: false,
                  isDark: isDark,
                  C: C,
                  onToggle: () => _toggleExpand(entry.id),
                  onEdit: () => _showEditor(entry),
                  onDelete: () => _deleteEntry(entry),
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(child: SizedBox()),
            ],
          ));
          i++;
        }
      }

      rows.add(const SizedBox(height: 10));
    }

    return rows;
  }
}

// ── WIKI KARTE ────────────────────────────────────────────────────────────────

class _WikiKarte extends StatefulWidget {
  const _WikiKarte({
    required this.entry,
    required this.expanded,
    required this.isDark,
    required this.C,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  final WikiEntry entry;
  final bool expanded;
  final bool isDark;
  final AppColorsExtension C;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_WikiKarte> createState() => _WikiKarteState();
}

class _WikiKarteState extends State<_WikiKarte> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.entry;
    final C = widget.C;
    final isDark = widget.isDark;
    final cfg = _cfg(e.entryType);
    final exp = widget.expanded;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: C.bgPanel,
          border: Border.all(
            color: exp || _hovered ? C.borderStrong : C.border,
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: exp
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Colored top stripe ─────────────────────
              Container(height: 3, color: cfg.dot),

              // ── Card header ────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 10, 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _TypBadge(
                                  type: e.entryType,
                                  isDark: isDark,
                                  small: true),
                              const SizedBox(width: 6),
                              Text(
                                e.isGlobal ? 'Global' : 'Kampagne',
                                style: TextStyle(
                                    fontSize: 10, color: C.textSoft),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            e.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: C.text,
                              height: 1.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        if (_hovered)
                          _SmallIconBtn(
                            icon: AppIconName.edit,
                            C: C,
                            onTap: widget.onEdit,
                          ),
                        _SmallIconBtn(
                          icon: exp
                              ? AppIconName.chevronUp
                              : AppIconName.chevronDown,
                          C: C,
                          active: exp,
                          onTap: widget.onToggle,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Collapsed content ──────────────────────
              if (!exp) ...[
                if (e.content.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Text(
                      e.content,
                      style: TextStyle(
                          fontSize: 12, color: C.textMid, height: 1.5),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (e.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: e.tags
                          .map((t) => _TagPill(label: t, C: C))
                          .toList(),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: Row(
                    children: [
                      AppIcon(AppIconName.calendar, size: 11,
                          color: C.textSoft),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(e.updatedAt),
                        style:
                            TextStyle(fontSize: 10, color: C.textSoft),
                      ),
                      if (e.location?.mapId != null) ...[
                        const SizedBox(width: 10),
                        AppIcon(AppIconName.location, size: 11,
                            color: C.textSoft),
                        const SizedBox(width: 4),
                        Text(
                          e.location!.mapId,
                          style:
                              TextStyle(fontSize: 10, color: C.textSoft),
                        ),
                      ],
                    ],
                  ),
                ),
              ],

              // ── Expanded content ───────────────────────
              if (exp) ...[
                Divider(height: 1, thickness: 1, color: C.border),
                Container(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.015),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left: full content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Inhalt', C),
                            const SizedBox(height: 8),
                            Text(
                              e.content.isNotEmpty
                                  ? e.content
                                  : '(Kein Inhalt)',
                              style: TextStyle(
                                fontSize: 13,
                                color: C.textMid,
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Right: details + actions
                      SizedBox(
                        width: 200,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _SectionLabel('Details', C),
                            const SizedBox(height: 8),
                            _DetailRow('Typ',
                                _TypBadge(
                                    type: e.entryType,
                                    isDark: isDark,
                                    small: true),
                                C),
                            const SizedBox(height: 6),
                            _DetailRow(
                                'Scope',
                                Text(
                                  e.isGlobal ? 'Global' : 'Kampagne',
                                  style: TextStyle(
                                      fontSize: 11, color: C.textMid),
                                ),
                                C),
                            if (e.location?.mapId != null) ...[
                              const SizedBox(height: 6),
                              _DetailRow(
                                  'Standort',
                                  Text(
                                    e.location!.mapId,
                                    style: TextStyle(
                                        fontSize: 11, color: C.textMid),
                                  ),
                                  C),
                            ],
                            if (e.tags.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _DetailRow(
                                'Tags',
                                Wrap(
                                  spacing: 4,
                                  runSpacing: 4,
                                  children: e.tags
                                      .map((t) =>
                                          _TagPill(label: t, C: C))
                                      .toList(),
                                ),
                                C,
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Action buttons
                            Row(
                              children: [
                                Expanded(
                                  child: FilledButton.icon(
                                    onPressed: widget.onEdit,
                                    icon: AppIcon(AppIconName.edit,
                                        size: 11, color: Colors.white),
                                    label: const Text('Bearbeiten',
                                        style: TextStyle(fontSize: 11)),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: C.accent,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 7),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(6)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton(
                                  onPressed: widget.onDelete,
                                  style: OutlinedButton.styleFrom(
                                    side: BorderSide(color: C.border),
                                    foregroundColor: C.red,
                                    padding: const EdgeInsets.all(7),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6)),
                                    minimumSize: const Size(36, 36),
                                  ),
                                  child: AppIcon(AppIconName.trash,
                                      size: 11, color: C.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── EDITOR SEITENLEISTE ───────────────────────────────────────────────────────

class _EditorLeiste extends StatefulWidget {
  const _EditorLeiste({
    required this.entry,
    required this.vm,
    required this.onClose,
  });

  final WikiEntry? entry;
  final WikiViewModel vm;
  final VoidCallback onClose;

  @override
  State<_EditorLeiste> createState() => _EditorLeisteState();
}

class _EditorLeisteState extends State<_EditorLeiste> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _locationCtrl;
  final TextEditingController _tagCtrl = TextEditingController();

  late WikiEntryType _type;
  late bool _isGlobal;
  late List<String> _tags;
  bool _saving = false;

  bool get _isNew => widget.entry == null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _titleCtrl = TextEditingController(text: e?.title ?? '');
    _contentCtrl = TextEditingController(text: e?.content ?? '');
    _locationCtrl = TextEditingController(text: e?.location?.mapId ?? '');
    _type = e?.entryType ?? WikiEntryType.Lore;
    _isGlobal = e?.isGlobal ?? true;
    _tags = List<String>.from(e?.tags ?? []);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _locationCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagCtrl.clear();
    }
  }

  Future<void> _save(AppColorsExtension C) async {
    if (_titleCtrl.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Titel darf nicht leer sein');
      return;
    }
    setState(() => _saving = true);
    try {
      if (_isNew) {
        await widget.vm.addEntry(
          WikiEntry.create(
            title: _titleCtrl.text.trim(),
            content: _contentCtrl.text.trim(),
            entryType: _type,
            tags: _tags,
            campaignId: _isGlobal ? null : '',
          ),
        );
      } else {
        await widget.vm.updateEntry(
          widget.entry!.copyWith(
            title: _titleCtrl.text.trim(),
            content: _contentCtrl.text.trim(),
            entryType: _type,
            tags: _tags,
            campaignId: _isGlobal ? null : widget.entry!.campaignId,
          ),
        );
      }
      widget.onClose();
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final isDark = context.watch<ThemeNotifier>().isDark;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: C.bgPanel,
        child: Container(
          width: 420,
          constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.9),
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: C.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                blurRadius: 32,
                offset: const Offset(-8, 0),
              ),
            ],
          ),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────
              SafeArea(
                bottom: false,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration:
                      BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isNew ? 'Neuer Wiki-Eintrag' : 'Eintrag bearbeiten',
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: C.text),
                        ),
                      ),
                      _SmallIconBtn(
                          icon: AppIconName.close,
                          C: C,
                          onTap: widget.onClose),
                    ],
                  ),
                ),
              ),

              // ── Body ────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Titel
                      _FieldLabel('Titel *', C),
                      _InputField(ctrl: _titleCtrl, hint: 'Titel des Eintrags', C: C),
                      const SizedBox(height: 14),

                      // Typ
                      _FieldLabel('Eintragstyp', C),
                      Wrap(
                        spacing: 5,
                        runSpacing: 5,
                        children: WikiEntryType.values.map((type) {
                          final cfg = _cfg(type);
                          final active = _type == type;
                          return GestureDetector(
                            onTap: () => setState(() => _type = type),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: active
                                    ? (isDark ? cfg.bgDark : cfg.bgLight)
                                    : Colors.transparent,
                                border: Border.all(
                                    color: active ? cfg.dot : C.border),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                _label(type),
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: active
                                      ? FontWeight.w500
                                      : FontWeight.w400,
                                  color: active ? cfg.color : C.textMid,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Scope
                      _FieldLabel('Scope', C),
                      Row(
                        children: [
                          _ScopeBtn(
                              label: 'Global',
                              active: _isGlobal,
                              C: C,
                              onTap: () => setState(() => _isGlobal = true)),
                          const SizedBox(width: 5),
                          _ScopeBtn(
                              label: 'Kampagne',
                              active: !_isGlobal,
                              C: C,
                              onTap: () => setState(() => _isGlobal = false)),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Inhalt
                      _FieldLabel('Inhalt *', C),
                      _TextAreaField(
                          ctrl: _contentCtrl,
                          hint: 'Beschreibung des Wiki-Eintrags...',
                          C: C),
                      const SizedBox(height: 14),

                      // Tags
                      _FieldLabel('Tags', C),
                      if (_tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Wrap(
                            spacing: 5,
                            runSpacing: 5,
                            children: _tags
                                .map((t) => _RemovableTag(
                                      label: t,
                                      C: C,
                                      onRemove: () =>
                                          setState(() => _tags.remove(t)),
                                    ))
                                .toList(),
                          ),
                        ),
                      Row(
                        children: [
                          Expanded(
                            child: _InputField(
                              ctrl: _tagCtrl,
                              hint: 'Neuer Tag',
                              C: C,
                              onSubmitted: (_) => _addTag(),
                            ),
                          ),
                          const SizedBox(width: 6),
                          _SmallIconBtn(
                              icon: AppIconName.plus, C: C, onTap: _addTag),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Standort
                      _FieldLabel('Standort (Optional)', C),
                      _InputField(
                          ctrl: _locationCtrl,
                          hint: 'z.B. Phandalin',
                          C: C),
                      const SizedBox(height: 4),
                      Text(
                        'Für zukünftige Kartenintegration',
                        style: TextStyle(fontSize: 11, color: C.textSoft),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Footer ──────────────────────────────────
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration:
                    BoxDecoration(border: Border(top: BorderSide(color: C.border))),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onClose,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: C.border),
                          foregroundColor: C.textMid,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7)),
                        ),
                        child: const Text('Abbrechen',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w500)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed: _saving ? null : () => _save(C),
                        icon: _saving
                            ? const SizedBox(
                                width: 13,
                                height: 13,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : AppIcon(AppIconName.save, size: 13,
                                color: Colors.white),
                        label: Text(
                          _isNew ? 'Erstellen' : 'Speichern',
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: C.accent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(7)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SHARED SMALL WIDGETS ──────────────────────────────────────────────────────

class _TypBadge extends StatelessWidget {
  const _TypBadge(
      {required this.type, required this.isDark, this.small = false});

  final WikiEntryType type;
  final bool isDark;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg(type);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: small ? 6 : 8, vertical: small ? 1 : 2),
      decoration: BoxDecoration(
        color: isDark ? cfg.bgDark : cfg.bgLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 5,
              height: 5,
              decoration:
                  BoxDecoration(color: cfg.dot, shape: BoxShape.circle)),
          const SizedBox(width: 4),
          Text(
            _label(type),
            style: TextStyle(
                fontSize: small ? 10 : 11,
                fontWeight: FontWeight.w500,
                color: cfg.color),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.count,
    required this.isActive,
    required this.color,
    required this.dot,
    required this.activeBg,
    required this.C,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isActive;
  final Color color;
  final Color dot;
  final Color activeBg;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? activeBg : C.bgPanel,
            border: Border.all(color: isActive ? dot : C.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
                  color: isActive ? color : C.textMid,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  color:
                      isActive ? color.withValues(alpha: 0.7) : C.textSoft,
                ),
              ),
            ],
          ),
        ),
      );
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label, required this.C});

  final String label;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        decoration: BoxDecoration(
          color: C.bgHover,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 10, color: C.textSoft)),
      );
}

class _RemovableTag extends StatelessWidget {
  const _RemovableTag(
      {required this.label, required this.C, required this.onRemove});

  final String label;
  final AppColorsExtension C;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: C.bgHover,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: C.textMid)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: Text('×',
                  style: TextStyle(
                      fontSize: 13,
                      color: C.textSoft,
                      height: 1)),
            ),
          ],
        ),
      );
}

class _SmallIconBtn extends StatefulWidget {
  const _SmallIconBtn(
      {required this.icon,
      required this.C,
      required this.onTap,
      this.active = false});

  final AppIconName icon;
  final AppColorsExtension C;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_SmallIconBtn> createState() => _SmallIconBtnState();
}

class _SmallIconBtnState extends State<_SmallIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 26,
            height: 26,
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              color: widget.active || _hovered
                  ? widget.C.bgActive
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: AppIcon(widget.icon, size: 12, color: widget.C.textSoft),
            ),
          ),
        ),
      );
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.C);

  final String text;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: C.textSoft,
          letterSpacing: 0.4,
        ),
      );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.valueWidget, this.C);

  final String label;
  final Widget valueWidget;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(label,
                style: TextStyle(fontSize: 11, color: C.textSoft)),
          ),
          const SizedBox(width: 8),
          Expanded(child: valueWidget),
        ],
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, this.C);

  final String text;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          text.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: C.textSoft,
            letterSpacing: 0.4,
          ),
        ),
      );
}

class _InputField extends StatelessWidget {
  const _InputField(
      {required this.ctrl,
      required this.hint,
      required this.C,
      this.onSubmitted});

  final TextEditingController ctrl;
  final String hint;
  final AppColorsExtension C;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        style: TextStyle(fontSize: 13, color: C.text),
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: C.textSoft),
          filled: true,
          fillColor: C.bgHover,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

class _TextAreaField extends StatelessWidget {
  const _TextAreaField(
      {required this.ctrl, required this.hint, required this.C});

  final TextEditingController ctrl;
  final String hint;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        maxLines: 6,
        style: TextStyle(fontSize: 13, color: C.text, height: 1.5),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: C.textSoft),
          filled: true,
          fillColor: C.bgHover,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

class _ScopeBtn extends StatelessWidget {
  const _ScopeBtn(
      {required this.label,
      required this.active,
      required this.C,
      required this.onTap});

  final String label;
  final bool active;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: active ? C.accent : Colors.transparent,
            border: Border.all(color: active ? C.accent : C.border),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.white : C.textMid,
            ),
          ),
        ),
      );
}

class _IconBtn extends StatefulWidget {
  const _IconBtn(
      {required this.C, required this.icon, required this.onTap});

  final AppColorsExtension C;
  final AppIconName icon;
  final VoidCallback onTap;

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color:
                  _hovered ? widget.C.bgHover : Colors.transparent,
              border: Border.all(
                  color: _hovered
                      ? widget.C.border
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: AppIcon(widget.icon, size: 14,
                  color: widget.C.textMid),
            ),
          ),
        ),
      );
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

String _formatDate(DateTime dt) {
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 60) return 'vor ${diff.inMinutes} Min';
  if (diff.inHours < 24) return 'vor ${diff.inHours} Std';
  if (diff.inDays == 1) return 'gestern';
  if (diff.inDays < 7) return 'vor ${diff.inDays} Tagen';
  return '${dt.day}.${dt.month}.${dt.year}';
}
