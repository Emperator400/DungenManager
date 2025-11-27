import 'package:flutter/material.dart';
import '../../viewmodels/sound_mixer_viewmodel.dart';
import '../../models/sound.dart';

/// Enhanced Sound Mixer Widget mit modernem Design und ViewModel-Integration
class EnhancedSoundMixerWidget extends StatefulWidget {
  const EnhancedSoundMixerWidget({super.key});

  @override
  State<EnhancedSoundMixerWidget> createState() => _EnhancedSoundMixerWidgetState();
}

class _EnhancedSoundMixerWidgetState extends State<EnhancedSoundMixerWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  late SoundMixerViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _viewModel = SoundMixerViewModel();
    
    // Daten laden
    _viewModel.loadSounds();
    
    // Search listener
    _searchController.addListener(() {
      _viewModel.searchSounds(_searchController.text);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildSearchAndFilters(context),
        _buildActiveSoundsBar(context),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllSoundsTab(),
              _buildAmbientSoundsTab(),
              _buildEffectSoundsTab(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Sound Mixer',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _viewModel,
            builder: (context, child) {
              return Row(
                children: [
                  if (_viewModel.activeAmbientCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_viewModel.activeAmbientCount} Ambiente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (_viewModel.activeEffectCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_viewModel.activeEffectCount} Effekte',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  IconButton(
                    onPressed: _viewModel.stopAllSounds,
                    icon: const Icon(Icons.stop_circle, color: Colors.red),
                    tooltip: 'Alle Sounds stoppen',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.background,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: Column(
            children: [
              // Search Bar
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Sounds durchsuchen...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _viewModel.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _viewModel.searchSounds('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                ),
              ),
              const SizedBox(height: 12),
              
              // Filter Chips
              Row(
                children: [
                  FilterChip(
                    label: const Text('Alle'),
                    selected: _viewModel.selectedType == null,
                    onSelected: (selected) => _viewModel.setTypeFilter(null),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Ambiente'),
                    selected: _viewModel.selectedType == SoundType.Ambiente,
                    onSelected: (selected) => _viewModel.setTypeFilter(
                      selected ? SoundType.Ambiente : null,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor: Colors.green.withOpacity(0.2),
                    checkmarkColor: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: const Text('Effekte'),
                    selected: _viewModel.selectedType == SoundType.Effekt,
                    onSelected: (selected) => _viewModel.setTypeFilter(
                      selected ? SoundType.Effekt : null,
                    ),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor: Colors.blue.withOpacity(0.2),
                    checkmarkColor: Colors.blue,
                  ),
                  const Spacer(),
                  FilterChip(
                    label: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.favorite, size: 16),
                        const SizedBox(width: 4),
                        const Text('Favorites'),
                      ],
                    ),
                    selected: _viewModel.showFavoritesOnly,
                    onSelected: (_) => _viewModel.toggleFavoritesFilter(),
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    selectedColor: Colors.red.withOpacity(0.2),
                    checkmarkColor: Colors.red,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveSoundsBar(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        if (_viewModel.activePlayers.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _viewModel.activePlayers.length,
            itemBuilder: (context, index) {
              final activePlayer = _viewModel.activePlayers[index];
              return _buildActiveSoundChip(context, activePlayer);
            },
          ),
        );
      },
    );
  }

  Widget _buildActiveSoundChip(BuildContext context, ActiveSoundPlayer activePlayer) {
    final sound = activePlayer.sound;
    final isActive = _viewModel.isSoundActive(sound.id);

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isActive 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
            : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            sound.soundType == SoundType.Ambiente 
                ? Icons.waves 
                : Icons.flash_on,
            size: 16,
            color: isActive 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
          const SizedBox(width: 8),
          Text(
            sound.name,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isActive 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 80,
            child: Slider(
              value: activePlayer.volume,
              onChanged: (value) => _viewModel.setVolume(sound.id, value),
              min: 0.0,
              max: 1.0,
              activeColor: Theme.of(context).colorScheme.primary,
              inactiveColor: Theme.of(context).dividerColor,
            ),
          ),
          IconButton(
            onPressed: () => _viewModel.stopSound(sound.id),
            icon: const Icon(Icons.stop, size: 16),
            tooltip: 'Stoppen',
            constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildAllSoundsTab() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return _buildSoundList(context, _viewModel.sounds);
      },
    );
  }

  Widget _buildAmbientSoundsTab() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return _buildSoundList(context, _viewModel.ambientSounds);
      },
    );
  }

  Widget _buildEffectSoundsTab() {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return _buildSoundList(context, _viewModel.effectSounds);
      },
    );
  }

  Widget _buildSoundList(BuildContext context, List<Sound> sounds) {
    if (_viewModel.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_viewModel.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden der Sounds',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _viewModel.error!,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _viewModel.refresh(),
              child: const Text('Erneut versuchen'),
            ),
          ],
        ),
      );
    }

    if (sounds.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.music_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Sounds gefunden',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
            if (_viewModel.searchQuery.isNotEmpty || _viewModel.selectedType != null) ...[
              const SizedBox(height: 8),
              Text(
                'Versuche es mit anderen Filtern',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () {
                  _viewModel.clearAllFilters();
                  _searchController.clear();
                },
                child: const Text('Filter löschen'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sounds.length,
      itemBuilder: (context, index) {
        final sound = sounds[index];
        return _buildSoundTile(context, sound);
      },
    );
  }

  Widget _buildSoundTile(BuildContext context, Sound sound) {
    final isActive = _viewModel.isSoundActive(sound.id);
    final activePlayer = _viewModel.getActivePlayer(sound.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isActive ? 4 : 1,
      child: InkWell(
        onTap: () {
          if (sound.soundType == SoundType.Ambiente) {
            _viewModel.toggleAmbience(sound);
          } else {
            if (isActive) {
              _viewModel.stopSound(sound.id);
            } else {
              _viewModel.playEffect(sound);
            }
          }
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Sound Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (sound.soundType == SoundType.Ambiente 
                          ? Colors.green 
                          : Colors.blue)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  sound.soundType == SoundType.Ambiente 
                      ? Icons.waves 
                      : Icons.flash_on,
                  color: sound.soundType == SoundType.Ambiente 
                      ? Colors.green 
                      : Colors.blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              
              // Sound Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sound.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isActive 
                            ? Theme.of(context).colorScheme.primary 
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      sound.description.isNotEmpty 
                          ? sound.description 
                          : 'Keine Beschreibung',
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (sound.duration != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Dauer: ${sound.formattedDuration}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Actions
              Row(
                children: [
                  if (sound.isFavorite)
                    Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 20,
                    ),
                  if (isActive && activePlayer != null) ...[
                    SizedBox(
                      width: 100,
                      child: Slider(
                        value: activePlayer.volume,
                        onChanged: (value) => _viewModel.setVolume(sound.id, value),
                        min: 0.0,
                        max: 1.0,
                        activeColor: Theme.of(context).colorScheme.primary,
                        inactiveColor: Theme.of(context).dividerColor,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _viewModel.stopSound(sound.id),
                      icon: const Icon(Icons.stop, color: Colors.red),
                      tooltip: 'Stoppen',
                    ),
                  ] else ...[
                    IconButton(
                      onPressed: () {
                        if (sound.soundType == SoundType.Ambiente) {
                          _viewModel.toggleAmbience(sound);
                        } else {
                          _viewModel.playEffect(sound);
                        }
                      },
                      icon: Icon(
                        sound.soundType == SoundType.Ambiente 
                            ? Icons.play_arrow 
                            : Icons.volume_up,
                      ),
                      tooltip: sound.soundType == SoundType.Ambiente 
                          ? 'Abspielen (Schleife)' 
                          : 'Abspielen',
                    ),
                  ],
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'favorite':
                          _viewModel.toggleFavorite(sound);
                          break;
                        case 'delete':
                          _showDeleteConfirmation(context, sound);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'favorite',
                        child: Row(
                          children: [
                            Icon(
                              sound.isFavorite 
                                  ? Icons.favorite_border 
                                  : Icons.favorite,
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            Text(sound.isFavorite 
                                ? 'Aus Favoriten entfernen' 
                                : 'Zu Favoriten hinzufügen'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: const [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Löschen', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Sound sound) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Löschen bestätigen'),
        content: Text(
          'Möchtest du den Sound "${sound.name}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _viewModel.deleteSound(sound.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
