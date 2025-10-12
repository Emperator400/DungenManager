// lib/widgets/sound_scenes_tab.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/sound_scene.dart';
import '../screens/edit_sound_scene_screen.dart';

class SoundScenesTab extends StatefulWidget {
  const SoundScenesTab({super.key});

  @override
  State<SoundScenesTab> createState() => _SoundScenesTabState();
}

class _SoundScenesTabState extends State<SoundScenesTab> {
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
    final String? sceneName = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Neue Klang-Szene erstellen"),
        content: TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name der Szene"), autofocus: true),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Abbrechen")),
          ElevatedButton(onPressed: () => Navigator.of(ctx).pop(nameController.text), child: const Text("Erstellen")),
        ],
      ),
    );

    if (sceneName != null && sceneName.isNotEmpty) {
      await dbHelper.insertSoundScene(SoundScene(name: sceneName));
      _loadScenes();
    }
  }

  // NEUE METHODE: Zeigt den Bestätigungs-Dialog und löscht die Szene
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
                leading: const Icon(Icons.movie_filter),
                title: Text(scene.name),
                // Ein Klick auf die Kachel öffnet den Editor
                onTap: () async {
                  await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => EditSoundSceneScreen(soundScene: scene)));
                  _loadScenes();
                },
                // Das Trailing ist jetzt ein Pop-up-Menü für mehr Aktionen
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