import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../models/item.dart';
import '../../../theme/app_theme.dart';
import '../../../viewmodels/edit_creature_viewmodel.dart';
import '../../../widgets/ui_components/feedback/snackbar_helper.dart';

/// Hilfsfunktionen für Item-Typen
class ItemTypeHelper {
  static String getItemTypeDisplayName(ItemType type) {
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

  static String getItemTypeString(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return 'weapon';
      case ItemType.Armor:
        return 'armor';
      case ItemType.Shield:
        return 'shield';
      case ItemType.Consumable:
        return 'consumable';
      case ItemType.Tool:
        return 'tool';
      case ItemType.Material:
        return 'material';
      case ItemType.Component:
        return 'component';
      case ItemType.MagicItem:
        return 'magic';
      case ItemType.Scroll:
        return 'scroll';
      case ItemType.Potion:
        return 'potion';
      case ItemType.Treasure:
        return 'treasure';
      case ItemType.Currency:
        return 'currency';
      case ItemType.AdventuringGear:
        return 'gear';
      case ItemType.SPELL_WEAPON:
        return 'spell_weapon';
    }
  }

  static Color getTypeColor(ItemType type, AppColorsExtension C) {
    switch (type) {
      case ItemType.Weapon:
        return C.red;
      case ItemType.Armor:
        return C.accent;
      case ItemType.Shield:
        return C.amber;
      case ItemType.Consumable:
        return C.green;
      case ItemType.Tool:
        return C.amber;
      case ItemType.MagicItem:
        return C.amber;
      case ItemType.Potion:
        return C.green;
      case ItemType.Scroll:
        return C.accent;
      case ItemType.Treasure:
        return C.amber;
      case ItemType.Currency:
        return C.green;
      case ItemType.Material:
        return C.amber;
      case ItemType.Component:
        return C.amber;
      default:
        return C.accent;
    }
  }

  static IconData getTypeIcon(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return Icons.gavel;
      case ItemType.Armor:
        return Icons.shield;
      case ItemType.Shield:
        return Icons.shield_outlined;
      case ItemType.Consumable:
        return Icons.restaurant;
      case ItemType.Tool:
        return Icons.build;
      case ItemType.MagicItem:
        return Icons.auto_awesome;
      case ItemType.Potion:
        return Icons.local_drink;
      case ItemType.Scroll:
        return Icons.description;
      case ItemType.Treasure:
        return Icons.diamond;
      case ItemType.Currency:
        return Icons.monetization_on;
      case ItemType.Material:
        return Icons.science;
      case ItemType.Component:
        return Icons.category;
      default:
        return Icons.inventory_2_outlined;
    }
  }
}

/// Widget für eine Item-Karte in der Bibliothek-Auswahl
class LibraryItemCard extends StatelessWidget {
  final Item item;
  final EditCreatureViewModel viewModel;
  final TextEditingController quantityController;

  const LibraryItemCard({
    super.key,
    required this.item,
    required this.viewModel,
    required this.quantityController,
  });

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final typeColor = ItemTypeHelper.getTypeColor(item.itemType, C);
    final typeIcon = ItemTypeHelper.getTypeIcon(item.itemType);

    return ListTile(
      contentPadding: const EdgeInsets.all(16),
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
        style: TextStyle(
          fontSize: 14,
          color: C.text,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            ItemTypeHelper.getItemTypeDisplayName(item.itemType),
            style: TextStyle(fontSize: 12, color: typeColor),
          ),
          if (item.description.isNotEmpty)
            Text(
              item.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: C.textMid),
            ),
          if (item.cost > 0)
            Text(
              '${item.cost.toStringAsFixed(2)} Gold',
              style: TextStyle(fontSize: 12, color: C.amber),
            ),
        ],
      ),
      trailing: Icon(
        Icons.add_circle,
        color: C.green,
        size: 32,
      ),
      onTap: () => _showQuantityDialog(context),
    );
  }

  Future<void> _showQuantityDialog(BuildContext context) async {
    final C = context.appColors;
    final quantity = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          'Menge für "${item.name}"',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.amber),
        ),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          autofocus: true,
          style: TextStyle(fontSize: 14, color: C.text),
          decoration: InputDecoration(
            filled: true,
            fillColor: C.bgPanel,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: C.accent),
            ),
            hintText: 'Menge',
            hintStyle: TextStyle(fontSize: 12, color: C.textMid),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(fontSize: 14, color: C.accent),
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

    if (quantity != null && quantity > 0 && context.mounted) {
      final newItem = {
        'name': item.name,
        'description': item.description,
        'type': ItemTypeHelper.getItemTypeString(item.itemType),
        'quantity': quantity,
        'value': item.cost,
      };
      viewModel.addInventoryItem(newItem);
      if (context.mounted) {
        Navigator.of(context).pop();
        SnackBarHelper.showSuccess(
          context,
          '$quantity× ${item.name} zum Inventar hinzugefügt',
        );
      }
    }
  }
}
