import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/creature.dart';
import '../models/item.dart';
import '../models/inventory_item.dart';
import '../models/official_monster.dart';
import 'official_monsters_screen.dart';
import 'item_library_screen.dart';

class EditCreatureScreen extends StatefulWidget {
  final Creature? creatureToEdit;
  const EditCreatureScreen({super.key, this.creatureToEdit});

  @override
  State<EditCreatureScreen> createState() => _EditCreatureScreenState();
}

class _EditCreatureScreenState extends State<EditCreatureScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TabController _tabController;
  final dbHelper = DatabaseHelper.instance;

  // Basis-Info Controllers
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  
  // Kampf-Stats Controllers
  late TextEditingController _hpController;
  late TextEditingController _acController;
  late TextEditingController _speedController;
  late TextEditingController _initBonusController;
  late TextEditingController _crController;
  
  // Attribute Controllers
  late TextEditingController _strController;
  late TextEditingController _dexController;
  late TextEditingController _conController;
  late TextEditingController _intController;
  late TextEditingController _wisController;
  late TextEditingController _chaController;
  
  // Fähigkeiten Controllers
  late TextEditingController _attacksController;
  late TextEditingController _specialAbilitiesController;
  late TextEditingController _legendaryActionsController;
  
  // D&D-Felder
  String _selectedSize = 'Medium';
  String _selectedType = 'Humanoid';
  String? _selectedSubtype;
  String _selectedAlignment = 'Neutral';
  
  // Inventar
  List<DisplayInventoryItem> _inventory = [];
  double _gold = 0.0;
  bool _isLoadingInventory = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _initializeControllers();
    _loadInventory();
  }

  void _initializeControllers() {
    final creature = widget.creatureToEdit;
    
    // Basis-Info
    _nameController = TextEditingController(text: creature?.name ?? '');
    _descriptionController = TextEditingController(text: creature?.description ?? '');
    
    // Kampf-Stats
    _hpController = TextEditingController(text: creature?.maxHp.toString() ?? '10');
    _acController = TextEditingController(text: creature?.armorClass.toString() ?? '10');
    _speedController = TextEditingController(text: creature?.speed ?? '30ft');
    _initBonusController = TextEditingController(text: creature?.initiativeBonus.toString() ?? '0');
    _crController = TextEditingController(text: creature?.challengeRating?.toString() ?? '0.25');
    
    // Attribute
    _strController = TextEditingController(text: creature?.strength.toString() ?? '10');
    _dexController = TextEditingController(text: creature?.dexterity.toString() ?? '10');
    _conController = TextEditingController(text: creature?.constitution.toString() ?? '10');
    _intController = TextEditingController(text: creature?.intelligence.toString() ?? '10');
    _wisController = TextEditingController(text: creature?.wisdom.toString() ?? '10');
    _chaController = TextEditingController(text: creature?.charisma.toString() ?? '10');
    
    // Fähigkeiten
    _attacksController = TextEditingController(text: creature?.attacks ?? '');
    _specialAbilitiesController = TextEditingController(text: creature?.specialAbilities ?? '');
    _legendaryActionsController = TextEditingController(text: creature?.legendaryActions ?? '');
    
    // D&D-Felder
    _selectedSize = creature?.size ?? 'Medium';
    _selectedType = creature?.type ?? 'Humanoid';
    _selectedSubtype = creature?.subtype;
    _selectedAlignment = creature?.alignment ?? 'True Neutral';
    _gold = creature?.gold ?? 0.0;
  }

  Future<void> _loadInventory() async {
    if (widget.creatureToEdit == null) return;
    
    setState(() => _isLoadingInventory = true);
    try {
      final inventory = await dbHelper.getDisplayInventoryForOwner(widget.creatureToEdit!.id);
      setState(() {
        _inventory = inventory;
        _isLoadingInventory = false;
      });
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Inventars: $e')),
        );
      }
      setState(() => _isLoadingInventory = false);
    }
  }

  Future<void> _saveForm() async {
    if (_formKey.currentState!.validate()) {
      // Berechne Ability Modifiers und andere abgeleitete Werte
      final strength = int.tryParse(_strController.text) ?? 10;
      final dexterity = int.tryParse(_dexController.text) ?? 10;
      final initiativeBonus = int.tryParse(_initBonusController.text) ?? 0;
      
      final creature = Creature(
        id: widget.creatureToEdit?.id,
        name: _nameController.text,
        maxHp: int.tryParse(_hpController.text) ?? 10,
        currentHp: int.tryParse(_hpController.text) ?? 10,
        armorClass: int.tryParse(_acController.text) ?? 10,
        speed: _speedController.text,
        attacks: _attacksController.text,
        initiativeBonus: initiativeBonus,
        strength: strength,
        dexterity: dexterity,
        constitution: int.tryParse(_conController.text) ?? 10,
        intelligence: int.tryParse(_intController.text) ?? 10,
        wisdom: int.tryParse(_wisController.text) ?? 10,
        charisma: int.tryParse(_chaController.text) ?? 10,
        gold: _gold,
        silver: 0.0, // Könnte später erweitert werden
        copper: 0.0, // Könnte später erweitert werden
        size: _selectedSize,
        type: _selectedType,
        subtype: _selectedSubtype?.isNotEmpty == true ? _selectedSubtype : null,
        alignment: _selectedAlignment,
        challengeRating: (double.tryParse(_crController.text) ?? 0.25).round(),
        specialAbilities: _specialAbilitiesController.text.isNotEmpty ? _specialAbilitiesController.text : null,
        legendaryActions: _legendaryActionsController.text.isNotEmpty ? _legendaryActionsController.text : null,
        description: _descriptionController.text.isNotEmpty ? _descriptionController.text : null,
        isCustom: true,
        sourceType: 'custom',
      );

      if (widget.creatureToEdit != null) {
        await dbHelper.updateCreature(creature);
      } else {
        await dbHelper.insertCreature(creature);
      }
      
      if (mounted && context.mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _importFromOfficialMonster() async {
    final selectedMonster = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const OfficialMonstersScreen(),
      ),
    );

    if (selectedMonster != null && mounted) {
      setState(() {
        _nameController.text = selectedMonster.name;
        _hpController.text = selectedMonster.hitPoints.toString();
        _acController.text = selectedMonster.armorClass;
        _speedController.text = selectedMonster.speed;
        _strController.text = selectedMonster.strength.toString();
        _dexController.text = selectedMonster.dexterity.toString();
        _conController.text = selectedMonster.constitution.toString();
        _intController.text = selectedMonster.intelligence.toString();
        _wisController.text = selectedMonster.wisdom.toString();
        _chaController.text = selectedMonster.charisma.toString();
        _crController.text = selectedMonster.challengeRating.toString();
        _selectedSize = selectedMonster.size;
        _selectedType = selectedMonster.type;
        _selectedSubtype = selectedMonster.subtype;
        _selectedAlignment = selectedMonster.alignment;
        _attacksController.text = selectedMonster.actions.map((a) => '${a.name}: ${a.description}').join('\n');
        _specialAbilitiesController.text = selectedMonster.specialAbilities.isNotEmpty 
            ? selectedMonster.specialAbilities.map((a) => '${a.name}: ${a.description}').join('\n\n')
            : '';
        _legendaryActionsController.text = selectedMonster.legendaryActions?.isNotEmpty == true
            ? selectedMonster.legendaryActions!.map((a) => '${a.name}: ${a.description}').join('\n\n')
            : '';
        _initBonusController.text = '0';
      });
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${selectedMonster.name} wurde importiert')),
        );
      }
    }
  }

  Future<void> _addItemFromLibrary() async {
    final selectedItem = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const ItemLibraryScreen(selectMode: true),
      ),
    );

    if (selectedItem != null && selectedItem is Item && mounted) {
      try {
        final creatureId = widget.creatureToEdit?.id;
        if (creatureId == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bitte speichern Sie zuerst die Kreatur')),
          );
          return;
        }

        final inventoryItem = InventoryItem(
          ownerId: creatureId,
          itemId: selectedItem.id,
          quantity: 1,
        );

        await dbHelper.insertInventoryItem(inventoryItem);
        await _loadInventory();

        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${selectedItem.name} wurde zum Inventar hinzugefügt')),
          );
        }
      } catch (e) {
        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Hinzufügen: $e')),
          );
        }
      }
    }
  }

  Future<void> _removeItem(DisplayInventoryItem displayItem) async {
    try {
      await dbHelper.deleteInventoryItem(displayItem.inventoryItem.id);
      await _loadInventory();

      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${displayItem.item.name} wurde entfernt')),
        );
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Entfernen: $e')),
        );
      }
    }
  }

  Future<void> _updateItemQuantity(DisplayInventoryItem displayItem, int newQuantity) async {
    if (newQuantity <= 0) {
      await _removeItem(displayItem);
      return;
    }

    try {
      final updatedItem = displayItem.inventoryItem.copyWith(quantity: newQuantity);
      await dbHelper.updateInventoryItem(updatedItem);
      await _loadInventory();
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Aktualisieren: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Alle Controller disposen
    _nameController.dispose();
    _descriptionController.dispose();
    _hpController.dispose();
    _acController.dispose();
    _speedController.dispose();
    _initBonusController.dispose();
    _crController.dispose();
    _strController.dispose();
    _dexController.dispose();
    _conController.dispose();
    _intController.dispose();
    _wisController.dispose();
    _chaController.dispose();
    _attacksController.dispose();
    _specialAbilitiesController.dispose();
    _legendaryActionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.creatureToEdit == null ? 'Neues Monster/NSC' : 'Monster/NSC bearbeiten'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Basis', icon: Icon(Icons.info)),
            Tab(text: 'Attribute', icon: Icon(Icons.fitness_center)),
            Tab(text: 'Fähigkeiten', icon: Icon(Icons.flash_on)),
            Tab(text: 'Inventar', icon: Icon(Icons.inventory)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _importFromOfficialMonster,
            tooltip: 'Aus offiziellem Monster importieren',
          ),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveForm),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildBasicInfoTab(),
          _buildAttributesTab(),
          _buildAbilitiesTab(),
          _buildInventoryTab(),
        ],
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              validator: (v) => v!.isEmpty ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 16),
            
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            
            // Kampf-Stats
            const Text('Kampf-Stats', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(child: _buildNumberField(_hpController, 'Maximale HP *')),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(_acController, 'Rüstungsklasse (AC) *')),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(_initBonusController, 'Initiative-Bonus')),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(child: TextFormField(
                  controller: _speedController,
                  decoration: const InputDecoration(labelText: 'Bewegungsrate'),
                )),
                const SizedBox(width: 16),
                Expanded(child: TextFormField(
                  controller: _crController,
                  decoration: const InputDecoration(labelText: 'Challenge Rating'),
                  keyboardType: TextInputType.number,
                )),
              ],
            ),
            const SizedBox(height: 16),
            
            // D&D-Klassifikation
            const Text('D&D-Klassifikation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedSize,
                    decoration: const InputDecoration(labelText: 'Größe'),
                    items: const [
                      DropdownMenuItem(value: 'Tiny', child: Text('Winzig')),
                      DropdownMenuItem(value: 'Small', child: Text('Klein')),
                      DropdownMenuItem(value: 'Medium', child: Text('Mittel')),
                      DropdownMenuItem(value: 'Large', child: Text('Groß')),
                      DropdownMenuItem(value: 'Huge', child: Text('Riesig')),
                      DropdownMenuItem(value: 'Gargantuan', child: Text('Gigantisch')),
                    ],
                    onChanged: (value) => setState(() => _selectedSize = value!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedType,
                    decoration: const InputDecoration(labelText: 'Typ'),
                    items: const [
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
                      DropdownMenuItem(value: 'Undead', child: Text('Untot')),
                    ],
                    onChanged: (value) => setState(() => _selectedType = value!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: TextEditingController(text: _selectedSubtype ?? ''),
                    decoration: const InputDecoration(labelText: 'Subtyp (optional)'),
                    onChanged: (value) => setState(() => _selectedSubtype = value.isEmpty ? null : value),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAlignment,
                    decoration: const InputDecoration(labelText: 'Gesinnung'),
                    items: const [
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
                    ],
                    onChanged: (value) => setState(() => _selectedAlignment = value!),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttributesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('Die 6 Hauptattribute', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          
          // Fähigkeitswerte in 2x3 Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            children: [
              _buildAttributeField(_strController, 'Stärke (STR)', 'red'),
              _buildAttributeField(_dexController, 'Geschicklichkeit (DEX)', 'green'),
              _buildAttributeField(_conController, 'Konstitution (CON)', 'orange'),
              _buildAttributeField(_intController, 'Intelligenz (INT)', 'blue'),
              _buildAttributeField(_wisController, 'Weisheit (WIS)', 'purple'),
              _buildAttributeField(_chaController, 'Charisma (CHA)', 'pink'),
            ],
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Ability Modifiers\n(STR-10)/2 = Modifier',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAbilitiesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView(
        children: [
          const Text('Angriffe & Aktionen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _attacksController,
            decoration: const InputDecoration(
              labelText: 'Angriffe & Aktionen',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              hintText: 'Schwerthieb: +4 (1W8+2) Hiegschaden\nBogen: +3 (1W6+2) Stichschaden',
            ),
            maxLines: 6,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 24),
          
          const Text('Spezielle Fähigkeiten', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _specialAbilitiesController,
            decoration: const InputDecoration(
              labelText: 'Spezielle Fähigkeiten',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              hintText: 'Regeneration (3/Runte). Wenn der Drache einen Feuer-Schaden erleidet, bekommt er keine Regeneration in diesem Zug.',
            ),
            maxLines: 6,
            keyboardType: TextInputType.multiline,
          ),
          const SizedBox(height: 24),
          
          const Text('Legendäre Aktionen', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextFormField(
            controller: _legendaryActionsController,
            decoration: const InputDecoration(
              labelText: 'Legendäre Aktionen',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
              hintText: 'Der Drache kann 3 legendäre Aktionen ausführen und wählt aus den folgenden Optionen. Nur eine legendäre Aktion kann gleichzeitig verwendet werden und nur am Ende des Zuges einer anderen Kreatur.',
            ),
            maxLines: 6,
            keyboardType: TextInputType.multiline,
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Gold-Management
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.monetization_on, color: Colors.amber),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      initialValue: _gold.toString(),
                      decoration: const InputDecoration(
                        labelText: 'Goldstücke',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) => setState(() => _gold = double.tryParse(value) ?? 0.0),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Inventar-Liste
          Expanded(
            child: Card(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        const Text('Inventar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        if (widget.creatureToEdit != null)
                          ElevatedButton.icon(
                            onPressed: _addItemFromLibrary,
                            icon: const Icon(Icons.add),
                            label: const Text('Gegenstand hinzufügen'),
                          ),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: _isLoadingInventory
                        ? const Center(child: CircularProgressIndicator())
                        : _inventory.isEmpty
                            ? const Center(
                                child: Text(
                                  'Keine Gegenstände im Inventar\n\nFügen Sie Gegenstände aus der Bibliothek hinzu',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.grey),
                                ),
                              )
                            : ListView.builder(
                                itemCount: _inventory.length,
                                itemBuilder: (context, index) {
                                  final displayItem = _inventory[index];
                                  final item = displayItem.item;
                                  final invItem = displayItem.inventoryItem;
                                  
                                  return ListTile(
                                    leading: CircleAvatar(
                                      child: Text(item.itemType.toString().split('.').first[0]),
                                    ),
                                    title: Text(item.name),
                                    subtitle: Text('${item.itemType.toString().split('.').last} • ${item.weight} Pfund'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Mengen-Editor
                                        SizedBox(
                                          width: 100,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.remove, size: 20),
                                                onPressed: () => _updateItemQuantity(displayItem, invItem.quantity - 1),
                                              ),
                                              Text(
                                                invItem.quantity.toString(),
                                                style: const TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add, size: 20),
                                                onPressed: () => _updateItemQuantity(displayItem, invItem.quantity + 1),
                                              ),
                                            ],
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeItem(displayItem),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildAttributeField(TextEditingController controller, String label, String color) {
    final value = int.tryParse(controller.text) ?? 10;
    final modifier = ((value - 10) / 2).floor();
    final modifierText = modifier >= 0 ? '+$modifier' : '$modifier';
    
    Color avatarColor;
    switch (color) {
      case 'red': avatarColor = Colors.red; break;
      case 'green': avatarColor = Colors.green; break;
      case 'orange': avatarColor = Colors.orange; break;
      case 'blue': avatarColor = Colors.blue; break;
      case 'purple': avatarColor = Colors.purple; break;
      case 'pink': avatarColor = Colors.pink; break;
      default: avatarColor = Colors.grey;
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: avatarColor,
                  child: Text(
                    value.toString(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  modifierText,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(isDense: true),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// Extension für InventoryItem copyWith
extension InventoryItemCopy on InventoryItem {
  InventoryItem copyWith({
    String? id,
    String? ownerId,
    String? itemId,
    int? quantity,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      itemId: itemId ?? this.itemId,
      quantity: quantity ?? this.quantity,
    );
  }
}
