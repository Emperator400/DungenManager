import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/item.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/item_library_viewmodel.dart';
import 'edit_item_screen.dart';

class ItemLibraryScreen extends StatefulWidget {
  final bool selectMode; // Auswahl-Modus für Inventar
  
  const ItemLibraryScreen({
    super.key, 
    this.selectMode = false,
  });

  @override
  State<ItemLibraryScreen> createState() => _ItemLibraryScreenState();
}

class _ItemLibraryScreenState extends State<ItemLibraryScreen>
    with TickerProviderStateMixin {
  late ItemLibraryViewModel _viewModel;
  late TabController _tabController;
  String _searchQuery = '';
  ItemType? _selectedType;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ItemLibraryViewModel();
    _tabController = TabController(length: 4, vsync: this);
    _loadItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      await _viewModel.loadItems();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Items: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  List<Item> get _filteredItems {
    final allItems = _viewModel.items;
    
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
    _loadItems();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ItemLibraryViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: DnDTheme.dungeonBlack,
        appBar: AppBar(
          title: Text(
            widget.selectMode ? "Gegenstand auswählen" : "Ausrüstungskammer",
            style: DnDTheme.headline2.copyWith(
              color: DnDTheme.ancientGold,
            ),
          ),
          backgroundColor: widget.selectMode ? DnDTheme.arcaneBlue : DnDTheme.stoneGrey,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
          leading: widget.selectMode 
              ? Container(
                  margin: const EdgeInsets.only(left: DnDTheme.sm),
                  decoration: DnDTheme.getMysticalBorder(
                    borderColor: Colors.white,
                    width: 2,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                )
              : null,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: _buildSearchAndFilterBar(),
          ),
        ),
        body: Consumer<ItemLibraryViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: DnDTheme.ancientGold,
                    ),
                    const SizedBox(height: DnDTheme.md),
                    Text(
                      'Lade Ausrüstung...',
                      style: DnDTheme.bodyText1.copyWith(
                        color: DnDTheme.ancientGold,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (viewModel.error != null) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(DnDTheme.lg),
                  decoration: DnDTheme.getDungeonWallDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: DnDTheme.errorRed,
                        size: 48,
                      ),
                      const SizedBox(height: DnDTheme.md),
                      Text(
                        'Fehler beim Laden',
                        style: DnDTheme.headline3.copyWith(
                          color: DnDTheme.errorRed,
                        ),
                      ),
                      const SizedBox(height: DnDTheme.sm),
                      Text(
                        viewModel.error!,
                        style: DnDTheme.bodyText2.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DnDTheme.md),
                      ElevatedButton.icon(
                        onPressed: () {
                          viewModel.clearError();
                          _refreshList();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Erneut versuchen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DnDTheme.errorRed,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final filteredItems = _filteredItems;
            
            if (filteredItems.isEmpty) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(DnDTheme.lg),
                  decoration: DnDTheme.getDungeonWallDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inventory_2_outlined,
                        size: 64,
                        color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: DnDTheme.md),
                      Text(
                        (_searchQuery.isNotEmpty || _selectedType != null)
                            ? "Keine Gegenstände gefunden, die den Filterkriterien entsprechen."
                            : "Keine Gegenstände in der Ausrüstungskammer.\n\nErstelle neue Gegenstände für deine Abenteurer!",
                        style: DnDTheme.bodyText1.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_searchQuery.isNotEmpty || _selectedType != null)
                        Padding(
                          padding: const EdgeInsets.only(top: DnDTheme.md),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _selectedType = null;
                                _searchController.clear();
                              });
                              _refreshList();
                            },
                            icon: const Icon(Icons.clear),
                            label: const Text('Filter zurücksetzen'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DnDTheme.arcaneBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                gradient: DnDTheme.getMysticalGradient(
                  startColor: DnDTheme.dungeonBlack,
                  endColor: DnDTheme.stoneGrey,
                ),
              ),
              child: _buildItemList(filteredItems),
            );
          },
        ),
        floatingActionButton: widget.selectMode 
            ? null 
            : Container(
                decoration: DnDTheme.getMysticalBorder(
                  borderColor: DnDTheme.successGreen,
                  width: 3,
                ),
                child: FloatingActionButton.extended(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const EditItemScreen())
                    );
                    _refreshList();
                  },
                  backgroundColor: DnDTheme.successGreen,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.add),
                  label: const Text('Neues Item'),
                ),
              ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        border: Border(
          bottom: BorderSide(
            color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Suchleiste
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Ausrüstung suchen...',
              hintStyle: DnDTheme.bodyText2.copyWith(
                color: Colors.white54,
              ),
              prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: DnDTheme.errorRed),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        _refreshList();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(color: DnDTheme.mysticalPurple),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(
                  color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
              ),
              filled: true,
              fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
            ),
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              // Kleine Verzögerung für die Suche
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) _refreshList();
              });
            },
          ),
          
          const SizedBox(height: DnDTheme.sm),
          
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
                  color: DnDTheme.mysticalPurple,
                ),
                ...ItemType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: DnDTheme.xs),
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
    );
  }

  Widget _buildItemList(List<Item> items) {
    return ListView.builder(
      padding: const EdgeInsets.all(DnDTheme.sm),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: DnDTheme.sm),
          child: _buildItemCard(item),
        );
      },
    );
  }

  Widget _buildItemCard(Item item) {
    return Container(
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: _getItemTypeColor(item.itemType).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DnDTheme.md),
        leading: Container(
          decoration: BoxDecoration(
            color: _getItemTypeColor(item.itemType),
            shape: BoxShape.circle,
            border: Border.all(
              color: DnDTheme.ancientGold,
              width: 2,
            ),
          ),
          child: Icon(
            _getItemTypeIcon(item.itemType),
            color: Colors.white,
            size: 24,
          ),
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
                color: DnDTheme.ancientGold,
              ),
            ),
            Row(
              children: [
                if (item.weight > 0) ...[
                  Icon(
                    Icons.fitness_center,
                    size: 14,
                    color: DnDTheme.infoBlue,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.weight} Pfund',
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(width: DnDTheme.sm),
                ],
                if (item.cost > 0) ...[
                  Icon(
                    Icons.monetization_on,
                    size: 14,
                    color: DnDTheme.successGreen,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${item.cost.toStringAsFixed(2)} Gold',
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: widget.selectMode 
            ? Container(
                decoration: BoxDecoration(
                  color: DnDTheme.successGreen,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: DnDTheme.ancientGold,
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.add_circle,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (item.rarity != null && item.rarity!.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DnDTheme.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _getRarityColor(item.rarity!),
                        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                      ),
                      child: Text(
                        item.rarity!,
                        style: DnDTheme.caption.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  const SizedBox(width: DnDTheme.sm),
                  Container(
                    decoration: DnDTheme.getMysticalBorder(
                      borderColor: DnDTheme.arcaneBlue,
                      width: 2,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.edit, color: DnDTheme.arcaneBlue),
                      onPressed: () async {
                        await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (ctx) => EditItemScreen(item: item)
                          )
                        );
                        _refreshList();
                      },
                      tooltip: 'Bearbeiten',
                    ),
                  ),
                  const SizedBox(width: DnDTheme.xs),
                  Container(
                    decoration: DnDTheme.getMysticalBorder(
                      borderColor: DnDTheme.errorRed,
                      width: 2,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.delete, color: DnDTheme.errorRed),
                      onPressed: () => _showDeleteConfirmation(item),
                      tooltip: 'Löschen',
                    ),
                  ),
                ],
              ),
        onTap: () async {
          if (widget.selectMode) {
            Navigator.of(context).pop(item);
          } else {
            await Navigator.of(context).push(
              MaterialPageRoute(
                builder: (ctx) => EditItemScreen(item: item)
              )
            );
            _refreshList();
          }
        },
      ),
    );
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
        style: DnDTheme.bodyText2.copyWith(
          color: isSelected ? Colors.white : color,
          fontWeight: FontWeight.w600,
        ),
      ),
      selected: isSelected,
      onSelected: onSelected,
      backgroundColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
      selectedColor: color,
      checkmarkColor: Colors.white,
      side: BorderSide(
        color: isSelected ? color : color.withValues(alpha: 0.5),
        width: 1.5,
      ),
      elevation: isSelected ? 2 : 0,
      pressElevation: 4,
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
        return DnDTheme.errorRed;
      case ItemType.Armor:
        return DnDTheme.infoBlue;
      case ItemType.Shield:
        return DnDTheme.arcaneBlue;
      case ItemType.AdventuringGear:
        return DnDTheme.successGreen;
      case ItemType.Treasure:
        return DnDTheme.ancientGold;
      case ItemType.MagicItem:
        return DnDTheme.mysticalPurple;
      case ItemType.SPELL_WEAPON:
        return DnDTheme.arcaneBlue;
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
        return DnDTheme.successGreen;
      case 'rare':
        return DnDTheme.infoBlue;
      case 'very rare':
        return DnDTheme.mysticalPurple;
      case 'legendary':
        return DnDTheme.ancientGold;
      default:
        return Colors.grey;
    }
  }

  void _showDeleteConfirmation(Item item) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Gegenstand löschen',
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.errorRed,
          ),
        ),
        content: Text(
          "Möchtest du '${item.name}' wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.",
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _viewModel.deleteItem(item.id);
                _refreshList();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.name} wurde gelöscht'),
                      backgroundColor: DnDTheme.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Löschen: $e'),
                      backgroundColor: DnDTheme.errorRed,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
