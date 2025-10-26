import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/inventory_item.dart';
import '../../models/equip_slot.dart';
import '../../screens/unified_character_editor_screen.dart';
import 'character_editor_controller.dart' show CharacterType;
import 'enhanced_inventory_tab_widget.dart';
import 'item_color_helper.dart';

class InventoryDemoWidget extends StatefulWidget {
  const InventoryDemoWidget({super.key});

  @override
  State<InventoryDemoWidget> createState() => _InventoryDemoWidgetState();
}

class _InventoryDemoWidgetState extends State<InventoryDemoWidget> {
  List<DisplayInventoryItem> _demoInventory = [];
  bool _isLoading = false;
  double _gold = 150.0;

  @override
  void initState() {
    super.initState();
    _generateDemoData();
  }

  void _generateDemoData() {
    setState(() {
      _isLoading = true;
    });

    // Demo-Items erstellen
    final items = [
      // Waffen
      Item(
        id: '1',
        name: 'Langschwert',
        description: 'Ein klassisches Langschwert aus geschmiedetem Stahl.',
        itemType: ItemType.Weapon,
        weight: 3.0,
        cost: 15.0,
        damage: '1d8 schl.',
        properties: 'Vielseitig, Schwer',
        rarity: 'Common',
      ),
      
      // Magische Waffe mit Bild
      Item(
        id: '2',
        name: 'Flammenschwert',
        description: 'Ein Schwert, das mit magischem Feuer erfüllt ist.',
        itemType: ItemType.Weapon,
        weight: 3.0,
        cost: 200.0,
        damage: '1d8 schl. + 1d6 Feuer',
        properties: 'Vielseitig, Schwer',
        rarity: 'Rare',
        requiresAttunement: true,
        imageUrl: 'https://picsum.photos/seed/flamesword/200/200.jpg',
      ),
      
      // Rüstung
      Item(
        id: '3',
        name: 'Kettenhemd',
        description: 'Aus miteinander verbundenen Metalldrähten gefertigte Rüstung.',
        itemType: ItemType.Armor,
        weight: 20.0,
        cost: 50.0,
        acFormula: '16',
        strengthRequirement: 13,
        stealthDisadvantage: true,
        rarity: 'Common',
      ),
      
      // Magische Rüstung
      Item(
        id: '4',
        name: 'Robe des Erzmagiers',
        description: 'Eine majestätische Robe, die mit arkanen Symbolen bestickt ist.',
        itemType: ItemType.Armor,
        weight: 2.0,
        cost: 1500.0,
        acFormula: '15 + Zaubergrad',
        rarity: 'Very Rare',
        requiresAttunement: true,
      ),
      
      // Schild
      Item(
        id: '5',
        name: 'Holzschild',
        description: 'Ein einfacher runder Holzschild.',
        itemType: ItemType.Shield,
        weight: 6.0,
        cost: 10.0,
        acFormula: '+2',
        rarity: 'Common',
      ),
      
      // Tränke
      Item(
        id: '6',
        name: 'Heiltrank',
        description: 'Ein roter, leicht glühender Trank in einer kleinen Glasflasche.',
        itemType: ItemType.Potion,
        weight: 0.5,
        cost: 50.0,
        rarity: 'Uncommon',
      ),
      
      // Schriftrolle
      Item(
        id: '7',
        name: 'Feuerball-Schriftrolle',
        description: 'Eine Schriftrolle mit dem Feuerball-Zauber.',
        itemType: ItemType.Scroll,
        weight: 0.1,
        cost: 150.0,
        rarity: 'Rare',
      ),
      
      // Zauber
      Item(
        id: '8',
        name: 'Magische Rakete',
        description: 'Ein Zauber, der mehrere magische Geschosse abfeuert.',
        itemType: ItemType.SPELL_WEAPON,
        weight: 0.0,
        cost: 0.0,
        spellLevel: 3,
        spellSchool: 'Evocation',
        isCantrip: false,
        requiresConcentration: false,
        rarity: 'Rare',
      ),
      
      // Werkzeug
      Item(
        id: '9',
        name: 'Diebeswerkzeug',
        description: 'Ein Satz von Spezialwerkzeugen für Diebstähle.',
        itemType: ItemType.Tool,
        weight: 1.0,
        cost: 25.0,
        rarity: 'Common',
      ),
      
      // Schatz
      Item(
        id: '10',
        name: 'Juwelenbesetzter Dolch',
        description: 'Ein Dolch mit einem wertvollen Edelstein am Griff.',
        itemType: ItemType.Treasure,
        weight: 1.0,
        cost: 500.0,
        rarity: 'Rare',
      ),
    ];

    // Inventory-Items erstellen
    _demoInventory = items.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;
      
      // Einige Items bereits ausrüsten
      final isEquipped = index < 3;
      EquipSlot? equipSlot;
      if (isEquipped) {
        if (index == 0) equipSlot = EquipSlot.mainHand;
        if (index == 1) equipSlot = EquipSlot.offHand;
        if (index == 2) equipSlot = EquipSlot.chest;
      }

      // Einige Items mit Menge > 1
      final quantity = (item.itemType == ItemType.Potion) ? 3 : 1;

      return DisplayInventoryItem(
        inventoryItem: InventoryItem(
          id: 'inv_${item.id}',
          ownerId: 'demo_character',
          itemId: item.id,
          quantity: quantity,
          isEquipped: isEquipped,
          equipSlot: equipSlot,
        ),
        item: item,
        currentDurability: item.hasDurability == true ? 
            (item.maxDurability != null ? (item.maxDurability! * 0.7).round() : null) : null,
      );
    }).toList();

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade900,
      appBar: AppBar(
        title: const Text('Inventar Demo'),
        backgroundColor: Colors.grey.shade800,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _generateDemoData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Demo-Daten neu laden',
          ),
        ],
      ),
      body: EnhancedInventoryTabWidget(
        characterType: CharacterType.npc, // NPCs können bearbeitet werden
        inventory: _demoInventory,
        isLoadingInventory: _isLoading,
        gold: _gold,
        onGoldChanged: (value) {
          setState(() {
            _gold = value;
          });
        },
        onAddItem: () {
          _showSnackBar('Item hinzufügen - Funktion demo');
        },
        onLoadInventory: () {
          _showSnackBar('Inventar neu geladen');
        },
        onManageItem: (displayItem) {
          _showSnackBar('Item verwalten: ${displayItem.item.name}');
        },
        onUpdateQuantity: (displayItem, newQuantity) {
          setState(() {
            final index = _demoInventory.indexWhere(
              (item) => item.inventoryItem.id == displayItem.inventoryItem.id,
            );
            if (index != -1) {
              final oldInvItem = _demoInventory[index].inventoryItem;
              _demoInventory[index] = DisplayInventoryItem(
                inventoryItem: InventoryItem(
                  id: oldInvItem.id,
                  ownerId: oldInvItem.ownerId,
                  itemId: oldInvItem.itemId,
                  quantity: newQuantity,
                  isEquipped: oldInvItem.isEquipped,
                  equipSlot: oldInvItem.equipSlot,
                ),
                item: _demoInventory[index].item,
                currentDurability: _demoInventory[index].currentDurability,
              );
            }
          });
          _showSnackBar('Menge aktualisiert: $newQuantity');
        },
        onRemoveItem: (displayItem) {
          setState(() {
            _demoInventory.removeWhere(
              (item) => item.inventoryItem.id == displayItem.inventoryItem.id,
            );
          });
          _showSnackBar('Item entfernt: ${displayItem.item.name}');
        },
        pcId: null,
        creatureId: 'demo_character',
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue.shade700,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
