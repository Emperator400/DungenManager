import 'package:flutter/material.dart';

/// Abstrakte Basisklasse für alle Card-Widgets
/// 
/// Stellt gemeinsame Layout-Logik und Standard-Styling bereit
abstract class UnifiedCardBase extends StatelessWidget {
  /// Konfiguration für die Card
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final bool isFavorite;
  final bool isSelected;
  final bool showActions;
  final double? elevation;
  final EdgeInsets? margin;
  final double borderRadius;

  const UnifiedCardBase({
    super.key,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
    this.isFavorite = false,
    this.isSelected = false,
    this.showActions = true,
    this.elevation,
    this.margin,
    this.borderRadius = 12.0,
  });

  /// Baut den Card-Inhalt - muss von Unterklassen implementiert werden
  Widget buildCardContent(BuildContext context);

  /// Baut optionale benutzerdefinierte trailing Widgets
  Widget? buildCustomTrailing(BuildContext context) => null;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: elevation ?? (isSelected ? 8 : 2),
      margin: margin ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: isSelected
            ? BorderSide(
                color: getAccentColor(context),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(borderRadius),
        child: buildCardContent(context),
      ),
    );
  }

  /// Gibt die Akzentfarbe für diese Card zurück
  Color getAccentColor(BuildContext context) {
    return Theme.of(context).primaryColor;
  }

  /// Standard-Padding für Card-Inhalte
  static const double defaultPadding = 16.0;

  /// Standard-Spacing zwischen Elementen
  static const double defaultSpacing = 8.0;
}
