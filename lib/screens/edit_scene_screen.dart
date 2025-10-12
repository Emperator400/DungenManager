// lib/screens/edit_scene_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/scene.dart';
import '../models/wiki_entry.dart';
import '../models/quest.dart';
import 'link_entry_to_scene_screen.dart';
import 'link_quest_to_scene_screen.dart';

class EditSceneScreen extends StatefulWidget {
  final Scene scene;
  const EditSceneScreen({super.key, required this.scene});

  @override
  State<EditSceneScreen> createState() => _EditSceneScreenState();
}

class _EditSceneScreenState extends State<EditSceneScreen> {
  final dbHelper = DatabaseHelper.instance;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  // Wir speichern die verknüpften IDs im State, um sie bearbeiten zu können
  late List<String> _linkedWikiEntryIds;
  late List<String> _linkedQuestIds;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.scene.title);
    _descriptionController = TextEditingController(text: widget.scene.description);
    _linkedWikiEntryIds = List.from(widget.scene.linkedWikiEntryIds);
    _linkedQuestIds = List.from(widget.scene.linkedQuestIds);
  }

  void _saveScene() async {
    widget.scene.title = _titleController.text;
    widget.scene.description = _descriptionController.text;
    widget.scene.linkedWikiEntryIds = _linkedWikiEntryIds;
    widget.scene.linkedQuestIds = _linkedQuestIds;
    await dbHelper.updateScene(widget.scene);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.scene.title),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveScene)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _titleController, decoration: const InputDecoration(labelText: "Szenen-Titel")),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: _descriptionController,
                maxLines: null, expands: true, textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: "Beschreibung & Notizen",
                  border: OutlineInputBorder(),
                  hintText: "Nutze > am Zeilenanfang für Dialoge...",
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Divider(),
            _buildLinksSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildLinksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text("NPC/Ort"),
              onPressed: () async {
                final selectedIds = await Navigator.of(context).push<List<String>>(
                  MaterialPageRoute(builder: (ctx) => LinkEntryToSceneScreen(previouslyLinkedIds: _linkedWikiEntryIds)),
                );
                if (selectedIds != null) {
                  setState(() { _linkedWikiEntryIds = selectedIds; });
                }
              },
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.flag),
              label: const Text("Quest"),
              onPressed: () async {
                final selectedIds = await Navigator.of(context).push<List<String>>(
                  MaterialPageRoute(builder: (ctx) => LinkQuestToSceneScreen(previouslyLinkedIds: _linkedQuestIds)),
                );
                if (selectedIds != null) {
                  setState(() { _linkedQuestIds = selectedIds; });
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Hier zeigen wir die Chips an
        FutureBuilder(
          future: Future.wait([
            dbHelper.getWikiEntriesByIds(_linkedWikiEntryIds),
            dbHelper.getQuestsByIds(_linkedQuestIds), // Diese Methode müssen wir noch im Helper erstellen!
          ]),
          builder: (context, AsyncSnapshot<List<List>> snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final wikiEntries = snapshot.data![0] as List<WikiEntry>;
            final quests = snapshot.data![1] as List<Quest>;
            return Wrap(
              spacing: 8.0,
              children: [
                ...wikiEntries.map((e) => Chip(label: Text(e.title), avatar: const Icon(Icons.person))),
                ...quests.map((q) => Chip(label: Text(q.title), avatar: const Icon(Icons.flag))),
              ],
            );
          },
        ),
      ],
    );
  }
}