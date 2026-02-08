import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Widget für Creature-Inventar (Map-basiert)
/// Zeigt Items als einfache Maps an
/// 
/// Beispiele:
/// ```dart
/// CreatureInventoryWidget(
///   mapItems: viewModel.creature?.inventory ?? [],
///   onAddItem: () => _showAddItemDialog(),
///   onRemoveItem: (index) => viewModel.removeInventoryItem(index),
///   onEditItem: (index, item) => _showEditItemDialog(index),
/// )
/// ```
class CreatureInventoryWidget extends StatelessWidget {
  /// Liste von Inventar-Items als Maps
  final List<Map<String, dynamic>> mapItems;
  
  /// Callback zum Hinzufügen eines Items
  final VoidCallback? onAddItem;
  
  /// Callback zum Entfernen eines Items
  final Function(int index)? onRemoveItem;
  
  /// Callback zum Bearbeiten eines Items
  final Function(int index, Map<String, dynamic> item)? onEditItem;
  
  /// Ob der Hinzufügen-Button angezeigt werden soll
  final bool showAddButton;
  
  /// Titel für leeren Zustand
  final String? emptyTitle;
  
  /// Untertitel für leeren Zustand
  final String? emptySubtitle;

  const CreatureInventoryWidget({
    super.key,
    required this.mapItems,
    this.onAddItem,
    this.onRemoveItem,
    this.onEditItem,
    this.showAddButton = true,
    this.emptyTitle = 'Inventar ist leer',
    this.emptySubtitle = 'Füge Gegenstände hinzu',
  });

  @override
  Widget build(BuildContext context) {
    if (mapItems.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit Counter
        _buildHeader(context),
        const SizedBox(height: DnDTheme.md),
        
        // Item-Liste
        _buildItemList(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Icon(
          Icons.inventory_2,
          color: DnDTheme.ancientGold,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Inventar',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 4,
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
            '${mapItems.length}',
            style: DnDTheme.bodyText1.copyWith(
              color: DnDTheme.arcaneBlue,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const Spacer(),
        if (showAddButton && onAddItem != null)
          ElevatedButton.icon(
            onPressed: onAddItem,
            icon: const Icon(Icons.add),
            label: const Text('Hinzufügen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.successGreen,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
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
          ],
        ),
      ),
    );
  }

  Widget _buildItemList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mapItems.length,
      separatorBuilder: (context, index) => const Divider(
        color: Colors.white12,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final item = mapItems[index];
        return _buildItemCard(context, index, item);
      },
    );
  }

  Widget _buildItemCard(BuildContext context, int index, Map<String, dynamic> item) {
    final name = item['name'] as String? ?? 'Unbekannter Gegenstand';
    final description = item['description'] as String? ?? '';
    final type = item['type'] as String? ?? 'item';
    final quantity = item['quantity'] as int? ?? 1;
    final value = item['value'] as double? ?? 0.0;

    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: DnDTheme.md,
          vertical: DnDTheme.sm,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: DnDTheme.arcaneBlue.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          ),
          child: Icon(
            _getItemIcon(type),
            color: DnDTheme.arcaneBlue,
            size: 24,
          ),
        ),
        title: Text(
          name,
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (description.isNotEmpty)
              Text(
                description,
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white70,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            Row(
              children: [
                if (quantity > 1)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DnDTheme.ancientGold,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'x$quantity',
                      style: DnDTheme.bodyText2.copyWith(
                        color: DnDTheme.dungeonBlack,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                if (value > 0) ...[
                  if (quantity > 1) const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: DnDTheme.successGreen,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.monetization_on,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${value.toStringAsFixed(2)}',
                          style: DnDTheme.bodyText2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onEditItem != null)
              IconButton(
                icon: Icon(
                  Icons.edit,
                  color: DnDTheme.arcaneBlue,
                ),
                onPressed: () => onEditItem!(index, item),
                tooltip: 'Bearbeiten',
              ),
            if (onRemoveItem != null)
              IconButton(
                icon: Icon(
                  Icons.delete,
                  color: DnDTheme.errorRed,
                ),
                onPressed: () => _confirmDelete(context, index, name),
                tooltip: 'Löschen',
              ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index, String itemName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Gegenstand löschen',
          style: DnDTheme.headline2.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Text(
          'Möchtest du wirklich "$itemName" löschen?',
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
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (onRemoveItem != null) {
                onRemoveItem!(index);
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

  IconData _getItemIcon(String type) {
    switch (type.toLowerCase()) {
      case 'weapon':
      case 'waffe':
        return Icons.sports_martial_arts;
      case 'armor':
      case 'rüstung':
        return Icons.security;
      case 'shield':
      case 'schild':
        return Icons.shield;
      case 'potion':
      case 'trank':
        return Icons.local_drink;
      case 'magic':
      case 'magisch':
        return Icons.auto_fix_high;
      case 'tool':
      case 'werkzeug':
        return Icons.build;
      case 'material':
      case 'material':
        return Icons.inventory_2;
      case 'treasure':
      case 'schatz':
        return Icons.diamond;
      case 'key':
      case 'schlüssel':
        return Icons.vpn_key;
      default:
        return Icons.inventory_2;
    }
  }
}
