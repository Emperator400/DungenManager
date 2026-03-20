// lib/widgets/sound_scenes_tab.dart
import 'package:flutter/material.dart';
import '../models/sound_scene.dart';
import '../models/sound_scene_item.dart';
import '../models/sound.dart';
import '../services/sound_scene_service.dart';
import '../viewmodels/sound_library_viewmodel.dart';
import '../theme/dnd_theme.dart';

/// Sound Scenes Tab - Verwaltung von Klang-Szenen mit vollständiger Funktionalität
class SoundScenesTab extends StatefulWidget {
  const SoundScenesTab({super.key});

  @override
  State<SoundScenesTab> createState() => SoundScenesTabState();
}

class SoundScenesTabState extends State<SoundScenesTab> {
  final SoundSceneService _sceneService = SoundSceneService();
  List<SoundScene> _scenes = [];
  List<Sound> _availableSounds = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
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
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Neue Klang-Szene erstellen',
          style: DnDTheme.headline3.copyWith(color: DnDTheme.ancientGold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name der Szene *',
                labelStyle: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              ),
              autofocus: true,
            ),
            const SizedBox(height: DnDTheme.md),
            TextField(
              controller: descriptionController,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Beschreibung (optional)',
                labelStyle: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(color: DnDTheme.mysticalPurple),
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
              backgroundColor: DnDTheme.successGreen,
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
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              backgroundColor: DnDTheme.successGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fehler beim Erstellen der Szene',
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              backgroundColor: DnDTheme.errorRed,
            ),
          );
        }
      }
      _loadData();
    }
  }

  Future<void> _deleteScene(SoundScene scene) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Szene löschen?',
          style: DnDTheme.headline3.copyWith(color: DnDTheme.errorRed),
        ),
        content: Text(
          'Möchtest du die Klang-Szene "${scene.name}" wirklich endgültig löschen?',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.errorRed,
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
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              backgroundColor: DnDTheme.successGreen,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Fehler beim Löschen der Szene',
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              backgroundColor: DnDTheme.errorRed,
            ),
          );
        }
      }
      _loadData();
    }
  }

  Future<void> _editScene(SoundScene scene) async {
    final nameController = TextEditingController(text: scene.name);
    final descriptionController = TextEditingController(text: scene.description);

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Szene bearbeiten',
          style: DnDTheme.headline3.copyWith(color: DnDTheme.ancientGold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name der Szene *',
                labelStyle: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              ),
              autofocus: true,
            ),
            const SizedBox(height: DnDTheme.md),
            TextField(
              controller: descriptionController,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Beschreibung (optional)',
                labelStyle: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(color: DnDTheme.mysticalPurple),
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
              backgroundColor: DnDTheme.arcaneBlue,
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
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              backgroundColor: DnDTheme.successGreen,
            ),
          );
        }
      }
      _loadData();
    }
  }

  Future<void> _addSoundToScene(SoundScene scene) async {
    if (_availableSounds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Keine Sounds verfügbar. Bitte zuerst Sounds hinzufügen.',
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          ),
          backgroundColor: DnDTheme.warningOrange,
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
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          ),
          backgroundColor: DnDTheme.warningOrange,
        ),
      );
      return;
    }

    final selectedSound = await showDialog<Sound>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Sound hinzufügen',
          style: DnDTheme.headline3.copyWith(color: DnDTheme.ancientGold),
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
                  color: DnDTheme.arcaneBlue,
                ),
                title: Text(
                  sound.name,
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                ),
                subtitle: Text(
                  sound.soundTypeDisplayName,
                  style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
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
              style: DnDTheme.bodyText1.copyWith(color: DnDTheme.mysticalPurple),
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
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
            ),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
      _loadData();
    }
  }

  Future<void> _removeSoundFromScene(SoundScene scene, SoundSceneItem item) async {
    final success = await _sceneService.removeSoundFromScene(scene.id, item.soundId);
    
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sound aus Szene entfernt',
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          ),
          backgroundColor: DnDTheme.successGreen,
        ),
      );
    }
    _loadData();
  }

  Future<void> _playScene(SoundScene scene) async {
    if (!scene.hasSounds) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Diese Szene enthält keine Sounds.',
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          ),
          backgroundColor: DnDTheme.warningOrange,
        ),
      );
      return;
    }

    // TODO: Multi-Track Playback mit mehreren Sounds gleichzeitig implementieren
    // Aktuell wird nur eine Info angezeigt
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '🔊 Szene "${scene.name}" mit ${scene.soundCount} Sound(s) - Playback wird implementiert',
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          ),
          backgroundColor: DnDTheme.arcaneBlue,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: DnDTheme.ancientGold),
            const SizedBox(height: DnDTheme.md),
            Text(
              'Lade Szenen...',
              style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
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
            Icon(Icons.error_outline, color: DnDTheme.errorRed, size: 48),
            const SizedBox(height: DnDTheme.md),
            Text(
              'Fehler beim Laden',
              style: DnDTheme.headline3.copyWith(color: DnDTheme.errorRed),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              _error!,
              style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: DnDTheme.md),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.arcaneBlue,
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
            Icon(Icons.movie_filter, color: DnDTheme.mysticalPurple, size: 48),
            const SizedBox(height: DnDTheme.md),
            Text(
              'Keine Klang-Szenen erstellt',
              style: DnDTheme.headline3.copyWith(color: DnDTheme.mysticalPurple),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              'Erstelle deine erste Szene um Sounds zu bündeln',
              style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: DnDTheme.lg),
            ElevatedButton.icon(
              onPressed: _createNewScene,
              icon: const Icon(Icons.add),
              label: const Text('Szene erstellen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.successGreen,
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
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: scene.isFavorite 
              ? DnDTheme.ancientGold.withValues(alpha: 0.5)
              : DnDTheme.mysticalPurple.withValues(alpha: 0.3),
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.all(DnDTheme.md),
        childrenPadding: const EdgeInsets.fromLTRB(
          DnDTheme.md, 0, DnDTheme.md, DnDTheme.md,
        ),
        leading: Container(
          decoration: BoxDecoration(
            gradient: DnDTheme.getMysticalGradient(
              startColor: DnDTheme.arcaneBlue,
              endColor: DnDTheme.mysticalPurple,
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.movie_filter,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          scene.name,
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          '${scene.soundCount} Sound${scene.soundCount != 1 ? 's' : ''}',
          style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Play Button
            IconButton(
              icon: Icon(Icons.play_arrow, color: DnDTheme.successGreen),
              onPressed: () => _playScene(scene),
              tooltip: 'Szene abspielen',
            ),
            // Add Sound Button
            IconButton(
              icon: Icon(Icons.add, color: DnDTheme.arcaneBlue),
              onPressed: () => _addSoundToScene(scene),
              tooltip: 'Sound hinzufügen',
            ),
            // Menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: DnDTheme.stoneGrey,
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
                      Icon(Icons.edit, color: DnDTheme.arcaneBlue, size: 20),
                      const SizedBox(width: DnDTheme.sm),
                      Text(
                        'Bearbeiten',
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
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
                        color: DnDTheme.ancientGold,
                        size: 20,
                      ),
                      const SizedBox(width: DnDTheme.sm),
                      Text(
                        scene.isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten',
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: DnDTheme.errorRed, size: 20),
                      const SizedBox(width: DnDTheme.sm),
                      Text(
                        'Löschen',
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
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
                style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
              ),
            ),
          const Divider(color: DnDTheme.mysticalPurple),
          if (scene.items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(DnDTheme.md),
              child: Text(
                'Keine Sounds in dieser Szene',
                style: DnDTheme.bodyText2.copyWith(color: Colors.white54),
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
                  color: DnDTheme.arcaneBlue,
                  size: 20,
                ),
                title: Text(
                  sound.name,
                  style: DnDTheme.bodyText2.copyWith(color: Colors.white),
                ),
                subtitle: Text(
                  'Lautstärke: ${item.formattedVolume}',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(Icons.remove_circle_outline, 
                      color: DnDTheme.errorRed, size: 20),
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