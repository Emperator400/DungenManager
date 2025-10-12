// lib/screens/item_library_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/item.dart';
import 'edit_item_screen.dart';

class ItemLibraryScreen extends StatefulWidget {
  const ItemLibraryScreen({super.key});

  @override
  State<ItemLibraryScreen> createState() => _ItemLibraryScreenState();
}

class _ItemLibraryScreenState extends State<ItemLibraryScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Item>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = dbHelper.getAllItems();
  }

  void _refreshList() {
    setState(() {
      _itemsFuture = dbHelper.getAllItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Ausrüstungskammer")),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                title: Text(item.name),
                subtitle: Text(item.itemType.toString().split('.').last),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => EditItemScreen(itemToEdit: item)));
                  _refreshList();
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const EditItemScreen()));
          _refreshList();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}