import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../game_data/game_data.dart';
import '../../game_data/dnd_models.dart';
import 'character_editor_controller.dart';

class BasicInfoTabBuilder {
  final CharacterEditorController controller;
  final GlobalKey<FormState> formKey;

  BasicInfoTabBuilder({
    required this.controller,
    required this.formKey,
  });

  Widget buildForPlayerCharacter(VoidCallback onStateChanged) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: 'Name des Charakters *'),
              validator: controller.validateRequired,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.playerNameController,
              decoration: const InputDecoration(labelText: 'Name des Spielers *'),
              validator: controller.validateRequired,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<DndClass>(
              value: controller.selectedClass,
              decoration: const InputDecoration(labelText: 'Klasse *'),
              items: allDndClasses.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (val) {
                controller.selectedClass = val;
                onStateChanged();
              },
              validator: (v) => v == null ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            
            DropdownButtonFormField<DndRace>(
              value: controller.selectedRace,
              decoration: const InputDecoration(labelText: 'Rasse *'),
              items: allDndRaces.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
              onChanged: (val) {
                controller.selectedRace = val;
                onStateChanged();
              },
              validator: (v) => v == null ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            
            _buildNumberField(controller.levelController, 'Stufe', onStateChanged),
            const SizedBox(height: 24),
            
            // Beschreibung für Player Characters
            const Text('Beschreibung', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              controller: controller.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Charakterbeschreibung',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            
            const Text('Kampfwerte', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            Row(
              children: [
                Expanded(child: _buildNumberField(controller.hpController, 'Maximale HP', onStateChanged)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(controller.acController, 'Rüstungsklasse', onStateChanged)),
              ],
            ),
            const SizedBox(height: 24),
            
            // D&D-Klassifikation für Player Characters
            const Text('D&D-Klassifikation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            _buildClassificationSection(onStateChanged),
          ],
        ),
      ),
    );
  }

  Widget buildForCreature(VoidCallback onStateChanged) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: controller.nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: controller.validateRequired,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: controller.descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            const Text('Kampf-Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(child: _buildNumberField(controller.hpController, 'Maximale HP *', onStateChanged)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(controller.acController, 'Rüstungsklasse (AC) *', onStateChanged)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(controller.initBonusController, 'Initiative-Bonus', onStateChanged)),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: TextFormField(
                  controller: controller.speedController,
                  decoration: const InputDecoration(labelText: 'Bewegungsrate'),
                )),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(
                  controller: controller.crController,
                  decoration: const InputDecoration(labelText: 'Challenge Rating'),
                  keyboardType: TextInputType.number,
                )),
              ],
            ),
            const SizedBox(height: 16),
            
            const Text('D&D-Klassifikation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            _buildClassificationSection(onStateChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildClassificationSection(VoidCallback onStateChanged) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String>(
                value: controller.selectedSize.isNotEmpty ? controller.selectedSize : null,
                decoration: const InputDecoration(labelText: 'Größe'),
                items: CharacterEditorConstants.sizeOptions,
                onChanged: (value) {
                  controller.selectedSize = value ?? 'Medium';
                  onStateChanged();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: controller.selectedType.isNotEmpty ? controller.selectedType : null,
                decoration: const InputDecoration(labelText: 'Typ'),
                items: CharacterEditorConstants.typeOptions,
                onChanged: (value) {
                  controller.selectedType = value ?? 'Humanoid';
                  onStateChanged();
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: TextEditingController(text: controller.selectedSubtype ?? ''),
                decoration: const InputDecoration(labelText: 'Subtyp (optional)'),
                onChanged: (value) {
                  controller.selectedSubtype = value.isEmpty ? null : value;
                  onStateChanged();
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: controller.selectedAlignment.isNotEmpty ? controller.selectedAlignment : null,
                decoration: const InputDecoration(labelText: 'Gesinnung'),
                items: CharacterEditorConstants.alignmentOptions,
                onChanged: (value) {
                  controller.selectedAlignment = value ?? 'True Neutral';
                  onStateChanged();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label, VoidCallback onStateChanged) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
      onChanged: (_) => onStateChanged(),
    );
  }
}

class CharacterEditorConstants {
  static const List<DropdownMenuItem<String>> sizeOptions = [
    DropdownMenuItem(value: 'Tiny', child: Text('Winzig')),
    DropdownMenuItem(value: 'Small', child: Text('Klein')),
    DropdownMenuItem(value: 'Medium', child: Text('Mittel')),
    DropdownMenuItem(value: 'Large', child: Text('Groß')),
    DropdownMenuItem(value: 'Huge', child: Text('Riesig')),
    DropdownMenuItem(value: 'Gargantuan', child: Text('Gigantisch')),
  ];

  static const List<DropdownMenuItem<String>> typeOptionsForPC = [
    DropdownMenuItem(value: 'Humanoid', child: Text('Humanoid')),
    DropdownMenuItem(value: 'Beast', child: Text('Tier')),
    DropdownMenuItem(value: 'Dragon', child: Text('Drache')),
    DropdownMenuItem(value: 'Elemental', child: Text('Elementar')),
    DropdownMenuItem(value: 'Fey', child: Text('Feenwesen')),
    DropdownMenuItem(value: 'Fiend', child: Text('Teufel/Dämon')),
    DropdownMenuItem(value: 'Celestial', child: Text('Himmelswesen')),
    DropdownMenuItem(value: 'Construct', child: Text('Konstrukt')),
    DropdownMenuItem(value: 'Undead', child: Text('Untot')),
  ];

  static const List<DropdownMenuItem<String>> typeOptions = [
    DropdownMenuItem(value: 'Aberration', child: Text('Aberration')),
    DropdownMenuItem(value: 'Beast', child: Text('Tier')),
    DropdownMenuItem(value: 'Celestial', child: Text('Himmelswesen')),
    DropdownMenuItem(value: 'Construct', child: Text('Konstrukt')),
    DropdownMenuItem(value: 'Dragon', child: Text('Drache')),
    DropdownMenuItem(value: 'Elemental', child: Text('Elementar')),
    DropdownMenuItem(value: 'Fey', child: Text('Feenwesen')),
    DropdownMenuItem(value: 'Fiend', child: Text('Teufel/Dämon')),
    DropdownMenuItem(value: 'Giant', child: Text('Riese')),
    DropdownMenuItem(value: 'Humanoid', child: Text('Humanoid')),
    DropdownMenuItem(value: 'humanoid (goblinoid)', child: Text('Humanoid (Goblinoid)')),
    DropdownMenuItem(value: 'humanoid (orc)', child: Text('Humanoid (Ork)')),
    DropdownMenuItem(value: 'Monstrosity', child: Text('Monstrosität')),
    DropdownMenuItem(value: 'Ooze', child: Text('Schleim')),
    DropdownMenuItem(value: 'Plant', child: Text('Pflanze')),
    DropdownMenuItem(value: 'undead', child: Text('Untot')),
  ];

  static const List<DropdownMenuItem<String>> alignmentOptions = [
    DropdownMenuItem(value: 'Lawful Good', child: Text('Gesetzmäßig Gut')),
    DropdownMenuItem(value: 'Neutral Good', child: Text('Neutral Gut')),
    DropdownMenuItem(value: 'Chaotic Good', child: Text('Chaotisch Gut')),
    DropdownMenuItem(value: 'Lawful Neutral', child: Text('Gesetzmäßig Neutral')),
    DropdownMenuItem(value: 'True Neutral', child: Text('Wahrhaft Neutral')),
    DropdownMenuItem(value: 'Chaotic Neutral', child: Text('Chaotisch Neutral')),
    DropdownMenuItem(value: 'Lawful Evil', child: Text('Gesetzmäßig Böse')),
    DropdownMenuItem(value: 'neutral evil', child: Text('Neutral Böse')),
    DropdownMenuItem(value: 'Chaotic Evil', child: Text('Chaotisch Böse')),
    DropdownMenuItem(value: 'Unaligned', child: Text('Nicht ausgerichtet')),
  ];
}
