import 'package:flutter/material.dart';
import '../../models/quest.dart';
import '../../database/repositories/quest_model_repository.dart';
import '../../database/core/database_connection.dart';
import '../../theme/app_theme.dart';

class QuestListSection extends StatefulWidget {
  final String campaignId;
  final QuestModelRepository? questRepository;
  final VoidCallback? onQuestUpdated;

  const QuestListSection({
    super.key,
    required this.campaignId,
    this.questRepository,
    this.onQuestUpdated,
  });

  @override
  State<QuestListSection> createState() => _QuestListSectionState();
}

class _QuestListSectionState extends State<QuestListSection> {
  List<Quest> _quests = [];
  bool _isLoading = true;
  String? _error;
  QuestStatus? _selectedFilter;
  late QuestModelRepository _questRepository;

  @override
  void initState() {
    super.initState();
    _questRepository = widget.questRepository ??
        QuestModelRepository(DatabaseConnection.instance);
    _loadQuests();
  }

  Future<void> _loadQuests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final quests = await _questRepository.findByCampaign(widget.campaignId);
      quests.sort((a, b) {
        if (a.status == QuestStatus.active && b.status != QuestStatus.active) return -1;
        if (a.status != QuestStatus.active && b.status == QuestStatus.active) return 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
      setState(() {
        _quests = quests;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<Quest> get _filteredQuests {
    if (_selectedFilter == null) return _quests;
    return _quests.where((q) => q.status == _selectedFilter).toList();
  }

  Future<void> _updateQuestStatus(Quest quest, QuestStatus newStatus) async {
    try {
      final updated = quest.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
        completedAt: newStatus == QuestStatus.completed ? DateTime.now() : null,
      );
      await _questRepository.update(updated);
      await _loadQuests();
      widget.onQuestUpdated?.call();
      if (mounted) {
        final label = _statusLabel(newStatus);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('"${quest.title}" als $label markiert',
              style: const TextStyle(fontSize: 12)),
          backgroundColor: _statusColor(newStatus, context.appColors),
          duration: const Duration(seconds: 2),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fehler: $e', style: const TextStyle(fontSize: 12)),
          backgroundColor: context.appColors.red,
          duration: const Duration(seconds: 2),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFilterRow(C),
        Flexible(child: _buildContent(C)),
      ],
    );
  }

  Widget _buildFilterRow(AppColorsExtension C) {
    final filters = <(QuestStatus?, String)>[
      (null, 'Alle'),
      (QuestStatus.active, 'Aktiv'),
      (QuestStatus.abandoned, 'Aufgegeben'),
      (QuestStatus.completed, 'Erledigt'),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      child: Row(
        children: filters.map((f) {
          final (status, label) = f;
          final count = status == null
              ? _quests.length
              : _quests.where((q) => q.status == status).length;
          final isSelected = _selectedFilter == status;
          final color = _filterColor(status, C);

          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: GestureDetector(
              onTap: () => setState(() => _selectedFilter = status),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: isSelected ? color : C.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? color : C.textSoft,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$count',
                      style: TextStyle(
                        fontSize: 10,
                        color: isSelected ? color.withValues(alpha: 0.7) : C.textSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent(AppColorsExtension C) {
    if (_isLoading) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: C.textSoft),
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text('Fehler beim Laden', style: TextStyle(color: C.red, fontSize: 12)),
      );
    }
    final filtered = _filteredQuests;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, color: C.textSoft, size: 24),
            const SizedBox(height: 6),
            Text('Keine Quests', style: TextStyle(color: C.textSoft, fontSize: 12)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildQuestCard(context, filtered[index]),
    );
  }

  Widget _buildQuestCard(BuildContext context, Quest quest) {
    final C = context.appColors;
    final statusColor = _statusColor(quest.status, C);
    const purple = Color(0xFF7C3AED);

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: C.bgHover,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  quest.title,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: C.text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: purple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _questTypeLabel(quest.questType),
                  style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: purple),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusButton(context, quest, QuestStatus.abandoned, 'Aufgegeben', C),
              const SizedBox(width: 5),
              _statusButton(context, quest, QuestStatus.active, 'Aktiv', C),
              const SizedBox(width: 5),
              _statusButton(context, quest, QuestStatus.completed, 'Erledigt', C),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusButton(
    BuildContext context,
    Quest quest,
    QuestStatus status,
    String label,
    AppColorsExtension C,
  ) {
    final isActive = quest.status == status;
    final color = _statusColor(status, C);

    return Expanded(
      child: GestureDetector(
        onTap: isActive ? null : () => _updateQuestStatus(quest, status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: isActive ? color : C.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isActive ? color : C.textSoft,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Color _statusColor(QuestStatus status, AppColorsExtension C) => switch (status) {
        QuestStatus.active => C.green,
        QuestStatus.completed => C.textMid,
        QuestStatus.failed => C.red,
        QuestStatus.abandoned => C.amber,
        QuestStatus.onHold => C.textMid,
      };

  Color _filterColor(QuestStatus? status, AppColorsExtension C) {
    if (status == null) return C.accent;
    return _statusColor(status, C);
  }

  String _statusLabel(QuestStatus status) => switch (status) {
        QuestStatus.active => 'Aktiv',
        QuestStatus.completed => 'Erledigt',
        QuestStatus.failed => 'Fehlgeschlagen',
        QuestStatus.abandoned => 'Aufgegeben',
        QuestStatus.onHold => 'Pausiert',
      };

  String _questTypeLabel(QuestType type) => switch (type) {
        QuestType.main => 'Haupt',
        QuestType.side => 'Neben',
        QuestType.personal => 'Pers',
        QuestType.faction => 'Frakt',
      };
}
