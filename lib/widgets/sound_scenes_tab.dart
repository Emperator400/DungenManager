// lib/widgets/sound_scenes_tab.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/sound_scene.dart';
import '../screens/edit_sound_scene_screen.dart';

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
      _scenesFuture = dbHelper.getAllSoundScenes();
    });
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
      await dbHelper.insertSoundScene(SoundScene(name: result['name'], type: result['type']));
      _loadScenes();
    }
  }

  // DIESE METHODE HATTE IN MEINER LETZTEN ANTWORT GEFEHLT
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
      // Wir verwenden die Methode, die die Szene UND ihre Verknüpfungen löscht
      await dbHelper.deleteSoundSceneAndLinks(scene.id); 
      _loadScenes();
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
                  await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => EditSoundSceneScreen(soundScene: scene)));
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