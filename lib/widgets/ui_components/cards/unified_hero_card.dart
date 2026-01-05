import 'package:flutter/material.dart';
import '../../../models/player_character.dart';
import '../base/unified_card_base.dart';
import '../base/card_header_widget.dart';
import '../base/card_content_widget.dart';
import '../base/card_actions_widget.dart';
import '../base/card_metadata_widget.dart';
import '../shared/unified_card_theme.dart';

/// Unified Hero Card
/// 
/// Beispielimplementierung für Helden/Player Characters unter Verwendung des neuen Card-Systems
class UnifiedHeroCard extends UnifiedCardBase {
  final PlayerCharacter hero;

  const UnifiedHeroCard({
    super.key,
    required this.hero,
    super.onTap,
    super.onEdit,
    super.onDelete,
    super.onToggleFavorite,
    super.isSelected,
    super.showActions,
    super.isFavorite,
  });

  @override
  bool get isFavorite => hero.isFavorite;

  @override
  Widget buildCardContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(UnifiedCardBase.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          CardHeaderWidget(
            title: hero.name,
            subtitle: _buildSubtitle(),
            leadingIcon: Icons.person,
            iconColor: UnifiedCardTheme.getIconColor('hero'),
            iconBackgroundColor: UnifiedCardTheme.getIconBackgroundColor('hero'),
            additionalInfo: [
              _buildInfoChip(
                Icons.group,
                hero.playerName,
              ),
              if (hero.alignment != null)
                _buildInfoChip(
                  Icons.shield,
                  hero.alignment!,
                ),
            ],
            onFavoriteToggle: onToggleFavorite,
            isFavorite: isFavorite,
            popupMenuItems: _buildPopupMenuItems(context),
            onPopupMenuItemSelected: (value) => _handlePopupMenuAction(context, value),
          ),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Description
          if (hero.description != null && hero.description!.isNotEmpty)
            CardContentWidget(
              description: hero.description!,
              descriptionMaxLines: 2,
            ),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Stats Row
          _buildStatsRow(),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Attributes Preview
          _buildAttributesPreview(),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Currency
          _buildCurrencyInfo(),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Metadata
          CardMetadataWidget(
            itemCount: hero.inventory.length,
            customMetadata: {
              'Klasse': hero.className,
              'Rasse': hero.raceName,
              'Level': '${hero.level}',
              'Prof. Bonus': '+${hero.proficiencyBonus}',
            },
          ),
          
          const SizedBox(height: UnifiedCardBase.defaultSpacing),
          
          // Actions
          CardActionsWidget(
            onEdit: onEdit,
            onDelete: onDelete,
            onQuickAction: () => _showQuickActions(context),
            alignment: MainAxisAlignment.end,
          ),
        ],
      ),
    );
  }

  String _buildSubtitle() {
    return '${hero.raceName} ${hero.className} • Level ${hero.level}';
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[700],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        _buildStatChip(
          Icons.favorite,
          'HP',
          '${hero.maxHp}',
          Colors.red,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          Icons.shield,
          'AC',
          '${hero.armorClass}',
          Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          Icons.flash_on,
          'Init',
          hero.initiativeBonus >= 0 ? '+${hero.initiativeBonus}' : '${hero.initiativeBonus}',
          Colors.orange,
        ),
        const SizedBox(width: 8),
        _buildStatChip(
          Icons.speed,
          'Bew.',
          '${hero.speed} ft',
          Colors.green,
        ),
      ],
    );
  }

  Widget _buildStatChip(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: color.withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 12, color: color),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributesPreview() {
    return Row(
      children: [
        _buildAttributeChip('STR', hero.strength),
        const SizedBox(width: 8),
        _buildAttributeChip('DEX', hero.dexterity),
        const SizedBox(width: 8),
        _buildAttributeChip('CON', hero.constitution),
        const SizedBox(width: 8),
        _buildAttributeChip('INT', hero.intelligence),
        const SizedBox(width: 8),
        _buildAttributeChip('WIS', hero.wisdom),
        const SizedBox(width: 8),
        _buildAttributeChip('CHA', hero.charisma),
      ],
    );
  }

  Widget _buildAttributeChip(String label, int value) {
    final modifier = _calculateModifier(value);
    final modifierText = modifier >= 0 ? '+$modifier' : '$modifier';
    
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              modifierText,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: modifier >= 0 ? Colors.green[700] : Colors.red[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _calculateModifier(int score) {
    return ((score - 10) / 2).floor();
  }

  Widget _buildCurrencyInfo() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.amber[50]?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.amber[200]!.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          if (hero.gold > 0) ...[
            Icon(Icons.monetization_on, size: 14, color: Colors.amber[700]),
            const SizedBox(width: 4),
            Text(
              '${hero.gold.toStringAsFixed(0)} Gold',
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hero.silver > 0 || hero.copper > 0) const SizedBox(width: 12),
          ],
          if (hero.silver > 0) ...[
            Icon(Icons.circle, size: 8, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              '${hero.silver.toStringAsFixed(0)} Silber',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            if (hero.copper > 0) const SizedBox(width: 12),
          ],
          if (hero.copper > 0) ...[
            Icon(Icons.circle, size: 8, color: Colors.brown[400]),
            const SizedBox(width: 4),
            Text(
              '${hero.copper.toStringAsFixed(0)} Kupfer',
              style: TextStyle(
                fontSize: 11,
                color: Colors.brown[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<PopupMenuItem<String>> _buildPopupMenuItems(BuildContext context) {
    return [
      const PopupMenuItem(
        value: 'duplicate',
        child: Row(
          children: [
            Icon(Icons.copy, size: 16),
            SizedBox(width: 8),
            Text('Duplizieren'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'export',
        child: Row(
          children: [
            Icon(Icons.file_download, size: 16),
            SizedBox(width: 8),
            Text('Exportieren'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'archive',
        child: Row(
          children: [
            Icon(Icons.archive, size: 16),
            SizedBox(width: 8),
            Text('Archivieren'),
          ],
        ),
      ),
      const PopupMenuItem(
        value: 'share',
        child: Row(
          children: [
            Icon(Icons.share, size: 16),
            SizedBox(width: 8),
            Text('Teilen'),
          ],
        ),
      ),
    ];
  }

  void _handlePopupMenuAction(BuildContext context, String action) {
    switch (action) {
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Held duplizieren...')),
        );
        break;
      case 'export':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Held exportieren...')),
        );
        break;
      case 'archive':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Held archivieren...')),
        );
        break;
      case 'share':
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Held teilen...')),
        );
        break;
    }
  }

  void _showQuickActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.inventory),
              title: const Text('Inventar verwalten'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Inventar verwalten...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.gavel),
              title: const Text('Angriffe bearbeiten'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Angriffe bearbeiten...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome),
              title: const Text('Spezialfähigkeiten'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Spezialfähigkeiten...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.psychology),
              title: const Text('Fertigkeiten'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Fertigkeiten...')),
                );
              },
            ),
            if (hero.spellSlots != null && hero.spellSlots!.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.auto_fix_high),
                title: const Text('Zauber-Slots verwalten'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Zauber-Slots verwalten...')),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.calculate),
              title: const Text('Level Up'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Level Up...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('HP wiederherstellen'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('HP wiederherstellen...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
