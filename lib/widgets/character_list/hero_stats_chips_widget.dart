import 'package:flutter/material.dart';
import '../../models/player_character.dart';
import 'character_list_helpers.dart';

/// Widget für die Anzeige von Status-Chips (Level, HP, AC, Initiative)
class HeroStatsChipsWidget extends StatelessWidget {
  final PlayerCharacter character;
  final bool showLevel;
  final bool showHp;
  final bool showAc;
  final bool showInitiative;
  final double chipHeight;
  final EdgeInsets spacing;

  const HeroStatsChipsWidget({
    super.key,
    required this.character,
    this.showLevel = true,
    this.showHp = true,
    this.showAc = true,
    this.showInitiative = true,
    this.chipHeight = 28.0,
    this.spacing = const EdgeInsets.symmetric(horizontal: 4.0),
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];
    
    if (showLevel) {
      chips.add(_buildLevelChip());
    }
    
    if (showHp) {
      chips.add(_buildHpChip());
    }
    
    if (showAc) {
      chips.add(_buildAcChip());
    }
    
    if (showInitiative) {
      chips.add(_buildInitiativeChip());
    }

    return Wrap(
      spacing: 4.0,
      runSpacing: 4.0,
      children: chips,
    );
  }

  Widget _buildLevelChip() {
    final levelColor = CharacterListHelpers.getLevelBadgeColor(character.level);
    
    return Container(
      height: chipHeight,
      decoration: BoxDecoration(
        color: levelColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: levelColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              size: 14,
              color: levelColor,
            ),
            const SizedBox(width: 4),
            Text(
              'LVL ${character.level}',
              style: TextStyle(
                color: levelColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHpChip() {
    final hpColor = CharacterListHelpers.getHpStatusColor(character.maxHp, character.maxHp);
    final hpText = CharacterListHelpers.getHpStatusText(character.maxHp, character.maxHp);
    
    return Container(
      height: chipHeight,
      decoration: BoxDecoration(
        color: hpColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: hpColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite,
              size: 14,
              color: hpColor,
            ),
            const SizedBox(width: 4),
            Text(
              hpText,
              style: TextStyle(
                color: hpColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcChip() {
    const acColor = Colors.blue;
    
    return Container(
      height: chipHeight,
      decoration: BoxDecoration(
        color: acColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: acColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.shield,
              size: 14,
              color: acColor,
            ),
            const SizedBox(width: 4),
            Text(
              'AC ${character.armorClass}',
              style: TextStyle(
                color: acColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInitiativeChip() {
    const initiativeColor = Colors.orange;
    final dexMod = (character.dexterity - 10) ~/ 2;
    final totalInit = dexMod + character.initiativeBonus;
    final initiativeBonus = totalInit >= 0 ? '+$totalInit' : '$totalInit';
    
    return Container(
      height: chipHeight,
      decoration: BoxDecoration(
        color: initiativeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: initiativeColor.withOpacity(0.3), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bolt,
              size: 14,
              color: initiativeColor,
            ),
            const SizedBox(width: 4),
            Text(
              'INIT $initiativeBonus',
              style: TextStyle(
                color: initiativeColor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kompakte Version der Stats-Chips für engere Platzverhältnisse
class CompactHeroStatsChipsWidget extends StatelessWidget {
  final PlayerCharacter character;
  final double iconSize;
  final double fontSize;

  const CompactHeroStatsChipsWidget({
    super.key,
    required this.character,
    this.iconSize = 12.0,
    this.fontSize = 9.0,
  });

  @override
  Widget build(BuildContext context) {
    final levelColor = CharacterListHelpers.getLevelBadgeColor(character.level);
    final hpColor = CharacterListHelpers.getHpStatusColor(character.maxHp, character.maxHp);
    final dexMod = (character.dexterity - 10) ~/ 2;
    final totalInit = dexMod + character.initiativeBonus;
    final initiativeBonus = totalInit >= 0 ? '+$totalInit' : '$totalInit';
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Level
        _buildCompactChip(
          Icons.star,
          '${character.level}',
          levelColor,
        ),
        const SizedBox(width: 6),
        
        // HP
        _buildCompactChip(
          Icons.favorite,
          '${character.maxHp}',
          hpColor,
        ),
        const SizedBox(width: 6),
        
        // AC
        _buildCompactChip(
          Icons.shield,
          '${character.armorClass}',
          Colors.blue,
        ),
        const SizedBox(width: 6),
        
        // Initiative
        _buildCompactChip(
          Icons.bolt,
          initiativeBonus,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildCompactChip(IconData icon, String text, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: iconSize,
          color: color,
        ),
        const SizedBox(width: 2),
        Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// Vertikale Stats-Anzeige für detaillierte Ansichten
class VerticalHeroStatsWidget extends StatelessWidget {
  final PlayerCharacter character;
  final double spacing;
  final TextStyle? labelStyle;
  final TextStyle? valueStyle;

  const VerticalHeroStatsWidget({
    super.key,
    required this.character,
    this.spacing = 8.0,
    this.labelStyle,
    this.valueStyle,
  });

  @override
  Widget build(BuildContext context) {
    final defaultLabelStyle = TextStyle(
      fontSize: 10,
      color: Colors.grey[600],
      fontWeight: FontWeight.w500,
    );
    
    final defaultValueStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStatRow('Level', '${character.level}', Colors.purple),
        _buildStatRow('HP', '${character.maxHp}', Colors.red),
        _buildStatRow('AC', '${character.armorClass}', Colors.blue),
        _buildStatRow('Initiative', _getInitiativeDisplay(), Colors.orange),
        if (character.gold > 0)
          _buildStatRow('Gold', CharacterListHelpers.formatInventoryValue(character.gold), Colors.amber),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.only(bottom: spacing),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: labelStyle?.copyWith(color: Colors.grey[600]) ??
                TextStyle(
                  fontSize: 10,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
          Text(
            value,
            style: valueStyle?.copyWith(color: color) ??
                TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  String _getInitiativeDisplay() {
    final dexMod = (character.dexterity - 10) ~/ 2;
    final totalInit = dexMod + character.initiativeBonus;
    return totalInit >= 0 ? '+$totalInit' : '$totalInit';
  }
}
