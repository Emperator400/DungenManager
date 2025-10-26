import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/inventory_item.dart';
import '../../models/equip_slot.dart';
import '../../database/database_helper.dart';
import '../../screens/item_library_screen.dart';
import '../../screens/add_item_from_library_screen.dart';
import '../character_editor/character_editor_controller.dart'
    show CharacterType;
import 'enhanced_inventory_grid_widget.dart';
import 'item_detail_panel.dart';
import 'item_color_helper.dart';

class EnhancedInventoryTabWidget extends StatefulWidget {
  final CharacterType characterType;
  final List<DisplayInventoryItem> inventory;
  final bool isLoadingInventory;
  final double gold;
  final Function(double) onGoldChanged;
  final VoidCallback onAddItem;
  final VoidCallback onLoadInventory;
  final Function(DisplayInventoryItem) onManageItem;
  final Function(DisplayInventoryItem, int) onUpdateQuantity;
  final Function(DisplayInventoryItem) onRemoveItem;
  final String? pcId;
  final String? creatureId;

  const EnhancedInventoryTabWidget({
    super.key,
    required this.characterType,
    required this.inventory,
    required this.isLoadingInventory,
    required this.gold,
    required this.onGoldChanged,
    required this.onAddItem,
    required this.onLoadInventory,
    required this.onManageItem,
    required this.onUpdateQuantity,
    required this.onRemoveItem,
    this.pcId,
    this.creatureId,
  });

  @override
  State<EnhancedInventoryTabWidget> createState() => _EnhancedInventoryTabWidgetState();
}

class _EnhancedInventoryTabWidgetState extends State<EnhancedInventoryTabWidget>
    with TickerProviderStateMixin {
  final dbHelper = DatabaseHelper.instance;
  bool _isGridView = true;
  DisplayInventoryItem? _selectedCard;
  bool _showDetailPanel = false;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Trenne ausgerüstete und nicht ausgerüstete Items
  List<DisplayInventoryItem> get equippedItems => 
      widget.inventory.where((item) => item.inventoryItem.isEquipped).toList();
  
  List<DisplayInventoryItem> get unequippedItems => 
      widget.inventory.where((item) => !item.inventoryItem.isEquipped).toList();

  @override
  void initState() {
    super.initState();
    
    // Slide-Animation für das Detail-Panel
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeInOut,
    ));
    
    // Fade-Animation für den Overlay-Hintergrund
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Hauptinhalt
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Gold-Management (nur für NPCs/Monster)
              if (widget.characterType != CharacterType.player)
                _buildGoldSection(),
              if (widget.characterType != CharacterType.player) const SizedBox(height: 16),
              
              // Ansichts-Wechsel und Hinzufügen-Button
              _buildHeader(),
              const SizedBox(height: 16),
              
              // Inventar-Ansicht
              Expanded(
                child: widget.isLoadingInventory
                    ? _buildLoadingIndicator()
                    : _isGridView
                        ? _buildEnhancedGridView()
                        : _buildListView(),
              ),
            ],
          ),
        ),
        
        // Detail-Panel (von rechts einschiebend)
        if (_showDetailPanel && _selectedCard != null)
          _buildAnimatedDetailPanel(),
      ],
    );
  }

  Widget _buildGoldSection() {
    return Card(
      color: Colors.grey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                initialValue: widget.gold.toString(),
                decoration: InputDecoration(
                  labelText: 'Goldstücke',
                  labelStyle: TextStyle(color: Colors.grey.shade400),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.grey.shade600),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.amber.shade600),
                  ),
                ),
                style: const TextStyle(color: Colors.white),
                keyboardType: TextInputType.number,
                onChanged: (value) => widget.onGoldChanged(double.tryParse(value) ?? 0.0),
              ),
            ),
          ],
        ),
      ),
  );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(
          'Inventar',
          style: const TextStyle(
            fontSize: 20, 
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        
        // Ansichts-Wechsel
        Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade700,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              _buildViewButton(
                icon: Icons.grid_view,
                isActive: _isGridView,
                onTap: () => setState(() => _isGridView = true),
                tooltip: 'Rasteransicht',
              ),
              _buildViewButton(
                icon: Icons.list,
                isActive: !_isGridView,
                onTap: () => setState(() => _isGridView = false),
                tooltip: 'Listenansicht',
              ),
            ],
          ),
        ),
        
        const SizedBox(width: 12),
        
        // Gegenstand hinzufügen
        if (_canAddItems())
          ElevatedButton.icon(
            onPressed: widget.onAddItem,
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Hinzufügen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
          ),
      ],
    );
  }

  Widget _buildViewButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isActive ? Colors.blue.shade700 : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? Colors.white : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(
        color: Colors.white,
      ),
    );
  }

  Widget _buildEnhancedGridView() {
    return EnhancedInventoryGridWidget(
      equippedItems: equippedItems,
      unequippedItems: unequippedItems,
      onEquipItem: _handleEquipItem,
      onUnequipItem: _handleUnequipItem,
      onManageItem: _handleManageItem,
      onUpdateQuantity: widget.onUpdateQuantity,
      onRemoveItem: widget.onRemoveItem,
      canEditItems: _canEditItems(),
      selectedCard: _selectedCard,
    );
  }

  Widget _buildListView() {
    return Card(
      color: Colors.grey.shade800,
      child: Column(
        children: [
          // Ausrüstungs-Bereich in Listenansicht
          if (equippedItems.isNotEmpty) ...[
            _buildEquippedItemsList(),
            Divider(color: Colors.grey.shade600),
          ],
          
          // Inventar-Liste
          Expanded(
            child: unequippedItems.isEmpty
                ? _buildEmptyInventory()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: unequippedItems.length,
                    itemBuilder: (context, index) {
                      final displayItem = unequippedItems[index];
                      final item = displayItem.item;
                      final invItem = displayItem.inventoryItem;
                       
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: ItemColorHelper.getItemTypeColor(item.itemType),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              ItemColorHelper.getItemTypeIcon(item.itemType),
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            '${ItemColorHelper.getItemTypeDisplayName(item.itemType)} • ${item.weight} Pfund',
                            style: TextStyle(
                              color: Colors.grey.shade400,
                            ),
                          ),
                          trailing: widget.characterType == CharacterType.player
                              ? Text(
                                  "x${invItem.quantity}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Mengen-Editor für NPCs/Monster
                                    Container(
                                      width: 100,
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade600,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, size: 16, color: Colors.white),
                                            onPressed: () => widget.onUpdateQuantity(displayItem, invItem.quantity - 1),
                                            padding: const EdgeInsets.all(4),
                                          ),
                                          Expanded(
                                            child: Text(
                                              invItem.quantity.toString(),
                                              textAlign: TextAlign.center,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, size: 16, color: Colors.white),
                                            onPressed: () => widget.onUpdateQuantity(displayItem, invItem.quantity + 1),
                                            padding: const EdgeInsets.all(4),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Equip-Button für NPCs/Monster
                                    IconButton(
                                      icon: const Icon(Icons.check, color: Colors.green),
                                      onPressed: () => _showEquipDialog(displayItem),
                                      tooltip: 'Ausrüsten',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => widget.onRemoveItem(displayItem),
                                    ),
                                  ],
                                ),
                          onTap: () => _handleManageItem(displayItem),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEquippedItemsList() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ausgerüstet',
            style: const TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          ...equippedItems.map((displayItem) {
            final item = displayItem.item;
            final slot = displayItem.inventoryItem.equipSlot;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade700,
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListTile(
                dense: true,
                leading: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: ItemColorHelper.getItemTypeColor(item.itemType),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    ItemColorHelper.getItemTypeIcon(item.itemType),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  slot?.displayName ?? 'Unbekannter Slot',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                  ),
                ),
                trailing: widget.characterType != CharacterType.player
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _handleUnequipItem(displayItem),
                        tooltip: 'Ablegen',
                      )
                    : null,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildEmptyInventory() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 64,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Gegenstände im Inventar',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade400,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Fügen Sie Gegenstände aus der Bibliothek hinzu',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedDetailPanel() {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ItemDetailPanel(
          displayItem: _selectedCard!,
          isVisible: _showDetailPanel,
          canEdit: _canEditItems(),
          onClose: _closeDetailPanel,
          onEquip: _selectedCard?.inventoryItem.isEquipped == false 
              ? () => _showEquipDialog(_selectedCard!) 
              : null,
          onUnequip: _selectedCard?.inventoryItem.isEquipped == true 
              ? () => _handleUnequipItem(_selectedCard!) 
              : null,
          onEdit: _canEditItems() 
              ? () {
                  _closeDetailPanel();
                  widget.onManageItem(_selectedCard!);
                } 
              : null,
          onDelete: _canEditItems() 
              ? () {
                  _closeDetailPanel();
                  widget.onRemoveItem(_selectedCard!);
                } 
              : null,
        ),
      ),
    );
  }

  void _handleManageItem(DisplayInventoryItem displayItem) {
    setState(() {
      _selectedCard = displayItem;
      _showDetailPanel = true;
    });
    
    // Animationen starten
    _fadeController.forward();
    _slideController.forward();
  }

  void _closeDetailPanel() {
    _fadeController.reverse().then((_) {
      _slideController.reverse().then((_) {
        setState(() {
          _showDetailPanel = false;
          _selectedCard = null;
        });
      });
    });
  }

  Future<void> _handleEquipItem(DisplayInventoryItem displayItem, EquipSlot? slot) async {
    if (!_canEditItems()) return;
    
    final ownerId = widget.pcId ?? widget.creatureId;
    if (ownerId == null) return;

    try {
      // Prüfen, ob das Item in den Slot kann
      if (slot != null) {
        final canEquip = await dbHelper.canEquipInSlot(displayItem.item.id, slot);
        if (!canEquip) {
          _showErrorSnackBar('${displayItem.item.name} kann nicht in ${slot.displayName} ausgerüstet werden');
          return;
        }
      }

      // Item ausrüsten
      await dbHelper.equipItem(displayItem.inventoryItem.id, slot!);
      
      // Inventory neu laden
      widget.onLoadInventory();
      
      _showSuccessSnackBar('${displayItem.item.name} ausgerüstet');
    } catch (e) {
      _showErrorSnackBar('Fehler beim Ausrüsten: $e');
    }
  }

  Future<void> _handleUnequipItem(DisplayInventoryItem displayItem) async {
    if (!_canEditItems()) return;

    try {
      // Item unequirüsten
      await dbHelper.unequipItem(displayItem.inventoryItem.id);
      
      // Inventory neu laden
      widget.onLoadInventory();
      
      _showSuccessSnackBar('${displayItem.item.name} abgelegt');
    } catch (e) {
      _showErrorSnackBar('Fehler beim Ablegen: $e');
    }
  }

  Future<void> _showEquipDialog(DisplayInventoryItem displayItem) async {
    final item = displayItem.item;
    final availableSlots = EquipSlot.values.where((slot) => 
        slot.allowedItemTypes.contains(item.itemType)).toList();

    if (availableSlots.isEmpty) {
      _showErrorSnackBar('${item.name} kann nicht ausgerüstet werden');
      return;
    }

    final selectedSlot = await showDialog<EquipSlot>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey.shade800,
        title: Text(
          '${item.name} ausrüsten',
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: availableSlots.map((slot) => ListTile(
            leading: Text(
              slot.iconName,
              style: const TextStyle(fontSize: 24, color: Colors.white),
            ),
            title: Text(
              slot.displayName,
              style: const TextStyle(color: Colors.white),
            ),
            onTap: () => Navigator.of(context).pop(slot),
          )).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
        ],
      ),
    );

    if (selectedSlot != null) {
      await _handleEquipItem(displayItem, selectedSlot);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green.shade700,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
      ),
    );
  }

  bool _canAddItems() {
    if (widget.characterType == CharacterType.player) {
      return widget.pcId != null;
    } else {
      return widget.creatureId != null;
    }
  }

  bool _canEditItems() {
    // Player-Characters können ihre Items nicht bearbeiten (nur ansehen)
    // NPCs/Monster können vom DM bearbeitet werden
    return widget.characterType != CharacterType.player;
  }
}
