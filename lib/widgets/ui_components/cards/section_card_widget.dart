import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class SectionCardWidget extends StatelessWidget {
  const SectionCardWidget({
    required this.title,
    required this.icon,
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(16.0),
    this.iconColor,
    this.backgroundColor,
    this.elevation = 0,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? elevation;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final ic = iconColor ?? C.amber;

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor ?? C.bgPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: padding!,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, color: ic, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: C.text,
                      ),
                    ),
                    if (onTap != null) ...[
                      const Spacer(),
                      Icon(Icons.expand_more, color: C.textSoft, size: 20),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
