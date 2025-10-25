import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/item.dart';
import 'edit_item_screen.dart';

class ItemLibraryScreen extends StatefulWidget {
  final bool selectMode; // NEU: Auswahl-Modus für Inventar
  const ItemLibraryScreen({super.key, this.selectMode = false});

  @override
  State<ItemLibraryScreen> createState() => _ItemLibraryScreenState();
}

class _ItemLibraryScreenState extends State<ItemLibraryScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Item>> _itemsFuture;
  String _searchQuery = '';
  ItemType? _selectedType;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  Future<List<Item>> _loadItems() async {
    final allItems = await dbHelper.getAllItems();
    
    // Filter anwenden
    var filteredItems = allItems.where((item) {
      // Suchfilter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        if (!item.name.toLowerCase().contains(searchLower)) return false;
      }
      
      // Typ-Filter
      if (_selectedType != null && item.itemType != _selectedType) return false;
      
      return true;
    }).toList();
    
    return filteredItems;
  }

  void _refreshList() {
    setState(() {
      _itemsFuture = _loadItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.selectMode ? "Gegenstand auswählen" : "Ausrüstungskammer"),
        bottom: widget.selectMode ? null : PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                // Suchfeld
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Suchen...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                    _refreshList();
                  },
                ),
                const SizedBox(height: 8),
                // Typ-Filter
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      FilterChip(
                        label: const Text('Alle'),
                        selected: _selectedType == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedType = selected ? null : _selectedType;
                          });
                          _refreshList();
                        },
                      ),
                      ...ItemType.values.map((type) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: FilterChip(
                          label: Text(_getItemTypeDisplayName(type)),
                          selected: _selectedType == type,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = selected ? type : null;
                            });
                            _refreshList();
                          },
                        ),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: FutureBuilder<List<Item>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final items = snapshot.data!;
          
          if (items.isEmpty) {
            return const Center(
              child: Text(
                'Keine Gegenstände gefunden\n\nErstellen Sie neue Gegenstände in der Ausrüstungskammer',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            );
          }
          
          return ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getItemTypeColor(item.itemType),
                    child: Icon(
                      _getItemTypeIcon(item.itemType),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_getItemTypeDisplayName(item.itemType)),
                      if (item.weight > 0) Text('${item.weight} Pfund'),
                      if (item.cost > 0) Text('${item.cost.toStringAsFixed(2)} Gold'),
                    ],
                  ),
                  trailing: widget.selectMode 
                      ? const Icon(Icons.add_circle, color: Colors.green)
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (item.rarity != null && item.rarity!.isNotEmpty)
                              Chip(
                                label: Text(item.rarity!),
                                backgroundColor: _getRarityColor(item.rarity!),
                                labelStyle: const TextStyle(color: Colors.white),
                              ),
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () async {
                                await Navigator.of(context).push(
                                  MaterialPageRoute(builder: (ctx) => EditItemScreen(itemToEdit: item))
                                );
                                _refreshList();
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Gegenstand löschen"),
                                    content: Text("Möchtest du '${item.name}' wirklich löschen?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text("Abbrechen"),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                                        child: const Text("Löschen"),
                                      ),
                                    ],
                                  ),
                                );
                                
                                if (confirmed == true) {
                                  await dbHelper.deleteItem(item.id);
                                  _refreshList();
                                }
                              },
                            ),
                          ],
                        ),
                  onTap: () async {
                    if (widget.selectMode) {
                      Navigator.of(context).pop(item);
                    } else {
                      await Navigator.of(context).push(
                        MaterialPageRoute(builder: (ctx) => EditItemScreen(itemToEdit: item))
                      );
                      _refreshList();
                    }
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.selectMode ? null : FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const EditItemScreen()));
          _refreshList();
        },
        child: const Icon(Icons.add),
      ),
    );
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
