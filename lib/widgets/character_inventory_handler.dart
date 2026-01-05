// lib/widgets/character_inventory_handler.dart
import 'package:flutter/material.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/inventory_item_model_repository.dart';
import '../models/inventory_item.dart';

/// Character Inventory Handler
/// 
/// Widget zur Verwaltung des Character Inventars.
/// HINWEIS: Dies ist eine Demo-Implementierung mit eingeschränkter Funktionalität.
/// Für die vollständige Funktionalität muss ein InventoryService erstellt werden.
class CharacterInventoryHandler extends StatefulWidget {
  final String characterId;
  final Function()? onItemTap;

  const CharacterInventoryHandler({
    super.key,
    required this.characterId,
    this.onItemTap,
  });

  @override
  State<CharacterInventoryHandler> createState() => _CharacterInventoryHandlerState();
}

class _CharacterInventoryHandlerState extends State<CharacterInventoryHandler> {
  late final InventoryItemModelRepository _inventoryRepository;

  @override
  void initState() {
    super.initState();
    _inventoryRepository = InventoryItemModelRepository(DatabaseConnection.instance);
  }

  Future<List<InventoryItem>> _loadInventory() async {
    try {
      final items = await _inventoryRepository.findByCharacter(widget.characterId);
      return items;
    } catch (e) {
      // Bei Fehlern leere Liste zurückgeben
      return <InventoryItem>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<InventoryItem>>(
      future: _loadInventory(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final items = snapshot.data!;
        if (items.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text('Keine Gegenstände im Inventar'),
                  const SizedBox(height: 8),
                  const Text(
                    'Demo-Modus',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final itemName = item.itemId ?? 'Unbekannt';
                  return ListTile(
                    leading: const Icon(Icons.inventory),
                    title: Text(itemName),
                    subtitle: Text('Menge: ${item.quantity}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () {
                        // Demo: Zeigt nur eine Nachricht
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gegenstand entfernen (Demo)'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
