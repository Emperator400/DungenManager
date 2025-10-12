// lib/screens/add_item_from_library_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/inventory_item.dart';
import '../models/item.dart'; // Wichtig: Wir verwenden jetzt das 'Item'-Modell

class AddItemFromLibraryScreen extends StatefulWidget {
  final String ownerId;
  const AddItemFromLibraryScreen({super.key, required this.ownerId});

  @override
  State<AddItemFromLibraryScreen> createState() => _AddItemFromLibraryScreenState();
}

class _AddItemFromLibraryScreenState extends State<AddItemFromLibraryScreen> {
  final dbHelper = DatabaseHelper.instance;

  // Die Logik zum Hinzufügen eines Items
  Future<void> _onItemTapped(Item item) async {
    final quantityController = TextEditingController(text: '1');
    final quantity = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Menge für '${item.name}'"),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Abbrechen")),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(quantityController.text) ?? 0;
              Navigator.of(ctx).pop(amount > 0 ? amount : null);
            },
            child: const Text("Hinzufügen"),
          ),
        ],
      ),
    );

    if (quantity != null && quantity > 0) {
      final newItem = InventoryItem(
        ownerId: widget.ownerId,
        itemId: item.id, // Verknüpfe mit der ID des ausgewählten Items
        quantity: quantity,
      );
      await dbHelper.insertInventoryItem(newItem);
      if(mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gegenstand aus Ausrüstungskammer wählen")),
      body: FutureBuilder<List<Item>>( // Wir erwarten jetzt eine Liste von 'Item'
        future: dbHelper.getAllItems(), // Wir rufen die korrekte Methode auf
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          if (items.isEmpty) return const Center(child: Text("Keine Gegenstände in der Ausrüstungskammer gefunden."));

          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: const Icon(Icons.shield_outlined),
                title: Text(item.name),
                subtitle: Text(item.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                onTap: () => _onItemTapped(item),
              );
            },
          );
        },
      ),
    );
  }
}