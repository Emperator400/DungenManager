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
import '../../widgets/ui_components/feedback/confirmation_dialog.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';

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

  static const _kTabs = [
    (Icons.list, 'Alle'),
    (Icons.flag, 'Hauptquests'),
    (Icons.star, 'Favoriten'),
  ];

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
      MaterialPageRoute(builder: (context) => EditQuestScreen(quest: quest)),
    );
    if (result == true) _viewModel.refresh();
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
    final count = _viewModel.selectedCount;
    final success = await _viewModel.addSelectedToCampaign();
    if (!mounted) return;
    if (success) {
      SnackBarHelper.showSuccess(context, '$count Quest(s) zur Kampagne hinzugefügt');
      Navigator.of(context).pop(true);
    } else {
      SnackBarHelper.showError(context, _viewModel.error ?? 'Fehler beim Hinzufügen');
    }
  }

  Future<void> _deleteQuest(Quest quest) async {
    final confirmed = await ConfirmationDialog.showDelete(
      context: context,
      title: 'Quest löschen',
      message: 'Möchtest du "${quest.title}" wirklich löschen?',
    );
    if (confirmed != true) return;
    await _viewModel.deleteQuest(quest);
    if (mounted) SnackBarHelper.showSuccess(context, 'Quest erfolgreich gelöscht');
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<QuestLibraryViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Consumer<QuestLibraryViewModel>(
            builder: (context, vm, _) => AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) => _buildTopBar(context, vm),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [_buildQuestList(), _buildQuestList(), _buildQuestList()],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, QuestLibraryViewModel vm) {
    final C = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              _IconBtn(icon: Icons.arrow_back, color: C.textMid, onTap: () => Navigator.of(context).pop()),
              Container(width: 1, height: 18, color: C.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: C.amber.withValues(alpha: 0.18),
                  border: Border.all(color: C.amber.withValues(alpha: 0.4)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(child: Icon(Icons.assignment, size: 14, color: C.amber)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isCampaignMode ? 'Quest hinzufügen' : 'Quest-Bibliothek',
                    style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13, height: 1.1),
                  ),
                  if (_isCampaignMode && vm.selectedCount > 0)
                    Text(
                      '${vm.selectedCount} ausgewählt',
                      style: TextStyle(color: C.accent, fontSize: 10, height: 1.1),
                    ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (int i = 0; i < _kTabs.length; i++)
                          _TabBtn(
                            icon: _kTabs[i].$1,
                            label: _kTabs[i].$2,
                            isActive: _tabController.index == i,
                            onTap: () => _tabController.animateTo(i),
                            C: C,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              _IconBtn(icon: Icons.search, color: C.textMid, onTap: _showSearch),
              if (!_isCampaignMode)
                PopupMenuButton<SortOption>(
                  icon: Icon(Icons.sort, size: 18, color: C.textMid),
                  tooltip: 'Sortieren',
                  color: C.bgPanel,
                  onSelected: vm.setSortOption,
                  itemBuilder: (context) => [
                    PopupMenuItem(value: SortOption.alphabetical, child: _sortItem(Icons.sort_by_alpha, 'Alphabetisch', C)),
                    PopupMenuItem(value: SortOption.type, child: _sortItem(Icons.category, 'Typ', C)),
                    PopupMenuItem(value: SortOption.difficulty, child: _sortItem(Icons.bolt, 'Schwierigkeit', C)),
                    PopupMenuItem(value: SortOption.level, child: _sortItem(Icons.signal_cellular_alt, 'Level', C)),
                    PopupMenuItem(value: SortOption.duration, child: _sortItem(Icons.schedule, 'Dauer', C)),
                    PopupMenuItem(value: SortOption.created, child: _sortItem(Icons.add_circle, 'Erstellt', C)),
                    PopupMenuItem(value: SortOption.updated, child: _sortItem(Icons.update, 'Aktualisiert', C)),
                  ],
                ),
              const SizedBox(width: 4),
              if (_isCampaignMode)
                vm.selectedCount > 0
                    ? GestureDetector(
                        onTap: _addSelectedToCampaign,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(color: C.amber, borderRadius: BorderRadius.circular(7)),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add_task, size: 13, color: Colors.black87),
                            const SizedBox(width: 5),
                            Text('${vm.selectedCount} hinzufügen',
                                style: const TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      )
                    : GestureDetector(
                        onTap: _navigateToCreateQuestForCampaign,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(color: C.accent, borderRadius: BorderRadius.circular(7)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add, size: 13, color: Colors.white),
                            SizedBox(width: 5),
                            Text('Neue Quest', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      )
              else
                GestureDetector(
                  onTap: () => _navigateToEditQuest(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(color: C.accent, borderRadius: BorderRadius.circular(7)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.add, size: 13, color: Colors.white),
                      SizedBox(width: 5),
                      Text('Neue Quest', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                    ]),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _sortItem(IconData icon, String label, AppColorsExtension C) => Row(children: [
    Icon(icon, size: 16, color: C.textMid),
    const SizedBox(width: 8),
    Text(label, style: TextStyle(color: C.text, fontSize: 13)),
  ]);

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
                Text('Fehler beim Laden',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.red)),
                const SizedBox(height: 8),
                Text(viewModel.error!,
                    style: TextStyle(fontSize: 14, color: C.textMid), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    viewModel.clearError();
                    viewModel.refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.accent,
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
              if (!_isCampaignMode) EnhancedQuestFilterChipsWidget(viewModel: viewModel),
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
                decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('Hinzugefügt',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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

  Widget _buildEmptyState(QuestLibraryViewModel viewModel, AppColorsExtension C) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.assignment_outlined, size: 64, color: C.border),
        const SizedBox(height: 16),
        Text('Keine Quests gefunden',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.textMid)),
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
            style: ElevatedButton.styleFrom(backgroundColor: C.accent, foregroundColor: Colors.white),
          )
        else
          ElevatedButton.icon(
            onPressed: _isCampaignMode ? _navigateToCreateQuestForCampaign : () => _navigateToEditQuest(),
            icon: const Icon(Icons.add),
            label: const Text('Neue Quest erstellen'),
            style: ElevatedButton.styleFrom(backgroundColor: C.accent, foregroundColor: Colors.white),
          ),
      ],
    ),
  );
}

// ── LOCAL WIDGETS ────────────────────────────────────────────────────────────

class _TabBtn extends StatelessWidget {
  const _TabBtn({required this.icon, required this.label, required this.isActive, required this.onTap, required this.C});
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        margin: const EdgeInsets.symmetric(horizontal: 1),
        decoration: BoxDecoration(
          color: isActive ? C.bgHover : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 13, color: isActive ? C.accent : C.textSoft),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            color: isActive ? C.text : C.textMid,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
          )),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 30, height: 30, child: Icon(icon, size: 18, color: color)),
    );
  }
}
