import 'package:flutter/material.dart';

import '../../models/wiki_entry.dart';
import '../../theme/app_theme.dart';

class LoreKeeperPickerDialog extends StatefulWidget {
  const LoreKeeperPickerDialog({
    super.key,
    required this.entries,
    this.typeFilter,
    this.title = 'Aus LoreKeeper wählen',
  });

  final List<WikiEntry> entries;
  final List<WikiEntryType>? typeFilter;
  final String title;

  /// Öffnet den Dialog und gibt den gewählten Eintrag zurück (null = abgebrochen).
  static Future<WikiEntry?> show(
    BuildContext context, {
    required List<WikiEntry> entries,
    List<WikiEntryType>? typeFilter,
    String title = 'Aus LoreKeeper wählen',
  }) =>
      showDialog<WikiEntry>(
        context: context,
        builder: (_) => LoreKeeperPickerDialog(
          entries: entries,
          typeFilter: typeFilter,
          title: title,
        ),
      );

  @override
  State<LoreKeeperPickerDialog> createState() => _LoreKeeperPickerDialogState();
}

class _LoreKeeperPickerDialogState extends State<LoreKeeperPickerDialog> {
  final _searchCtrl = TextEditingController();
  WikiEntryType? _activeFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    if (widget.typeFilter?.length == 1) _activeFilter = widget.typeFilter!.first;
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<WikiEntry> get _filtered {
    var list = widget.entries;
    if (widget.typeFilter != null) list = list.where((e) => widget.typeFilter!.contains(e.entryType)).toList();
    if (_activeFilter != null) list = list.where((e) => e.entryType == _activeFilter).toList();
    if (_query.isNotEmpty) list = list.where((e) => e.title.toLowerCase().contains(_query)).toList();
    return list;
  }

  List<WikiEntryType> get _availableTypes {
    final base = widget.typeFilter ?? WikiEntryType.values;
    return base.where((t) => widget.entries.any((e) => e.entryType == t)).toList();
  }

  Color _typeColor(WikiEntryType t, AppColorsExtension C) {
    switch (t) {
      case WikiEntryType.Person:   return C.green;
      case WikiEntryType.Place:    return C.accent;
      case WikiEntryType.Quest:    return C.amber;
      case WikiEntryType.Creature: return C.red;
      case WikiEntryType.Faction:  return C.accent;
      case WikiEntryType.Item:     return C.amber;
      default:                     return C.textMid;
    }
  }

  String _typeLabel(WikiEntryType t) {
    switch (t) {
      case WikiEntryType.Person:   return 'NPC';
      case WikiEntryType.Place:    return 'Ort';
      case WikiEntryType.Quest:    return 'Quest';
      case WikiEntryType.Creature: return 'Kreatur';
      case WikiEntryType.Faction:  return 'Fraktion';
      case WikiEntryType.Item:     return 'Gegenstand';
      case WikiEntryType.Lore:     return 'Lore';
      case WikiEntryType.Magic:    return 'Magie';
      case WikiEntryType.History:  return 'Geschichte';
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final filtered = _filtered;
    final types = _availableTypes;

    return Dialog(
      backgroundColor: C.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: C.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 560),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 12, 12),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, size: 16, color: C.textSoft),
                  ),
                ],
              ),
            ),

            // Suche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                style: TextStyle(fontSize: 13, color: C.text),
                decoration: InputDecoration(
                  hintText: 'Suchen…',
                  hintStyle: TextStyle(color: C.textSoft),
                  prefixIcon: Icon(Icons.search, size: 16, color: C.textSoft),
                  filled: true,
                  fillColor: C.bgHover,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: C.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: C.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: C.accent)),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Typ-Filter (nur wenn mehrere verfügbar)
            if (types.length > 1) ...[
              SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _FilterChip(
                      label: 'Alle',
                      active: _activeFilter == null,
                      color: C.textMid,
                      C: C,
                      onTap: () => setState(() => _activeFilter = null),
                    ),
                    ...types.map((t) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _FilterChip(
                            label: _typeLabel(t),
                            active: _activeFilter == t,
                            color: _typeColor(t, C),
                            C: C,
                            onTap: () => setState(() => _activeFilter = _activeFilter == t ? null : t),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],

            Divider(height: 1, thickness: 1, color: C.border),

            // Ergebnisliste
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        'Keine Einträge gefunden',
                        style: TextStyle(fontSize: 13, color: C.textSoft),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final entry = filtered[i];
                        final color = _typeColor(entry.entryType, C);
                        return _EntryTile(
                          entry: entry,
                          color: color,
                          typeLabel: _typeLabel(entry.entryType),
                          C: C,
                          onTap: () => Navigator.of(context).pop(entry),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.active, required this.color, required this.C, required this.onTap});

  final String label;
  final bool active;
  final Color color;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: active ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: active ? color.withValues(alpha: 0.4) : C.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: active ? color : C.textMid,
              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
}

class _EntryTile extends StatefulWidget {
  const _EntryTile({required this.entry, required this.color, required this.typeLabel, required this.C, required this.onTap});

  final WikiEntry entry;
  final Color color;
  final String typeLabel;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  State<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends State<_EntryTile> {
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
          duration: const Duration(milliseconds: 80),
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: _hovered ? C.bgHover : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 36,
                decoration: BoxDecoration(
                  color: widget.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.title,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.entry.content.isNotEmpty)
                      Text(
                        widget.entry.content,
                        style: TextStyle(fontSize: 10, color: C.textSoft),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  widget.typeLabel,
                  style: TextStyle(fontSize: 9, color: widget.color, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
