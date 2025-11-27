import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/wiki_entry.dart';
import '../viewmodels/wiki_viewmodel.dart';
import '../widgets/lore_keeper/enhanced_wiki_entry_card_widget.dart';
import '../widgets/lore_keeper/enhanced_wiki_filter_chips_widget.dart';
import '../widgets/lore_keeper/wiki_search_delegate.dart';
import '../theme/dnd_theme.dart';
import 'enhanced_edit_wiki_entry_screen.dart';

/// Enhanced Lore Keeper Screen mit Provider-Pattern und modernem Design
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
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<bool?> _showDeleteConfirmation(WikiEntry entry) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Löschen bestätigen'),
        content: Text('Möchtest du "${entry.title}" wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: DnDTheme.errorRed),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<WikiViewModel>(
      create: (_) => WikiViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Lore Keeper', style: TextStyle(color: DnDTheme.ancientGold)),
          backgroundColor: DnDTheme.stoneGrey,
          foregroundColor: Colors.white,
          elevation: 4,
          bottom: TabBar(
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
          actions: [
            Consumer<WikiViewModel>(
              builder: (context, viewModel, child) {
                return IconButton(
                  icon: const Icon(Icons.search, color: Colors.white),
                  onPressed: _showSearch,
                  tooltip: 'Suchen',
                );
              },
            ),
            Consumer<WikiViewModel>(
              builder: (context, viewModel, child) {
                return PopupMenuButton<WikiSortOption>(
                  icon: const Icon(Icons.sort, color: Colors.white),
                  tooltip: 'Sortieren',
                  onSelected: (option) => viewModel.setSortOption(option),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: WikiSortOption.title,
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha, color: DnDTheme.stoneGrey),
                          SizedBox(width: 8),
                          Text('Alphabetisch'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: WikiSortOption.createdAt,
                      child: Row(
                        children: [
                          Icon(Icons.add_circle, color: DnDTheme.stoneGrey),
                          SizedBox(width: 8),
                          Text('Erstellt'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: WikiSortOption.updatedAt,
                      child: Row(
                        children: [
                          Icon(Icons.update, color: DnDTheme.stoneGrey),
                          SizedBox(width: 8),
                          Text('Aktualisiert'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: WikiSortOption.type,
                      child: Row(
                        children: [
                          Icon(Icons.category, color: DnDTheme.stoneGrey),
                          SizedBox(width: 8),
                          Text('Typ'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: WikiSortOption.tagCount,
                      child: Row(
                        children: [
                          Icon(Icons.local_offer, color: DnDTheme.stoneGrey),
                          SizedBox(width: 8),
                          Text('Anzahl Tags'),
                        ],
                      ),
                    ),
                  ],
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
        floatingActionButton: FloatingActionButton.extended(
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
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(DnDTheme.mysticalPurple),
            ),
          );
        }

        if (viewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: DnDTheme.errorRed,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fehler beim Laden',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: DnDTheme.errorRed,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  viewModel.error!,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    viewModel.clearError();
                    viewModel.refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DnDTheme.mysticalPurple,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suchfeld
                  TextField(
                    onChanged: viewModel.searchEntries,
                    decoration: InputDecoration(
                      hintText: 'Wiki-Einträge durchsuchen...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: viewModel.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => viewModel.searchEntries(''),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DnDTheme.stoneGrey.withOpacity(0.3)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: DnDTheme.ancientGold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Filter-Chips
                  EnhancedWikiFilterChipsWidget(
                    viewModel: viewModel,
                    onSearchChanged: viewModel.searchEntries,
                  ),
                ],
              ),
            ),
            
            // Ergebnisse Liste
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: viewModel.filteredEntries.length,
                itemBuilder: (context, index) {
                  final entry = viewModel.filteredEntries[index];
                  return EnhancedWikiEntryCardWidget(
                    entry: entry,
                    viewModel: viewModel,
                    onTap: () => _navigateToEditScreen(entry),
                    onDelete: () => _deleteEntry(entry),
                  );
                },
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                hasActiveFilters ? Icons.filter_list : Icons.menu_book,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                hasActiveFilters ? 'Keine Ergebnisse' : 'Dein Wiki ist noch leer',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasActiveFilters
                    ? 'Keine Wiki-Einträge entsprechen den aktuellen Filtern'
                    : 'Erstelle deine ersten Wiki-Einträge für NPCs, Orte und Lore',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (hasActiveFilters)
                ElevatedButton.icon(
                  onPressed: () => viewModel.clearAllFilters(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Filter zurücksetzen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DnDTheme.mysticalPurple,
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
        );
      },
    );
  }
}
