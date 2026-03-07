import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/quest.dart';
import '../../screens/quests/edit_quest_screen.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/quest_library_viewmodel.dart';
import '../../widgets/quest_library/enhanced_quest_filter_chips_widget.dart';
import '../../widgets/quest_library/quest_search_delegate.dart';
import '../../widgets/ui_components/cards/unified_quest_card.dart';

class QuestLibraryScreen extends StatefulWidget {
  const QuestLibraryScreen({super.key});

  @override
  State<QuestLibraryScreen> createState() => _QuestLibraryScreenState();
}

class _QuestLibraryScreenState extends State<QuestLibraryScreen>
    with SingleTickerProviderStateMixin {
  late QuestLibraryViewModel _viewModel;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _viewModel = QuestLibraryViewModel();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    // Daten laden nach dem ersten Frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.loadQuests();
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) return;
    _viewModel.setCurrentTab(_tabController.index);
  }

  Future<void> _showSearch() async {
    final selectedQuest = await showSearch<Quest?>(
      context: context,
      delegate: QuestSearchDelegate(
        allQuests: _viewModel.allQuests,
        selectedType: _viewModel.selectedType,
        selectedDifficulty: _viewModel.selectedDifficulty,
        selectedTags: _viewModel.selectedTags,
        showFavoritesOnly: _viewModel.showFavoritesOnly,
      ),
    );

    if (selectedQuest != null) {
      await _navigateToEditQuest(selectedQuest);
    }
  }

  Future<void> _navigateToEditQuest([Quest? quest]) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EditQuestScreen(quest: quest),
      ),
    );

    if (result == true) {
      _viewModel.refresh();
    }
  }

  Future<void> _deleteQuest(Quest quest) async {
    final confirmed = await _showDeleteConfirmation(quest);
    if (!confirmed) return;

    await _viewModel.deleteQuest(quest);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quest erfolgreich gelöscht'),
          backgroundColor: DnDTheme.successGreen,
        ),
      );
    }
  }

  Future<bool> _showDeleteConfirmation(Quest quest) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Quest löschen'),
        content: Text('Möchtest du "${quest.title}" wirklich löschen?'),
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
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<QuestLibraryViewModel>.value(
      value: _viewModel,
      child: Scaffold(
      appBar: AppBar(
        title: const Text('Quest-Bibliothek'),
        backgroundColor: DnDTheme.stoneGrey,
        foregroundColor: Colors.white,
        elevation: 4,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: DnDTheme.ancientGold,
          labelColor: DnDTheme.ancientGold,
          unselectedLabelColor: Colors.white70,
          onTap: (index) => _viewModel.setCurrentTab(index),
          tabs: const [
            Tab(text: 'Alle', icon: Icon(Icons.list)),
            Tab(text: 'Hauptquests', icon: Icon(Icons.flag)),
            Tab(text: 'Favoriten', icon: Icon(Icons.star)),
          ],
        ),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearch,
              tooltip: 'Suchen',
            ),
            Consumer<QuestLibraryViewModel>(
              builder: (context, viewModel, child) {
                return PopupMenuButton<SortOption>(
                  icon: const Icon(Icons.sort),
                  tooltip: 'Sortieren',
                  onSelected: (option) {
                    viewModel.setSortOption(option);
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: SortOption.alphabetical,
                      child: Row(
                        children: [
                          Icon(Icons.sort_by_alpha),
                          SizedBox(width: 8),
                          Text('Alphabetisch'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: SortOption.type,
                      child: Row(
                        children: [
                          Icon(Icons.category),
                          SizedBox(width: 8),
                          Text('Typ'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: SortOption.difficulty,
                      child: Row(
                        children: [
                          Icon(Icons.bolt),
                          SizedBox(width: 8),
                          Text('Schwierigkeit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: SortOption.level,
                      child: Row(
                        children: [
                          Icon(Icons.signal_cellular_alt),
                          SizedBox(width: 8),
                          Text('Level'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: SortOption.duration,
                      child: Row(
                        children: [
                          Icon(Icons.schedule),
                          SizedBox(width: 8),
                          Text('Dauer'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: SortOption.created,
                      child: Row(
                        children: [
                          Icon(Icons.add_circle),
                          SizedBox(width: 8),
                          Text('Erstellt'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: SortOption.updated,
                      child: Row(
                        children: [
                          Icon(Icons.update),
                          SizedBox(width: 8),
                          Text('Aktualisiert'),
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
            _buildQuestList(), // Alle Quests
            _buildQuestList(), // Hauptquests (gefiltert)
            _buildQuestList(), // Favoriten (gefiltert)
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => _navigateToEditQuest(),
          backgroundColor: DnDTheme.mysticalPurple,
          child: const Icon(Icons.add),
          tooltip: 'Neue Quest',
        ),
      ),
    );
  }

  Widget _buildQuestList() {
    return Consumer<QuestLibraryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
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

        if (viewModel.filteredQuests.isEmpty) {
          return _buildEmptyState();
        }

        return RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: Column(
            children: [
              // Filter-Chips
              EnhancedQuestFilterChipsWidget(
                viewModel: viewModel,
              ),
              
              // Quest-Liste
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: viewModel.filteredQuests.length,
                  itemBuilder: (context, index) {
                    final quest = viewModel.filteredQuests[index];
                    return UnifiedQuestCard(
                      quest: quest,
                      onTap: () => _navigateToEditQuest(quest),
                      onEdit: () => _navigateToEditQuest(quest),
                      onDelete: () => _deleteQuest(quest),
                      onToggleFavorite: () => viewModel.toggleFavorite(quest),
                      isFavorite: quest.isFavorite,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Consumer<QuestLibraryViewModel>(
      builder: (context, viewModel, child) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_outlined,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                'Keine Quests gefunden',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                viewModel.hasActiveFilters 
                    ? 'Keine Quests entsprechen den aktuellen Filtern'
                    : 'Erstelle deine erste Quest oder ändere die Filter',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              if (viewModel.hasActiveFilters)
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
                  onPressed: () => _navigateToEditQuest(),
                  icon: const Icon(Icons.add),
                  label: const Text('Neue Quest erstellen'),
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
