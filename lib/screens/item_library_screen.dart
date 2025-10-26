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
        title: Text(
          widget.selectMode ? "Gegenstand auswählen" : "Ausrüstungskammer",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: widget.selectMode ? Colors.blue.shade600 : Colors.deepPurple.shade600,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        bottom: widget.selectMode ? null : PreferredSize(
          preferredSize: const Size.fromHeight(80),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple.shade50, Colors.blue.shade50],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  // Suchfeld
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: const InputDecoration(
                        labelText: 'Suchen...',
                        prefixIcon: Icon(Icons.search, color: Colors.deepPurple),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                        _refreshList();
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Typ-Filter
                  SizedBox(
                    height: 40,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildFilterChip(
                          label: 'Alle',
                          isSelected: _selectedType == null,
                          onSelected: (selected) {
                            setState(() {
                              _selectedType = selected ? null : _selectedType;
                            });
                            _refreshList();
                          },
                          color: Colors.grey,
                        ),
                        ...ItemType.values.map((type) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            label: _getItemTypeDisplayName(type),
                            isSelected: _selectedType == type,
                            onSelected: (selected) {
                              setState(() {
                                _selectedType = selected ? type : null;
                              });
                              _refreshList();
                            },
                            color: _getItemTypeColor(type),
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
      case ItemType.Shield:
        return 'Schild';
      case ItemType.AdventuringGear:
        return 'Ausrüstung';
      case ItemType.Treasure:
        return 'Schatz';
      case ItemType.MagicItem:
        return 'Magisches Item';
      case ItemType.SPELL_WEAPON:
        return 'Zauber';
      case ItemType.Consumable:
        return 'Verbrauchbar';
      case ItemType.Tool:
        return 'Werkzeug';
      case ItemType.Material:
        return 'Material';
      case ItemType.Component:
        return 'Komponente';
      case ItemType.Scroll:
        return 'Schriftrolle';
      case ItemType.Potion:
        return 'Trank';
      case ItemType.Currency:
        return 'Währung';
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

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required Function(bool) onSelected,
    required Color color,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: Colors.white,
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? color : color.withOpacity(0.3),
        width: 1.5,
      ),
      elevation: isSelected ? 2 : 0,
      pressElevation: 4,
    );
  }
}
