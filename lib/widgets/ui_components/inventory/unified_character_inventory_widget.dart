import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';
import '../../../models/item.dart';
import '../../../models/equipment.dart';
import '../../../theme/dnd_theme.dart';
import '../cards/section_card_widget.dart';
import '../../character_editor/item_color_helper.dart';

/// Unified Character Inventory Widget
/// 
/// Eine integrierte UI-Komponente, die Ausrüstung und Inventar in einer einzigen
/// übersichtlichen Oberfläche vereint. Ideal für Character-Erstellung und -Bearbeitung.
/// 
/// ## Features
/// - ✅ Integrierte Ausrüstungs- und Inventar-Sektion
/// - ✅ Kompakte Ausrüstungs-Slots oben
/// - ✅ Grid/List Toggle für Inventar
/// - ✅ Filter nach Item-Typ
/// - ✅ Item-Details Panel
/// - ✅ Gold-Anzeige
/// - ✅ Konsistentes DnD Design
/// 
/// ## Beispiel
/// ```dart
/// UnifiedCharacterInventoryWidget(
///   inventoryItems: viewModel.inventory,
///   equipmentMap: viewModel.equipmentMap,
///   gold: viewModel.gold,
///   onEquipItem: (slot, displayItem) => viewModel.equipItem(slot, displayItem),
///   onUnequipItem: (slot) => viewModel.unequipItem(slot),
///   onAddItem: () => _addItemFromLibrary(),
///   onDeleteItem: (displayItem) => viewModel.removeInventoryItem(displayItem.inventoryItem.id),
///   onUpdateQuantity: (displayItem, quantity) => viewModel.updateItemQuantity(displayItem.inventoryItem.id, quantity),
/// )
/// ```
class UnifiedCharacterInventoryWidget extends StatefulWidget {
  // Daten
  final List<DisplayInventoryItem> inventoryItems;
  final Map<EquipmentSlot, DisplayInventoryItem?> equipmentMap;
  final int gold;
  final int? silver;
  final int? copper;

  // Callbacks
  final Function(EquipmentSlot slot, DisplayInventoryItem item)? onEquipItem;
  final Function(EquipmentSlot slot)? onUnequipItem;
  final VoidCallback? onAddItem;
  final Function(DisplayInventoryItem item)? onDeleteItem;
  final Function(DisplayInventoryItem item, int quantity)? onUpdateQuantity;

  // Optionen
  final bool showGold;
  final bool allowQuantityEdit;
  final bool allowDelete;
  final bool isEditable;

  const UnifiedCharacterInventoryWidget({
    super.key,
    required this.inventoryItems,
    required this.equipmentMap,
    required this.gold,
    this.silver,
    this.copper,
    this.onEquipItem,
    this.onUnequipItem,
    this.onAddItem,
    this.onDeleteItem,
    this.onUpdateQuantity,
    this.showGold = true,
    this.allowQuantityEdit = false,
    this.allowDelete = true,
    this.isEditable = true,
  });

  @override
  State<UnifiedCharacterInventoryWidget> createState() => _UnifiedCharacterInventoryWidgetState();
}

class _UnifiedCharacterInventoryWidgetState extends State<UnifiedCharacterInventoryWidget>
    with TickerProviderStateMixin {
  bool _isGridView = true;
  ItemType? _selectedFilter;
  DisplayInventoryItem? _selectedItem;
  bool _showDetailPanel = false;

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

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
    final unequippedItems = _getUnequippedItems();

    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(DnDTheme.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Gold-Sektion
              if (widget.showGold) ...[
                _buildGoldSection(),
                const SizedBox(height: DnDTheme.lg),
              ],

              // Ausrüstungs-Sektion
              _buildEquipmentSection(),
              const SizedBox(height: DnDTheme.lg),

              // Inventar-Sektion
              _buildInventorySection(unequippedItems),
            ],
          ),
        ),

        // Detail-Panel
        if (_showDetailPanel && _selectedItem != null)
          _buildDetailPanel(_selectedItem!),
      ],
    );
  }

  Widget _buildGoldSection() {
    return SectionCardWidget(
      title: 'Währung',
      icon: Icons.monetization_on,
      child: Row(
        children: [
          _CurrencyChip(
            label: 'Gold',
            value: widget.gold,
            color: DnDTheme.ancientGold,
            icon: Icons.monetization_on,
          ),
          if (widget.silver != null) ...[
            const SizedBox(width: DnDTheme.sm),
            _CurrencyChip(
              label: 'Silber',
              value: widget.silver!,
              color: Colors.grey.shade400,
              icon: Icons.circle,
            ),
          ],
          if (widget.copper != null) ...[
            const SizedBox(width: DnDTheme.sm),
            _CurrencyChip(
              label: 'Kupfer',
              value: widget.copper!,
              color: Colors.brown.shade400,
              icon: Icons.circle,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEquipmentSection() {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.shield,
                  color: DnDTheme.ancientGold,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Ausrüstung',
                  style: DnDTheme.headline2.copyWith(
                    color: DnDTheme.ancientGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                _buildEquipInfo(),
              ],
            ),
            const SizedBox(height: DnDTheme.md),
            _buildCompactEquipmentGrid(),
          ],
        ),
      ),
    );
  }

  Widget _buildEquipInfo() {
    final equippedCount = widget.equipmentMap.values.where((item) => item != null).length;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DnDTheme.sm,
        vertical: DnDTheme.xs,
      ),
      decoration: BoxDecoration(
        color: DnDTheme.ancientGold.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: DnDTheme.ancientGold,
          width: 1,
        ),
      ),
      child: Text(
        '$equippedCount/${EquipmentSlot.values.length}',
        style: DnDTheme.bodyText2.copyWith(
          color: DnDTheme.ancientGold,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCompactEquipmentGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 0.9,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: EquipmentSlot.values.length,
      itemBuilder: (context, index) {
        final slot = EquipmentSlot.values[index];
        final equippedItem = widget.equipmentMap[slot];
        
        // DEBUG: Prüfe ob das Item gefunden wird
        if (equippedItem != null) {
          print('📦 [EquipmentGrid] Slot $slot belegt mit: ${equippedItem.item.name}');
          print('  - InventoryItem ID: ${equippedItem.inventoryItem.id}');
          print('  - isEquipped: ${equippedItem.inventoryItem.isEquipped}');
          print('  - equipSlot: ${equippedItem.inventoryItem.equipSlot}');
        }
        
        return _buildEquipmentSlot(slot, equippedItem);
      },
    );
  }

  Widget _buildEquipmentSlot(EquipmentSlot slot, DisplayInventoryItem? equippedItem) {
    final slotName = Equipment.getSlotName(slot);
    final slotIcon = _getSlotIcon(slot);
    final isEquipped = equippedItem != null;

    return GestureDetector(
      onTap: isEquipped ? () => _showItemDetails(equippedItem!) : () => _showEquipmentDialog(slot),
      onLongPress: isEquipped ? () => _showUnequipConfirmation(slot, equippedItem!) : null,
      child: Container(
        decoration: BoxDecoration(
          color: DnDTheme.stoneGrey,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isEquipped ? DnDTheme.ancientGold : DnDTheme.slateGrey,
            width: isEquipped ? 2 : 1,
          ),
        ),
        child: Stack(
          children: [
            // Zentriertes Icon oder Slot-Name
            Center(
              child: isEquipped
                  ? Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: ItemColorHelper.getItemTypeColor(equippedItem!.item.itemType),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        ItemColorHelper.getItemTypeIcon(equippedItem.item.itemType),
                        color: Colors.white,
                        size: 18,
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          slotIcon,
                          color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
                          size: 20,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          slotName,
                          style: DnDTheme.bodyText2.copyWith(
                            color: Colors.white60,
                            fontSize: 7,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
            ),
            // Ablegen-Button oben rechts
            if (isEquipped && widget.onUnequipItem != null)
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _showUnequipConfirmation(slot, equippedItem!),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: DnDTheme.errorRed,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 12,
                    ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventorySection(List<DisplayInventoryItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.inventory_2,
                  color: DnDTheme.ancientGold,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Inventar',
                  style: DnDTheme.headline2.copyWith(
                    color: DnDTheme.ancientGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const Spacer(),
                _buildInventoryHeader(items),
              ],
            ),
            const SizedBox(height: DnDTheme.md),
            _buildFilterChips(),
            const SizedBox(height: DnDTheme.md),
            items.isEmpty
                ? _buildEmptyInventory()
                : _isGridView
                    ? _buildInventoryGrid(items)
                    : _buildInventoryList(items),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryHeader(List<DisplayInventoryItem> items) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DnDTheme.sm,
            vertical: DnDTheme.xs,
          ),
          decoration: BoxDecoration(
            color: DnDTheme.arcaneBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            border: Border.all(
              color: DnDTheme.arcaneBlue,
              width: 1,
            ),
          ),
          child: Text(
            '${items.length}',
            style: DnDTheme.bodyText2.copyWith(
              color: DnDTheme.arcaneBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: DnDTheme.sm),
        if (widget.isEditable && widget.onAddItem != null)
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: widget.onAddItem,
            color: DnDTheme.ancientGold,
            tooltip: 'Gegenstand hinzufügen',
          ),
        IconButton(
          icon: Icon(_isGridView ? Icons.grid_view : Icons.list, size: 20),
          onPressed: () => setState(() => _isGridView = !_isGridView),
          color: DnDTheme.arcaneBlue,
          tooltip: _isGridView ? 'Listenansicht' : 'Rasteransicht',
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final itemTypes = [
      null, // Alle
      ...ItemType.values,
    ];

    return Wrap(
      spacing: DnDTheme.sm,
      runSpacing: DnDTheme.sm,
      children: itemTypes.map((itemType) {
        final isSelected = _selectedFilter == itemType;
        return FilterChip(
          label: Text(
            itemType == null ? 'Alle' : ItemColorHelper.getItemTypeDisplayName(itemType),
            style: DnDTheme.bodyText2.copyWith(
              color: isSelected ? Colors.white : Colors.white70,
              fontSize: 11,
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              _selectedFilter = selected ? itemType : null;
            });
          },
          selectedColor: DnDTheme.ancientGold,
          checkmarkColor: Colors.white,
          backgroundColor: DnDTheme.stoneGrey,
          padding: const EdgeInsets.symmetric(
            horizontal: DnDTheme.sm,
            vertical: 2,
          ),
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _buildEmptyInventory() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
            ),
            const SizedBox(height: DnDTheme.lg),
            Text(
              'Inventar ist leer',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.ancientGold,
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              'Füge Gegenstände aus der Bibliothek hinzu',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryGrid(List<DisplayInventoryItem> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 6,
        childAspectRatio: 0.85,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return _buildInventoryItemCard(items[index]);
      },
    );
  }

  Widget _buildInventoryList(List<DisplayInventoryItem> items) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: DnDTheme.sm),
          child: _buildInventoryItemCard(items[index], isList: true),
        );
      },
    );
  }

  Widget _buildInventoryItemCard(DisplayInventoryItem displayItem, {bool isList = false}) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;

    return GestureDetector(
      onTap: () => _showItemDetails(displayItem),
      child: Container(
        decoration: BoxDecoration(
          color: DnDTheme.slateGrey,
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          border: Border.all(
            color: DnDTheme.stoneGrey,
            width: 1,
          ),
        ),
        child: isList
            ? _buildListItem(displayItem, item, invItem)
            : _buildGridItem(displayItem, item, invItem),
      ),
    );
  }

  Widget _buildListItem(DisplayInventoryItem displayItem, Item item, InventoryItem invItem) {
    return ListTile(
      contentPadding: const EdgeInsets.all(DnDTheme.sm),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: ItemColorHelper.getItemTypeColor(item.itemType),
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        ),
        child: Icon(
          ItemColorHelper.getItemTypeIcon(item.itemType),
          color: Colors.white,
          size: 20,
        ),
      ),
      title: Text(
        item.name,
        style: DnDTheme.bodyText1.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${ItemColorHelper.getItemTypeDisplayName(item.itemType)} • ${item.weight} Pfund',
        style: DnDTheme.bodyText2.copyWith(
          color: Colors.white60,
          fontSize: 11,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (invItem.quantity > 1) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: DnDTheme.sm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: DnDTheme.ancientGold.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                border: Border.all(
                  color: DnDTheme.ancientGold,
                  width: 1,
                ),
              ),
              child: Text(
                'x${invItem.quantity}',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
            const SizedBox(width: DnDTheme.sm),
          ],
          IconButton(
            icon: const Icon(Icons.check, color: DnDTheme.successGreen, size: 18),
            onPressed: () => _showEquipDialog(displayItem),
            tooltip: 'Ausrüsten',
          ),
          if (widget.allowDelete && widget.onDeleteItem != null)
            IconButton(
              icon: const Icon(Icons.delete, color: DnDTheme.errorRed, size: 18),
              onPressed: () => _showDeleteDialog(displayItem),
              tooltip: 'Löschen',
            ),
        ],
      ),
    );
  }

  Widget _buildGridItem(DisplayInventoryItem displayItem, Item item, InventoryItem invItem) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon
          Center(
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: ItemColorHelper.getItemTypeColor(item.itemType),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                ItemColorHelper.getItemTypeIcon(item.itemType),
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
          const SizedBox(height: 2),

          // Name
          Text(
            item.name,
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          // Quantity
          if (invItem.quantity > 1) ...[
            const SizedBox(height: 1),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 1,
                ),
                decoration: BoxDecoration(
                  color: DnDTheme.ancientGold,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Text(
                  'x${invItem.quantity}',
                  style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 8,
                  ),
                ),
              ),
            ),
          ],

          // Actions
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InkWell(
                onTap: () => _showEquipDialog(displayItem),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: DnDTheme.successGreen.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: DnDTheme.successGreen,
                    size: 12,
                  ),
                ),
              ),
              if (widget.allowDelete && widget.onDeleteItem != null) ...[
                const SizedBox(width: 2),
                InkWell(
                  onTap: () => _showDeleteDialog(displayItem),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: DnDTheme.errorRed.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: const Icon(
                      Icons.delete,
                      color: DnDTheme.errorRed,
                      size: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailPanel(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          color: DnDTheme.dungeonBlack.withValues(alpha: 0.8),
          child: SafeArea(
            child: Column(
              children: [
                // Overlay-Hintergrund
                Expanded(
                  child: GestureDetector(
                    onTap: _closeDetailPanel,
                    child: Container(),
                  ),
                ),

                // Panel
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.7,
                  decoration: BoxDecoration(
                    color: DnDTheme.stoneGrey,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(DnDTheme.radiusLarge),
                      topRight: Radius.circular(DnDTheme.radiusLarge),
                    ),
                  ),
                  child: Column(
                    children: [
                      // Header
                      _buildDetailPanelHeader(item),

                      // Content
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(DnDTheme.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Icon und Name
                              _buildDetailItemHeader(displayItem),

                              const SizedBox(height: DnDTheme.lg),

                              // Details
                              _buildDetailItemInfo(item, invItem),

                              const SizedBox(height: DnDTheme.lg),

                              // Beschreibung
                              if (item.description.isNotEmpty) ...[
                                Text(
                                  'Beschreibung',
                                  style: DnDTheme.headline3.copyWith(
                                    color: DnDTheme.ancientGold,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: DnDTheme.sm),
                                Text(
                                  item.description,
                                  style: DnDTheme.bodyText1.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                              ],

                              const SizedBox(height: DnDTheme.lg),

                              // Actions
                              _buildDetailActions(displayItem),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailPanelHeader(Item item) {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DnDTheme.radiusLarge),
          topRight: Radius.circular(DnDTheme.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: _closeDetailPanel,
          ),
          const SizedBox(width: DnDTheme.sm),
          Expanded(
            child: Text(
              item.name,
              style: DnDTheme.headline2.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItemHeader(DisplayInventoryItem displayItem) {
    final item = displayItem.item;

    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: ItemColorHelper.getItemTypeColor(item.itemType),
            borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          ),
          child: Icon(
            ItemColorHelper.getItemTypeIcon(item.itemType),
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(width: DnDTheme.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                style: DnDTheme.headline2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: DnDTheme.xs),
              Text(
                ItemColorHelper.getItemTypeDisplayName(item.itemType),
                style: DnDTheme.bodyText1.copyWith(
                  color: DnDTheme.ancientGold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItemInfo(Item item, InventoryItem invItem) {
    return Card(
      color: DnDTheme.slateGrey,
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailInfoRow('Gewicht', '${item.weight} Pfund'),
            const SizedBox(height: DnDTheme.sm),
            _buildDetailInfoRow('Menge', '${invItem.quantity}'),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white60,
          ),
        ),
        Text(
          value,
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailActions(DisplayInventoryItem displayItem) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.onEquipItem != null)
          ElevatedButton.icon(
            onPressed: () {
              _closeDetailPanel();
              _showEquipDialog(displayItem);
            },
            icon: const Icon(Icons.check),
            label: const Text('Ausrüsten'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: DnDTheme.dungeonBlack,
              padding: const EdgeInsets.symmetric(vertical: DnDTheme.md),
            ),
          ),
        const SizedBox(height: DnDTheme.sm),
        if (widget.allowDelete && widget.onDeleteItem != null)
          OutlinedButton.icon(
            onPressed: () {
              _closeDetailPanel();
              _showDeleteDialog(displayItem);
            },
            icon: const Icon(Icons.delete),
            label: const Text('Löschen'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DnDTheme.errorRed,
              side: const BorderSide(color: DnDTheme.errorRed),
              padding: const EdgeInsets.symmetric(vertical: DnDTheme.md),
            ),
          ),
      ],
    );
  }

  List<DisplayInventoryItem> _getUnequippedItems() {
    // Prüfe direkt die InventoryItems.isEquipped statt der equipmentMap
    // Das verhindert Synchronisierungsprobleme zwischen den beiden Equip-Systemen
    return widget.inventoryItems
        .where((item) => !item.inventoryItem.isEquipped)
        .where((item) => _selectedFilter == null || item.item.itemType == _selectedFilter)
        .toList();
  }

  IconData _getSlotIcon(EquipmentSlot slot) {
    switch (slot) {
      case EquipmentSlot.helmet:
        return Icons.security;
      case EquipmentSlot.armor:
        return Icons.shield;
      case EquipmentSlot.shield:
        return Icons.shield;
      case EquipmentSlot.weaponPrimary:
        return Icons.sports_martial_arts;
      case EquipmentSlot.weaponSecondary:
        return Icons.sports_kabaddi;
      case EquipmentSlot.gloves:
        return Icons.back_hand;
      case EquipmentSlot.boots:
        return Icons.hiking;
      case EquipmentSlot.ring1:
      case EquipmentSlot.ring2:
        return Icons.circle;
      case EquipmentSlot.amulet:
        return Icons.emoji_events;
      case EquipmentSlot.cloak:
        return Icons.checkroom;
    }
  }

  IconData _getItemIcon(ItemType itemType) {
    return ItemColorHelper.getItemTypeIcon(itemType);
  }

  void _showItemDetails(DisplayInventoryItem displayItem) {
    // Prüfe ob das Item ausgerüstet ist
    final equippedSlot = widget.equipmentMap.entries
        .firstWhere(
          (entry) => entry.value?.inventoryItem.id == displayItem.inventoryItem.id,
          orElse: () => MapEntry(EquipmentSlot.armor, null),
        )
        .key;

    final isEquipped = displayItem.inventoryItem.isEquipped;

    if (isEquipped) {
      // Zeige Dialog mit Abwählen und Tauschen
      _showEquippedItemDialog(equippedSlot, displayItem);
    } else {
      // Zeige Detail-Panel für nicht ausgerüstete Items
      setState(() {
        _selectedItem = displayItem;
        _showDetailPanel = true;
      });
      _fadeController.forward();
      _slideController.forward();
    }
  }

  void _showEquippedItemDialog(EquipmentSlot slot, DisplayInventoryItem displayItem) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          displayItem.item.name,
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: ItemColorHelper.getItemTypeColor(displayItem.item.itemType),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    ItemColorHelper.getItemTypeIcon(displayItem.item.itemType),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: DnDTheme.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayItem.item.name,
                        style: DnDTheme.bodyText1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Equipment.getSlotName(slot),
                        style: DnDTheme.bodyText2.copyWith(
                          color: DnDTheme.ancientGold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: DnDTheme.md),
            Text(
              displayItem.item.description.isNotEmpty
                  ? displayItem.item.description
                  : 'Keine Beschreibung',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white70,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          // Abwählen Button
          if (widget.onUnequipItem != null)
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onUnequipItem!(slot);
              },
              icon: const Icon(Icons.undo, size: 18),
              label: const Text('Abwählen'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DnDTheme.errorRed,
                side: const BorderSide(color: DnDTheme.errorRed),
              ),
            ),
          const SizedBox(width: DnDTheme.sm),
          // Tauschen Button
          if (widget.onEquipItem != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _showSwapDialog(slot, displayItem);
              },
              icon: const Icon(Icons.swap_horiz, size: 18),
              label: const Text('Tauschen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.ancientGold,
                foregroundColor: DnDTheme.dungeonBlack,
              ),
            ),
        ],
      ),
    );
  }

  void _showSwapDialog(EquipmentSlot slot, DisplayInventoryItem currentItem) {
    // Finde alle nicht ausgerüsteten Items die in diesen Slot passen
    final unequippedItems = _getUnequippedItems();
    final swappableItems = unequippedItems.where((item) {
      return _getAvailableSlotsForItem(item.item).contains(slot);
    }).toList();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          '${currentItem.item.name} tauschen',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wähle einen Gegenstand zum Tauschen:',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: DnDTheme.md),
            if (swappableItems.isEmpty)
              Padding(
                padding: const EdgeInsets.all(DnDTheme.md),
                child: Center(
                  child: Text(
                    'Keine tauschbaren Gegenstände im Inventar',
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white60,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ...swappableItems.map((item) {
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: ItemColorHelper.getItemTypeColor(item.item.itemType),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(
                      ItemColorHelper.getItemTypeIcon(item.item.itemType),
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    item.item.name,
                    style: DnDTheme.bodyText1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    ItemColorHelper.getItemTypeDisplayName(item.item.itemType),
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white60,
                      fontSize: 11,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(dialogContext).pop();
                    // Erst ablegen, dann ausrüsten
                    widget.onUnequipItem!(slot);
                    // Kleine Verzögerung damit das Ablegen fertig ist
                    Future.delayed(const Duration(milliseconds: 100), () {
                      widget.onEquipItem!(slot, item);
                    });
                  },
                );
              }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _closeDetailPanel() {
    _fadeController.reverse().then((_) {
      _slideController.reverse().then((_) {
        setState(() {
          _showDetailPanel = false;
          _selectedItem = null;
        });
      });
    });
  }

  void _showUnequipConfirmation(EquipmentSlot slot, DisplayInventoryItem displayItem) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          '${displayItem.item.name} ablegen?',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Text(
          'Möchtest du "${displayItem.item.name}" wirklich ablegen?',
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onUnequipItem!(slot);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ablegen'),
          ),
        ],
      ),
    );
  }

  void _showEquipmentDialog(EquipmentSlot slot) {
    final equippedItem = widget.equipmentMap[slot];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          Equipment.getSlotName(slot),
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (equippedItem != null) ...[
              _buildEquippedItemInfo(equippedItem),
              const SizedBox(height: DnDTheme.md),
            ] else ...[
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
              ),
              const SizedBox(height: DnDTheme.md),
              Text(
                'Kein Gegenstand ausgerüstet',
                style: DnDTheme.bodyText1.copyWith(
                  color: Colors.white60,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
        actions: [
          if (equippedItem != null && widget.onUnequipItem != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                widget.onUnequipItem!(slot);
              },
              icon: const Icon(Icons.undo),
              label: Text(
                'Ablegen',
                style: DnDTheme.bodyText1.copyWith(
                  color: DnDTheme.errorRed,
                ),
              ),
            ),
          if (equippedItem == null)
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Abbrechen',
                style: DnDTheme.bodyText1.copyWith(
                  color: Colors.white70,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEquippedItemInfo(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;

    return Card(
      color: DnDTheme.slateGrey,
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ItemColorHelper.getItemTypeColor(item.itemType),
                    borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  ),
                  child: Icon(
                    ItemColorHelper.getItemTypeIcon(item.itemType),
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: DnDTheme.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: DnDTheme.bodyText1.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        ItemColorHelper.getItemTypeDisplayName(item.itemType),
                        style: DnDTheme.bodyText2.copyWith(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (invItem.quantity > 1) ...[
              const SizedBox(height: DnDTheme.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DnDTheme.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: DnDTheme.ancientGold.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  border: Border.all(
                    color: DnDTheme.ancientGold,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Menge: ${invItem.quantity}',
                  style: DnDTheme.bodyText2.copyWith(
                    color: DnDTheme.ancientGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showEquipDialog(DisplayInventoryItem displayItem) {
    final item = displayItem.item;

    // Finde verfügbare Slots basierend auf Item-Typ
    final availableSlots = _getAvailableSlotsForItem(item);

    if (availableSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${item.name} kann nicht ausgerüstet werden'),
          backgroundColor: DnDTheme.errorRed,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          '${item.name} ausrüsten',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Wähle einen Slot:',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: DnDTheme.md),
            ...availableSlots.map((slot) {
              final isEquipped = widget.equipmentMap[slot] != null;
              final slotName = Equipment.getSlotName(slot);
              
              return ListTile(
                enabled: !isEquipped && widget.onEquipItem != null,
                leading: Icon(
                  _getSlotIcon(slot),
                  color: isEquipped
                      ? Colors.white30
                      : DnDTheme.ancientGold,
                ),
                title: Text(
                  slotName,
                  style: DnDTheme.bodyText1.copyWith(
                    color: isEquipped
                        ? Colors.white30
                        : Colors.white,
                  ),
                ),
                subtitle: Text(
                  Equipment.getSlotDescription(slot),
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white60,
                    fontSize: 11,
                  ),
                ),
                trailing: isEquipped
                    ? Text(
                        'Belegt',
                        style: DnDTheme.bodyText2.copyWith(
                          color: DnDTheme.errorRed,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : const Icon(
                        Icons.check_circle_outline,
                        color: DnDTheme.successGreen,
                      ),
                onTap: isEquipped
                    ? null
                    : () {
                        Navigator.of(dialogContext).pop();
                        widget.onEquipItem!(slot, displayItem);
                      },
              );
            }).toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<EquipmentSlot> _getAvailableSlotsForItem(Item item) {
    switch (item.itemType) {
      case ItemType.Weapon:
        return [
          EquipmentSlot.weaponPrimary,
          EquipmentSlot.weaponSecondary,
        ];
      case ItemType.Armor:
        return [EquipmentSlot.armor];
      case ItemType.Shield:
        return [EquipmentSlot.shield];
      case ItemType.MagicItem:
        return EquipmentSlot.values; // Magische Items können fast überall
      case ItemType.Potion:
        return []; // Tränke können nicht ausgerüstet werden
      case ItemType.Tool:
        return [EquipmentSlot.weaponSecondary]; // Werkzeuge als Nebenwaffe
      case ItemType.Material:
        return []; // Materialien können nicht ausgerüstet werden
      case ItemType.AdventuringGear:
        return [
          EquipmentSlot.weaponSecondary,
          EquipmentSlot.gloves,
          EquipmentSlot.boots,
          EquipmentSlot.cloak,
        ];
      default:
        return [];
    }
  }

  void _showDeleteDialog(DisplayInventoryItem displayItem) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          '${displayItem.item.name} löschen',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Text(
          'Möchtest du "${displayItem.item.name}" wirklich löschen?',
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white70,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              widget.onDeleteItem!(displayItem);
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

/// Helper Widget für Währungs-Chips
class _CurrencyChip extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final IconData icon;

  const _CurrencyChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: DnDTheme.md,
        vertical: DnDTheme.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: color,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: color,
            size: 16,
          ),
          const SizedBox(width: DnDTheme.sm),
          Text(
            label,
            style: DnDTheme.bodyText2.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: DnDTheme.xs),
          Text(
            value.toString(),
            style: DnDTheme.bodyText1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
