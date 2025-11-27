import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/database_helper.dart';
import '../../models/inventory_item.dart';
import '../../models/item.dart';
import '../../screens/enhanced_item_library_screen.dart';
import '../../screens/add_item_from_library_screen.dart';
import '../../services/uuid_service.dart';
import 'character_editor_controller.dart'
    show CharacterType;
import 'enhanced_character_editor_controller.dart'
    show EnhancedCharacterEditorController;

class CharacterInventoryHandler {
  final EnhancedCharacterEditorController controller;
  final BuildContext context;
  final VoidCallback onInventoryChanged;

  CharacterInventoryHandler({
    required this.controller,
    required this.context,
    required this.onInventoryChanged,
  });

  Future<void> addItemFromLibrary() async {
    String? ownerId;
    
    if (controller.characterType == CharacterType.player) {
      ownerId = controller.pcToEdit?.id;
    } else {
      ownerId = controller.creatureToEdit?.id;
    }
    
    if (ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte speichern Sie zuerst den Charakter')),
      );
      return;
    }

    if (controller.characterType == CharacterType.player) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => AddItemFromLibraryScreen(ownerId: ownerId!),
        ),
      );
    } else {
      final selectedItem = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => const EnhancedItemLibraryScreen(selectMode: true),
        ),
      );

      if (selectedItem != null && selectedItem is Item) {
        final uuidService = UuidService();
        final inventoryItem = InventoryItem(
          id: uuidService.generateId(),
          ownerId: ownerId!,
          itemId: selectedItem.id,
          quantity: 1,
        );
        await DatabaseHelper.instance.insertInventoryItem(inventoryItem);
      }
    }
    
    await loadInventory();
  }

  Future<void> loadInventory() async {
    try {
      await controller.loadInventory();
      onInventoryChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Inventars: $e')),
        );
      }
    }
  }

  Future<void> showManageItemDialog(DisplayInventoryItem displayItem) async {
    final quantityController = TextEditingController(text: displayItem.inventoryItem.quantity.toString());
    final dbHelper = DatabaseHelper.instance;
    
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(displayItem.item.name),
        content: TextField(
          controller: quantityController,
          decoration: const InputDecoration(labelText: "Menge"),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              try {
                await dbHelper.deleteInventoryItem(displayItem.inventoryItem.id);
                if (context.mounted) Navigator.of(ctx).pop();
                await loadInventory();
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${displayItem.item.name} wurde entfernt')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Entfernen: $e')),
                  );
                }
              }
            },
            child: const Text("Löschen", style: TextStyle(color: Colors.redAccent)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final newQuantity = int.tryParse(quantityController.text) ?? 1;
                final updatedItem = InventoryItem(
                  id: displayItem.inventoryItem.id,
                  ownerId: displayItem.inventoryItem.ownerId,
                  itemId: displayItem.inventoryItem.itemId,
                  quantity: newQuantity,
                );
                await dbHelper.updateInventoryItem(updatedItem);
                if (context.mounted) Navigator.of(ctx).pop();
                await loadInventory();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fehler beim Aktualisieren: $e')),
                  );
                }
              }
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );
  }

  Future<void> updateItemQuantity(DisplayInventoryItem displayItem, int newQuantity) async {
    if (newQuantity <= 0) {
      await removeItem(displayItem);
      return;
    }

    try {
      final dbHelper = DatabaseHelper.instance;
      final updatedItem = displayItem.inventoryItem.copyWith(quantity: newQuantity);
      await dbHelper.updateInventoryItem(updatedItem);
      await loadInventory();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Aktualisieren: $e')),
        );
      }
    }
  }

  Future<void> removeItem(DisplayInventoryItem displayItem) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.deleteInventoryItem(displayItem.inventoryItem.id);
      await loadInventory();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${displayItem.item.name} wurde entfernt')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Entfernen: $e')),
        );
      }
    }
  }

  Future<void> importFromOfficialMonster() async {
    // Diese Methode wird vom Haupt-Screen implementiert
    // da sie Navigation zum OfficialMonstersScreen benötigt
  }
}

// Extension für InventoryItem copyWith
extension InventoryItemCopy on InventoryItem {
  InventoryItem copyWith({
    String? id,
    String? ownerId,
    String? itemId,
    int? quantity,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
    );
  }
}
