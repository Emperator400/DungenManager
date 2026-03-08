import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/inventory_item_repository.dart';
import '../../database/entities/inventory_item_entity.dart';
import '../../models/inventory_item.dart';
import '../../viewmodels/character_editor_viewmodel.dart';
import 'character_editor_controller.dart'
    show CharacterType;
import 'enhanced_character_editor_controller.dart'
    show EnhancedCharacterEditorController;

class CharacterInventoryHandler {
  final EnhancedCharacterEditorController controller;
  final BuildContext context;
  final VoidCallback onInventoryChanged;
  final InventoryItemRepository _inventoryRepository;
  final CharacterEditorViewModel? _viewModel;

  CharacterInventoryHandler({
    required this.controller,
    required this.context,
    required this.onInventoryChanged,
    CharacterEditorViewModel? viewModel,
  }) : _inventoryRepository = InventoryItemRepository(DatabaseConnection.instance),
       _viewModel = viewModel;

  Future<void> addItemFromLibrary() async {
    String? characterId;
    
    if (controller.characterType == CharacterType.player) {
      characterId = controller.pcToEdit?.id;
    } else {
      characterId = controller.creatureToEdit?.id;
    }
    
    if (characterId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bitte speichern Sie zuerst den Charakter')),
      );
      return;
    }

    // Die Navigation zu Item-Screens wird noch migriert
    // Platzhalter für zukünftige Implementierung
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item-Add-Funktion wird noch migriert')),
    );
    
    await loadInventory();
  }

  Future<void> loadInventory() async {
    try {
      print('=== LOAD INVENTORY DEBUG ===');
      print('CharacterType: ${controller.characterType}');
      print('ViewModel verfügbar: ${_viewModel != null}');
      
      // Wenn ViewModel verfügbar ist, lade darüber
      if (_viewModel != null) {
        if (controller.characterType == CharacterType.player) {
          final pcId = controller.pcToEdit?.id;
          if (pcId != null) {
            print('Lade Player Character Inventory: $pcId');
            await _viewModel!.initWithPlayerCharacter(pcId);
          }
        } else {
          final creatureId = controller.creatureToEdit?.id;
          if (creatureId != null) {
            print('Lade Creature Inventory: $creatureId');
            await _viewModel!.initWithCreature(creatureId);
          }
        }
      } else {
        print('WARNUNG: Kein ViewModel verfügbar!');
      }
      
      onInventoryChanged();
      print('Inventar neu geladen');
    } catch (e) {
      print('=== LOAD INVENTORY ERROR ===');
      print('Error: $e');
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Inventars: $e')),
        );
      }
    }
  }

  Future<void> showManageItemDialog(DisplayInventoryItem displayItem) async {
    final quantityController = TextEditingController(text: displayItem.inventoryItem.quantity.toString());
    
    // Konvertiere Model zu Entity für Repository-Operationen
    final inventoryItemEntity = InventoryItemEntity.fromModel(displayItem.inventoryItem);
    
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
                await _inventoryRepository.delete(displayItem.inventoryItem.id);
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
                final updatedEntity = inventoryItemEntity.copyWith(quantity: newQuantity);
                await _inventoryRepository.update(updatedEntity);
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
      // Konvertiere Model zu Entity für Repository-Operationen
      final inventoryItemEntity = InventoryItemEntity.fromModel(displayItem.inventoryItem);
      final updatedEntity = inventoryItemEntity.copyWith(quantity: newQuantity);
      await _inventoryRepository.update(updatedEntity);
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
      print('=== REMOVE ITEM DEBUG ===');
      print('InventoryItem ID: ${displayItem.inventoryItem.id}');
      print('InventoryItem Name: ${displayItem.inventoryItem.name}');
      print('Repository: ${_inventoryRepository.runtimeType}');
      
      await _inventoryRepository.delete(displayItem.inventoryItem.id);
      print('Item erfolgreich gelöscht');
      
      await loadInventory();
      print('Inventar neu geladen');

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${displayItem.item.name} wurde entfernt')),
        );
      }
    } catch (e, stackTrace) {
      print('=== REMOVE ITEM ERROR ===');
      print('Error: $e');
      print('StackTrace: $stackTrace');
      
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
    String? characterId,
    String? itemId,
    String? name,
    String? description,
    int? quantity,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      characterId: characterId ?? this.characterId,
      itemId: itemId ?? this.itemId,
      name: name ?? this.name,
      description: description ?? this.description,
      quantity: quantity ?? this.quantity,
    );
  }
}