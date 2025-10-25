import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/inventory_item.dart';
import '../../models/equip_slot.dart';
import '../../database/database_helper.dart';
import '../../screens/item_library_screen.dart';
import '../../screens/add_item_from_library_screen.dart';
import '../../screens/unified_character_editor_screen.dart';
import 'inventory_grid_widget.dart';

class InventoryTabWidget extends StatefulWidget {
  final CharacterType characterType;
  final List<DisplayInventoryItem> inventory;
  final bool isLoadingInventory;
  final double gold;
  final Function(double) onGoldChanged;
  final VoidCallback onAddItem;
  final VoidCallback onLoadInventory;
  final Function(DisplayInventoryItem) onManageItem;
  final Function(DisplayInventoryItem, int) onUpdateQuantity;
  final Function(DisplayInventoryItem) onRemoveItem;
  final String? pcId;
  final String? creatureId;

  const InventoryTabWidget({
    super.key,
    required this.characterType,
    required this.inventory,
    required this.isLoadingInventory,
    required this.gold,
    required this.onGoldChanged,
    required this.onAddItem,
    required this.onLoadInventory,
    required this.onManageItem,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    this.pcId,
    this.creatureId,
  });

  @override
  State<InventoryTabWidget> createState() => _InventoryTabWidgetState();
}

class _InventoryTabWidgetState extends State<InventoryTabWidget> {
  final dbHelper = DatabaseHelper.instance;
  bool _isGridView = true;

  // Trenne ausgerüstete und nicht ausgerüstete Items
  List<DisplayInventoryItem> get equippedItems => 
      widget.inventory.where((item) => item.inventoryItem.isEquipped).toList();
  
  List<DisplayInventoryItem> get unequippedItems => 
      widget.inventory.where((item) => !item.inventoryItem.isEquipped).toList();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Gold-Management (nur für NPCs/Monster)
          if (widget.characterType != CharacterType.player)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Colors.amber),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: widget.gold.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Goldstücke',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) => widget.onGoldChanged(double.tryParse(value) ?? 0.0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.characterType != CharacterType.player) const SizedBox(height: 16),
          
          // Ansichts-Wechsel und Hinzufügen-Button
          Row(
            children: [
              Text(
                'Inventar',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Ansichts-Wechsel
              IconButton(
                onPressed: () => setState(() => _isGridView = !_isGridView),
                icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
                tooltip: _isGridView ? 'Listenansicht' : 'Rasteransicht',
              ),
              // Gegenstand hinzufügen
              if (_canAddItems())
                ElevatedButton.icon(
                  onPressed: widget.onAddItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Hinzufügen'),
                ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Inventar-Ansicht
          Expanded(
            child: widget.isLoadingInventory
                ? const Center(child: CircularProgressIndicator())
                : _isGridView
                    ? _buildGridView()
                    : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return InventoryGridWidget(
      equippedItems: equippedItems,
      unequippedItems: unequippedItems,
      onEquipItem: _handleEquipItem,
      onUnequipItem: _handleUnequipItem,
      onManageItem: widget.onManageItem,
      onUpdateQuantity: widget.onUpdateQuantity,
      onRemoveItem: widget.onRemoveItem,
      canEditItems: _canEditItems(),
    );
  }

  Widget _buildListView() {
    return Card(
      child: Column(
        children: [
          // Ausrüstungs-Bereich in Listenansicht
          if (equippedItems.isNotEmpty) ...[
            _buildEquippedItemsList(),
            const Divider(),
          ],
          
          // Inventar-Liste
          Expanded(
            child: unequippedItems.isEmpty
                ? const Center(
                    child: Text(
                      'Keine Gegenstände im Inventar\n\nFügen Sie Gegenstände aus der Bibliothek hinzu',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: unequippedItems.length,
                    itemBuilder: (context, index) {
                      final displayItem = unequippedItems[index];
                      final item = displayItem.item;
                      final invItem = displayItem.inventoryItem;
                      
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getItemTypeColor(item.itemType),
                          child: Icon(
                            _getItemTypeIcon(item.itemType),
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        title: Text(item.name),
                        subtitle: Text('${_getItemTypeDisplayName(item.itemType)} • ${item.weight} Pfund'),
                        trailing: widget.characterType == CharacterType.player
                            ? Text("x${invItem.quantity}")
                            : Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Mengen-Editor für NPCs/Monster
                                  SizedBox(
                                    width: 100,
                                    child: Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.remove, size: 20),
                                          onPressed: () => widget.onUpdateQuantity(displayItem, invItem.quantity - 1),
                                        ),
                                        Text(
                                          invItem.quantity.toString(),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.add, size: 20),
                                          onPressed: () => widget.onUpdateQuantity(displayItem, invItem.quantity + 1),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Equip-Button für NPCs/Monster
                                  IconButton(
                                    icon: const Icon(Icons.check, color: Colors.green),
                                    onPressed: () => _showEquipDialog(displayItem),
                                    tooltip: 'Ausrüsten',
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => widget.onRemoveItem(displayItem),
                                  ),
                                ],
                              ),
                        onTap: () => widget.onManageItem(displayItem),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquippedItemsList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ausgerüstet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...equippedItems.map((displayItem) {
            final item = displayItem.item;
            final slot = displayItem.inventoryItem.equipSlot;
            
            return ListTile(
              dense: true,
              leading: CircleAvatar(
                backgroundColor: _getItemTypeColor(item.itemType),
                child: Icon(
                  _getItemTypeIcon(item.itemType),
                  color: Colors.white,
                  size: 16,
                ),
              ),
              title: Text(item.name),
              subtitle: Text(slot?.displayName ?? 'Unbekannter Slot'),
              trailing: widget.characterType != CharacterType.player
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: () => _handleUnequipItem(displayItem),
                      tooltip: 'Ablegen',
                    )
                  : null,
            );
          }).toList(),
        ],
      ),
    );
  }

  Future<void> _handleEquipItem(DisplayInventoryItem displayItem, EquipSlot? slot) async {
    if (!_canEditItems()) return;
    
    final ownerId = widget.pcId ?? widget.creatureId;
    if (ownerId == null) return;

    try {
      // Prüfen, ob das Item in den Slot kann
      if (slot != null) {
        final canEquip = await dbHelper.canEquipInSlot(displayItem.item.id, slot);
        if (!canEquip) {
          _showErrorSnackBar('${displayItem.item.name} kann nicht in ${slot.displayName} ausgerüstet werden');
          return;
        }
      }

      // Item ausrüsten
      await dbHelper.equipItem(displayItem.inventoryItem.id, slot!);
      
      // Inventory neu laden
      widget.onLoadInventory();
      
      _showSuccessSnackBar('${displayItem.item.name} ausgerüstet');
    } catch (e) {
      _showErrorSnackBar('Fehler beim Ausrüsten: $e');
    }
  }

  Future<void> _handleUnequipItem(DisplayInventoryItem displayItem) async {
    if (!_canEditItems()) return;

    try {
      // Item unequirüsten
      await dbHelper.unequipItem(displayItem.inventoryItem.id);
      
      // Inventory neu laden
      widget.onLoadInventory();
      
      _showSuccessSnackBar('${displayItem.item.name} abgelegt');
    } catch (e) {
      _showErrorSnackBar('Fehler beim Ablegen: $e');
    }
  }

  Future<void> _showEquipDialog(DisplayInventoryItem displayItem) async {
    final item = displayItem.item;
    final availableSlots = EquipSlot.values.where((slot) => 
        slot.allowedItemTypes.contains(item.itemType)).toList();

    if (availableSlots.isEmpty) {
      _showErrorSnackBar('${item.name} kann nicht ausgerüstet werden');
      return;
    }

    final selectedSlot = await showDialog<EquipSlot>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${item.name} ausrüsten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableSlots.map((slot) => ListTile(
            leading: Text(slot.iconName),
            title: Text(slot.displayName),
            onTap: () => Navigator.of(context).pop(slot),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );

    if (selectedSlot != null) {
      await _handleEquipItem(displayItem, selectedSlot);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  bool _canAddItems() {
    if (widget.characterType == CharacterType.player) {
      return widget.pcId != null;
    } else {
      return widget.creatureId != null;
    }
  }

  bool _canEditItems() {
    // Player-Characters können ihre Items nicht bearbeiten (nur ansehen)
    // NPCs/Monster können vom DM bearbeitet werden
    return widget.characterType != CharacterType.player;
  }

  String _getItemTypeDisplayName(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return 'Waffe';
      case ItemType.Armor:
        return 'Rüstung';
      case ItemType.AdventuringGear:
        return 'Ausrüstung';
      case ItemType.Treasure:
        return 'Schatz';
      case ItemType.MagicItem:
        return 'Magisches Item';
    }
  }

  Color _getItemTypeColor(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return Colors.red;
      case ItemType.Armor:
        return Colors.blue;
      case ItemType.AdventuringGear:
        return Colors.green;
      case ItemType.Treasure:
        return Colors.amber;
      case ItemType.MagicItem:
        return Colors.purple;
    }
  }

  IconData _getItemTypeIcon(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return Icons.gavel;
      case ItemType.Armor:
        return Icons.security;
      case ItemType.AdventuringGear:
        return Icons.backpack;
      case ItemType.Treasure:
        return Icons.monetization_on;
      case ItemType.MagicItem:
        return Icons.auto_awesome;
    }
  }
}
