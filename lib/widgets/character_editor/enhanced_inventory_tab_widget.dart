import 'package:flutter/material.dart';
import '../../models/inventory_item.dart';
import '../../models/equip_slot.dart';
import '../../models/item.dart';
import '../character_editor/character_editor_controller.dart'
    show CharacterType;
import 'enhanced_inventory_grid_widget.dart';
import 'item_detail_panel.dart';
import 'item_color_helper.dart';
import '../../viewmodels/character_editor_viewmodel.dart';

/// Refactored EnhancedInventoryTabWidget mit CharacterEditorViewModel
/// Entfernt direkte Datenbankzugriffe und Business-Logik aus UI
class EnhancedInventoryTabWidget extends StatefulWidget {
  final CharacterType characterType;
  final String? pcId;
  final String? creatureId;
  final CharacterEditorViewModel? viewModel;

  const EnhancedInventoryTabWidget({
    super.key,
    required this.characterType,
    this.pcId,
    this.creatureId,
    this.viewModel,
  });

  @override
  State<EnhancedInventoryTabWidget> createState() => _EnhancedInventoryTabWidgetState();
}

class _EnhancedInventoryTabWidgetState extends State<EnhancedInventoryTabWidget>
    with TickerProviderStateMixin {
  bool _isGridView = true;
  DisplayInventoryItem? _selectedCard;
  bool _showDetailPanel = false;
  
  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

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
    final viewModel = widget.viewModel;
    if (viewModel == null) {
      return const Center(
        child: Text(
          'ViewModel nicht verfügbar',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return Stack(
      children: [
        // Hauptinhalt
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Gold-Management (nur für NPCs/Monster)
              if (widget.characterType != CharacterType.player)
                _buildGoldSection(viewModel),
              if (widget.characterType != CharacterType.player) const SizedBox(height: 16),
              
              // Ansichts-Wechsel und Hinzufügen-Button
              _buildHeader(viewModel),
              const SizedBox(height: 16),
              
              // Inventar-Ansicht
              Expanded(
                child: viewModel.isLoading
                    ? _buildLoadingIndicator()
                    : _isGridView
                        ? _buildEnhancedGridView(viewModel)
                        : _buildListView(viewModel),
              ),
            ],
          ),
        ),
        
        // Detail-Panel (von rechts einschiebend)
        if (_showDetailPanel && _selectedCard != null)
          _buildAnimatedDetailPanel(viewModel),
      ],
    );
  }

  Widget _buildGoldSection(CharacterEditorViewModel viewModel) {
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
                initialValue: widget.characterType == CharacterType.player 
                    ? viewModel.playerCharacter?.gold.toString() ?? '0'
                    : viewModel.creature?.gold.toString() ?? '0',
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
                onChanged: (value) {
                  if (viewModel.isPlayerCharacter && viewModel.playerCharacter != null) {
                    // Player Characters werden über ViewModel aktualisiert
                    // TODO: Implementiere updateGold in ViewModel
                  } else if (!viewModel.isPlayerCharacter && viewModel.creature != null) {
                    // NPCs/Monster werden über Service aktualisiert
                    // TODO: Implementiere updateCreatureGold in ViewModel
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CharacterEditorViewModel viewModel) {
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
        if (_canAddItems(viewModel))
          ElevatedButton.icon(
            onPressed: () => _handleAddItem(viewModel),
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

  Widget _buildEnhancedGridView(CharacterEditorViewModel viewModel) {
    final separatedItems = viewModel.equippedAndUnequippedItems;
    
    // Konvertiere InventoryItem zu DisplayInventoryItem mit echten Item-Details
    final equippedDisplayItems = separatedItems.equipped.map((invItem) {
      final item = viewModel.getItemDetails(invItem.itemId) ?? _createFallbackItem(invItem);
      return DisplayInventoryItem(inventoryItem: invItem, item: item);
    }).toList();
    
    final unequippedDisplayItems = separatedItems.unequipped.map((invItem) {
      final item = viewModel.getItemDetails(invItem.itemId) ?? _createFallbackItem(invItem);
      return DisplayInventoryItem(inventoryItem: invItem, item: item);
    }).toList();
    
    return EnhancedInventoryGridWidget(
      equippedItems: equippedDisplayItems,
      unequippedItems: unequippedDisplayItems,
      onEquipItem: (displayItem, slot) => _handleEquipItem(displayItem, slot, viewModel),
      onUnequipItem: (displayItem) => _handleUnequipItem(displayItem, viewModel),
      onManageItem: (displayItem) => _handleInventoryItemTap(displayItem, viewModel),
      onUpdateQuantity: (displayItem, quantity) => _handleUpdateQuantity(displayItem, quantity, viewModel),
      onRemoveItem: (displayItem) => _handleRemoveItem(displayItem, viewModel),
      canEditItems: _canEditItems(viewModel),
      selectedCard: _selectedCard,
    );
  }

  Widget _buildListView(CharacterEditorViewModel viewModel) {
    final separatedItems = viewModel.equippedAndUnequippedItems;
    final equippedItems = separatedItems.equipped;
    final unequippedItems = separatedItems.unequipped;
    
    // Konvertiere zu DisplayInventoryItem mit echten Item-Details
    final equippedDisplayItems = equippedItems.map((invItem) {
      final item = viewModel.getItemDetails(invItem.itemId) ?? _createFallbackItem(invItem);
      return DisplayInventoryItem(inventoryItem: invItem, item: item);
    }).toList();
    
    final unequippedDisplayItems = unequippedItems.map((invItem) {
      final item = viewModel.getItemDetails(invItem.itemId) ?? _createFallbackItem(invItem);
      return DisplayInventoryItem(inventoryItem: invItem, item: item);
    }).toList();
    
    return Card(
      color: Colors.grey.shade800,
      child: Column(
        children: [
          // Ausrüstungs-Bereich in Listenansicht
          if (equippedDisplayItems.isNotEmpty) ...[
            _buildEquippedItemsList(equippedDisplayItems, viewModel),
            Divider(color: Colors.grey.shade600),
          ],
          
          // Inventar-Liste
          Expanded(
            child: unequippedDisplayItems.isEmpty
                ? _buildEmptyInventory()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: unequippedDisplayItems.length,
                    itemBuilder: (context, index) {
                      final displayItem = unequippedDisplayItems[index];
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
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Menge anzeigen für alle
                              if (invItem.quantity > 1)
                                Text(
                                  "x${invItem.quantity}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                               
                              // Mengen-Editor nur für NPCs/Monster
                              if (widget.characterType != CharacterType.player) ...[
                                const SizedBox(width: 8),
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
                                        onPressed: () => _handleUpdateQuantity(displayItem, invItem.quantity - 1, viewModel),
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
                                        onPressed: () => _handleUpdateQuantity(displayItem, invItem.quantity + 1, viewModel),
                                        padding: const EdgeInsets.all(4),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                               
                              // Equip-Button für alle Charaktere
                              if (!displayItem.inventoryItem.isEquipped) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  onPressed: () => _showEquipDialog(displayItem, viewModel),
                                  tooltip: 'Ausrüsten',
                                ),
                              ],
                               
                              // Delete-Button nur für NPCs/Monster
                              if (widget.characterType != CharacterType.player) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _handleRemoveItem(displayItem, viewModel),
                                ),
                              ],
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

  Widget _buildEquippedItemsList(List<DisplayInventoryItem> equippedItems, CharacterEditorViewModel viewModel) {
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
                        onPressed: () => _handleUnequipItem(displayItem, viewModel),
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

  Widget _buildAnimatedDetailPanel(CharacterEditorViewModel viewModel) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: ItemDetailPanel(
          displayItem: _selectedCard!,
          isVisible: _showDetailPanel,
          canEdit: _canEditItems(viewModel),
          onClose: _closeDetailPanel,
          onEquip: _selectedCard?.inventoryItem.isEquipped == false 
              ? () => _showEquipDialog(_selectedCard!, viewModel) 
              : null,
          onUnequip: _selectedCard?.inventoryItem.isEquipped == true 
              ? () => _handleUnequipItem(_selectedCard!, viewModel) 
              : null,
          onEdit: _canEditItems(viewModel) 
              ? () {
                  _closeDetailPanel();
                  _handleManageItem(_selectedCard!);
                } 
              : null,
          onDelete: _canEditItems(viewModel) 
              ? () {
                  _closeDetailPanel();
                  _handleRemoveItem(_selectedCard!, viewModel);
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

  Future<void> _handleEquipItem(DisplayInventoryItem displayItem, EquipSlot? slot, CharacterEditorViewModel viewModel) async {
    if (!_canEditItems(viewModel)) return;
    
    try {
      await viewModel.equipItem(displayItem.inventoryItem.id, slot!);
      _showSuccessSnackBar('${displayItem.item.name} ausgerüstet');
    } catch (e) {
      _showErrorSnackBar('Fehler beim Ausrüsten: $e');
    }
  }

  Future<void> _handleUnequipItem(DisplayInventoryItem displayItem, CharacterEditorViewModel viewModel) async {
    if (!_canEditItems(viewModel)) return;

    try {
      await viewModel.unequipItem(displayItem.inventoryItem.id);
      _showSuccessSnackBar('${displayItem.item.name} abgelegt');
    } catch (e) {
      _showErrorSnackBar('Fehler beim Ablegen: $e');
    }
  }

  Future<void> _handleUpdateQuantity(DisplayInventoryItem displayItem, int newQuantity, CharacterEditorViewModel viewModel) async {
    if (!_canEditItems(viewModel)) return;

    try {
      await viewModel.updateItemQuantity(displayItem.inventoryItem.id, newQuantity);
    } catch (e) {
      _showErrorSnackBar('Fehler beim Aktualisieren der Menge: $e');
    }
  }

  Future<void> _handleRemoveItem(DisplayInventoryItem displayItem, CharacterEditorViewModel viewModel) async {
    if (!_canEditItems(viewModel)) return;

    try {
      await viewModel.removeItem(displayItem.inventoryItem.id);
      _showSuccessSnackBar('${displayItem.item.name} entfernt');
    } catch (e) {
      _showErrorSnackBar('Fehler beim Entfernen: $e');
    }
  }

  /// Handelt Taps auf Inventar-Items in der Rasteransicht
  /// - Nicht ausgerüstet: Öffnet Equip-Dialog
  /// - Bereits ausgerüstet: Legt Item sofort ab
  void _handleInventoryItemTap(DisplayInventoryItem displayItem, CharacterEditorViewModel viewModel) {
    print('👆 [EnhancedInventoryTabWidget] Item angeklickt: ${displayItem.item.name}');
    print('  - isEquipped: ${displayItem.inventoryItem.isEquipped}');
    print('  - equipSlot: ${displayItem.inventoryItem.equipSlot}');
    
    if (displayItem.inventoryItem.isEquipped) {
      // Item ist bereits ausgerüstet → Ablegen
      print('👆 [EnhancedInventoryTabWidget] Item ist ausgerüstet → lege ab');
      _handleUnequipItem(displayItem, viewModel);
    } else {
      // Item ist nicht ausgerüstet → Equip-Dialog zeigen
      print('👆 [EnhancedInventoryTabWidget] Item ist nicht ausgerüstet → zeige Equip-Dialog');
      _showEquipDialog(displayItem, viewModel);
    }
  }

  Future<void> _showEquipDialog(DisplayInventoryItem displayItem, CharacterEditorViewModel viewModel) async {
    final item = displayItem.item;
    final availableSlots = viewModel.getAvailableEquipSlots(item);

    if (availableSlots.isEmpty) {
      _showErrorSnackBar('${item.name} kann nicht ausgerüstet werden');
      return;
    }

    final selectedSlot = await showDialog<EquipSlot?>(
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
      await _handleEquipItem(displayItem, selectedSlot, viewModel);
    }
  }

  Future<void> _handleAddItem(CharacterEditorViewModel viewModel) async {
    if (!_canAddItems(viewModel)) return;

    final characterId = viewModel.isPlayerCharacter 
        ? viewModel.playerCharacter?.id 
        : viewModel.creature?.id;

    if (characterId == null) {
      _showErrorSnackBar('Character nicht gefunden');
      return;
    }

    // TODO: Item-Add-Funktion wird noch migriert
    // Platzhalter für zukünftige Implementierung
    _showErrorSnackBar('Item-Add-Funktion wird noch migriert');
    
    /*
    // Zeige Item Bibliothek für Auswahl
    final result = await Navigator.of(context).push<Map<String, dynamic>>(
      MaterialPageRoute(
        builder: (context) => AddItemScreen(
          characterId: characterId!,
        ),
      ),
    );

    // Wenn Item ausgewählt wurde, lade Inventar neu
    if (result != null) {
      // ViewModel sollte automatisch durch Listener aktualisiert werden
    }
    */
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

  bool _canAddItems(CharacterEditorViewModel viewModel) {
    if (widget.characterType == CharacterType.player) {
      return viewModel.playerCharacter != null;
    } else {
      return viewModel.creature != null;
    }
  }

  bool _canEditItems(CharacterEditorViewModel viewModel) {
    // Player-Characters können ihre Items ausrüsten/ablegen, aber nicht Menge bearbeiten
    // NPCs/Monster können vom DM vollständig bearbeitet werden (Menge, Ausrüstung, etc.)
    return true; // Alle können Items ausrüsten
  }

  /// Erstellt ein Fallback-Item wenn die Details nicht gefunden wurden
  Item _createFallbackItem(InventoryItem invItem) {
    print('=== FALLBACK ITEM CREATED ===');
    print('InventoryItem ID: ${invItem.id}');
    print('Item ID: ${invItem.itemId}');
    print('Inventory Name: ${invItem.name}');
    
    return Item(
      id: invItem.itemId,
      name: invItem.name.isNotEmpty ? invItem.name : 'Unbekannter Gegenstand',
      itemType: ItemType.AdventuringGear, // Default Typ
      weight: 1.0,
      description: invItem.description ?? '',
    );
  }
}