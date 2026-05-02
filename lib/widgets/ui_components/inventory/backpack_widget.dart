import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';
import '../../../models/item.dart';
import '../../../theme/app_theme.dart';

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
    final C = context.appColors;
    final backpackItems = _backpackItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titel
        Row(
          children: [
            Icon(
              Icons.backpack,
              color: C.amber,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Tasche',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text).copyWith(
                color: C.amber,
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
                color: C.accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: C.accent,
                  width: 1,
                ),
              ),
              child: Text(
                '${backpackItems.length}',
                style: TextStyle(fontSize: 12, color: C.textMid).copyWith(
                  color: C.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Item-Liste oder Empty State
        if (backpackItems.isEmpty)
          _buildEmptyState(C)
        else
          _buildItemList(context, C),
      ],
    );
  }

  Widget _buildEmptyState(AppColorsExtension C) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.bgPanel.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: C.bgPanel,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 48,
            color: C.accent.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 12),
          Text(
            'Tasche ist leer',
            style: TextStyle(fontSize: 14, color: C.text).copyWith(
              color: Colors.white60,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Füge Gegenstände aus dem Inventar hinzu',
            style: TextStyle(fontSize: 12, color: C.textMid).copyWith(
              color: Colors.white38,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildItemList(BuildContext context, AppColorsExtension C) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        childAspectRatio: 1,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: _backpackItems.length,
      itemBuilder: (context, index) {
        final displayItem = _backpackItems[index];
        return _buildItemCard(context, displayItem, C);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, DisplayInventoryItem displayItem, AppColorsExtension C) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;

    return GestureDetector(
      onTap: () => _showItemDialog(context, displayItem, C),
      child: Container(
        decoration: BoxDecoration(
          color: C.bgPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: C.amber,
            width: 1,
          ),
        ),
        child: Stack(
          children: [
            // Hauptinhalt
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Item-Icon
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: C.accent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getItemIcon(item.itemType),
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Item-Name
                  Text(
                    item.name,
                    style: TextStyle(fontSize: 12, color: C.textMid).copyWith(
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
                        color: C.amber,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'x${invItem.quantity}',
                        style: TextStyle(fontSize: 12, color: C.textMid).copyWith(
                          color: Colors.black,
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
                      color: C.green,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
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

  void _showItemDialog(BuildContext context, DisplayInventoryItem displayItem, AppColorsExtension C) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          item.name,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: C.text).copyWith(
            color: C.amber,
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
                  color: C.accent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getItemIcon(item.itemType),
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Details
            Text(
              item.itemType.name,
              style: TextStyle(fontSize: 14, color: C.text).copyWith(
                color: C.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (item.description.isNotEmpty)
              Text(
                item.description,
                style: TextStyle(fontSize: 12, color: C.textMid).copyWith(
                  color: Colors.white70,
                ),
              ),
            if (invItem.quantity > 1) ...[
              const SizedBox(height: 8),
              Text(
                'Menge: ${invItem.quantity}',
                style: TextStyle(fontSize: 12, color: C.textMid).copyWith(
                  color: C.amber,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Gewicht: ${item.weight} Pfund',
              style: TextStyle(fontSize: 12, color: C.textMid).copyWith(
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
                style: TextStyle(fontSize: 14, color: C.text).copyWith(
                  color: C.accent,
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
                style: TextStyle(fontSize: 14, color: C.text).copyWith(
                  color: C.red,
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
                backgroundColor: C.green,
                foregroundColor: Colors.white,
              ),
            ),

          // Abbrechen
          const SizedBox(width: 8),

          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Schließen',
              style: TextStyle(fontSize: 14, color: C.text).copyWith(
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
