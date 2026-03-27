import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';
import '../../../models/item.dart';
import '../../../theme/dnd_theme.dart';
import '../../character_editor/item_color_helper.dart';
import '../chips/unified_info_chip.dart';

/// Unified Item Card
/// 
/// Einheitliche Item-Karte für Inventar und Item-Bibliothek
/// Unterstützt Rarity-basierte Farben, Drag & Drop, Durability
class UnifiedItemCard extends StatelessWidget {
  final DisplayInventoryItem displayItem;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;
  final bool isCompact;
  final bool showDurability;
  final bool showQuantity;

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

  @override
  Widget build(BuildContext context) {
    final item = displayItem.item;
    final inventoryItem = displayItem.inventoryItem;
    final rarityColor = item.rarity != null 
        ? DnDTheme.getRarityColor(item.rarity!)
        : DnDTheme.rarityColors['common']!;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: isCompact ? 100 : 120,
        height: isCompact ? 130 : 150,
        decoration: _buildDecoration(rarityColor),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 4.0 : 6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item-Icon/Bild
              _buildItemIcon(item, rarityColor),
              
              SizedBox(height: isCompact ? 4 : 6),
              
              // Item-Name
              Expanded(
                child: Text(
                  item.name,
                  style: DnDTheme.caption.copyWith(
                    color: rarityColor,
                    fontSize: isCompact ? 10 : 11,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              
              SizedBox(height: isCompact ? 1 : 2),
              
              // Item-Details
              _buildItemDetails(item, inventoryItem),
            ],
          ),
        ),
      ),
    );
  }

  /// Item-Icon oder Bild
  Widget _buildItemIcon(Item item, Color rarityColor) {
    return Center(
      child: Container(
        width: isCompact ? 32 : 40,
        height: isCompact ? 32 : 40,
        decoration: BoxDecoration(
          color: ItemColorHelper.getItemTypeColor(item.itemType),
          borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
          border: Border.all(
            color: rarityColor.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
          child: item.imageUrl.isNotEmpty
              ? Image.network(
                  item.imageUrl,
                  width: isCompact ? 32 : 40,
                  height: isCompact ? 32 : 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return _buildFallbackIcon(item);
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: isCompact ? 12 : 14,
                        height: isCompact ? 12 : 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : _buildFallbackIcon(item),
        ),
      ),
    );
  }

  /// Fallback-Icon wenn kein Bild vorhanden
  Widget _buildFallbackIcon(Item item) {
    return Icon(
      ItemColorHelper.getItemTypeIcon(item.itemType),
      color: Colors.white,
      size: isCompact ? 18 : 22,
    );
  }

  /// Item-Details: Typ, Gewicht, Menge, Durability
  Widget _buildItemDetails(Item item, InventoryItem inventoryItem) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Item-Typ
        Text(
          ItemColorHelper.getItemTypeDisplayName(item.itemType),
          style: DnDTheme.caption.copyWith(
            color: DnDTheme.mysticalPurple.withOpacity(0.7),
            fontSize: isCompact ? 6 : 7,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        SizedBox(height: isCompact ? 0.5 : 1),
        
        // Gewicht und Menge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Gewicht
            Text(
              '${item.weight} lbs',
              style: DnDTheme.caption.copyWith(
                color: DnDTheme.stoneGrey.withOpacity(0.8),
                fontSize: isCompact ? 5 : 6,
              ),
            ),
            
            // Menge
            if (showQuantity && inventoryItem.quantity > 1) ...[
              const SizedBox(width: 2),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 1 : 2, 
                  vertical: isCompact ? 0.25 : 0.5
                ),
                decoration: BoxDecoration(
                  color: DnDTheme.emeraldGreen.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  border: Border.all(
                    color: DnDTheme.ancientGold,
                    width: 0.5,
                  ),
                ),
                child: Text(
                  '×${inventoryItem.quantity}',
                  style: DnDTheme.caption.copyWith(
                    color: Colors.white,
                    fontSize: isCompact ? 5 : 6,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        
        // Durability-Indikator
        if (showDurability && 
            item.hasDurability == true && 
            displayItem.currentDurability != null &&
            item.maxDurability != null) ...[
          SizedBox(height: isCompact ? 0.5 : 1),
          _buildDurabilityIndicator(item),
        ],
      ],
    );
  }

  /// Decoration für die Karte
  BoxDecoration _buildDecoration(Color rarityColor) {
    return BoxDecoration(
      color: DnDTheme.slateGrey.withOpacity(0.3),
      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      border: Border.all(
        color: isSelected ? DnDTheme.ancientGold : rarityColor,
        width: isSelected ? 2 : 1,
      ),
      boxShadow: [
        if (isSelected)
          BoxShadow(
            color: DnDTheme.ancientGold.withOpacity(0.5),
            blurRadius: 12,
            spreadRadius: 2,
          )
        else
          BoxShadow(
            color: rarityColor.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
      ],
    );
  }

  /// Durability-Indikator
  Widget _buildDurabilityIndicator(Item item) {
    final current = displayItem.currentDurability ?? item.maxDurability ?? 100;
    final max = item.maxDurability ?? 100;
    final percentage = current / max;
    
    return Container(
      width: isCompact ? 14 : 18,
      height: 2,
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: BorderRadius.circular(1),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: ItemColorHelper.getDurabilityColor(percentage),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

/// Erweiterte Item-Card für Listenansicht
class UnifiedItemListTile extends StatelessWidget {
  final DisplayInventoryItem displayItem;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isSelected;

  const UnifiedItemListTile({
    super.key,
    required this.displayItem,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final item = displayItem.item;
    final inventoryItem = displayItem.inventoryItem;
    final rarityColor = item.rarity != null 
        ? DnDTheme.getRarityColor(item.rarity!)
        : DnDTheme.rarityColors['common']!;

    return Container(
      decoration: BoxDecoration(
        color: isSelected 
            ? DnDTheme.ancientGold.withOpacity(0.1)
            : DnDTheme.slateGrey.withOpacity(0.2),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: isSelected ? DnDTheme.ancientGold : rarityColor.withOpacity(0.3),
          width: isSelected ? 2 : 1,
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
            border: Border.all(
              color: rarityColor.withOpacity(0.5),
            ),
          ),
          child: Icon(
            ItemColorHelper.getItemTypeIcon(item.itemType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          item.name,
          style: DnDTheme.bodyText2.copyWith(
            color: rarityColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ItemColorHelper.getItemTypeDisplayName(item.itemType),
              style: DnDTheme.caption.copyWith(
                color: DnDTheme.mysticalPurple.withOpacity(0.7),
              ),
            ),
            if (item.description != null && item.description!.isNotEmpty)
              Text(
                item.description!,
                style: DnDTheme.caption.copyWith(
                  color: Colors.white54,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (inventoryItem.quantity > 1)
              UnifiedInfoChip.count(
                label: '',
                count: inventoryItem.quantity,
                color: DnDTheme.emeraldGreen,
              ),
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                color: DnDTheme.arcaneBlue,
                onPressed: onEdit,
              ),
            if (onDelete != null)
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: DnDTheme.errorRed,
                onPressed: onDelete,
              ),
          ],
        ),
      ),
    );
  }
}