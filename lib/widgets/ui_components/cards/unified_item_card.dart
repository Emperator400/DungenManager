import 'package:flutter/material.dart';

import '../../../models/inventory_item.dart';
import '../../../models/item.dart';
import '../../../theme/app_theme.dart';
import '../../character_editor/item_color_helper.dart';
import '../resource_image.dart';

class UnifiedItemCard extends StatelessWidget {
  const UnifiedItemCard({
    super.key,
    required this.displayItem,
    this.onTap,
    this.onLongPress,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
    this.isCompact = false,
    this.showDurability = true,
    this.showQuantity = true,
  });

  final DisplayInventoryItem displayItem;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool isCompact;
  final bool showDurability;
  final bool showQuantity;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final item = displayItem.item;
    final inventoryItem = displayItem.inventoryItem;
    final rarityColor = _rarityColor(item.rarity, C);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: isCompact ? 100 : 120,
        height: isCompact ? 130 : 150,
        decoration: BoxDecoration(
          color: C.bgPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? C.accent : rarityColor.withValues(alpha: 0.5),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 4.0 : 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildItemIcon(item, rarityColor),
              SizedBox(height: isCompact ? 4 : 6),
              Expanded(
                child: Text(
                  item.name,
                  style: TextStyle(
                    color: rarityColor,
                    fontSize: isCompact ? 10 : 11,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: isCompact ? 1 : 2),
              _buildItemDetails(item, inventoryItem, C),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemIcon(Item item, Color rarityColor) => Center(
        child: Container(
          width: isCompact ? 32 : 40,
          height: isCompact ? 32 : 40,
          decoration: BoxDecoration(
            color: ItemColorHelper.getItemTypeColor(item.itemType),
            borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
            border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
            child: buildResourceImage(
              ref: item.imageUrl.isNotEmpty ? item.imageUrl : null,
              fallback: _fallbackIcon(item),
              width: isCompact ? 32 : 40,
              height: isCompact ? 32 : 40,
            ),
          ),
        ),
      );

  Widget _fallbackIcon(Item item) => Icon(
        ItemColorHelper.getItemTypeIcon(item.itemType),
        color: Colors.white,
        size: isCompact ? 18 : 22,
      );

  Widget _buildItemDetails(Item item, InventoryItem inventoryItem, AppColorsExtension C) =>
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ItemColorHelper.getItemTypeDisplayName(item.itemType),
            style: TextStyle(
              color: C.textSoft,
              fontSize: isCompact ? 6 : 7,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isCompact ? 0.5 : 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${item.weight} lbs',
                style: TextStyle(color: C.textSoft, fontSize: isCompact ? 5 : 6),
              ),
              if (showQuantity && inventoryItem.quantity > 1) ...[
                const SizedBox(width: 2),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isCompact ? 1 : 2,
                    vertical: isCompact ? 0.25 : 0.5,
                  ),
                  decoration: BoxDecoration(
                    color: C.green,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    '×${inventoryItem.quantity}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isCompact ? 5 : 6,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
          if (showDurability &&
              (item.hasDurability ?? false) &&
              displayItem.currentDurability != null &&
              item.maxDurability != null) ...[
            SizedBox(height: isCompact ? 0.5 : 1),
            _buildDurabilityBar(item),
          ],
        ],
      );

  Widget _buildDurabilityBar(Item item) {
    final current = displayItem.currentDurability ?? item.maxDurability ?? 100;
    final max = item.maxDurability ?? 100;
    final pct = (current / max).clamp(0.0, 1.0);
    return Container(
      width: isCompact ? 14 : 18,
      height: 2,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(1),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: pct,
        child: Container(
          decoration: BoxDecoration(
            color: ItemColorHelper.getDurabilityColor(pct),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

// ── LIST TILE ─────────────────────────────────────────────────────────────────

class UnifiedItemListTile extends StatelessWidget {
  const UnifiedItemListTile({
    required this.displayItem,
    super.key,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
  });

  final DisplayInventoryItem displayItem;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final item = displayItem.item;
    final inventoryItem = displayItem.inventoryItem;
    final rarityColor = _rarityColor(item.rarity, C);

    return Container(
      decoration: BoxDecoration(
        color: isSelected ? C.accentSoft : C.bgPanel,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? C.accent : C.border,
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: ItemColorHelper.getItemTypeColor(item.itemType),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: rarityColor.withValues(alpha: 0.5)),
          ),
          child: Icon(
            ItemColorHelper.getItemTypeIcon(item.itemType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          item.name,
          style: TextStyle(
            color: rarityColor,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ItemColorHelper.getItemTypeDisplayName(item.itemType),
              style: TextStyle(color: C.textSoft, fontSize: 11),
            ),
            if (item.description.isNotEmpty)
              Text(
                item.description,
                style: TextStyle(color: C.textMid, fontSize: 11),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inventoryItem.quantity > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: C.greenSoft,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '×${inventoryItem.quantity}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: C.green,
                  ),
                ),
              ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: C.accent,
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: C.red,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

Color _rarityColor(String? rarity, AppColorsExtension C) {
  switch ((rarity ?? 'common').toLowerCase()) {
    case 'uncommon':
      return C.green;
    case 'rare':
      return C.accent;
    case 'very rare':
      return const Color(0xFF7C3AED);
    case 'legendary':
      return C.amber;
    default:
      return C.textSoft;
  }
}
