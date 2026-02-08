import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';
import '../../../models/item.dart';
import '../../../theme/dnd_theme.dart';
import '../../character_editor/item_color_helper.dart';

/// Vereinheitlichtes Widget für Inventare
/// Unterstützt sowohl Map-basierte (Creature) als auch Item-basierte (Hero) Inventare
/// 
/// Beispiele:
/// ```dart
/// // Für Helden (Item-basiert)
/// UnifiedInventoryWidget(
///   displayItems: viewModel.inventory,
///   onAddItem: () => // Item hinzufügen
///   onEditItem: (displayItem) => // Item bearbeiten
///   onDeleteItem: (displayItem) => // Item löschen
///   showAddButton: true,
/// )
///
/// // Für Kreaturen (Map-basiert)
/// UnifiedInventoryWidget(
///   mapItems: creature.inventory,
///   onAddItem: () => // Item hinzufügen
///   onEditMapItem: (index, item) => // Item bearbeiten
///   onRemoveMapItem: (index) => // Item löschen
///   showAddButton: true,
/// )
/// ```
class UnifiedInventoryWidget extends StatelessWidget {
  // Item-basierte Daten (für Helden)
  final List<DisplayInventoryItem>? displayItems;
  final Function(DisplayInventoryItem)? onEditItem;
  final Function(DisplayInventoryItem)? onDeleteItem;

  // Map-basierte Daten (für Kreaturen)
  final List<Map<String, dynamic>>? mapItems;
  final Function(int index, Map<String, dynamic> item)? onEditMapItem;
  final Function(int index)? onRemoveMapItem;

  // Gemeinsame Optionen
  final VoidCallback? onAddItem;
  final bool showAddButton;
  final bool showEmptyState;
  final String? emptyTitle;
  final String? emptySubtitle;
  final String sectionTitle;
  final IconData sectionIcon;

  const UnifiedInventoryWidget({
    super.key,
    this.displayItems,
    this.onEditItem,
    this.onDeleteItem,
    this.mapItems,
    this.onEditMapItem,
    this.onRemoveMapItem,
    this.onAddItem,
    this.showAddButton = true,
    this.showEmptyState = true,
    this.emptyTitle,
    this.emptySubtitle,
    this.sectionTitle = 'Inventar',
    this.sectionIcon = Icons.inventory_2,
  });

  @override
  Widget build(BuildContext context) {
    final isMapBased = mapItems != null;
    final hasItems = isMapBased 
        ? (mapItems?.isNotEmpty ?? false)
        : (displayItems?.isNotEmpty ?? false);

    if (!hasItems && showEmptyState) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAddButton) ...[
          _buildAddButton(context),
          const SizedBox(height: DnDTheme.md),
        ],
        if (isMapBased)
          _buildMapInventoryList()
        else
          _buildItemInventoryList(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(DnDTheme.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 80,
              color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
            ),
            const SizedBox(height: DnDTheme.lg),
            Text(
              emptyTitle ?? 'Inventar ist leer',
              style: DnDTheme.headline2.copyWith(
                color: DnDTheme.ancientGold,
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              emptySubtitle ?? 'Füge Gegenstände hinzu',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            if (showAddButton && onAddItem != null) ...[
              const SizedBox(height: DnDTheme.lg),
              ElevatedButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add),
                label: const Text('Gegenstand hinzufügen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DnDTheme.ancientGold,
                  foregroundColor: DnDTheme.dungeonBlack,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onAddItem,
        icon: const Icon(Icons.add),
        label: const Text('Gegenstand hinzufügen'),
        style: ElevatedButton.styleFrom(
          backgroundColor: DnDTheme.ancientGold,
          foregroundColor: DnDTheme.dungeonBlack,
          padding: const EdgeInsets.symmetric(vertical: DnDTheme.md),
        ),
      ),
    );
  }

  Widget _buildMapInventoryList() {
    if (mapItems == null) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mapItems!.length,
      itemBuilder: (context, index) {
        final item = mapItems![index];
        return _buildMapInventoryItemCard(context, index, item);
      },
    );
  }

  Widget _buildItemInventoryList() {
    if (displayItems == null) return const SizedBox.shrink();

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(DnDTheme.md),
      itemCount: displayItems!.length,
      itemBuilder: (context, index) {
        final displayItem = displayItems![index];
        return _buildItemInventoryItemCard(context, displayItem);
      },
    );
  }

  Widget _buildMapInventoryItemCard(
    BuildContext context,
    int index,
    Map<String, dynamic> item,
  ) {
    final name = item['name'] as String? ?? 'Unbekannter Gegenstand';
    final description = item['description'] as String? ?? '';
    final quantity = item['quantity'] as int? ?? 1;
    final value = item['value'] as double? ?? 0.0;
    final itemType = item['type'] as String? ?? 'item';

    return Card(
      color: DnDTheme.slateGrey,
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DnDTheme.lg),
        leading: _buildMapItemIcon(itemType),
        title: Text(
          name,
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (description.isNotEmpty)
              Text(
                description,
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white60,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            if (quantity > 1 || value > 0) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  if (quantity > 1) ...[
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
                        'x$quantity',
                        style: DnDTheme.bodyText2.copyWith(
                          color: DnDTheme.ancientGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: DnDTheme.sm),
                  ],
                  if (value > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: DnDTheme.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: DnDTheme.arcaneBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                        border: Border.all(
                          color: DnDTheme.arcaneBlue,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.monetization_on,
                            size: 14,
                            color: DnDTheme.arcaneBlue,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${value.toStringAsFixed(0)} Gold',
                            style: DnDTheme.bodyText2.copyWith(
                              color: DnDTheme.arcaneBlue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEditMapItem != null)
              IconButton(
                icon: const Icon(Icons.edit, color: DnDTheme.arcaneBlue),
                onPressed: () => onEditMapItem!(index, item),
                tooltip: 'Bearbeiten',
              ),
            if (onRemoveMapItem != null)
              IconButton(
                icon: const Icon(Icons.delete, color: DnDTheme.errorRed),
                onPressed: () => _showMapDeleteDialog(context, index, name),
                tooltip: 'Löschen',
              ),
          ],
        ),
        onTap: onEditMapItem != null ? () => onEditMapItem!(index, item) : null,
      ),
    );
  }

  Widget _buildItemInventoryItemCard(
    BuildContext context,
    DisplayInventoryItem displayItem,
  ) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;

    return Card(
      color: DnDTheme.slateGrey,
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DnDTheme.lg),
        leading: _buildItemIcon(item),
        title: Text(
          item.name,
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildItemDescription(item),
            if (item.hasDurability == true && 
                displayItem.currentDurability != null) ...[
              const SizedBox(height: 4),
              _buildDurabilityBar(displayItem),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (invItem.quantity > 1) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: DnDTheme.md,
                  vertical: DnDTheme.xs,
                ),
                decoration: BoxDecoration(
                  color: DnDTheme.ancientGold,
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                ),
                child: Text(
                  'x${invItem.quantity}',
                  style: DnDTheme.bodyText2.copyWith(
                    color: DnDTheme.dungeonBlack,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: DnDTheme.sm),
            ],
            if (onEditItem != null)
              IconButton(
                icon: const Icon(Icons.edit, color: DnDTheme.arcaneBlue),
                onPressed: () => onEditItem!(displayItem),
                tooltip: 'Bearbeiten',
              ),
            if (onDeleteItem != null)
              IconButton(
                icon: const Icon(Icons.delete, color: DnDTheme.errorRed),
                onPressed: () => _showItemDeleteDialog(context, displayItem),
                tooltip: 'Löschen',
              ),
          ],
        ),
        onTap: onEditItem != null ? () => onEditItem!(displayItem) : null,
      ),
    );
  }

  Widget _buildMapItemIcon(String itemType) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: _getMapItemTypeColor(itemType),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
      ),
      child: Icon(
        _getMapItemTypeIcon(itemType),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildItemIcon(Item item) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: DnDTheme.arcaneBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        ItemColorHelper.getItemTypeIcon(item.itemType),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildItemDescription(Item item) {
    final description = item.description.isNotEmpty 
        ? item.description 
        : '${item.itemType.name} • ${item.weight} Pfund';
    
    return Text(
      description,
      style: DnDTheme.bodyText2.copyWith(
        color: Colors.white60,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildDurabilityBar(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final current = displayItem.currentDurability ?? item.maxDurability ?? 100;
    final max = item.maxDurability ?? 100;
    final percentage = current / max;
    
    final durabilityColor = ItemColorHelper.getDurabilityColor(percentage);
    
    return Container(
      width: double.infinity,
      height: 4,
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: percentage,
        child: Container(
          decoration: BoxDecoration(
            color: durabilityColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  Color _getMapItemTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'waffe':
      case 'weapon':
        return DnDTheme.errorRed;
      case 'rüstung':
      case 'armor':
        return DnDTheme.successGreen;
      case 'zauber':
      case 'magic':
        return DnDTheme.arcaneBlue;
      case 'trank':
      case 'potion':
        return Colors.purple;
      case 'schatz':
      case 'treasure':
        return DnDTheme.ancientGold;
      default:
        return DnDTheme.stoneGrey;
    }
  }

  IconData _getMapItemTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'waffe':
      case 'weapon':
        return Icons.sports_martial_arts;
      case 'rüstung':
      case 'armor':
        return Icons.security;
      case 'zauber':
      case 'magic':
        return Icons.auto_fix_high;
      case 'trank':
      case 'potion':
        return Icons.local_drink;
      case 'schatz':
      case 'treasure':
        return Icons.monetization_on;
      case 'werkzeug':
      case 'tool':
        return Icons.build;
      default:
        return Icons.inventory_2_outlined;
    }
  }

  void _showMapDeleteDialog(BuildContext context, int index, String itemName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          '$itemName löschen',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Text(
          'Möchtest du "$itemName" wirklich löschen?',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (onRemoveMapItem != null) {
                onRemoveMapItem!(index);
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

  void _showItemDeleteDialog(BuildContext context, DisplayInventoryItem displayItem) {
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
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (onDeleteItem != null) {
                onDeleteItem!(displayItem);
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
