// lib/widgets/character_editor/enhanced_hotbar_widget.dart
import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/inventory_item.dart';
import '../../models/equip_slot.dart';
import '../../models/spell_slot_manager.dart';

class EnhancedHotbarWidget extends StatefulWidget {
  final List<DisplayInventoryItem> equippedWeapons;
  final List<DisplayInventoryItem> equippedSpells;
  final SpellSlotManager? spellSlotManager;
  final Function(DisplayInventoryItem)? onQuickEquip;
  final Function(DisplayInventoryItem)? onQuickUse;
  final bool canEditItems;

  const EnhancedHotbarWidget({
    super.key,
    required this.equippedWeapons,
    required this.equippedSpells,
    this.spellSlotManager,
    this.onQuickEquip,
    this.onQuickUse,
    this.canEditItems = true,
  });

  @override
  State<EnhancedHotbarWidget> createState() => _EnhancedHotbarWidgetState();
}

class _EnhancedHotbarWidgetState extends State<EnhancedHotbarWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SCHNELLEINSTIEGUNG',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Weapon Hotbar (4 Slots)
            _buildHotbarSection(
              'WAFFEN',
              '4 schnelle Waffen-Slots',
              [
                EquipSlot.mainHand,
                EquipSlot.offHand,
                EquipSlot.ranged,
                null, // Extra slot für zukünftige Erweiterungen
              ],
              widget.equippedWeapons,
              Colors.red,
            ),
            
            const SizedBox(height: 16),
            
            // Spell Hotbar (4 Slots)
            _buildSpellHotbarSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHotbarSection(
    String title,
    String description,
    List<EquipSlot?> slots,
    List<DisplayInventoryItem> items,
    Color primaryColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: slots.asMap().entries.map((entry) {
            final index = entry.key;
            final slot = entry.value;
            
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: index < slots.length - 1 ? 4.0 : 0.0,
                ),
                child: _buildHotbarSlot(slot, items, index, primaryColor),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSpellHotbarSection() {
    if (widget.spellSlotManager == null) {
      return const Text(
        'Kein Spell Slot Manager verfügbar',
        style: TextStyle(color: Colors.red),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'ZAUBER',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Cantrips & vorbereitete Zauber',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            // Cantrip Slot
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4.0),
                child: _buildSpellSlot(
                  EquipSlot.cantripReady,
                  widget.equippedSpells,
                  'Cantrip',
                  Colors.orange,
                  isCantrip: true,
                ),
              ),
            ),
            // 3 Prepared Spell Slots
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: _buildSpellSlot(
                  EquipSlot.spellPrepared1,
                  widget.equippedSpells,
                  'Zauber 1',
                  Colors.deepPurple,
                  spellLevel: 1,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2.0),
                child: _buildSpellSlot(
                  EquipSlot.spellPrepared2,
                  widget.equippedSpells,
                  'Zauber 2',
                  Colors.deepPurple,
                  spellLevel: 2,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4.0),
                child: _buildSpellSlot(
                  EquipSlot.spellPrepared3,
                  widget.equippedSpells,
                  'Zauber 3',
                  Colors.deepPurple,
                  spellLevel: 3,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHotbarSlot(
    EquipSlot? slot,
    List<DisplayInventoryItem> items,
    int index,
    Color primaryColor,
  ) {
    final equippedItem = slot != null
        ? items.firstWhere(
            (item) => item.inventoryItem.equipSlot == slot,
            orElse: () => DisplayInventoryItem(
              inventoryItem: InventoryItem(
                id: '',
                ownerId: '',
                itemId: '',
                isEquipped: false,
                equipSlot: slot,
              ),
              item: Item(
                id: '',
                name: '',
                itemType: ItemType.Weapon,
              ),
            ),
          )
        : null;

    return GestureDetector(
      onTap: equippedItem != null && widget.onQuickUse != null
          ? () => widget.onQuickUse!(equippedItem!)
          : null,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            color: equippedItem != null ? primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: equippedItem != null ? primaryColor.withOpacity(0.1) : Colors.grey.shade100,
        ),
        child: Stack(
          children: [
            // Slot-Nummer
            if (slot != null)
              Positioned(
                top: 2,
                left: 2,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            
            // Item-Icon und Name
            if (equippedItem?.item.id.isEmpty == false)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getItemTypeIcon(equippedItem!.item.itemType),
                        color: primaryColor,
                        size: 20,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        equippedItem!.item.name.length > 10
                            ? '${equippedItem!.item.name.substring(0, 8)}...'
                            : equippedItem!.item.name,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            
            // Empty Slot Icon
            if (equippedItem?.item.id.isEmpty == true && slot != null)
              Center(
                child: Text(
                  slot!.iconName,
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpellSlot(
    EquipSlot slot,
    List<DisplayInventoryItem> spells,
    String slotName,
    Color primaryColor, {
    int? spellLevel,
    bool isCantrip = false,
  }) {
    final equippedSpell = spells.firstWhere(
      (spell) => spell.inventoryItem.equipSlot == slot,
      orElse: () => DisplayInventoryItem(
        inventoryItem: InventoryItem(
          id: '',
          ownerId: '',
          itemId: '',
          isEquipped: false,
          equipSlot: slot,
        ),
        item: Item(
          id: '',
          name: '',
          itemType: ItemType.SPELL_WEAPON,
        ),
      ),
    );

    int? remainingCasts;
    if (!isCantrip && spellLevel != null && widget.spellSlotManager != null) {
      remainingCasts = widget.spellSlotManager!.getRemainingSlots(spellLevel!);
    }

    return GestureDetector(
      onTap: equippedSpell.item.id.isNotEmpty && widget.onQuickUse != null
          ? () => widget.onQuickUse!(equippedSpell)
          : null,
      child: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border.all(
            color: equippedSpell.item.id.isNotEmpty ? primaryColor : Colors.grey.shade300,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: equippedSpell.item.id.isNotEmpty 
              ? primaryColor.withOpacity(0.1) 
              : Colors.grey.shade100,
        ),
        child: Stack(
          children: [
            // Slot-Name
            Positioned(
              top: 2,
              left: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: primaryColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  slotName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            // Spell-Icon und Name
            if (equippedSpell.item.id.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.flourescent,
                        color: primaryColor,
                        size: 18,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        equippedSpell.item.name.length > 12
                            ? '${equippedSpell.item.name.substring(0, 10)}...'
                            : equippedSpell.item.name,
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (remainingCasts != null)
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: remainingCasts! > 0 ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '$remainingCasts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 7,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            
            // Empty Spell Slot
            if (equippedSpell.item.id.isEmpty)
              Center(
                child: Text(
                  slot.iconName,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade400,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getItemTypeIcon(ItemType type) {
    switch (type) {
      case ItemType.Weapon:
        return Icons.gavel;
      case ItemType.Armor:
        return Icons.security;
      case ItemType.Shield:
        return Icons.shield;
      case ItemType.SPELL_WEAPON:
        return Icons.flourescent;
      default:
        return Icons.category;
    }
  }
}
