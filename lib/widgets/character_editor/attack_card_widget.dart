import 'package:flutter/material.dart';
import '../../models/attack.dart';

class AttackCardWidget extends StatelessWidget {
  final Attack attack;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool showEditButton;
  final bool showDeleteButton;

  const AttackCardWidget({
    super.key,
    required this.attack,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.showEditButton = true,
    this.showDeleteButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Name und Aktionen
              Row(
                children: [
                  Expanded(
                    child: Text(
                      attack.name.isNotEmpty ? attack.name : 'Unbenannter Angriff',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  if (showEditButton)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      tooltip: 'Bearbeiten',
                      color: Colors.blue,
                    ),
                  if (showDeleteButton)
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20),
                      onPressed: onDelete,
                      tooltip: 'Löschen',
                      color: Colors.red,
                    ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Angriffsbonus und Schaden
              Row(
                children: [
                  _buildStatChip(
                    'Angriff',
                    attack.formattedAttackBonus,
                    _getAttackBonusColor(attack.attackBonus),
                    Icons.gavel,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    'Schaden',
                    attack.totalDamage,
                    _getDamageColor(attack.damageDice),
                    Icons.flash_on,
                  ),
                  const SizedBox(width: 12),
                  _buildStatChip(
                    'Art',
                    attack.damageType,
                    Colors.grey[600]!,
                    Icons.local_fire_department,
                  ),
                ],
              ),
              
              // Zusätzliche Informationen
              if (attack.range != null || attack.abilityUsed != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (attack.range != null) ...[
                      Icon(
                        Icons.my_location,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        attack.range!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (attack.range != null && attack.abilityUsed != null)
                      const SizedBox(width: 16),
                    if (attack.abilityUsed != null) ...[
                      Icon(
                        Icons.fitness_center,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        attack.abilityUsed!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                    if (attack.isProficient) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.withOpacity(0.5)),
                        ),
                        child: const Text(
                          'Proficient',
                          style: TextStyle(
                            color: Colors.green,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
              
              // Beschreibung
              if (attack.description != null && attack.description!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    attack.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: color.withOpacity(0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getAttackBonusColor(int bonus) {
    if (bonus >= 8) return Colors.purple[700]!;
    if (bonus >= 6) return Colors.purple[600]!;
    if (bonus >= 4) return Colors.blue[600]!;
    if (bonus >= 2) return Colors.blue[500]!;
    if (bonus >= 0) return Colors.blue[400]!;
    if (bonus >= -2) return Colors.orange[600]!;
    return Colors.red[600]!;
  }

  Color _getDamageColor(String damageDice) {
    // Extrahiere die Würfelgröße für die Farbzuordnung
    final diceMatch = RegExp(r'W(\d+)').firstMatch(damageDice);
    if (diceMatch != null) {
      final diceSize = int.tryParse(diceMatch.group(1)!) ?? 6;
      if (diceSize >= 12) return Colors.red[700]!;
      if (diceSize >= 10) return Colors.red[600]!;
      if (diceSize >= 8) return Colors.orange[600]!;
      if (diceSize >= 6) return Colors.green[600]!;
      if (diceSize >= 4) return Colors.blue[600]!;
      return Colors.grey[600]!;
    }
    return Colors.grey[600]!;
  }
}

// Kompakte Version für Listen
class CompactAttackCardWidget extends StatelessWidget {
  final Attack attack;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CompactAttackCardWidget({
    super.key,
    required this.attack,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: _getAttackBonusColor(attack.attackBonus).withOpacity(0.2),
          child: Text(
            attack.formattedAttackBonus,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: _getAttackBonusColor(attack.attackBonus),
            ),
          ),
        ),
        title: Text(
          attack.name.isNotEmpty ? attack.name : 'Unbenannter Angriff',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          '${attack.totalDamage} ${attack.damageType}',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (attack.isProficient)
              Icon(
                Icons.check_circle,
                size: 16,
                color: Colors.green[600],
              ),
            if (onEdit != null || onDelete != null) ...[
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 16),
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit?.call();
                      break;
                    case 'delete':
                      onDelete?.call();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  if (onEdit != null)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 16),
                          SizedBox(width: 8),
                          Text('Bearbeiten'),
                        ],
                      ),
                    ),
                  if (onDelete != null)
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 16, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Löschen', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Color _getAttackBonusColor(int bonus) {
    if (bonus >= 8) return Colors.purple[700]!;
    if (bonus >= 6) return Colors.purple[600]!;
    if (bonus >= 4) return Colors.blue[600]!;
    if (bonus >= 2) return Colors.blue[500]!;
    if (bonus >= 0) return Colors.blue[400]!;
    if (bonus >= -2) return Colors.orange[600]!;
    return Colors.red[600]!;
  }
}
