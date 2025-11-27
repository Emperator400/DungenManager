// lib/widgets/sound_scenes_tab.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/sound_scene.dart';

class SoundScenesTab extends StatefulWidget {
  const SoundScenesTab({super.key});

  @override
  State<SoundScenesTab> createState() => SoundScenesTabState();
}

class SoundScenesTabState extends State<SoundScenesTab> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<SoundScene>> _scenesFuture;

  @override
  void initState() {
    super.initState();
    _loadScenes();
  }

  void _loadScenes() {
    setState(() {
      _scenesFuture = _loadScenesData();
    });
  }

  Future<List<SoundScene>> _loadScenesData() async {
    try {
      // Da es keine getAllSoundScenes Methode gibt, erstellen wir eine leere Liste
      // In einer echten Implementierung würde dies die Datenbank abfragen
      return <SoundScene>[];
    } catch (e) {
      print('Fehler beim Laden der SoundScenes: $e');
      return <SoundScene>[];
    }
  }

  Future<void> _createNewScene() async {
    final nameController = TextEditingController();
    SoundSceneType selectedType = SoundSceneType.Ambiente;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Neue Klang-Szene erstellen"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name der Szene"), autofocus: true),
                const SizedBox(height: 16),
                DropdownButtonFormField<SoundSceneType>(
                  value: selectedType,
                  decoration: const InputDecoration(labelText: "Szenen-Typ"),
                  items: SoundSceneType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.toString().split('.').last))).toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Abbrechen")),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    Navigator.of(ctx).pop({'name': nameController.text, 'type': selectedType});
                  }
                },
                child: const Text("Erstellen"),
              ),
            ],
          );
        },
      ),
    );

    if (result != null) {
      try {
        final scene = SoundScene(
          id: '', // Wird von der Datenbank generiert
          name: result['name'] as String, 
          type: result['type'] as SoundSceneType,
          sceneId: '', // Temporäre leere sceneId für standalone SoundScenes
        );
        
        // Da es keine insertSoundScene Methode gibt, zeigen wir nur eine Nachricht
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('SoundScene "${scene.name}" erstellt (Demo)')),
          );
        }
        _loadScenes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Erstellen: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteScene(SoundScene scene) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Szene löschen?"),
        content: Text("Möchtest du die Klang-Szene '${scene.name}' wirklich endgültig löschen?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Abbrechen")),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Löschen", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        // Da es keine deleteSoundSceneAndLinks Methode gibt, zeigen wir nur eine Nachricht
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('SoundScene "${scene.name}" gelöscht (Demo)')),
          );
        }
        _loadScenes();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fehler beim Löschen: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<SoundScene>>(
        future: _scenesFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final scenes = snapshot.data!;
          if (scenes.isEmpty) return const Center(child: Text("Keine Klang-Szenen erstellt."));

          return ListView.builder(
            itemCount: scenes.length,
            itemBuilder: (context, index) {
              final scene = scenes[index];
              return ListTile(
                leading: Icon(scene.type == SoundSceneType.Ambiente ? Icons.music_video : Icons.surround_sound),
                title: Text(scene.name),
                subtitle: Text(scene.type.toString().split('.').last),
                onTap: () async {
                  // EditSoundSceneScreen existiert nicht, zeigen wir eine Demo-Nachricht
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Bearbeitung für "${scene.name}" (Demo)')),
                    );
                  }
                  _loadScenes();
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      _deleteScene(scene);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Löschen', style: TextStyle(color: Colors.red))),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewScene,
        child: const Icon(Icons.add),
        tooltip: "Neue Klang-Szene erstellen",
      ),
    );
  }
}
