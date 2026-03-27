import 'package:flutter/material.dart';
import '../../../models/wiki_entry.dart';
import '../../../theme/dnd_theme.dart';
import '../base/unified_card_base.dart';
import '../base/card_header_widget.dart';
import '../base/card_content_widget.dart';
import '../base/card_actions_widget.dart';
import '../base/card_metadata_widget.dart';
import '../chips/unified_info_chip.dart';

/// Unified Wiki Entry Card für den Lore Keeper
/// 
/// Erbt von UnifiedCardBase und nutzt die einheitlichen Chip-Komponenten
class UnifiedWikiEntryCard extends UnifiedCardBase {
  final WikiEntry entry;
  final VoidCallback? onTap;

  const UnifiedWikiEntryCard({
    super.key,
    required this.entry,
    super.onEdit,
    super.onDelete,
    super.onToggleFavorite,
    this.onTap,
    super.isFavorite,
    super.isSelected,
    super.showActions,
    super.elevation,
    super.margin,
    super.borderRadius,
  });

  @override
  bool get isFavorite => entry.isFavorite;

  @override
  Color getAccentColor(BuildContext context) {
    return _getTypeColor();
  }

  /// Gibt die Farbe basierend auf dem Entry-Typ zurück
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

  /// Gibt das Icon basierend auf dem Entry-Typ zurück
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

  /// Gibt den Anzeigenamen für den Entry-Typ zurück
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

  @override
  Widget buildCardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UnifiedCardBase.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header mit Typ und Titel
          CardHeaderWidget(
            title: entry.title,
            subtitle: _buildSubtitle(),
            leadingIcon: _getTypeIcon(),
            iconColor: _getTypeColor(),
            iconBackgroundColor: _getTypeColor().withOpacity(0.2),
            additionalInfo: _buildTypeChips(),
            onFavoriteToggle: onToggleFavorite,
            isFavorite: isFavorite,
            popupMenuItems: _buildPopupMenuItems(context),
            onPopupMenuItemSelected: (value) => _handlePopupMenuAction(context, value),
          ),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Content Preview
          _buildContentPreview(),
          
          // Tags
          if (entry.tags.isNotEmpty) ...[
            const SizedBox(height: UnifiedCardBase.defaultSpacing),
            _buildTags(),
          ],
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Metadaten
          CardMetadataWidget(
            customMetadata: _buildMetadata(),
          ),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Aktionen
          CardActionsWidget(
            onEdit: onEdit,
            onDelete: onDelete,
            onQuickAction: onTap,
            alignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    final parts = <String>[];
    parts.add(_getTypeDisplayName());
    
    if (entry.campaignId == null) {
      parts.add('Global');
    }
    
    if (entry.isMarkdown) {
      parts.add('Markdown');
    }
    
    return parts.join(' • ');
  }

  List<Widget> _buildTypeChips() {
    final chips = <Widget>[];
    
    // Typ-Chip
    chips.add(
      UnifiedInfoChip.type(
        type: _getTypeDisplayName(),
        icon: _getTypeIcon(),
        color: _getTypeColor(),
      ),
    );
    
    // Global-Badge
    if (entry.campaignId == null) {
      chips.add(
        UnifiedInfoChip.tag(
          tag: 'Global',
          icon: Icons.public,
          color: DnDTheme.arcaneBlue,
        ),
      );
    }
    
    // Standort-Badge
    if (entry.location != null) {
      chips.add(
        UnifiedInfoChip.tag(
          tag: 'Standort',
          icon: Icons.location_on,
          color: DnDTheme.successGreen,
        ),
      );
    }
    
    return chips;
  }

  Widget _buildContentPreview() {
    final content = entry.isMarkdown 
        ? _stripMarkdown(entry.content)
        : entry.content;
    
    return CardContentWidget(
      description: content,
      descriptionMaxLines: 3,
    );
  }

  String _stripMarkdown(String markdown) {
    // Einfache Markdown-Reinigung für Preview
    return markdown
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'\1') // Bold
        .replaceAll(RegExp(r'\*(.*?)\*'), r'\1')     // Italic
        .replaceAll(RegExp(r'_(.*?)_'), r'\1')       // Italic
        .replaceAll(RegExp(r'`(.*?)`'), r'\1')       // Code
        .replaceAll(RegExp(r'#{1,6}\s*'), '')        // Headers
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^\)]+\)'), r'\1') // Links
        .replaceAll(RegExp(r'\n'), ' ')              // Newlines
        .trim();
  }

  Widget _buildTags() {
    final chips = entry.tags.take(5).map((tag) => 
      UnifiedInfoChip.tag(
        tag: tag,
        color: DnDTheme.ancientGold,
      ),
    ).toList();
    
    return UnifiedChipSection(
      title: 'Tags',
      titleIcon: Icons.label_outline,
      titleColor: DnDTheme.ancientGold,
      chips: chips,
    );
  }

  Map<String, String> _buildMetadata() {
    final metadata = <String, String>{};
    
    // Aktualisiert
    metadata['Aktualisiert'] = _formatDate(entry.updatedAt);
    
    // Verknüpfungen
    if (entry.childIds.isNotEmpty) {
      metadata['Verknüpfungen'] = '${entry.childIds.length}';
    }
    
    // Standort
    if (entry.location != null) {
      metadata['Koordinaten'] = 
        '${entry.location!.latitude.toStringAsFixed(2)}, ${entry.location!.longitude.toStringAsFixed(2)}';
    }
    
    return metadata;
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
      PopupMenuItem(
        value: 'toggle_global',
        child: Row(
          children: [
            Icon(
              entry.campaignId == null ? Icons.campaign : Icons.public,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              entry.campaignId == null ? 'Zu Campaign machen' : 'Global machen',
            ),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'link',
        child: Row(
          children: [
            Icon(Icons.link, size: 16),
            SizedBox(width: 8),
            Text('Verknüpfen'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'export',
        child: Row(
          children: [
            Icon(Icons.file_download, size: 16),
            SizedBox(width: 8),
            Text('Exportieren'),
          ],
        ),
      ),
    ];
  }

  void _handlePopupMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eintrag duplizieren...')),
        );
        break;
      case 'toggle_global':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Global-Status ändern...')),
        );
        break;
      case 'link':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eintrag verknüpfen...')),
        );
        break;
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eintrag exportieren...')),
        );
        break;
    }
  }
}