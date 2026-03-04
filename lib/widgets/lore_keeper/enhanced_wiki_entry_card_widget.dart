import 'package:flutter/material.dart';
import '../../models/wiki_entry.dart';
import '../../viewmodels/wiki_viewmodel.dart';
import '../../theme/dnd_theme.dart';

/// Enhanced Wiki Entry Card Widget mit Enhanced Design und ViewModel-Integration
class EnhancedWikiEntryCardWidget extends StatelessWidget {
  final WikiEntry entry;
  final WikiViewModel viewModel;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;

  const EnhancedWikiEntryCardWidget({
    super.key,
    required this.entry,
    required this.viewModel,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: DnDTheme.xs, vertical: DnDTheme.xs),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DnDTheme.dungeonBlack.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(DnDTheme.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: DnDTheme.sm),
              _buildTitle(context),
              const SizedBox(height: DnDTheme.xs),
              _buildContentPreview(),
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: DnDTheme.sm),
                _buildTags(),
              ],
              const SizedBox(height: DnDTheme.sm),
              _buildMetadata(context),
              const SizedBox(height: DnDTheme.xs),
              _buildActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DnDTheme.sm),
          decoration: BoxDecoration(
            color: _getTypeColor().withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            border: Border.all(
              color: _getTypeColor().withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            _getTypeIcon(),
            color: _getTypeColor(),
            size: 24,
          ),
        ),
        const SizedBox(width: DnDTheme.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTypeDisplayName(),
                style: DnDTheme.bodyText2.copyWith(
                  fontWeight: FontWeight.w600,
                  color: _getTypeColor(),
                ),
              ),
              Row(
                children: [
                  if (entry.location != null) ...[
                    Icon(
                      Icons.location_on,
                      color: DnDTheme.arcaneBlue,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Standort (${entry.location!.latitude.toStringAsFixed(2)}, ${entry.location!.longitude.toStringAsFixed(2)})',
                      style: DnDTheme.caption.copyWith(
                        color: Colors.white70,
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (entry.campaignId == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DnDTheme.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DnDTheme.arcaneBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                        border: Border.all(
                          color: DnDTheme.arcaneBlue.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'Global',
                        style: DnDTheme.caption.copyWith(
                          color: DnDTheme.arcaneBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        _buildFavoriteButton(context),
      ],
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return IconButton(
      onPressed: onToggleFavorite,
      icon: Icon(
        entry.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: entry.isFavorite ? DnDTheme.warningOrange : Colors.white70,
        size: 20,
      ),
      tooltip: entry.isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      entry.title,
      style: DnDTheme.bodyText1.copyWith(
        fontWeight: FontWeight.bold,
        color: Colors.white,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildContentPreview() {
    final content = entry.isMarkdown 
        ? _stripMarkdown(entry.content)
        : entry.content;
    
    return Text(
      content.length > 150 ? '${content.substring(0, 150)}...' : content,
      style: DnDTheme.bodyText2.copyWith(
        height: 1.4,
        color: Colors.white70,
      ),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }

  String _stripMarkdown(String markdown) {
    // Einfache Markdown-Reinigung für Preview
    return markdown
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1') // Bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'\1')     // Italic
        .replaceAll(RegExp(r'_(.*?)_'), r'\1')         // Italic
        .replaceAll(RegExp(r'`(.*?)`'), r'\1')         // Code
        .replaceAll(RegExp(r'#{1,6}\s*'), '')        // Headers
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'\1') // Links
        .replaceAll(RegExp(r'\n'), ' ')                // Newlines
        .trim();
  }

  Widget _buildTags() {
    return Wrap(
      spacing: DnDTheme.xs,
      runSpacing: DnDTheme.xs,
      children: entry.tags.take(4).map((tag) => _buildTagChip(tag)).toList(),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DnDTheme.sm,
        vertical: DnDTheme.xs,
      ),
      decoration: BoxDecoration(
        color: DnDTheme.ancientGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.ancientGold.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        tag,
        style: DnDTheme.caption.copyWith(
          color: DnDTheme.ancientGold,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: Colors.white70,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(entry.updatedAt),
          style: DnDTheme.caption.copyWith(
            color: Colors.white70,
          ),
        ),
        if (entry.childIds.isNotEmpty) ...[
          const SizedBox(width: DnDTheme.sm),
          Icon(
            Icons.link,
            size: 14,
            color: Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            '${entry.childIds.length} Verknüpfungen',
            style: DnDTheme.caption.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
        if (entry.isMarkdown) ...[
          const SizedBox(width: DnDTheme.sm),
          Icon(
            Icons.code,
            size: 14,
            color: Colors.white70,
          ),
          const SizedBox(width: 4),
          Text(
            'Markdown',
            style: DnDTheme.caption.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
        const Spacer(),
        _buildStatusChip(context),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    Color chipColor;
    String statusText;
    
    if (entry.isFavorite) {
      chipColor = DnDTheme.warningOrange;
      statusText = 'Favorit';
    } else if (entry.childIds.isNotEmpty) {
      chipColor = DnDTheme.arcaneBlue;
      statusText = 'Verknüpft';
    } else if (entry.location != null) {
      chipColor = DnDTheme.successGreen;
      statusText = 'Standort';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DnDTheme.xs,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        statusText,
        style: DnDTheme.caption.copyWith(
          color: chipColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (onEdit != null)
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Bearbeiten'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: DnDTheme.sm,
                vertical: DnDTheme.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: DnDTheme.arcaneBlue,
            ),
          ),
        if (onDelete != null) ...[
          const SizedBox(width: DnDTheme.xs),
          TextButton.icon(
            onPressed: () => _showDeleteConfirmation(context),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Löschen'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: DnDTheme.sm,
                vertical: DnDTheme.xs,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: DnDTheme.errorRed,
            ),
          ),
        ],
        const SizedBox(width: DnDTheme.xs),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16),
          iconSize: 16,
          onSelected: (value) {
            switch (value) {
              case 'duplicate':
                viewModel.duplicateEntry(entry);
                break;
              case 'toggle_global':
                // Toggle global/campaign status
                break;
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'duplicate',
              child: Row(
                children: [
                  Icon(Icons.copy, size: 16, color: DnDTheme.arcaneBlue),
                  const SizedBox(width: 8),
                  Text('Duplizieren', style: DnDTheme.bodyText2.copyWith(color: Colors.white)),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'toggle_global',
              child: Row(
                children: [
                  Icon(
                    entry.campaignId == null ? Icons.campaign : Icons.public,
                    size: 16,
                    color: DnDTheme.arcaneBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.campaignId == null ? 'Zu Campaign machen' : 'Global machen',
                    style: DnDTheme.bodyText2.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Löschen bestätigen',
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.errorRed,
          ),
        ),
        content: Text(
          'Möchtest du den Wiki-Eintrag "${entry.title}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (entry.entryType) {
      case WikiEntryType.Person:
        return Icons.person;
      case WikiEntryType.Place:
        return Icons.location_on;
      case WikiEntryType.Lore:
        return Icons.menu_book;
      case WikiEntryType.Faction:
        return Icons.groups;
      case WikiEntryType.Magic:
        return Icons.auto_fix_high;
      case WikiEntryType.History:
        return Icons.history;
      case WikiEntryType.Item:
        return Icons.inventory_2;
      case WikiEntryType.Quest:
        return Icons.task_alt;
      case WikiEntryType.Creature:
        return Icons.cruelty_free;
    }
  }

  Color _getTypeColor() {
    switch (entry.entryType) {
      case WikiEntryType.Person:
        return DnDTheme.arcaneBlue;
      case WikiEntryType.Place:
        return DnDTheme.successGreen;
      case WikiEntryType.Lore:
        return DnDTheme.mysticalPurple;
      case WikiEntryType.Faction:
        return DnDTheme.warningOrange;
      case WikiEntryType.Magic:
        return DnDTheme.infoBlue;
      case WikiEntryType.History:
        return DnDTheme.ancientGold;
      case WikiEntryType.Item:
        return DnDTheme.arcaneBlue;
      case WikiEntryType.Quest:
        return DnDTheme.mysticalPurple;
      case WikiEntryType.Creature:
        return DnDTheme.errorRed;
    }
  }

  String _getTypeDisplayName() {
    switch (entry.entryType) {
      case WikiEntryType.Person:
        return 'NPC';
      case WikiEntryType.Place:
        return 'Ort';
      case WikiEntryType.Lore:
        return 'Lore';
      case WikiEntryType.Faction:
        return 'Fraktion';
      case WikiEntryType.Magic:
        return 'Magie';
      case WikiEntryType.History:
        return 'Geschichte';
      case WikiEntryType.Item:
        return 'Gegenstand';
      case WikiEntryType.Quest:
        return 'Quest';
      case WikiEntryType.Creature:
        return 'Kreatur';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}.${date.month}.${date.year}';
    } else if (difference.inDays > 0) {
      return 'vor ${difference.inDays} ${difference.inDays == 1 ? 'Tag' : 'Tagen'}';
    } else if (difference.inHours > 0) {
      return 'vor ${difference.inHours} ${difference.inHours == 1 ? 'Stunde' : 'Stunden'}';
    } else {
      return 'vor ${difference.inMinutes} ${difference.inMinutes == 1 ? 'Minute' : 'Minuten'}';
    }
  }
}