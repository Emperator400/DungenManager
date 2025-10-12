// lib/screens/edit_sound_scene_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/sound_scene.dart';
import '../models/scene_sound_link.dart';
import 'add_sound_to_scene_screen.dart';
import '../models/sound.dart';

class EditSoundSceneScreen extends StatefulWidget {
  final SoundScene soundScene;
  const EditSoundSceneScreen({super.key, required this.soundScene});

  @override
  State<EditSoundSceneScreen> createState() => _EditSoundSceneScreenState();
}

class _EditSoundSceneScreenState extends State<EditSoundSceneScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<DisplaySceneSound>> _soundsFuture;

  @override
  void initState() {
    super.initState();
    _loadSounds();
  }

  void _loadSounds() {
    setState(() {
      _soundsFuture = dbHelper.getDisplaySoundsForScene(widget.soundScene.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Szene: ${widget.soundScene.name}")),
      body: FutureBuilder<List<DisplaySceneSound>>(
        future: _soundsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final displaySounds = snapshot.data!;

          return ListView.builder(
            itemCount: displaySounds.length,
            itemBuilder: (context, index) {
              final displaySound = displaySounds[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(displaySound.sound.soundType == SoundType.Ambiente ? Icons.music_note : Icons.volume_up),
                  title: Text(displaySound.sound.name),
                  subtitle: Slider(
                    value: displaySound.link.volume,
                    onChanged: (newVolume) {
                      setState(() {
                        displaySound.link.volume = newVolume;
                        // Optional: Hier könnte man eine Debounce-Logik zum automatischen Speichern einbauen
                      });
                    },
                    onChangeEnd: (finalVolume) {
                      // Speichere die finale Lautstärke in der DB
                      dbHelper.updateSceneSoundLink(displaySound.link);
                    },
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.redAccent),
                    onPressed: () async {
                      await dbHelper.deleteSceneSoundLink(displaySound.link.id);
                      _loadSounds();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Sound zu dieser Szene hinzufügen",
        child: const Icon(Icons.playlist_add),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => AddSoundToSceneScreen(sceneId: widget.soundScene.id),
          ));
          _loadSounds();
        },
      ),
    );
  }
}