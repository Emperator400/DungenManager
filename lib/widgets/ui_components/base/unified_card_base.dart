import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Abstrakte Basisklasse für alle Card-Widgets.
/// Neue Optik: weißes/dunkles Panel, 1px Border, 8px Radius, kein Schatten.
abstract class UnifiedCardBase extends StatelessWidget {
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
    this.borderRadius = 8.0,
  });

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

  Widget buildCardContent(BuildContext context);

  Widget? buildCustomTrailing(BuildContext context) => null;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Container(
      margin: margin ?? EdgeInsets.zero,
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(
          color: isSelected ? C.accent : C.border,
          width: isSelected ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          hoverColor: C.bgHover,
          child: buildCardContent(context),
        ),
      ),
    );
  }

  Color getAccentColor(BuildContext context) =>
      context.appColors.accent;

  static const double defaultPadding = 14.0;
  static const double defaultSpacing = 8.0;
}
