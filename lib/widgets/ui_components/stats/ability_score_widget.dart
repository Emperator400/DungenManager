import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../game_data/dnd_logic.dart';
import '../../../theme/dnd_theme.dart';

/// Widget für Attributspunkte (Ability Scores)
class AbilityScoreWidget extends StatelessWidget {
  final String name;
  final int value;
  final IconData icon;
  final Color color;
  final Function(int) onChanged;
  final int minScore;
  final int maxScore;

  const AbilityScoreWidget({
    super.key,
    required this.name,
    required this.value,
    required this.icon,
    required this.color,
    required this.onChanged,
    this.minScore = 1,
    this.maxScore = 20,
  });

  @override
  Widget build(BuildContext context) {
    final modifierString = getModifierString(value);
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 600; // Basis: 600px Breite (kleinerer Faktor)
    
    return Container(
      padding: EdgeInsets.all(6 * scaleFactor),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: BorderRadius.circular(8 * scaleFactor),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20 * scaleFactor),
          SizedBox(height: 3 * scaleFactor),
          Text(
            name,
            style: TextStyle(
              fontSize: 10 * scaleFactor,
              color: _getTextColor(context),
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6 * scaleFactor),
          _buildScoreInput(scaleFactor),
          SizedBox(height: 3 * scaleFactor),
          _buildModifierDisplay(modifierString, scaleFactor),
        ],
      ),
    );
  }

  Widget _buildScoreInput(double scaleFactor) {
    return Container(
      width: 40 * scaleFactor,
      height: 32 * scaleFactor,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _getInputBackgroundColor(),
        borderRadius: BorderRadius.circular(4 * scaleFactor),
        border: Border.all(
          color: _getBorderColor(),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        initialValue: value.toString(),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
        style: TextStyle(
          fontSize: 14 * scaleFactor,
          fontWeight: FontWeight.bold,
          color: _getInputTextColor(),
        ),
        onChanged: (newValue) {
          final newValueInt = int.tryParse(newValue);
          if (newValueInt != null && newValueInt >= minScore && newValueInt <= maxScore) {
            onChanged(newValueInt);
          }
        },
      ),
    );
  }

  Widget _buildModifierDisplay(String modifierString, double scaleFactor) {
    final modifier = getModifier(value);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Mod: ',
          style: TextStyle(
            fontSize: 10 * scaleFactor,
            color: _getSecondaryTextColor(),
          ),
        ),
        Text(
          modifierString,
          style: TextStyle(
            fontSize: 12 * scaleFactor,
            fontWeight: FontWeight.bold,
            color: modifier >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    return DnDTheme.slateGrey;
  }

  Color _getTextColor(BuildContext context) {
    return Colors.white;
  }

  Color _getInputBackgroundColor() {
    return DnDTheme.stoneGrey;
  }

  Color _getBorderColor() {
    return DnDTheme.ancientGold;
  }

  Color _getInputTextColor() {
    return DnDTheme.ancientGold;
  }

  Color _getSecondaryTextColor() {
    return Colors.white70;
  }
}

/// Grid für alle sechs Attributspunkte
class AbilityScoreGrid extends StatelessWidget {
  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final Function(int) onStrengthChanged;
  final Function(int) onDexterityChanged;
  final Function(int) onConstitutionChanged;
  final Function(int) onIntelligenceChanged;
  final Function(int) onWisdomChanged;
  final Function(int) onCharismaChanged;

  const AbilityScoreGrid({
    super.key,
    required this.strength,
    required this.dexterity,
    required this.constitution,
    required this.intelligence,
    required this.wisdom,
    required this.charisma,
    required this.onStrengthChanged,
    required this.onDexterityChanged,
    required this.onConstitutionChanged,
    required this.onIntelligenceChanged,
    required this.onWisdomChanged,
    required this.onCharismaChanged,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 600; // Konsistent mit Widget (kleinerer Faktor)
    
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 5 * scaleFactor,
      crossAxisSpacing: 5 * scaleFactor,
      childAspectRatio: 1.6,
      
      children: [
        AbilityScoreWidget(
          name: 'Stärke',
          value: strength,
          icon: Icons.fitness_center,
          color: Colors.red,
          onChanged: onStrengthChanged,
        ),
        AbilityScoreWidget(
          name: 'Geschicklichkeit',
          value: dexterity,
          icon: Icons.flash_on,
          color: Colors.green,
          onChanged: onDexterityChanged,
        ),
        AbilityScoreWidget(
          name: 'Konstitution',
          value: constitution,
          icon: Icons.favorite,
          color: Colors.orange,
          onChanged: onConstitutionChanged,
        ),
        AbilityScoreWidget(
          name: 'Intelligenz',
          value: intelligence,
          icon: Icons.school,
          color: Colors.blue,
          onChanged: onIntelligenceChanged,
        ),
        AbilityScoreWidget(
          name: 'Weisheit',
          value: wisdom,
          icon: Icons.psychology,
          color: Colors.purple,
          onChanged: onWisdomChanged,
        ),
        AbilityScoreWidget(
          name: 'Charisma',
          value: charisma,
          icon: Icons.people,
          color: Colors.pink,
          onChanged: onCharismaChanged,
        ),
      ],
    );
  }
}

/// Widget für Kampfwerte (Combat Stats)
class CombatStatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const CombatStatChip({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Entferne Expanded aus CombatStatChip - verursacht verschachtelte Expanded
    return Container(
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
    );
  }
}

/// Zeile für Kampfwerte
class CombatStatsRow extends StatelessWidget {
  final int maxHp;
  final int armorClass;
  final int initiativeBonus;
  final int speed;

  const CombatStatsRow({
    super.key,
    required this.maxHp,
    required this.armorClass,
    required this.initiativeBonus,
    required this.speed,
  });

  @override
  Widget build(BuildContext context) {
    // Packe jeden Chip in Expanded, da CombatStatChip selbst kein Expanded mehr ist
    return Row(
      children: [
        Expanded(
          child: CombatStatChip(
            icon: Icons.favorite,
            label: 'HP',
            value: '$maxHp',
            color: Colors.red,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CombatStatChip(
            icon: Icons.shield,
            label: 'AC',
            value: '$armorClass',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CombatStatChip(
            icon: Icons.flash_on,
            label: 'Init',
            value: initiativeBonus >= 0 ? '+$initiativeBonus' : '$initiativeBonus',
            color: Colors.orange,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: CombatStatChip(
            icon: Icons.speed,
            label: 'Bew.',
            value: '$speed ft',
            color: Colors.green,
          ),
        ),
      ],
    );
  }
}

/// Widget für Währungsanzeige
class CurrencyWidget extends StatelessWidget {
  final double gold;
  final double silver;
  final double copper;

  const CurrencyWidget({
    super.key,
    required this.gold,
    required this.silver,
    required this.copper,
  });

  @override
  Widget build(BuildContext context) {
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
          if (gold > 0) ...[
            Icon(Icons.monetization_on, size: 14, color: Colors.amber[700]),
            const SizedBox(width: 4),
            Text(
              '${gold.toStringAsFixed(0)} Gold',
              style: TextStyle(
                fontSize: 11,
                color: Colors.amber[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            if (silver > 0 || copper > 0) const SizedBox(width: 12),
          ],
          if (silver > 0) ...[
            Icon(Icons.circle, size: 8, color: Colors.grey[500]),
            const SizedBox(width: 4),
            Text(
              '${silver.toStringAsFixed(0)} Silber',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
            if (copper > 0) const SizedBox(width: 12),
          ],
          if (copper > 0) ...[
            Icon(Icons.circle, size: 8, color: Colors.brown[400]),
            const SizedBox(width: 4),
            Text(
              '${copper.toStringAsFixed(0)} Kupfer',
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
}
