import 'package:flutter/material.dart';
import 'ability_card_widget.dart';
import 'character_editor_helpers.dart';

class AbilitiesTabWidget extends StatelessWidget {
  final TextEditingController attacksController;
  final TextEditingController specialAbilitiesController;
  final TextEditingController legendaryActionsController;

  const AbilitiesTabWidget({
    super.key,
    required this.attacksController,
    required this.specialAbilitiesController,
    required this.legendaryActionsController,
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
              const Icon(Icons.flash_on, size: 28, color: Colors.orange),
              const SizedBox(width: 12),
              const Text(
                'Fähigkeiten & Aktionen',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.help_outline, color: Colors.grey),
                onPressed: () => CharacterEditorHelpers.showAbilitiesHelpDialog(context),
                tooltip: 'Hilfe zu Fähigkeiten',
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Angriffe & Aktionen
          AbilityCardWidget(
            title: 'Angriffe & Aktionen',
            icon: Icons.gavel,
            color: Colors.red,
            controller: attacksController,
            hintText: 'Schwerthieb: +4 (1W8+2) Hiegschaden\nBogen: +3 (1W6+2) Stichschaden',
            description: 'Alle Angriffe und Aktionen, die die Kreatur im Kampf ausführen kann.',
            onTooltip: () => CharacterEditorHelpers.showTooltipDialog(
              context,
              'Angriffe & Aktionen',
              'Beschreiben Sie hier alle Angriffe und Aktionen, die die Kreatur ausführen kann.\n\n'
              'Format: "Angriffsname: +Bonus (Schaden) Beschreibung"\n'
              'Beispiel: "Schwerthieb: +4 (1W8+2) Hiegschaden"',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Spezielle Fähigkeiten
          AbilityCardWidget(
            title: 'Spezielle Fähigkeiten',
            icon: Icons.auto_awesome,
            color: Colors.blue,
            controller: specialAbilitiesController,
            hintText: 'Regeneration (3/Runte). Wenn der Drache einen Feuer-Schaden erleidet, bekommt er keine Regeneration in diesem Zug.',
            description: 'Einzigartige Fähigkeiten, die die Kreatur von anderen unterscheidet.',
            onTooltip: () => CharacterEditorHelpers.showTooltipDialog(
              context,
              'Spezielle Fähigkeiten',
              'Einzigartige Fähigkeiten wie Regeneration, Magieresistenz oder andere besondere Eigenschaften.\n\n'
              'Beispiel: "Regeneration (3/Runte). Die Kreatur heilt jede Runde 3 Schadenspunkte."',
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Legendäre Aktionen
          AbilityCardWidget(
            title: 'Legendäre Aktionen',
            icon: Icons.star,
            color: Colors.purple,
            controller: legendaryActionsController,
            hintText: 'Der Drache kann 3 legendäre Aktionen ausführen und wählt aus den folgenden Optionen. Nur eine legendäre Aktion kann gleichzeitig verwendet werden und nur am Ende des Zuges einer anderen Kreatur.',
            description: 'Spezielle Aktionen, die starke Monster außerhalb ihres normalen Zuges ausführen können.',
            onTooltip: () => CharacterEditorHelpers.showTooltipDialog(
              context,
              'Legendäre Aktionen',
              'Spezielle Aktionen für mächtige Monster (CR 10+), die außerhalb ihres normalen Zuges ausgeführt werden können.\n\n'
              'Beispiel: "Flügelschlag: Der Drache schlägt mit seinen Flügeln und verursacht 2W6 Schaden."',
            ),
          ),
        ],
      ),
    );
  }
}
