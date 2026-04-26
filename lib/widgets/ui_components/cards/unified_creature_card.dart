import 'package:flutter/material.dart';

import '../../../models/creature.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/ui_components/shared/app_icon.dart';
import '../base/unified_card_base.dart';

class UnifiedCreatureCard extends UnifiedCardBase {
  const UnifiedCreatureCard({
    required this.creature,
    super.key,
    super.onTap,
    super.onEdit,
    super.onDelete,
    super.onToggleFavorite,
    super.isSelected,
  });

  final Creature creature;

  @override
  Widget buildCardContent(BuildContext context) =>
      _CreatureCardContent(card: this);
}

// ── CARD CONTENT ──────────────────────────────────────────────────────────────

class _CreatureCardContent extends StatefulWidget {
  const _CreatureCardContent({required this.card});
  final UnifiedCreatureCard card;

  @override
  State<_CreatureCardContent> createState() => _CreatureCardContentState();
}

class _CreatureCardContentState extends State<_CreatureCardContent> {
  bool _hovered = false;
  UnifiedCreatureCard get c => widget.card;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final stripeColor = _typeColor(c.creature.type, C);

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
                        _Avatar(
                          letter: c.creature.name.isNotEmpty
                              ? c.creature.name[0].toUpperCase()
                              : '?',
                          color: stripeColor,
                          bg: stripeColor.withValues(alpha: 0.12),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.creature.name,
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
                              _TypeBadge(creature: c.creature, color: stripeColor, C: C),
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

                    // Beschreibung / Fähigkeiten
                    if (c.creature.specialAbilities != null &&
                        c.creature.specialAbilities!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        c.creature.specialAbilities!,
                        style: TextStyle(fontSize: 12, color: C.textMid, height: 1.5),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],

                    // Kampfwerte
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _StatChip(icon: AppIconName.shield, label: 'AC', value: '${c.creature.armorClass}', C: C),
                        const SizedBox(width: 8),
                        _StatChip(icon: AppIconName.heart, label: 'HP', value: '${c.creature.maxHp}', C: C),
                        if (c.creature.challengeRating != null) ...[
                          const SizedBox(width: 8),
                          _StatChip(icon: AppIconName.star, label: 'CR', value: '${c.creature.challengeRating}', C: C),
                        ],
                        const Spacer(),
                        if (c.creature.size != null)
                          Text(
                            c.creature.size!,
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
  final UnifiedCreatureCard card;
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

class _Avatar extends StatelessWidget {
  const _Avatar({required this.letter, required this.color, required this.bg});
  final String letter;
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
            letter,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color),
          ),
        ),
      );
}

class _TypeBadge extends StatelessWidget {
  const _TypeBadge({required this.creature, required this.color, required this.C});
  final Creature creature;
  final Color color;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    final label = [
      if (creature.type != null) creature.type!,
      if (creature.subtype != null) '(${creature.subtype})',
    ].join(' ');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label.isNotEmpty ? label : 'Kreatur',
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: color),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.label, required this.value, required this.C});
  final AppIconName icon;
  final String label;
  final String value;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(icon, size: 11, color: C.textSoft),
          const SizedBox(width: 3),
          Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text),
          ),
          const SizedBox(width: 1),
          Text(label, style: TextStyle(fontSize: 9, color: C.textSoft)),
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

Color _typeColor(String? type, AppColorsExtension C) {
  final t = (type ?? '').toLowerCase();
  if (t.contains('dragon')) {
    return const Color(0xFFC93A3A);
  }
  if (t.contains('undead')) {
    return const Color(0xFF7C3AED);
  }
  if (t.contains('fiend') || t.contains('devil') || t.contains('demon')) {
    return const Color(0xFFBE185D);
  }
  if (t.contains('beast')) {
    return const Color(0xFF1A7F4B);
  }
  if (t.contains('humanoid')) {
    return const Color(0xFF2F6FEB);
  }
  if (t.contains('elemental')) {
    return const Color(0xFF0891B2);
  }
  return C.textMid;
}
