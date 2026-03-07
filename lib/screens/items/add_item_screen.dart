import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/item.dart';
import '../../theme/dnd_theme.dart';
import '../../services/inventory_service.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';

/// Add Item From Library Screen
/// 
/// Screen zum Hinzufügen von Gegenständen aus der Ausrüstung zum Inventar.
/// Verwendet den InventoryService für vollständige Funktionalität.
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
    
    final quantity = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Menge für "${item.name}"',
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: DnDTheme.slateGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
              borderSide: const BorderSide(color: DnDTheme.mysticalPurple),
            ),
            hintText: 'Menge',
            hintStyle: DnDTheme.bodyText2.copyWith(
              color: Colors.white60,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = int.tryParse(quantityController.text) ?? 0;
              Navigator.of(ctx).pop(amount > 0 ? amount : null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.successGreen,
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
          SnackBarHelper.showSuccess(
            context,
            '$quantity× ${item.name} zum Inventar hinzugefügt',
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          SnackBarHelper.showError(context, 'Fehler beim Hinzufügen: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      appBar: AppBar(
        title: const Text(
          'Gegenstand aus Ausrüstung wählen',
          style: TextStyle(
            color: DnDTheme.ancientGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: DnDTheme.stoneGrey,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: FutureBuilder<List<Item>>(
              future: _itemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: DnDTheme.ancientGold,
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(DnDTheme.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            color: DnDTheme.errorRed,
                            size: 64,
                          ),
                          const SizedBox(height: DnDTheme.lg),
                          Text(
                            'Fehler beim Laden',
                            style: DnDTheme.headline2.copyWith(
                              color: DnDTheme.errorRed,
                            ),
                          ),
                          const SizedBox(height: DnDTheme.sm),
                          Text(
                            snapshot.error.toString(),
                            style: DnDTheme.bodyText1.copyWith(
                              color: Colors.white70,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: DnDTheme.xl),
                          ElevatedButton.icon(
                            onPressed: _loadItems,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Erneut versuchen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DnDTheme.arcaneBlue,
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
                    : items.where((item) =>
                        item.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(DnDTheme.xl),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: DnDTheme.mysticalPurple.withValues(alpha: 0.4),
                          ),
                          const SizedBox(height: DnDTheme.lg),
                          Text(
                            'Keine Gegenstände gefunden',
                            style: DnDTheme.bodyText1.copyWith(
                              color: Colors.white60,
                            ),
                          ),
                          if (_searchQuery.isNotEmpty) ...[
                            const SizedBox(height: DnDTheme.sm),
                            Text(
                              'Versuche eine andere Suche',
                              style: DnDTheme.bodyText2.copyWith(
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(DnDTheme.md),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    return _buildItemCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      color: DnDTheme.stoneGrey,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: 'Gegenstände durchsuchen...',
          hintStyle: DnDTheme.bodyText2.copyWith(
            color: Colors.white60,
          ),
          prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
          filled: true,
          fillColor: DnDTheme.slateGrey,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(DnDTheme.md),
        ),
        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildItemCard(Item item) {
    Color typeColor = DnDTheme.mysticalPurple;
    IconData typeIcon = Icons.inventory_2_outlined;
    
    switch (item.itemType) {
      case ItemType.Weapon:
        typeColor = DnDTheme.errorRed;
        typeIcon = Icons.gavel;
        break;
      case ItemType.Armor:
        typeColor = DnDTheme.arcaneBlue;
        typeIcon = Icons.shield;
        break;
      case ItemType.Shield:
        typeColor = DnDTheme.warningOrange;
        typeIcon = Icons.shield_outlined;
        break;
      case ItemType.Consumable:
        typeColor = DnDTheme.emeraldGreen;
        typeIcon = Icons.restaurant;
        break;
      case ItemType.Tool:
        typeColor = DnDTheme.warningOrange;
        typeIcon = Icons.build;
        break;
      case ItemType.MagicItem:
        typeColor = DnDTheme.ancientGold;
        typeIcon = Icons.auto_awesome;
        break;
      case ItemType.Potion:
        typeColor = DnDTheme.emeraldGreen;
        typeIcon = Icons.local_drink;
        break;
      case ItemType.Scroll:
        typeColor = DnDTheme.mysticalPurple;
        typeIcon = Icons.description;
        break;
      case ItemType.Treasure:
        typeColor = DnDTheme.ancientGold;
        typeIcon = Icons.diamond;
        break;
      case ItemType.Currency:
        typeColor = DnDTheme.successGreen;
        typeIcon = Icons.monetization_on;
        break;
      case ItemType.Material:
        typeColor = DnDTheme.warningOrange;
        typeIcon = Icons.science;
        break;
      case ItemType.Component:
        typeColor = DnDTheme.warningOrange;
        typeIcon = Icons.category;
        break;
      default:
        typeIcon = Icons.inventory_2_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DnDTheme.md),
        leading: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
            border: Border.all(
              color: typeColor,
              width: 2,
            ),
          ),
          child: Icon(typeIcon, color: typeColor, size: 24),
        ),
        title: Text(
          item.name,
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getItemTypeDisplayName(item.itemType),
              style: DnDTheme.bodyText2.copyWith(
                color: typeColor,
              ),
            ),
            if (item.description.isNotEmpty)
              Text(
                item.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white60,
                ),
              ),
            if (item.cost > 0)
              Text(
                '${item.cost.toStringAsFixed(2)} Gold',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
              ),
          ],
        ),
        trailing: Icon(
          Icons.add_circle,
          color: DnDTheme.successGreen,
          size: 32,
        ),
        onTap: () => _onItemTapped(item),
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
      case ItemType.Consumable:
        return 'Verbrauchsgegenstand';
      case ItemType.Tool:
        return 'Werkzeug';
      case ItemType.Material:
        return 'Material';
      case ItemType.Component:
        return 'Komponente';
      case ItemType.MagicItem:
        return 'Magischer Gegenstand';
      case ItemType.Scroll:
        return 'Schriftrolle';
      case ItemType.Potion:
        return 'Trank';
      case ItemType.Treasure:
        return 'Schatz';
      case ItemType.Currency:
        return 'Währung';
      case ItemType.AdventuringGear:
        return 'Ausrüstung';
      case ItemType.SPELL_WEAPON:
        return 'Zauberwaffe';
    }
  }
}
