import 'package:flutter/material.dart';
import '../../models/wiki_entry.dart';
import '../../viewmodels/wiki_viewmodel.dart';
import '../../theme/app_theme.dart';

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
    final C = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: C.accent.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: C.bg.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, C),
              const SizedBox(height: 8),
              _buildTitle(context, C),
              const SizedBox(height: 4),
              _buildContentPreview(C),
              if (entry.tags.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildTags(C),
              ],
              const SizedBox(height: 8),
              _buildMetadata(context, C),
              const SizedBox(height: 4),
              _buildActionButtons(context, C),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColorsExtension C) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTypeColor(C).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: _getTypeColor(C).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Icon(
            _getTypeIcon(),
            color: _getTypeColor(C),
            size: 24,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getTypeDisplayName(),
                style: TextStyle(
                  fontSize: 12,
                  color: C.textMid,
                  fontWeight: FontWeight.w600,
                ).copyWith(
                  color: _getTypeColor(C),
                ),
              ),
              Row(
                children: [
                  if (entry.location != null) ...[
                    Icon(
                      Icons.location_on,
                      color: C.accent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Standort (${entry.location!.latitude.toStringAsFixed(2)}, ${entry.location!.longitude.toStringAsFixed(2)})',
                      style: TextStyle(fontSize: 11, color: C.textSoft),
                    ),
                  ],
                  const Spacer(),
                  if (entry.campaignId == null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: C.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(
                          color: C.accent.withValues(alpha: 0.5),
                        ),
                      ),
                      child: Text(
                        'Global',
                        style: TextStyle(
                          fontSize: 11,
                          color: C.accent,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
        _buildFavoriteButton(context, C),
      ],
    );
  }

  Widget _buildFavoriteButton(BuildContext context, AppColorsExtension C) {
    return IconButton(
      onPressed: onToggleFavorite,
      icon: Icon(
        entry.isFavorite ? Icons.favorite : Icons.favorite_border,
        color: entry.isFavorite ? C.amber : Colors.white70,
        size: 20,
      ),
      tooltip: entry.isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
    );
  }

  Widget _buildTitle(BuildContext context, AppColorsExtension C) {
    return Text(
      entry.title,
      style: TextStyle(
        fontSize: 14,
        color: C.text,
        fontWeight: FontWeight.bold,
        height: 1.2,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildContentPreview(AppColorsExtension C) {
    final content = entry.isMarkdown
        ? _stripMarkdown(entry.content)
        : entry.content;

    return Text(
      content.length > 150 ? '${content.substring(0, 150)}...' : content,
      style: TextStyle(fontSize: 12, color: C.textMid, height: 1.4),
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

  Widget _buildTags(AppColorsExtension C) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: entry.tags.take(4).map((tag) => _buildTagChip(tag, C)).toList(),
    );
  }

  Widget _buildTagChip(String tag, AppColorsExtension C) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: C.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: C.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        tag,
        style: TextStyle(
          fontSize: 11,
          color: C.amber,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMetadata(BuildContext context, AppColorsExtension C) {
    return Row(
      children: [
        Icon(
          Icons.schedule,
          size: 14,
          color: C.textSoft,
        ),
        const SizedBox(width: 4),
        Text(
          _formatDate(entry.updatedAt),
          style: TextStyle(fontSize: 11, color: C.textSoft),
        ),
        if (entry.childIds.isNotEmpty) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.link,
            size: 14,
            color: C.textSoft,
          ),
          const SizedBox(width: 4),
          Text(
            '${entry.childIds.length} Verknüpfungen',
            style: TextStyle(fontSize: 11, color: C.textSoft),
          ),
        ],
        if (entry.isMarkdown) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.code,
            size: 14,
            color: C.textSoft,
          ),
          const SizedBox(width: 4),
          Text(
            'Markdown',
            style: TextStyle(fontSize: 11, color: C.textSoft),
          ),
        ],
        const Spacer(),
        _buildStatusChip(context, C),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context, AppColorsExtension C) {
    Color chipColor;
    String statusText;

    if (entry.isFavorite) {
      chipColor = C.amber;
      statusText = 'Favorit';
    } else if (entry.childIds.isNotEmpty) {
      chipColor = C.accent;
      statusText = 'Verknüpft';
    } else if (entry.location != null) {
      chipColor = C.green;
      statusText = 'Standort';
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: chipColor.withValues(alpha: 0.5),
        ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 11,
          color: chipColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, AppColorsExtension C) {
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
                horizontal: 8,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: C.accent,
            ),
          ),
        if (onDelete != null) ...[
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: () => _showDeleteConfirmation(context, C),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Löschen'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              foregroundColor: C.red,
            ),
          ),
        ],
        const SizedBox(width: 4),
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
          itemBuilder: (context) {
            final popC = context.appColors;
            return [
              PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 16, color: popC.accent),
                    const SizedBox(width: 8),
                    Text('Duplizieren', style: TextStyle(fontSize: 12, color: popC.text)),
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
                      color: popC.accent,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      entry.campaignId == null ? 'Zu Campaign machen' : 'Global machen',
                      style: TextStyle(fontSize: 12, color: popC.text),
                    ),
                  ],
                ),
              ),
            ];
          },
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, AppColorsExtension C) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          'Löschen bestätigen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.red),
        ),
        content: Text(
          'Möchtest du den Wiki-Eintrag "${entry.title}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(fontSize: 14, color: C.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(fontSize: 14, color: C.accent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.red,
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

  Color _getTypeColor(AppColorsExtension C) {
    switch (entry.entryType) {
      case WikiEntryType.Person:
        return C.accent;
      case WikiEntryType.Place:
        return C.green;
      case WikiEntryType.Lore:
        return C.accent;
      case WikiEntryType.Faction:
        return C.amber;
      case WikiEntryType.Magic:
        return C.accent;
      case WikiEntryType.History:
        return C.amber;
      case WikiEntryType.Item:
        return C.accent;
      case WikiEntryType.Quest:
        return C.accent;
      case WikiEntryType.Creature:
        return C.red;
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
