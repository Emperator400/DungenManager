import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';
import '../shared/unified_card_theme.dart';

/// Ein einheitlicher Info-Chip für das gesamte Projekt
/// 
/// Konsolidiert die Funktionalität von PcInfoChip und anderen Chip-Implementierungen
/// Unterstützt verschiedene Chip-Typen durch Factory-Konstruktoren
class UnifiedInfoChip extends StatelessWidget {
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

  const UnifiedInfoChip({
    super.key,
    required this.label,
    required this.value,
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

  // ============================================
  // Factory-Konstruktoren für verschiedene Typen
  // ============================================

  /// Factory für Kampf-Stats (AC, HP, INIT, SPEED)
  factory UnifiedInfoChip.combat({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
    bool isCompact = false,
  }) {
    final chipColor = color ?? Colors.blueGrey;
    return UnifiedInfoChip(
      label: label,
      value: value,
      icon: icon,
      backgroundColor: chipColor.withOpacity(0.15),
      textColor: chipColor,
      iconColor: chipColor,
      borderColor: chipColor.withOpacity(0.3),
      onTap: onTap,
      isCompact: isCompact,
    );
  }

  /// Factory für Attribut-Chips (STR, DEX, etc.)
  factory UnifiedInfoChip.attribute({
    required String name,
    required int value,
    required int modifier,
    VoidCallback? onTap,
    bool isCompact = false,
  }) {
    final qualityColor = _getAttributeColor(value);
    final modText = modifier >= 0 ? '+$modifier' : '$modifier';
    
    return UnifiedInfoChip(
      label: name,
      value: '$value ($modText)',
      backgroundColor: qualityColor.withOpacity(0.15),
      textColor: qualityColor,
      iconColor: qualityColor,
      borderColor: qualityColor.withOpacity(0.3),
      fontSize: isCompact ? 10 : 12,
      onTap: onTap,
      isCompact: isCompact,
    );
  }

  /// Factory für Attribut-Chip mit nur dem Wert (kompakt)
  factory UnifiedInfoChip.attributeCompact({
    required String name,
    required int value,
    VoidCallback? onTap,
  }) {
    final modifier = ((value - 10) / 2).floor();
    final qualityColor = _getAttributeColor(value);
    final modText = modifier >= 0 ? '+$modifier' : '$modifier';
    
    return UnifiedInfoChip(
      label: name,
      value: '$value $modText',
      backgroundColor: qualityColor.withOpacity(0.1),
      textColor: qualityColor,
      borderColor: qualityColor.withOpacity(0.2),
      fontSize: 10,
      iconSize: 12,
      onTap: onTap,
      isCompact: true,
      showBorder: true,
    );
  }

  /// Factory für Währungs-Chips
  factory UnifiedInfoChip.currency({
    required String label,
    required double amount,
    required IconData icon,
    Color? color,
    bool isCompact = false,
  }) {
    final chipColor = color ?? DnDTheme.ancientGold;
    return UnifiedInfoChip(
      label: label,
      value: amount.toStringAsFixed(0),
      icon: icon,
      backgroundColor: chipColor.withOpacity(0.15),
      textColor: chipColor.withOpacity(0.9),
      iconColor: chipColor,
      borderColor: chipColor.withOpacity(0.3),
      fontSize: isCompact ? 10 : 11,
      iconSize: isCompact ? 12 : 14,
      isCompact: isCompact,
    );
  }

  /// Factory für Gesinnungs-Chip
  factory UnifiedInfoChip.alignment({
    required String alignment,
    VoidCallback? onTap,
  }) {
    final color = _getAlignmentColor(alignment);
    return UnifiedInfoChip(
      label: '',
      value: alignment,
      icon: Icons.balance,
      backgroundColor: color.withOpacity(0.15),
      textColor: color,
      iconColor: color,
      borderColor: color.withOpacity(0.3),
      fontSize: 11,
      onTap: onTap,
    );
  }

  /// Factory für Status-Chip
  factory UnifiedInfoChip.status({
    required String status,
    IconData? icon,
    VoidCallback? onTap,
  }) {
    final color = UnifiedCardTheme.getStatusColor(status);
    return UnifiedInfoChip(
      label: '',
      value: status,
      icon: icon ?? _getStatusIcon(status),
      backgroundColor: color.withOpacity(0.15),
      textColor: color,
      iconColor: color,
      borderColor: color.withOpacity(0.3),
      fontSize: 11,
      onTap: onTap,
    );
  }

  /// Factory für Tag-Chip
  factory UnifiedInfoChip.tag({
    required String tag,
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
    bool isSelected = false,
  }) {
    final chipColor = color ?? Colors.purple;
    return UnifiedInfoChip(
      label: '',
      value: tag,
      icon: icon,
      backgroundColor: isSelected ? chipColor.withOpacity(0.3) : chipColor.withOpacity(0.1),
      textColor: chipColor,
      iconColor: chipColor,
      borderColor: chipColor.withOpacity(isSelected ? 0.5 : 0.2),
      fontSize: 11,
      iconSize: 12,
      onTap: onTap,
      isCompact: true,
    );
  }

  /// Factory für Typ-spezifische Chips (Kreatur-Typ, Wiki-Typ, etc.)
  factory UnifiedInfoChip.type({
    required String type,
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    final chipColor = color ?? UnifiedCardTheme.getIconColor(type);
    return UnifiedInfoChip(
      label: '',
      value: type,
      icon: icon,
      backgroundColor: chipColor.withOpacity(0.15),
      textColor: chipColor,
      iconColor: chipColor,
      borderColor: chipColor.withOpacity(0.3),
      fontSize: 11,
      onTap: onTap,
    );
  }

  /// Factory für Level/CR-Chip
  factory UnifiedInfoChip.level({
    required String label,
    required int level,
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    final chipColor = color ?? DnDTheme.ancientGold;
    return UnifiedInfoChip(
      label: label,
      value: '$level',
      icon: icon ?? Icons.star,
      backgroundColor: chipColor.withOpacity(0.15),
      textColor: chipColor,
      iconColor: chipColor,
      borderColor: chipColor.withOpacity(0.3),
      fontSize: 12,
      onTap: onTap,
    );
  }

  /// Factory für Zahlen-Chip (Count, Menge, etc.)
  factory UnifiedInfoChip.count({
    required String label,
    required int count,
    IconData? icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    final chipColor = color ?? Colors.blueGrey;
    return UnifiedInfoChip(
      label: label,
      value: '$count',
      icon: icon ?? Icons.format_list_numbered,
      backgroundColor: chipColor.withOpacity(0.1),
      textColor: chipColor,
      iconColor: chipColor,
      borderColor: chipColor.withOpacity(0.2),
      fontSize: 11,
      iconSize: 14,
      onTap: onTap,
      isCompact: true,
    );
  }

  // ============================================
  // Hilfsmethoden für Farben
  // ============================================

  static Color _getAttributeColor(int value) {
    if (value >= 18) return Colors.greenAccent;
    if (value >= 16) return Colors.green;
    if (value >= 14) return Colors.lightGreen;
    if (value >= 12) return Colors.blue;
    if (value >= 10) return Colors.lightBlue;
    if (value >= 8) return Colors.orange;
    if (value >= 6) return Colors.deepOrange;
    return Colors.red;
  }

  static Color _getAlignmentColor(String alignment) {
    final lower = alignment.toLowerCase();
    if (lower.contains('good')) return Colors.green;
    if (lower.contains('evil')) return Colors.red;
    if (lower.contains('lawful')) return Colors.blue;
    if (lower.contains('chaotic')) return Colors.orange;
    if (lower.contains('neutral')) return Colors.grey;
    return DnDTheme.mysticalPurple;
  }

  static IconData _getStatusIcon(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('aktiv') || lower.contains('active')) return Icons.check_circle;
    if (lower.contains('pending') || lower.contains('wartet')) return Icons.pending;
    if (lower.contains('komplett') || lower.contains('complete')) return Icons.done_all;
    if (lower.contains('archiv')) return Icons.archive;
    return Icons.info_outline;
  }

  // ============================================
  // Build-Methode
  // ============================================

  @override
  Widget build(BuildContext context) {
    final effectivePadding = padding ?? EdgeInsets.symmetric(
      horizontal: isCompact ? 6 : 8,
      vertical: isCompact ? 4 : 6,
    );
    
    final effectiveFontSize = fontSize ?? (isCompact ? 11 : 12);
    final effectiveIconSize = iconSize ?? (isCompact ? 14 : 16);
    
    final chipContent = Container(
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: backgroundColor ?? DnDTheme.slateGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(isCompact ? 6 : DnDTheme.radiusSmall),
        border: showBorder
            ? Border.all(
                color: borderColor ?? (iconColor ?? textColor ?? Colors.white).withOpacity(0.3),
                width: 1,
              )
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: effectiveIconSize,
              color: iconColor ?? textColor ?? Colors.white70,
            ),
            SizedBox(width: isCompact ? 3 : 4),
          ],
          if (label.isNotEmpty) ...[
            Text(
              '$label ',
              style: TextStyle(
                fontSize: effectiveFontSize,
                color: textColor?.withOpacity(0.7) ?? Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: effectiveFontSize,
              color: textColor ?? Colors.white,
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
          borderRadius: BorderRadius.circular(isCompact ? 6 : DnDTheme.radiusSmall),
          child: chipContent,
        ),
      );
    }
    
    return chipContent;
  }
}

// ============================================
// Hilf-Widgets für Chip-Gruppierungen
// ============================================

/// Eine Zeile von Chips mit automatischem Wrapping
class UnifiedChipRow extends StatelessWidget {
  final List<Widget> chips;
  final double spacing;
  final double runSpacing;
  final WrapAlignment alignment;

  const UnifiedChipRow({
    super.key,
    required this.chips,
    this.spacing = 8,
    this.runSpacing = 8,
    this.alignment = WrapAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      alignment: alignment,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: chips,
    );
  }
}

/// Sektion mit Titel und Chips
class UnifiedChipSection extends StatelessWidget {
  final String? title;
  final List<Widget> chips;
  final IconData? titleIcon;
  final Color? titleColor;

  const UnifiedChipSection({
    super.key,
    this.title,
    required this.chips,
    this.titleIcon,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTitleColor = titleColor ?? DnDTheme.ancientGold;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          Row(
            children: [
              if (titleIcon != null) ...[
                Icon(
                  titleIcon,
                  size: 14,
                  color: effectiveTitleColor.withOpacity(0.8),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                title!,
                style: TextStyle(
                  color: effectiveTitleColor.withOpacity(0.8),
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

/// Eine kompakte Statistik-Zeile (z.B. HP, AC, INIT, SPEED)
class UnifiedStatsRow extends StatelessWidget {
  final List<UnifiedStatItem> stats;
  final double spacing;

  const UnifiedStatsRow({
    super.key,
    required this.stats,
    this.spacing = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < stats.length - 1 ? spacing : 0),
            child: _StatCard(stat: stat),
          ),
        );
      }).toList(),
    );
  }
}

/// Datenklasse für einen Statistik-Eintrag
class UnifiedStatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const UnifiedStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  /// Factory für HP-Stat
  factory UnifiedStatItem.hp(int current, int max, {VoidCallback? onTap}) {
    return UnifiedStatItem(
      label: 'HP',
      value: '$current/$max',
      icon: Icons.favorite,
      color: Colors.red,
      onTap: onTap,
    );
  }

  /// Factory für AC-Stat
  factory UnifiedStatItem.ac(int value, {VoidCallback? onTap}) {
    return UnifiedStatItem(
      label: 'AC',
      value: '$value',
      icon: Icons.shield,
      color: Colors.blue,
      onTap: onTap,
    );
  }

  /// Factory für Initiative-Stat
  factory UnifiedStatItem.initiative(int bonus, {VoidCallback? onTap}) {
    final text = bonus >= 0 ? '+$bonus' : '$bonus';
    return UnifiedStatItem(
      label: 'INIT',
      value: text,
      icon: Icons.flash_on,
      color: Colors.orange,
      onTap: onTap,
    );
  }

  /// Factory für Speed-Stat
  factory UnifiedStatItem.speed(int value, {VoidCallback? onTap}) {
    return UnifiedStatItem(
      label: 'Bew.',
      value: '$value ft',
      icon: Icons.speed,
      color: Colors.green,
      onTap: onTap,
    );
  }

  /// Factory für CR (Challenge Rating)
  factory UnifiedStatItem.cr(String cr, {VoidCallback? onTap}) {
    return UnifiedStatItem(
      label: 'CR',
      value: cr,
      icon: Icons.warning_amber,
      color: Colors.amber,
      onTap: onTap,
    );
  }

  /// Factory für Level
  factory UnifiedStatItem.level(int level, {VoidCallback? onTap}) {
    return UnifiedStatItem(
      label: 'Lvl',
      value: '$level',
      icon: Icons.star,
      color: DnDTheme.ancientGold,
      onTap: onTap,
    );
  }
}

/// Interne Stat-Card Komponente
class _StatCard extends StatelessWidget {
  final UnifiedStatItem stat;

  const _StatCard({required this.stat});

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: stat.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: stat.color.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(stat.icon, size: 12, color: stat.color),
              const SizedBox(width: 4),
              Text(
                stat.label,
                style: TextStyle(
                  fontSize: 10,
                  color: stat.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 14,
              color: stat.color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );

    if (stat.onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: stat.onTap,
          borderRadius: BorderRadius.circular(8),
          child: content,
        ),
      );
    }

    return content;
  }
}