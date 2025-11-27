import 'package:flutter/material.dart';
import '../../models/wiki_entry.dart';
import '../../viewmodels/wiki_viewmodel.dart';

/// Enhanced Wiki Entry Card Widget mit modernem Design und ViewModel-Integration
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
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context),
              const SizedBox(height: 12),
              _buildTitle(context),
              const SizedBox(height: 8),
              _buildContentPreview(),
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildTags(),
              ],
              const SizedBox(height: 16),
              _buildMetadata(context),
              const SizedBox(height: 12),
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
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTypeColor().withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getTypeIcon(),
            color: _getTypeColor(),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTypeDisplayName(),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _getTypeColor(),
                ),
              ),
              Row(
                children: [
                  if (entry.location != null) ...[
                    Icon(
                      Icons.location_on,
                      color: Colors.grey[600],
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Standort (${entry.location!.latitude.toStringAsFixed(2)}, ${entry.location!.longitude.toStringAsFixed(2)})',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (entry.campaignId == null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Global',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.blue[700],
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
        color: entry.isFavorite ? Colors.red : Colors.grey[600],
        size: 20,
      ),
      tooltip: entry.isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Text(
      entry.title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
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
      style: TextStyle(
        fontSize: 14,
        height: 1.4,
        color: Colors.grey[700],
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
      spacing: 6,
      runSpacing: 4,
      children: entry.tags.take(4).map((tag) => _buildTagChip(tag)).toList(),
    );
  }

  Widget _buildTagChip(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.3)),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 11,
          color: Colors.amber[700],
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
          color: Colors.grey[600],
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(entry.updatedAt),
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        if (entry.childIds.isNotEmpty) ...[
          const SizedBox(width: 12),
          Icon(
            Icons.link,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            '${entry.childIds.length} Verknüpfungen',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
        if (entry.isMarkdown) ...[
          const SizedBox(width: 12),
          Icon(
            Icons.code,
            size: 14,
            color: Colors.grey[600],
          ),
          const SizedBox(width: 4),
          Text(
            'Markdown',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
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
      chipColor = Colors.red;
      statusText = 'Favorit';
    } else if (entry.childIds.isNotEmpty) {
      chipColor = Colors.blue;
      statusText = 'Verknüpft';
    } else if (entry.location != null) {
      chipColor = Colors.green;
      statusText = 'Standort';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 10,
          color: chipColor.withOpacity(0.8),
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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        if (onDelete != null) ...[
          const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _showDeleteConfirmation(context),
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
            label: const Text('Löschen', style: TextStyle(color: Colors.red)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, size: 16),
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
            PopupMenuItem(
              value: 'toggle_global',
              child: Row(
                children: [
                  Icon(
                    entry.campaignId == null ? Icons.campaign : Icons.public,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(entry.campaignId == null ? 'Zu Campaign machen' : 'Global machen'),
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
        title: const Text('Löschen bestätigen'),
        content: Text(
          'Möchtest du den Wiki-Eintrag "${entry.title}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
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
        return Colors.blue;
      case WikiEntryType.Place:
        return Colors.green;
      case WikiEntryType.Lore:
        return Colors.purple;
      case WikiEntryType.Faction:
        return Colors.orange;
      case WikiEntryType.Magic:
        return Colors.pink;
      case WikiEntryType.History:
        return Colors.brown;
      case WikiEntryType.Item:
        return Colors.teal;
      case WikiEntryType.Quest:
        return Colors.indigo;
      case WikiEntryType.Creature:
        return Colors.red;
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
