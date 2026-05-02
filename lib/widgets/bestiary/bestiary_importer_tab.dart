import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
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
    final C = context.appColors;
    try {
      final count = await viewModel.importMonstersFrom5eTools();
      await viewModel.loadDndData();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count Monster von 5e.tools importiert'),
            backgroundColor: C.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Import: $e'),
            backgroundColor: C.red,
          ),
        );
      }
    }
  }

  Future<void> _importAllAvailable(BuildContext context) async {
    final C = context.appColors;
    try {
      await viewModel.importAllMonsters();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alle verfügbaren Monster importiert'),
            backgroundColor: C.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Import: $e'),
            backgroundColor: C.red,
          ),
        );
      }
    }
  }

  Future<void> _addSingleMonster(BuildContext context, Map<String, dynamic> monsterData) async {
    final C = context.appColors;
    try {
      await viewModel.addMonsterToBestiary(monsterData);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${monsterData['name']} wurde hinzugefügt'),
            backgroundColor: C.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Hinzufügen: $e'),
            backgroundColor: C.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Consumer<BestiaryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingDndData) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: C.amber,
                ),
                const SizedBox(height: 16),
                Text(
                  'Lade Monster-Daten...',
                  style: TextStyle(fontSize: 14, color: C.amber),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Import-Buttons
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: C.accent),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _importFrom5eTools(context),
                        icon: const Icon(Icons.download),
                        label: const Text("Von 5e.tools"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: C.accent,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: C.green),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: () => _importAllAvailable(context),
                        icon: const Icon(Icons.library_add),
                        label: const Text("Alle importieren"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: C.green,
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
                              Icons.download_outlined,
                              size: 64,
                              color: C.accent.withValues(alpha: 0.6),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "Keine Monster-Daten verfügbar.\nImportiere zuerst von 5e.tools.",
                              style: TextStyle(fontSize: 14, color: C.text),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: viewModel.availableMonsters.length,
                      itemBuilder: (context, index) {
                        final monster = viewModel.availableMonsters[index];
                        final monsterId = monster['id']?.toString();
                        final isAlreadyImported = this.viewModel.allCreatures.any((creature) =>
                          creature.officialMonsterId == monsterId
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: C.bgPanel,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isAlreadyImported
                                  ? C.border
                                  : C.accent.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: ListTile(
                            leading: Icon(
                              Icons.pets,
                              color: isAlreadyImported ? C.textMid : C.accent,
                            ),
                            title: Text(
                              monster['name']?.toString() ?? 'Unbekannt',
                              style: TextStyle(
                                fontSize: 14,
                                color: isAlreadyImported ? C.textMid : C.text,
                                fontStyle: isAlreadyImported ? FontStyle.italic : null,
                              ),
                            ),
                            subtitle: Text(
                              '${monster['type']?.toString() ?? 'Unbekannt'} • '
                              'SG ${monster['challenge_rating']?.toString() ?? '0'} • '
                              'TP ${monster['hit_points']?.toString() ?? '0'}',
                              style: TextStyle(
                                fontSize: 12,
                                color: isAlreadyImported ? C.textSoft : C.textMid,
                              ),
                            ),
                            trailing: isAlreadyImported
                                ? Icon(Icons.check_circle, color: C.green)
                                : Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: C.green),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: IconButton(
                                      icon: Icon(Icons.add_circle, color: C.green),
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
