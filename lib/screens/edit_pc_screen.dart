// lib/screens/edit_pc_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';
import '../models/inventory_item.dart';
import '../models/player_character.dart';
// WICHTIG: DIESER IMPORT HAT GEFEHLT
import '../game_data/game_data.dart';
import '../game_data/dnd_models.dart';
import '../game_data/dnd_logic.dart';
import 'add_item_from_library_screen.dart';
import 'edit_item_screen.dart';

class EditPlayerCharacterScreen extends StatefulWidget {
  final String campaignId;
  final PlayerCharacter? pcToEdit;
  const EditPlayerCharacterScreen({super.key, required this.campaignId, this.pcToEdit});

  @override
  State<EditPlayerCharacterScreen> createState() => _EditPlayerCharacterScreenState();
}

class _EditPlayerCharacterScreenState extends State<EditPlayerCharacterScreen> {
  final _formKey = GlobalKey<FormState>();
  final dbHelper = DatabaseHelper.instance;
  
  late TextEditingController _nameController, _playerNameController, _levelController, _hpController, _acController, _strController, _dexController, _conController, _intController, _wisController, _chaController;
  DndClass? _selectedClass;
  DndRace? _selectedRace;
  late Set<String> _proficientSkills;
  String? _imagePath;
  late Future<List<DisplayInventoryItem>> _inventoryFuture;
  
  


  @override
  void initState() {
    super.initState();
    final pc = widget.pcToEdit;
    _nameController = TextEditingController(text: pc?.name ?? '');
    _playerNameController = TextEditingController(text: pc?.playerName ?? '');
    _levelController = TextEditingController(text: pc?.level.toString() ?? '1');
    _hpController = TextEditingController(text: pc?.maxHp.toString() ?? '10');
    _acController = TextEditingController(text: pc?.armorClass.toString() ?? '10');
    _strController = TextEditingController(text: pc?.strength.toString() ?? '10');
    _dexController = TextEditingController(text: pc?.dexterity.toString() ?? '10');
    _conController = TextEditingController(text: pc?.constitution.toString() ?? '10');
    _intController = TextEditingController(text: pc?.intelligence.toString() ?? '10');
    _wisController = TextEditingController(text: pc?.wisdom.toString() ?? '10');
    _chaController = TextEditingController(text: pc?.charisma.toString() ?? '10');
    _proficientSkills = pc?.proficientSkills.toSet() ?? {};
    _imagePath = pc?.imagePath;

    if (pc != null) {
      _selectedClass = allDndClasses.firstWhere((c) => c.name == pc.className, orElse: () => allDndClasses.first);
      _selectedRace = allDndRaces.firstWhere((r) => r.name == pc.raceName, orElse: () => allDndRaces.first);
    }
    _refreshInventory();
  }

  @override
  void dispose() {
    _nameController.dispose(); _playerNameController.dispose(); _levelController.dispose();
    _hpController.dispose(); _acController.dispose(); _strController.dispose();
    _dexController.dispose(); _conController.dispose(); _intController.dispose();
    _wisController.dispose(); _chaController.dispose();
    super.dispose();
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate() && _selectedClass != null && _selectedRace != null) {
      final dexScore = int.tryParse(_dexController.text) ?? 10;
      final pc = PlayerCharacter(
        id: widget.pcToEdit?.id,
        campaignId: widget.campaignId, name: _nameController.text, playerName: _playerNameController.text,
        className: _selectedClass!.name, raceName: _selectedRace!.name,
        level: int.tryParse(_levelController.text) ?? 1, maxHp: int.tryParse(_hpController.text) ?? 10,
        armorClass: int.tryParse(_acController.text) ?? 10, initiativeBonus: getModifier(dexScore),
        imagePath: _imagePath,
        strength: int.tryParse(_strController.text) ?? 10, dexterity: dexScore,
        constitution: int.tryParse(_conController.text) ?? 10, intelligence: int.tryParse(_intController.text) ?? 10,
        wisdom: int.tryParse(_wisController.text) ?? 10, charisma: int.tryParse(_chaController.text) ?? 10,
        proficientSkills: _proficientSkills.toList(),
      );

      if (widget.pcToEdit != null) { await dbHelper.updatePlayerCharacter(pc); } 
      else { await dbHelper.insertPlayerCharacter(pc); }
      
      if (mounted) Navigator.of(context).pop();
    }
  }


  void _showInfoDialog(String title, String explanation) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(explanation),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Verstanden")),
        ],
      ),
    );
  }

void _refreshInventory() {
    if (widget.pcToEdit != null) {
      setState(() { _inventoryFuture = dbHelper.getDisplayInventoryForOwner(widget.pcToEdit!.id); });
    } else {
      setState(() { _inventoryFuture = Future.value([]); });
    }
  }

    Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80, maxWidth: 600);
    if (image != null) {
      setState(() { _imagePath = image.path; });
    }
  }

  Future<void> _showManageItemDialog(DisplayInventoryItem displayItem) async {
    final quantityController = TextEditingController(text: displayItem.inventoryItem.quantity.toString());
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(displayItem.item.name),
        content: TextField(
          controller: quantityController,
          decoration: const InputDecoration(labelText: "Menge"),
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        actions: [
          // Löschen-Knopf
          TextButton(
            onPressed: () async {
              await dbHelper.deleteInventoryItem(displayItem.inventoryItem.id);
              if (mounted) Navigator.of(ctx).pop();
              _refreshInventory();
            },
            child: const Text("Löschen", style: TextStyle(color: Colors.redAccent)),
          ),
          // Abbrechen-Knopf
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("Abbrechen"),
          ),
          // Speichern-Knopf
          ElevatedButton(
            onPressed: () async {
              final newQuantity = int.tryParse(quantityController.text) ?? 1;
              final updatedItem = InventoryItem(
                id: displayItem.inventoryItem.id,
                ownerId: displayItem.inventoryItem.ownerId,
                itemId: displayItem.inventoryItem.itemId,
                quantity: newQuantity,
              );
              await dbHelper.updateInventoryItem(updatedItem);
              if (mounted) Navigator.of(ctx).pop();
              _refreshInventory();
            },
            child: const Text("Speichern"),
          ),
        ],
      ),
    );
  }
  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pcToEdit == null ? 'Neuen Helden erstellen' : 'Helden bearbeiten'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveForm)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // --- SEKTION 1: STAMMDATEN ---
            Text("Stammdaten", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            TextFormField(controller: _nameController, decoration: const InputDecoration(labelText: 'Name des Charakters'), validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null),
            const SizedBox(height: 16),
            TextFormField(controller: _playerNameController, decoration: const InputDecoration(labelText: 'Name des Spielers'), validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null),
            const SizedBox(height: 16),
            DropdownButtonFormField<DndClass>(
              value: _selectedClass, decoration: const InputDecoration(labelText: 'Klasse'),
              items: allDndClasses.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (val) => setState(() => _selectedClass = val),
              validator: (v) => v == null ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<DndRace>(
              value: _selectedRace, decoration: const InputDecoration(labelText: 'Rasse'),
              items: allDndRaces.map((r) => DropdownMenuItem(value: r, child: Text(r.name))).toList(),
              onChanged: (val) => setState(() => _selectedRace = val),
              validator: (v) => v == null ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            _buildNumberField(_levelController, 'Stufe'),
            const SizedBox(height: 24),

            // --- SEKTION 2: ATTRIBUTE ---
            Text("Attribute", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            _buildAbilityScoreRow("Stärke", _strController, "Erkläre deinem Spieler: 'Stärke ist deine Muskelkraft. Sie bestimmt, wie hart du zuschlägst, wie viel du tragen kannst und ob du eine schwere Tür eintreten kannst.'"),
            _buildAbilityScoreRow("Geschicklichkeit", _dexController, "Erkläre deinem Spieler: 'Geschicklichkeit ist deine Agilität und Reflexe. Sie ist wichtig für Diebe und Bogenschützen. Sie bestimmt deine Rüstungsklasse und wer im Kampf zuerst dran ist (Initiative).'"),
            _buildAbilityScoreRow("Konstitution", _conController, "Erkläre deinem Spieler: 'Konstitution ist deine Ausdauer und Zähigkeit. Ein hoher Wert gibt dir mehr Trefferpunkte und hilft dir, Giften zu widerstehen.'"),
            _buildAbilityScoreRow("Intelligenz", _intController, "Erkläre deinem Spieler: 'Intelligenz ist dein Wissen und deine Auffassungsgabe. Sie ist das wichtigste Attribut für Zauberer und hilft dir, magische Schriften zu entziffern oder Rätsel zu lösen.'"),
            _buildAbilityScoreRow("Weisheit", _wisController, "Erkläre deinem Spieler: 'Weisheit ist deine Intuition und dein Gespür für die Umgebung. Kleriker und Druiden brauchen sie. Sie hilft dir, Gefahren zu bemerken oder zu erkennen, ob jemand lügt.'"),
            _buildAbilityScoreRow("Charisma", _chaController, "Erkläre deinem Spieler: 'Charisma ist deine Persönlichkeit und Überzeugungskraft. Barden und Hexenmeister brauchen es. Es hilft dir, Leute zu überreden, einzuschüchtern oder zu täuschen.'"),
            const SizedBox(height: 24),
            
            // --- SEKTION 3: FÄHIGKEITEN ---
            Text("Fähigkeiten", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            // Hier wird 'allDndSkills' verwendet
            ...allDndSkills.map((skill) => _buildSkillRow(skill)).toList(),
            const SizedBox(height: 24),

            // --- SEKTION 4: KAMPFWERTE ---
            Text("Kampfwerte", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            Row(children: [
              Expanded(child: _buildNumberField(_hpController, 'Max. HP')),
              const SizedBox(width: 16),
              Expanded(child: _buildNumberField(_acController, 'Rüstungsklasse')),
            ]),
            const SizedBox(height: 24),
            const SizedBox(height: 24),
            // --- SEKTION 5: INVENTAR ---
            Text("Inventar", style: Theme.of(context).textTheme.titleLarge),
            const Divider(),
            
            if (widget.pcToEdit != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text("Gegenstand aus Bibliothek hinzufügen"),
                  onPressed: () async {
                    // TODO: Hier muss die Navigation zum neuen Item-Auswahl-Screen hin
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => AddItemFromLibraryScreen(ownerId: widget.pcToEdit!.id),
                     ));
                    _refreshInventory();
                  },
                ),
              ),

            if (widget.pcToEdit == null)
              const Text("Speichere den Charakter zuerst, um Gegenstände hinzuzufügen.", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),

            FutureBuilder<List<DisplayInventoryItem>>(
              future: _inventoryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("Inventar ist leer.", style: TextStyle(color: Colors.grey)));
                }
                final displayItems = snapshot.data!;
                return Column(
                  children: displayItems.map((displayItem) {
                    return ListTile(
                      leading: const Icon(Icons.shield_outlined),
                      // KORREKTUR: Greift auf das 'item'-Objekt zu, nicht 'entry'
                      title: Text(displayItem.item.name),
                      subtitle: Text(displayItem.item.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                      // KORREKTUR: Greift auf das 'inventoryItem'-Objekt für die Menge zu
                      trailing: Text("x${displayItem.inventoryItem.quantity}"),
                      onTap: () => _showManageItemDialog(displayItem),
                    );
                  }).toList(),// <-- HIER IST DIE LÖSUNG
                );
              }
            )
          ],
        ),
      ),
    );
  }
  
  Widget _buildAbilityScoreRow(String label, TextEditingController controller, String infoText) {
    void triggerRebuild() => setState(() {});
    final score = int.tryParse(controller.text) ?? 10;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(children: [
        Expanded(flex: 3, child: Row(children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.grey, size: 20),
            onPressed: () => _showInfoDialog(label, infoText),
            splashRadius: 20,
          ),
        ])),
        Expanded(flex: 2, child: TextFormField(
          controller: controller, textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(border: OutlineInputBorder()),
          onChanged: (_) => triggerRebuild(),
        )),
        Expanded(flex: 2, child: Center(child: Text(
          getModifierString(score),
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ))),
      ]),
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

  Widget _buildSkillRow(DndSkill skill) {
    final Map<Ability, TextEditingController> abilityControllers = {
      Ability.strength: _strController, Ability.dexterity: _dexController,
      Ability.constitution: _conController, Ability.intelligence: _intController,
      Ability.wisdom: _wisController, Ability.charisma: _chaController,
    };
    final score = int.tryParse(abilityControllers[skill.ability]!.text) ?? 10;
    final modifier = getModifier(score);
    final proficiencyBonus = getProficiencyBonus(int.tryParse(_levelController.text) ?? 1);
    final isProficient = _proficientSkills.contains(skill.name);
    final totalBonus = modifier + (isProficient ? proficiencyBonus : 0);
    final bonusString = totalBonus >= 0 ? "+$totalBonus" : totalBonus.toString();

    return Row(
      children: [
        Checkbox(
          value: isProficient,
          onChanged: (value) {
            setState(() {
              if (value == true) {
                _proficientSkills.add(skill.name);
              } else {
                _proficientSkills.remove(skill.name);
              }
            });
          },
        ),
        Expanded(child: Text(skill.name)),
        SizedBox(
          width: 40,
          child: Text(bonusString, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), textAlign: TextAlign.center),
        ),
      ],
    );
  }
}