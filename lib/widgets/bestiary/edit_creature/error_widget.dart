import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Widget zur Anzeige von Fehlern in der Kreatur-Bearbeitung
class CreatureErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const CreatureErrorWidget({
    super.key,
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(DnDTheme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: DnDTheme.errorRed,
              size: 64,
            ),
            const SizedBox(height: DnDTheme.lg),
            Text(
              'Fehler',
              style: DnDTheme.headline2.copyWith(
                color: DnDTheme.errorRed,
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              error,
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DnDTheme.xl),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.arcaneBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: DnDTheme.lg,
                  vertical: DnDTheme.md,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}