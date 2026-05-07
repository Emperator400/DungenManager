import 'package:flutter/material.dart';

import '../../models/quest.dart';
import '../../theme/app_theme.dart';

class QuestPickerDialog extends StatefulWidget {
  const QuestPickerDialog({
    super.key,
    required this.quests,
    this.title = 'Aus Questbibliothek wählen',
  });

  final List<Quest> quests;
  final String title;

  static Future<Quest?> show(
    BuildContext context, {
    required List<Quest> quests,
    String title = 'Aus Questbibliothek wählen',
  }) =>
      showDialog<Quest>(
        context: context,
        builder: (_) => QuestPickerDialog(quests: quests, title: title),
      );

  @override
  State<QuestPickerDialog> createState() => _QuestPickerDialogState();
}

class _QuestPickerDialogState extends State<QuestPickerDialog> {
  final _searchCtrl = TextEditingController();
  QuestType? _activeFilter;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Quest> get _filtered {
    var list = widget.quests;
    if (_activeFilter != null) list = list.where((q) => q.questType == _activeFilter).toList();
    if (_query.isNotEmpty) {
      list = list.where((q) => q.title.toLowerCase().contains(_query) || q.description.toLowerCase().contains(_query)).toList();
    }
    return list;
  }

  List<QuestType> get _availableTypes =>
      QuestType.values.where((t) => widget.quests.any((q) => q.questType == t)).toList();

  Color _typeColor(QuestType t, AppColorsExtension C) {
    switch (t) {
      case QuestType.main:     return C.accent;
      case QuestType.side:     return C.green;
      case QuestType.personal: return C.amber;
      case QuestType.faction:  return C.red;
    }
  }

  String _typeLabel(QuestType t) {
    switch (t) {
      case QuestType.main:     return 'Haupt';
      case QuestType.side:     return 'Neben';
      case QuestType.personal: return 'Persönlich';
      case QuestType.faction:  return 'Fraktion';
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

            if (types.length > 1) ...[
              SizedBox(
                height: 30,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  children: [
                    _QuestFilterChip(
                      label: 'Alle',
                      active: _activeFilter == null,
                      color: C.textMid,
                      C: C,
                      onTap: () => setState(() => _activeFilter = null),
                    ),
                    ...types.map((t) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _QuestFilterChip(
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

            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.quests.isEmpty ? 'Keine Quests in der Bibliothek' : 'Keine Quests gefunden',
                        style: TextStyle(fontSize: 13, color: C.textSoft),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final quest = filtered[i];
                        final color = _typeColor(quest.questType, C);
                        return _QuestTile(
                          quest: quest,
                          color: color,
                          typeLabel: _typeLabel(quest.questType),
                          C: C,
                          onTap: () => Navigator.of(context).pop(quest),
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

class _QuestFilterChip extends StatelessWidget {
  const _QuestFilterChip({required this.label, required this.active, required this.color, required this.C, required this.onTap});

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

class _QuestTile extends StatefulWidget {
  const _QuestTile({required this.quest, required this.color, required this.typeLabel, required this.C, required this.onTap});

  final Quest quest;
  final Color color;
  final String typeLabel;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  State<_QuestTile> createState() => _QuestTileState();
}

class _QuestTileState extends State<_QuestTile> {
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
                      widget.quest.title,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.quest.description.isNotEmpty)
                      Text(
                        widget.quest.description,
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
