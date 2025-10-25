import 'package:flutter/material.dart';
import '../../game_data/game_data.dart';
import '../../game_data/dnd_models.dart';
import '../../game_data/dnd_logic.dart';
import 'attribute_card_widget.dart';
import 'skill_row_widget.dart';
import 'character_editor_helpers.dart';

class AttributesTabWidget extends StatelessWidget {
  final TextEditingController strController;
  final TextEditingController dexController;
  final TextEditingController conController;
  final TextEditingController intController;
  final TextEditingController wisController;
  final TextEditingController chaController;
  final TextEditingController levelController;
  final Set<String> proficientSkills;
  final Function(String) onSkillToggle;
  final VoidCallback onRebuild;
  final bool showSkills;

  const AttributesTabWidget({
    super.key,
    required this.strController,
    required this.dexController,
    required this.conController,
    required this.intController,
    required this.wisController,
    required this.chaController,
    required this.levelController,
    required this.proficientSkills,
    required this.onSkillToggle,
    required this.onRebuild,
    this.showSkills = true,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header mit Titel und Info
          Row(
            children: [
              const Icon(Icons.fitness_center, size: 28, color: Colors.blue),
              const SizedBox(width: 12),
              Text(
                showSkills ? 'Attribute & Fähigkeiten' : 'Attribute',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.grey),
                onPressed: () => CharacterEditorHelpers.showAttributesHelpDialog(context),
                tooltip: 'Hilfe zu Attributen',
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Die 6 Hauptattribute in modernem 3x2 Raster
          const Text(
            'Die 6 Hauptattribute',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          
          // Alle Attributkarten auf einen Blick - 3x2 Raster mit Pastellfarben
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            childAspectRatio: 2.3,
            crossAxisSpacing: 3,
            mainAxisSpacing: 3,
            children: [
              AttributeCardWidget(
                name: "Stärke",
                controller: strController,
                color: Colors.red,
                description: "Muskelkraft, Tragkraft, Nahkampf",
                onQuickEdit: (name, controller, color) => CharacterEditorHelpers.showAttributeQuickEditDialog(
                  context, name, controller, color, onRebuild,
                ),
                onAdjustAttribute: (controller, adjustment) => CharacterEditorHelpers.adjustAttribute(controller, adjustment, onRebuild),
              ),
              AttributeCardWidget(
                name: "Geschicklichkeit",
                controller: dexController,
                color: Colors.green,
                description: "Reflexe, Geschick, Rüstungsklasse",
                onQuickEdit: (name, controller, color) => CharacterEditorHelpers.showAttributeQuickEditDialog(
                  context, name, controller, color, onRebuild,
                ),
                onAdjustAttribute: (controller, adjustment) => CharacterEditorHelpers.adjustAttribute(controller, adjustment, onRebuild),
              ),
              AttributeCardWidget(
                name: "Konstitution",
                controller: conController,
                color: Colors.orange,
                description: "Ausdauer, Trefferpunkte, Widerstand",
                onQuickEdit: (name, controller, color) => CharacterEditorHelpers.showAttributeQuickEditDialog(
                  context, name, controller, color, onRebuild,
                ),
                onAdjustAttribute: (controller, adjustment) => CharacterEditorHelpers.adjustAttribute(controller, adjustment, onRebuild),
              ),
              AttributeCardWidget(
                name: "Intelligenz",
                controller: intController,
                color: Colors.blue,
                description: "Wissen, Logik, Magie",
                onQuickEdit: (name, controller, color) => CharacterEditorHelpers.showAttributeQuickEditDialog(
                  context, name, controller, color, onRebuild,
                ),
                onAdjustAttribute: (controller, adjustment) => CharacterEditorHelpers.adjustAttribute(controller, adjustment, onRebuild),
              ),
              AttributeCardWidget(
                name: "Weisheit",
                controller: wisController,
                color: Colors.purple,
                description: "Wahrnehmung, Intuition, Sinne",
                onQuickEdit: (name, controller, color) => CharacterEditorHelpers.showAttributeQuickEditDialog(
                  context, name, controller, color, onRebuild,
                ),
                onAdjustAttribute: (controller, adjustment) => CharacterEditorHelpers.adjustAttribute(controller, adjustment, onRebuild),
              ),
              AttributeCardWidget(
                name: "Charisma",
                controller: chaController,
                color: Colors.pink,
                description: "Persönlichkeit, Überzeugung, Führung",
                onQuickEdit: (name, controller, color) => CharacterEditorHelpers.showAttributeQuickEditDialog(
                  context, name, controller, color, onRebuild,
                ),
                onAdjustAttribute: (controller, adjustment) => CharacterEditorHelpers.adjustAttribute(controller, adjustment, onRebuild),
              ),
            ],
          ),
          
          if (showSkills) ...[
            const SizedBox(height: 80),
            
            // Fähigkeiten-Sektion
            const Text(
              'Fertigkeiten',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.blue, size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Fertigkeiten auswählen',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        const Spacer(),
                        Text(
                          'Proficiency: +${getProficiencyBonus(int.tryParse(levelController.text) ?? 1)}',
                          style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(),
                    ...allDndSkills.map((skill) => _buildSkillRow(skill)).toList(),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkillRow(DndSkill skill) {
    final Map<Ability, TextEditingController> abilityControllers = {
      Ability.strength: strController, 
      Ability.dexterity: dexController,
      Ability.constitution: conController, 
      Ability.intelligence: intController,
      Ability.wisdom: wisController, 
      Ability.charisma: chaController,
    };
    
    final score = int.tryParse(abilityControllers[skill.ability]!.text) ?? 10;
    final modifier = getModifier(score);
    final proficiencyBonus = getProficiencyBonus(int.tryParse(levelController.text) ?? 1);
    final isProficient = proficientSkills.contains(skill.name);
    final totalBonus = modifier + (isProficient ? proficiencyBonus : 0);

    return SkillRowWidget(
      skill: skill,
      isProficient: isProficient,
      totalBonus: totalBonus,
      onTap: () => onSkillToggle(skill.name),
    );
  }
}
