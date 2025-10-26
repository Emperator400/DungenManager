import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/inventory_item.dart';
import '../../models/equip_slot.dart';

class InventoryGridWidget extends StatefulWidget {
  final List<DisplayInventoryItem> equippedItems;
  final List<DisplayInventoryItem> unequippedItems;
  final Function(DisplayInventoryItem, EquipSlot?) onEquipItem;
  final Function(DisplayInventoryItem) onUnequipItem;
  final Function(DisplayInventoryItem) onManageItem;
  final Function(DisplayInventoryItem, int) onUpdateQuantity;
  final Function(DisplayInventoryItem) onRemoveItem;
  final bool canEditItems;

  const InventoryGridWidget({
    super.key,
    required this.equippedItems,
    required this.unequippedItems,
    required this.onEquipItem,
    required this.onUnequipItem,
    required this.onManageItem,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    this.canEditItems = true,
  });

  @override
  State<InventoryGridWidget> createState() => _InventoryGridWidgetState();
}

class _InventoryGridWidgetState extends State<InventoryGridWidget> {
  DisplayInventoryItem? draggedItem;

  // Ausrüstungs-Slots nach Kategorien gruppiert
  Map<String, List<EquipSlot>> get categorizedSlots => {
    'Waffen': [EquipSlot.mainHand, EquipSlot.offHand, EquipSlot.ranged],
    'Zauber': [EquipSlot.spellActive, EquipSlot.cantripReady, EquipSlot.spellPrepared1, EquipSlot.spellPrepared2, EquipSlot.spellPrepared3, EquipSlot.spellPrepared4],
    'Rüstung': [EquipSlot.head, EquipSlot.chest, EquipSlot.hands, EquipSlot.feet, EquipSlot.cloak],
    'Accessoires': [EquipSlot.ring1, EquipSlot.ring2, EquipSlot.amulet, EquipSlot.belt],
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Ausrüstungs-Bereich
        _buildEquipmentSection(),
        const SizedBox(height: 16),
        // Inventar-Bereich
        _buildInventorySection(),
      ],
    );
  }

  Widget _buildEquipmentSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'AUSRÜSTUNG',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Waffen-Slots
            _buildEquipmentCategory('Waffen', categorizedSlots['Waffen']!),
            const SizedBox(height: 12),
            
            // Zauber-Slots
            _buildEquipmentCategory('Zauber', categorizedSlots['Zauber']!),
            const SizedBox(height: 12),
            
            // Rüstungs-Slots
            _buildEquipmentCategory('Rüstung', categorizedSlots['Rüstung']!),
            const SizedBox(height: 12),
            
            // Accessoire-Slots
            _buildEquipmentCategory('Accessoires', categorizedSlots['Accessoires']!),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipmentCategory(String categoryTitle, List<EquipSlot> slots) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          categoryTitle,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: slots.map((slot) => _buildEquipSlot(slot)).toList(),
        ),
      ],
    );
  }

  Widget _buildEquipSlot(EquipSlot slot) {
    final equippedItem = widget.equippedItems.firstWhere(
      (item) => item.inventoryItem.equipSlot == slot,
      orElse: () => DisplayInventoryItem(
        inventoryItem: InventoryItem(
          id: '',
          ownerId: '',
          itemId: '',
          isEquipped: false,
          equipSlot: slot,
        ),
        item: Item(
          id: '',
          name: '',
          itemType: ItemType.AdventuringGear,
        ),
      ),
    );

    return DragTarget<DisplayInventoryItem>(
      onAccept: (draggedItem) {
        if (widget.canEditItems) {
          _handleEquipItem(draggedItem, slot);
        }
      },
      builder: (context, candidateData, rejectedData) {
        final isHighlighted = candidateData.isNotEmpty;
        
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(
              color: isHighlighted ? Colors.green : Colors.grey.shade300,
              width: isHighlighted ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: equippedItem.item.id.isNotEmpty 
                ? Colors.amber.shade50 
                : Colors.grey.shade100,
          ),
          child: Stack(
            children: [
              // Slot-Icon
              if (equippedItem.item.id.isEmpty)
                Center(
                  child: Text(
                    slot.iconName,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              
              // Ausgerüstetes Item
              if (equippedItem.item.id.isNotEmpty)
                _buildEquippedItem(equippedItem),
              
              // Remove-Button (nur wenn editierbar)
              if (equippedItem.item.id.isNotEmpty && widget.canEditItems)
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () => widget.onUnequipItem(equippedItem),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEquippedItem(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Item-Typ Icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getItemTypeColor(item.itemType),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              _getItemTypeIcon(item.itemType),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          
          // Item-Name (gekürzt)
          Expanded(
            child: Text(
              item.name.length > 8 
                  ? '${item.name.substring(0, 6)}...' 
                  : item.name,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Durability-Indikator (wenn vorhanden)
          if (item.hasDurability == true && displayItem.currentDurability != null)
            _buildDurabilityIndicator(displayItem),
        ],
      ),
    );
  }

  Widget _buildDurabilityIndicator(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final current = displayItem.currentDurability ?? item.maxDurability ?? 100;
    final max = item.maxDurability ?? 100;
    final percentage = current / max;
    
    Color durabilityColor;
    if (percentage > 0.6) {
      durabilityColor = Colors.green;
    } else if (percentage > 0.3) {
      durabilityColor = Colors.orange;
    } else {
      durabilityColor = Colors.red;
    }
    
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
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

  Widget _buildInventorySection() {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'INVENTAR',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  Text(
                    '${widget.unequippedItems.length} Gegenstände',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Grid-Layout für Inventar-Items
              Expanded(
                child: widget.unequippedItems.isEmpty
                    ? _buildEmptyInventory()
                    : _buildInventoryGrid(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Gegenstände im Inventar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fügen Sie Gegenstände aus der Bibliothek hinzu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: widget.unequippedItems.length,
      itemBuilder: (context, index) {
        final displayItem = widget.unequippedItems[index];
        return _buildInventoryItem(displayItem);
      },
    );
  }

  Widget _buildInventoryItem(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final inventoryItem = displayItem.inventoryItem;
    
    return LongPressDraggable<DisplayInventoryItem>(
      data: displayItem,
      feedback: _buildDragFeedback(displayItem),
      childWhenDragging: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
      ),
      child: GestureDetector(
        onTap: () => widget.onManageItem(displayItem),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Item-Typ Icon
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _getItemTypeColor(item.itemType),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        _getItemTypeIcon(item.itemType),
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    
                    // Item-Name (gekürzt)
                    Expanded(
                      child: Text(
                        item.name.length > 12 
                            ? '${item.name.substring(0, 10)}...' 
                            : item.name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Menge
                    if (inventoryItem.quantity > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'x${inventoryItem.quantity}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
              // Rarity-Indicator
              if (item.rarity != null && item.rarity!.isNotEmpty)
                Positioned(
                  top: 2,
                  left: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getRarityColor(item.rarity!),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDragFeedback(DisplayInventoryItem displayItem) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.amber, width: 2),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getItemTypeIcon(displayItem.item.itemType),
                color: _getItemTypeColor(displayItem.item.itemType),
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                displayItem.item.name.length > 8 
                    ? '${displayItem.item.name.substring(0, 6)}...' 
                    : displayItem.item.name,
                style: const TextStyle(fontSize: 8),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleEquipItem(DisplayInventoryItem item, EquipSlot slot) {
    final canEquip = slot.allowedItemTypes.contains(item.item.itemType);
    if (canEquip) {
      widget.onEquipItem(item, slot);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.item.name} kann nicht in ${slot.displayName} ausgerüstet werden',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _getItemTypeColor(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return Colors.red;
      case ItemType.Armor:
        return Colors.blue;
      case ItemType.Shield:
        return Colors.cyan;
      case ItemType.AdventuringGear:
        return Colors.green;
      case ItemType.Treasure:
        return Colors.amber;
      case ItemType.MagicItem:
        return Colors.purple;
      case ItemType.SPELL_WEAPON:
        return Colors.deepPurple;
      case ItemType.Consumable:
        return Colors.orange;
      case ItemType.Tool:
        return Colors.brown;
      case ItemType.Material:
        return Colors.grey;
      case ItemType.Component:
        return Colors.teal;
      case ItemType.Scroll:
        return Colors.indigo;
      case ItemType.Potion:
        return Colors.pink;
      case ItemType.Currency:
        return Colors.yellow;
    }
  }

  IconData _getItemTypeIcon(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return Icons.gavel;
      case ItemType.Armor:
        return Icons.security;
      case ItemType.Shield:
        return Icons.shield;
      case ItemType.AdventuringGear:
        return Icons.backpack;
      case ItemType.Treasure:
        return Icons.monetization_on;
      case ItemType.MagicItem:
        return Icons.auto_awesome;
      case ItemType.SPELL_WEAPON:
        return Icons.flourescent;
      case ItemType.Consumable:
        return Icons.restaurant;
      case ItemType.Tool:
        return Icons.build;
      case ItemType.Material:
        return Icons.category;
      case ItemType.Component:
        return Icons.science;
      case ItemType.Scroll:
        return Icons.description;
      case ItemType.Potion:
        return Icons.local_drink;
      case ItemType.Currency:
        return Icons.attach_money;
    }
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey;
      case 'uncommon':
        return Colors.green;
      case 'rare':
        return Colors.blue;
      case 'very rare':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
