// lib/screens/link_wiki_entries_screen.dart
import 'package:flutter/material.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/wiki_entry_model_repository.dart';
import '../models/wiki_entry.dart';

class LinkWikiEntriesScreen extends StatefulWidget {
  final List<String> previouslyLinkedIds;
  const LinkWikiEntriesScreen({super.key, required this.previouslyLinkedIds});

  @override
  State<LinkWikiEntriesScreen> createState() => _LinkWikiEntriesScreenState();
}

class _LinkWikiEntriesScreenState extends State<LinkWikiEntriesScreen> {
  late WikiEntryModelRepository _wikiRepository;
  late Future<List<WikiEntry>> _entriesFuture;
  late final List<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _wikiRepository = WikiEntryModelRepository(DatabaseConnection.instance);
    _entriesFuture = _wikiRepository.findAll();
    _selectedIds = List.from(widget.previouslyLinkedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Einträge verknüpfen"),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () {
              Navigator.of(context).pop(_selectedIds);
            },
          )
        ],
      ),
      body: FutureBuilder<List<WikiEntry>>(
        future: _entriesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final allEntries = snapshot.data!;
          if (allEntries.isEmpty) {
            return const Center(child: Text("Keine Wiki-Einträge zum Verknüpfen vorhanden."));
          }
          
          allEntries.sort((a,b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));

          return ListView.builder(
            itemCount: allEntries.length,
            itemBuilder: (context, index) {
              final entry = allEntries[index];
              return CheckboxListTile(
                title: Text(entry.title),
                subtitle: Text(entry.entryType.toString().split('.').last),
                value: _selectedIds.contains(entry.id),
                onChanged: (bool? value) {
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
