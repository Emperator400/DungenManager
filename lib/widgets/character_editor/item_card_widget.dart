import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';
import 'item_color_helper.dart';
import '../../theme/dnd_theme.dart';

class ItemCardWidget extends StatelessWidget {
  final DisplayInventoryItem displayItem;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isDraggable;
  final bool isSelected;

  const ItemCardWidget({
    super.key,
    required this.displayItem,
    this.onTap,
    this.onLongPress,
    this.isDraggable = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final item = displayItem.item;
    final inventoryItem = displayItem.inventoryItem;
    
    // Nutze D&D Theme Rarity-Farben mit Fallback auf ItemColorHelper
    final rarityColor = item.rarity != null 
        ? DnDTheme.getRarityColor(item.rarity!)
        : DnDTheme.rarityColors['common']!;

    // Verwende GestureDetector statt LongPressDraggable für bessere Kompatibilität
    Widget cardWidget = GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        width: 120,
        height: 150,
        decoration: DnDTheme.getRarityBorder(item.rarity ?? 'common').copyWith(
          color: isSelected ? DnDTheme.ancientGold : rarityColor,
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          boxShadow: [
            // Mystischer Schatten für selected Items
            if (isSelected)
              BoxShadow(
                color: DnDTheme.ancientGold.withValues(alpha: 0.5),
                blurRadius: 12,
                spreadRadius: 2,
              )
            else
              // Standard mystical shadow
              BoxShadow(
                color: rarityColor.withValues(alpha: 0.3),
                blurRadius: 8,
                spreadRadius: 1,
              ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item-Bild oder Icon
              Center(
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ItemColorHelper.getItemTypeColor(item.itemType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: item.imageUrl.isNotEmpty
                        ? Image.network(
                            item.imageUrl,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback auf Icon wenn Bild nicht geladen werden kann
                              return Icon(
                                ItemColorHelper.getItemTypeIcon(item.itemType),
                                color: Colors.white,
                                size: 22,
                              );
                            },
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        : Icon(
                            ItemColorHelper.getItemTypeIcon(item.itemType),
                            color: Colors.white,
                            size: 22,
                          ),
                  ),
                ),
              ),
              
              const SizedBox(height: 6),
              
              // Item-Name
              Expanded(
                child: Text(
                  item.name,
                  style: DnDTheme.caption.copyWith(
                    color: rarityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    height: 1.0,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 2),
              
              // Untere Zeile: Typ, Gewicht und Menge
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Item-Typ
                  Text(
                    ItemColorHelper.getItemTypeDisplayName(item.itemType),
                    style: DnDTheme.caption.copyWith(
                      color: DnDTheme.mysticalPurple.withValues(alpha: 0.7),
                      fontSize: 7,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 1),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Gewicht
                      Text(
                        '${item.weight} lbs',
                        style: DnDTheme.caption.copyWith(
                          color: DnDTheme.stoneGrey.withValues(alpha: 0.8),
                          fontSize: 6,
                        ),
                      ),
                      
                      // Menge (wenn > 1) - mit mystischem Effekt
                      if (inventoryItem.quantity > 1) ...[
                        const SizedBox(width: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 0.5),
                            decoration: BoxDecoration(
                              color: DnDTheme.emeraldGreen.withValues(alpha: 0.8),
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
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  
                  // Haltbarkeits-Indikator (wenn vorhanden)
                  if (item.hasDurability == true && 
                      displayItem.currentDurability != null &&
                      item.maxDurability != null) ...[
                    const SizedBox(height: 1),
                    _buildDurabilityIndicator(displayItem),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );

    return cardWidget;
  }

  Widget _buildDurabilityIndicator(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final current = displayItem.currentDurability ?? item.maxDurability ?? 100;
    final max = item.maxDurability ?? 100;
    final percentage = current / max;
    
    return Container(
      width: 18,
      height: 2,
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
        borderRadius: BorderRadius.circular(1),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
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
