// lib/screens/encounter_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/creature.dart';
import '../models/player_character.dart';
import 'initiative_tracker_screen.dart';

class EncounterSetupScreen extends StatefulWidget {
  final Campaign campaign;
  const EncounterSetupScreen({super.key, required this.campaign});

  @override
  State<EncounterSetupScreen> createState() => _EncounterSetupScreenState();
}

class _EncounterSetupScreenState extends State<EncounterSetupScreen> {
  // Datenbank-Helfer 
  final dbHelper = DatabaseHelper.instance;
  // Futures für Helden und Monster
  late Future<List<PlayerCharacter>> _pcsFuture;
  late Future<List<Creature>> _monstersFuture;
  // Ausgewählte Teilnehmer
  final List<PlayerCharacter> _selectedPcs = [];
  final List<Creature> _selectedMonsters = [];
  // Map zur Speicherung der eingegebenen Ini-Werte
  final Map<String, int?> _initiativeScores = {};

  @override
  void initState() {
    super.initState();
    _pcsFuture = dbHelper.getPlayerCharactersForCampaign(widget.campaign.id);
    _monstersFuture = dbHelper.getAllCreatures();
  }

 void _startCombat() async {
    if (_selectedPcs.isEmpty && _selectedMonsters.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Bitte wähle Teilnehmer aus.")));
      return;
    }

    final List<Creature> combatants = [];

    // Lade Inventare für die Helden und erstelle die Kampf-Objekte
    for (final pc in _selectedPcs) {
      // Warte auf das Inventar aus der Datenbank
      final inventory = await dbHelper.getDisplayInventoryForOwner(pc.id);
      combatants.add(Creature(
        id: pc.id, name: pc.name, maxHp: pc.maxHp, currentHp: pc.maxHp, isPlayer: true,
        armorClass: pc.armorClass, initiativeBonus: pc.initiativeBonus,
        strength: pc.strength, dexterity: pc.dexterity, constitution: pc.constitution,
        intelligence: pc.intelligence, wisdom: pc.wisdom, charisma: pc.charisma,
        inventory: inventory, // Übergib das geladene Inventar
      )..initiative = _initiativeScores[pc.id]);
    }

    // Lade Inventare für die Monster und erstelle die Kampf-Objekte
    // Lade Inventare für die Monster und erstelle die Kampf-Objekte
    for (final monster in _selectedMonsters) {
      // Warte auf das Inventar aus der Datenbank
      final inventory = await dbHelper.getDisplayInventoryForOwner(monster.id);
      combatants.add(Creature(
        id: monster.id, name: monster.name, maxHp: monster.maxHp, currentHp: monster.maxHp, isPlayer: false,
        armorClass: monster.armorClass, speed: monster.speed, attacks: monster.attacks, 
        initiativeBonus: monster.initiativeBonus,
        inventory: inventory, // Übergib das geladene Inventar
      )..initiative = _initiativeScores[monster.id]);
    }
    
    // Wichtig: 'mounted' prüfen nach einem await-Aufruf
    if (!mounted) return;

    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => InitiativeTrackerScreen(creatures: combatants),
    ));
  


    // Übergib alle Werte des Monsters an das Kampf-Objekt
    combatants.addAll(_selectedMonsters.map((m) => Creature(
      id: m.id, name: m.name, maxHp: m.maxHp, currentHp: m.maxHp, isPlayer: false,
      armorClass: m.armorClass, speed: m.speed, attacks: m.attacks, 
      initiativeBonus: m.initiativeBonus,
    )));

    Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => InitiativeTrackerScreen(creatures: combatants),
    ));
  }
  
  void _addCombatant(Object data) {
    setState(() {
      if (data is PlayerCharacter && !_selectedPcs.contains(data)) _selectedPcs.add(data);
      else if (data is Creature && !_selectedMonsters.contains(data)) _selectedMonsters.add(data);
    });
  }
  
  void _removeCombatant(Object data) {
    setState(() {
      final id = data is PlayerCharacter ? data.id : (data as Creature).id;
      _initiativeScores.remove(id);
      if (data is PlayerCharacter) _selectedPcs.remove(data);
      else if (data is Creature) _selectedMonsters.remove(data);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kampf zusammenstellen")),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_pcsFuture, _monstersFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final List<PlayerCharacter> allPcs = snapshot.data![0];
          final List<Creature> allMonsters = snapshot.data![1];
          final availablePcs = allPcs.where((pc) => !_selectedPcs.contains(pc)).toList();
          final availableMonsters = allMonsters.where((m) => !_selectedMonsters.contains(m)).toList();

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const Text("Verfügbar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      const Text("Helden", style: TextStyle(color: Colors.grey)),
                      Expanded(child: _buildDraggableList(availablePcs)),
                      const Divider(),
                      const Text("Gegner", style: TextStyle(color: Colors.grey)),
                      Expanded(child: _buildDraggableList(availableMonsters)),
                    ],
                  ),
                ),
                const VerticalDivider(width: 16),
                Expanded(
                  flex: 3,
                  child: DragTarget<Object>(
                    onAccept: (data) => _addCombatant(data),
                    builder: (context, candidateData, rejectedData) => Container(
                       decoration: BoxDecoration(
                         color: candidateData.isNotEmpty ? Colors.orange.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                         borderRadius: BorderRadius.circular(8),
                       ),
                      child: Column(
                        children: [
                          const Text("Im Kampf", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          const Divider(),
                          Expanded(child: _buildSelectedList([..._selectedPcs, ..._selectedMonsters])),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton.icon(
          icon: const Icon(Icons.play_arrow),
          label: const Text("Kampf beginnen!"),
          onPressed: _startCombat,
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ),
    );
  }

  Widget _buildDraggableList(List<Object> items) {
    if (items.isEmpty) return const Center(child: Text("Keine verfügbar", style: TextStyle(color: Colors.grey)));
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final card = _buildItemCard(item);
        return Draggable<Object>(
          data: item,
          feedback: Material(color: Colors.transparent, child: card),
          childWhenDragging: Opacity(opacity: 0.4, child: card),
          child: card,
        );
      },
    );
  }

  Widget _buildSelectedList(List<Object> items) {
  if (items.isEmpty) return const Center(child: Text("Hier Teilnehmer reinziehen", style: TextStyle(color: Colors.grey)));
  
  return ListView.builder(
    itemCount: items.length,
    itemBuilder: (context, index) {
      final item = items[index];
      final id = item is PlayerCharacter ? item.id : (item as Creature).id;
      final name = item is PlayerCharacter ? item.name : (item as Creature).name;
      final isPc = item is PlayerCharacter;
      
      // Hole den Bonus, abhängig vom Typ
      final int bonus = item is PlayerCharacter ? item.initiativeBonus : (item as Creature).initiativeBonus;
      final String bonusString = bonus >= 0 ? "+$bonus" : bonus.toString();

      return ListTile(
        leading: Icon(isPc ? Icons.account_circle : Icons.shield),
        title: Text(name),
        trailing: SizedBox(
          width: 120,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Wickel das Textfeld in ein Tooltip-Widget
              Tooltip(
                message: "Automatischer Wurf: 1W20 $bonusString",
                child: SizedBox(
                  width: 50,
                  child: TextField(
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(hintText: "Ini"),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (value) {
                      if (value.isEmpty) {
                        _initiativeScores[id] = null;
                      } else {
                        _initiativeScores[id] = int.tryParse(value);
                      }
                    },
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                onPressed: () => _removeCombatant(item),
              ),
            ],
          ),
        ),
      );
    },
  );
}

  Widget _buildItemCard(Object item) {
    final bool isPc = item is PlayerCharacter;
    return Card(
      color: isPc ? Colors.blue[800] : Colors.red[900],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Text(
          isPc ? (item as PlayerCharacter).name : (item as Creature).name, 
          style: const TextStyle(color: Colors.white)
        ),
      ),
    );
  }
}