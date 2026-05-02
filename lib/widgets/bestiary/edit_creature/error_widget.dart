import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

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
    final C = context.appColors;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: C.red,
              size: 64,
            ),
            const SizedBox(height: 24),
            Text(
              'Fehler',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: C.red),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 14, color: C.text),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: C.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
