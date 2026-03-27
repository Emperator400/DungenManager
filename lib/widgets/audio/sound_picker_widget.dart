import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sound.dart';
import '../../viewmodels/sound_library_viewmodel.dart';
import '../../theme/dnd_theme.dart';
import '../../services/sound_service.dart';
import '../ui_components/states/loading_state_widget.dart';
import '../ui_components/states/empty_state_widget.dart';
import '../ui_components/filter/unified_filter_chip.dart';
import '../ui_components/chips/unified_info_chip.dart';

/// Sound Picker Widget zum Auswählen mehrerer Sounds
/// 
/// Zeigt alle Sounds mit Such- und Filter-Funktionen an und ermöglicht
/// das Anhören von Sounds vor dem Hinzufügen zur Session.
class SoundPickerWidget extends StatefulWidget {
  final List<String> initiallySelectedSoundIds;
  final Function(List<String>) onSelectionChanged;
  
  const SoundPickerWidget({
    super.key,
    required this.initiallySelectedSoundIds,
    required this.onSelectionChanged,
  });

  @override
  State<SoundPickerWidget> createState() => _SoundPickerWidgetState();
}

class _SoundPickerWidgetState extends State<SoundPickerWidget> {
  late SoundLibraryViewModel _viewModel;
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedSoundIds = {};
  Sound? _currentlyPlayingSound;

  @override
  void initState() {
    super.initState();
    _viewModel = SoundLibraryViewModel();
    _selectedSoundIds.addAll(widget.initiallySelectedSoundIds);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SoundLibraryViewModel>.value(
      value: _viewModel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),
          
          // Search und Filter
          _buildFilterBar(),
          
          // Sound Type Filter Chips
          _buildSoundTypeFilterChips(),
          
          // Sound Liste
          Flexible(
            child: Consumer<SoundLibraryViewModel>(
              builder: (context, viewModel, child) {
                if (viewModel.isLoadingSounds) {
                  return LoadingStateWidget.standard(color: DnDTheme.ancientGold);
                }

                if (viewModel.sounds.isEmpty) {
                  return EmptyStateWidget.minimal(
                    title: 'Keine Sounds gefunden',
                    icon: Icons.music_note,
                    iconColor: DnDTheme.mysticalPurple,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(DnDTheme.md),
                  itemCount: viewModel.sounds.length,
                  itemBuilder: (context, index) {
                    final sound = viewModel.sounds[index];
                    return _buildSoundCard(sound);
                  },
                );
              },
            ),
          ),
          
          // Footer mit Aktionen
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DnDTheme.radiusMedium),
          topRight: Radius.circular(DnDTheme.radiusMedium),
        ),
        border: Border(
          bottom: BorderSide(
            color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            color: DnDTheme.ancientGold,
            size: 24,
          ),
          const SizedBox(width: DnDTheme.sm),
          Text(
            'Sounds auswählen',
            style: DnDTheme.headline3.copyWith(
              color: Colors.white,
            ),
          ),
          const Spacer(),
          UnifiedInfoChip.count(
            label: 'ausgewählt',
            count: _selectedSoundIds.length,
            color: DnDTheme.mysticalPurple,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Consumer<SoundLibraryViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(DnDTheme.md),
          decoration: BoxDecoration(
            gradient: DnDTheme.getMysticalGradient(
              startColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              endColor: DnDTheme.stoneGrey.withValues(alpha: 0.3),
            ),
            border: Border(
              bottom: BorderSide(
                color: DnDTheme.mysticalPurple.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Sounds suchen...',
                    hintStyle: DnDTheme.bodyText2.copyWith(color: Colors.white54),
                    prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
                    suffixIcon: viewModel.soundSearchQuery.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear, color: DnDTheme.errorRed),
                            onPressed: () {
                              _searchController.clear();
                              viewModel.setSoundSearchQuery('');
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                      borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                      borderSide: BorderSide(
                        color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                      borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                    ),
                    filled: true,
                    fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: DnDTheme.md,
                      vertical: DnDTheme.sm,
                    ),
                  ),
                  onChanged: (value) => viewModel.setSoundSearchQuery(value),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSoundTypeFilterChips() {
    return Consumer<SoundLibraryViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: DnDTheme.md,
            vertical: DnDTheme.sm,
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: DnDTheme.mysticalPurple.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                UnifiedFilterChip<String>(
                  value: 'all',
                  label: 'Alle',
                  isSelected: viewModel.selectedSoundType == null,
                  selectedColor: DnDTheme.ancientGold,
                  onSelected: (_) => viewModel.setSoundTypeFilter(null),
                ),
                ...SoundType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(left: DnDTheme.xs),
                  child: UnifiedFilterChip<String>(
                    value: type.name,
                    label: type.displayName,
                    isSelected: viewModel.selectedSoundType == type,
                    selectedColor: DnDTheme.ancientGold,
                    onSelected: (_) => viewModel.setSoundTypeFilter(type),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSoundCard(Sound sound) {
    final isSelected = _selectedSoundIds.contains(sound.id);
    
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: isSelected 
              ? DnDTheme.ancientGold.withValues(alpha: 0.2)
              : DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: isSelected 
              ? DnDTheme.ancientGold
              : DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DnDTheme.md),
        leading: Checkbox(
          value: isSelected,
          onChanged: (_) => _toggleSoundSelection(sound.id),
          activeColor: DnDTheme.ancientGold,
          checkColor: Colors.black,
        ),
        title: Text(
          sound.name,
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sound.soundTypeDisplayName,
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white70,
              ),
            ),
            if (sound.description.isNotEmpty) ...[
              const SizedBox(height: DnDTheme.xs),
              Text(
                sound.description,
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _currentlyPlayingSound?.id == sound.id 
                    ? Icons.stop 
                    : Icons.play_arrow,
                color: DnDTheme.arcaneBlue,
              ),
              onPressed: () => _toggleSoundPlayback(sound),
              tooltip: 'Anhören',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        border: Border(
          top: BorderSide(
            color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: DnDTheme.md),
                side: BorderSide(color: Colors.grey.shade400),
              ),
              child: Text('Abbrechen'),
            ),
          ),
          const SizedBox(width: DnDTheme.md),
          Expanded(
            child: ElevatedButton(
              onPressed: _selectedSoundIds.isEmpty 
                  ? null 
                  : () => Navigator.of(context).pop(_selectedSoundIds.toList()),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.successGreen,
                padding: const EdgeInsets.symmetric(vertical: DnDTheme.md),
              ),
              child: Text(
                '${_selectedSoundIds.length} Sounds hinzufügen',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleSoundSelection(String soundId) {
    setState(() {
      if (_selectedSoundIds.contains(soundId)) {
        _selectedSoundIds.remove(soundId);
      } else {
        _selectedSoundIds.add(soundId);
      }
      widget.onSelectionChanged(_selectedSoundIds.toList());
    });
  }

  void _toggleSoundPlayback(Sound sound) async {
    if (_currentlyPlayingSound?.id == sound.id) {
      // Stop current sound
      await SoundService.stopSound();
      setState(() {
        _currentlyPlayingSound = null;
      });
    } else {
      // Play new sound
      setState(() {
        _currentlyPlayingSound = sound;
      });
      final success = await SoundService.playSound(sound.filePath);
      if (!success) {
        setState(() {
          _currentlyPlayingSound = null;
        });
      }
    }
  }
}

// Extension für SoundType Display Name
extension SoundTypeExtension on SoundType {
  String get displayName {
    switch (this) {
      case SoundType.Ambiente:
        return 'Ambiente';
      case SoundType.Effekt:
        return 'Effekt';
    }
  }
}

// Extension für Sound Display Name
extension SoundExtension on Sound {
  String get soundTypeDisplayName {
    return soundType.displayName;
  }
}