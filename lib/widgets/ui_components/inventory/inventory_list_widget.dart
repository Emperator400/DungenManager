import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';
import '../../../models/item.dart';
import '../../../theme/dnd_theme.dart';
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
    if (items.isEmpty && showEmptyState) {
      return _buildEmptyState();
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final displayItem = items[index];
        return _buildInventoryItemCard(context, displayItem);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
            ),
            const SizedBox(height: DnDTheme.lg),
            Text(
              emptyTitle ?? 'Inventar ist leer',
              style: DnDTheme.headline2.copyWith(
                color: DnDTheme.ancientGold,
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              emptySubtitle ?? 'Füge Gegenstände hinzu',
              style: DnDTheme.bodyText1.copyWith(
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
  ) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;
    
    return Card(
      color: DnDTheme.slateGrey,
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DnDTheme.lg),
        leading: _buildItemIcon(item),
        title: Text(
          item.name,
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildItemDescription(item),
            if (item.hasDurability == true && 
                displayItem.currentDurability != null) ...[
              const SizedBox(height: 4),
              _buildDurabilityBar(displayItem),
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
                  horizontal: DnDTheme.md,
                  vertical: DnDTheme.xs,
                ),
                decoration: BoxDecoration(
                  color: DnDTheme.ancientGold,
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                ),
                child: Text(
                  'x${invItem.quantity}',
                  style: DnDTheme.bodyText2.copyWith(
                    color: DnDTheme.dungeonBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: DnDTheme.sm),
            ],
            // Action Buttons
            if (isEditable) ...[
              if (onItemEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, color: DnDTheme.arcaneBlue),
                  onPressed: () => onItemEdit!(displayItem),
                  tooltip: 'Bearbeiten',
                ),
              if (onItemDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete, color: DnDTheme.errorRed),
                  onPressed: () => _showDeleteDialog(context, displayItem),
                  tooltip: 'Löschen',
                ),
            ],
          ],
        ),
        onTap: onItemTap != null ? () => onItemTap!(displayItem) : null,
      ),
    );
  }

  Widget _buildItemIcon(Item item) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: DnDTheme.arcaneBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        ItemColorHelper.getItemTypeIcon(item.itemType),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildItemDescription(Item item) {
    final description = item.description.isNotEmpty 
        ? item.description 
        : '${item.itemType.name} • ${item.weight} Pfund';
    
    return Text(
      description,
      style: DnDTheme.bodyText2.copyWith(
        color: Colors.white60,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDurabilityBar(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final current = displayItem.currentDurability ?? item.maxDurability ?? 100;
    final max = item.maxDurability ?? 100;
    final percentage = current / max;
    
    final durabilityColor = ItemColorHelper.getDurabilityColor(percentage);
    
    return Container(
      width: double.infinity,
      height: 4,
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
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

  void _showDeleteDialog(BuildContext context, DisplayInventoryItem displayItem) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          '${displayItem.item.name} löschen',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Text(
          'Möchtest du "${displayItem.item.name}" wirklich löschen?',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
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
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
