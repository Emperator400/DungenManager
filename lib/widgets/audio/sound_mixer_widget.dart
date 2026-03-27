import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sound.dart';
import '../../services/multi_stream_sound_service.dart';
import '../../database/repositories/sound_model_repository.dart';
import '../../theme/dnd_theme.dart';
import '../ui_components/states/loading_state_widget.dart';
import '../ui_components/states/empty_state_widget.dart';
import 'sound_mixer_channel.dart';
import 'sound_picker_widget.dart';

/// Konfiguration für das SoundMixerWidget
class SoundMixerConfig {
  /// Kompakte Darstellung (reduzierte Controls)
  final bool compactMode;
  
  /// "Sound hinzufügen" Buttons anzeigen
  final bool showAddButtons;
  
  /// Master-Lautstärke-Regler anzeigen
  final bool showMasterVolume;
  
  /// "Alle stoppen" Button anzeigen
  final bool showStopAllButton;
  
  /// Kanal-Counter anzeigen
  final bool showChannelCounter;
  
  /// Nur Wiedergabe, keine neuen Sounds hinzufügbar
  final bool readOnly;
  
  /// Maximale Höhe des Widgets (null = unbegrenzt)
  final double? maxHeight;
  
  /// Divider zwischen Master und Kanäle anzeigen
  final bool showDivider;
  
  /// Header anzeigen
  final bool showHeader;
  
  /// Skip-Buttons (±10 Sekunden) pro Kanal anzeigen
  final bool showSkipButtons;
  
  /// Detaillierte Sound-Info (Beschreibung, Kategorie) anzeigen
  final bool showDetailedInfo;
  
  /// Speed-Control (0.5x - 2.0x) pro Kanal anzeigen
  final bool showSpeedControl;
  
  /// Großer zentraler Play-Button für bessere Usability
  final bool showLargePlayButton;

  const SoundMixerConfig({
    this.compactMode = false,
    this.showAddButtons = true,
    this.showMasterVolume = true,
    this.showStopAllButton = true,
    this.showChannelCounter = true,
    this.readOnly = false,
    this.maxHeight,
    this.showDivider = true,
    this.showHeader = false,
    this.showSkipButtons = false,
    this.showDetailedInfo = false,
    this.showSpeedControl = false,
    this.showLargePlayButton = false,
  });

  /// Standard-Konfiguration für volle Funktionalität
  static const SoundMixerConfig full = SoundMixerConfig(
    compactMode: false,
    showAddButtons: true,
    showMasterVolume: true,
    showStopAllButton: true,
    showChannelCounter: true,
    readOnly: false,
    showDivider: true,
    showHeader: false,
    showSkipButtons: false,
    showDetailedInfo: false,
  );

  /// Kompakte Konfiguration für Szenen-Integration
  static const SoundMixerConfig compact = SoundMixerConfig(
    compactMode: true,
    showAddButtons: false,
    showMasterVolume: true,
    showStopAllButton: true,
    showChannelCounter: false,
    readOnly: true,
    showDivider: false,
    showHeader: true,
    showSkipButtons: false,
    showDetailedInfo: false,
  );

  /// Minimale Konfiguration (nur Kanäle)
  static const SoundMixerConfig minimal = SoundMixerConfig(
    compactMode: true,
    showAddButtons: false,
    showMasterVolume: false,
    showStopAllButton: false,
    showChannelCounter: false,
    readOnly: true,
    showDivider: false,
    showHeader: false,
    showSkipButtons: false,
    showDetailedInfo: false,
  );

  /// Player-Konfiguration für Sound-Vorschau (Single-Sound mit allen Controls)
  static const SoundMixerConfig playerPreview = SoundMixerConfig(
    compactMode: false,
    showAddButtons: false,
    showMasterVolume: true,
    showStopAllButton: true,
    showChannelCounter: false,
    readOnly: true,
    showDivider: false,
    showHeader: true,
    showSkipButtons: true,
    showDetailedInfo: true,
    showSpeedControl: true,
    showLargePlayButton: true,
  );
}

/// Haupt-Sound-Mixer Widget für die Active Session
/// 
/// Bietet:
/// - Liste aller aktiver Sound-Kanäle
/// - "Sound hinzufügen" Buttons (Ambiente & Effekt)
/// - Master-Lautstärke-Regler
/// - "Alle stoppen" Button
/// 
/// Konfigurierbar via [config] Parameter für verschiedene Verwendungszwecke.
class SoundMixerWidget extends StatefulWidget {
  /// Optional: Liste von Sound-IDs die automatisch geladen werden sollen
  final List<String>? initialSoundIds;
  
  /// Optional: Liste von Sound-Objekten die direkt geladen werden sollen
  final List<Sound>? initialSounds;
  
  /// Konfiguration für das Widget-Verhalten
  final SoundMixerConfig config;
  
  /// Callback wenn sich die Liste der aktiven Sounds ändert
  final VoidCallback? onSoundsChanged;
  
  /// Wenn true, wird der SoundService beim dispose nicht disposed (für Preview-Modus)
  /// Sounds laufen dann weiter nach Schließen des Widgets
  final bool keepAlive;

  const SoundMixerWidget({
    super.key,
    this.initialSoundIds,
    this.initialSounds,
    this.config = SoundMixerConfig.full,
    this.onSoundsChanged,
    this.keepAlive = false,
  });

  @override
  State<SoundMixerWidget> createState() => _SoundMixerWidgetState();
}

class _SoundMixerWidgetState extends State<SoundMixerWidget> {
  late MultiStreamSoundService _mixerService;
  bool _isInitialized = false;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _mixerService = MultiStreamSoundService();
    _initializeMixer();
  }

  Future<void> _initializeMixer() async {
    // Direkt übergebene Sound-Objekte laden
    if (widget.initialSounds != null && widget.initialSounds!.isNotEmpty) {
      for (final sound in widget.initialSounds!) {
        if (_isDisposed) return; // Prüfen ob Widget noch existiert
        if (sound.isValid) {
          await _mixerService.addSound(
            sound,
            volume: 0.8,
            isLooping: sound.soundType == SoundType.Ambiente,
            autoPlay: false,
          );
        }
      }
    }
    
    // Sound-IDs laden falls vorhanden
    if (widget.initialSoundIds != null && widget.initialSoundIds!.isNotEmpty) {
      final soundRepo = context.read<SoundModelRepository>();
      
      for (final soundId in widget.initialSoundIds!) {
        if (_isDisposed) return; // Prüfen ob Widget noch existiert
        // Überspringen wenn bereits geladen
        if (_mixerService.hasSound(soundId)) continue;
        
        try {
          final sound = await soundRepo.findById(soundId);
          if (_isDisposed) return; // Prüfen ob Widget noch existiert
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
    
    if (_isDisposed) return; // Prüfen ob Widget noch existiert
    setState(() {
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // Wenn keepAlive true ist, nur Sounds stoppen aber Service nicht disposen
    // (für Preview-Modus, damit Sounds weiterlaufen können)
    if (widget.keepAlive) {
      _mixerService.stopAll();
      // Service wird nicht disposed - läuft weiter
    } else {
      // Normaler Dispose: Alles stoppen und disposen
      _mixerService.stopAll();
      _mixerService.dispose();
    }
    
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return LoadingStateWidget.standard(color: DnDTheme.ancientGold);
    }

    return AnimatedBuilder(
      animation: _mixerService,
      builder: (context, child) {
        // Maximale Höhe anwenden falls konfiguriert
        if (widget.config.maxHeight != null) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: widget.config.maxHeight!),
            child: _buildContent(),
          );
        }

        return _buildContent();
      },
    );
  }

  Widget _buildContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Optional: Header
        if (widget.config.showHeader) _buildHeader(),
        
        // Master-Lautstärke
        if (widget.config.showMasterVolume) _buildMasterVolumeControl(),
        
        // Divider
        if (widget.config.showDivider && widget.config.showMasterVolume)
          const Divider(
            color: DnDTheme.mysticalPurple,
            height: 16,
          ),
        
        // Aktive Kanäle
        if (_mixerService.channels.isEmpty)
          _buildEmptyState()
        else
          _buildChannelsList(),
        
        // Action Buttons
        if (widget.config.showAddButtons || 
            (widget.config.showStopAllButton && _mixerService.channels.isNotEmpty) ||
            widget.config.showChannelCounter)
          _buildActionButtons(),
      ],
    );
  }

  /// Header für kompakte Darstellung
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: DnDTheme.mysticalPurple.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            color: DnDTheme.ancientGold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            'Sounds',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          Text(
            '${_mixerService.channelCount} aktiv',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Master-Lautstärke-Regler
  Widget _buildMasterVolumeControl() {
    final isCompact = widget.config.compactMode;
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 8 : 12, 
        vertical: isCompact ? 4 : 8
      ),
      decoration: BoxDecoration(
        color: DnDTheme.arcaneBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
      ),
      child: Row(
        children: [
          Icon(
            _mixerService.masterVolume == 0 ? Icons.volume_off : Icons.volume_up,
            color: DnDTheme.arcaneBlue,
            size: isCompact ? 16 : 20,
          ),
          if (!isCompact) ...[
            const SizedBox(width: 8),
            Text(
              'Master',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ],
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: isCompact ? 3 : 4,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: isCompact ? 6 : 8),
                overlayShape: RoundSliderOverlayShape(overlayRadius: isCompact ? 10 : 14),
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
                  widget.onSoundsChanged?.call();
                },
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${(_mixerService.masterVolume * 100).toInt()}%',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontSize: isCompact ? 9 : 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Leere Anzeige wenn keine Kanäle aktiv sind
  Widget _buildEmptyState() {
    if (widget.config.compactMode) {
      return Center(
        child: Text(
          'Keine Sounds',
          style: DnDTheme.bodyText2.copyWith(
            color: Colors.white54,
            fontSize: 10,
          ),
        ),
      );
    }
    
    return EmptyStateWidget.minimal(
      title: 'Keine Sounds aktiv',
      icon: Icons.music_note,
      iconColor: DnDTheme.arcaneBlue,
    );
  }
  
  /// Liste der aktiven Kanäle
  Widget _buildChannelsList() {
    final channels = _mixerService.channels;
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: channels.map((channel) {
        return SoundMixerChannel(
          channel: channel,
          mixerService: _mixerService,
          compactMode: widget.config.compactMode,
          showSkipButtons: widget.config.showSkipButtons,
          showDetailedInfo: widget.config.showDetailedInfo,
          showSpeedControl: widget.config.showSpeedControl,
          showLargePlayButton: widget.config.showLargePlayButton,
          onRemove: widget.config.readOnly ? null : () => _removeChannel(channel.id),
        );
      }).toList(),
    );
  }

  /// Action Buttons am unteren Rand
  Widget _buildActionButtons() {
    final isCompact = widget.config.compactMode;
    
    return Container(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 8),
      child: Column(
        children: [
          // Erste Reihe: Hinzufügen-Buttons (nur wenn nicht readOnly)
          if (widget.config.showAddButtons && !widget.config.readOnly)
            Row(
              children: [
                // Ambiente Sound hinzufügen
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _mixerService.channelCount < MultiStreamSoundService.maxChannels
                        ? () => _showSoundPicker(SoundType.Ambiente)
                        : null,
                    icon: Icon(Icons.waves, size: isCompact ? 14 : 16),
                    label: Text(
                      'Ambiente',
                      style: TextStyle(fontSize: isCompact ? 9 : 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DnDTheme.arcaneBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: DnDTheme.slateGrey,
                      padding: EdgeInsets.symmetric(vertical: isCompact ? 6 : 8),
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
                    icon: Icon(Icons.speaker, size: isCompact ? 14 : 16),
                    label: Text(
                      'Effekt',
                      style: TextStyle(fontSize: isCompact ? 9 : 11),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DnDTheme.successGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: DnDTheme.slateGrey,
                      padding: EdgeInsets.symmetric(vertical: isCompact ? 6 : 8),
                    ),
                  ),
                ),
              ],
            ),
          
          if (widget.config.showAddButtons && !widget.config.readOnly)
            const SizedBox(height: 8),
          
          // Zweite Reihe: Stoppen und Counter
          Row(
            children: [
              // Alle stoppen
              if (widget.config.showStopAllButton && _mixerService.channels.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: _mixerService.playingCount > 0
                      ? () {
                          _mixerService.stopAll();
                          widget.onSoundsChanged?.call();
                        }
                      : null,
                  icon: Icon(Icons.stop, size: isCompact ? 14 : 16),
                  label: Text(
                    'Alle stoppen',
                    style: TextStyle(fontSize: isCompact ? 9 : 11),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DnDTheme.errorRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: DnDTheme.slateGrey,
                    padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12, vertical: isCompact ? 6 : 8),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              
              const Spacer(),
              
              // Counter
              if (widget.config.showChannelCounter)
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
                      fontSize: isCompact ? 9 : 10,
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
      widget.onSoundsChanged?.call();
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
    widget.onSoundsChanged?.call();
  }
}