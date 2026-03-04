import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/inventory_item.dart';
import '../../models/equip_slot.dart';
import 'item_card_widget.dart';
import 'item_color_helper.dart';

class EnhancedInventoryGridWidget extends StatefulWidget {
  final List<DisplayInventoryItem> equippedItems;
  final List<DisplayInventoryItem> unequippedItems;
  final Function(DisplayInventoryItem, EquipSlot?) onEquipItem;
  final Function(DisplayInventoryItem) onUnequipItem;
  final Function(DisplayInventoryItem) onManageItem;
  final Function(DisplayInventoryItem, int) onUpdateQuantity;
  final Function(DisplayInventoryItem) onRemoveItem;
  final bool canEditItems;
  final DisplayInventoryItem? selectedCard;

  const EnhancedInventoryGridWidget({
    super.key,
    required this.equippedItems,
    required this.unequippedItems,
    required this.onEquipItem,
    required this.onUnequipItem,
    required this.onManageItem,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    this.canEditItems = true,
    this.selectedCard,
  });

  @override
  State<EnhancedInventoryGridWidget> createState() => _EnhancedInventoryGridWidgetState();
}

class _EnhancedInventoryGridWidgetState extends State<EnhancedInventoryGridWidget>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  
  // Ausrüstungs-Slots nach Kategorien gruppiert
  Map<String, List<EquipSlot>> get categorizedSlots => {
    'Waffen': [EquipSlot.mainHand, EquipSlot.offHand, EquipSlot.ranged],
    'Zauber': [EquipSlot.spellActive, EquipSlot.cantripReady, EquipSlot.spellPrepared1, EquipSlot.spellPrepared2, EquipSlot.spellPrepared3, EquipSlot.spellPrepared4],
    'Rüstung': [EquipSlot.head, EquipSlot.chest, EquipSlot.hands, EquipSlot.feet, EquipSlot.cloak],
    'Accessoires': [EquipSlot.ring1, EquipSlot.ring2, EquipSlot.amulet, EquipSlot.belt],
  };

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Linke Seite: Inventar
        Expanded(
          flex: 2,
          child: _buildInventorySection(),
        ),
        const SizedBox(width: 16),
        // Rechte Seite: Ausrüstung
        Expanded(
          flex: 1,
          child: _buildEquipmentSection(),
        ),
      ],
    );
  }

  Widget _buildEquipmentSection() {
    return Card(
      color: Colors.grey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AUSRÜSTUNG',
              style: const TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            
            // Ausrüstungs-Kategorien in SingleChildScrollView für Overflow-Prävention
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
            ),
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
          style: TextStyle(
            fontSize: 14, 
            fontWeight: FontWeight.w600, 
            color: Colors.grey.shade400,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
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
          characterId: '',
          itemId: '',
          isEquipped: false,
          equipSlot: slot,
        ),
        item: Item(
          id: '',
          name: '',
          itemType: ItemType.AdventuringGear,
        ),
        currentDurability: null,
      ),
    );

    // Entferne DragTarget - verursacht ParentDataWidget Exception
    return Container(
      width: 85,
      height: 85,
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.grey.shade600,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
        color: equippedItem.item.id.isNotEmpty 
            ? Colors.amber.shade800.withOpacity(0.3)
            : Colors.grey.shade700,
      ),
      child: Stack(
        children: [
          // Slot-Icon
          if (equippedItem.item.id.isEmpty)
            Center(
              child: Icon(
                _getEquipSlotIcon(slot),
                size: 20,
                color: Colors.grey.shade500,
              ),
            ),
          
          // Ausgerüstetes Item
          if (equippedItem.item.id.isNotEmpty)
            _buildEquippedItemCompact(equippedItem),
          
          // Remove-Button (nur wenn editierbar)
          if (equippedItem.item.id.isNotEmpty && widget.canEditItems)
            Positioned(
              top: 2,
              right: 2,
              child: GestureDetector(
                onTap: () => widget.onUnequipItem(equippedItem),
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEquippedItemCompact(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    
    return Padding(
      padding: const EdgeInsets.all(2.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Item-Typ Icon
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: ItemColorHelper.getItemTypeColor(item.itemType),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              ItemColorHelper.getItemTypeIcon(item.itemType),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(height: 2),
          
          // Item-Name (gekürzt)
          Flexible(
            child: Text(
              item.name.length > 8 
                  ? '${item.name.substring(0, 6)}..' 
                  : item.name,
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Durability-Indikator (wenn vorhanden)
          if (item.hasDurability == true && displayItem.currentDurability != null)
            Padding(
              padding: const EdgeInsets.only(top: 2.0),
              child: _buildCompactDurabilityIndicator(displayItem),
            ),
        ],
      ),
    );
  }

  Widget _buildCompactDurabilityIndicator(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final current = displayItem.currentDurability ?? item.maxDurability ?? 100;
    final max = item.maxDurability ?? 100;
    final percentage = current / max;
    
    Color durabilityColor = ItemColorHelper.getDurabilityColor(percentage);
    
    return Container(
      width: 24,
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
            color: durabilityColor,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }

  Widget _buildDurabilityIndicator(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final current = displayItem.currentDurability ?? item.maxDurability ?? 100;
    final max = item.maxDurability ?? 100;
    final percentage = current / max;
    
    Color durabilityColor = ItemColorHelper.getDurabilityColor(percentage);
    
    return Container(
      width: 32,
      height: 3,
      decoration: BoxDecoration(
        color: Colors.grey.shade600,
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
    // Berechne Gesamtgewicht und Gesamtwert
    final totalWeight = _calculateTotalWeight();
    final totalValue = _calculateTotalValue();
    
    return Card(
      color: Colors.grey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'INVENTAR',
                  style: const TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const Spacer(),
                // Icon-Legende Button
                IconButton(
                  onPressed: _showIconLegend,
                  icon: Icon(
                    Icons.help_outline,
                    color: Colors.grey.shade400,
                  ),
                  tooltip: 'Icon-Legende',
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.unequippedItems.length} Gegenstände',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Inventar-Statistik
            _buildInventoryStats(totalWeight, totalValue),
            const SizedBox(height: 16),
            
            // Grid-Layout für Inventar-Items
            Expanded(
              child: widget.unequippedItems.isEmpty
                  ? _buildEmptyInventory()
                  : _buildResponsiveInventoryGrid(),
            ),
          ],
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
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Gegenstände im Inventar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
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

  Widget _buildResponsiveInventoryGrid() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive Spaltenanzahl basierend auf verfügbarer Breite
        int crossAxisCount;
        if (constraints.maxWidth < 500) {
          crossAxisCount = 3;
        } else if (constraints.maxWidth < 700) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth < 1000) {
          crossAxisCount = 5;
        } else {
          crossAxisCount = 6;
        }

        return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 120 / 150, // Verhältnis der Item-Karten
          ),
          itemCount: widget.unequippedItems.length,
          itemBuilder: (context, index) {
            final displayItem = widget.unequippedItems[index];
            final isSelected = widget.selectedCard?.inventoryItem.id == displayItem.inventoryItem.id;
            
            return ItemCardWidget(
              displayItem: displayItem,
              onTap: () => widget.onManageItem(displayItem),
              isDraggable: widget.canEditItems,
              isSelected: isSelected,
            );
          },
        );
      },
    );
  }

  IconData _getEquipSlotIcon(EquipSlot slot) {
    switch (slot) {
      case EquipSlot.mainHand:
        return Icons.sports_martial_arts;
      case EquipSlot.offHand:
        return Icons.back_hand;
      case EquipSlot.ranged:
        return Icons.gps_fixed;
      case EquipSlot.head:
        return Icons.face;
      case EquipSlot.chest:
        return Icons.accessibility_new;
      case EquipSlot.hands:
        return Icons.back_hand;
      case EquipSlot.feet:
        return Icons.directions_walk;
      case EquipSlot.cloak:
        return Icons.umbrella;
      case EquipSlot.ring1:
      case EquipSlot.ring2:
        return Icons.radio_button_unchecked;
      case EquipSlot.amulet:
        return Icons.circle;
      case EquipSlot.belt:
        return Icons.line_style;
      case EquipSlot.spellActive:
        return Icons.auto_fix_high;
      case EquipSlot.cantripReady:
        return Icons.wb_sunny;
      case EquipSlot.spellPrepared1:
      case EquipSlot.spellPrepared2:
      case EquipSlot.spellPrepared3:
      case EquipSlot.spellPrepared4:
        return Icons.book;
    }
  }

  double _calculateTotalWeight() {
    return widget.unequippedItems.fold(0.0, (sum, displayItem) {
      return sum + (displayItem.item.weight * displayItem.inventoryItem.quantity);
    });
  }

  double _calculateTotalValue() {
    return widget.unequippedItems.fold(0.0, (sum, displayItem) {
      return sum + (displayItem.item.cost * displayItem.inventoryItem.quantity);
    });
  }

  Widget _buildInventoryStats(double totalWeight, double totalValue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Gesamtgewicht
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.fitness_center,
                      size: 16,
                      color: Colors.blue.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Gesamtgewicht',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalWeight.toStringAsFixed(1)} lbs',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Gesamtwert
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.monetization_on,
                      size: 16,
                      color: Colors.amber.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Gesamtwert',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${totalValue.toStringAsFixed(0)} Gold',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showIconLegend() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.grey.shade800,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Container(
            width: 500,
            height: 600,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.help_outline,
                      color: Colors.white,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Item-Typen Legende',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Item-Typen Legende
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendSection('Waffen & Kampf', [
                          ItemType.Weapon,
                          ItemType.Shield,
                          ItemType.SPELL_WEAPON,
                        ]),
                        const SizedBox(height: 16),
                        _buildLegendSection('Rüstung & Schutz', [
                          ItemType.Armor,
                        ]),
                        const SizedBox(height: 16),
                        _buildLegendSection('Magie & Zauber', [
                          ItemType.MagicItem,
                          ItemType.Scroll,
                          ItemType.Potion,
                        ]),
                        const SizedBox(height: 16),
                        _buildLegendSection('Werkzeug & Material', [
                          ItemType.Tool,
                          ItemType.Material,
                          ItemType.Component,
                        ]),
                        const SizedBox(height: 16),
                        _buildLegendSection('Verschiedenes', [
                          ItemType.Consumable,
                          ItemType.Treasure,
                          ItemType.Currency,
                          ItemType.AdventuringGear,
                        ]),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLegendSection(String title, List<ItemType> types) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade300,
          ),
        ),
        const SizedBox(height: 8),
        ...types.map((type) => _buildLegendItem(type)).toList(),
      ],
    );
  }

  Widget _buildLegendItem(ItemType type) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: ItemColorHelper.getItemTypeColor(type),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              ItemColorHelper.getItemTypeIcon(type),
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              ItemColorHelper.getItemTypeDisplayName(type),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
          ),
        ],
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
}
