import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../game_data/dnd_logic.dart';
import '../../../theme/app_theme.dart';

class AbilityScoreWidget extends StatelessWidget {
  const AbilityScoreWidget({
    required this.name,
    required this.value,
    required this.icon,
    required this.color,
    required this.onChanged,
    super.key,
    this.minScore = 1,
    this.maxScore = 20,
  });

  final String name;
  final int value;
  final IconData icon;
  final Color color;
  final void Function(int) onChanged;
  final int minScore;
  final int maxScore;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final modifierString = getModifierString(value);
    final screenWidth = MediaQuery.of(context).size.width;
    final scale = screenWidth / 600;

    return Container(
      padding: EdgeInsets.all(6 * scale),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(8 * scale),
        border: Border.all(color: C.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20 * scale),
          SizedBox(height: 3 * scale),
          Text(
            name,
            style: TextStyle(fontSize: 10 * scale, color: C.textSoft, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6 * scale),
          _buildScoreInput(scale, C),
          SizedBox(height: 3 * scale),
          _buildModifierDisplay(modifierString, scale, C),
        ],
      ),
    );
  }

  Widget _buildScoreInput(double scale, AppColorsExtension C) => Container(
        width: 40 * scale,
        height: 32 * scale,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: C.bgHover,
          borderRadius: BorderRadius.circular(4 * scale),
          border: Border.all(color: C.accent, width: 1.5),
        ),
        child: TextFormField(
          initialValue: value.toString(),
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.zero),
          style: TextStyle(fontSize: 14 * scale, fontWeight: FontWeight.bold, color: C.accent),
          onChanged: (v) {
            final parsed = int.tryParse(v);
            if (parsed != null && parsed >= minScore && parsed <= maxScore) {
              onChanged(parsed);
            }
          },
        ),
      );

  Widget _buildModifierDisplay(String modifierString, double scale, AppColorsExtension C) {
    final modifier = getModifier(value);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Mod: ', style: TextStyle(fontSize: 10 * scale, color: C.textSoft)),
        Text(
          modifierString,
          style: TextStyle(
            fontSize: 12 * scale,
            fontWeight: FontWeight.bold,
            color: modifier >= 0 ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }
}

// ── GRID ──────────────────────────────────────────────────────────────────────

class AbilityScoreGrid extends StatelessWidget {
  const AbilityScoreGrid({
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
    super.key,
  });

  final int strength;
  final int dexterity;
  final int constitution;
  final int intelligence;
  final int wisdom;
  final int charisma;
  final void Function(int) onStrengthChanged;
  final void Function(int) onDexterityChanged;
  final void Function(int) onConstitutionChanged;
  final void Function(int) onIntelligenceChanged;
  final void Function(int) onWisdomChanged;
  final void Function(int) onCharismaChanged;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final screenScale = MediaQuery.of(context).size.width / 600;
      const crossAxisSpacing = 5.0;
      final cellWidth = (constraints.maxWidth - crossAxisSpacing * 2) / 3;
      // Content height ≈ 102 * screenScale; derive aspect ratio from actual cell width
      final contentHeight = 102.0 * screenScale;
      final aspectRatio = (cellWidth / contentHeight).clamp(0.7, 1.8);

      return GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: crossAxisSpacing * screenScale,
        crossAxisSpacing: crossAxisSpacing * screenScale,
        childAspectRatio: aspectRatio,
        children: [
        AbilityScoreWidget(name: 'Stärke', value: strength, icon: Icons.fitness_center, color: Colors.red, onChanged: onStrengthChanged),
        AbilityScoreWidget(name: 'Geschicklichkeit', value: dexterity, icon: Icons.flash_on, color: Colors.green, onChanged: onDexterityChanged),
        AbilityScoreWidget(name: 'Konstitution', value: constitution, icon: Icons.favorite, color: Colors.orange, onChanged: onConstitutionChanged),
        AbilityScoreWidget(name: 'Intelligenz', value: intelligence, icon: Icons.school, color: Colors.blue, onChanged: onIntelligenceChanged),
        AbilityScoreWidget(name: 'Weisheit', value: wisdom, icon: Icons.psychology, color: Colors.purple, onChanged: onWisdomChanged),
        AbilityScoreWidget(name: 'Charisma', value: charisma, icon: Icons.people, color: Colors.pink, onChanged: onCharismaChanged),
      ],
      );
    });
  }
}
