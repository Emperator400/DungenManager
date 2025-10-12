// lib/widgets/sound_mixer_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../database/database_helper.dart';
import '../models/sound_scene.dart';
import '../models/scene_sound_link.dart';
import '../models/sound.dart';

class SoundMixerWidget extends StatefulWidget {
  const SoundMixerWidget({super.key});

  @override
  State<SoundMixerWidget> createState() => _SoundMixerWidgetState();
}

class _SoundMixerWidgetState extends State<SoundMixerWidget> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<SoundScene>> _scenesFuture;
  
  // Wir verwalten eine Liste von aktiven Audio-Playern
  final Map<String, AudioPlayer> _activePlayers = {};

  @override
  void initState() {
    super.initState();
    _scenesFuture = dbHelper.getAllSoundScenes();
  }

  @override
  void dispose() {
    // Stoppe und entsorge alle Player, wenn der Bildschirm verlassen wird
    for (var player in _activePlayers.values) {
      player.stop();
      player.dispose();
    }
    super.dispose();
  }

  Future<void> _toggleScene(SoundScene scene) async {
    final sceneId = scene.id;

    // Wenn die Szene bereits aktiv ist, stoppe sie
    if (_activePlayers.containsKey(sceneId)) {
      final player = _activePlayers[sceneId];
      await player?.stop();
      setState(() {
        _activePlayers.remove(sceneId);
      });
      return;
    }

    // Ansonsten, starte die Szene
    final links = await dbHelper.getLinksForScene(sceneId);
    for (final link in links) {
      final sound = await dbHelper.getSoundById(link.soundId);
      if (sound != null && sound.soundType == SoundType.Ambiente) {
        final player = AudioPlayer();
        await player.setSource(DeviceFileSource(sound.filePath));
        await player.setVolume(link.volume);
        await player.setReleaseMode(ReleaseMode.loop); // Ambiente-Sounds loopen
        await player.resume();
        setState(() {
          _activePlayers[sceneId] = player;
        });
        // Da wir nur einen Ambiente-Sound pro Szene haben wollen (vereinfacht), brechen wir hier ab
        break; 
      }
    }
  }

  Future<void> _playEffect(SceneSoundLink link) async {
    final sound = await dbHelper.getSoundById(link.soundId);
    if (sound != null) {
      final player = AudioPlayer();
      await player.setSource(DeviceFileSource(sound.filePath));
      await player.setVolume(link.volume);
      await player.resume();
      // Der Player wird automatisch entsorgt, nachdem der Effekt abgespielt wurde
      player.onPlayerComplete.listen((event) {
        player.dispose();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<SoundScene>>(
      future: _scenesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final scenes = snapshot.data!;
        if (scenes.isEmpty) return const Center(child: Text("Keine Klang-Szenen erstellt."));
        
        return ListView.builder(
          itemCount: scenes.length,
          itemBuilder: (context, index) {
            final scene = scenes[index];
            final bool isPlaying = _activePlayers.containsKey(scene.id);

            return Card(
              color: isPlaying ? Colors.green.withOpacity(0.3) : null,
              child: ListTile(
                leading: IconButton(
                  icon: Icon(isPlaying ? Icons.stop_circle_outlined : Icons.play_circle_outline),
                  onPressed: () => _toggleScene(scene),
                  iconSize: 30,
                ),
                title: Text(scene.name),
                // Hier könnten wir die Effekt-Knöpfe anzeigen
              ),
            );
          },
        );
      },
    );
  }
}