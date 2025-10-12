// lib/screens/initiative_tracker_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import '../models/creature.dart';
import '../models/condition.dart';
import '../game_data/dnd_logic.dart';

class InitiativeTrackerScreen extends StatefulWidget {
  final List<Creature> creatures;
  const InitiativeTrackerScreen({super.key, required this.creatures});

  @override
  State<InitiativeTrackerScreen> createState() => _InitiativeTrackerScreenState();
}

class _InitiativeTrackerScreenState extends State<InitiativeTrackerScreen> {
  late List<Creature> _combatants;
  int _roundCounter = 1;
  int _currentTurnIndex = 0;

  @override
  void initState() {
    super.initState();
    _combatants = widget.creatures;
    _rollInitiative();
  }

  void _rollInitiative() {
    final random = Random();
    for (var creature in _combatants) {
      if (creature.initiative == null) {
        creature.initiative = random.nextInt(20) + 1 + creature.initiativeBonus;
      }
    }
    _combatants.sort((a, b) => b.initiative!.compareTo(a.initiative!));
  }

  void _nextTurn() {
    setState(() {
      if (_currentTurnIndex >= _combatants.length - 1) {
        _currentTurnIndex = 0;
        _roundCounter++;
      } else {
        _currentTurnIndex++;
      }
    });
  }

  void _changeHp(Creature creature, int amount) {
    setState(() {
      creature.currentHp += amount;
      if (creature.currentHp < 0) creature.currentHp = 0;
      if (creature.currentHp > creature.maxHp) creature.currentHp = creature.maxHp;
    });
  }

  void _showConditionsDialog(Creature creature) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text("Zustände für ${creature.name}"),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: Condition.values.length,
                itemBuilder: (context, index) {
                  final condition = Condition.values[index];
                  return CheckboxListTile(
                    title: Text(condition.toString().split('.').last),
                    value: creature.conditions.contains(condition),
                    onChanged: (bool? value) {
                      setDialogState(() {
                        if (value == true) {
                          creature.conditions.add(condition);
                        } else {
                          creature.conditions.remove(condition);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  setState(() {});
                  Navigator.of(context).pop();
                },
                child: const Text("Fertig"),
              )
            ],
          );
        },
      ),
    );
  }

  void _showContextMenu(BuildContext context, Creature creature, TapDownDetails details) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    showMenu(
      context: context,
      position: RelativeRect.fromRect(details.globalPosition & const Size(40, 40), Offset.zero & overlay.size),
      items: [
        const PopupMenuItem(value: 'damage', child: ListTile(leading: Icon(Icons.flash_on), title: Text("Schaden"))),
        const PopupMenuItem(value: 'heal', child: ListTile(leading: Icon(Icons.healing), title: Text("Heilung"))),
        const PopupMenuItem(value: 'condition', child: ListTile(leading: Icon(Icons.shield), title: Text("Zustand"))),
      ],
    ).then((value) {
      if (value == 'damage') _showDamageDialog(creature, isHealing: false);
      if (value == 'heal') _showDamageDialog(creature, isHealing: true);
      if (value == 'condition') _showConditionsDialog(creature);
    });
  }

  void _showDamageDialog(Creature creature, {required bool isHealing}) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isHealing ? "Heilung für ${creature.name}" : "Schaden für ${creature.name}"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: "Menge"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Abbrechen")),
          TextButton(
            onPressed: () {
              final amount = int.tryParse(controller.text) ?? 0;
              _changeHp(creature, isHealing ? amount : -amount);
              Navigator.of(context).pop();
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kampf-Tracker"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 20.0),
              child: Text("Runde: $_roundCounter", style: Theme.of(context).textTheme.titleLarge),
            ),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 80),
        itemCount: _combatants.length,
        itemBuilder: (ctx, index) {
          final creature = _combatants[index];
          final bool isActive = index == _currentTurnIndex;

          return GestureDetector(
            onLongPress: () => _showContextMenu(context, creature, TapDownDetails()), // Angepasst für Touch
            onSecondaryTapDown: (details) => _showContextMenu(context, creature, details), // Für Rechtsklick am PC
            child: Opacity(
              opacity: isActive ? 1.0 : 0.6,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: EdgeInsets.symmetric(horizontal: isActive ? 4 : 8, vertical: isActive ? 6 : 4),
                child: _buildCreatureExpansionTile(creature),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nextTurn,
        label: const Text("Zug beenden"),
        icon: const Icon(Icons.arrow_forward),
      ),
    );
  }

  Widget _buildCreatureExpansionTile(Creature creature) {
    final cardColor = creature.isPlayer ? Colors.blue.shade800 : Colors.red.shade900;
    final hpPercentage = creature.maxHp > 0 ? creature.currentHp / creature.maxHp : 0.0;

    return Card(
      color: cardColor,
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Row(children: [
          CircleAvatar(
            radius: 20,
            child: Text(creature.initiative.toString(), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(creature.name, style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold))),
        ]),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Column(
            children: [
              Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("HP: ${creature.currentHp} / ${creature.maxHp}", style: TextStyle(color: Colors.grey[300])),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: hpPercentage, backgroundColor: Colors.black45, minHeight: 6, borderRadius: BorderRadius.circular(3),
                    valueColor: AlwaysStoppedAnimation<Color>(hpPercentage > 0.5 ? Colors.green.shade400 : (hpPercentage > 0.2 ? Colors.amber.shade400 : Colors.red.shade700)),
                  ),
                ])),
                IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.white, size: 20), onPressed: () => _changeHp(creature, -1)),
                IconButton(icon: const Icon(Icons.add_circle_outline, color: Colors.white, size: 20), onPressed: () => _changeHp(creature, 1)),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: creature.conditions.isEmpty
                  ? Text("Keine Zustände", style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey[400]))
                  : Wrap(
                      spacing: 6.0, runSpacing: 4.0,
                      children: creature.conditions.map((c) => Chip(
                        visualDensity: VisualDensity.compact,
                        label: Text(c.toString().split('.').last, style: const TextStyle(fontSize: 12)),
                      )).toList(),
                    ),
                ),
                IconButton(icon: const Icon(Icons.add_box_outlined, color: Colors.white), onPressed: () => _showConditionsDialog(creature)),
              ]),
            ],
          ),
        ),
        children: [
          Container(
            color: Colors.black.withOpacity(0.2),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: creature.isPlayer ? _buildPlayerCheatsheet(creature) : _buildMonsterCheatsheet(creature),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayerCheatsheet(Creature creature) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ /* ... unverändert ... */ ]),
        const Divider(height: 24, color: Colors.white30),
        _buildAbilityRow("STR", creature.strength), _buildAbilityRow("DEX", creature.dexterity),
        _buildAbilityRow("CON", creature.constitution), _buildAbilityRow("INT", creature.intelligence),
        _buildAbilityRow("WIS", creature.wisdom), _buildAbilityRow("CHA", creature.charisma),
        
        // NEU: Die Inventar-Anzeige für den Spieler
        if (creature.inventory.isNotEmpty) ...[
          const Divider(height: 24, color: Colors.white30),
          const Text("Ausrüstung", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...creature.inventory.map((invItem) => Text(
            "• ${invItem.item.name} (x${invItem.inventoryItem.quantity}) ${invItem.item.damage != null ? '[${invItem.item.damage}]' : ''}",
            style: const TextStyle(color: Colors.white70)
          )).toList(),
        ]
      ],
    );
  }
  
  Widget _buildMonsterCheatsheet(Creature creature) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [ /* ... unverändert ... */ ]),
        const Divider(height: 24, color: Colors.white30),
        const Text("Angriffe & Aktionen", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SelectableText(creature.attacks, style: const TextStyle(color: Colors.white70)),

        // NEU: Die Inventar-Anzeige (Loot) für das Monster
        if (creature.inventory.isNotEmpty) ...[
          const Divider(height: 24, color: Colors.white30),
          const Text("Loot / Inventar", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...creature.inventory.map((invItem) => Text(
            "• ${invItem.item.name} (x${invItem.inventoryItem.quantity})",
            style: const TextStyle(color: Colors.white70)
          )).toList(),
        ]
      ],
    );
  }

  Widget _buildAbilityRow(String label, int score) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text("$label: $score ", style: TextStyle(color: Colors.grey[300])),
        Text("(${getModifierString(score)})", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ]),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Column(children: [
      Text(label, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
    ]);
  }
}