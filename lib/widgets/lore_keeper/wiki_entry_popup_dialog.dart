import 'package:flutter/material.dart';
import '../../models/wiki_entry.dart';
import '../../theme/dnd_theme.dart';

/// Popup-Dialog zur Anzeige von Wiki-Eintrags-Details
/// 
/// Wird verwendet, um Wiki-Einträge in Szenen und anderen Kontexten
/// schnell anzuzeigen ohne die Hauptseite zu verlassen.
class WikiEntryPopupDialog extends StatelessWidget {
  final WikiEntry entry;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenFull;

  const WikiEntryPopupDialog({
    super.key,
    required this.entry,
    this.onEdit,
    this.onDelete,
    this.onOpenFull,
  });

  @override
  Widget build(BuildContext context) => Dialog(
    backgroundColor: Colors.transparent,
    insetPadding: const EdgeInsets.symmetric(horizontal: DnDTheme.md, vertical: DnDTheme.lg),
    child: Container(
      constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.dungeonBlack,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: _getTypeColor().withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getTypeColor().withValues(alpha: 0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(DnDTheme.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.tags.isNotEmpty) ...[
                    _buildTags(),
                    const SizedBox(height: DnDTheme.sm),
                  ],
                  _buildContent(),
                  const SizedBox(height: DnDTheme.sm),
                  _buildMetadata(),
                ],
              ),
            ),
          ),
          _buildActions(context),
        ],
      ),
    ),
  );

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.all(DnDTheme.md),
    decoration: BoxDecoration(
      color: _getTypeColor().withValues(alpha: 0.15),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(DnDTheme.radiusMedium),
        topRight: Radius.circular(DnDTheme.radiusMedium),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(DnDTheme.sm),
          decoration: BoxDecoration(
            color: _getTypeColor().withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            border: Border.all(
              color: _getTypeColor().withValues(alpha: 0.5),
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
                style: DnDTheme.caption.copyWith(
                  color: _getTypeColor(),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                entry.title,
                style: DnDTheme.headline3.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (entry.isFavorite)
          Padding(
            padding: const EdgeInsets.only(right: DnDTheme.xs),
            child: Icon(
              Icons.favorite,
              color: DnDTheme.warningOrange,
              size: 20,
            ),
          ),
        if (entry.isMarkdown)
          Padding(
            padding: const EdgeInsets.only(right: DnDTheme.xs),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: DnDTheme.arcaneBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              ),
              child: Text(
                'MD',
                style: DnDTheme.caption.copyWith(
                  color: DnDTheme.arcaneBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _buildTags() => Wrap(
    spacing: DnDTheme.xs,
    runSpacing: DnDTheme.xs,
    children: entry.tags.map((tag) => _buildTagChip(tag)).toList(),
  );

  Widget _buildTagChip(String tag) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DnDTheme.sm,
      vertical: DnDTheme.xs,
    ),
    decoration: BoxDecoration(
      color: DnDTheme.ancientGold.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      border: Border.all(
        color: DnDTheme.ancientGold.withValues(alpha: 0.4),
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

  Widget _buildContent() {
    final content = entry.isMarkdown 
        ? _stripMarkdown(entry.content)
        : entry.content;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(DnDTheme.sm),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: DnDTheme.slateGrey.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        content.isNotEmpty ? content : 'Kein Inhalt vorhanden',
        style: DnDTheme.bodyText2.copyWith(
          color: content.isNotEmpty ? Colors.white70 : Colors.white38,
          height: 1.5,
          fontStyle: content.isEmpty ? FontStyle.italic : FontStyle.normal,
        ),
      ),
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
        .replaceAll(RegExp(r'\n+'), '\n')            // Multiple newlines
        .trim();
  }

  Widget _buildMetadata() => Wrap(
    spacing: DnDTheme.md,
    runSpacing: DnDTheme.xs,
    children: [
      _buildMetadataItem(
        Icons.schedule,
        'Erstellt: ${_formatDate(entry.createdAt)}',
      ),
      if (entry.updatedAt != entry.createdAt)
        _buildMetadataItem(
          Icons.update,
          'Aktualisiert: ${_formatDate(entry.updatedAt)}',
        ),
      if (entry.childIds.isNotEmpty)
        _buildMetadataItem(
          Icons.link,
          '${entry.childIds.length} Verknüpfung${entry.childIds.length == 1 ? '' : 'en'}',
        ),
      if (entry.campaignId == null)
        _buildMetadataItem(
          Icons.public,
          'Global',
          color: DnDTheme.arcaneBlue,
        ),
    ],
  );

  Widget _buildMetadataItem(IconData icon, String text, {Color? color}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 14,
        color: color ?? Colors.white54,
      ),
      const SizedBox(width: 4),
      Text(
        text,
        style: DnDTheme.caption.copyWith(
          color: color ?? Colors.white54,
        ),
      ),
    ],
  );

  Widget _buildActions(BuildContext context) => Container(
    padding: const EdgeInsets.all(DnDTheme.sm),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.2),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(DnDTheme.radiusMedium),
        bottomRight: Radius.circular(DnDTheme.radiusMedium),
      ),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        // Löschen-Button (wenn onDelete bereitgestellt wird)
        if (onDelete != null) ...[
          TextButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              onDelete?.call();
            },
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Löschen'),
            style: TextButton.styleFrom(
              foregroundColor: DnDTheme.errorRed,
            ),
          ),
          const SizedBox(width: DnDTheme.xs),
        ],
        // Im Wiki öffnen-Button
        if (onOpenFull != null)
          TextButton.icon(
            onPressed: onOpenFull,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Im Wiki öffnen'),
            style: TextButton.styleFrom(
              foregroundColor: DnDTheme.arcaneBlue,
            ),
          ),
        // Bearbeiten-Button
        if (onEdit != null) ...[
          const SizedBox(width: DnDTheme.xs),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Bearbeiten'),
            style: TextButton.styleFrom(
              foregroundColor: DnDTheme.ancientGold,
            ),
          ),
        ],
        const SizedBox(width: DnDTheme.xs),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            foregroundColor: Colors.white70,
          ),
          child: const Text('Schließen'),
        ),
      ],
    ),
  );

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
        return 'NPC / Person';
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

  String _formatDate(DateTime date) => '${date.day}.${date.month}.${date.year}';

  /// Helper-Methode zum Anzeigen des Dialogs
  static Future<void> show({
    required BuildContext context,
    required WikiEntry entry,
    VoidCallback? onEdit,
    VoidCallback? onDelete,
    VoidCallback? onOpenFull,
  }) {
    return showDialog(
      context: context,
      builder: (context) => WikiEntryPopupDialog(
        entry: entry,
        onEdit: onEdit,
        onDelete: onDelete,
        onOpenFull: onOpenFull,
      ),
    );
  }
}