import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Wiederverwendbare Karte mit Titel und Icon für Sektionen
/// 
/// Beispiele:
/// ```dart
/// SectionCardWidget(
///   title: 'Grundinformationen',
///   icon: Icons.info_outline,
///   child: Column(
///     children: [
///       TextFormField(...),
///     ],
///   ),
/// )
/// ```
class SectionCardWidget extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? elevation;
  final VoidCallback? onTap;

  const SectionCardWidget({
    Key? key,
    required this.title,
    required this.icon,
    required this.child,
    this.padding = const EdgeInsets.all(16.0),
    this.iconColor,
    this.backgroundColor,
    this.elevation = 2.0,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation,
      color: backgroundColor ?? DnDTheme.slateGrey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        child: Padding(
          padding: padding!,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Titel mit Icon
              Row(
                children: [
                  Icon(
                    icon,
                    color: iconColor ?? DnDTheme.ancientGold,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: DnDTheme.headline2.copyWith(
                      color: DnDTheme.ancientGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  if (onTap != null) ...[
                    const Spacer(),
                    Icon(
                      Icons.expand_more,
                      color: Colors.grey.shade400,
                      size: 20,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              // Inhalt
              child,
            ],
          ),
        ),
      ),
    );
  }
}
