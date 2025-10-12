// lib/screens/add_sound_to_scene_screen.dart
import 'package:flutter/material.dart';
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
                leading: Icon(sound.soundType == SoundType.Ambiente ? Icons.music_note : Icons.volume_up),
                title: Text(sound.name),
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