import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/bestiary_viewmodel.dart';

/// Zeigt den Import-Dialog für das Bestiarum an
void showBestiaryImportDialog({
  required BuildContext context,
  required BestiaryViewModel viewModel,
  required VoidCallback onImport,
}) {
  final C = context.appColors;
  showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: C.bg,
      title: Text(
        'Monster importieren',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.amber),
      ),
      content: Text(
        "Möchtest du Monster von 5e.tools herunterladen und importieren?\n\n"
        "Dabei werden alle verfügbaren Monster-Daten geladen.",
        style: TextStyle(fontSize: 14, color: C.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            'Abbrechen',
            style: TextStyle(fontSize: 14, color: C.accent),
          ),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            onImport();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: C.accent,
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
  final C = context.appColors;
  showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: C.bg,
      title: Text(
        'Bestiarum zurücksetzen?',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.red),
      ),
      content: Text(
        "Bist du sicher, dass du alle Kreaturen im Bestiarum löschen möchtest? "
        "Diese Aktion kann nicht rückgängig gemacht werden.",
        style: TextStyle(fontSize: 14, color: C.text),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(
            'Abbrechen',
            style: TextStyle(fontSize: 14, color: C.accent),
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
                    backgroundColor: C.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler: $e'),
                    backgroundColor: C.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: C.red,
            foregroundColor: Colors.white,
          ),
          child: const Text('Zurücksetzen'),
        ),
      ],
    ),
  );
}
