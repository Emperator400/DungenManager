import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../shared/unified_card_theme.dart';

class UnifiedInfoChip extends StatelessWidget {
  const UnifiedInfoChip({
    required this.label,
    required this.value,
    super.key,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.borderColor,
    this.fontSize,
    this.iconSize,
    this.padding,
    this.onTap,
    this.showBorder = true,
    this.isCompact = false,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final Color? borderColor;
  final double? fontSize;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final bool showBorder;
  final bool isCompact;

  factory UnifiedInfoChip.combat({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
    bool isCompact = false,
  }) {
    final c = color ?? const Color(0xFF2F6FEB);
    return UnifiedInfoChip(
      label: label,
      value: value,
      icon: icon,
      backgroundColor: c.withValues(alpha: 0.15),
      textColor: c,
      iconColor: c,
      borderColor: c.withValues(alpha: 0.3),
      onTap: onTap,
      isCompact: isCompact,
    );
  }

  factory UnifiedInfoChip.attribute({
    required String name,
    required int value,
    required int modifier,
    VoidCallback? onTap,
    bool isCompact = false,
  }) {
    final c = _attributeColor(value);
    final modText = modifier >= 0 ? '+$modifier' : '$modifier';
    return UnifiedInfoChip(
      label: name,
      value: '$value ($modText)',
      backgroundColor: c.withValues(alpha: 0.15),
      textColor: c,
      iconColor: c,
      borderColor: c.withValues(alpha: 0.3),
      fontSize: isCompact ? 10 : 12,
      onTap: onTap,
      isCompact: isCompact,
    );
  }

  factory UnifiedInfoChip.attributeCompact({
    required String name,
    required int value,
    VoidCallback? onTap,
  }) {
    final modifier = ((value - 10) / 2).floor();
    final c = _attributeColor(value);
    final modText = modifier >= 0 ? '+$modifier' : '$modifier';
    return UnifiedInfoChip(
      label: name,
      value: '$value $modText',
      backgroundColor: c.withValues(alpha: 0.1),
      textColor: c,
      borderColor: c.withValues(alpha: 0.2),
      fontSize: 10,
      iconSize: 12,
      onTap: onTap,
      isCompact: true,
      showBorder: true,
    );
  }

  factory UnifiedInfoChip.currency({
    required String label,
    required double amount,
    required IconData icon,
    Color? color,
    bool isCompact = false,
  }) {
    final c = color ?? const Color(0xFFF59E0B);
    return UnifiedInfoChip(
      label: label,
      value: amount.toStringAsFixed(0),
      icon: icon,
      backgroundColor: c.withValues(alpha: 0.15),
      textColor: c.withValues(alpha: 0.9),
      iconColor: c,
      borderColor: c.withValues(alpha: 0.3),
      fontSize: isCompact ? 10 : 11,
      iconSize: isCompact ? 12 : 14,
      isCompact: isCompact,
    );
  }

  factory UnifiedInfoChip.alignment({
    required String alignment,
    VoidCallback? onTap,
  }) {
    final c = _alignmentColor(alignment);
    return UnifiedInfoChip(
      label: '',
      value: alignment,
      icon: Icons.balance,
      backgroundColor: c.withValues(alpha: 0.15),
      textColor: c,
      iconColor: c,
      borderColor: c.withValues(alpha: 0.3),
      fontSize: 11,
      onTap: onTap,
    );
  }

  factory UnifiedInfoChip.status({
    required String status,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final s = status.toLowerCase();
    final c = s.contains('aktiv') || s.contains('active') || s.contains('laufend')
        ? const Color(0xFF2F6FEB)
        : s.contains('done') || s.contains('erledigt') || s.contains('abgeschlossen')
            ? const Color(0xFF1A7F4B)
            : s.contains('failed') || s.contains('fehl') || s.contains('abgebrochen')
                ? const Color(0xFFDC2626)
                : const Color(0xFFF97316);
    return UnifiedInfoChip(
      label: '',
      value: status,
      icon: icon ?? _statusIcon(status),
      backgroundColor: c.withValues(alpha: 0.15),
      textColor: c,
      iconColor: c,
      borderColor: c.withValues(alpha: 0.3),
      fontSize: 11,
      onTap: onTap,
    );
  }

  factory UnifiedInfoChip.tag({
    required String tag,
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final c = color ?? const Color(0xFF7C3AED);
    return UnifiedInfoChip(
      label: '',
      value: tag,
      icon: icon,
      backgroundColor: isSelected ? c.withValues(alpha: 0.3) : c.withValues(alpha: 0.1),
      textColor: c,
      iconColor: c,
      borderColor: c.withValues(alpha: isSelected ? 0.5 : 0.2),
      fontSize: 11,
      iconSize: 12,
      onTap: onTap,
      isCompact: true,
    );
  }

  factory UnifiedInfoChip.type({
    required String type,
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    final c = color ?? UnifiedCardTheme.getIconColor(type);
    return UnifiedInfoChip(
      label: '',
      value: type,
      icon: icon,
      backgroundColor: c.withValues(alpha: 0.15),
      textColor: c,
      iconColor: c,
      borderColor: c.withValues(alpha: 0.3),
      fontSize: 11,
      onTap: onTap,
    );
  }

  factory UnifiedInfoChip.level({
    required String label,
    required int level,
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    final c = color ?? const Color(0xFFF59E0B);
    return UnifiedInfoChip(
      label: label,
      value: '$level',
      icon: icon ?? Icons.star,
      backgroundColor: c.withValues(alpha: 0.15),
      textColor: c,
      iconColor: c,
      borderColor: c.withValues(alpha: 0.3),
      fontSize: 12,
      onTap: onTap,
    );
  }

  factory UnifiedInfoChip.count({
    required String label,
    required int count,
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    final c = color ?? const Color(0xFF2F6FEB);
    return UnifiedInfoChip(
      label: label,
      value: '$count',
      icon: icon ?? Icons.format_list_numbered,
      backgroundColor: c.withValues(alpha: 0.1),
      textColor: c,
      iconColor: c,
      borderColor: c.withValues(alpha: 0.2),
      fontSize: 11,
      iconSize: 14,
      onTap: onTap,
      isCompact: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 8,
          vertical: isCompact ? 4 : 6,
        );
    final effectiveFontSize = fontSize ?? (isCompact ? 11 : 12);
    final effectiveIconSize = iconSize ?? (isCompact ? 14 : 16);

    final chipContent = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? C.bgPanel,
        borderRadius: BorderRadius.circular(isCompact ? 6 : 6),
        border: showBorder
            ? Border.all(
                color: borderColor ??
                    (iconColor ?? textColor ?? C.border).withValues(alpha: 0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: effectiveIconSize, color: iconColor ?? textColor ?? C.textSoft),
            SizedBox(width: isCompact ? 3 : 4),
          ],
          if (label.isNotEmpty) ...[
            Text(
              '$label ',
              style: TextStyle(
                fontSize: effectiveFontSize,
                color: textColor?.withValues(alpha: 0.7) ?? C.textSoft,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: effectiveFontSize,
              color: textColor ?? C.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: chipContent,
        ),
      );
    }

    return chipContent;
  }
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

Color _attributeColor(int value) {
  if (value >= 18) {
    return const Color(0xFF059669);
  }
  if (value >= 14) {
    return const Color(0xFF1A7F4B);
  }
  if (value >= 12) {
    return const Color(0xFF2F6FEB);
  }
  if (value >= 10) {
    return const Color(0xFF0891B2);
  }
  if (value >= 8) {
    return const Color(0xFFF97316);
  }
  if (value >= 6) {
    return const Color(0xFF991B1B);
  }
  return const Color(0xFFDC2626);
}

Color _alignmentColor(String alignment) {
  final l = alignment.toLowerCase();
  if (l.contains('good')) {
    return const Color(0xFF1A7F4B);
  }
  if (l.contains('evil')) {
    return const Color(0xFFDC2626);
  }
  if (l.contains('lawful')) {
    return const Color(0xFF2F6FEB);
  }
  if (l.contains('chaotic')) {
    return const Color(0xFFF97316);
  }
  if (l.contains('neutral')) {
    return const Color(0xFF6B7280);
  }
  return const Color(0xFF7C3AED);
}

IconData _statusIcon(String status) {
  final l = status.toLowerCase();
  if (l.contains('aktiv') || l.contains('active')) {
    return Icons.check_circle;
  }
  if (l.contains('pending') || l.contains('wartet')) {
    return Icons.pending;
  }
  if (l.contains('komplett') || l.contains('complete')) {
    return Icons.done_all;
  }
  if (l.contains('archiv')) {
    return Icons.archive;
  }
  return Icons.info_outline;
}

// ── CHIP ROW / SECTION ────────────────────────────────────────────────────────

class UnifiedChipRow extends StatelessWidget {
  const UnifiedChipRow({
    required this.chips,
    super.key,
    this.spacing = 8,
    this.runSpacing = 8,
    this.alignment = WrapAlignment.start,
  });

  final List<Widget> chips;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context) => Wrap(
        spacing: spacing,
        runSpacing: runSpacing,
        alignment: alignment,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: chips,
      );
}

class UnifiedChipSection extends StatelessWidget {
  const UnifiedChipSection({
    required this.chips,
    super.key,
    this.title,
    this.titleIcon,
    this.titleColor,
  });

  final String? title;
  final List<Widget> chips;
  final IconData? titleIcon;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final tc = titleColor ?? C.amber;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(titleIcon, size: 14, color: tc.withValues(alpha: 0.8)),
                const SizedBox(width: 6),
              ],
              Text(
                title!,
                style: TextStyle(
                  color: tc.withValues(alpha: 0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        UnifiedChipRow(chips: chips),
      ],
    );
  }
}

// ── STATS ROW ─────────────────────────────────────────────────────────────────

class UnifiedStatsRow extends StatelessWidget {
  const UnifiedStatsRow({required this.stats, super.key, this.spacing = 8});

  final List<UnifiedStatItem> stats;
  final double spacing;

  @override
  Widget build(BuildContext context) => Row(
        children: stats.asMap().entries.map((entry) {
          final i = entry.key;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < stats.length - 1 ? spacing : 0),
              child: _StatCard(stat: entry.value),
            ),
          );
        }).toList(),
      );
}

class UnifiedStatItem {
  const UnifiedStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  factory UnifiedStatItem.hp(int current, int max, {VoidCallback? onTap}) =>
      UnifiedStatItem(label: 'HP', value: '$current/$max', icon: Icons.favorite, color: Colors.red, onTap: onTap);

  factory UnifiedStatItem.ac(int value, {VoidCallback? onTap}) =>
      UnifiedStatItem(label: 'AC', value: '$value', icon: Icons.shield, color: Colors.blue, onTap: onTap);

  factory UnifiedStatItem.initiative(int bonus, {VoidCallback? onTap}) => UnifiedStatItem(
        label: 'INIT',
        value: bonus >= 0 ? '+$bonus' : '$bonus',
        icon: Icons.flash_on,
        color: Colors.orange,
        onTap: onTap,
      );

  factory UnifiedStatItem.speed(int value, {VoidCallback? onTap}) =>
      UnifiedStatItem(label: 'Bew.', value: '$value ft', icon: Icons.speed, color: Colors.green, onTap: onTap);

  factory UnifiedStatItem.cr(String cr, {VoidCallback? onTap}) => UnifiedStatItem(
        label: 'CR',
        value: cr,
        icon: Icons.warning_amber,
        color: const Color(0xFFF59E0B),
        onTap: onTap,
      );

  factory UnifiedStatItem.level(int level, {VoidCallback? onTap}) => UnifiedStatItem(
        label: 'Lvl',
        value: '$level',
        icon: Icons.star,
        color: const Color(0xFFF59E0B),
        onTap: onTap,
      );
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});
  final UnifiedStatItem stat;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: stat.color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(stat.icon, size: 12, color: stat.color),
              const SizedBox(width: 4),
              Text(stat.label, style: TextStyle(fontSize: 10, color: stat.color, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(stat.value, style: TextStyle(fontSize: 14, color: stat.color, fontWeight: FontWeight.bold)),
        ],
      ),
    );

    if (stat.onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(onTap: stat.onTap, borderRadius: BorderRadius.circular(8), child: content),
      );
    }

    return content;
  }
}
