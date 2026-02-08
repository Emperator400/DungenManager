import 'package:flutter/material.dart';
import 'ability_score_widget.dart';
import '../cards/section_card_widget.dart';

/// Gemeinsames Widget für Attribut-Sektionen
/// Wird sowohl von Helden- als auch Kreaturen-Erstellung genutzt
class AttributesSectionWidget extends StatelessWidget {
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
  final String title;
  final IconData icon;
  final bool useSectionCard;

  const AttributesSectionWidget({
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
    this.title = 'Attribute',
    this.icon = Icons.fitness_center,
    this.useSectionCard = true,
  });

  @override
  Widget build(BuildContext context) {
    final abilityGrid = AbilityScoreGrid(
      strength: strength,
      dexterity: dexterity,
      constitution: constitution,
      intelligence: intelligence,
      wisdom: wisdom,
      charisma: charisma,
      onStrengthChanged: onStrengthChanged,
      onDexterityChanged: onDexterityChanged,
      onConstitutionChanged: onConstitutionChanged,
      onIntelligenceChanged: onIntelligenceChanged,
      onWisdomChanged: onWisdomChanged,
      onCharismaChanged: onCharismaChanged,
    );

    if (useSectionCard) {
      return SectionCardWidget(
        title: title,
        icon: icon,
        padding: EdgeInsets.zero,
        child: Container(
          padding: const EdgeInsets.all(16),
          child: abilityGrid,
        ),
      );
    }

    return abilityGrid;
  }
}
