import 'package:flutter/material.dart';
import '../../models/creature.dart';
import '../../theme/dnd_theme.dart';
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
  Color _getSourceColor(String sourceType) {
    switch (sourceType) {
      case 'official':
        return DnDTheme.arcaneBlue;
      case 'custom':
        return DnDTheme.successGreen;
      case 'hybrid':
        return DnDTheme.mysticalPurple;
      default:
        return DnDTheme.slateGrey;
    }
  }

  void _showDeleteConfirmation(BuildContext context) {
    // ScaffoldMessenger vor dem Dialog speichern
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Kreatur löschen',
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.errorRed,
          ),
        ),
        content: Text(
          "Möchtest du '${creature.name}' wirklich löschen? "
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
                await viewModel.deleteCreature(creature.id.toString());
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('${creature.name} wurde gelöscht'),
                      backgroundColor: DnDTheme.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  scaffoldMessenger.showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Löschen: $e'),
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
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOfficial = creature.sourceType == 'official';
    final isCustom = creature.sourceType == 'custom';
    
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.sm),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: _getSourceColor(creature.sourceType).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DnDTheme.md),
        leading: Container(
          decoration: BoxDecoration(
            color: _getSourceColor(creature.sourceType),
            shape: BoxShape.circle,
            border: Border.all(
              color: DnDTheme.ancientGold,
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
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "HP: ${creature.currentHp}/${creature.maxHp} | RK: ${creature.armorClass}",
              style: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.ancientGold,
              ),
            ),
            if (creature.type != null)
              Text(
                "Typ: ${creature.type}${creature.subtype != null ? ' (${creature.subtype})' : ''}",
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white70,
                ),
              ),
            if (creature.challengeRating != null)
              Text(
                "SG: ${creature.challengeRating} | Größe: ${creature.size ?? 'Medium'}",
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white70,
                ),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Favoriten-Stern
            Container(
              decoration: DnDTheme.getMysticalBorder(
                borderColor: creature.isFavorite ? DnDTheme.ancientGold : DnDTheme.slateGrey,
                width: 2,
              ),
              child: IconButton(
                icon: Icon(
                  creature.isFavorite ? Icons.star : Icons.star_border,
                  color: creature.isFavorite ? DnDTheme.ancientGold : DnDTheme.slateGrey,
                ),
                onPressed: () async {
                  try {
                    await viewModel.toggleFavorite(creature);
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
                tooltip: 'Favorit',
              ),
            ),
            const SizedBox(width: DnDTheme.xs),
            // Bearbeiten-Button
            Container(
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.arcaneBlue,
                width: 2,
              ),
              child: IconButton(
                icon: Icon(Icons.edit, color: DnDTheme.arcaneBlue),
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
            const SizedBox(width: DnDTheme.xs),
            // Löschen-Button
            Container(
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.errorRed,
                width: 2,
              ),
              child: IconButton(
                icon: Icon(Icons.delete, color: DnDTheme.errorRed),
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