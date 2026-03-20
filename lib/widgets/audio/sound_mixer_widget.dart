import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sound.dart';
import '../../services/multi_stream_sound_service.dart';
import '../../database/repositories/sound_model_repository.dart';
import '../../theme/dnd_theme.dart';
import 'sound_mixer_channel.dart';
import 'sound_picker_widget.dart';

/// Haupt-Sound-Mixer Widget für die Active Session
/// 
/// Bietet:
/// - Liste aller aktiver Sound-Kanäle
/// - "Sound hinzufügen" Buttons (Ambiente & Effekt)
/// - Master-Lautstärke-Regler
/// - "Alle stoppen" Button
class SoundMixerWidget extends StatefulWidget {
  /// Optional: Liste von Sound-IDs die automatisch geladen werden sollen
  final List<String>? initialSoundIds;
  
  const SoundMixerWidget({
    super.key,
    this.initialSoundIds,
  });

  @override
  State<SoundMixerWidget> createState() => _SoundMixerWidgetState();
}

class _SoundMixerWidgetState extends State<SoundMixerWidget> {
  late MultiStreamSoundService _mixerService;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _mixerService = MultiStreamSoundService();
    _initializeMixer();
  }

  Future<void> _initializeMixer() async {
    // Initiale Sounds laden falls vorhanden
    if (widget.initialSoundIds != null && widget.initialSoundIds!.isNotEmpty) {
      final soundRepo = context.read<SoundModelRepository>();
      
      for (final soundId in widget.initialSoundIds!) {
        try {
          final sound = await soundRepo.findById(soundId);
          if (sound != null && sound.isValid) {
            await _mixerService.addSound(
              sound,
              volume: 0.8,
              isLooping: true,
              autoPlay: false,
            );
          }
        } catch (e) {
          debugPrint('Fehler beim Laden des Sounds $soundId: $e');
        }
      }
    }
    
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _mixerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: DnDTheme.ancientGold,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _mixerService,
      builder: (context, child) {
        return Column(
          children: [
            // Master-Lautstärke
            _buildMasterVolumeControl(),
            
            const Divider(
              color: DnDTheme.mysticalPurple,
              height: 16,
            ),
            
            // Aktive Kanäle
            Expanded(
              child: _mixerService.channels.isEmpty
                  ? _buildEmptyState()
                  : _buildChannelsList(),
            ),
            
            // Action Buttons
            _buildActionButtons(),
          ],
        );
      },
    );
  }

  /// Master-Lautstärke-Regler
  Widget _buildMasterVolumeControl() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DnDTheme.arcaneBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            _mixerService.masterVolume == 0 ? Icons.volume_off : Icons.volume_up,
            color: DnDTheme.arcaneBlue,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            'Master',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: DnDTheme.arcaneBlue,
                inactiveTrackColor: DnDTheme.slateGrey.withValues(alpha: 0.5),
                thumbColor: DnDTheme.ancientGold,
              ),
              child: Slider(
                value: _mixerService.masterVolume,
                min: 0.0,
                max: 1.0,
                onChanged: (value) {
                  _mixerService.setMasterVolume(value);
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(_mixerService.masterVolume * 100).toInt()}%',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Leere Anzeige wenn keine Kanäle aktiv sind
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 40,
            color: Colors.white38,
          ),
          const SizedBox(height: 12),
          Text(
            'Keine Sounds aktiv',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Füge Sounds hinzu, um sie abzuspielen',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white54,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Liste der aktiven Kanäle
  Widget _buildChannelsList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: _mixerService.channels.length,
      itemBuilder: (context, index) {
        final channel = _mixerService.channels[index];
        return SoundMixerChannel(
          channel: channel,
          mixerService: _mixerService,
          onRemove: () => _removeChannel(channel.id),
        );
      },
    );
  }

  /// Action Buttons am unteren Rand
  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Erste Reihe: Zwei Hinzufügen-Buttons
          Row(
            children: [
              // Ambiente Sound hinzufügen
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _mixerService.channelCount < MultiStreamSoundService.maxChannels
                      ? () => _showSoundPicker(SoundType.Ambiente)
                      : null,
                  icon: const Icon(Icons.waves, size: 16),
                  label: Text(
                    'Ambiente',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DnDTheme.arcaneBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: DnDTheme.slateGrey,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Effekt Sound hinzufügen
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _mixerService.channelCount < MultiStreamSoundService.maxChannels
                      ? () => _showSoundPicker(SoundType.Effekt)
                      : null,
                  icon: const Icon(Icons.speaker, size: 16),
                  label: Text(
                    'Effekt',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DnDTheme.successGreen,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: DnDTheme.slateGrey,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Zweite Reihe: Stoppen und Counter
          Row(
            children: [
              // Alle stoppen
              if (_mixerService.channels.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: _mixerService.playingCount > 0
                      ? () => _mixerService.stopAll()
                      : null,
                  icon: const Icon(Icons.stop, size: 16),
                  label: Text(
                    'Alle stoppen',
                    style: TextStyle(fontSize: 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DnDTheme.errorRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: DnDTheme.slateGrey,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              const Spacer(),
              
              // Counter
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DnDTheme.mysticalPurple.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_mixerService.channelCount}/${MultiStreamSoundService.maxChannels}',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Zeigt den Sound-Picker Dialog
  Future<void> _showSoundPicker(SoundType filterType) async {
    // Aktive Sound-IDs sammeln
    final activeSoundIds = _mixerService.channels.map((c) => c.sound.id).toList();
    
    final result = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            gradient: DnDTheme.getMysticalGradient(
              startColor: DnDTheme.stoneGrey,
              endColor: DnDTheme.slateGrey,
            ),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DnDTheme.radiusLarge),
              topRight: Radius.circular(DnDTheme.radiusLarge),
            ),
          ),
          child: SoundPickerWidget(
            initiallySelectedSoundIds: activeSoundIds,
            onSelectionChanged: (_) {}, // Wird nicht benötigt da wir das Ergebnis beim Schließen bekommen
          ),
        ),
      ),
    );

    // Neue Sounds hinzufügen
    if (result != null && result.isNotEmpty) {
      await _addSoundsToMixer(result, activeSoundIds, filterType);
    }
  }

  /// Fügt die ausgewählten Sounds zum Mixer hinzu
  Future<void> _addSoundsToMixer(
    List<String> selectedSoundIds,
    List<String> currentActiveIds,
    SoundType preferredType,
  ) async {
    final soundRepo = context.read<SoundModelRepository>();
    
    // Sounds die entfernt werden sollen
    final toRemove = currentActiveIds.where((id) => !selectedSoundIds.contains(id));
    for (final soundId in toRemove) {
      await _mixerService.removeSound(soundId);
    }
    
    // Neue Sounds hinzufügen
    for (final soundId in selectedSoundIds) {
      // Überspringen wenn bereits aktiv
      if (_mixerService.hasSound(soundId)) continue;
      
      try {
        final sound = await soundRepo.findById(soundId);
        if (sound != null && sound.isValid) {
          await _mixerService.addSound(
            sound,
            volume: 0.8,
            isLooping: sound.soundType == SoundType.Ambiente,
            autoPlay: false, // Nicht automatisch abspielen
          );
        }
      } catch (e) {
        debugPrint('Fehler beim Hinzufügen des Sounds $soundId: $e');
      }
    }
  }

  /// Entfernt einen Kanal aus dem Mixer
  Future<void> _removeChannel(String channelId) async {
    await _mixerService.removeSound(channelId);
  }
}