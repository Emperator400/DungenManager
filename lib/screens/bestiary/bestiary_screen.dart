 import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/creature.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/bestiary_viewmodel.dart';
import 'edit_creature_screen.dart';

class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> 
    with TickerProviderStateMixin {
  late BestiaryViewModel _viewModel;
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = BestiaryViewModel();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await _viewModel.loadCreatures();
      await _viewModel.loadDndData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BestiaryViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: DnDTheme.dungeonBlack,
        appBar: AppBar(
          title: Text(
            "Bestiarum",
            style: DnDTheme.headline2.copyWith(
              color: DnDTheme.ancientGold,
            ),
          ),
          backgroundColor: DnDTheme.stoneGrey,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: _buildSearchAndFilterBar(),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: DnDTheme.sm),
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.arcaneBlue,
                width: 2,
              ),
              child: IconButton(
                icon: const Icon(Icons.download),
                tooltip: "Monster importieren",
                onPressed: _showImportDialog,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: DnDTheme.sm),
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.errorRed,
                width: 2,
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: "Bestiarum zurücksetzen",
                onPressed: _showResetDialog,
              ),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildCreaturesTab(_tabAll, "Alle Kreaturen"),
            _buildCreaturesTab(_tabCustom, "Eigene Kreaturen"),
            _buildCreaturesTab(_tabOfficial, "Offizielle Monster"),
            _buildImporterTab(),
          ],
        ),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Consumer<BestiaryViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(DnDTheme.md),
          decoration: BoxDecoration(
            gradient: DnDTheme.getMysticalGradient(
              startColor: DnDTheme.stoneGrey,
              endColor: DnDTheme.slateGrey,
            ),
            border: Border(
              bottom: BorderSide(
                color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Suchleiste
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Kreaturen suchen...',
                  hintStyle: DnDTheme.bodyText2.copyWith(
                    color: Colors.white54,
                  ),
                  prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
                  suffixIcon: viewModel.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: DnDTheme.errorRed),
                          onPressed: () {
                            viewModel.updateSearchQuery('');
                            _searchController.clear();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                    borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                    borderSide: BorderSide(
                      color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                    borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                  ),
                  filled: true,
                  fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                ),
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                onChanged: (value) {
                  viewModel.updateSearchQuery(value);
                },
              ),
              
              const SizedBox(height: DnDTheme.sm),
              
              // Filter-Chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip(
                      label: 'Alle',
                      isSelected: viewModel.selectedSourceType == 'all',
                      onSelected: (selected) => viewModel.updateSourceTypeFilter('all'),
                      color: DnDTheme.mysticalPurple,
                    ),
                    _buildFilterChip(
                      label: 'Eigene',
                      isSelected: viewModel.selectedSourceType == 'custom',
                      onSelected: (selected) => viewModel.updateSourceTypeFilter('custom'),
                      color: DnDTheme.successGreen,
                    ),
                    _buildFilterChip(
                      label: 'Offiziell',
                      isSelected: viewModel.selectedSourceType == 'official',
                      onSelected: (selected) => viewModel.updateSourceTypeFilter('official'),
                      color: DnDTheme.arcaneBlue,
                    ),
                    _buildFilterChip(
                      label: 'Favoriten',
                      isSelected: viewModel.showFavoritesOnly,
                      onSelected: (selected) => viewModel.updateFavoritesFilter(selected),
                      color: DnDTheme.ancientGold,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: DnDTheme.xs),
      child: FilterChip(
        label: Text(
          label,
          style: DnDTheme.bodyText2.copyWith(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.w600,
          ),
        ),
        selected: isSelected,
        onSelected: onSelected,
        backgroundColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
        selectedColor: color,
        checkmarkColor: Colors.white,
        side: BorderSide(
          color: isSelected ? color : color.withValues(alpha: 0.5),
          width: 1.5,
        ),
        elevation: isSelected ? 2 : 0,
        pressElevation: 4,
      ),
    );
  }

  /// Enum für die verschiedenen Kreatur-Listen-Typen
  static const int _tabAll = 0;
  static const int _tabCustom = 1;
  static const int _tabOfficial = 2;
  static const int _tabImporter = 3;

  /// Holt die richtige Kreatur-Liste basierend auf dem Tab-Typ
  /// Wird INNERHALB des Consumers aufgerufen, um aktuelle Daten zu erhalten
  List<Creature> _getCreaturesForTab(BestiaryViewModel viewModel, int listType) {
    switch (listType) {
      case _tabAll:
        // Alle Kreaturen filtern und sortieren
        final filtered = viewModel.filterCreatures(viewModel.allCreatures);
        return viewModel.sortCreatures(filtered);
      case _tabCustom:
        // Eigene Kreaturen
        return viewModel.customCreatures;
      case _tabOfficial:
        // Offizielle Monster
        return viewModel.officialCreatures;
      default:
        return [];
    }
  }

  Widget _buildCreaturesTab(int listType, String title) {
    return Consumer<BestiaryViewModel>(
      builder: (context, viewModel, child) {
        // Liste wird INNERHALB des Consumers basierend auf dem listType berechnet
        final creatures = _getCreaturesForTab(viewModel, listType);
        
        if (viewModel.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  color: DnDTheme.ancientGold,
                ),
                const SizedBox(height: DnDTheme.md),
                Text(
                  'Lade $title...',
                  style: DnDTheme.bodyText1.copyWith(
                    color: DnDTheme.ancientGold,
                  ),
                ),
              ],
            ),
          );
        }

        if (viewModel.error != null) {
          return Center(
            child: Container(
              padding: const EdgeInsets.all(DnDTheme.lg),
              decoration: DnDTheme.getDungeonWallDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: DnDTheme.errorRed,
                    size: 48,
                  ),
                  const SizedBox(height: DnDTheme.md),
                  Text(
                    'Fehler beim Laden',
                    style: DnDTheme.headline3.copyWith(
                      color: DnDTheme.errorRed,
                    ),
                  ),
                  const SizedBox(height: DnDTheme.sm),
                  Text(
                    viewModel.error!,
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: DnDTheme.md),
                  ElevatedButton.icon(
                    onPressed: () {
                      viewModel.clearError();
                      _loadData();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Erneut versuchen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DnDTheme.errorRed,
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
              padding: const EdgeInsets.all(DnDTheme.lg),
              decoration: DnDTheme.getDungeonWallDecoration(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: 64,
                    color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: DnDTheme.md),
                  Text(
                    "Keine Kreaturen gefunden.",
                    style: DnDTheme.bodyText1.copyWith(
                      color: Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (viewModel.searchQuery.isNotEmpty || 
                      viewModel.selectedSourceType != 'all' ||
                      viewModel.showFavoritesOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: DnDTheme.md),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          viewModel.resetFilters();
                          _searchController.clear();
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Filter zurücksetzen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DnDTheme.arcaneBlue,
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
          decoration: BoxDecoration(
            gradient: DnDTheme.getMysticalGradient(
              startColor: DnDTheme.dungeonBlack,
              endColor: DnDTheme.stoneGrey,
            ),
          ),
          child: ListView.builder(
            padding: const EdgeInsets.all(DnDTheme.sm),
            itemCount: creatures.length,
            itemBuilder: (context, index) {
              return _buildCreatureCard(creatures[index]);
            },
          ),
        );
      },
    );
  }

  Widget _buildCreatureCard(Creature creature) {
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
                    await _viewModel.toggleFavorite(creature);
                  } catch (e) {
                    if (mounted) {
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
                    _loadData();
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
                onPressed: () => _showDeleteConfirmation(creature),
                tooltip: 'Löschen',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImporterTab() {
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
                        onPressed: _importFrom5eTools,
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
                        onPressed: _importAllAvailable,
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
                        final isAlreadyImported = _viewModel.allCreatures.any((creature) => 
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
                                      onPressed: () => _addSingleMonster(monster),
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

  Widget _buildFloatingActionButton() {
    return Consumer<BestiaryViewModel>(
      builder: (context, viewModel, child) {
        // Zeige FAB nur auf den ersten drei Tabs
        if (_tabController.index >= 3) return const SizedBox.shrink();
        
        return Container(
          decoration: DnDTheme.getMysticalBorder(
            borderColor: DnDTheme.successGreen,
            width: 3,
          ),
          child: FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (ctx) => const EditCreatureScreen(),
                ),
              );
              if (result == true) {
                _loadData();
              }
            },
            backgroundColor: DnDTheme.successGreen,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Neue Kreatur'),
          ),
        );
      },
    );
  }

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

  void _showImportDialog() {
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _importFrom5eTools();
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

  void _showResetDialog() {
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _viewModel.resetBestiary();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Bestiarum wurde zurückgesetzt'),
                      backgroundColor: DnDTheme.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
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

  void _showDeleteConfirmation(Creature creature) {
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _viewModel.deleteCreature(creature.id.toString());
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${creature.name} wurde gelöscht'),
                      backgroundColor: DnDTheme.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
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

  Future<void> _importFrom5eTools() async {
    try {
      final count = await _viewModel.importMonstersFrom5eTools();
      await _viewModel.loadDndData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count Monster von 5e.tools importiert'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Import: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _importAllAvailable() async {
    try {
      await _viewModel.importAllMonsters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Alle verfügbaren Monster importiert'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Import: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _addSingleMonster(Map<String, dynamic> monsterData) async {
    try {
      await _viewModel.addMonsterToBestiary(monsterData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${monsterData['name']} wurde hinzugefügt'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Hinzufügen: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }
}
