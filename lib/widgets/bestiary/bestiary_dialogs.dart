import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/bestiary_viewmodel.dart';

/// Zeigt den Import-Dialog für das Bestiarum an
void showBestiaryImportDialog({
  required BuildContext context,
  required BestiaryViewModel viewModel,
  required VoidCallback onImport,
}) {
  showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: DnDTheme.stoneGrey,
      title: Text(
        'Monster importieren',
        style: DnDTheme.headline3.copyWith(
          color: DnDTheme.ancientGold,
        ),
      ),
      content: Text(
        "Möchtest du Monster von 5e.tools herunterladen und importieren?\n\n"
        "Dabei werden alle verfügbaren Monster-Daten geladen.",
        style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            'Abbrechen',
            style: DnDTheme.bodyText1.copyWith(
              color: DnDTheme.mysticalPurple,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            onImport();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DnDTheme.arcaneBlue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Importieren'),
        ),
      ],
    ),
  );
}

/// Zeigt den Reset-Dialog für das Bestiarum an
void showBestiaryResetDialog({
  required BuildContext context,
  required BestiaryViewModel viewModel,
}) {
  showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: DnDTheme.stoneGrey,
      title: Text(
        'Bestiarum zurücksetzen?',
        style: DnDTheme.headline3.copyWith(
          color: DnDTheme.errorRed,
        ),
      ),
      content: Text(
        "Bist du sicher, dass du alle Kreaturen im Bestiarum löschen möchtest? "
        "Diese Aktion kann nicht rückgängig gemacht werden.",
        style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            'Abbrechen',
            style: DnDTheme.bodyText1.copyWith(
              color: DnDTheme.mysticalPurple,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(dialogContext);
            try {
              await viewModel.resetBestiary();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bestiarum wurde zurückgesetzt'),
                    backgroundColor: DnDTheme.successGreen,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler: $e'),
                    backgroundColor: DnDTheme.errorRed,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DnDTheme.errorRed,
            foregroundColor: Colors.white,
          ),
          child: const Text('Zurücksetzen'),
        ),
      ],
    ),
  );
}