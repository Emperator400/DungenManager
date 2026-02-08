import 'package:flutter/material.dart';
import '../../../models/inventory_item.dart';
import '../../../models/item.dart';
import '../../../models/equipment.dart';
import '../../../theme/dnd_theme.dart';
import '../cards/section_card_widget.dart';

/// Widget zur Anzeige und Verwaltung der Ausrüstung
/// Ähnlich wie in echten RPG-Spielen
/// 
/// Beispiele:
/// ```dart
/// EquipmentWidget(
///   equipment: viewModel.equipment,
///   onEquipItem: (slot, displayItem) => // Item ausrüsten
///   onUnequipItem: (slot) => // Item ablegen
/// )
/// ```
class EquipmentWidget extends StatelessWidget {
  final Map<EquipmentSlot, DisplayInventoryItem?> equipment;
  final Function(EquipmentSlot slot, DisplayInventoryItem item)? onEquipItem;
  final Function(EquipmentSlot slot)? onUnequipItem;
  final String? title;

  const EquipmentWidget({
    super.key,
    required this.equipment,
    this.onEquipItem,
    this.onUnequipItem,
    this.title = 'Ausrüstung',
  });

  @override
  Widget build(BuildContext context) {
    return SectionCardWidget(
      title: title ?? 'Ausrüstung',
      icon: Icons.shield,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeaponSection(context),
          const SizedBox(height: DnDTheme.lg),
          _buildArmorSection(context),
          const SizedBox(height: DnDTheme.lg),
          _buildAccessorySection(context),
          const SizedBox(height: DnDTheme.lg),
          _buildJewelrySection(context),
        ],
      ),
    );
  }

  /// Waffen-Sektion (Primär & Sekundär)
  Widget _buildWeaponSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.gavel, color: DnDTheme.ancientGold, size: 20),
            const SizedBox(width: 8),
            Text(
              'Waffen',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: DnDTheme.md),
        Row(
          children: [
            Expanded(
              child: _buildEquipmentSlot(
                context,
                slot: EquipmentSlot.weaponPrimary,
                label: 'Hauptwaffe',
                icon: Icons.sports_martial_arts,
              ),
            ),
            const SizedBox(width: DnDTheme.md),
            Expanded(
              child: _buildEquipmentSlot(
                context,
                slot: EquipmentSlot.weaponSecondary,
                label: 'Nebenwaffe',
                icon: Icons.sports_kabaddi,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Rüstung-Sektion (Helm, Rüstung, Schild, Handschuhe, Stiefel)
  Widget _buildArmorSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.security, color: DnDTheme.ancientGold, size: 20),
            const SizedBox(width: 8),
            Text(
              'Rüstung',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: DnDTheme.md),
        Row(
          children: [
            Expanded(
              child: _buildEquipmentSlot(
                context,
                slot: EquipmentSlot.helmet,
                label: 'Helm',
                icon: Icons.motorcycle,
              ),
            ),
            const SizedBox(width: DnDTheme.md),
            Expanded(
              child: _buildEquipmentSlot(
                context,
                slot: EquipmentSlot.armor,
                label: 'Rüstung',
                icon: Icons.security,
              ),
            ),
          ],
        ),
        const SizedBox(height: DnDTheme.md),
        Row(
          children: [
            Expanded(
              child: _buildEquipmentSlot(
                context,
                slot: EquipmentSlot.shield,
                label: 'Schild',
                icon: Icons.shield,
              ),
            ),
            const SizedBox(width: DnDTheme.md),
            Expanded(
              child: _buildEquipmentSlot(
                context,
                slot: EquipmentSlot.gloves,
                label: 'Handschuhe',
                icon: Icons.back_hand,
              ),
            ),
          ],
        ),
        const SizedBox(height: DnDTheme.md),
        _buildEquipmentSlot(
          context,
          slot: EquipmentSlot.boots,
          label: 'Stiefel',
          icon: Icons.hiking,
          fullWidth: true,
        ),
      ],
    );
  }

  /// Zubehör-Sektion (Umhang)
  Widget _buildAccessorySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.checkroom, color: DnDTheme.ancientGold, size: 20),
            const SizedBox(width: 8),
            Text(
              'Zubehör',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: DnDTheme.md),
        _buildEquipmentSlot(
          context,
          slot: EquipmentSlot.cloak,
          label: 'Umhang',
          icon: Icons.ac_unit,
          fullWidth: true,
        ),
      ],
    );
  }

  /// Schmuck-Sektion (Ringe, Amulett)
  Widget _buildJewelrySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.diamond, color: DnDTheme.ancientGold, size: 20),
            const SizedBox(width: 8),
            Text(
              'Schmuck',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: DnDTheme.md),
        Row(
          children: [
            Expanded(
              child: _buildEquipmentSlot(
                context,
                slot: EquipmentSlot.ring1,
                label: 'Ring 1',
                icon: Icons.radio_button_unchecked,
              ),
            ),
            const SizedBox(width: DnDTheme.md),
            Expanded(
              child: _buildEquipmentSlot(
                context,
                slot: EquipmentSlot.ring2,
                label: 'Ring 2',
                icon: Icons.radio_button_unchecked,
              ),
            ),
          ],
        ),
        const SizedBox(height: DnDTheme.md),
        _buildEquipmentSlot(
          context,
          slot: EquipmentSlot.amulet,
          label: 'Amulett',
          icon: Icons.cable,
          fullWidth: true,
        ),
      ],
    );
  }

  /// Einzelner Equipment-Slot
  Widget _buildEquipmentSlot(
    BuildContext context, {
    required EquipmentSlot slot,
    required String label,
    required IconData icon,
    bool fullWidth = false,
  }) {
    final equippedItem = equipment[slot];
    final isEquipped = equippedItem != null;

    return GestureDetector(
      onTap: () => _showEquipmentDialog(context, slot, label),
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(DnDTheme.md),
        decoration: BoxDecoration(
          color: DnDTheme.stoneGrey,
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          border: Border.all(
            color: isEquipped ? DnDTheme.ancientGold : DnDTheme.slateGrey,
            width: isEquipped ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: DnDTheme.ancientGold,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: DnDTheme.bodyText2.copyWith(
                    color: DnDTheme.ancientGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DnDTheme.sm),
            if (isEquipped && equippedItem != null)
              _buildEquippedItemInfo(equippedItem)
            else
              _buildEmptySlot(),
          ],
        ),
      ),
    );
  }

  /// Zeigt Infos zum ausgerüsteten Item
  Widget _buildEquippedItemInfo(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final invItem = displayItem.inventoryItem;

    return Container(
      padding: const EdgeInsets.all(DnDTheme.sm),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DnDTheme.arcaneBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getItemIcon(item.itemType),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: DnDTheme.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item.name,
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (invItem.quantity > 1)
                  Text(
                    'x${invItem.quantity}',
                    style: DnDTheme.bodyText2.copyWith(
                      color: DnDTheme.ancientGold,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Zeigt einen leeren Slot
  Widget _buildEmptySlot() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.sm),
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
      ),
      child: Text(
        'Leer',
        style: DnDTheme.bodyText2.copyWith(
          color: Colors.white38,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  /// Zeigt Dialog zum Auswählen/Ablegen von Equipment
  void _showEquipmentDialog(
    BuildContext context,
    EquipmentSlot slot,
    String slotName,
  ) {
    final equippedItem = equipment[slot];

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          slotName,
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
              Text(
                'Aktuell ausgerüstet:',
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
            if (equippedItem == null) ...[
              Icon(
                Icons.inventory_2_outlined,
                size: 48,
                color: DnDTheme.mysticalPurple.withOpacity(0.6),
              ),
              const SizedBox(height: DnDTheme.md),
              Text(
                'Kein Gegenstand ausgerüstet',
                style: DnDTheme.bodyText1.copyWith(
                  color: Colors.white60,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (equippedItem != null)
            TextButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (onUnequipItem != null) {
                  onUnequipItem!(slot);
                }
              },
              icon: const Icon(Icons.undo),
              label: Text(
                'Ablegen',
                style: DnDTheme.bodyText1.copyWith(
                  color: DnDTheme.errorRed,
                ),
              ),
            ),
          if (onEquipItem != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                // Hier müsste man eine Item-Auswahl öffnen
                // Das könnte z.B. das UnifiedInventoryWidget sein
                // mit Filter für den spezifischen Slot-Typ
              },
              icon: const Icon(Icons.add),
              label: const Text('Ausrüsten'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.ancientGold,
                foregroundColor: DnDTheme.dungeonBlack,
              ),
            ),
        ],
      ),
    );
  }

  /// Gibt ein Icon basierend auf dem Item-Typ zurück
  IconData _getItemIcon(ItemType itemType) {
    switch (itemType) {
      case ItemType.Weapon:
        return Icons.sports_martial_arts;
      case ItemType.Armor:
        return Icons.security;
      case ItemType.Shield:
        return Icons.shield;
      case ItemType.Potion:
        return Icons.local_drink;
      case ItemType.MagicItem:
        return Icons.auto_fix_high;
      case ItemType.Tool:
        return Icons.build;
      case ItemType.Material:
        return Icons.inventory_2;
      case ItemType.AdventuringGear:
        return Icons.backpack;
      default:
        return Icons.inventory_2;
    }
  }
}
