import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sound.dart';
import '../../services/multi_stream_sound_service.dart';
import '../../database/repositories/sound_model_repository.dart';
import 'sound_mixer_channel.dart';
import 'sound_picker_widget.dart';

/// Modern Audio Design Colors (Spotify-inspired)
class ModernAudioColors {
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF181818);
  static const Color surfaceLight = Color(0xFF282828);
  static const Color surfaceHighlight = Color(0xFF404040);
  
  static const Color accentGreen = Color(0xFF1DB954);
  static const Color accentGreenLight = Color(0xFF1ED760);
  static const Color accentCyan = Color(0xFF00D4AA);
  
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3B3);
  static const Color textMuted = Color(0xFF727272);
  
  static const Color playingGlow = Color(0xFF1DB954);
  static const Color progressBar = Color(0xFF1DB954);
  static const Color progressBackground = Color(0xFF4D4D4D);
}

/// Size-Enumeration für das SoundMixerWidget
/// 
/// Definiert 5 Größenstufen mit zunehmender Funktionalität:
/// - [minimal]: Nur Play/Pause + Volume pro Kanal
/// - [compact]: + Master-Volume, Header, Stop-All
/// - [medium]: + Zeit-Anzeige, Fortschrittsbalken, Loop-Toggle
/// - [expanded]: + Skip-Buttons, Speed-Control, detaillierte Info
/// - [full]: + Add-Sound Buttons, Channel-Counter (alle Features)
enum SoundMixerSize {
  /// Kleinstmöglich: Nur Play/Pause + Volume pro Kanal
  minimal,
  
  /// Klein: + Master-Volume, Header, Stop-All Button
  compact,
  
  /// Mittel: + Zeit-Anzeige, Fortschrittsbalken, Loop-Toggle
  medium,
  
  /// Groß: + Skip-Buttons, Speed-Control, detaillierte Info
  expanded,
  
  /// Voll: + Add-Sound Buttons, Channel-Counter (alle Features)
  full,
}

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
  
  /// Zeit-Anzeige und Fortschrittsbalken anzeigen
  final bool showTimeDisplay;
  
  /// Loop-Toggle Button anzeigen
  final bool showLoopToggle;

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
    this.showTimeDisplay = true,
    this.showLoopToggle = true,
  });

  /// Erstellt eine Config basierend auf einer Size-Stufe
  factory SoundMixerConfig.fromSize(SoundMixerSize size) {
    switch (size) {
      case SoundMixerSize.minimal:
        return const SoundMixerConfig(
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
          showSpeedControl: false,
          showLargePlayButton: false,
          showTimeDisplay: false,
          showLoopToggle: false,
        );
      
      case SoundMixerSize.compact:
        return const SoundMixerConfig(
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
          showSpeedControl: false,
          showLargePlayButton: false,
          showTimeDisplay: false,
          showLoopToggle: false,
        );
      
      case SoundMixerSize.medium:
        return const SoundMixerConfig(
          compactMode: false,
          showAddButtons: false,
          showMasterVolume: true,
          showStopAllButton: true,
          showChannelCounter: false,
          readOnly: true,
          showDivider: true,
          showHeader: true,
          showSkipButtons: false,
          showDetailedInfo: false,
          showSpeedControl: false,
          showLargePlayButton: false,
          showTimeDisplay: true,
          showLoopToggle: true,
        );
      
      case SoundMixerSize.expanded:
        return const SoundMixerConfig(
          compactMode: false,
          showAddButtons: false,
          showMasterVolume: true,
          showStopAllButton: true,
          showChannelCounter: false,
          readOnly: true,
          showDivider: true,
          showHeader: true,
          showSkipButtons: true,
          showDetailedInfo: true,
          showSpeedControl: true,
          showLargePlayButton: false,
          showTimeDisplay: true,
          showLoopToggle: true,
        );
      
      case SoundMixerSize.full:
        return const SoundMixerConfig(
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
          showSpeedControl: false,
          showLargePlayButton: false,
          showTimeDisplay: true,
          showLoopToggle: true,
        );
    }
  }

  /// Standard-Konfiguration für volle Funktionalität
  static const SoundMixerConfig fullConfig = SoundMixerConfig(
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
    showTimeDisplay: true,
    showLoopToggle: true,
  );

  /// Kompakte Konfiguration für Szenen-Integration
  static const SoundMixerConfig compactConfig = SoundMixerConfig(
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
    showTimeDisplay: false,
    showLoopToggle: false,
  );

  /// Minimale Konfiguration (nur Kanäle)
  static const SoundMixerConfig minimalConfig = SoundMixerConfig(
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
    showTimeDisplay: false,
    showLoopToggle: false,
  );

  /// Player-Konfiguration für Sound-Vorschau (Single-Sound mit allen Controls)
  static const SoundMixerConfig playerPreviewConfig = SoundMixerConfig(
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
    showTimeDisplay: true,
    showLoopToggle: true,
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
/// Konfigurierbar via [size] oder [config] Parameter für verschiedene Verwendungszwecke.
class SoundMixerWidget extends StatefulWidget {
  /// Size-Stufe für vordefinierte Konfiguration
  final SoundMixerSize size;
  
  /// Optional: Liste von Sound-IDs die automatisch geladen werden sollen
  final List<String>? initialSoundIds;
  
  /// Optional: Liste von Sound-Objekten die direkt geladen werden sollen
  final List<Sound>? initialSounds;
  
  /// Konfiguration für das Widget-Verhalten (überschreibt size wenn angegeben)
  final SoundMixerConfig? config;
  
  /// Callback wenn sich die Liste der aktiven Sounds ändert
  final VoidCallback? onSoundsChanged;
  
  /// Wenn true, wird der SoundService beim dispose nicht disposed (für Preview-Modus)
  /// Sounds laufen dann weiter nach Schließen des Widgets
  final bool keepAlive;

  const SoundMixerWidget({
    super.key,
    this.size = SoundMixerSize.full,
    this.initialSoundIds,
    this.initialSounds,
    this.config,
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
  late SoundMixerConfig _config;

  @override
  void initState() {
    super.initState();
    _mixerService = MultiStreamSoundService();
    _updateConfig();
    _initializeMixer();
  }

  void _updateConfig() {
    _config = widget.config ?? SoundMixerConfig.fromSize(widget.size);
  }

  @override
  void didUpdateWidget(SoundMixerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Config aktualisieren
    if (oldWidget.size != widget.size || oldWidget.config != widget.config) {
      _updateConfig();
    }
    
    // Prüfen ob sich die initialSounds geändert haben
    if (!_listEquals(oldWidget.initialSounds, widget.initialSounds)) {
      _updateInitialSounds();
    }
  }
  
  /// Prüft ob zwei Listen von Sounds gleich sind
  bool _listEquals(List<Sound>? a, List<Sound>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
    }
    return true;
  }
  
  /// Aktualisiert die Sounds wenn sich initialSounds ändert
  Future<void> _updateInitialSounds() async {
    if (_isDisposed) return;
    
    // Erst alle aktuellen Sounds entfernen
    await _mixerService.clearAll();
    
    // Dann die neuen Sounds laden
    if (widget.initialSounds != null && widget.initialSounds!.isNotEmpty) {
      for (final sound in widget.initialSounds!) {
        if (_isDisposed) return;
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
    
    if (_isDisposed) return;
    setState(() {});
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
      return const Center(
        child: CircularProgressIndicator(
          color: ModernAudioColors.accentGreen,
        ),
      );
    }

    return AnimatedBuilder(
      animation: _mixerService,
      builder: (context, child) {
        // Maximale Höhe anwenden falls konfiguriert
        if (_config.maxHeight != null) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: _config.maxHeight!),
            child: _buildContent(),
          );
        }

        return _buildContent();
      },
    );
  }

    /// Modernes Spotify-inspiriertes Design (für alle Größen)
  Widget _buildContent() {
    final isCompact = _config.compactMode;
    final padding = isCompact ? 8.0 : 16.0;
    final borderRadius = isCompact ? 8.0 : 16.0;
    
    return Container(
      decoration: BoxDecoration(
        color: ModernAudioColors.background,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: EdgeInsets.all(padding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Moderner Header
          if (_config.showHeader || _config.showMasterVolume || _config.showStopAllButton)
            _buildModernHeader(),
          
          if (_config.showHeader || _config.showMasterVolume)
            SizedBox(height: isCompact ? 8 : 16),
          
          // Master-Lautstärke (modern)
          if (_config.showMasterVolume) _buildModernMasterVolumeControl(),
          
          // Divider
          if (_config.showDivider && _config.showMasterVolume && _mixerService.channels.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: isCompact ? 4 : 8),
              child: Container(
                height: 1,
                color: ModernAudioColors.surfaceHighlight.withValues(alpha: 0.3),
              ),
            ),
          
          // Aktive Kanäle
          if (_mixerService.channels.isEmpty)
            _buildModernEmptyState()
          else
            _buildChannelsList(),
          
          // Action Buttons (modern)
          if (_config.showAddButtons || 
              (_config.showStopAllButton && _mixerService.channels.isNotEmpty) ||
              _config.showChannelCounter)
            _buildModernActionButtons(),
        ],
      ),
    );
  }

  /// Moderner Header
  Widget _buildModernHeader() {
    final isCompact = _config.compactMode;
    final playingCount = _mixerService.playingCount;
    final iconSize = isCompact ? 32.0 : 48.0;
    final iconInnerSize = isCompact ? 18.0 : 28.0;
    
    return Row(
      children: [
        // Spotify-Style Icon
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: ModernAudioColors.accentGreen,
            borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
          ),
          child: Icon(
            Icons.graphic_eq,
            color: ModernAudioColors.background,
            size: iconInnerSize,
          ),
        ),
        SizedBox(width: isCompact ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sound Mixer',
                style: TextStyle(
                  color: ModernAudioColors.textPrimary,
                  fontSize: isCompact ? 14 : 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: isCompact ? 0 : 2),
              Text(
                '$playingCount von ${_mixerService.channelCount} spielen',
                style: TextStyle(
                  color: ModernAudioColors.textSecondary,
                  fontSize: isCompact ? 10 : 12,
                ),
              ),
            ],
          ),
        ),
        // Stop All Button (im Header wenn nicht showHeader)
        if (_config.showStopAllButton && _mixerService.channels.isNotEmpty && !_config.showHeader)
          GestureDetector(
            onTap: () {
              _mixerService.stopAll();
              widget.onSoundsChanged?.call();
            },
            child: Container(
              padding: EdgeInsets.all(isCompact ? 6 : 10),
              decoration: BoxDecoration(
                color: ModernAudioColors.surfaceLight,
                borderRadius: BorderRadius.circular(isCompact ? 6 : 8),
              ),
              child: Icon(
                Icons.stop,
                color: ModernAudioColors.textSecondary,
                size: isCompact ? 16 : 20,
              ),
            ),
          ),
      ],
    );
  }

  /// Moderner Master-Lautstärke-Regler
  Widget _buildModernMasterVolumeControl() {
    final isCompact = _config.compactMode;
    final padding = isCompact ? 8.0 : 12.0;
    final iconSize = isCompact ? 16.0 : 20.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: ModernAudioColors.surface,
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
      ),
      child: Row(
        children: [
          Icon(
            _mixerService.masterVolume == 0 ? Icons.volume_off : Icons.volume_up,
            color: _mixerService.masterVolume > 0 
                ? ModernAudioColors.accentGreen 
                : ModernAudioColors.textMuted,
            size: iconSize,
          ),
          SizedBox(width: isCompact ? 8 : 12),
          Text(
            'Master',
            style: TextStyle(
              color: ModernAudioColors.textPrimary,
              fontSize: isCompact ? 12 : 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: isCompact ? 8 : 12),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: isCompact ? 3 : 4,
                thumbShape: RoundSliderThumbShape(enabledThumbRadius: isCompact ? 5 : 7),
                overlayShape: RoundSliderOverlayShape(overlayRadius: isCompact ? 10 : 14),
                activeTrackColor: ModernAudioColors.accentGreen,
                inactiveTrackColor: ModernAudioColors.progressBackground,
                thumbColor: ModernAudioColors.textPrimary,
                overlayColor: ModernAudioColors.accentGreen.withValues(alpha: 0.2),
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
          SizedBox(width: isCompact ? 4 : 8),
          SizedBox(
            width: isCompact ? 35 : 45,
            child: Text(
              '${(_mixerService.masterVolume * 100).toInt()}%',
              style: TextStyle(
                color: ModernAudioColors.textSecondary,
                fontSize: isCompact ? 10 : 12,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  /// Moderner Empty State
  Widget _buildModernEmptyState() {
    final isCompact = _config.compactMode;
    final padding = isCompact ? 16.0 : 32.0;
    final iconContainerSize = isCompact ? 40.0 : 64.0;
    final iconSize = isCompact ? 20.0 : 32.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      child: Column(
        children: [
          Container(
            width: iconContainerSize,
            height: iconContainerSize,
            decoration: BoxDecoration(
              color: ModernAudioColors.surfaceLight,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.music_note_outlined,
              color: ModernAudioColors.textMuted,
              size: iconSize,
            ),
          ),
          SizedBox(height: isCompact ? 8 : 16),
          Text(
            'Keine Sounds aktiv',
            style: TextStyle(
              color: ModernAudioColors.textSecondary,
              fontSize: isCompact ? 12 : 14,
            ),
          ),
        ],
      ),
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
          config: _config,
          onRemove: _config.readOnly ? null : () => _removeChannel(channel.id),
        );
      }).toList(),
    );
  }

  /// Moderne Action Buttons
  Widget _buildModernActionButtons() {
    final isCompact = _config.compactMode;
    final paddingTop = isCompact ? 8.0 : 16.0;
    
    return Container(
      padding: EdgeInsets.only(top: paddingTop),
      child: Column(
        children: [
          // Add Buttons
          if (_config.showAddButtons && !_config.readOnly) ...[
            Row(
              children: [
                Expanded(
                  child: _buildModernAddButton(
                    icon: Icons.waves,
                    label: 'Ambiente',
                    color: ModernAudioColors.accentCyan,
                    onPressed: _mixerService.channelCount < MultiStreamSoundService.maxChannels
                        ? () => _showSoundPicker(SoundType.Ambiente)
                        : null,
                  ),
                ),
                SizedBox(width: isCompact ? 8 : 12),
                Expanded(
                  child: _buildModernAddButton(
                    icon: Icons.speaker,
                    label: 'Effekt',
                    color: ModernAudioColors.accentGreen,
                    onPressed: _mixerService.channelCount < MultiStreamSoundService.maxChannels
                        ? () => _showSoundPicker(SoundType.Effekt)
                        : null,
                  ),
                ),
              ],
            ),
            SizedBox(height: isCompact ? 8 : 12),
          ],
          
          // Counter
          if (_config.showChannelCounter)
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isCompact ? 8 : 12, 
                  vertical: isCompact ? 4 : 6
                ),
                decoration: BoxDecoration(
                  color: ModernAudioColors.surfaceLight,
                  borderRadius: BorderRadius.circular(isCompact ? 12 : 16),
                ),
                child: Text(
                  '${_mixerService.channelCount}/${MultiStreamSoundService.maxChannels} Kanäle',
                  style: TextStyle(
                    color: ModernAudioColors.textMuted,
                    fontSize: isCompact ? 10 : 12,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildModernAddButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    final isCompact = _config.compactMode;
    final isDisabled = onPressed == null;
    final verticalPadding = isCompact ? 10.0 : 14.0;
    
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        decoration: BoxDecoration(
          color: isDisabled ? ModernAudioColors.surfaceLight : color,
          borderRadius: BorderRadius.circular(isCompact ? 16 : 24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isDisabled ? ModernAudioColors.textMuted : ModernAudioColors.background,
              size: isCompact ? 16 : 20,
            ),
            SizedBox(width: isCompact ? 6 : 8),
            Text(
              label,
              style: TextStyle(
                color: isDisabled ? ModernAudioColors.textMuted : ModernAudioColors.background,
                fontSize: isCompact ? 12 : 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
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
          decoration: const BoxDecoration(
            color: ModernAudioColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
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