import 'package:flutter/material.dart';
import '../../models/player_character.dart';
import '../../models/inventory_item.dart';
import '../../screens/unified_character_editor_screen.dart';
import 'character_list_helpers.dart';
import 'hero_avatar_widget.dart';
import 'hero_stats_chips_widget.dart';
import '../character_editor/inventory_demo_widget.dart';
import '../character_editor/item_color_helper.dart';

enum HeroCardViewMode {
  compact,
  detailed,
  grid,
  inventory,
}

/// Moderne Heldenkarte mit allen Informationen und Interaktionsmöglichkeiten
class EnhancedHeroCardWidget extends StatelessWidget {
  final PlayerCharacter character;
  final HeroCardViewMode viewMode;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onFavoriteToggle;
  final VoidCallback? onQuickAction;
  final bool isSelected;
  final double? elevation;

  const EnhancedHeroCardWidget({
    super.key,
    required this.character,
    this.viewMode = HeroCardViewMode.compact,
    this.onTap,
    this.onEdit,
    this.onFavoriteToggle,
    this.onQuickAction,
    this.isSelected = false,
    this.elevation,
  });

  @override
  Widget build(BuildContext context) {
    switch (viewMode) {
      case HeroCardViewMode.compact:
        return _buildCompactCard(context);
      case HeroCardViewMode.detailed:
        return _buildDetailedCard(context);
      case HeroCardViewMode.grid:
        return _buildGridCard(context);
      case HeroCardViewMode.inventory:
        return _buildInventoryCard(context);
    }
  }

  Widget _buildCompactCard(BuildContext context) {
    final classColor = CharacterListHelpers.getClassColor(character.className);
    
    return Card(
      elevation: elevation ?? 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: classColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar
              HeroAvatarWidget(
                character: character,
                size: 50,
                showLevelBadge: true,
              ),
              
              const SizedBox(width: 12),
              
              // Hauptinformationen
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name mit Favorit-Stern
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            character.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onFavoriteToggle != null)
                          IconButton(
                            icon: Icon(
                              character.isFavorite 
                                  ? Icons.star 
                                  : Icons.star_border,
                              color: character.isFavorite 
                                  ? Colors.amber[600] 
                                  : Colors.grey[400],
                              size: 20,
                            ),
                            onPressed: onFavoriteToggle,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 4),
                    
                    // Klasse und Spieler
                    Text(
                      '${character.raceName} ${character.className}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    
                    Text(
                      'Spieler: ${character.playerName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                    ),
                    
                    const SizedBox(height: 6),
                    
                    // Stats Chips
                    CompactHeroStatsChipsWidget(
                      character: character,
                      iconSize: 10,
                      fontSize: 8,
                    ),
                  ],
                ),
              ),
              
              // Action Buttons
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onQuickAction != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 20),
                      onPressed: onQuickAction,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedCard(BuildContext context) {
    final classColor = CharacterListHelpers.getClassColor(character.className);
    final topAttributes = CharacterListHelpers.getTopAttributes(character);
    
    return Card(
      elevation: elevation ?? 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected 
            ? BorderSide(color: classColor, width: 3)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Avatar und Basis-Info
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: classColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  HeroAvatarWidget(
                    character: character,
                    size: 60,
                    showLevelBadge: true,
                    showAlignment: true,
                  ),
                  
                  const SizedBox(width: 16),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name mit Favorit
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                character.name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (onFavoriteToggle != null)
                              IconButton(
                                icon: Icon(
                                  character.isFavorite 
                                      ? Icons.star 
                                      : Icons.star_border,
                                  color: character.isFavorite 
                                      ? Colors.amber[600] 
                                      : Colors.grey[400],
                                  size: 24,
                                ),
                                onPressed: onFavoriteToggle,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Klasse und Rasse
                        Text(
                          '${character.raceName} ${character.className}',
                          style: TextStyle(
                            fontSize: 14,
                            color: classColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        Text(
                          'Spieler: ${character.playerName}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        
                        if (character.description != null && character.description!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              character.description!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Stats Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Stats Chips
                  HeroStatsChipsWidget(character: character),
                  
                  const SizedBox(height: 12),
                  
                  // Top Attributes
                  Text(
                    'Wichtigste Attribute',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 6),
                  
                  Row(
                    children: topAttributes.map((attr) {
                      return Expanded(
                        child: _buildAttributeIndicator(
                          attr['name'] as String,
                          attr['value'] as int,
                          attr['label'] as String,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            // Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onQuickAction != null)
                    TextButton.icon(
                      onPressed: onQuickAction,
                      icon: const Icon(Icons.more_horiz),
                      label: const Text('Aktionen'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit),
                      label: const Text('Bearbeiten'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: classColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridCard(BuildContext context) {
    final classColor = CharacterListHelpers.getClassColor(character.className);
    
    return Card(
      elevation: elevation ?? 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected 
            ? BorderSide(color: classColor, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              HeroAvatarWidget(
                character: character,
                size: 40,
                showLevelBadge: true,
              ),
              
              const SizedBox(height: 8),
              
              // Name
              Text(
                character.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 4),
              
              // Klasse
              Text(
                character.className,
                style: TextStyle(
                  fontSize: 11,
                  color: classColor,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 6),
              
              // Kompakte Stats
              CompactHeroStatsChipsWidget(
                character: character,
                iconSize: 9,
                fontSize: 7,
              ),
              
              const SizedBox(height: 8),
              
              // Action Icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (onFavoriteToggle != null)
                    IconButton(
                      icon: Icon(
                        character.isFavorite 
                            ? Icons.star 
                            : Icons.star_border,
                        color: character.isFavorite 
                            ? Colors.amber[600] 
                            : Colors.grey[400],
                        size: 16,
                      ),
                      onPressed: onFavoriteToggle,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit, size: 16),
                      onPressed: onEdit,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                  if (onQuickAction != null)
                    IconButton(
                      icon: const Icon(Icons.more_vert, size: 16),
                      onPressed: onQuickAction,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 24,
                        minHeight: 24,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryCard(BuildContext context) {
    final classColor = CharacterListHelpers.getClassColor(character.className);
    final inventoryItems = character.inventory;
    final equippedItems = inventoryItems.where((item) => item.inventoryItem.isEquipped).toList();
    final unequippedItems = inventoryItems.where((item) => !item.inventoryItem.isEquipped).toList();
    
    return Card(
      elevation: elevation ?? 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected 
            ? BorderSide(color: classColor, width: 3)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header mit Charakter-Info
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: classColor.withOpacity(0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  HeroAvatarWidget(
                    character: character,
                    size: 50,
                    showLevelBadge: true,
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                character.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (onFavoriteToggle != null)
                              IconButton(
                                icon: Icon(
                                  character.isFavorite 
                                      ? Icons.star 
                                      : Icons.star_border,
                                  color: character.isFavorite 
                                      ? Colors.amber[600] 
                                      : Colors.grey[400],
                                  size: 20,
                                ),
                                onPressed: onFavoriteToggle,
                                padding: EdgeInsets.zero,
                              ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          '${character.raceName} ${character.className}',
                          style: TextStyle(
                            fontSize: 12,
                            color: classColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Gold-Anzeige
                        Row(
                          children: [
                            Icon(Icons.monetization_on, size: 14, color: Colors.amber[600]),
                            const SizedBox(width: 4),
                            Text(
                              '${character.gold.toStringAsFixed(1)} Gold',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (character.silver > 0) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.monetization_on, size: 14, color: Colors.grey[400]),
                              const SizedBox(width: 4),
                              Text(
                                '${character.silver.toStringAsFixed(1)} Silber',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                            if (character.copper > 0) ...[
                              const SizedBox(width: 8),
                              Icon(Icons.monetization_on, size: 14, color: Colors.brown[400]),
                              const SizedBox(width: 4),
                              Text(
                                '${character.copper.toStringAsFixed(1)} Kupfer',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Inventar-Bereich
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ausgerüstete Items
                    if (equippedItems.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 16, color: Colors.green[600]),
                          const SizedBox(width: 6),
                          Text(
                            'Ausgerüstet (${equippedItems.length})',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 60,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: equippedItems.length,
                          itemBuilder: (context, index) {
                            final displayItem = equippedItems[index];
                            final item = displayItem.item;
                            
                            return Container(
                              width: 50,
                              margin: const EdgeInsets.only(right: 8),
                              child: Column(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: ItemColorHelper.getItemTypeColor(item.itemType),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.green, width: 2),
                                    ),
                                    child: Icon(
                                      ItemColorHelper.getItemTypeIcon(item.itemType),
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.name.length > 8 
                                        ? '${item.name.substring(0, 8)}...'
                                        : item.name,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      color: Colors.grey,
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    
                    // Inventar-Items
                    Row(
                      children: [
                        Icon(Icons.inventory_2, size: 16, color: Colors.blue[600]),
                        const SizedBox(width: 6),
                        Text(
                          'Inventar (${unequippedItems.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                        const Spacer(),
                        if (unequippedItems.isNotEmpty)
                          Text(
                            '${unequippedItems.map((item) => item.item.weight * item.inventoryItem.quantity).fold(0.0, (a, b) => a + b).toStringAsFixed(1)} lbs',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    
                    // Inventar Grid
                    Expanded(
                      child: unequippedItems.isEmpty
                          ? Container(
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 32,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Keine Gegenstände',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[500],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 4,
                                childAspectRatio: 1,
                                crossAxisSpacing: 8,
                                mainAxisSpacing: 8,
                              ),
                              itemCount: unequippedItems.length > 8 ? 8 : unequippedItems.length,
                              itemBuilder: (context, index) {
                                final displayItem = unequippedItems[index];
                                final item = displayItem.item;
                                final quantity = displayItem.inventoryItem.quantity;
                                
                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[100],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey[300]!),
                                  ),
                                  child: Stack(
                                    children: [
                                      Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              ItemColorHelper.getItemTypeIcon(item.itemType),
                                              color: ItemColorHelper.getItemTypeColor(item.itemType),
                                              size: 20,
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              item.name.length > 10 
                                                  ? '${item.name.substring(0, 10)}...'
                                                  : item.name,
                                              style: const TextStyle(
                                                fontSize: 8,
                                                color: Colors.grey,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      // Mengen-Anzeige
                                      if (quantity > 1)
                                        Positioned(
                                          top: 2,
                                          right: 2,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                            decoration: BoxDecoration(
                                              color: Colors.blue[600],
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              quantity.toString(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      
                                      // Seltenheits-Indikator
                                      if (item.rarity != null && item.rarity != 'Common')
                                        Positioned(
                                          top: 2,
                                          left: 2,
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: _getRarityColor(item.rarity!),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    
                    // Mehr Items Indicator
                    if (unequippedItems.length > 8)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue[200]!),
                          ),
                          child: Center(
                            child: Text(
                              '+${unequippedItems.length - 8} weitere Gegenstände',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (onQuickAction != null)
                    TextButton.icon(
                      onPressed: onQuickAction,
                      icon: const Icon(Icons.more_horiz, size: 16),
                      label: const Text('Aktionen', style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  if (onEdit != null) ...[
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Bearbeiten', style: TextStyle(fontSize: 12)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: classColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributeIndicator(String name, int value, String label) {
    final color = CharacterListHelpers.getAttributeQualityColor(value);
    final modifier = CharacterListHelpers.getModifierDisplay(value);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            modifier,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'common':
        return Colors.grey;
      case 'uncommon':
        return Colors.green;
      case 'rare':
        return Colors.blue;
      case 'very rare':
        return Colors.purple;
      case 'legendary':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// Widget für die Anzeige von Quick-Actions in einem Popup-Menü
class HeroQuickActionsWidget extends StatelessWidget {
  final PlayerCharacter character;
  final VoidCallback? onEdit;
  final VoidCallback? onDuplicate;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;

  const HeroQuickActionsWidget({
    super.key,
    required this.character,
    this.onEdit,
    this.onDuplicate,
    this.onDelete,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'edit':
            onEdit?.call();
            break;
          case 'duplicate':
            onDuplicate?.call();
            break;
          case 'favorite':
            onToggleFavorite?.call();
            break;
          case 'delete':
            onDelete?.call();
            break;
        }
      },
      itemBuilder: (BuildContext context) {
        return [
          const PopupMenuItem<String>(
            value: 'edit',
            child: Row(
              children: [
                Icon(Icons.edit, size: 16),
                SizedBox(width: 8),
                Text('Bearbeiten'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy, size: 16),
                SizedBox(width: 8),
                Text('Duplizieren'),
              ],
            ),
          ),
          PopupMenuItem<String>(
            value: 'favorite',
            child: Row(
              children: [
                Icon(
                  character.isFavorite ? Icons.star : Icons.star_border,
                  size: 16,
                  color: character.isFavorite ? Colors.amber : null,
                ),
                SizedBox(width: 8),
                Text(character.isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen'),
              ],
            ),
          ),
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 16, color: Colors.red),
                SizedBox(width: 8),
                Text('Löschen', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
        ];
      },
    );
  }
}
