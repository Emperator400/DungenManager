import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';
import '../../../models/item.dart';
import '../../../theme/app_theme.dart';
import '../../character_editor/item_color_helper.dart';

/// Wiederverwendbares Widget für Inventar-Listen
///
/// Beispiele:
/// ```dart
/// InventoryListWidget(
///   items: viewModel.inventory,
///   onItemTap: (item) => // Handle Item-Tap
///   onItemDelete: (item) => // Handle Item-Löschung
///   isEditable: true,
/// )
/// ```
class InventoryListWidget extends StatelessWidget {
  final List<DisplayInventoryItem> items;
  final Function(DisplayInventoryItem)? onItemTap;
  final Function(DisplayInventoryItem)? onItemDelete;
  final Function(DisplayInventoryItem)? onItemEdit;
  final bool isEditable;
  final bool showEmptyState;
  final String? emptyTitle;
  final String? emptySubtitle;

  const InventoryListWidget({
    Key? key,
    required this.items,
    this.onItemTap,
    this.onItemDelete,
    this.onItemEdit,
    this.isEditable = true,
    this.showEmptyState = true,
    this.emptyTitle,
    this.emptySubtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    if (items.isEmpty && showEmptyState) {
      return _buildEmptyState(C);
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final displayItem = items[index];
        return _buildInventoryItemCard(context, displayItem, C);
      },
    );
  }

  Widget _buildEmptyState(AppColorsExtension C) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: C.accent.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              emptyTitle ?? 'Inventar ist leer',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: C.text).copyWith(
                color: C.amber,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              emptySubtitle ?? 'Füge Gegenstände hinzu',
              style: TextStyle(fontSize: 14, color: C.text).copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryItemCard(
    BuildContext context,
    DisplayInventoryItem displayItem,
    AppColorsExtension C,
  ) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;

    return Card(
      color: C.bgPanel,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: _buildItemIcon(item, C),
        title: Text(
          item.name,
          style: TextStyle(fontSize: 14, color: C.text).copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildItemDescription(item, C),
            if (item.hasDurability == true &&
                displayItem.currentDurability != null) ...[
              const SizedBox(height: 4),
              _buildDurabilityBar(displayItem, C),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Quantity Badge
            if (invItem.quantity > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: C.amber,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'x${invItem.quantity}',
                  style: TextStyle(fontSize: 12, color: C.textMid).copyWith(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            // Action Buttons
            if (isEditable) ...[
              if (onItemEdit != null)
                IconButton(
                  icon: Icon(Icons.edit, color: C.accent),
                  onPressed: () => onItemEdit!(displayItem),
                  tooltip: 'Bearbeiten',
                ),
              if (onItemDelete != null)
                IconButton(
                  icon: Icon(Icons.delete, color: C.red),
                  onPressed: () => _showDeleteDialog(context, displayItem, C),
                  tooltip: 'Löschen',
                ),
            ],
          ],
        ),
        onTap: onItemTap != null ? () => onItemTap!(displayItem) : null,
      ),
    );
  }

  Widget _buildItemIcon(Item item, AppColorsExtension C) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: C.accent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        ItemColorHelper.getItemTypeIcon(item.itemType),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildItemDescription(Item item, AppColorsExtension C) {
    final description = item.description.isNotEmpty
        ? item.description
        : '${item.itemType.name} • ${item.weight} Pfund';

    return Text(
      description,
      style: TextStyle(fontSize: 12, color: C.textMid).copyWith(
        color: Colors.white60,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDurabilityBar(DisplayInventoryItem displayItem, AppColorsExtension C) {
    final item = displayItem.item;
    final current = displayItem.currentDurability ?? item.maxDurability ?? 100;
    final max = item.maxDurability ?? 100;
    final percentage = current / max;

    final durabilityColor = ItemColorHelper.getDurabilityColor(percentage);

    return Container(
      width: double.infinity,
      height: 4,
      decoration: BoxDecoration(
        color: C.bg,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            color: durabilityColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, DisplayInventoryItem displayItem, AppColorsExtension C) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          '${displayItem.item.name} löschen',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: C.text).copyWith(
            color: C.amber,
          ),
        ),
        content: Text(
          'Möchtest du "${displayItem.item.name}" wirklich löschen?',
          style: TextStyle(fontSize: 14, color: C.text).copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(fontSize: 14, color: C.text).copyWith(
                color: C.accent,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (onItemDelete != null) {
                onItemDelete!(displayItem);
              }
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
}
