import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/item.dart';
import '../../theme/app_theme.dart';
import '../../services/inventory_service.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';

class AddItemFromLibraryScreen extends StatefulWidget {
  final String characterId;
  const AddItemFromLibraryScreen({super.key, required this.characterId});

  @override
  State<AddItemFromLibraryScreen> createState() => _AddItemFromLibraryScreenState();
}

class _AddItemFromLibraryScreenState extends State<AddItemFromLibraryScreen> {
  late InventoryService _inventoryService;
  late Future<List<Item>> _itemsFuture;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _inventoryService = InventoryService();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _itemsFuture = _inventoryService.getAllItems();
    });
  }

  Future<void> _onItemTapped(Item item) async {
    final quantityController = TextEditingController(text: '1');
    final C = context.appColors;

    final quantity = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text(
          'Menge für "${item.name}"',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: C.amber),
        ),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          style: const TextStyle(fontSize: 16, color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: C.bgHover,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: C.border),
            ),
            hintText: 'Menge',
            hintStyle: const TextStyle(fontSize: 14, color: Colors.white60),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'Abbrechen',
              style: TextStyle(fontSize: 16, color: Color(0xFF7C3AED)),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(quantityController.text) ?? 0;
              Navigator.of(ctx).pop(amount > 0 ? amount : null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hinzufügen'),
          ),
        ],
      ),
    );

    if (quantity != null && quantity > 0) {
      try {
        await _inventoryService.addItemToInventory(
          characterId: widget.characterId,
          itemId: item.id,
          quantity: quantity,
        );
        if (mounted) {
          SnackBarHelper.showSuccess(context, '$quantity× ${item.name} zum Inventar hinzugefügt');
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) SnackBarHelper.showError(context, 'Fehler beim Hinzufügen: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(
          'Gegenstand aus Ausrüstung wählen',
          style: TextStyle(color: C.amber, fontWeight: FontWeight.bold),
        ),
        backgroundColor: C.bgPanel,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: FutureBuilder<List<Item>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                final C = context.appColors;
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator(color: C.amber));
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, color: C.red, size: 64),
                          const SizedBox(height: 24),
                          Text(
                            'Fehler beim Laden',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: C.red,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: const TextStyle(fontSize: 16, color: Colors.white70),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton.icon(
                            onPressed: _loadItems,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Erneut versuchen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: C.accent,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final items = snapshot.data ?? [];
                final filteredItems = _searchQuery.isEmpty
                    ? items
                    : items
                        .where((item) =>
                            item.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                        .toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'Keine Gegenstände gefunden',
                            style: TextStyle(fontSize: 16, color: C.textSoft),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Versuche eine andere Suche',
                              style: TextStyle(fontSize: 14, color: C.textSoft),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) => _buildItemCard(filteredItems[index]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(24),
      color: C.bgPanel,
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Gegenstände durchsuchen...',
          hintStyle: const TextStyle(fontSize: 14, color: Colors.white60),
          prefixIcon: Icon(Icons.search, color: C.amber),
          filled: true,
          fillColor: C.bgHover,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(16),
        ),
        style: const TextStyle(fontSize: 16, color: Colors.white),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    final C = context.appColors;
    Color typeColor = const Color(0xFF7C3AED);
    IconData typeIcon = Icons.inventory_2_outlined;

    switch (item.itemType) {
      case ItemType.Weapon:
        typeColor = C.red;
        typeIcon = Icons.gavel;
      case ItemType.Armor:
        typeColor = C.accent;
        typeIcon = Icons.shield;
      case ItemType.Shield:
        typeColor = const Color(0xFFEA580C);
        typeIcon = Icons.shield_outlined;
      case ItemType.Consumable:
        typeColor = C.green;
        typeIcon = Icons.restaurant;
      case ItemType.Tool:
        typeColor = const Color(0xFFEA580C);
        typeIcon = Icons.build;
      case ItemType.MagicItem:
        typeColor = C.amber;
        typeIcon = Icons.auto_awesome;
      case ItemType.Potion:
        typeColor = C.green;
        typeIcon = Icons.local_drink;
      case ItemType.Scroll:
        typeColor = const Color(0xFF7C3AED);
        typeIcon = Icons.description;
      case ItemType.Treasure:
        typeColor = C.amber;
        typeIcon = Icons.diamond;
      case ItemType.Currency:
        typeColor = C.green;
        typeIcon = Icons.monetization_on;
      case ItemType.Material:
        typeColor = const Color(0xFFEA580C);
        typeIcon = Icons.science;
      case ItemType.Component:
        typeColor = const Color(0xFFEA580C);
        typeIcon = Icons.category;
      default:
        typeIcon = Icons.inventory_2_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: C.bgHover,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(color: typeColor, width: 2),
          ),
          child: Icon(typeIcon, color: typeColor, size: 24),
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getItemTypeDisplayName(item.itemType),
              style: TextStyle(fontSize: 14, color: typeColor),
            ),
            if (item.description.isNotEmpty)
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: Colors.white60),
              ),
            if (item.cost > 0)
              Text(
                '${item.cost.toStringAsFixed(2)} Gold',
                style: TextStyle(fontSize: 14, color: C.amber),
              ),
          ],
        ),
        trailing: Icon(Icons.add_circle, color: C.green, size: 32),
        onTap: () => _onItemTapped(item),
      ),
    );
  }

  String _getItemTypeDisplayName(ItemType type) {
    return switch (type) {
      ItemType.Weapon => 'Waffe',
      ItemType.Armor => 'Rüstung',
      ItemType.Shield => 'Schild',
      ItemType.Consumable => 'Verbrauchsgegenstand',
      ItemType.Tool => 'Werkzeug',
      ItemType.Material => 'Material',
      ItemType.Component => 'Komponente',
      ItemType.MagicItem => 'Magischer Gegenstand',
      ItemType.Scroll => 'Schriftrolle',
      ItemType.Potion => 'Trank',
      ItemType.Treasure => 'Schatz',
      ItemType.Currency => 'Währung',
      ItemType.AdventuringGear => 'Ausrüstung',
      ItemType.SPELL_WEAPON => 'Zauberwaffe',
    };
  }
}
