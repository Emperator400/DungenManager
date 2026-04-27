import 'package:flutter/material.dart';
import '../../models/quest.dart';
import '../../theme/dnd_theme.dart';
import '../../database/repositories/quest_model_repository.dart';
import '../../database/core/database_connection.dart';

/// Quest-Liste für die aktive Session
/// 
/// Zeigt alle Quests der Kampagne in einer scrollbaren Liste an.
/// Ermöglicht schnelle Status-Änderungen direkt aus der Liste.
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
      
      // Sortiere: Aktive zuerst, dann nach UpdatedAt
      quests.sort((a, b) {
        // Aktive Quests zuerst
        if (a.status == QuestStatus.active && b.status != QuestStatus.active) {
          return -1;
        }
        if (a.status != QuestStatus.active && b.status == QuestStatus.active) {
          return 1;
        }
        // Dann nach Update-Zeit
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
    if (_selectedFilter == null) {
      return _quests;
    }
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
      
      // Callback aufrufen um Parent-Widget zu benachrichtigen
      widget.onQuestUpdated?.call();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  _getQuestStatusIcon(newStatus),
                  color: Colors.white,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '"${quest.title}" als ${_getQuestStatusText(newStatus)} markiert',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: _getQuestStatusColor(newStatus),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Aktualisieren: $e'),
            backgroundColor: DnDTheme.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          // Filter Chips
          _buildFilterChips(),
          // Content
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final activeCount = _quests.where((q) => q.status == QuestStatus.active).length;
    final completedCount = _quests.where((q) => q.status == QuestStatus.completed).length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DnDTheme.mysticalPurple.withValues(alpha: 0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DnDTheme.radiusMedium),
          topRight: Radius.circular(DnDTheme.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: DnDTheme.mysticalPurple, size: 24),
          const SizedBox(width: 10),
          Text(
            'Quests',
            style: DnDTheme.headline3.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          _buildStatusBadge('Aktiv', activeCount, DnDTheme.ancientGold),
          const SizedBox(width: 8),
          _buildStatusBadge('Erledigt', completedCount, DnDTheme.successGreen),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: DnDTheme.bodyText2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(null, 'Alle', _quests.length),
            const SizedBox(width: 8),
            _buildFilterChip(QuestStatus.active, 'Aktiv', 
                _quests.where((q) => q.status == QuestStatus.active).length),
            const SizedBox(width: 8),
            _buildFilterChip(QuestStatus.completed, 'Abgeschlossen',
                _quests.where((q) => q.status == QuestStatus.completed).length),
            const SizedBox(width: 8),
            _buildFilterChip(QuestStatus.abandoned, 'Aufgegeben',
                _quests.where((q) => q.status == QuestStatus.abandoned).length),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(QuestStatus? status, String label, int count) {
    final isSelected = _selectedFilter == status;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = isSelected ? null : status;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? DnDTheme.mysticalPurple.withValues(alpha: 0.5)
              : DnDTheme.slateGrey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected 
                ? DnDTheme.mysticalPurple 
                : Colors.white24,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: DnDTheme.bodyText1.copyWith(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              '($count)',
              style: DnDTheme.bodyText1.copyWith(
                color: isSelected ? DnDTheme.ancientGold : Colors.white54,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: DnDTheme.mysticalPurple,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: DnDTheme.errorRed, size: 32),
            const SizedBox(height: 8),
            Text(
              'Fehler beim Laden',
              style: DnDTheme.bodyText2.copyWith(color: DnDTheme.errorRed),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _loadQuests,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.arcaneBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    final filteredQuests = _filteredQuests;

    if (filteredQuests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 32,
              color: Colors.white38,
            ),
            const SizedBox(height: 8),
            Text(
              _selectedFilter == null 
                  ? 'Keine Quests vorhanden'
                  : 'Keine ${_getQuestStatusText(_selectedFilter!)}en Quests',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredQuests.length,
      itemBuilder: (context, index) {
        final quest = filteredQuests[index];
        return _buildQuestCard(quest);
      },
    );
  }

  Widget _buildQuestCard(Quest quest) {
    final statusColor = _getQuestStatusColor(quest.status);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey.withValues(alpha: 0.6),
          endColor: DnDTheme.stoneGrey.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Theme(
        data: ThemeData(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          childrenPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          leading: Container(
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
              border: Border.all(color: statusColor.withValues(alpha: 0.5), width: 2),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  quest.title,
                  style: DnDTheme.bodyText1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Quest Type Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getQuestTypeColor(quest.questType).withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  _getQuestTypeShort(quest.questType),
                  style: DnDTheme.bodyText2.copyWith(
                    color: _getQuestTypeColor(quest.questType),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          trailing: _buildQuickStatusButton(quest),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          children: [
            // Beschreibung
            if (quest.description.isNotEmpty) ...[
              Text(
                quest.description,
                style: DnDTheme.bodyText1.copyWith(
                  color: Colors.white70,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
            ],
            // Details Row
            Row(
              children: [
                if (quest.location != null && quest.location!.isNotEmpty) ...[
                  Icon(Icons.location_on, color: Colors.white54, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    quest.location!,
                    style: DnDTheme.bodyText1.copyWith(
                      color: Colors.white54,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                if (quest.recommendedLevel != null) ...[
                  Icon(Icons.star, color: DnDTheme.ancientGold, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    'Lvl ${quest.recommendedLevel}',
                    style: DnDTheme.bodyText1.copyWith(
                      color: DnDTheme.ancientGold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            // Status Actions
            Row(
              children: [
                _buildStatusActionButton(
                  quest: quest,
                  status: QuestStatus.abandoned,
                  icon: Icons.remove_circle_outline,
                  label: 'Aufgegeben',
                ),
                const SizedBox(width: 6),
                _buildStatusActionButton(
                  quest: quest,
                  status: QuestStatus.active,
                  icon: Icons.play_circle_outline,
                  label: 'Aktiv',
                ),
                const SizedBox(width: 6),
                _buildStatusActionButton(
                  quest: quest,
                  status: QuestStatus.completed,
                  icon: Icons.check_circle_outline,
                  label: 'Erledigt',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatusButton(Quest quest) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: _getQuestStatusColor(quest.status).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: _getQuestStatusColor(quest.status).withValues(alpha: 0.4),
          width: 2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getQuestStatusIcon(quest.status),
            color: _getQuestStatusColor(quest.status),
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            _getQuestStatusText(quest.status),
            style: DnDTheme.bodyText1.copyWith(
              color: _getQuestStatusColor(quest.status),
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusActionButton({
    required Quest quest,
    required QuestStatus status,
    required IconData icon,
    required String label,
  }) {
    final isSelected = quest.status == status;
    final color = _getQuestStatusColor(status);

    return Expanded(
      child: GestureDetector(
        onTap: isSelected ? null : () => _updateQuestStatus(quest, status),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected 
                ? color.withValues(alpha: 0.4)
                : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : color.withValues(alpha: 0.7),
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: DnDTheme.bodyText1.copyWith(
                  color: isSelected ? color : Colors.white70,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ========== HELPER METHODS ==========

  Color _getQuestStatusColor(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return DnDTheme.ancientGold;
      case QuestStatus.onHold:
        return DnDTheme.arcaneBlue;
      case QuestStatus.completed:
        return DnDTheme.successGreen;
      case QuestStatus.failed:
        return DnDTheme.errorRed;
      case QuestStatus.abandoned:
        return Colors.orange;
    }
  }

  IconData _getQuestStatusIcon(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return Icons.flag;
      case QuestStatus.onHold:
        return Icons.pause;
      case QuestStatus.completed:
        return Icons.check_circle;
      case QuestStatus.failed:
        return Icons.cancel;
      case QuestStatus.abandoned:
        return Icons.remove_circle;
    }
  }

  String _getQuestStatusText(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return 'Aktiv';
      case QuestStatus.onHold:
        return 'Pause';
      case QuestStatus.completed:
        return 'Erledigt';
      case QuestStatus.failed:
        return 'Fehlgeschlagen';
      case QuestStatus.abandoned:
        return 'Aufgegeben';
    }
  }

  Color _getQuestTypeColor(QuestType type) {
    switch (type) {
      case QuestType.main:
        return DnDTheme.ancientGold;
      case QuestType.side:
        return DnDTheme.arcaneBlue;
      case QuestType.personal:
        return DnDTheme.mysticalPurple;
      case QuestType.faction:
        return DnDTheme.successGreen;
    }
  }

  String _getQuestTypeShort(QuestType type) {
    switch (type) {
      case QuestType.main:
        return 'Haupt';
      case QuestType.side:
        return 'Neben';
      case QuestType.personal:
        return 'Pers';
      case QuestType.faction:
        return 'Frakt';
    }
  }
}