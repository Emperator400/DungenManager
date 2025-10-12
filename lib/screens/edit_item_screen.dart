// lib/screens/edit_item_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/item.dart';

class EditItemScreen extends StatefulWidget {
  final Item? itemToEdit;

  const EditItemScreen({super.key, this.itemToEdit});

  @override
  State<EditItemScreen> createState() => _EditItemScreenState();
}

class _EditItemScreenState extends State<EditItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;

  late TextEditingController _nameController, _descriptionController, _weightController, _costController;
  late TextEditingController _damageController, _propertiesController, _acFormulaController;
  
  ItemType _selectedType = ItemType.AdventuringGear;
  bool _requiresAttunement = false;

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descriptionController = TextEditingController(text: item?.description ?? '');
    _weightController = TextEditingController(text: item?.weight.toString() ?? '0');
    _costController = TextEditingController(text: item?.cost.toString() ?? '0');
    _damageController = TextEditingController(text: item?.damage ?? '');
    _propertiesController = TextEditingController(text: item?.properties ?? '');
    _acFormulaController = TextEditingController(text: item?.acFormula ?? '');
    
    if (item != null) {
      _selectedType = item.itemType;
      _requiresAttunement = item.requiresAttunement ?? false;
    }
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final item = Item(
        id: widget.itemToEdit?.id,
        name: _nameController.text,
        description: _descriptionController.text,
        itemType: _selectedType,
        weight: double.tryParse(_weightController.text) ?? 0.0,
        cost: double.tryParse(_costController.text) ?? 0.0,
        damage: _selectedType == ItemType.Weapon ? _damageController.text : null,
        properties: _selectedType == ItemType.Weapon ? _propertiesController.text : null,
        acFormula: _selectedType == ItemType.Armor ? _acFormulaController.text : null,
        requiresAttunement: _requiresAttunement,
        // Weitere Felder wie rarity, etc. könnten hier hinzugefügt werden
      );

      if (widget.itemToEdit != null) {
        await dbHelper.updateItem(item);
      } else {
        await dbHelper.insertItem(item);
      }
      
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.itemToEdit == null ? 'Neuer Gegenstand' : 'Gegenstand bearbeiten'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveForm)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: "Name"), validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<ItemType>(
              value: _selectedType,
              decoration: const InputDecoration(labelText: "Gegenstandstyp"),
              items: ItemType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.toString().split('.').last))).toList(),
              onChanged: (val) => setState(() => _selectedType = val!),
            ),
            const SizedBox(height: 16),
            TextFormField(controller: _descriptionController, decoration: const InputDecoration(labelText: "Beschreibung", border: OutlineInputBorder()), maxLines: 3),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(child: TextFormField(controller: _weightController, decoration: const InputDecoration(labelText: "Gewicht (Pfund)"), keyboardType: TextInputType.number)),
              const SizedBox(width: 16),
              Expanded(child: TextFormField(controller: _costController, decoration: const InputDecoration(labelText: "Wert (Gold)"), keyboardType: TextInputType.number)),
            ]),
            const SizedBox(height: 16),
            
            // --- Dynamische Felder, die nur bei bestimmtem Typ erscheinen ---
            if (_selectedType == ItemType.Weapon) ...[
              const Divider(height: 24),
              Text("Waffen-Eigenschaften", style: Theme.of(context).textTheme.titleMedium),
              TextFormField(controller: _damageController, decoration: const InputDecoration(labelText: "Schaden (z.B. 1W8 Wuchtschaden)")),
              TextFormField(controller: _propertiesController, decoration: const InputDecoration(labelText: "Eigenschaften (z.B. Finesse, Vielseitig)")),
            ],

            if (_selectedType == ItemType.Armor) ...[
              const Divider(height: 24),
              Text("Rüstungs-Eigenschaften", style: Theme.of(context).textTheme.titleMedium),
              TextFormField(controller: _acFormulaController, decoration: const InputDecoration(labelText: "Rüstungsklassen-Formel (z.B. 14 + DEX (max 2))")),
            ],
            
            if (_selectedType == ItemType.MagicItem) ...[
              const Divider(height: 24),
              Text("Magische Eigenschaften", style: Theme.of(context).textTheme.titleMedium),
              SwitchListTile(
                title: const Text("Einstimmung erforderlich?"),
                value: _requiresAttunement,
                onChanged: (val) => setState(() => _requiresAttunement = val),
              ),
            ],
          ],
        ),
      ),
    );
  }
}