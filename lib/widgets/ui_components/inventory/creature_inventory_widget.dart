import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Widget für Creature-Inventar (Map-basiert)
/// Zeigt Items als moderne Karten mit farbcodierten Icons an
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
        const SizedBox(height: DnDTheme.lg),
        
        // Item-Grid
        _buildItemGrid(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.ancientGold.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.inventory_2,
            color: DnDTheme.ancientGold,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inventar',
                  style: DnDTheme.headline2.copyWith(
                    color: DnDTheme.ancientGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Alle Gegenstände der Kreatur',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: DnDTheme.arcaneBlue.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
              border: Border.all(
                color: DnDTheme.arcaneBlue,
                width: 2,
              ),
            ),
            child: Text(
              '${mapItems.length}',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.arcaneBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(DnDTheme.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(DnDTheme.xl),
              decoration: BoxDecoration(
                color: DnDTheme.mysticalPurple.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: DnDTheme.xl),
            Text(
              emptyTitle ?? 'Inventar ist leer',
              style: DnDTheme.headline2.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
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
            const SizedBox(height: DnDTheme.xxl),
            if (showAddButton && onAddItem != null)
              ElevatedButton.icon(
                onPressed: onAddItem,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Ersten Gegenstand hinzufügen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DnDTheme.successGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: DnDTheme.xl,
                    vertical: DnDTheme.lg,
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemGrid() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: mapItems.length,
      separatorBuilder: (context, index) => const SizedBox(height: DnDTheme.md),
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

    final typeInfo = _getItemTypeInfo(type);

    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: typeInfo.color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showItemDetails(context, item),
            child: Padding(
              padding: const EdgeInsets.all(DnDTheme.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header mit Icon und Name
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: typeInfo.color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                          border: Border.all(
                            color: typeInfo.color,
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          typeInfo.icon,
                          color: typeInfo.color,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: DnDTheme.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    name,
                                    style: DnDTheme.headline3.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                if (quantity > 1) ...[
                                  const SizedBox(width: DnDTheme.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: DnDTheme.ancientGold,
                                      borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                                    ),
                                    child: Text(
                                      '×$quantity',
                                      style: DnDTheme.bodyText1.copyWith(
                                        color: DnDTheme.dungeonBlack,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              typeInfo.displayName,
                              style: DnDTheme.bodyText2.copyWith(
                                color: typeInfo.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Aktionen
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (onEditItem != null)
                            _buildActionButton(
                              icon: Icons.edit_outlined,
                              color: DnDTheme.arcaneBlue,
                              onPressed: () => onEditItem!(index, item),
                              tooltip: 'Bearbeiten',
                            ),
                          if (onRemoveItem != null)
                            _buildActionButton(
                              icon: Icons.delete_outline,
                              color: DnDTheme.errorRed,
                              onPressed: () => _confirmDelete(context, index, name),
                              tooltip: 'Löschen',
                            ),
                        ],
                      ),
                    ],
                  ),
                  
                  if (description.isNotEmpty || value > 0) ...[
                    const SizedBox(height: DnDTheme.md),
                    const Divider(color: Colors.white12, height: 1),
                    const SizedBox(height: DnDTheme.md),
                    
                    // Details
                    Row(
                      children: [
                        if (description.isNotEmpty)
                          Expanded(
                            child: Text(
                              description,
                              style: DnDTheme.bodyText2.copyWith(
                                color: Colors.white70,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        if (value > 0) ...[
                          if (description.isNotEmpty) const SizedBox(width: DnDTheme.md),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: DnDTheme.successGreen.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                              border: Border.all(
                                color: DnDTheme.successGreen,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.monetization_on,
                                  size: 16,
                                  color: DnDTheme.successGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${value.toStringAsFixed(2)} Gold',
                                  style: DnDTheme.bodyText2.copyWith(
                                    color: DnDTheme.successGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: DnDTheme.sm),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          child: Container(
            padding: const EdgeInsets.all(DnDTheme.sm),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
              border: Border.all(
                color: color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _showItemDetails(BuildContext context, Map<String, dynamic> item) {
    final name = item['name'] as String? ?? 'Unbekannter Gegenstand';
    final description = item['description'] as String? ?? '';
    final type = item['type'] as String? ?? 'item';
    final quantity = item['quantity'] as int? ?? 1;
    final value = item['value'] as double? ?? 0.0;

    final typeInfo = _getItemTypeInfo(type);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) => Container(
        decoration: BoxDecoration(
          color: DnDTheme.stoneGrey,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DnDTheme.radiusLarge),
          ),
        ),
        padding: MediaQuery.of(dialogContext).viewInsets,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(DnDTheme.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle-Drag-Indikator
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: DnDTheme.lg),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              
              // Header mit Icon und Name
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: typeInfo.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      border: Border.all(
                        color: typeInfo.color,
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      typeInfo.icon,
                      color: typeInfo.color,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: DnDTheme.headline2.copyWith(
                            color: DnDTheme.ancientGold,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: typeInfo.color.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                            border: Border.all(
                              color: typeInfo.color.withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            typeInfo.displayName,
                            style: DnDTheme.bodyText2.copyWith(
                              color: typeInfo.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: DnDTheme.lg),
              const Divider(color: Colors.white12, height: 1),
              const SizedBox(height: DnDTheme.lg),
              
              // Details-Sektion
              if (description.isNotEmpty) ...[
                Row(
                  children: [
                    Icon(
                      Icons.description,
                      color: Colors.white60,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Beschreibung',
                      style: DnDTheme.bodyText2.copyWith(
                        color: Colors.white60,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: DnDTheme.sm),
                Container(
                  padding: const EdgeInsets.all(DnDTheme.md),
                  decoration: BoxDecoration(
                    color: DnDTheme.slateGrey,
                    borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                    border: Border.all(
                      color: Colors.white12,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    description,
                    style: DnDTheme.bodyText1.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: DnDTheme.lg),
              ],
              
              // Statistiken
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.white60,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Statistiken',
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white60,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: DnDTheme.sm),
              Container(
                decoration: BoxDecoration(
                  color: DnDTheme.slateGrey,
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                  border: Border.all(
                    color: Colors.white12,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      icon: Icons.inventory,
                      label: 'Menge',
                      value: quantity.toString(),
                      color: DnDTheme.ancientGold,
                    ),
                    if (quantity > 0 || value > 0)
                      const Divider(color: Colors.white12, height: 1),
                    if (value > 0)
                      _buildStatRow(
                        icon: Icons.monetization_on,
                        label: 'Wert',
                        value: '${value.toStringAsFixed(2)} Gold',
                        color: DnDTheme.successGreen,
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: DnDTheme.xl),
              
              // Schließen-Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  icon: const Icon(Icons.close),
                  label: const Text('Schließen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DnDTheme.mysticalPurple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      vertical: DnDTheme.md,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: DnDTheme.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(DnDTheme.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: DnDTheme.bodyText1.copyWith(
              color: Colors.white60,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: DnDTheme.bodyText1.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, int index, String itemName) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Row(
          children: [
            Icon(
              Icons.warning_outlined,
              color: DnDTheme.errorRed,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Gegenstand löschen?',
                style: DnDTheme.headline2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'Möchtest du wirklich "$itemName" aus dem Inventar entfernen?',
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

  ({IconData icon, Color color, String displayName}) _getItemTypeInfo(String type) {
    final typeLower = type.toLowerCase();
    
    switch (typeLower) {
      case 'weapon':
      case 'waffe':
        return (
          icon: Icons.gavel,
          color: DnDTheme.errorRed,
          displayName: 'Waffe',
        );
      case 'armor':
      case 'rüstung':
        return (
          icon: Icons.shield,
          color: DnDTheme.arcaneBlue,
          displayName: 'Rüstung',
        );
      case 'shield':
      case 'schild':
        return (
          icon: Icons.shield_outlined,
          color: DnDTheme.warningOrange,
          displayName: 'Schild',
        );
      case 'potion':
      case 'trank':
        return (
          icon: Icons.local_drink,
          color: DnDTheme.emeraldGreen,
          displayName: 'Trank',
        );
      case 'magic':
      case 'magisch':
      case 'magic_item':
        return (
          icon: Icons.auto_awesome,
          color: DnDTheme.ancientGold,
          displayName: 'Magischer Gegenstand',
        );
      case 'tool':
      case 'werkzeug':
        return (
          icon: Icons.build,
          color: DnDTheme.warningOrange,
          displayName: 'Werkzeug',
        );
      case 'material':
        return (
          icon: Icons.science,
          color: DnDTheme.warningOrange,
          displayName: 'Material',
        );
      case 'component':
      case 'komponente':
        return (
          icon: Icons.category,
          color: DnDTheme.warningOrange,
          displayName: 'Komponente',
        );
      case 'treasure':
      case 'schatz':
        return (
          icon: Icons.diamond,
          color: DnDTheme.ancientGold,
          displayName: 'Schatz',
        );
      case 'currency':
      case 'währung':
        return (
          icon: Icons.monetization_on,
          color: DnDTheme.successGreen,
          displayName: 'Währung',
        );
      case 'scroll':
      case 'schriftrolle':
        return (
          icon: Icons.description,
          color: DnDTheme.mysticalPurple,
          displayName: 'Schriftrolle',
        );
      case 'gear':
      case 'ausrüstung':
        return (
          icon: Icons.inventory_2,
          color: DnDTheme.mysticalPurple,
          displayName: 'Ausrüstung',
        );
      case 'key':
      case 'schlüssel':
        return (
          icon: Icons.vpn_key,
          color: DnDTheme.arcaneBlue,
          displayName: 'Schlüssel',
        );
      case 'consumable':
      case 'verbrauchsgegenstand':
        return (
          icon: Icons.restaurant,
          color: DnDTheme.emeraldGreen,
          displayName: 'Verbrauchsgegenstand',
        );
      default:
        return (
          icon: Icons.inventory_2,
          color: DnDTheme.mysticalPurple,
          displayName: 'Gegenstand',
        );
    }
  }
}