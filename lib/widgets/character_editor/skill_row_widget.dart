import 'package:flutter/material.dart';
import '../../game_data/dnd_models.dart';
import '../../game_data/dnd_logic.dart';

class SkillRowWidget extends StatelessWidget {
  final DndSkill skill;
  final bool isProficient;
  final int totalBonus;
  final VoidCallback onTap;

  const SkillRowWidget({
    super.key,
    required this.skill,
    required this.isProficient,
    required this.totalBonus,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bonusString = totalBonus >= 0 ? "+$totalBonus" : totalBonus.toString();
    
    final abilityColors = {
      Ability.strength: Colors.red,
      Ability.dexterity: Colors.green,
      Ability.constitution: Colors.orange,
      Ability.intelligence: Colors.blue,
      Ability.wisdom: Colors.purple,
      Ability.charisma: Colors.pink,
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              // Checkbox mit Fähigkeitsfarbe
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isProficient ? abilityColors[skill.ability]! : Colors.grey[300]!,
                    width: 2,
                  ),
                  color: isProficient ? abilityColors[skill.ability]!.withOpacity(0.2) : Colors.transparent,
                ),
                child: isProficient
                    ? Icon(
                        Icons.check,
                        size: 16,
                        color: abilityColors[skill.ability],
                      )
                    : null,
              ),
              
              const SizedBox(width: 12),
              
              // Fähigkeitsname und Attribut
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      skill.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '(${skill.ability.name.toUpperCase()})',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bonus-Anzeige
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: totalBonus >= 0 ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: totalBonus >= 0 ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                  ),
                ),
                child: Text(
                  bonusString,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: totalBonus >= 0 ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}