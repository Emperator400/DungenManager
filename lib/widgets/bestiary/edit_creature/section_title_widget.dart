import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

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
    return Row(
      children: [
        Icon(
          icon,
          color: DnDTheme.ancientGold,
          size: 22,
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ],
    );
  }
}