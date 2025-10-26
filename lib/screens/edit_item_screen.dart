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
  
  // Spell-spezifische Variablen
  bool _isCantrip = false;
  int _spellLevel = 1;
  int _maxCastsPerDay = 1;
  bool _requiresConcentration = false;
  String _spellSchool = "Evocation";

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
      
      // Spell-spezifische Felder laden
      if (item.itemType == ItemType.SPELL_WEAPON) {
        _isCantrip = item.isCantrip ?? false;
        _spellLevel = item.spellLevel ?? 1;
        _maxCastsPerDay = item.maxCastsPerDay ?? 1;
        _requiresConcentration = item.requiresConcentration ?? false;
        _spellSchool = item.spellSchool ?? "Evocation";
      }
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
        damage: (_selectedType == ItemType.Weapon || _selectedType == ItemType.SPELL_WEAPON || _selectedType == ItemType.Scroll) 
            ? _damageController.text 
            : null,
        properties: (_selectedType == ItemType.Weapon || _selectedType == ItemType.SPELL_WEAPON || 
                     _selectedType == ItemType.Shield || _selectedType == ItemType.Consumable ||
                     _selectedType == ItemType.Potion || _selectedType == ItemType.Tool ||
                     _selectedType == ItemType.Material || _selectedType == ItemType.Component ||
                     _selectedType == ItemType.Scroll) 
            ? _propertiesController.text 
            : null,
        acFormula: (_selectedType == ItemType.Armor || _selectedType == ItemType.Shield ||
                   _selectedType == ItemType.Consumable || _selectedType == ItemType.Potion ||
                   _selectedType == ItemType.Scroll) 
            ? _acFormulaController.text 
            : null,
        requiresAttunement: _requiresAttunement,
        // Spell-spezifische Felder
        isSpell: _selectedType == ItemType.SPELL_WEAPON,
        spellLevel: _selectedType == ItemType.SPELL_WEAPON ? _spellLevel : null,
        spellSchool: _selectedType == ItemType.SPELL_WEAPON ? (_spellSchool.isEmpty ? null : _spellSchool) : null,
        isCantrip: _selectedType == ItemType.SPELL_WEAPON ? _isCantrip : false,
        maxCastsPerDay: (_selectedType == ItemType.SPELL_WEAPON && !_isCantrip) ? _maxCastsPerDay : null,
        requiresConcentration: _selectedType == ItemType.SPELL_WEAPON ? _requiresConcentration : false,
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
        title: Text(
          widget.itemToEdit == null ? 'Neuer Gegenstand' : 'Gegenstand bearbeiten',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: _getAppBarColor(),
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveForm,
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        ],
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

      if (_selectedType == ItemType.Shield) ...[
        const Divider(height: 24),
        Text("Schild-Eigenschaften", style: Theme.of(context).textTheme.titleMedium),
        TextFormField(controller: _acFormulaController, decoration: const InputDecoration(labelText: "Schadenbonus (z.B. +2)")),
        TextFormField(controller: _propertiesController, decoration: const InputDecoration(labelText: "Eigenschaften (z.B. Heavy, Magic)")),
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

      if (_selectedType == ItemType.SPELL_WEAPON) ...[
        const Divider(height: 24),
        Text("Zauber-Eigenschaften", style: Theme.of(context).textTheme.titleMedium),
        TextFormField(
          controller: _damageController,
          decoration: const InputDecoration(labelText: "Schaden (z.B. 3W6 Feuer)"),
          keyboardType: TextInputType.text,
        ),
        TextFormField(
          controller: _propertiesController,
          decoration: const InputDecoration(labelText: "Beschreibung/Effekte"),
          maxLines: 3,
        ),
        SwitchListTile(
          title: const Text("Ist Cantrip?"),
          subtitle: const Text("Cantrips können unbegrenzt gewirkt werden"),
          value: _isCantrip,
          onChanged: (val) => setState(() => _isCantrip = val),
        ),
        if (!_isCantrip) ...[
          TextFormField(
            controller: TextEditingController(text: _spellLevel.toString()),
            decoration: const InputDecoration(labelText: "Zauber-Level"),
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() => _spellLevel = int.tryParse(val) ?? 1),
          ),
          TextFormField(
            controller: TextEditingController(text: _maxCastsPerDay.toString()),
            decoration: const InputDecoration(labelText: "Maximale Beschwörungen pro Tag"),
            keyboardType: TextInputType.number,
            onChanged: (val) => setState(() => _maxCastsPerDay = int.tryParse(val) ?? 1),
          ),
        ],
        SwitchListTile(
          title: const Text("Konzentration erforderlich?"),
          subtitle: const Text("Benötigt Konzentration während der Wirkungsdauer"),
          value: _requiresConcentration,
          onChanged: (val) => setState(() => _requiresConcentration = val),
        ),
        DropdownButtonFormField<String?>(
          value: _spellSchool,
          decoration: const InputDecoration(labelText: "Magische Schule"),
          items: const [
            DropdownMenuItem(value: "Abjuration", child: Text("Abjuration")),
            DropdownMenuItem(value: "Conjuration", child: Text("Conjuration")),
            DropdownMenuItem(value: "Divination", child: Text("Divination")),
            DropdownMenuItem(value: "Enchantment", child: Text("Enchantment")),
            DropdownMenuItem(value: "Evocation", child: Text("Evocation")),
            DropdownMenuItem(value: "Illusion", child: Text("Illusion")),
            DropdownMenuItem(value: "Necromancy", child: Text("Necromancy")),
            DropdownMenuItem(value: "Transmutation", child: Text("Transmutation")),
          ],
          onChanged: (val) => setState(() => _spellSchool = val ?? "Evocation"),
        ),
      ],

      if (_selectedType == ItemType.Consumable) ...[
        const Divider(height: 24),
        Text("Verbrauchsgegenstand-Eigenschaften", style: Theme.of(context).textTheme.titleMedium),
        TextFormField(controller: _propertiesController, decoration: const InputDecoration(labelText: "Effekte (z.B. Heilt 2W8)")),
        TextFormField(controller: _acFormulaController, decoration: const InputDecoration(labelText: "Dauer (z.B. 1 Stunde)")),
      ],

      if (_selectedType == ItemType.Potion) ...[
        const Divider(height: 24),
        Text("Trank-Eigenschaften", style: Theme.of(context).textTheme.titleMedium),
        TextFormField(controller: _propertiesController, decoration: const InputDecoration(labelText: "Effekte (z.B. +2 Stärke für 1 Minute)")),
        TextFormField(controller: _acFormulaController, decoration: const InputDecoration(labelText: "Dauer (z.B. 1 Stunde)")),
      ],
      
      if (_selectedType == ItemType.Scroll) ...[
        const Divider(height: 24),
        Text("Schriftrollen-Eigenschaften", style: Theme.of(context).textTheme.titleMedium),
        TextFormField(controller: _damageController, decoration: const InputDecoration(labelText: "Enthaltener Zauber")),
        TextFormField(controller: _propertiesController, decoration: const InputDecoration(labelText: "Zauber-Level")),
        TextFormField(controller: _acFormulaController, decoration: const InputDecoration(labelText: "Ritualdauer (falls Ritual)")),
      ],

      if (_selectedType == ItemType.Tool) ...[
        const Divider(height: 24),
        Text("Werkzeug-Eigenschaften", style: Theme.of(context).textTheme.titleMedium),
        TextFormField(controller: _propertiesController, decoration: const InputDecoration(labelText: "Fähigkeiten (z.B. +2 auf Diebstahl Checks)")),
      ],

      if (_selectedType == ItemType.Material || _selectedType == ItemType.Component) ...[
        const Divider(height: 24),
        Text("Material-Eigenschaften", style: Theme.of(context).textTheme.titleMedium),
        TextFormField(controller: _propertiesController, decoration: const InputDecoration(labelText: "Verwendungszweck")),
        TextFormField(controller: _acFormulaController, decoration: const InputDecoration(labelText: "Seltenheit/Wert")),
      ],
          ],
        ),
      ),
    );
  }

  Color _getAppBarColor() {
    switch (_selectedType) {
      case ItemType.Weapon:
        return Colors.red.shade600;
      case ItemType.Armor:
        return Colors.blue.shade600;
      case ItemType.Shield:
        return Colors.cyan.shade600;
      case ItemType.SPELL_WEAPON:
        return Colors.deepPurple.shade600;
      case ItemType.MagicItem:
        return Colors.purple.shade600;
      case ItemType.Consumable:
        return Colors.orange.shade600;
      case ItemType.Potion:
        return Colors.pink.shade600;
      case ItemType.Scroll:
        return Colors.indigo.shade600;
      case ItemType.Tool:
        return Colors.brown.shade600;
      case ItemType.Material:
      case ItemType.Component:
        return Colors.grey.shade600;
      case ItemType.Treasure:
        return Colors.amber.shade600;
      case ItemType.Currency:
        return Colors.yellow.shade600;
      case ItemType.AdventuringGear:
      default:
        return Colors.green.shade600;
    }
  }
}
