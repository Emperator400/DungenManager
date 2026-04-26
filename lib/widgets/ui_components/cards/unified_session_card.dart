import 'package:flutter/material.dart';

import '../../../models/session.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/ui_components/shared/app_icon.dart';
import '../base/unified_card_base.dart';

class UnifiedSessionCard extends UnifiedCardBase {
  const UnifiedSessionCard({
    required this.session,
    required this.sessionNumber,
    super.key,
    super.onTap,
    super.onEdit,
    super.onDelete,
    super.isSelected,
    this.onPlay,
  });

  final Session session;
  final int sessionNumber;
  final VoidCallback? onPlay;

  @override
  Widget buildCardContent(BuildContext context) =>
      _SessionCardContent(card: this);
}

// ── CARD CONTENT ──────────────────────────────────────────────────────────────

class _SessionCardContent extends StatefulWidget {
  const _SessionCardContent({required this.card});
  final UnifiedSessionCard card;

  @override
  State<_SessionCardContent> createState() => _SessionCardContentState();
}

class _SessionCardContentState extends State<_SessionCardContent> {
  bool _hovered = false;
  UnifiedSessionCard get c => widget.card;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final isActive = c.session.completedAt == null;
    final stripeColor = isActive ? C.accent : C.green;

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
                        _NumberAvatar(
                          number: c.sessionNumber,
                          color: stripeColor,
                          bg: stripeColor.withValues(alpha: 0.12),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.session.title,
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
                              _StatusBadge(isActive: isActive, C: C),
                            ],
                          ),
                        ),
                        // Play-Button immer sichtbar
                        if (c.onPlay != null) ...[
                          _PlayBtn(onPlay: c.onPlay!, C: C),
                          const SizedBox(width: 2),
                        ],
                        if (_hovered) ...[
                          _IconBtn(C: C, icon: AppIconName.edit, onTap: c.onEdit),
                          const SizedBox(width: 2),
                          _PopupBtn(card: c, C: C),
                        ],
                      ],
                    ),

                    // Notizen-Vorschau
                    if (c.session.liveNotes.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        c.session.liveNotes,
                        style: TextStyle(fontSize: 12, color: C.textMid, height: 1.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Meta
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _MetaChip(
                          icon: AppIconName.play,
                          value: _formatDuration(c.session.inGameTimeInMinutes),
                          C: C,
                        ),
                        if (c.session.sceneIds.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _MetaChip(
                            icon: AppIconName.folder,
                            value: '${c.session.sceneIds.length} Scenes',
                            C: C,
                          ),
                        ],
                        if (c.session.encounterIds.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          _MetaChip(
                            icon: AppIconName.sword,
                            value: '${c.session.encounterIds.length}',
                            C: C,
                          ),
                        ],
                        const Spacer(),
                        Text(
                          _formatDate(c.session.createdAt),
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

// ── POPUP ─────────────────────────────────────────────────────────────────────

class _PopupBtn extends StatelessWidget {
  const _PopupBtn({required this.card, required this.C});
  final UnifiedSessionCard card;
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

class _NumberAvatar extends StatelessWidget {
  const _NumberAvatar({required this.number, required this.color, required this.bg});
  final int number;
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
          child: Text(
            '#$number',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isActive, required this.C});
  final bool isActive;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: isActive ? C.accentSoft : C.greenSoft,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          isActive ? 'Geplant' : 'Abgeschlossen',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: isActive ? C.accent : C.green,
          ),
        ),
      );
}

class _PlayBtn extends StatelessWidget {
  const _PlayBtn({required this.onPlay, required this.C});
  final VoidCallback onPlay;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPlay,
        child: Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: C.accentSoft,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(child: AppIcon(AppIconName.play, size: 12, color: C.accent)),
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

String _formatDuration(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return h > 0 ? '${h}h ${m}min' : '${m}min';
}

String _formatDate(DateTime d) => '${d.day}.${d.month}.${d.year}';
