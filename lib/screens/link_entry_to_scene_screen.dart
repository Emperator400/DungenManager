// lib/screens/link_entry_to_scene_screen.dart
import 'package:flutter/material.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../models/wiki_entry.dart';

class LinkEntryToSceneScreen extends StatefulWidget {
  final List<String> previouslyLinkedIds;
  const LinkEntryToSceneScreen({super.key, required this.previouslyLinkedIds});

  @override
  State<LinkEntryToSceneScreen> createState() => _LinkEntryToSceneScreenState();
}

class _LinkEntryToSceneScreenState extends State<LinkEntryToSceneScreen> {
  late WikiEntryModelRepository _wikiRepository;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _wikiRepository = WikiEntryModelRepository(DatabaseConnection.instance);
    _selectedIds = widget.previouslyLinkedIds.toSet();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("NPC/Ort verknüpfen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () => Navigator.of(context).pop(_selectedIds.toList()),
          )
        ],
      ),
      body: FutureBuilder<List<WikiEntry>>(
        future: _wikiRepository.findAll(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final entries = snapshot.data!;
          return ListView.builder(
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              return CheckboxListTile(
                title: Text(entry.title),
                subtitle: Text(entry.entryType.toString().split('.').last),
                value: _selectedIds.contains(entry.id),
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIds.add(entry.id);
                    } else {
                      _selectedIds.remove(entry.id);
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
