// lib/screens/add_quest_from_library_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/quest.dart';

class AddQuestFromLibraryScreen extends StatefulWidget {
  final String campaignId;
  const AddQuestFromLibraryScreen({super.key, required this.campaignId});

  @override
  State<AddQuestFromLibraryScreen> createState() => _AddQuestFromLibraryScreenState();
}

class _AddQuestFromLibraryScreenState extends State<AddQuestFromLibraryScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Quest>> _allQuestsFuture;
  late Future<List<Map<String, dynamic>>> _linkedQuestsFuture;
  
  final List<String> _selectedQuestIds = [];

  @override
  void initState() {
    super.initState();
    _allQuestsFuture = dbHelper.getAllQuests();
    _linkedQuestsFuture = dbHelper.getQuestLinksForCampaign(widget.campaignId);
  }

  void _addQuestsToCampaign() async {
    for (final questId in _selectedQuestIds) {
      await dbHelper.addQuestToCampaign(widget.campaignId, questId);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quests hinzufügen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: "Auswahl hinzufügen",
            onPressed: _addQuestsToCampaign,
          ),
        ],
      ),
      body: FutureBuilder(
        // Wir warten auf beide Abfragen
        future: Future.wait([_allQuestsFuture, _linkedQuestsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final allQuests = snapshot.data![0] as List<Quest>;
          final linkedQuests = snapshot.data![1] as List<Map<String, dynamic>>;
          final linkedQuestIds = linkedQuests.map((q) => q['questId'] as String).toSet();

          // Wir zeigen nur Quests an, die noch NICHT Teil der Kampagne sind
          final availableQuests = allQuests.where((q) => !linkedQuestIds.contains(q.id)).toList();

          if (availableQuests.isEmpty) {
            return const Center(child: Text("Alle verfügbaren Quests wurden bereits hinzugefügt."));
          }

          return ListView.builder(
            itemCount: availableQuests.length,
            itemBuilder: (context, index) {
              final quest = availableQuests[index];
              final isSelected = _selectedQuestIds.contains(quest.id);
              return CheckboxListTile(
                title: Text(quest.title),
                subtitle: Text(quest.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedQuestIds.add(quest.id);
                    } else {
                      _selectedQuestIds.remove(quest.id);
                    }
                  });
                },
              );
            },
          );
        },
      ),
    );
  }
}