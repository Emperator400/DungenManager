import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';

/// Ein moderner UI-Chip für die Anzeige von PC-Informationen
class PcInfoChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? iconColor;
  final double? fontSize;
  final double? iconSize;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  const PcInfoChip({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.iconColor,
    this.fontSize,
    this.iconSize,
    this.padding,
    this.onTap,
  });

  /// Factory für Kampf-Stats (AC, HP, INIT, SPEED)
  factory PcInfoChip.combat({
    required String label,
    required String value,
    required IconData icon,
    Color? color,
    VoidCallback? onTap,
  }) {
    return PcInfoChip(
      label: label,
      value: value,
      icon: icon,
      backgroundColor: color?.withOpacity(0.15) ?? DnDTheme.slateGrey.withOpacity(0.3),
      textColor: color ?? Colors.white,
      iconColor: color ?? DnDTheme.ancientGold,
      onTap: onTap,
    );
  }

  /// Factory für Attribut-Chips (STR, DEX, etc.)
  factory PcInfoChip.attribute({
    required String name,
    required int value,
    required int modifier,
    VoidCallback? onTap,
  }) {
    final qualityColor = _getAttributeColor(value);
    final modText = modifier >= 0 ? '+$modifier' : '$modifier';
    
    return PcInfoChip(
      label: name,
      value: '$value ($modText)',
      backgroundColor: qualityColor.withOpacity(0.15),
      textColor: qualityColor,
      iconColor: qualityColor,
      fontSize: 12,
      onTap: onTap,
    );
  }

  /// Factory für Währungs-Chips
  factory PcInfoChip.currency({
    required String label,
    required double amount,
    required IconData icon,
    Color? color,
  }) {
    return PcInfoChip(
      label: label,
      value: amount.toStringAsFixed(0),
      icon: icon,
      backgroundColor: color?.withOpacity(0.15) ?? DnDTheme.slateGrey.withOpacity(0.3),
      textColor: color ?? Colors.white70,
      iconColor: color ?? DnDTheme.ancientGold,
      fontSize: 11,
      iconSize: 14,
    );
  }

  /// Factory für Gesinnungs-Chip
  factory PcInfoChip.alignment({
    required String alignment,
  }) {
    final color = _getAlignmentColor(alignment);
    return PcInfoChip(
      label: 'Gesinnung',
      value: alignment,
      icon: Icons.balance,
      backgroundColor: color.withOpacity(0.15),
      textColor: color,
      iconColor: color,
      fontSize: 11,
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final chipContent = Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? DnDTheme.slateGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: (iconColor ?? textColor ?? Colors.white).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: iconSize ?? 16,
              color: iconColor ?? textColor ?? Colors.white70,
            ),
            const SizedBox(width: 4),
          ],
          if (label.isNotEmpty) ...[
            Text(
              '$label ',
              style: TextStyle(
                fontSize: fontSize ?? 12,
                color: textColor?.withOpacity(0.7) ?? Colors.white70,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
          Text(
            value,
            style: TextStyle(
              fontSize: fontSize ?? 12,
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
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          child: chipContent,
        ),
      );
    }
    
    return chipContent;
  }
}

/// Eine Zeile von Chips mit automatischem Wrapping
class PcChipRow extends StatelessWidget {
  final List<Widget> chips;
  final double spacing;
  final double runSpacing;
  final CrossAxisAlignment alignment;

  const PcChipRow({
    super.key,
    required this.chips,
    this.spacing = 8,
    this.runSpacing = 8,
    this.alignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: spacing,
      runSpacing: runSpacing,
      crossAxisAlignment: WrapCrossAlignment.start,
      children: chips,
    );
  }
}

/// Sektion mit Titel und Chips
class PcChipSection extends StatelessWidget {
  final String? title;
  final List<Widget> chips;
  final IconData? titleIcon;

  const PcChipSection({
    super.key,
    this.title,
    required this.chips,
    this.titleIcon,
  });

  @override
  Widget build(BuildContext context) {
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
                  color: DnDTheme.ancientGold.withOpacity(0.8),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                title!,
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold.withOpacity(0.8),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
        ],
        PcChipRow(chips: chips),
      ],
    );
  }
}