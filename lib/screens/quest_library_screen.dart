// lib/screens/quest_library_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/quest.dart';
import 'edit_quest_screen.dart';

class QuestLibraryScreen extends StatefulWidget {
  const QuestLibraryScreen({super.key});

  @override
  State<QuestLibraryScreen> createState() => _QuestLibraryScreenState();
}

class _QuestLibraryScreenState extends State<QuestLibraryScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Quest>> _questsFuture;

  @override
  void initState() {
    super.initState();
    _questsFuture = dbHelper.getAllQuests();
  }

  void _refreshQuestList() {
    setState(() {
      _questsFuture = dbHelper.getAllQuests();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quest-Bibliothek"),
      ),
      body: FutureBuilder<List<Quest>>(
        future: _questsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Keine Quest-Vorlagen erstellt."));
          }
          final quests = snapshot.data!;
          return ListView.builder(
            itemCount: quests.length,
            itemBuilder: (context, index) {
              final quest = quests[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.flag, size: 40),
                  title: Text(quest.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(quest.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => EditQuestScreen(questToEdit: quest),
                    ));
                    _refreshQuestList();
                  },
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                    onPressed: () async {
                      await dbHelper.deleteQuest(quest.id);
                      _refreshQuestList();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Neue Quest-Vorlage erstellen",
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => const EditQuestScreen(),
          ));
          _refreshQuestList();
        },
      ),
    );
  }
}