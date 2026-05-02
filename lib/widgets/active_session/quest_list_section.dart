import 'package:flutter/material.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/quest_model_repository.dart';
import '../../models/quest.dart';
import '../../theme/app_theme.dart';
import '../../theme/dnd_theme.dart';

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
      final updatedQuest = quest.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
        completedAt: newStatus == QuestStatus.completed ? DateTime.now() : null,
      );
      await _questRepository.update(updatedQuest);
      await _loadQuests();
      widget.onQuestUpdated?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${quest.title}" als ${_statusLabel(newStatus)} markiert',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: _statusColor(newStatus, context.appColors),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Aktualisieren: $e'),
            backgroundColor: context.appColors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Column(
      children: [
        _buildHeader(C),
        _buildFilterRow(C),
        Expanded(child: _buildContent(C)),
      ],
    );
  }

  Widget _buildHeader(AppColorsExtension C) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
      child: Row(
        children: [
          Icon(Icons.flag, size: 13, color: DnDTheme.mysticalPurple),
          const SizedBox(width: 6),
          Text(
            'Quests',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(AppColorsExtension C) {
    final counts = {
      null: _quests.length,
      QuestStatus.active: _quests.where((q) => q.status == QuestStatus.active).length,
      QuestStatus.abandoned: _quests.where((q) => q.status == QuestStatus.abandoned).length,
      QuestStatus.completed: _quests.where((q) => q.status == QuestStatus.completed).length,
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _filterChip(null, 'Alle', counts[null]!, C),
            const SizedBox(width: 4),
            _filterChip(QuestStatus.active, 'Aktiv', counts[QuestStatus.active]!, C),
            const SizedBox(width: 4),
            _filterChip(QuestStatus.abandoned, 'Aufgegeben', counts[QuestStatus.abandoned]!, C),
            const SizedBox(width: 4),
            _filterChip(QuestStatus.completed, 'Erledigt', counts[QuestStatus.completed]!, C),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(QuestStatus? status, String label, int count, AppColorsExtension C) {
    final isSelected = _selectedFilter == status;
    final color = status == null ? C.accent : _statusColor(status, C);
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = isSelected ? null : status),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(
            color: isSelected ? color : C.border,
          ),
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
                color: isSelected ? color.withValues(alpha: 0.8) : C.textSoft.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AppColorsExtension C) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: C.accent, strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: C.red, size: 24),
            const SizedBox(height: 8),
            Text('Fehler beim Laden', style: TextStyle(color: C.red, fontSize: 12)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _loadQuests,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: C.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: C.accent.withValues(alpha: 0.35)),
                ),
                child: Text('Erneut versuchen', style: TextStyle(fontSize: 11, color: C.accent)),
              ),
            ),
          ],
        ),
      );
    }
    final filtered = _filteredQuests;
    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 24, color: C.textSoft),
            const SizedBox(height: 6),
            Text(
              _selectedFilter == null ? 'Keine Quests' : 'Keine ${_statusLabel(_selectedFilter!)}en Quests',
              style: TextStyle(fontSize: 12, color: C.textSoft),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: filtered.length,
      itemBuilder: (context, index) => _buildQuestCard(filtered[index], C),
    );
  }

  Widget _buildQuestCard(Quest quest, AppColorsExtension C) {
    final statusColor = _statusColor(quest.status, C);
    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.all(10),
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
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: DnDTheme.mysticalPurple.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: DnDTheme.mysticalPurple.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _questTypeLabel(quest.questType),
                  style: const TextStyle(fontSize: 9, color: DnDTheme.mysticalPurple, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _statusButton(quest, QuestStatus.abandoned, 'Aufgegeben', C),
              const SizedBox(width: 5),
              _statusButton(quest, QuestStatus.active, 'Aktiv', C),
              const SizedBox(width: 5),
              _statusButton(quest, QuestStatus.completed, 'Erledigt', C),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusButton(Quest quest, QuestStatus status, String label, AppColorsExtension C) {
    final isSelected = quest.status == status;
    final color = _statusColor(status, C);
    return Expanded(
      child: GestureDetector(
        onTap: isSelected ? null : () => _updateQuestStatus(quest, status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(color: isSelected ? color : C.border),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected ? color : C.textSoft,
              fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(QuestStatus status, AppColorsExtension C) {
    switch (status) {
      case QuestStatus.active:    return C.green;
      case QuestStatus.completed: return C.green;
      case QuestStatus.abandoned: return C.amber;
      case QuestStatus.failed:    return C.red;
      case QuestStatus.onHold:    return C.accent;
    }
  }

  String _statusLabel(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:    return 'Aktiv';
      case QuestStatus.onHold:    return 'Pause';
      case QuestStatus.completed: return 'Erledigt';
      case QuestStatus.failed:    return 'Fehlgeschlagen';
      case QuestStatus.abandoned: return 'Aufgegeben';
    }
  }

  String _questTypeLabel(QuestType type) {
    switch (type) {
      case QuestType.main:     return 'Haupt';
      case QuestType.side:     return 'Neben';
      case QuestType.personal: return 'Pers';
      case QuestType.faction:  return 'Frakt';
    }
  }
}
