import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CharacterEditorHelpers {
  static void showAttributeQuickEditDialog(
    BuildContext context,
    String name,
    TextEditingController controller,
    Color color,
    VoidCallback onRebuild,
  ) {
    final currentValue = int.tryParse(controller.text) ?? 10;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$name bearbeiten'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Aktueller Wert: $currentValue',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildEditButton(ctx, '-5', () => controller.text = (currentValue - 5).clamp(1, 30).toString()),
                _buildEditButton(ctx, '-1', () => controller.text = (currentValue - 1).clamp(1, 30).toString()),
                _buildEditButton(ctx, '+1', () => controller.text = (currentValue + 1).clamp(1, 30).toString()),
                _buildEditButton(ctx, '+5', () => controller.text = (currentValue + 5).clamp(1, 30).toString()),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: color),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: color, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Abbrechen"),
          ),
          ElevatedButton(
            onPressed: () {
              onRebuild();
              Navigator.of(ctx).pop();
            },
            child: const Text("Übernehmen"),
          ),
        ],
      ),
    );
  }

  static Widget _buildEditButton(BuildContext context, String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  static void showTooltipDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Verstanden"),
          ),
        ],
      ),
    );
  }

  static void showAttributesHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Attribute & Fertigkeiten Hilfe'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Die 6 Hauptattribute:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Stärke (STR): Muskelkraft, Nahkampf\n'
                '• Geschicklichkeit (DEX): Reflexe, Geschick\n'
                '• Konstitution (CON): Ausdauer, HP\n'
                '• Intelligenz (INT): Wissen, Logik\n'
                '• Weisheit (WIS): Wahrnehmung, Intuition\n'
                '• Charisma (CHA): Persönlichkeit',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Modifier:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Der Modifier wird berechnet als: (Attribut - 10) / 2\n'
                'Beispiel: 16 Stärke = (16-10)/2 = +3 Modifier',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Fertigkeiten:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Markierte Fertigkeiten erhalten den Proficiency-Bonus\n'
                'dazu auf den Attribut-Modifier.',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Verstanden"),
          ),
        ],
      ),
    );
  }

  static void showAbilitiesHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fähigkeiten & Aktionen Hilfe'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Angriffe & Aktionen:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Beschreiben Sie hier alle Angriffe und Aktionen, die die Kreatur ausführen kann.\n\n'
                'Format: "Angriffsname: +Bonus (Schaden) Beschreibung"\n'
                'Beispiel: "Schwerthieb: +4 (1W8+2) Hiegschaden"',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Spezielle Fähigkeiten:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Einzigartige Fähigkeiten wie Regeneration, Magieresistenz oder andere besondere Eigenschaften.\n\n'
                'Beispiel: "Regeneration (3/Runte). Die Kreatur heilt jede Runde 3 Schadenspunkte."',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Legendäre Aktionen:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Spezielle Aktionen für mächtige Monster (CR 10+), die außerhalb ihres normalen Zuges ausgeführt werden können.\n\n'
                'Beispiel: "Flügelschlag: Der Drache schlägt mit seinen Flügeln und verursacht 2W6 Schaden."',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Verstanden"),
          ),
        ],
      ),
    );
  }

  static void adjustAttribute(TextEditingController controller, int adjustment, VoidCallback onRebuild) {
    final currentValue = int.tryParse(controller.text) ?? 10;
    final newValue = (currentValue + adjustment).clamp(1, 30); // D&D 5e limits
    controller.text = newValue.toString();
    onRebuild();
  }

  static Widget buildStatChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
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
}
