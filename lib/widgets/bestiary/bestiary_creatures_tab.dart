import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/creature.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/bestiary_viewmodel.dart';
import '../../screens/bestiary/edit_creature_screen.dart';
import '../ui_components/cards/unified_creature_card.dart';

/// Tab-Typen für die Kreaturen-Listen
enum BestiaryTabType {
  all,
  custom,
  official,
}

/// Kreaturen-Tab mit Liste für Alle/Eigene/Offizielle Kreaturen
class BestiaryCreaturesTab extends StatelessWidget {
  final BestiaryTabType tabType;
  final String title;
  final TextEditingController searchController;
  final VoidCallback onDataChanged;

  const BestiaryCreaturesTab({
    super.key,
    required this.tabType,
    required this.title,
    required this.searchController,
    required this.onDataChanged,
  });

  /// Holt die richtige Kreatur-Liste basierend auf dem Tab-Typ
  List<Creature> _getCreaturesForTab(BestiaryViewModel viewModel) {
    switch (tabType) {
      case BestiaryTabType.all:
        // Alle Kreaturen filtern und sortieren
        final filtered = viewModel.filterCreatures(viewModel.allCreatures);
        return viewModel.sortCreatures(filtered);
      case BestiaryTabType.custom:
        // Eigene Kreaturen
        return viewModel.customCreatures;
      case BestiaryTabType.official:
        // Offizielle Monster
        return viewModel.officialCreatures;
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Consumer<BestiaryViewModel>(
      builder: (context, viewModel, child) {
        // Liste wird INNERHALB des Consumers basierend auf dem tabType berechnet
        final creatures = _getCreaturesForTab(viewModel);

        if (viewModel.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: C.amber,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lade $title...',
                  style: TextStyle(fontSize: 14, color: C.amber),
                ),
              ],
            ),
          );
        }

        if (viewModel.error != null) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: C.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: C.red,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Fehler beim Laden',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.red),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    viewModel.error!,
                    style: TextStyle(fontSize: 12, color: C.textMid),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      viewModel.clearError();
                      onDataChanged();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (creatures.isEmpty) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: C.bg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: C.border),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: 64,
                    color: C.accent.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Keine Kreaturen gefunden.",
                    style: TextStyle(fontSize: 14, color: C.text),
                    textAlign: TextAlign.center,
                  ),
                  if (viewModel.searchQuery.isNotEmpty ||
                      viewModel.selectedSourceType != 'all' ||
                      viewModel.showFavoritesOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          viewModel.resetFilters();
                          searchController.clear();
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Filter zurücksetzen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: C.accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        return Container(
          color: C.bg,
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: creatures.length,
            itemBuilder: (context, index) {
              final creature = creatures[index];
              return UnifiedCreatureCard(
                creature: creature,
                onToggleFavorite: () async {
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
                onEdit: () async {
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
                onDelete: () async {
                  try {
                    await viewModel.deleteCreature(creature.id.toString());
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${creature.name} wurde gelöscht'),
                          backgroundColor: C.green,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Fehler beim Löschen: $e'),
                          backgroundColor: C.red,
                        ),
                      );
                    }
                  }
                },
                onTap: () async {
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
              );
            },
          ),
        );
      },
    );
  }
}
