// lib/screens/link_quest_to_scene_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/quest.dart';

class LinkQuestToSceneScreen extends StatefulWidget {
  final List<String> previouslyLinkedIds;
  const LinkQuestToSceneScreen({super.key, required this.previouslyLinkedIds});

  @override
  State<LinkQuestToSceneScreen> createState() => _LinkQuestToSceneScreenState();
}

class _LinkQuestToSceneScreenState extends State<LinkQuestToSceneScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.previouslyLinkedIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quest verknüpfen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
          )
        ],
      ),
      body: FutureBuilder<List<Quest>>(
        future: dbHelper.getAllQuests(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final quests = snapshot.data!;
          return ListView.builder(
            itemCount: quests.length,
            itemBuilder: (context, index) {
              final quest = quests[index];
              return CheckboxListTile(
                title: Text(quest.title),
                value: _selectedIds.contains(quest.id),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIds.add(quest.id);
                    } else {
                      _selectedIds.remove(quest.id);
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