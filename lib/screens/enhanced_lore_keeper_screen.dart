import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wiki_entry.dart';
import '../viewmodels/wiki_viewmodel.dart';
import '../widgets/lore_keeper/enhanced_wiki_entry_card_widget.dart';
import '../widgets/lore_keeper/enhanced_wiki_filter_chips_widget.dart';
import '../widgets/lore_keeper/wiki_search_delegate.dart';
import '../theme/dnd_theme.dart';
import 'enhanced_edit_wiki_entry_screen.dart';

/// Enhanced Lore Keeper Screen mit Provider-Pattern und modernem Enhanced Design
class EnhancedLoreKeeperScreen extends StatefulWidget {
  const EnhancedLoreKeeperScreen({super.key});

  @override
  State<EnhancedLoreKeeperScreen> createState() => _EnhancedLoreKeeperScreenState();
}

class _EnhancedLoreKeeperScreenState extends State<EnhancedLoreKeeperScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Daten laden nach dem Build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WikiViewModel>().loadEntries();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _showSearch() async {
    final viewModel = context.read<WikiViewModel>();
    final delegate = WikiSearchDelegate(
      allEntries: viewModel.allEntries,
      selectedType: viewModel.selectedType,
      selectedTags: viewModel.selectedTags,
    );
    
    final result = await showSearch<WikiEntry?>(
      context: context,
      delegate: delegate,
    );
    
    if (result != null) {
      await _navigateToEditScreen(result);
    }
  }

  Future<void> _navigateToEditScreen([WikiEntry? entryToEdit]) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedEditWikiEntryScreen(entry: entryToEdit),
      ),
    );
    
    // Nach dem Bearbeiten die Daten neu laden
    context.read<WikiViewModel>().refresh();
  }

  Future<void> _deleteEntry(WikiEntry entry) async {
    final confirmed = await _showDeleteConfirmation(entry);
    if (confirmed == true) {
      await context.read<WikiViewModel>().deleteEntry(entry.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${entry.title} gelöscht'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(WikiEntry entry) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Löschen bestätigen',
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.errorRed,
          ),
        ),
        content: Text(
          'Möchtest du "${entry.title}" wirklich löschen?',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
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
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      appBar: AppBar(
        title: Text(
          'Lore Keeper',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        backgroundColor: DnDTheme.stoneGrey,
        foregroundColor: Colors.white,
        elevation: 4,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(140),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: DnDTheme.ancientGold,
                labelColor: DnDTheme.ancientGold,
                unselectedLabelColor: Colors.white70,
                isScrollable: true,
                tabs: const [
                  Tab(text: 'Alle', icon: Icon(Icons.library_books)),
                  Tab(text: 'NPCs', icon: Icon(Icons.people)),
                  Tab(text: 'Orte', icon: Icon(Icons.location_on)),
                  Tab(text: 'Gegenstände', icon: Icon(Icons.inventory)),
                  Tab(text: 'Lore', icon: Icon(Icons.auto_stories)),
                ],
              ),
              Container(
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
                child: Consumer<WikiViewModel>(
                  builder: (context, viewModel, child) {
                    return Column(
                      children: [
                        // Suchfeld
                        TextField(
                          onChanged: viewModel.searchEntries,
                          decoration: InputDecoration(
                            hintText: 'Wiki-Einträge durchsuchen...',
                            hintStyle: DnDTheme.bodyText2.copyWith(
                              color: Colors.white54,
                            ),
                            prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
                            suffixIcon: viewModel.searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: Icon(Icons.clear, color: DnDTheme.errorRed),
                                    onPressed: () => viewModel.searchEntries(''),
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
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          Consumer<WikiViewModel>(
            builder: (context, viewModel, child) {
              return Container(
                margin: const EdgeInsets.only(right: DnDTheme.sm),
                decoration: DnDTheme.getMysticalBorder(
                  borderColor: DnDTheme.arcaneBlue,
                  width: 2,
                ),
                child: PopupMenuButton<WikiSortOption>(
                  icon: Icon(Icons.sort, color: DnDTheme.arcaneBlue),
                  tooltip: 'Sortieren',
                  onSelected: (option) => viewModel.setSortOption(option),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: WikiSortOption.title,
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha, size: 16, color: DnDTheme.arcaneBlue),
                          const SizedBox(width: 8),
                          Text('Alphabetisch', style: DnDTheme.bodyText2.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: WikiSortOption.createdAt,
                      child: Row(
                        children: [
                          Icon(Icons.add_circle, size: 16, color: DnDTheme.arcaneBlue),
                          const SizedBox(width: 8),
                          Text('Erstellt', style: DnDTheme.bodyText2.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: WikiSortOption.updatedAt,
                      child: Row(
                        children: [
                          Icon(Icons.update, size: 16, color: DnDTheme.arcaneBlue),
                          const SizedBox(width: 8),
                          Text('Aktualisiert', style: DnDTheme.bodyText2.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: WikiSortOption.type,
                      child: Row(
                        children: [
                          Icon(Icons.category, size: 16, color: DnDTheme.arcaneBlue),
                          const SizedBox(width: 8),
                          Text('Typ', style: DnDTheme.bodyText2.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: WikiSortOption.tagCount,
                      child: Row(
                        children: [
                          Icon(Icons.local_offer, size: 16, color: DnDTheme.arcaneBlue),
                          const SizedBox(width: 8),
                          Text('Anzahl Tags', style: DnDTheme.bodyText2.copyWith(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWikiList(), // Alle
          _buildWikiList(WikiEntryType.Person), // NPCs
          _buildWikiList(WikiEntryType.Place), // Orte
          _buildWikiList(WikiEntryType.Item), // Gegenstände
          _buildWikiList(WikiEntryType.Lore), // Lore
        ],
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 100, right: 16),
        child: FloatingActionButton.extended(
          onPressed: () => _navigateToEditScreen(),
          icon: const Icon(Icons.add),
          label: const Text('Neuer Eintrag'),
          backgroundColor: DnDTheme.mysticalPurple,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildWikiList([WikiEntryType? filterType]) {
    return Consumer<WikiViewModel>(
      builder: (context, viewModel, child) {
        // Setze den Typ-Filter wenn nötig
        if (filterType != null && viewModel.selectedType != filterType) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            viewModel.setTypeFilter(filterType);
          });
        }

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
                  'Lade Wiki-Einträge...',
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
                      viewModel.refresh();
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

        if (viewModel.filteredEntries.isEmpty) {
          return _buildEmptyState(viewModel.hasActiveFilters);
        }

        return Column(
          children: [
            // Filter-Chips
            Container(
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
              child: EnhancedWikiFilterChipsWidget(
                viewModel: viewModel,
                onSearchChanged: viewModel.searchEntries,
              ),
            ),
            
            // Ergebnisse Liste
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: DnDTheme.getMysticalGradient(
                    startColor: DnDTheme.dungeonBlack,
                    endColor: DnDTheme.stoneGrey,
                  ),
                ),
                child: ListView.builder(
                  padding: const EdgeInsets.all(DnDTheme.sm),
                  itemCount: viewModel.filteredEntries.length,
                  itemBuilder: (context, index) {
                    final entry = viewModel.filteredEntries[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: DnDTheme.sm),
                      child: EnhancedWikiEntryCardWidget(
                        entry: entry,
                        viewModel: viewModel,
                        onTap: () => _navigateToEditScreen(entry),
                        onDelete: () => _deleteEntry(entry),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyState(bool hasActiveFilters) {
    return Consumer<WikiViewModel>(
      builder: (context, viewModel, child) {
        return Center(
          child: Container(
            padding: const EdgeInsets.all(DnDTheme.lg),
            decoration: DnDTheme.getDungeonWallDecoration(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasActiveFilters ? Icons.filter_list : Icons.menu_book,
                  size: 64,
                  color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
                ),
                const SizedBox(height: DnDTheme.md),
                Text(
                  hasActiveFilters ? 'Keine Ergebnisse' : 'Dein Wiki ist noch leer',
                  style: DnDTheme.headline3.copyWith(
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: DnDTheme.sm),
                Text(
                  hasActiveFilters
                      ? 'Keine Wiki-Einträge entsprechen den aktuellen Filtern'
                      : 'Erstelle deine ersten Wiki-Einträge für NPCs, Orte und Lore',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white60,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: DnDTheme.md),
                if (hasActiveFilters)
                  ElevatedButton.icon(
                    onPressed: () => viewModel.clearAllFilters(),
                    icon: const Icon(Icons.clear_all),
                    label: const Text('Filter zurücksetzen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DnDTheme.arcaneBlue,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _navigateToEditScreen(),
                    icon: const Icon(Icons.add),
                    label: const Text('Ersten Eintrag erstellen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DnDTheme.mysticalPurple,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}