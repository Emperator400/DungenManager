import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/quest.dart';
import '../../models/quest_reward.dart';
import '../../screens/quests/edit_quest_screen.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/quest_library_viewmodel.dart';
import '../../widgets/ui_components/feedback/confirmation_dialog.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';

// ── TYPE CONFIG ────────────────────────────────────────────────────────────────

class _QC {
  const _QC({required this.color, required this.icon});
  final Color color;
  final IconData icon;
}

const Map<QuestType, _QC> _qc = {
  QuestType.main:     _QC(color: Color(0xFFc93a3a), icon: Icons.flag),
  QuestType.side:     _QC(color: Color(0xFF2f6feb), icon: Icons.star_border),
  QuestType.personal: _QC(color: Color(0xFF7c3aed), icon: Icons.person),
  QuestType.faction:  _QC(color: Color(0xFF1a7f4b), icon: Icons.groups),
};

_QC _cfg(QuestType type) => _qc[type]!;

String _questTypeName(QuestType type) => switch (type) {
  QuestType.main     => 'Hauptquest',
  QuestType.side     => 'Nebenquest',
  QuestType.personal => 'Persönlich',
  QuestType.faction  => 'Fraktion',
};

String _statusName(QuestStatus status) => switch (status) {
  QuestStatus.active    => 'Aktiv',
  QuestStatus.completed => 'Abgeschlossen',
  QuestStatus.failed    => 'Fehlgeschlagen',
  QuestStatus.abandoned => 'Aufgegeben',
  QuestStatus.onHold    => 'Pausiert',
};

String _difficultyName(QuestDifficulty d) => switch (d) {
  QuestDifficulty.easy      => 'Einfach',
  QuestDifficulty.medium    => 'Mittel',
  QuestDifficulty.hard      => 'Schwer',
  QuestDifficulty.deadly    => 'Tödlich',
  QuestDifficulty.epic      => 'Episch',
  QuestDifficulty.legendary => 'Legendär',
};

// ── SCREEN ────────────────────────────────────────────────────────────────────

class QuestLibraryScreen extends StatefulWidget {
  final String? campaignId;
  const QuestLibraryScreen({super.key, this.campaignId});

  @override
  State<QuestLibraryScreen> createState() => _QuestLibraryScreenState();
}

class _QuestLibraryScreenState extends State<QuestLibraryScreen> {
  late QuestLibraryViewModel _viewModel;
  final _searchCtrl = TextEditingController();
  Quest? _selectedQuest;

  bool get _isCampaignMode => widget.campaignId != null;

  @override
  void initState() {
    super.initState();
    _viewModel = QuestLibraryViewModel();
    _searchCtrl.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isCampaignMode) {
        _viewModel.initCampaignMode(widget.campaignId!);
      } else {
        _viewModel.loadQuests().then((_) {
          if (mounted && _viewModel.filteredQuests.isNotEmpty) {
            setState(() => _selectedQuest = _viewModel.filteredQuests.first);
          }
        });
      }
    });
  }

  void _onSearchChanged() => _viewModel.searchQuests(_searchCtrl.text);

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _navigateToEditQuest([Quest? quest]) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditQuestScreen(quest: quest)),
    );
    if (result == true && mounted) {
      await _viewModel.refresh();
      if (mounted) {
        setState(() {
          _selectedQuest = quest != null
              ? _viewModel.filteredQuests.where((q) => q.id == quest.id).firstOrNull
              : _viewModel.filteredQuests.firstOrNull;
        });
      }
    }
  }

  Future<void> _navigateToCreateQuestForCampaign() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => EditQuestScreen(campaignId: widget.campaignId)),
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
    if (confirmed != true || !mounted) return;
    await _viewModel.deleteQuest(quest);
    if (mounted) {
      SnackBarHelper.showSuccess(context, 'Quest erfolgreich gelöscht');
      setState(() => _selectedQuest = _viewModel.filteredQuests.firstOrNull);
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return ChangeNotifierProvider<QuestLibraryViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: _buildTopBar(context, C),
        body: _isCampaignMode
            ? _buildCampaignBody(context, C)
            : Row(
                children: [
                  SizedBox(width: 340, child: _buildLeftPane(context, C)),
                  VerticalDivider(width: 1, thickness: 1, color: C.border),
                  Expanded(child: _buildRightPane(context, C)),
                ],
              ),
      ),
    );
  }

  // ── TOP BAR ───────────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildTopBar(BuildContext context, AppColorsExtension C) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(48),
      child: Container(
        height: 48,
        color: C.bgPanel,
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    if (Navigator.canPop(context)) ...[
                      _IconBtn(
                        icon: Icons.arrow_back,
                        color: C.textMid,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 4),
                      Container(width: 1, height: 18, color: C.border),
                      const SizedBox(width: 10),
                    ],
                    Container(
                      width: 26,
                      height: 26,
                      decoration: BoxDecoration(
                        color: C.amber.withValues(alpha: 0.18),
                        border: Border.all(color: C.amber.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Icon(Icons.assignment, size: 13, color: C.amber)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isCampaignMode ? 'Quest hinzufügen' : 'Quest-Bibliothek',
                      style: TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
                    ),
                    const Spacer(),
                    Consumer<QuestLibraryViewModel>(
                      builder: (_, vm, __) {
                        if (_isCampaignMode && vm.selectedCount > 0) {
                          return Text(
                            '${vm.selectedCount} ausgewählt',
                            style: TextStyle(fontSize: 12, color: C.accent),
                          );
                        }
                        return Text(
                          '${vm.filteredQuests.length} Quests',
                          style: TextStyle(fontSize: 12, color: C.textSoft),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    if (_isCampaignMode)
                      Consumer<QuestLibraryViewModel>(
                        builder: (_, vm, __) => vm.selectedCount > 0
                            ? _ActionBtn(
                                label: '${vm.selectedCount} hinzufügen',
                                icon: Icons.add_task,
                                color: C.amber,
                                textColor: Colors.black87,
                                onTap: _addSelectedToCampaign,
                              )
                            : _ActionBtn(
                                label: 'Neue Quest',
                                icon: Icons.add,
                                color: C.accent,
                                textColor: Colors.white,
                                onTap: _navigateToCreateQuestForCampaign,
                              ),
                      )
                    else
                      _ActionBtn(
                        label: 'Neue Quest',
                        icon: Icons.add,
                        color: C.accent,
                        textColor: Colors.white,
                        onTap: () => _navigateToEditQuest(),
                      ),
                  ],
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: C.border),
          ],
        ),
      ),
    );
  }

  // ── LEFT PANE ─────────────────────────────────────────────────────────────────

  Widget _buildLeftPane(BuildContext context, AppColorsExtension C) {
    return Consumer<QuestLibraryViewModel>(
      builder: (_, vm, __) {
        final presentTypes = QuestType.values
            .where((t) => vm.allQuests.any((q) => q.questType == t))
            .toList();

        return Container(
          color: C.bgPanel,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: _SearchField(C: C, ctrl: _searchCtrl),
              ),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                  children: [
                    _TypeChip(
                      label: 'Alle',
                      isActive: vm.selectedType == null,
                      color: C.accent,
                      dot: C.accent,
                      onTap: () => vm.setTypeFilter(null),
                    ),
                    ...presentTypes.map((t) {
                      final cfg = _cfg(t);
                      final isActive = vm.selectedType == t;
                      return _TypeChip(
                        label: _questTypeName(t),
                        isActive: isActive,
                        color: cfg.color,
                        dot: cfg.color,
                        onTap: () => vm.setTypeFilter(isActive ? null : t),
                      );
                    }),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: C.border),
              Expanded(
                child: vm.isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: C.accent, strokeWidth: 2))
                    : vm.filteredQuests.isEmpty
                        ? _EmptyList(C: C, hasSearch: vm.hasActiveFilters)
                        : ListView.builder(
                            itemCount: vm.filteredQuests.length,
                            itemBuilder: (_, i) {
                              final quest = vm.filteredQuests[i];
                              final isSelected = _selectedQuest?.id == quest.id;
                              return _QuestRow(
                                quest: quest,
                                isSelected: isSelected,
                                C: C,
                                onTap: () =>
                                    setState(() => _selectedQuest = quest),
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

  // ── RIGHT PANE ────────────────────────────────────────────────────────────────

  Widget _buildRightPane(BuildContext context, AppColorsExtension C) {
    final quest = _selectedQuest;
    if (quest == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.assignment_outlined, size: 32, color: C.border),
            const SizedBox(height: 10),
            Text('Quest auswählen',
                style: TextStyle(fontSize: 14, color: C.textSoft)),
          ],
        ),
      );
    }
    return _QuestDetail(
      key: ValueKey(quest.id),
      quest: quest,
      C: C,
      onEdit: () => _navigateToEditQuest(quest),
      onDelete: () => _deleteQuest(quest),
      onToggleFavorite: () => _viewModel.toggleFavorite(quest),
    );
  }

  // ── CAMPAIGN BODY ─────────────────────────────────────────────────────────────

  Widget _buildCampaignBody(BuildContext context, AppColorsExtension C) {
    return Consumer<QuestLibraryViewModel>(
      builder: (context, vm, _) {
        if (vm.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        if (vm.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: C.red),
                const SizedBox(height: 12),
                Text('Fehler beim Laden',
                    style: TextStyle(fontSize: 16, color: C.red)),
                const SizedBox(height: 8),
                Text(vm.error!,
                    style: TextStyle(fontSize: 13, color: C.textMid),
                    textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    vm.clearError();
                    vm.refresh();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Erneut versuchen'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: C.accent, foregroundColor: Colors.white),
                ),
              ],
            ),
          );
        }
        if (vm.filteredQuests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 48, color: C.border),
                const SizedBox(height: 12),
                Text('Keine Quests gefunden',
                    style: TextStyle(fontSize: 16, color: C.textMid)),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _navigateToCreateQuestForCampaign,
                  icon: const Icon(Icons.add),
                  label: const Text('Neue Quest erstellen'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: C.accent, foregroundColor: Colors.white),
                ),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: vm.filteredQuests.length,
          itemBuilder: (context, index) {
            final quest = vm.filteredQuests[index];
            final linked = vm.isLinked(quest);
            final selected = vm.isSelected(quest);
            return Stack(
              children: [
                _CampaignQuestRow(
                  quest: quest,
                  isSelected: selected,
                  isLinked: linked,
                  C: C,
                  onTap: linked ? null : () => vm.toggleSelection(quest),
                ),
                if (linked)
                  Positioned(
                    bottom: 10,
                    right: 14,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                          color: C.green,
                          borderRadius: BorderRadius.circular(12)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check, color: Colors.white, size: 12),
                          SizedBox(width: 4),
                          Text('Hinzugefügt',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── QUEST ROW ─────────────────────────────────────────────────────────────────

class _QuestRow extends StatefulWidget {
  const _QuestRow({
    required this.quest,
    required this.isSelected,
    required this.C,
    required this.onTap,
  });

  final Quest quest;
  final bool isSelected;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  State<_QuestRow> createState() => _QuestRowState();
}

class _QuestRowState extends State<_QuestRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final quest = widget.quest;
    final C = widget.C;
    final cfg = _cfg(quest.questType);
    final sel = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: sel
                ? C.bgActive
                : _hovered
                    ? C.bgHover
                    : Colors.transparent,
            border: Border(
              bottom: BorderSide(color: C.border),
              left: BorderSide(
                color: sel ? cfg.color : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: cfg.color.withValues(alpha: 0.15),
                  border: Border.all(color: cfg.color.withValues(alpha: 0.28)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text(
                    quest.title.isNotEmpty ? quest.title[0].toUpperCase() : '?',
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: cfg.color),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            sel ? FontWeight.w500 : FontWeight.w400,
                        color: C.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    _QuestTypeBadge(type: quest.questType, small: true),
                  ],
                ),
              ),
              if (quest.isFavorite)
                Icon(Icons.star, size: 13, color: C.amber),
            ],
          ),
        ),
      ),
    );
  }
}

// ── CAMPAIGN QUEST ROW ────────────────────────────────────────────────────────

class _CampaignQuestRow extends StatelessWidget {
  const _CampaignQuestRow({
    required this.quest,
    required this.isSelected,
    required this.isLinked,
    required this.C,
    required this.onTap,
  });

  final Quest quest;
  final bool isSelected;
  final bool isLinked;
  final AppColorsExtension C;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg(quest.questType);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? C.bgActive : Colors.transparent,
          border: Border(bottom: BorderSide(color: C.border)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: cfg.color.withValues(alpha: 0.15),
                border:
                    Border.all(color: cfg.color.withValues(alpha: 0.28)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(child: Icon(cfg.icon, size: 16, color: cfg.color)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    quest.title,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: C.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      _QuestTypeBadge(type: quest.questType, small: true),
                      if (quest.description.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            quest.description,
                            style: TextStyle(
                                fontSize: 10, color: C.textSoft),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 22,
                height: 22,
                decoration:
                    BoxDecoration(color: C.accent, shape: BoxShape.circle),
                child:
                    const Icon(Icons.check, color: Colors.white, size: 14),
              ),
            if (isLinked) const SizedBox(width: 22),
          ],
        ),
      ),
    );
  }
}

// ── QUEST DETAIL ──────────────────────────────────────────────────────────────

class _QuestDetail extends StatelessWidget {
  const _QuestDetail({
    super.key,
    required this.quest,
    required this.C,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleFavorite,
  });

  final Quest quest;
  final AppColorsExtension C;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg(quest.questType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            decoration: BoxDecoration(
              color: cfg.color.withValues(alpha: 0.08),
              border: Border.all(color: cfg.color.withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cfg.color.withValues(alpha: 0.15),
                    border:
                        Border.all(color: cfg.color.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      quest.title.isNotEmpty
                          ? quest.title[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: cfg.color),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(quest.title,
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: C.text)),
                      const SizedBox(height: 4),
                      _QuestTypeBadge(type: quest.questType),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    quest.isFavorite ? Icons.star : Icons.star_border,
                    size: 18,
                    color: quest.isFavorite ? C.amber : C.textSoft,
                  ),
                  onPressed: onToggleFavorite,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 2),
                _EditBtn(C: C, onTap: onEdit),
                const SizedBox(width: 6),
                _DeleteBtn(C: C, onTap: onDelete),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Meta Grid ─────────────────────────────────
          _buildMetaGrid(),
          const SizedBox(height: 14),

          // ── Description ───────────────────────────────
          if (quest.description.isNotEmpty) ...[
            _SectionLabel('Beschreibung', C),
            const SizedBox(height: 6),
            Text(
              quest.description,
              style: TextStyle(fontSize: 12, color: C.textMid, height: 1.5),
              maxLines: 8,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 14),
          ],

          // ── Tags ──────────────────────────────────────
          if (quest.tags.isNotEmpty) ...[
            _SectionLabel('Tags', C),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: quest.tags
                  .map((tag) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: C.bgPanel,
                          border: Border.all(color: C.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(tag,
                            style:
                                TextStyle(fontSize: 11, color: C.textMid)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 14),
          ],

          // ── Rewards ───────────────────────────────────
          if (quest.rewards.isNotEmpty) ...[
            _SectionLabel('Belohnungen', C),
            const SizedBox(height: 6),
            ...quest.rewards.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: _RewardTile(reward: r, C: C),
                )),
            const SizedBox(height: 14),
          ],

          // ── NPCs ──────────────────────────────────────
          if (quest.involvedNpcs.isNotEmpty) ...[
            _SectionLabel('Beteiligte NPCs', C),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: quest.involvedNpcs
                  .map((npc) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: C.bgPanel,
                          border: Border.all(color: C.border),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_outline,
                                size: 11, color: C.textSoft),
                            const SizedBox(width: 4),
                            Text(npc,
                                style: TextStyle(
                                    fontSize: 11, color: C.textMid)),
                          ],
                        ),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetaGrid() {
    final entries = <_MetaEntry>[
      _MetaEntry(label: 'Status', value: _statusName(quest.status)),
      _MetaEntry(label: 'Typ', value: _questTypeName(quest.questType)),
      _MetaEntry(
          label: 'Schwierigkeit',
          value: _difficultyName(quest.difficulty)),
      if (quest.location != null && quest.location!.isNotEmpty)
        _MetaEntry(label: 'Ort', value: quest.location!),
      if (quest.recommendedLevel != null)
        _MetaEntry(label: 'Level', value: 'Level ${quest.recommendedLevel}'),
      if (quest.estimatedDurationHours != null)
        _MetaEntry(
            label: 'Dauer',
            value:
                '${quest.estimatedDurationHours!.toStringAsFixed(1)} h'),
    ];

    if (entries.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3,
      ),
      itemCount: entries.length,
      itemBuilder: (_, i) => _MetaTile(entry: entries[i], C: C),
    );
  }
}

// ── LOCAL WIDGETS ─────────────────────────────────────────────────────────────

class _QuestTypeBadge extends StatelessWidget {
  const _QuestTypeBadge({required this.type, this.small = false});

  final QuestType type;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg(type);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: cfg.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration:
                BoxDecoration(color: cfg.color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            _questTypeName(type),
            style: TextStyle(
              fontSize: small ? 10 : 11,
              fontWeight: FontWeight.w500,
              color: cfg.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isActive,
    required this.color,
    required this.dot,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final Color color;
  final Color dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
                color: isActive ? dot : context.appColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive ? color : context.appColors.textMid,
                  fontWeight:
                      isActive ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.C, required this.ctrl});

  final AppColorsExtension C;
  final TextEditingController ctrl;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: ctrl,
      style: TextStyle(fontSize: 12, color: C.text),
      decoration: InputDecoration(
        hintText: 'Quest suchen…',
        hintStyle: TextStyle(fontSize: 12, color: C.textSoft),
        prefixIcon: Padding(
          padding: const EdgeInsets.all(10),
          child: Icon(Icons.search, size: 15, color: C.textSoft),
        ),
        filled: true,
        fillColor: C.bgHover,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(7),
          borderSide: BorderSide(color: C.accent),
        ),
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.C, required this.hasSearch});

  final AppColorsExtension C;
  final bool hasSearch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.assignment_outlined, size: 28, color: C.border),
          const SizedBox(height: 10),
          Text(
            hasSearch ? 'Keine Quests gefunden' : 'Keine Quests vorhanden',
            style: TextStyle(fontSize: 13, color: C.textSoft),
          ),
        ],
      ),
    );
  }
}

class _RewardTile extends StatelessWidget {
  const _RewardTile({required this.reward, required this.C});

  final QuestReward reward;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: [
          Icon(Icons.card_giftcard, size: 14, color: C.amber),
          const SizedBox(width: 8),
          Text(reward.name, style: TextStyle(fontSize: 13, color: C.text)),
          if (reward.description != null &&
              reward.description!.isNotEmpty) ...[
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                reward.description!,
                style: TextStyle(fontSize: 11, color: C.textSoft),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text, this.C);

  final String text;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: C.textSoft,
        letterSpacing: 0.4,
      ),
    );
  }
}

class _MetaEntry {
  const _MetaEntry({required this.label, required this.value});

  final String label;
  final String value;
}

class _MetaTile extends StatelessWidget {
  const _MetaTile({required this.entry, required this.C});

  final _MetaEntry entry;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(entry.label,
              style: TextStyle(
                  fontSize: 10,
                  color: C.textSoft,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          Text(entry.value,
              style: TextStyle(
                  fontSize: 12,
                  color: C.text,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn(
      {required this.icon, required this.color, required this.onTap});

  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child:
          SizedBox(width: 30, height: 30, child: Icon(icon, size: 18, color: color)),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: color, borderRadius: BorderRadius.circular(7)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: textColor),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: textColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _EditBtn extends StatelessWidget {
  const _EditBtn({required this.C, required this.onTap});

  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: C.bgHover,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(Icons.edit_outlined, size: 14, color: C.textMid),
      ),
    );
  }
}

class _DeleteBtn extends StatelessWidget {
  const _DeleteBtn({required this.C, required this.onTap});

  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: C.red.withValues(alpha: 0.08),
          border: Border.all(color: C.red.withValues(alpha: 0.25)),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(Icons.delete_outline, size: 14, color: C.red),
      ),
    );
  }
}
