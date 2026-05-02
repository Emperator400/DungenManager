// lib/screens/audio/add_sound_screen.dart
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/sound_model_repository.dart';
import '../../models/sound.dart';
import '../../models/scene_sound_link.dart';
import '../../viewmodels/sound_library_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_components/states/loading_state_widget.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';

class AddSoundToSceneScreen extends StatefulWidget {
  const AddSoundToSceneScreen({super.key, required this.sceneId});

  final String sceneId;

  @override
  State<AddSoundToSceneScreen> createState() => _AddSoundToSceneScreenState();
}

class _AddSoundToSceneScreenState extends State<AddSoundToSceneScreen> {
  late SoundModelRepository _soundRepository;
  final AudioPlayer _previewPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _soundRepository = SoundModelRepository(DatabaseConnection.instance);
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  Future<List<SceneSoundLink>> _getAllSceneSoundLinks() async {
    final db = await DatabaseConnection.instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'scene_sound_links',
      where: 'scene_id = ?',
      whereArgs: [widget.sceneId],
    );
    return maps.map((map) => SceneSoundLink.fromMap(map)).toList();
  }

  Future<void> _insertSceneSoundLink(SceneSoundLink link) async {
    final db = await DatabaseConnection.instance.database;
    await db.insert('scene_sound_links', link.toMap());
  }

  Future<void> _deleteSceneSoundLink(String linkId) async {
    final db = await DatabaseConnection.instance.database;
    await db.delete('scene_sound_links', where: 'id = ?', whereArgs: [linkId]);
  }

  Future<void> _previewSound(Sound sound) async {
    await _previewPlayer.stop();
    await _previewPlayer.play(DeviceFileSource(sound.filePath));
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return ChangeNotifierProvider<SoundLibraryViewModel>(
      create: (context) => SoundLibraryViewModel(),
      builder: (context, viewModel) {
        return FutureBuilder(
          future: _soundRepository.findAll(),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const LoadingStateWidget();
            }
            if (snapshot.hasError) {
              return Center(child: Text('Fehler: ${snapshot.error}'));
            }
            final sounds = snapshot.data ?? [];
            return FutureBuilder(
              future: _getAllSceneSoundLinks(),
              builder: (context, linksSnapshot) {
                if (linksSnapshot.connectionState != ConnectionState.done) {
                  return const LoadingStateWidget();
                }
                if (linksSnapshot.hasError) {
                  return Center(child: Text('Fehler: ${linksSnapshot.error}'));
                }
                final sceneLinks = linksSnapshot.data ?? [];
                return Scaffold(
                  appBar: PreferredSize(
                    preferredSize: const Size.fromHeight(52),
                    child: Container(
                      decoration: BoxDecoration(
                        color: C.bgPanel,
                        border: Border(bottom: BorderSide(color: C.border)),
                      ),
                      child: SafeArea(
                        bottom: false,
                        child: SizedBox(
                          height: 52,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(children: [
                              GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: SizedBox(width: 30, height: 30, child: Icon(Icons.arrow_back, size: 18, color: C.textMid)),
                              ),
                              Container(width: 1, height: 18, color: C.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
                              Text('Sound zur Szene hinzufügen', style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13)),
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  body: Column(
                    children: [
                      if (sceneLinks.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.all(8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: C.bgHover,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: C.border),
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
                                final sound = sounds.firstWhere(
                                  (s) => s.id == link.soundId,
                                  orElse: () => sounds.first,
                                );
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          sound.name,
                                          style: Theme.of(context).textTheme.bodyMedium,
                                        ),
                                      ),
                                      Text(
                                        ' (Lautstärke: ${link.volume})',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: C.textSoft,
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete),
                                        onPressed: () async {
                                          await _deleteSceneSoundLink(link.id);
                                          setState(() {});
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      Expanded(child: _buildSoundSelectionSection(sounds)),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSoundSelectionSection(List<Sound> sounds) {
    final C = context.appColors;
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
            itemCount: sounds.length,
            itemBuilder: (context, index) {
              final sound = sounds[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: C.bgPanel,
                  border: Border.all(color: C.border),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () async {
                    final newLink = SceneSoundLink(
                      sceneId: widget.sceneId,
                      soundId: sound.id,
                      volume: 0.5,
                    );
                    await _insertSceneSoundLink(newLink);
                    setState(() {});
                    if (mounted) {
                      SnackBarHelper.showSuccess(context, '${sound.name} zur Szene hinzugefügt');
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.music_note, color: C.accent, size: 18),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(sound.name,
                                  style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 2),
                              Text(sound.soundType.toString().split('.').last,
                                  style: TextStyle(color: C.textSoft, fontSize: 11),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _previewSound(sound),
                          child: SizedBox(width: 30, height: 30, child: Icon(Icons.volume_up, size: 18, color: C.textMid)),
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
