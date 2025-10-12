// lib/screens/edit_creature_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/creature.dart';

class EditCreatureScreen extends StatefulWidget {
  final Creature? creatureToEdit;
  const EditCreatureScreen({super.key, this.creatureToEdit});

  @override
  State<EditCreatureScreen> createState() => _EditCreatureScreenState();
}

class _EditCreatureScreenState extends State<EditCreatureScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _hpController;
  late TextEditingController _acController;
  late TextEditingController _speedController;
  late TextEditingController _attacksController;
  late TextEditingController _initBonusController;

  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.creatureToEdit?.name ?? '');
    _hpController = TextEditingController(text: widget.creatureToEdit?.maxHp.toString() ?? '');
    _acController = TextEditingController(text: widget.creatureToEdit?.armorClass.toString() ?? '10');
    _speedController = TextEditingController(text: widget.creatureToEdit?.speed ?? '30ft');
    _attacksController = TextEditingController(text: widget.creatureToEdit?.attacks ?? '');
    _initBonusController = TextEditingController(text: widget.creatureToEdit?.initiativeBonus.toString() ?? '0');
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      // Erstelle ein Creature-Objekt mit allen Daten aus den Feldern
      final creature = Creature(
        id: widget.creatureToEdit?.id,
        name: _nameController.text,
        maxHp: int.tryParse(_hpController.text) ?? 10,
        currentHp: int.tryParse(_hpController.text) ?? 10, // Beim Speichern immer volle HP
        armorClass: int.tryParse(_acController.text) ?? 10,
        speed: _speedController.text,
        attacks: _attacksController.text,
        initiativeBonus: int.tryParse(_initBonusController.text) ?? 0,
      );

      if (widget.creatureToEdit != null) {
        await dbHelper.updateCreature(creature);
      } else {
        await dbHelper.insertCreature(creature);
      }
      
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.creatureToEdit == null ? 'Neues Monster/NSC' : 'Monster/NSC bearbeiten'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveForm)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null),
              const SizedBox(height: 16),
              // Wir packen HP und AC nebeneinander für ein kompakteres Layout
              Row(
                children: [
                  Expanded(child: _buildNumberField(_hpController, 'Maximale HP')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildNumberField(_acController, 'Rüstungsklasse (AC)')),
                  const SizedBox(width: 16),
                  Expanded(child: _buildNumberField(_initBonusController, 'Initiative-Bonus')),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(controller: _speedController, decoration: const InputDecoration(labelText: 'Bewegungsrate (z.B. 30ft, 40ft fly)')),
              const SizedBox(height: 16),
              // Grosses Textfeld für die Angriffe
              TextFormField(
                controller: _attacksController,
                decoration: const InputDecoration(labelText: 'Angriffe & Aktionen', alignLabelWithHint: true, border: OutlineInputBorder()),
                maxLines: 5,
                keyboardType: TextInputType.multiline,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
    );
  }
}