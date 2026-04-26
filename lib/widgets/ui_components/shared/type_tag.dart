// lib/widgets/ui_components/shared/type_tag.dart
//
// TypeTag nach UI_vorschrift:
// Farbiger Punkt + Label + farbiger Hintergrund (light/dark-aware).

import 'package:flutter/material.dart';
import '../../../theme/app_colors_map.dart';

class TypeTag extends StatelessWidget {
  const TypeTag(this.type, {super.key, this.small = false});

  final String type;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cfg = AppTypeColors.of(type);

    final fs = small ? 10.0 : 11.0;
    final px = small ? 6.0  : 8.0;
    final py = small ? 1.0  : 2.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: px, vertical: py),
      decoration: BoxDecoration(
        color: isDark ? cfg.bgDark : cfg.bgLight,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: cfg.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            type,
            style: TextStyle(
              fontSize: fs,
              fontWeight: FontWeight.w500,
              color: cfg.color,
            ),
          ),
        ],
      ),
    );
  }
}
