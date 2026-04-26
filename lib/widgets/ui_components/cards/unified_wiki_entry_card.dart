import 'package:flutter/material.dart';

import '../../../models/wiki_entry.dart';
import '../../../theme/app_colors_map.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/ui_components/shared/app_icon.dart';
import '../base/unified_card_base.dart';

class UnifiedWikiEntryCard extends UnifiedCardBase {
  const UnifiedWikiEntryCard({
    required this.entry,
    super.key,
    super.onTap,
    super.onEdit,
    super.onDelete,
    super.onToggleFavorite,
    super.isSelected,
  });

  final WikiEntry entry;

  @override
  Widget buildCardContent(BuildContext context) =>
      _WikiEntryCardContent(card: this);
}

// ── CARD CONTENT ──────────────────────────────────────────────────────────────

class _WikiEntryCardContent extends StatefulWidget {
  const _WikiEntryCardContent({required this.card});

  final UnifiedWikiEntryCard card;

  @override
  State<_WikiEntryCardContent> createState() => _WikiEntryCardContentState();
}

class _WikiEntryCardContentState extends State<_WikiEntryCardContent> {
  bool _hovered = false;

  UnifiedWikiEntryCard get c => widget.card;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final typeName = _typeName(c.entry.entryType);
    final typeConfig = AppTypeColors.of(typeName);
    final bright = Theme.of(context).brightness == Brightness.light;
    final typeBg = bright ? typeConfig.bgLight : typeConfig.bgDark;
    final typeColor = typeConfig.color;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: c.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          color: _hovered ? C.bgHover : C.bgPanel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Farbstreifen
              Container(height: 3, color: typeColor),

              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TypeAvatar(
                          letter: c.entry.title.isNotEmpty
                              ? c.entry.title[0].toUpperCase()
                              : '?',
                          icon: _typeIcon(c.entry.entryType),
                          color: typeColor,
                          bg: typeBg,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.entry.title,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: C.text,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              _TypeBadge(
                                label: typeName,
                                color: typeColor,
                                bg: typeBg,
                                isGlobal: c.entry.campaignId == null,
                                C: C,
                              ),
                            ],
                          ),
                        ),
                        if (_hovered) ...[
                          _IconBtn(
                            C: C,
                            icon: AppIconName.edit,
                            onTap: c.onEdit,
                          ),
                          const SizedBox(width: 2),
                          _PopupBtn(card: c, C: C),
                        ],
                      ],
                    ),

                    // Inhalt-Vorschau
                    if (c.entry.content.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        _stripMarkdown(c.entry.content),
                        style: TextStyle(
                          fontSize: 12,
                          color: C.textMid,
                          height: 1.5,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Tags
                    if (c.entry.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        runSpacing: 4,
                        children: c.entry.tags
                            .take(4)
                            .map((tag) => _TagChip(label: tag, C: C))
                            .toList(),
                      ),
                    ],

                    // Meta-Zeile
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (c.entry.childIds.isNotEmpty) ...[
                          _MetaChip(
                            icon: AppIconName.link,
                            value: '${c.entry.childIds.length}',
                            C: C,
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (c.entry.location != null) ...[
                          _MetaChip(
                            icon: AppIconName.location,
                            value: 'Karte',
                            C: C,
                          ),
                          const SizedBox(width: 10),
                        ],
                        const Spacer(),
                        Text(
                          _relativeDate(c.entry.updatedAt),
                          style: TextStyle(fontSize: 10, color: C.textSoft),
                        ),
                      ],
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

// ── POPUP MENU ────────────────────────────────────────────────────────────────

class _PopupBtn extends StatelessWidget {
  const _PopupBtn({required this.card, required this.C});

  final UnifiedWikiEntryCard card;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
        tooltip: '',
        color: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: C.border),
        ),
        offset: const Offset(0, 30),
        onSelected: (v) => _handle(context, v),
        itemBuilder: (_) => [
          _item('delete', AppIconName.trash, 'Löschen', C, color: C.red),
        ],
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: C.bgHover,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: AppIcon(AppIconName.dots, size: 12, color: C.textSoft),
          ),
        ),
      );

  PopupMenuItem<String> _item(
    String value,
    AppIconName icon,
    String label,
    AppColorsExtension C, {
    Color? color,
  }) =>
      PopupMenuItem(
        value: value,
        child: Row(
          children: [
            AppIcon(icon, size: 13, color: color ?? C.textMid),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(fontSize: 13, color: color ?? C.text),
            ),
          ],
        ),
      );

  void _handle(BuildContext context, String action) {
    switch (action) {
      case 'delete':
        _showDeleteDialog(context);
    }
  }

  Future<void> _showDeleteDialog(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => _DeleteDialog(title: card.entry.title, C: C),
    );
    if ((confirmed ?? false) && context.mounted) {
      card.onDelete?.call();
    }
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.title, required this.C});

  final String title;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Dialog(
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
              Text(
                'Eintrag löschen',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: C.red,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Möchtest du "$title" wirklich löschen? '
                'Diese Aktion kann nicht rückgängig gemacht werden.',
                style: TextStyle(fontSize: 13, color: C.textMid),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: C.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(
                      'Abbrechen',
                      style: TextStyle(color: C.textMid, fontSize: 13),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: C.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child:
                        const Text('Löschen', style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
}

// ── HELPER WIDGETS ────────────────────────────────────────────────────────────

class _TypeAvatar extends StatelessWidget {
  const _TypeAvatar({
    required this.letter,
    required this.icon,
    required this.color,
    required this.bg,
  });

  final String letter;
  final AppIconName icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) => Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: color.withValues(alpha: 0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: AppIcon(icon, color: color),
        ),
      );
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({
    required this.label,
    required this.color,
    required this.bg,
    required this.isGlobal,
    required this.C,
  });

  final String label;
  final Color color;
  final Color bg;
  final bool isGlobal;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          if (isGlobal) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: C.bgHover,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'Global',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: C.textSoft,
                ),
              ),
            ),
          ],
        ],
      );
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, required this.C});

  final String label;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
        decoration: BoxDecoration(
          color: C.bgHover,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, color: C.textSoft),
        ),
      );
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.value, required this.C});

  final AppIconName icon;
  final String value;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 11, color: C.textSoft),
          const SizedBox(width: 3),
          Text(value, style: TextStyle(fontSize: 11, color: C.textSoft)),
        ],
      );
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.C, required this.icon, this.onTap});

  final AppColorsExtension C;
  final AppIconName icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: C.bgActive,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(
            child: AppIcon(icon, size: 12, color: C.textSoft),
          ),
        ),
      );
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

String _typeName(WikiEntryType t) {
  switch (t) {
    case WikiEntryType.Person:
      return 'NPC';
    case WikiEntryType.Place:
      return 'Ort';
    case WikiEntryType.Lore:
      return 'Lore';
    case WikiEntryType.Faction:
      return 'Fraktion';
    case WikiEntryType.Magic:
      return 'Magie';
    case WikiEntryType.History:
      return 'Geschichte';
    case WikiEntryType.Item:
      return 'Gegenstand';
    case WikiEntryType.Quest:
      return 'Quest';
    case WikiEntryType.Creature:
      return 'Kreatur';
  }
}

AppIconName _typeIcon(WikiEntryType t) {
  switch (t) {
    case WikiEntryType.Person:
      return AppIconName.user;
    case WikiEntryType.Place:
      return AppIconName.location;
    case WikiEntryType.Lore:
      return AppIconName.book;
    case WikiEntryType.Faction:
      return AppIconName.users;
    case WikiEntryType.Magic:
      return AppIconName.star;
    case WikiEntryType.History:
      return AppIconName.scroll;
    case WikiEntryType.Item:
      return AppIconName.folder;
    case WikiEntryType.Quest:
      return AppIconName.check;
    case WikiEntryType.Creature:
      return AppIconName.shield;
  }
}

String _stripMarkdown(String text) {
  var s = text;
  s = s.replaceAllMapped(RegExp(r'\*\*(.*?)\*\*'), (m) => m[1] ?? '');
  s = s.replaceAllMapped(RegExp(r'\*(.*?)\*'), (m) => m[1] ?? '');
  s = s.replaceAllMapped(RegExp('_(.*?)_'), (m) => m[1] ?? '');
  s = s.replaceAllMapped(RegExp('`(.*?)`'), (m) => m[1] ?? '');
  s = s.replaceAll(RegExp(r'#{1,6}\s*'), '');
  s = s.replaceAllMapped(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), (m) => m[1] ?? '');
  s = s.replaceAll('\n', ' ');
  return s.trim();
}

String _relativeDate(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 7) {
    return '${date.day}.${date.month}.${date.year}';
  }
  if (diff.inDays > 0) {
    return 'vor ${diff.inDays} ${diff.inDays == 1 ? 'Tag' : 'Tagen'}';
  }
  if (diff.inHours > 0) {
    return 'vor ${diff.inHours} ${diff.inHours == 1 ? 'Stunde' : 'Stunden'}';
  }
  return 'vor ${diff.inMinutes} ${diff.inMinutes == 1 ? 'Minute' : 'Minuten'}';
}
