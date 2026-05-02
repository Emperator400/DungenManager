// lib/widgets/sound_scenes_tab.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sound_scene.dart';
import '../models/sound_scene_item.dart';
import '../models/sound.dart';
import '../services/multi_stream_sound_service.dart';
import '../services/sound_scene_service.dart';
import '../viewmodels/sound_library_viewmodel.dart';
import '../theme/dnd_theme.dart';
import '../theme/app_theme.dart';

/// Sound Scenes Tab - Verwaltung von Klang-Szenen mit vollständiger Funktionalität
class SoundScenesTab extends StatefulWidget {
  const SoundScenesTab({super.key});

  @override
  State<SoundScenesTab> createState() => SoundScenesTabState();
}

class SoundScenesTabState extends State<SoundScenesTab> {
  final SoundSceneService _sceneService = SoundSceneService();
  late MultiStreamSoundService _soundService;
  List<SoundScene> _scenes = [];
  List<Sound> _availableSounds = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _soundService = context.read<MultiStreamSoundService>();
  }

  /// Gibt zurück ob irgendein Sound dieser Szene gerade aktiv im Mixer ist
  bool _isScenePlaying(SoundScene scene) {
    final activeIds = _soundService.channels.map((c) => c.id).toSet();
    return scene.items.any((item) => activeIds.contains(item.soundId));
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Lade Szenen mit Items
      final scenes = await _sceneService.getAllSoundScenesWithItems();

      // Lade verfügbare Sounds über das ViewModel
      final viewModel = SoundLibraryViewModel();
      await viewModel.loadSounds();

      if (mounted) {
        setState(() {
          _scenes = scenes;
          _availableSounds = viewModel.sounds;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createNewScene() async {
    final C = context.appColors;
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          'Neue Klang-Szene erstellen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.amber),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name der Szene *',
                labelStyle: TextStyle(fontSize: 12, color: C.textMid),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: C.bgPanel.withValues(alpha: 0.3),
              ),
              autofocus: true,
            ),
            const SizedBox(height: DnDTheme.md),
            TextField(
              controller: descriptionController,
              style: TextStyle(fontSize: 14, color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Beschreibung (optional)',
                labelStyle: TextStyle(fontSize: 12, color: C.textMid),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: C.bgPanel.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(fontSize: 14, color: C.accent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.of(ctx).pop({
                  'name': nameController.text,
                  'description': descriptionController.text,
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );

    if (result != null) {
      final scene = SoundScene(
        name: result['name'] as String,
        description: result['description'] as String? ?? '',
      );

      final created = await _sceneService.createSoundScene(scene);

      if (mounted) {
        if (created != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Szene "${created.name}" erstellt',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: C.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fehler beim Erstellen der Szene',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: C.red,
            ),
          );
        }
      }
      _loadData();
    }
  }

  Future<void> _deleteScene(SoundScene scene) async {
    final C = context.appColors;
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          'Szene löschen?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.red),
        ),
        content: Text(
          'Möchtest du die Klang-Szene "${scene.name}" wirklich endgültig löschen?',
          style: TextStyle(fontSize: 14, color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Abbrechen',
              style: TextStyle(fontSize: 14, color: C.textMid),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: C.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _sceneService.deleteSoundScene(scene.id);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Szene "${scene.name}" gelöscht',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: C.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fehler beim Löschen der Szene',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: C.red,
            ),
          );
        }
      }
      _loadData();
    }
  }

  Future<void> _editScene(SoundScene scene) async {
    final C = context.appColors;
    final nameController = TextEditingController(text: scene.name);
    final descriptionController = TextEditingController(text: scene.description);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          'Szene bearbeiten',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.amber),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name der Szene *',
                labelStyle: TextStyle(fontSize: 12, color: C.textMid),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: C.bgPanel.withValues(alpha: 0.3),
              ),
              autofocus: true,
            ),
            const SizedBox(height: DnDTheme.md),
            TextField(
              controller: descriptionController,
              style: TextStyle(fontSize: 14, color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Beschreibung (optional)',
                labelStyle: TextStyle(fontSize: 12, color: C.textMid),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                filled: true,
                fillColor: C.bgPanel.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(fontSize: 14, color: C.accent),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                Navigator.of(ctx).pop({
                  'name': nameController.text,
                  'description': descriptionController.text,
                });
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.accent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );

    if (result != null) {
      final updatedScene = scene.copyWith(
        name: result['name'] as String,
        description: result['description'] as String? ?? '',
      );

      final success = await _sceneService.updateSoundScene(updatedScene);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Szene "${updatedScene.name}" aktualisiert',
                style: TextStyle(fontSize: 14, color: Colors.white),
              ),
              backgroundColor: C.green,
            ),
          );
        }
      }
      _loadData();
    }
  }

  Future<void> _addSoundToScene(SoundScene scene) async {
    final C = context.appColors;
    if (_availableSounds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Keine Sounds verfügbar. Bitte zuerst Sounds hinzufügen.',
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: C.amber,
        ),
      );
      return;
    }

    // Filtere Sounds, die noch nicht in der Szene sind
    final existingSoundIds = scene.items.map((item) => item.soundId).toSet();
    final availableToAdd = _availableSounds
        .where((sound) => !existingSoundIds.contains(sound.id))
        .toList();

    if (availableToAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Alle verfügbaren Sounds sind bereits in dieser Szene.',
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: C.amber,
        ),
      );
      return;
    }

    final selectedSound = await showDialog<Sound>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          'Sound hinzufügen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.amber),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: availableToAdd.length,
            itemBuilder: (context, index) {
              final sound = availableToAdd[index];
              return ListTile(
                leading: Icon(
                  sound.soundType == SoundType.Ambiente
                      ? Icons.waves
                      : Icons.volume_up,
                  color: C.accent,
                ),
                title: Text(
                  sound.name,
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                subtitle: Text(
                  sound.soundTypeDisplayName,
                  style: TextStyle(fontSize: 12, color: C.textMid),
                ),
                onTap: () => Navigator.of(ctx).pop(sound),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Abbrechen',
              style: TextStyle(fontSize: 14, color: C.accent),
            ),
          ),
        ],
      ),
    );

    if (selectedSound != null) {
      final item = await _sceneService.addSoundToScene(
        sceneId: scene.id,
        soundId: selectedSound.id,
        volume: 1.0,
        isLooping: true,
      );

      if (mounted && item != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sound "${selectedSound.name}" zur Szene hinzugefügt',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: C.green,
          ),
        );
      }
      _loadData();
    }
  }

  Future<void> _removeSoundFromScene(SoundScene scene, SoundSceneItem item) async {
    final C = context.appColors;
    final success = await _sceneService.removeSoundFromScene(scene.id, item.soundId);

    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sound aus Szene entfernt',
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
          backgroundColor: C.green,
        ),
      );
    }
    _loadData();
  }

  Future<void> _playScene(SoundScene scene) async {
    final C = context.appColors;
    if (!scene.hasSounds) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Diese Szene enthält keine Sounds.',
              style: TextStyle(fontSize: 14, color: Colors.white),
            ),
            backgroundColor: C.amber,
          ),
        );
      }
      return;
    }

    int startedCount = 0;

    for (final item in scene.items) {
      // Sound-Objekt anhand der ID aus der geladenen Liste holen
      final sound = _availableSounds.cast<Sound?>().firstWhere(
        (s) => s!.id == item.soundId,
        orElse: () => null,
      );

      if (sound == null) {
        debugPrint('⚠️ Sound ${item.soundId} nicht gefunden, übersprungen');
        continue;
      }

      // Wenn der Sound bereits läuft, überspringen
      if (_soundService.channels.any((c) => c.id == sound.id)) {
        continue;
      }

      final channelId = await _soundService.addSound(
        sound,
        volume: item.volume,
        isLooping: item.isLooping,
        autoPlay: true,
      );

      if (channelId != null) {
        startedCount++;
      } else {
        debugPrint('⚠️ Sound "${sound.name}" konnte nicht gestartet werden');
      }
    }

    if (mounted) {
      final message = startedCount > 0
          ? 'Szene "${scene.name}" gestartet ($startedCount Sound${startedCount != 1 ? 's' : ''})'
          : 'Szene konnte nicht gestartet werden';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: TextStyle(fontSize: 14, color: Colors.white),
          ),
          backgroundColor:
              startedCount > 0 ? C.green : C.red,
          duration: const Duration(seconds: 2),
        ),
      );
      setState(() {}); // Play-Button-Status aktualisieren
    }
  }

  Future<void> _stopScene(SoundScene scene) async {
    for (final item in scene.items) {
      await _soundService.removeSound(item.soundId);
    }
    if (mounted) {
      setState(() {}); // Play-Button-Status zurücksetzen
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: C.amber),
            const SizedBox(height: DnDTheme.md),
            Text(
              'Lade Szenen...',
              style: TextStyle(fontSize: 14, color: C.textMid),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: C.red, size: 48),
            const SizedBox(height: DnDTheme.md),
            Text(
              'Fehler beim Laden',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.red),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              _error!,
              style: TextStyle(fontSize: 12, color: C.textMid),
            ),
            const SizedBox(height: DnDTheme.md),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: C.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_scenes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.movie_filter, color: C.accent, size: 48),
            const SizedBox(height: DnDTheme.md),
            Text(
              'Keine Klang-Szenen erstellt',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.accent),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              'Erstelle deine erste Szene um Sounds zu bündeln',
              style: TextStyle(fontSize: 12, color: C.textMid),
            ),
            const SizedBox(height: DnDTheme.lg),
            ElevatedButton.icon(
              onPressed: _createNewScene,
              icon: const Icon(Icons.add),
              label: const Text('Szene erstellen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: C.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(DnDTheme.md),
      itemCount: _scenes.length,
      itemBuilder: (context, index) {
        final scene = _scenes[index];
        return _buildSceneCard(scene);
      },
    );
  }

  Widget _buildSceneCard(SoundScene scene) {
    return ListenableBuilder(
      listenable: _soundService,
      builder: (context, _) {
        final isPlaying = _isScenePlaying(scene);
        return _buildSceneCardContent(context, scene, isPlaying);
      },
    );
  }

  Widget _buildSceneCardContent(BuildContext context, SoundScene scene, bool isPlaying) {
    final C = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isPlaying
              ? C.green.withValues(alpha: 0.8)
              : scene.isFavorite
                  ? C.amber.withValues(alpha: 0.5)
                  : C.accent.withValues(alpha: 0.3),
          width: isPlaying ? 2.0 : 1.0,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(DnDTheme.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          DnDTheme.md, 0, DnDTheme.md, DnDTheme.md,
        ),
        leading: Container(
          decoration: BoxDecoration(
            color: C.bgPanel,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.movie_filter,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                scene.name,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (isPlaying) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: C.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: C.green.withValues(alpha: 0.6),
                  ),
                ),
                child: Text(
                  'LÄUFT',
                  style: TextStyle(
                    fontSize: 12,
                    color: C.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          '${scene.soundCount} Sound${scene.soundCount != 1 ? 's' : ''}',
          style: TextStyle(fontSize: 12, color: C.textMid),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play/Stop Toggle
            IconButton(
              icon: Icon(
                isPlaying ? Icons.stop_circle : Icons.play_circle,
                color: isPlaying ? C.red : C.green,
              ),
              onPressed: () =>
                  isPlaying ? _stopScene(scene) : _playScene(scene),
              tooltip: isPlaying ? 'Szene stoppen' : 'Szene abspielen',
            ),
            // Add Sound Button
            IconButton(
              icon: Icon(Icons.add, color: C.accent),
              onPressed: () => _addSoundToScene(scene),
              tooltip: 'Sound hinzufügen',
            ),
            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: C.bg,
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editScene(scene);
                    break;
                  case 'delete':
                    _deleteScene(scene);
                    break;
                  case 'favorite':
                    _sceneService.toggleFavorite(scene.id);
                    _loadData();
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: C.accent, size: 20),
                      const SizedBox(width: DnDTheme.sm),
                      Text(
                        'Bearbeiten',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'favorite',
                  child: Row(
                    children: [
                      Icon(
                        scene.isFavorite ? Icons.star : Icons.star_border,
                        color: C.amber,
                        size: 20,
                      ),
                      const SizedBox(width: DnDTheme.sm),
                      Text(
                        scene.isFavorite
                            ? 'Aus Favoriten entfernen'
                            : 'Zu Favoriten',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: C.red, size: 20),
                      const SizedBox(width: DnDTheme.sm),
                      Text(
                        'Löschen',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        children: [
          if (scene.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: DnDTheme.sm),
              child: Text(
                scene.description,
                style: TextStyle(fontSize: 12, color: C.textMid),
              ),
            ),
          Divider(color: C.accent),
          if (scene.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(DnDTheme.md),
              child: Text(
                'Keine Sounds in dieser Szene',
                style: TextStyle(fontSize: 12, color: C.textSoft),
              ),
            )
          else
            ...scene.items.map((item) {
              final sound = _availableSounds.firstWhere(
                (s) => s.id == item.soundId,
                orElse: () => Sound(
                  id: item.soundId,
                  name: 'Unbekannter Sound',
                  filePath: '',
                  soundType: SoundType.Ambiente,
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ),
              );

              return ListTile(
                dense: true,
                leading: Icon(
                  sound.soundType == SoundType.Ambiente
                      ? Icons.waves
                      : Icons.volume_up,
                  color: C.accent,
                  size: 20,
                ),
                title: Text(
                  sound.name,
                  style: TextStyle(fontSize: 12, color: Colors.white),
                ),
                subtitle: Text(
                  'Lautstärke: ${item.formattedVolume}',
                  style: TextStyle(
                    fontSize: 12,
                    color: C.textSoft,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle_outline,
                      color: C.red, size: 20),
                  onPressed: () => _removeSoundFromScene(scene, item),
                  tooltip: 'Aus Szene entfernen',
                ),
              );
            }),
        ],
      ),
    );
  }
}
