// lib/screens/encounter_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/campaign.dart';
import '../models/creature.dart';
import '../models/player_character.dart';

/// Encounter Setup Screen
/// 
/// Screen zum Zusammenstellen von Kämpfen mit Helden und Monstern.
/// HINWEIS: Dies ist eine Demo-Implementierung mit eingeschränkter Funktionalität.
/// Für die vollständige Funktionalität müssen entsprechende Services erstellt werden.
class EncounterSetupScreen extends StatefulWidget {
  final Campaign campaign;
  const EncounterSetupScreen({super.key, required this.campaign});

  @override
  State<EncounterSetupScreen> createState() => _EncounterSetupScreenState();
}

class _EncounterSetupScreenState extends State<EncounterSetupScreen> {
  // Demo-Daten: In einer echten Implementierung würden diese aus einer Datenbank kommen
  late Future<List<PlayerCharacter>> _pcsFuture;
  late Future<List<Creature>> _monstersFuture;
  
  // Ausgewählte Teilnehmer
  final List<PlayerCharacter> _selectedPcs = [];
  final List<Creature> _selectedMonsters = [];
  
  // Map zur Speicherung der eingegebenen Initiative-Werte
  final Map<String, int?> _initiativeScores = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    // Demo-Implementierung: Gibt leere Listen zurück
    // HINWEIS: Für die volle Funktionalität müssen entsprechende Services erstellt werden
    setState(() {
      _pcsFuture = _loadPcsData();
      _monstersFuture = _loadMonstersData();
    });
  }

  Future<List<PlayerCharacter>> _loadPcsData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return <PlayerCharacter>[];
  }

  Future<List<Creature>> _loadMonstersData() async {
    await Future.delayed(const Duration(milliseconds: 100));
    return <Creature>[];
  }

  Future<void> _startCombat() async {
    if (_selectedPcs.isEmpty && _selectedMonsters.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bitte wähle Teilnehmer aus.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Kampf starten (Demo)'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _addCombatant(Object data) {
    setState(() {
      if (data is PlayerCharacter && !_selectedPcs.contains(data)) {
        _selectedPcs.add(data as PlayerCharacter);
      } else if (data is Creature && !_selectedMonsters.contains(data)) {
        _selectedMonsters.add(data as Creature);
      }
    });
  }
  
  void _removeCombatant(Object data) {
    setState(() {
      final id = data is PlayerCharacter 
          ? (data as PlayerCharacter).id 
          : (data as Creature).id;
      _initiativeScores.remove(id);
      if (data is PlayerCharacter) {
        _selectedPcs.remove(data as PlayerCharacter);
      } else if (data is Creature) {
        _selectedMonsters.remove(data as Creature);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kampf zusammenstellen'),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_pcsFuture, _monstersFuture]),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final allPcs = (snapshot.data![0] as List).cast<PlayerCharacter>();
          final allMonsters = (snapshot.data![1] as List).cast<Creature>();
          
          final availablePcs = allPcs.where((pc) => !_selectedPcs.contains(pc)).toList();
          final availableMonsters = allMonsters.where((m) => !_selectedMonsters.contains(m)).toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      const Text('Verfügbar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const Divider(),
                      const Text('Helden', style: TextStyle(color: Colors.grey)),
                      Expanded(child: _buildDraggableList(availablePcs)),
                      const Divider(),
                      const Text('Gegner', style: TextStyle(color: Colors.grey)),
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
                        color: candidateData.isNotEmpty 
                              ? Colors.orange.withOpacity(0.2) 
                              : Colors.black.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('Im Kampf', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
          label: const Text('Kampf beginnen!'),
          onPressed: _startCombat,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableList(List<Object> items) {
    if (items.isEmpty) {
      return const Center(child: Text('Keine verfügbar', style: TextStyle(color: Colors.grey)));
    }
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
    if (items.isEmpty) {
      return const Center(child: Text('Hier Teilnehmer reinziehen', style: TextStyle(color: Colors.grey)));
    }
  
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final id = item is PlayerCharacter 
            ? item.id 
            : (item as Creature).id;
        final name = item is PlayerCharacter 
            ? (item as PlayerCharacter).name 
            : (item as Creature).name;
        final isPc = item is PlayerCharacter;
      
        // Demo: Keine echten Kampfberechnung
        final int bonus = 0;
        final String bonusString = bonus >= 0 ? '+$bonus' : bonus.toString();

        return ListTile(
          leading: Icon(isPc ? Icons.account_circle : Icons.shield),
          title: Text(name),
          trailing: SizedBox(
            width: 120,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Demo: Initiative-Eingabefeld ohne echte Logik
                Tooltip(
                  message: 'Automatischer Wurf: 1W20 $bonusString',
                  child: SizedBox(
                    width: 50,
                    child: TextField(
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(
                        hintText: 'Ini',
                        border: OutlineInputBorder(),
                      ),
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
                  tooltip: 'Entfernen',
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
