// lib/screens/lore_keeper_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/wiki_entry.dart';
import 'edit_wiki_entry_screen.dart';

class LoreKeeperScreen extends StatefulWidget {
  const LoreKeeperScreen({super.key});

  @override
  State<LoreKeeperScreen> createState() => _LoreKeeperScreenState();
}

class _LoreKeeperScreenState extends State<LoreKeeperScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<WikiEntry>> _entriesFuture;

  @override
  void initState() {
    super.initState();
    _entriesFuture = dbHelper.getAllWikiEntries();
  }

  void _refreshEntriesList() {
    setState(() {
      _entriesFuture = dbHelper.getAllWikiEntries();
    });
  }

  // KORRIGIERTE METHODE: Der 'Item'-Fall wurde entfernt und die Logik vereinfacht.
  IconData _getIconForType(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return Icons.person; // 'Person' im Wiki ist immer ein NPC
      case WikiEntryType.Place:
        return Icons.location_on;
      case WikiEntryType.Lore:
        return Icons.menu_book;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Lore Keeper")),
      body: FutureBuilder<List<WikiEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Dein Wiki ist noch leer."));
          }
          final entries = snapshot.data!;
          entries.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: Icon(_getIconForType(entry.entryType)),
                title: Text(entry.title),
                subtitle: Text(
                  // 'Person' wird jetzt immer als 'NPC' angezeigt
                  entry.entryType == WikiEntryType.Person
                      ? 'NPC'
                      : entry.entryType.toString().split('.').last,
                ),
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(
                    builder: (ctx) => EditWikiEntryScreen(entryToEdit: entry),
                  ));
                  _refreshEntriesList();
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    await dbHelper.deleteWikiEntry(entry.id);
                    _refreshEntriesList();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => const EditWikiEntryScreen(),
          ));
          _refreshEntriesList();
        },
      ),
    );
  }
}