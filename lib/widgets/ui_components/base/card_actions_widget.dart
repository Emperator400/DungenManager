import 'package:flutter/material.dart';

/// Standardisierte Action-Bar für Cards
/// 
/// Zeigt Edit/Delete Buttons und weitere Aktionen
class CardActionsWidget extends StatelessWidget {
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onFavorite;
  final VoidCallback? onQuickAction;
  final bool isFavorite;
  final bool showActions;
  final MainAxisAlignment alignment;

  const CardActionsWidget({
    super.key,
    this.onEdit,
    this.onDelete,
    this.onDuplicate,
    this.onFavorite,
    this.onQuickAction,
    this.isFavorite = false,
    this.showActions = true,
    this.alignment = MainAxisAlignment.end,
  });

  @override
  Widget build(BuildContext context) {
    if (!showActions) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: alignment,
      children: [
        // Quick Action Button
        if (onQuickAction != null)
          TextButton.icon(
            onPressed: onQuickAction,
            icon: const Icon(Icons.more_horiz, size: 16),
            label: const Text('Aktionen'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        
        // Edit Button
        if (onEdit != null) ...[
          if (alignment == MainAxisAlignment.end)
            const SizedBox(width: 8),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Bearbeiten'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
        
        // Delete Button
        if (onDelete != null) ...[
          if (alignment == MainAxisAlignment.end && onEdit == null)
            const SizedBox(width: 8),
          TextButton.icon(
            onPressed: () => _showDeleteConfirmation(context),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Löschen'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Löschen bestätigen'),
        content: const Text(
          'Möchtest du diesen Eintrag wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
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
}
