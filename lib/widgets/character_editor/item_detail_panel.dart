import 'package:flutter/material.dart';
import '../../models/item.dart';
import '../../models/inventory_item.dart';
import '../../models/equip_slot.dart';
import 'item_color_helper.dart';

class ItemDetailPanel extends StatelessWidget {
  final DisplayInventoryItem displayItem;
  final VoidCallback onClose;
  final VoidCallback? onEquip;
  final VoidCallback? onUnequip;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool canEdit;
  final bool isVisible;

  const ItemDetailPanel({
    super.key,
    required this.displayItem,
    required this.onClose,
    this.onEquip,
    this.onUnequip,
    this.onEdit,
    this.onDelete,
    this.canEdit = true,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final item = displayItem.item;
    final inventoryItem = displayItem.inventoryItem;

    return GestureDetector(
      onTap: onClose,
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Row(
          children: [
            const Expanded(child: SizedBox.shrink()),
            _buildPanel(context, item, inventoryItem),
          ],
        ),
      ),
    );
  }

  Widget _buildPanel(BuildContext context, Item item, InventoryItem inventoryItem) {
    return GestureDetector(
      onTap: () {}, // Verhindert Schließen beim Klick auf das Panel
      child: Container(
        width: 400,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(-5, 0),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header mit Schließen-Button
            _buildHeader(item),
            
            // Content mit ScrollView
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Item-Bild und Basis-Infos
                    _buildItemOverview(item, inventoryItem),
                    
                    const SizedBox(height: 24),
                    
                    // Detaillierte Informationen basierend auf Item-Typ
                    _buildTypeSpecificDetails(item),
                    
                    const SizedBox(height: 24),
                    
                    // Beschreibung
                    if (item.description.isNotEmpty) ...[
                      _buildSectionTitle('Beschreibung'),
                      const SizedBox(height: 8),
                      Text(
                        item.description,
                        style: TextStyle(
                          color: Colors.grey.shade300,
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    
                    // Magische Eigenschaften
                    _buildMagicalProperties(item),
                  ],
                ),
              ),
            ),
            
            // Aktionen
            if (canEdit) _buildActions(item, inventoryItem),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Item item) {
    final rarityColor = item.rarity != null 
        ? ItemColorHelper.getRarityColor(item.rarity!)
        : Colors.grey.shade600;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade700,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Item-Typ Icon
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: ItemColorHelper.getItemTypeColor(item.itemType),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ItemColorHelper.getItemTypeIcon(item.itemType),
              color: Colors.white,
              size: 28,
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Titel
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      ItemColorHelper.getItemTypeDisplayName(item.itemType),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                    if (item.rarity != null && item.rarity!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: rarityColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          item.rarity!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Schließen-Button
          IconButton(
            onPressed: onClose,
            icon: const Icon(
              Icons.close,
              color: Colors.white,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemOverview(Item item, InventoryItem inventoryItem) {
    return Card(
      color: Colors.grey.shade800,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basis-Informationen',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard('Gewicht', '${item.weight} lbs'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInfoCard('Wert', '${item.cost.toStringAsFixed(0)} Gold'),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoCard('Menge', '${inventoryItem.quantity} Stück'),
                ),
                if (item.hasDurability == true && item.maxDurability != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDurabilityCard(displayItem),
                  ),
                ] else ...[
                  const Expanded(child: SizedBox()),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSpecificDetails(Item item) {
    switch (item.itemType) {
      case ItemType.Weapon:
        return _buildWeaponDetails(item);
      case ItemType.Armor:
        return _buildArmorDetails(item);
      case ItemType.Shield:
        return _buildShieldDetails(item);
      case ItemType.SPELL_WEAPON:
        return _buildSpellDetails(item);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildWeaponDetails(Item item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Waffen-Eigenschaften'),
        const SizedBox(height: 12),
        if (item.damage != null) _buildInfoRow('Schaden', item.damage!),
        if (item.properties != null) _buildInfoRow('Eigenschaften', item.properties!),
      ],
    );
  }

  Widget _buildArmorDetails(Item item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Rüstungs-Eigenschaften'),
        const SizedBox(height: 12),
        if (item.acFormula != null) _buildInfoRow('Rüstungsklasse', item.acFormula!),
        if (item.strengthRequirement != null) 
          _buildInfoRow('Stärke-Anforderung', '${item.strengthRequirement}'),
        if (item.stealthDisadvantage == true)
          _buildInfoRow('Verstecken', 'Nachteil'),
      ],
    );
  }

  Widget _buildShieldDetails(Item item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Schild-Eigenschaften'),
        const SizedBox(height: 12),
        if (item.acFormula != null) _buildInfoRow('Bonus', item.acFormula!),
      ],
    );
  }

  Widget _buildSpellDetails(Item item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Zauber-Informationen'),
        const SizedBox(height: 12),
        if (item.spellLevel != null) _buildInfoRow('Stufe', '${item.spellLevel}'),
        if (item.spellSchool != null) _buildInfoRow('Schule', item.spellSchool!),
        if (item.isCantrip == true) _buildInfoRow('Kantrip', 'Ja'),
        if (item.requiresConcentration == true) 
          _buildInfoRow('Konzentration', 'Erforderlich'),
        if (item.maxCastsPerDay != null) 
          _buildInfoRow('Maximal pro Tag', '${item.maxCastsPerDay}'),
      ],
    );
  }

  Widget _buildMagicalProperties(Item item) {
    if (item.rarity == null || item.rarity!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Magische Eigenschaften'),
        const SizedBox(height: 12),
        _buildInfoRow('Seltenheit', item.rarity!),
        if (item.requiresAttunement == true)
          _buildInfoRow('Bindung erforderlich', 'Ja'),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurabilityRow(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final current = displayItem.currentDurability ?? item.maxDurability ?? 100;
    final max = item.maxDurability ?? 100;
    final percentage = current / max;
    final durabilityColor = ItemColorHelper.getDurabilityColor(percentage);

    return Row(
      children: [
        Text(
          'Haltbarkeit',
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: Colors.grey.shade700,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: percentage,
              child: Container(
                decoration: BoxDecoration(
                  color: durabilityColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$current/$max',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDurabilityCard(DisplayInventoryItem displayItem) {
    final item = displayItem.item;
    final current = displayItem.currentDurability ?? item.maxDurability ?? 100;
    final max = item.maxDurability ?? 100;
    final percentage = current / max;
    final durabilityColor = ItemColorHelper.getDurabilityColor(percentage);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Haltbarkeit',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade600,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: durabilityColor,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$current/$max',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions(Item item, InventoryItem inventoryItem) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        border: Border(
          top: BorderSide(
            color: Colors.grey.shade700,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Ausrüsten/Ablegen
          if (inventoryItem.isEquipped) ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onUnequip,
                icon: const Icon(Icons.remove_circle_outline),
                label: const Text('Ablegen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ] else ...[
            Expanded(
              child: ElevatedButton.icon(
                onPressed: onEquip,
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Ausrüsten'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
          
          const SizedBox(width: 12),
          
          // Bearbeiten
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.edit),
              label: const Text('Bearbeiten'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Löschen
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete, color: Colors.red),
          ),
        ],
      ),
    );
  }
}
