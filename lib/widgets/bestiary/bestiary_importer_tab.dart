import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/bestiary_viewmodel.dart';

/// Importer-Tab für das Bestiarum (5e.tools Import)
class BestiaryImporterTab extends StatelessWidget {
  final BestiaryViewModel viewModel;
  final VoidCallback onDataChanged;

  const BestiaryImporterTab({
    super.key,
    required this.viewModel,
    required this.onDataChanged,
  });

  Future<void> _importFrom5eTools(BuildContext context) async {
    try {
      final count = await viewModel.importMonstersFrom5eTools();
      await viewModel.loadDndData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count Monster von 5e.tools importiert'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Import: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _importAllAvailable(BuildContext context) async {
    try {
      await viewModel.importAllMonsters();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alle verfügbaren Monster importiert'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Import: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _addSingleMonster(BuildContext context, Map<String, dynamic> monsterData) async {
    try {
      await viewModel.addMonsterToBestiary(monsterData);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${monsterData['name']} wurde hinzugefügt'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Hinzufügen: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BestiaryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingDndData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: DnDTheme.ancientGold,
                ),
                const SizedBox(height: DnDTheme.md),
                Text(
                  'Lade Monster-Daten...',
                  style: DnDTheme.bodyText1.copyWith(
                    color: DnDTheme.ancientGold,
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Import-Buttons
            Padding(
              padding: const EdgeInsets.all(DnDTheme.md),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: DnDTheme.getMysticalBorder(
                        borderColor: DnDTheme.arcaneBlue,
                        width: 2,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _importFrom5eTools(context),
                        icon: const Icon(Icons.download),
                        label: const Text("Von 5e.tools"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DnDTheme.arcaneBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: DnDTheme.sm),
                  Expanded(
                    child: Container(
                      decoration: DnDTheme.getMysticalBorder(
                        borderColor: DnDTheme.successGreen,
                        width: 2,
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _importAllAvailable(context),
                        icon: const Icon(Icons.library_add),
                        label: const Text("Alle importieren"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DnDTheme.successGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Verfügbarer Monster-Liste
            Expanded(
              child: viewModel.availableMonsters.isEmpty
                  ? Center(
                      child: Container(
                        padding: const EdgeInsets.all(DnDTheme.lg),
                        decoration: DnDTheme.getDungeonWallDecoration(),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.download_outlined,
                              size: 64,
                              color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: DnDTheme.md),
                            Text(
                              "Keine Monster-Daten verfügbar.\nImportiere zuerst von 5e.tools.",
                              style: DnDTheme.bodyText1.copyWith(
                                color: Colors.white70,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(DnDTheme.sm),
                      itemCount: viewModel.availableMonsters.length,
                      itemBuilder: (context, index) {
                        final monster = viewModel.availableMonsters[index];
                        final monsterId = monster['id']?.toString();
                        final isAlreadyImported = this.viewModel.allCreatures.any((creature) => 
                          creature.officialMonsterId == monsterId
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: DnDTheme.sm),
                          decoration: BoxDecoration(
                            gradient: DnDTheme.getMysticalGradient(
                              startColor: DnDTheme.slateGrey,
                              endColor: DnDTheme.stoneGrey,
                            ),
                            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                            border: Border.all(
                              color: isAlreadyImported 
                                  ? Colors.grey.withValues(alpha: 0.5)
                                  : DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.pets,
                              color: isAlreadyImported ? Colors.grey : DnDTheme.mysticalPurple,
                            ),
                            title: Text(
                              monster['name']?.toString() ?? 'Unbekannt',
                              style: DnDTheme.bodyText1.copyWith(
                                color: isAlreadyImported ? Colors.grey : Colors.white,
                                fontStyle: isAlreadyImported ? FontStyle.italic : null,
                              ),
                            ),
                            subtitle: Text(
                              '${monster['type']?.toString() ?? 'Unbekannt'} • '
                              'SG ${monster['challenge_rating']?.toString() ?? '0'} • '
                              'TP ${monster['hit_points']?.toString() ?? '0'}',
                              style: DnDTheme.bodyText2.copyWith(
                                color: isAlreadyImported ? Colors.grey.shade600 : Colors.white70,
                              ),
                            ),
                            trailing: isAlreadyImported
                                ? const Icon(Icons.check_circle, color: DnDTheme.successGreen)
                                : Container(
                                    decoration: DnDTheme.getMysticalBorder(
                                      borderColor: DnDTheme.successGreen,
                                      width: 2,
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.add_circle, color: DnDTheme.successGreen),
                                      onPressed: () => _addSingleMonster(context, monster),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}