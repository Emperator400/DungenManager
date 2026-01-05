import 'package:flutter/material.dart';
import '../../../models/quest.dart';
import '../base/unified_card_base.dart';
import '../base/card_header_widget.dart';
import '../base/card_content_widget.dart';
import '../base/card_actions_widget.dart';
import '../base/card_metadata_widget.dart';
import '../shared/unified_card_theme.dart';

/// Unified Quest Card
/// 
/// Beispielimplementierung für Quests unter Verwendung des neuen Card-Systems
class UnifiedQuestCard extends UnifiedCardBase {
  final Quest quest;

  const UnifiedQuestCard({
    super.key,
    required this.quest,
    super.onTap,
    super.onEdit,
    super.onDelete,
    super.onToggleFavorite,
    super.isSelected,
    super.showActions,
    super.isFavorite,
  });

  @override
  bool get isFavorite => quest.isFavorite;

  @override
  Widget buildCardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UnifiedCardBase.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          CardHeaderWidget(
            title: quest.title,
            subtitle: _buildSubtitle(),
            leadingIcon: _getQuestTypeIcon(),
            iconColor: UnifiedCardTheme.getIconColor('quest'),
            iconBackgroundColor: UnifiedCardTheme.getIconBackgroundColor('quest'),
            additionalInfo: [
              if (quest.hasLevelRecommendation)
                _buildInfoChip(
                  Icons.format_list_numbered,
                  'Level ${quest.recommendedLevel}',
                ),
              if (quest.hasDurationEstimate)
                _buildInfoChip(
                  Icons.schedule,
                  '${quest.estimatedDurationHours?.toStringAsFixed(1)}h',
                ),
            ],
            onFavoriteToggle: onToggleFavorite,
            isFavorite: isFavorite,
            popupMenuItems: _buildPopupMenuItems(context),
            onPopupMenuItemSelected: (value) => _handlePopupMenuAction(context, value),
          ),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Content
          if (quest.description.isNotEmpty)
            CardContentWidget(
              description: quest.description,
              descriptionMaxLines: 3,
              tags: quest.hasTags ? quest.tags : null,
            ),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Rewards Info
          if (quest.hasRewards) _buildRewardsInfo(),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Metadata
          CardMetadataWidget(
            createdAt: quest.createdAt,
            updatedAt: quest.updatedAt,
            status: _getStatusDescription(),
            priority: _getDifficultyDescription(),
            itemCount: quest.rewards.length,
            customMetadata: {
              if (quest.hasLocation) 'Ort': quest.location!,
              if (quest.hasNpcs) 'NPCs': quest.npcsString,
            },
          ),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Actions
          CardActionsWidget(
            onEdit: onEdit,
            onDelete: onDelete,
            onQuickAction: () => _showQuickActions(context),
            alignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final type = quest.questTypeDescription;
    final difficulty = quest.difficultyDescription;
    return '$type • $difficulty';
  }

  IconData _getQuestTypeIcon() {
    switch (quest.questType) {
      case QuestType.main:
        return Icons.star;
      case QuestType.side:
        return Icons.verified;
      case QuestType.personal:
        return Icons.person;
      case QuestType.faction:
        return Icons.groups;
    }
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildRewardsInfo() {
    final hasGold = quest.totalGoldAmount > 0;
    final hasXP = quest.totalXP > 0;
    
    if (!hasGold && !hasXP) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber[100]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber[300]!.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasGold) ...[
            Icon(Icons.monetization_on, size: 16, color: Colors.amber[700]),
            const SizedBox(width: 4),
            Text(
              '${quest.totalGoldAmount} Gold',
              style: TextStyle(
                fontSize: 12,
                color: Colors.amber[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hasXP) const SizedBox(width: 12),
          ],
          if (hasXP) ...[
            Icon(Icons.auto_graph, size: 16, color: Colors.blue[700]),
            const SizedBox(width: 4),
            Text(
              '${quest.totalXP} EP',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[800],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getStatusDescription() {
    switch (quest.status) {
      case QuestStatus.active:
        return 'Aktiv';
      case QuestStatus.completed:
        return 'Abgeschlossen';
      case QuestStatus.failed:
        return 'Fehlgeschlagen';
      case QuestStatus.abandoned:
        return 'Abgebrochen';
      case QuestStatus.onHold:
        return 'Pausiert';
    }
  }

  String _getDifficultyDescription() {
    return quest.difficultyDescription;
  }

  List<PopupMenuItem<String>> _buildPopupMenuItems(BuildContext context) {
    return [
      const PopupMenuItem(
        value: 'duplicate',
        child: Row(
          children: [
            Icon(Icons.copy, size: 16),
            SizedBox(width: 8),
            Text('Duplizieren'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'move',
        child: Row(
          children: [
            Icon(Icons.move_to_inbox, size: 16),
            SizedBox(width: 8),
            Text('Verschieben'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'archive',
        child: Row(
          children: [
            Icon(Icons.archive, size: 16),
            SizedBox(width: 8),
            Text('Archivieren'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'share',
        child: Row(
          children: [
            Icon(Icons.share, size: 16),
            SizedBox(width: 8),
            Text('Teilen'),
          ],
        ),
      ),
    ];
  }

  void _handlePopupMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quest duplizieren...')),
        );
        break;
      case 'move':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quest verschieben...')),
        );
        break;
      case 'archive':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quest archivieren...')),
        );
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Quest teilen...')),
        );
        break;
    }
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (quest.status == QuestStatus.active)
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: const Text('Als abgeschlossen markieren'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quest als abgeschlossen markieren...')),
                  );
                },
              ),
            if (quest.status == QuestStatus.active)
              ListTile(
                leading: const Icon(Icons.pause_circle),
                title: const Text('Auf Pausieren setzen'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Quest pausieren...')),
                  );
                },
              ),
            if (quest.hasLocation)
              ListTile(
                leading: const Icon(Icons.map),
                title: const Text('Auf Karte anzeigen'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Auf Karte anzeigen...')),
                  );
                },
              ),
            if (quest.hasWikiLinks)
              ListTile(
                leading: const Icon(Icons.link),
                title: const Text('Verknüpfte Wiki-Einträge'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Verknüpfte Wiki-Einträge anzeigen...')),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.add_circle),
              title: const Text('Belohnung hinzufügen'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Belohnung hinzufügen...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.note_add),
              title: const Text('Notiz hinzufügen'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Notiz hinzufügen...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
