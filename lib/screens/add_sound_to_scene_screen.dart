// lib/screens/add_sound_to_scene_screen.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../database/database_helper.dart';
import '../models/sound.dart';
import '../models/scene_sound_link.dart';

class AddSoundToSceneScreen extends StatefulWidget {
  final String sceneId;
  const AddSoundToSceneScreen({super.key, required this.sceneId});

  @override
  State<AddSoundToSceneScreen> createState() => _AddSoundToSceneScreenState();
}

class _AddSoundToSceneScreenState extends State<AddSoundToSceneScreen> {
  final dbHelper = DatabaseHelper.instance;
  final AudioPlayer _previewPlayer = AudioPlayer();

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<void> _previewSound(Sound sound) async {
    await _previewPlayer.stop();
    await _previewPlayer.play(DeviceFileSource(sound.filePath));
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sound aus Bibliothek wählen")),
      body: FutureBuilder<List<Sound>>(
        future: dbHelper.getAllSounds(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final sounds = snapshot.data!;
          return ListView.builder(
            itemCount: sounds.length,
            itemBuilder: (context, index) {
              final sound = sounds[index];
              return ListTile(
                leading: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: "Vorschau",
                  onPressed: () => _previewSound(sound),
                ),
                title: Text(sound.name),
                subtitle: Text(sound.soundType.toString().split('.').last),
                // Ein Klick auf die Kachel fügt den Sound hinzu
                onTap: () async {
                  final newLink = SceneSoundLink(sceneId: widget.sceneId, soundId: sound.id);
                  await dbHelper.insertSceneSoundLink(newLink);
                  if (mounted) Navigator.of(context).pop();
                },
              );
            },
          );
        },
      ),
    );
  }
}