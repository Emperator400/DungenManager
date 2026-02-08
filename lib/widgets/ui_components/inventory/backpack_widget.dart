import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';
import '../../../models/item.dart';
import '../../../theme/dnd_theme.dart';

/// Widget für die Tasche/Rucksack-ansicht
/// Zeigt Items, die NICHT ausgerüstet sind
/// 
/// Beispiele:
/// ```dart
/// BackpackWidget(
///   inventoryItems: viewModel.inventory,
///   equippedItemIds: viewModel.equippedItemIds,
///   onEquipItem: (displayItem) => // Item in Slot rüsten
/// )
/// ```
class BackpackWidget extends StatelessWidget {
  /// Alle Items im Inventar
  final List<DisplayInventoryItem> inventoryItems;
  
  /// IDs der ausgerüsteten Items (werden ausgeblendet)
  final Set<String> equippedItemIds;
  
  /// Callback wenn ein Item ausgerüstet wird
  final Function(DisplayInventoryItem)? onEquipItem;
  
  /// Optional: Callback für Bearbeiten
  final Function(DisplayInventoryItem)? onEditItem;
  
  /// Optional: Callback für Löschen
  final Function(DisplayInventoryItem)? onDeleteItem;

  const BackpackWidget({
    super.key,
    required this.inventoryItems,
    required this.equippedItemIds,
    this.onEquipItem,
    this.onEditItem,
    this.onDeleteItem,
  });

  /// Gibt nur die Items zurück, die NICHT ausgerüstet sind
  List<DisplayInventoryItem> get _backpackItems {
    return inventoryItems.where((item) {
      return !equippedItemIds.contains(item.inventoryItem.id);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final backpackItems = _backpackItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titel
        Row(
          children: [
            Icon(
              Icons.backpack,
              color: DnDTheme.ancientGold,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Tasche',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: DnDTheme.arcaneBlue.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                border: Border.all(
                  color: DnDTheme.arcaneBlue,
                  width: 1,
                ),
              ),
              child: Text(
                '${backpackItems.length}',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.arcaneBlue,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: DnDTheme.md),
        
        // Item-Liste oder Empty State
        if (backpackItems.isEmpty)
          _buildEmptyState()
        else
          _buildItemList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.slateGrey,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
          ),
          const SizedBox(height: DnDTheme.md),
          Text(
            'Tasche ist leer',
            style: DnDTheme.bodyText1.copyWith(
              color: Colors.white60,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DnDTheme.sm),
          Text(
            'Füge Gegenstände aus dem Inventar hinzu',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white38,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemList() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: DnDTheme.sm,
        mainAxisSpacing: DnDTheme.sm,
      ),
      itemCount: _backpackItems.length,
      itemBuilder: (context, index) {
        final displayItem = _backpackItems[index];
        return _buildItemCard(context, displayItem);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;

    return GestureDetector(
      onTap: () => _showItemDialog(context, displayItem),
      child: Container(
        decoration: BoxDecoration(
          color: DnDTheme.slateGrey,
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          border: Border.all(
            color: DnDTheme.ancientGold,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Hauptinhalt
            Padding(
              padding: const EdgeInsets.all(DnDTheme.sm),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Item-Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: DnDTheme.arcaneBlue,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getItemIcon(item.itemType),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: DnDTheme.xs),
                  // Item-Name
                  Text(
                    item.name,
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  // Menge
                  if (invItem.quantity > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: DnDTheme.ancientGold,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'x${invItem.quantity}',
                        style: DnDTheme.bodyText2.copyWith(
                          color: DnDTheme.dungeonBlack,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            
            // Ausrüsten-Button (oben rechts)
            if (onEquipItem != null)
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () {
                    if (onEquipItem != null) {
                      onEquipItem!(displayItem);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: DnDTheme.successGreen,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showItemDialog(BuildContext context, DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          item.name,
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Center(
              child: Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: DnDTheme.arcaneBlue,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getItemIcon(item.itemType),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: DnDTheme.md),
            
            // Details
            Text(
              item.itemType.name,
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            if (item.description.isNotEmpty)
              Text(
                item.description,
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white70,
                ),
              ),
            if (invItem.quantity > 1) ...[
              const SizedBox(height: DnDTheme.sm),
              Text(
                'Menge: ${invItem.quantity}',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
              ),
            ],
            const SizedBox(height: DnDTheme.sm),
            Text(
              'Gewicht: ${item.weight} Pfund',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white60,
              ),
            ),
          ],
        ),
        actions: [
          // Bearbeiten
          if (onEditItem != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onEditItem!(displayItem);
              },
              icon: const Icon(Icons.edit),
              label: Text(
                'Bearbeiten',
                style: DnDTheme.bodyText1.copyWith(
                  color: DnDTheme.arcaneBlue,
                ),
              ),
            ),
          
          // Löschen
          if (onDeleteItem != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onDeleteItem!(displayItem);
              },
              icon: const Icon(Icons.delete),
              label: Text(
                'Löschen',
                style: DnDTheme.bodyText1.copyWith(
                  color: DnDTheme.errorRed,
                ),
              ),
            ),
          
          // Ausrüsten
          if (onEquipItem != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onEquipItem!(displayItem);
              },
              icon: const Icon(Icons.add),
              label: const Text('Ausrüsten'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.successGreen,
                foregroundColor: Colors.white,
              ),
            ),
          
          // Abbrechen
          const SizedBox(width: DnDTheme.sm),
          
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Schließen',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getItemIcon(ItemType itemType) {
    switch (itemType) {
      case ItemType.Weapon:
        return Icons.sports_martial_arts;
      case ItemType.Armor:
        return Icons.security;
      case ItemType.Shield:
        return Icons.shield;
      case ItemType.Potion:
        return Icons.local_drink;
      case ItemType.MagicItem:
        return Icons.auto_fix_high;
      case ItemType.Tool:
        return Icons.build;
      case ItemType.Material:
        return Icons.inventory_2;
      case ItemType.AdventuringGear:
        return Icons.backpack;
      default:
        return Icons.inventory_2;
    }
  }
}
