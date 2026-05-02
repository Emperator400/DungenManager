import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sound.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/sound_library_viewmodel.dart';

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
    final C = context.appColors;
    return ChangeNotifierProvider<SoundLibraryViewModel>.value(
      value: _viewModel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(C),
          _buildFilterBar(C),
          _buildTypeChips(C),
          Flexible(child: _buildSoundList(C)),
          _buildFooter(C),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColorsExtension C) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.music_note, color: C.accent, size: 16),
          const SizedBox(width: 8),
          Text(
            'Sounds auswählen',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
          ),
          const Spacer(),
          if (_selectedSoundIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: C.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: C.accent.withValues(alpha: 0.35)),
              ),
              child: Text(
                '${_selectedSoundIds.length} ausgewählt',
                style: TextStyle(fontSize: 11, color: C.accent, fontWeight: FontWeight.w500),
              ),
            ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Icon(Icons.close, size: 18, color: C.textMid),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(AppColorsExtension C) {
    return Consumer<SoundLibraryViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
          decoration: BoxDecoration(
            color: C.bgPanel,
            border: Border(bottom: BorderSide(color: C.border)),
          ),
          child: TextField(
            controller: _searchController,
            style: TextStyle(fontSize: 13, color: C.text),
            decoration: InputDecoration(
              hintText: 'Sounds suchen...',
              hintStyle: TextStyle(color: C.textSoft, fontSize: 13),
              prefixIcon: Icon(Icons.search, color: C.textSoft, size: 18),
              suffixIcon: viewModel.soundSearchQuery.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        viewModel.setSoundSearchQuery('');
                      },
                      child: Icon(Icons.close, color: C.textSoft, size: 16),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              filled: true,
              fillColor: C.bgHover,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: C.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: C.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(7),
                borderSide: BorderSide(color: C.accent),
              ),
            ),
            onChanged: viewModel.setSoundSearchQuery,
          ),
        );
      },
    );
  }

  Widget _buildTypeChips(AppColorsExtension C) {
    return Consumer<SoundLibraryViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          decoration: BoxDecoration(
            color: C.bgPanel,
            border: Border(bottom: BorderSide(color: C.border)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _typeChip('Alle', viewModel.selectedSoundType == null, C.accent, C,
                    onTap: () => viewModel.setSoundTypeFilter(null)),
                const SizedBox(width: 4),
                ...SoundType.values.map((type) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: _typeChip(
                    type.displayName,
                    viewModel.selectedSoundType == type,
                    C.green,
                    C,
                    onTap: () => viewModel.setSoundTypeFilter(type),
                  ),
                )),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _typeChip(String label, bool isSelected, Color color, AppColorsExtension C, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: isSelected ? color : C.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isSelected ? color : C.textSoft,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSoundList(AppColorsExtension C) {
    return Consumer<SoundLibraryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoadingSounds) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(color: C.accent, strokeWidth: 2),
            ),
          );
        }
        if (viewModel.sounds.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_off, size: 32, color: C.textSoft),
                  const SizedBox(height: 8),
                  Text('Keine Sounds gefunden', style: TextStyle(fontSize: 13, color: C.textSoft)),
                ],
              ),
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          itemCount: viewModel.sounds.length,
          itemBuilder: (context, index) => _buildSoundCard(viewModel.sounds[index], C),
        );
      },
    );
  }

  Widget _buildSoundCard(Sound sound, AppColorsExtension C) {
    final isSelected = _selectedSoundIds.contains(sound.id);
    final isPlaying = _currentlyPlayingSound?.id == sound.id;

    return GestureDetector(
      onTap: () => _toggleSoundSelection(sound.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isSelected ? C.accent.withValues(alpha: 0.07) : C.bgHover,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(
            color: isSelected ? C.accent.withValues(alpha: 0.4) : C.border,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: isSelected ? C.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: isSelected ? C.accent : C.border),
              ),
              child: isSelected
                  ? Icon(Icons.check, size: 12, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 10),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sound.name,
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.text),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: C.green.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          sound.soundType.displayName,
                          style: TextStyle(fontSize: 9, color: C.green, fontWeight: FontWeight.w500),
                        ),
                      ),
                      if (sound.description.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            sound.description,
                            style: TextStyle(fontSize: 11, color: C.textSoft),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Preview button
            GestureDetector(
              onTap: () => _toggleSoundPlayback(sound),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isPlaying ? C.accent.withValues(alpha: 0.15) : C.bgActive,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: isPlaying ? C.accent.withValues(alpha: 0.4) : C.border),
                ),
                child: Icon(
                  isPlaying ? Icons.stop : Icons.play_arrow,
                  color: isPlaying ? C.accent : C.textMid,
                  size: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(AppColorsExtension C) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(top: BorderSide(color: C.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(color: C.border),
                ),
                alignment: Alignment.center,
                child: Text('Abbrechen', style: TextStyle(fontSize: 13, color: C.textMid)),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(_selectedSoundIds.toList()),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: C.accent,
                  borderRadius: BorderRadius.circular(7),
                ),
                alignment: Alignment.center,
                child: Text(
                  _selectedSoundIds.isEmpty
                      ? 'Alle entfernen'
                      : '${_selectedSoundIds.length} anwenden',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white),
                ),
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

  Future<void> _toggleSoundPlayback(Sound sound) async {
    if (_currentlyPlayingSound?.id == sound.id) {
      await SoundService.stopSound();
      setState(() => _currentlyPlayingSound = null);
    } else {
      setState(() => _currentlyPlayingSound = sound);
      final success = await SoundService.playSound(sound.filePath);
      if (!success) setState(() => _currentlyPlayingSound = null);
    }
  }
}

extension _SoundTypeDisplayName on SoundType {
  String get displayName {
    switch (this) {
      case SoundType.Ambiente: return 'Ambiente';
      case SoundType.Effekt:   return 'Effekt';
    }
  }
}

