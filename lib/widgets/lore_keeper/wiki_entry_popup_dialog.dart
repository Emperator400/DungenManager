import 'package:flutter/material.dart';
import '../../models/wiki_entry.dart';
import '../../theme/app_theme.dart';

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
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        decoration: BoxDecoration(
          color: C.bgPanel,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: _getTypeColor(C).withValues(alpha: 0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: _getTypeColor(C).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(C),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.tags.isNotEmpty) ...[
                      _buildTags(C),
                      const SizedBox(height: 8),
                    ],
                    _buildContent(C),
                    const SizedBox(height: 8),
                    _buildMetadata(C),
                  ],
                ),
              ),
            ),
            _buildActions(context, C),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension C) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: _getTypeColor(C).withValues(alpha: 0.15),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12.0),
        topRight: Radius.circular(12.0),
      ),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getTypeColor(C).withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: _getTypeColor(C).withValues(alpha: 0.5),
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
                  fontSize: 11,
                  color: _getTypeColor(C),
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                entry.title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: C.text,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (entry.isFavorite)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(
              Icons.favorite,
              color: C.amber,
              size: 20,
            ),
          ),
        if (entry.isMarkdown)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: C.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                'MD',
                style: TextStyle(
                  fontSize: 10,
                  color: C.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  );

  Widget _buildTags(AppColorsExtension C) => Wrap(
    spacing: 4,
    runSpacing: 4,
    children: entry.tags.map((tag) => _buildTagChip(tag, C)).toList(),
  );

  Widget _buildTagChip(String tag, AppColorsExtension C) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: 8,
      vertical: 4,
    ),
    decoration: BoxDecoration(
      color: C.amber.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(12.0),
      border: Border.all(
        color: C.amber.withValues(alpha: 0.4),
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

  Widget _buildContent(AppColorsExtension C) {
    final content = entry.isMarkdown
        ? _stripMarkdown(entry.content)
        : entry.content;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: C.bgPanel.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        content.isNotEmpty ? content : 'Kein Inhalt vorhanden',
        style: TextStyle(
          fontSize: 12,
          color: content.isNotEmpty ? C.textMid : C.textSoft,
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

  Widget _buildMetadata(AppColorsExtension C) => Wrap(
    spacing: 16,
    runSpacing: 4,
    children: [
      _buildMetadataItem(
        Icons.schedule,
        'Erstellt: ${_formatDate(entry.createdAt)}',
        C,
      ),
      if (entry.updatedAt != entry.createdAt)
        _buildMetadataItem(
          Icons.update,
          'Aktualisiert: ${_formatDate(entry.updatedAt)}',
          C,
        ),
      if (entry.childIds.isNotEmpty)
        _buildMetadataItem(
          Icons.link,
          '${entry.childIds.length} Verknüpfung${entry.childIds.length == 1 ? '' : 'en'}',
          C,
        ),
      if (entry.campaignId == null)
        _buildMetadataItem(
          Icons.public,
          'Global',
          C,
          color: C.accent,
        ),
    ],
  );

  Widget _buildMetadataItem(IconData icon, String text, AppColorsExtension C, {Color? color}) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(
        icon,
        size: 14,
        color: color ?? C.textSoft,
      ),
      const SizedBox(width: 4),
      Text(
        text,
        style: TextStyle(
          fontSize: 11,
          color: color ?? C.textSoft,
        ),
      ),
    ],
  );

  Widget _buildActions(BuildContext context, AppColorsExtension C) => Container(
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.black.withValues(alpha: 0.2),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(12.0),
        bottomRight: Radius.circular(12.0),
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
              foregroundColor: C.red,
            ),
          ),
          const SizedBox(width: 4),
        ],
        // Im Wiki öffnen-Button
        if (onOpenFull != null)
          TextButton.icon(
            onPressed: onOpenFull,
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('Im Wiki öffnen'),
            style: TextButton.styleFrom(
              foregroundColor: C.accent,
            ),
          ),
        // Bearbeiten-Button
        if (onEdit != null) ...[
          const SizedBox(width: 4),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Bearbeiten'),
            style: TextButton.styleFrom(
              foregroundColor: C.amber,
            ),
          ),
        ],
        const SizedBox(width: 4),
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
