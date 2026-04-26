import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/quest.dart';
import '../../screens/quests/edit_quest_screen.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/edit_quest_viewmodel.dart';
import '../../viewmodels/quest_library_viewmodel.dart';
import '../../widgets/quest_library/enhanced_quest_filter_chips_widget.dart';
import '../../widgets/quest_library/quest_search_delegate.dart';
import '../../widgets/ui_components/cards/unified_quest_card.dart';

class QuestLibraryScreen extends StatefulWidget {
  final String? campaignId;

  const QuestLibraryScreen({super.key, this.campaignId});

  @override
  State<QuestLibraryScreen> createState() => _QuestLibraryScreenState();
}

class _QuestLibraryScreenState extends State<QuestLibraryScreen>
    with SingleTickerProviderStateMixin {
  late QuestLibraryViewModel _viewModel;
  late TabController _tabController;

  bool get _isCampaignMode => widget.campaignId != null;

  @override
  void initState() {
    super.initState();
    _viewModel = QuestLibraryViewModel();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isCampaignMode) {
        _viewModel.initCampaignMode(widget.campaignId!);
      } else {
        _viewModel.loadQuests();
      }
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
      if (_isCampaignMode) {
        _viewModel.toggleSelection(selectedQuest);
      } else {
        await _navigateToEditQuest(selectedQuest);
      }
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

  Future<void> _navigateToCreateQuestForCampaign() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<EditQuestViewModel>(
          create: (_) => EditQuestViewModel(),
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context
                    .read<EditQuestViewModel>()
                    .initialize(null, campaignId: widget.campaignId);
              });
              return const EditQuestScreen();
            },
          ),
        ),
      ),
    );

    if ((result ?? false) && _isCampaignMode) {
      await _viewModel.initCampaignMode(widget.campaignId!);
    }
  }

  Future<void> _addSelectedToCampaign() async {
    final C = context.appColors;
    final count = _viewModel.selectedCount;
    final success = await _viewModel.addSelectedToCampaign();
    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count Quest(s) zur Kampagne hinzugefügt'),
          backgroundColor: C.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.error ?? 'Fehler beim Hinzufügen'),
          backgroundColor: C.red,
        ),
      );
    }
  }

  Future<void> _deleteQuest(Quest quest) async {
    final confirmed = await _showDeleteConfirmation(quest);
    if (!confirmed) {
      return;
    }

    await _viewModel.deleteQuest(quest);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Quest erfolgreich gelöscht'),
          backgroundColor: context.appColors.green,
        ),
      );
    }
  }

  Future<bool> _showDeleteConfirmation(Quest quest) async {
    final C = context.appColors;
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
            style: TextButton.styleFrom(foregroundColor: C.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return ChangeNotifierProvider<QuestLibraryViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _isCampaignMode ? 'Quest zur Kampagne hinzufügen' : 'Quest-Bibliothek',
          ),
          backgroundColor: C.bgPanel,
          foregroundColor: C.text,
          elevation: 0,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: C.amber,
            labelColor: C.amber,
            unselectedLabelColor: C.textSoft,
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
            if (!_isCampaignMode)
              Consumer<QuestLibraryViewModel>(
                builder: (context, viewModel, child) {
                  return PopupMenuButton<SortOption>(
                    icon: const Icon(Icons.sort),
                    tooltip: 'Sortieren',
                    onSelected: viewModel.setSortOption,
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: SortOption.alphabetical,
                        child: Row(children: [Icon(Icons.sort_by_alpha), SizedBox(width: 8), Text('Alphabetisch')]),
                      ),
                      const PopupMenuItem(
                        value: SortOption.type,
                        child: Row(children: [Icon(Icons.category), SizedBox(width: 8), Text('Typ')]),
                      ),
                      const PopupMenuItem(
                        value: SortOption.difficulty,
                        child: Row(children: [Icon(Icons.bolt), SizedBox(width: 8), Text('Schwierigkeit')]),
                      ),
                      const PopupMenuItem(
                        value: SortOption.level,
                        child: Row(children: [Icon(Icons.signal_cellular_alt), SizedBox(width: 8), Text('Level')]),
                      ),
                      const PopupMenuItem(
                        value: SortOption.duration,
                        child: Row(children: [Icon(Icons.schedule), SizedBox(width: 8), Text('Dauer')]),
                      ),
                      const PopupMenuItem(
                        value: SortOption.created,
                        child: Row(children: [Icon(Icons.add_circle), SizedBox(width: 8), Text('Erstellt')]),
                      ),
                      const PopupMenuItem(
                        value: SortOption.updated,
                        child: Row(children: [Icon(Icons.update), SizedBox(width: 8), Text('Aktualisiert')]),
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
            _buildQuestList(),
            _buildQuestList(),
            _buildQuestList(),
          ],
        ),
        floatingActionButton: _buildFab(C),
      ),
    );
  }

  Widget _buildFab(AppColorsExtension C) {
    if (_isCampaignMode) {
      return Consumer<QuestLibraryViewModel>(
        builder: (context, vm, _) {
          if (vm.selectedCount > 0) {
            return FloatingActionButton.extended(
              backgroundColor: C.amber,
              foregroundColor: Colors.black87,
              icon: const Icon(Icons.add_task),
              label: Text('${vm.selectedCount} Quest(s) hinzufügen'),
              onPressed: _addSelectedToCampaign,
            );
          }
          return FloatingActionButton(
            backgroundColor: const Color(0xFF7C3AED),
            tooltip: 'Neue Quest erstellen',
            onPressed: _navigateToCreateQuestForCampaign,
            child: const Icon(Icons.add),
          );
        },
      );
    }

    return FloatingActionButton(
      onPressed: () => _navigateToEditQuest(),
      backgroundColor: const Color(0xFF7C3AED),
      tooltip: 'Neue Quest',
      child: const Icon(Icons.add),
    );
  }

  Widget _buildQuestList() {
    return Consumer<QuestLibraryViewModel>(
      builder: (context, viewModel, child) {
        final C = context.appColors;

        if (viewModel.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (viewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: C.red),
                const SizedBox(height: 16),
                Text(
                  'Fehler beim Laden',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.red),
                ),
                const SizedBox(height: 8),
                Text(
                  viewModel.error!,
                  style: TextStyle(fontSize: 14, color: C.textMid),
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
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          );
        }

        if (viewModel.filteredQuests.isEmpty) {
          return _buildEmptyState(viewModel, C);
        }

        return RefreshIndicator(
          onRefresh: viewModel.refresh,
          child: Column(
            children: [
              if (!_isCampaignMode)
                EnhancedQuestFilterChipsWidget(viewModel: viewModel),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: viewModel.filteredQuests.length,
                  itemBuilder: (context, index) {
                    final quest = viewModel.filteredQuests[index];
                    return _buildQuestItem(quest, viewModel, C);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildQuestItem(Quest quest, QuestLibraryViewModel viewModel, AppColorsExtension C) {
    if (_isCampaignMode) {
      final linked = viewModel.isLinked(quest);
      final selected = viewModel.isSelected(quest);

      return Stack(
        children: [
          UnifiedQuestCard(
            quest: quest,
            isSelected: selected,
            onTap: linked ? null : () => viewModel.toggleSelection(quest),
            onEdit: null,
            onDelete: null,
            onToggleFavorite: null,
          ),
          if (linked)
            Positioned(
              bottom: 10,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: C.green,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Hinzugefügt',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
    }

    return UnifiedQuestCard(
      quest: quest,
      onTap: () => _navigateToEditQuest(quest),
      onEdit: () => _navigateToEditQuest(quest),
      onDelete: () => _deleteQuest(quest),
      onToggleFavorite: () => viewModel.toggleFavorite(quest),
    );
  }

  Widget _buildEmptyState(QuestLibraryViewModel viewModel, AppColorsExtension C) =>
      Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_outlined, size: 64, color: C.border),
          const SizedBox(height: 16),
          Text(
            'Keine Quests gefunden',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.textMid),
          ),
          const SizedBox(height: 8),
          Text(
            viewModel.hasActiveFilters
                ? 'Keine Quests entsprechen den aktuellen Filtern'
                : _isCampaignMode
                    ? 'Erstelle eine neue Quest für diese Kampagne'
                    : 'Erstelle deine erste Quest',
            style: TextStyle(fontSize: 14, color: C.textSoft),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          if (viewModel.hasActiveFilters)
            ElevatedButton.icon(
              onPressed: () => viewModel.clearAllFilters(),
              icon: const Icon(Icons.clear_all),
              label: const Text('Filter zurücksetzen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
            )
          else
            ElevatedButton.icon(
              onPressed: _isCampaignMode
                  ? _navigateToCreateQuestForCampaign
                  : () => _navigateToEditQuest(),
              icon: const Icon(Icons.add),
              label: const Text('Neue Quest erstellen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
}
