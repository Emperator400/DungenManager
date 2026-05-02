import 'package:flutter/material.dart';
import '../../models/quest.dart';
import '../../services/quest_helper_service.dart';
import '../../theme/app_theme.dart';

/// Modernisiertes QuestCardWidget mit ViewModel-Integration
/// 
/// Dieses Widget verwendet Helper-Methoden anstelle von direkter Business-Logik
/// und ist optimiert für das neue QuestLibraryViewModel Pattern.
class EnhancedQuestCardWidget extends StatelessWidget {
  final Quest quest;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final Widget? customTrailing;
  final bool showActions;
  final bool isSelected;

  const EnhancedQuestCardWidget({
    super.key,
    required this.quest,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
    this.customTrailing,
    this.showActions = true,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: isSelected ? 8 : 2,
      color: isSelected ? C.amber.withValues(alpha: 0.1) : null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Titel und Aktionen
              _buildHeader(context),
              const SizedBox(height: 8),

              // Beschreibung
              _buildDescription(context),
              const SizedBox(height: 8),

              // Meta-Informationen Row
              _buildMetaInfoRow(context),

              // Tags Row
              if (QuestHelperService.getHasTags(quest)) ...[
                const SizedBox(height: 8),
                _buildTagsRow(context),
              ],

              // Belohnungen und NPCs (wenn vorhanden)
              if (QuestHelperService.getHasRewards(quest) || QuestHelperService.getHasNpcs(quest)) ...[
                const SizedBox(height: 8),
                _buildRewardsAndNpcsRow(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Baut den Header mit Titel und Aktionen
  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Quest-Icon basierend auf Typ
        _buildQuestTypeIcon(context),
        const SizedBox(width: 12),

        // Titel und Typ
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                quest.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                QuestHelperService.getQuestTypeDisplayName(quest),
                style: TextStyle(
                  fontSize: 12,
                  color: context.appColors.textMid,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // Custom trailing (für Checkbox etc.)
        if (customTrailing != null)
          customTrailing!
        else ...[
          // Favoriten-Button
          if (onToggleFavorite != null && showActions)
            IconButton(
              icon: Icon(
                quest.isFavorite ? Icons.star : Icons.star_border,
                color: quest.isFavorite ? context.appColors.amber : context.appColors.textMid,
              ),
              onPressed: onToggleFavorite,
              tooltip: quest.isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
            ),

          // More-Options-Button
          if ((onEdit != null || onDelete != null) && showActions)
            _buildMoreOptionsButton(),
        ],
      ],
    );
  }

  /// Baut das Quest-Typ Icon
  Widget _buildQuestTypeIcon(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: _getQuestTypeColor(context).withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        _getQuestTypeIcon(),
        color: _getQuestTypeColor(context),
        size: 20,
      ),
    );
  }

  /// Baut die Beschreibung
  Widget _buildDescription(BuildContext context) {
    return Text(
      quest.description,
      style: TextStyle(
        fontSize: 14,
        color: context.appColors.textMid,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  /// Baut die Meta-Informationen Row
  Widget _buildMetaInfoRow(BuildContext context) {
    final C = context.appColors;
    return Row(
      children: [
        // Schwierigkeitsgrad
        _buildInfoChip(
          icon: Icons.bolt,
          label: QuestHelperService.getDifficultyDisplayName(quest),
          color: _getDifficultyColor(context),
        ),

        const SizedBox(width: 8),

        // Level-Empfehlung
        if (quest.recommendedLevel != null)
          _buildInfoChip(
            icon: Icons.signal_cellular_alt,
            label: 'Level ${quest.recommendedLevel}',
            color: C.accent,
          ),

        const SizedBox(width: 8),

        // Geschätzte Dauer
        if (quest.estimatedDurationHours != null)
          _buildInfoChip(
            icon: Icons.schedule,
            label: '${quest.estimatedDurationHours}h',
            color: C.amber,
          ),

        const Spacer(),

        // Location
        if (quest.location != null && quest.location!.isNotEmpty)
          _buildInfoChip(
            icon: Icons.location_on,
            label: quest.location!,
            color: C.green,
          ),
      ],
    );
  }

  /// Baut die Tags Row
  Widget _buildTagsRow(BuildContext context) {
    final C = context.appColors;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: quest.tags.take(3).map((tag) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: C.amber.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: C.amber.withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            tag,
            style: TextStyle(
              fontSize: 10,
              color: C.amber,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Baut die Belohnungen und NPCs Row
  Widget _buildRewardsAndNpcsRow(BuildContext context) {
    final C = context.appColors;
    return Row(
      children: [
        if (QuestHelperService.getHasRewards(quest)) ...[
          Icon(Icons.card_giftcard, size: 14, color: C.amber),
          const SizedBox(width: 4),
          Text(
            '${quest.rewards.length} Belohnungen',
            style: TextStyle(
              fontSize: 11,
              color: C.amber,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],

        if (QuestHelperService.getHasRewards(quest) && QuestHelperService.getHasNpcs(quest))
          const SizedBox(width: 12),

        if (QuestHelperService.getHasNpcs(quest)) ...[
          Icon(Icons.people, size: 14, color: C.accent),
          const SizedBox(width: 4),
          Text(
            '${quest.involvedNpcs.length} NPCs',
            style: TextStyle(
              fontSize: 11,
              color: C.accent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  /// Baut das More Options Button
  Widget _buildMoreOptionsButton() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (context) => [
        if (onEdit != null)
          const PopupMenuItem(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 18),
                SizedBox(width: 8),
                Text('Bearbeiten'),
              ],
            ),
          ),
        if (onDelete != null)
          PopupMenuItem(
            value: 'delete',
            child: Builder(
              builder: (context) => Row(
                children: [
                  Icon(Icons.delete, color: context.appColors.red, size: 18),
                  const SizedBox(width: 8),
                  Text('Löschen', style: TextStyle(color: context.appColors.red)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Baut eine Info-Chip
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// Gibt die Farbe für den Quest-Typ zurück
  Color _getQuestTypeColor(BuildContext context) {
    final C = context.appColors;
    switch (quest.questType) {
      case QuestType.main:
        return C.red;
      case QuestType.side:
        return C.accent;
      case QuestType.personal:
        return C.accent;
      case QuestType.faction:
        return C.green;
    }
  }

  /// Gibt das Icon für den Quest-Typ zurück
  IconData _getQuestTypeIcon() {
    switch (quest.questType) {
      case QuestType.main:
        return Icons.flag;
      case QuestType.side:
        return Icons.explore;
      case QuestType.personal:
        return Icons.person;
      case QuestType.faction:
        return Icons.group;
    }
  }

  /// Gibt die Farbe für die Schwierigkeit zurück
  Color _getDifficultyColor(BuildContext context) {
    final C = context.appColors;
    switch (quest.difficulty) {
      case QuestDifficulty.easy:
        return C.green;
      case QuestDifficulty.medium:
        return C.amber;
      case QuestDifficulty.hard:
        return C.amber;
      case QuestDifficulty.deadly:
        return C.red;
      case QuestDifficulty.epic:
        return C.accent;
      case QuestDifficulty.legendary:
        return C.amber;
    }
  }
}
