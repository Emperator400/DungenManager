// lib/widgets/sound_mixer_widget.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../database/database_helper.dart';
import '../models/sound.dart';

// Helfer-Klasse, um einen Player und seinen Zustand zu verwalten
class ActivePlayer {
  final AudioPlayer player;
  double volume;
  final Sound sound;

  ActivePlayer({required this.player, this.volume = 0.8, required this.sound});
}

class SoundMixerWidget extends StatefulWidget {
  const SoundMixerWidget({super.key});
  @override
  State<SoundMixerWidget> createState() => _SoundMixerWidgetState();
}

class _SoundMixerWidgetState extends State<SoundMixerWidget> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Sound>> _soundsFuture;

  // Wir speichern jetzt ALLE aktiven Player in einer einzigen Map
  final Map<String, ActivePlayer> _activePlayers = {};

  @override
  void initState() {
    super.initState();
    _soundsFuture = dbHelper.getAllSounds();
  }

  @override
  void dispose() {
    _stopAllSounds();
    super.dispose();
  }

  // NEUE METHODE: Stoppt absolut alles
  Future<void> _stopAllSounds() async {
    for (var activePlayer in _activePlayers.values) {
      await activePlayer.player.stop();
      await activePlayer.player.dispose();
    }
    // Wichtig: KEIN setState hier, da diese Methode aus dispose() aufgerufen werden kann
    _activePlayers.clear();
    // Wenn die Methode von einem Knopf aufgerufen wird, brauchen wir setState
    // Wir trennen das also auf.
  }
  
  // Eigene Methode für den UI-Knopf
  void _onStopAllSoundsPressed() {
    setState(() {
      _stopAllSounds();
    });
  }

  // Startet oder stoppt einen AMBIENTE-Sound
  Future<void> _toggleAmbience(Sound sound) async {
    final soundId = sound.id;
    if (_activePlayers.containsKey(soundId)) {
      final activePlayer = _activePlayers[soundId]!;
      await activePlayer.player.stop();
      await activePlayer.player.dispose();
      setState(() { _activePlayers.remove(soundId); });
    } else {
      final player = AudioPlayer();
      await player.setSource(DeviceFileSource(sound.filePath));
      await player.setVolume(0.8);
      await player.setReleaseMode(ReleaseMode.loop);
      await player.resume();
      setState(() {
        _activePlayers[soundId] = ActivePlayer(player: player, sound: sound);
      });
    }
  }

  // Spielt einen EFFEKT ab (und fügt ihn zur Liste hinzu)
  Future<void> _playEffect(Sound effect) async {
    final soundId = effect.id;
    // Wenn der Effekt schon läuft, starte ihn nicht nochmal
    if (_activePlayers.containsKey(soundId)) return;

    final player = AudioPlayer();
    await player.setSource(DeviceFileSource(effect.filePath));
    await player.setVolume(0.8);
    await player.resume();
    setState(() {
      _activePlayers[soundId] = ActivePlayer(player: player, sound: effect, volume: 1.0);
    });
    
    player.onPlayerComplete.listen((event) {
      setState(() {
        _activePlayers.remove(soundId);
      });
      player.dispose();
    });
  }

  // Stoppt einen einzelnen EFFEKT
  Future<void> _stopEffect(String soundId) async {
    if (_activePlayers.containsKey(soundId)) {
      final activePlayer = _activePlayers[soundId]!;
      await activePlayer.player.stop();
      await activePlayer.player.dispose();
      setState(() {
        _activePlayers.remove(soundId);
      });
    }
  }

  // Passt die Lautstärke eines beliebigen laufenden Sounds an
  void _setVolume(String soundId, double volume) {
    if (_activePlayers.containsKey(soundId)) {
      final activePlayer = _activePlayers[soundId]!;
      setState(() {
        activePlayer.volume = volume;
      });
      activePlayer.player.setVolume(volume);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: OutlinedButton.icon(
            icon: const Icon(Icons.stop, color: Colors.redAccent),
            label: const Text("Alle Sounds stoppen"),
            onPressed:  _onStopAllSoundsPressed,
            style: OutlinedButton.styleFrom(foregroundColor: Colors.redAccent, side: const BorderSide(color: Colors.redAccent)),
          ),
        ),
        const Divider(),
        Expanded(
          child: FutureBuilder<List<Sound>>(
            future: _soundsFuture,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final allSounds = snapshot.data!;
              if (allSounds.isEmpty) return const Center(child: Text("Keine Sounds in der Bibliothek.", style: TextStyle(color: Colors.grey)));

              final ambientSounds = allSounds.where((s) => s.soundType == SoundType.Ambiente).toList();
              final effectSounds = allSounds.where((s) => s.soundType == SoundType.Effekt).toList();

              return SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Ambiente & Musik", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    ...ambientSounds.map((sound) => _buildSoundChannel(sound)).toList(),
                    const Divider(height: 24),
                    const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text("Sound-Effekte", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    ),
                    ...effectSounds.map((sound) => _buildSoundChannel(sound)).toList(),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // EINZIGE, UNIVERSELLE METHODE ZUM BAUEN EINES SOUND-KANALS
  Widget _buildSoundChannel(Sound sound) {
    final activePlayer = _activePlayers[sound.id];
    final bool isPlaying = activePlayer != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        children: [
          // Play/Stop Knopf
          IconButton(
            icon: Icon(isPlaying ? Icons.stop : (sound.soundType == SoundType.Ambiente ? Icons.play_arrow : Icons.volume_up)),
            color: isPlaying ? Colors.green : Theme.of(context).iconTheme.color,
            onPressed: () {
              if (sound.soundType == SoundType.Ambiente) {
                _toggleAmbience(sound);
              } else {
                if (isPlaying) {
                  _stopEffect(sound.id);
                } else {
                  _playEffect(sound);
                }
              }
            },
          ),
          Expanded(flex: 2, child: Text(sound.name, overflow: TextOverflow.ellipsis)),
          Expanded(
            flex: 3,
            child: Slider(
              value: activePlayer?.volume ?? 0.0,
              onChanged: isPlaying ? (newVolume) => _setVolume(sound.id, newVolume) : null,
            ),
          ),
        ],
      ),
    );
  }
}