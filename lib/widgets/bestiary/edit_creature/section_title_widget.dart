import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

/// Widget für Sektionstitel in der Kreatur-Bearbeitung
class SectionTitleWidget extends StatelessWidget {
  final String title;
  final IconData icon;

  const SectionTitleWidget({
    super.key,
    required this.title,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Row(
      children: [
        Icon(
          icon,
          color: C.amber,
          size: 22,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: C.amber,
          ),
        ),
      ],
    );
  }
}
