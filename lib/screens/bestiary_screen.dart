// lib/screens/bestiary_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/creature.dart';
// WICHTIG: Dieser Import hat wahrscheinlich gefehlt.
import 'edit_creature_screen.dart';

class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Creature>> _creaturesFuture;

  @override
  void initState() {
    super.initState();
    _creaturesFuture = dbHelper.getAllCreatures();
  }
  
  void _refreshCreatureList() {
    setState(() {
      _creaturesFuture = dbHelper.getAllCreatures();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bestiarium"),
      ),
      body: FutureBuilder<List<Creature>>(
        future: _creaturesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } 
          else if (snapshot.hasError) {
            return Center(child: Text("Fehler: ${snapshot.error}"));
          } 
          else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("Noch keine Kreaturen erstellt. Füge eine hinzu!"),
            );
          } 
          else {
            final creatures = snapshot.data!;
            return ListView.builder(
              itemCount: creatures.length,
              itemBuilder: (context, index) {
                final creature = creatures[index];
                return ListTile(
                  title: Text(creature.name),
                  subtitle: Text("Max HP: ${creature.maxHp}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () async {
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (ctx) => EditCreatureScreen(creatureToEdit: creature),
                          ));
                          _refreshCreatureList();
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () async {
                          await dbHelper.deleteCreature(creature.id);
                          _refreshCreatureList();
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => const EditCreatureScreen(),
          ));
          _refreshCreatureList();
        },
      ),
    );
  }
}