// lib/screens/add_sound_to_scene_screen.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../database/database_helper.dart';
import '../models/sound.dart';
import '../models/scene_sound_link.dart';
import '../viewmodels/sound_library_viewmodel.dart';

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
    return ChangeNotifierProvider<SoundLibraryViewModel>(
      create: (context) => SoundLibraryViewModel(),
      builder: (context, viewModel) {
        return FutureBuilder(
          future: dbHelper.getAllSounds(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (snapshot.hasError) {
                return Center(child: Text('Fehler: ${snapshot.error}'));
              }
              
              final sounds = snapshot.data as List<Sound>? ?? [];
              
              // Lade den aktuellen Zustand der scene_sound_links Tabelle
              return FutureBuilder(
                future: dbHelper.getAllSceneSoundLinks(),
                builder: (context, linksSnapshot) {
                  if (linksSnapshot.connectionState == ConnectionState.done) {
                    if (linksSnapshot.hasError) {
                      return Center(child: Text('Fehler: ${linksSnapshot.error}'));
                    }
                    
                    final links = linksSnapshot.data as List<Map<String, dynamic>>? ?? [];
                    
                    // Finde alle Links für diese Szene
                    final sceneLinks = links.where((link) => link['sceneId'] == widget.sceneId).toList();
                    
                    return Scaffold(
                      appBar: AppBar(
                        title: Text('Sound zur Szene hinzufügen'),
                        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      body: Column(
                        children: [
                          // Zeige existierende Sounds für diese Szene an
                          if (sceneLinks.isNotEmpty) ...[
                            Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[300]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bereits existierende Sounds:',
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 8),
                                  ...sceneLinks.map((link) {
                                    final sound = sounds.firstWhere((s) => s.id == link['soundId']);
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${sound.name}',
                                              style: Theme.of(context).textTheme.bodyMedium,
                                            ),
                                          ),
                                          Text(
                                              ' (Lautstärke: ${link['volume']})',
                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                color: Colors.grey[600],
                                              ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete),
                                            onPressed: () async {
                                              // Entferne den Sound-Link
                                              final linkId = link['id'] as String;
                                              await dbHelper.deleteSceneSoundLink(linkId);
                                              
                                              
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],
                          Expanded(
                            child: buildSoundSelectionSection(sounds),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return const Center(child: CircularProgressIndicator());
                  }
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        );
      },
    );
  }

  Widget buildSoundSelectionSection(List<Sound> sounds) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Sound aus Bibliothek wählen:',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        Expanded(
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: sounds.length,
            itemBuilder: (context, index) {
              final sound = sounds[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: InkWell(
                  onTap: () async {
                    // Füge den Sound zur Szene hinzu
                    final newLink = SceneSoundLink(
                      sceneId: widget.sceneId,
                      soundId: sound.id,
                      volume: 0.5, // Standard-Lautstärke
                    );
                    await dbHelper.insertSceneSoundLink(newLink.toMap());
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${sound.name} zur Szene hinzugefügt'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(
                          Icons.music_note,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sound.name,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                sound.soundType.toString().split('.').last,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.volume_up),
                          tooltip: "Vorschau",
                          onPressed: () => _previewSound(sound),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
