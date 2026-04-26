import 'package:flutter/material.dart';

import '../../../models/quest.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/ui_components/shared/app_icon.dart';
import '../base/unified_card_base.dart';

class UnifiedQuestCard extends UnifiedCardBase {
  const UnifiedQuestCard({
    required this.quest,
    super.key,
    super.onTap,
    super.onEdit,
    super.onDelete,
    super.onToggleFavorite,
    super.isSelected,
  });

  final Quest quest;

  @override
  Widget buildCardContent(BuildContext context) =>
      _QuestCardContent(card: this);
}

// ── CARD CONTENT ──────────────────────────────────────────────────────────────

class _QuestCardContent extends StatefulWidget {
  const _QuestCardContent({required this.card});
  final UnifiedQuestCard card;

  @override
  State<_QuestCardContent> createState() => _QuestCardContentState();
}

class _QuestCardContentState extends State<_QuestCardContent> {
  bool _hovered = false;
  UnifiedQuestCard get c => widget.card;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final stripeColor = _typeColor(c.quest.questType, C);

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
              Container(height: 3, color: stripeColor),
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
                          icon: _typeIcon(c.quest.questType),
                          color: stripeColor,
                          bg: stripeColor.withValues(alpha: 0.12),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.quest.title,
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
                              Row(
                                children: [
                                  _StatusBadge(quest: c.quest, C: C),
                                  const SizedBox(width: 4),
                                  _DiffBadge(quest: c.quest, C: C),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (_hovered) ...[
                          _IconBtn(C: C, icon: AppIconName.edit, onTap: c.onEdit),
                          const SizedBox(width: 2),
                          _PopupBtn(card: c, C: C),
                        ],
                      ],
                    ),

                    // Beschreibung
                    if (c.quest.description.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        c.quest.description,
                        style: TextStyle(fontSize: 12, color: C.textMid, height: 1.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Meta
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        if (c.quest.recommendedLevel != null) ...[
                          _MetaChip(icon: AppIconName.star, value: 'Lvl ${c.quest.recommendedLevel}', C: C),
                          const SizedBox(width: 8),
                        ],
                        if (c.quest.totalGoldAmount > 0) ...[
                          _MetaChip(icon: AppIconName.scroll, value: '${c.quest.totalGoldAmount.toStringAsFixed(0)} G', C: C),
                          const SizedBox(width: 8),
                        ],
                        if (c.quest.totalXP > 0)
                          _MetaChip(icon: AppIconName.shield, value: '${c.quest.totalXP} XP', C: C),
                        const Spacer(),
                        Text(
                          _relativeDate(c.quest.updatedAt),
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
  final UnifiedQuestCard card;
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
        onSelected: (v) {
          if (v == 'delete') {
            card.onDelete?.call();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                AppIcon(AppIconName.trash, size: 13, color: C.red),
                const SizedBox(width: 8),
                Text('Löschen', style: TextStyle(fontSize: 13, color: C.red)),
              ],
            ),
          ),
        ],
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(color: C.bgHover, borderRadius: BorderRadius.circular(5)),
          child: Center(child: AppIcon(AppIconName.dots, size: 12, color: C.textSoft)),
        ),
      );
}

// ── HILFSWIDGETS ──────────────────────────────────────────────────────────────

class _TypeAvatar extends StatelessWidget {
  const _TypeAvatar({required this.icon, required this.color, required this.bg});
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
        child: Center(child: AppIcon(icon, color: color)),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.quest, required this.C});
  final Quest quest;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = _statusColors(quest.status, C);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(
        _statusLabel(quest.status),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: fg),
      ),
    );
  }
}

class _DiffBadge extends StatelessWidget {
  const _DiffBadge({required this.quest, required this.C});
  final Quest quest;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(color: C.bgHover, borderRadius: BorderRadius.circular(4)),
        child: Text(
          quest.difficultyDescription,
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
          decoration: BoxDecoration(color: C.bgActive, borderRadius: BorderRadius.circular(5)),
          child: Center(child: AppIcon(icon, size: 12, color: C.textSoft)),
        ),
      );
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

Color _typeColor(QuestType t, AppColorsExtension C) {
  switch (t) {
    case QuestType.main:
      return C.accent;
    case QuestType.side:
      return C.green;
    case QuestType.personal:
      return C.amber;
    case QuestType.faction:
      return const Color(0xFF7C3AED);
  }
}

AppIconName _typeIcon(QuestType t) {
  switch (t) {
    case QuestType.main:
      return AppIconName.star;
    case QuestType.side:
      return AppIconName.scroll;
    case QuestType.personal:
      return AppIconName.user;
    case QuestType.faction:
      return AppIconName.users;
  }
}

(Color, Color) _statusColors(QuestStatus s, AppColorsExtension C) {
  switch (s) {
    case QuestStatus.active:
      return (C.accent, C.accentSoft);
    case QuestStatus.completed:
      return (C.green, C.greenSoft);
    case QuestStatus.failed:
    case QuestStatus.abandoned:
      return (C.red, C.redSoft);
    case QuestStatus.onHold:
      return (C.amber, C.amberSoft);
  }
}

String _statusLabel(QuestStatus s) {
  switch (s) {
    case QuestStatus.active:
      return 'Aktiv';
    case QuestStatus.completed:
      return 'Erledigt';
    case QuestStatus.failed:
      return 'Fehlgeschlagen';
    case QuestStatus.abandoned:
      return 'Aufgegeben';
    case QuestStatus.onHold:
      return 'Pausiert';
  }
}

String _relativeDate(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 7) {
    return '${date.day}.${date.month}.${date.year}';
  }
  if (diff.inDays > 0) {
    return 'vor ${diff.inDays}d';
  }
  return 'heute';
}
