import 'package:flutter/material.dart';
import '../../models/creature.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/bestiary_viewmodel.dart';
import '../../screens/bestiary/edit_creature_screen.dart';

/// Kreatur-Karte für die Bestiarum-Liste
class BestiaryCreatureCard extends StatelessWidget {
  final Creature creature;
  final BestiaryViewModel viewModel;
  final VoidCallback onDataChanged;

  const BestiaryCreatureCard({
    super.key,
    required this.creature,
    required this.viewModel,
    required this.onDataChanged,
  });

  /// Gibt die Farbe basierend auf dem Quelltyp zurück
  Color _getSourceColor(String sourceType, AppColorsExtension C) {
    switch (sourceType) {
      case 'official':
        return C.accent;
      case 'custom':
        return C.green;
      case 'hybrid':
        return C.accent;
      default:
        return C.bgActive;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    final C = context.appColors;
    // ScaffoldMessenger vor dem Dialog speichern
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          'Kreatur löschen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.red),
        ),
        content: Text(
          "Möchtest du '${creature.name}' wirklich löschen? "
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
                await viewModel.deleteCreature(creature.id.toString());
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('${creature.name} wurde gelöscht'),
                      backgroundColor: C.green,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Löschen: $e'),
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
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final isOfficial = creature.sourceType == 'official';
    final isCustom = creature.sourceType == 'custom';
    final sourceColor = _getSourceColor(creature.sourceType, C);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: sourceColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          decoration: BoxDecoration(
            color: sourceColor,
            shape: BoxShape.circle,
            border: Border.all(
              color: C.amber,
              width: 2,
            ),
          ),
          child: Icon(
            isOfficial ? Icons.public : (isCustom ? Icons.person : Icons.sync),
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          creature.name,
          style: TextStyle(
            fontSize: 14,
            color: C.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "HP: ${creature.currentHp}/${creature.maxHp} | RK: ${creature.armorClass}",
              style: TextStyle(fontSize: 12, color: C.amber),
            ),
            if (creature.type != null)
              Text(
                "Typ: ${creature.type}${creature.subtype != null ? ' (${creature.subtype})' : ''}",
                style: TextStyle(fontSize: 12, color: C.textMid),
              ),
            if (creature.challengeRating != null)
              Text(
                "SG: ${creature.challengeRating} | Größe: ${creature.size ?? 'Medium'}",
                style: TextStyle(fontSize: 12, color: C.textMid),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Favoriten-Stern
            Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: creature.isFavorite ? C.amber : C.bgActive,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(
                  creature.isFavorite ? Icons.star : Icons.star_border,
                  color: creature.isFavorite ? C.amber : C.bgActive,
                ),
                onPressed: () async {
                  try {
                    await viewModel.toggleFavorite(creature);
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
                tooltip: 'Favorit',
              ),
            ),
            const SizedBox(width: 4),
            // Bearbeiten-Button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: C.accent),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.edit, color: C.accent),
                onPressed: () async {
                  final result = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (ctx) => EditCreatureScreen(
                        creature: creature,
                      ),
                    ),
                  );
                  if (result == true) {
                    onDataChanged();
                  }
                },
                tooltip: 'Bearbeiten',
              ),
            ),
            const SizedBox(width: 4),
            // Löschen-Button
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: C.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.delete, color: C.red),
                onPressed: () => _showDeleteConfirmation(context),
                tooltip: 'Löschen',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
