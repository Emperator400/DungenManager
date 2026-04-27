import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sound.dart';
import '../../services/multi_stream_sound_service.dart';
import '../../database/repositories/sound_model_repository.dart';
import '../../theme/app_theme.dart';
import 'sound_mixer_channel.dart';
import 'sound_picker_widget.dart';

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
  
  /// Optional: Gespeicherte Lautstärken der Sounds (Map von Sound-ID zu Lautstärke)
  final Map<String, double>? initialVolumes;
  
  /// Konfiguration für das Widget-Verhalten (überschreibt size wenn angegeben)
  final SoundMixerConfig? config;
  
  /// Callback wenn sich die Liste der aktiven Sounds ändert
  final Function(List<String> activeSoundIds)? onSoundsChanged;
  
  /// Callback wenn sich die Lautstärken der aktiven Sounds ändern
  final Function(Map<String, double> volumes)? onVolumesChanged;
  
  /// Wenn true, wird der SoundService beim dispose nicht disposed (für Preview-Modus)
  /// Sounds laufen dann weiter nach Schließen des Widgets
  final bool keepAlive;

  const SoundMixerWidget({
    super.key,
    this.size = SoundMixerSize.full,
    this.initialSoundIds,
    this.initialSounds,
    this.initialVolumes,
    this.config,
    this.onSoundsChanged,
    this.onVolumesChanged,
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
  Map<String, double> _lastVolumes = {};
  Timer? _volumeDebounce;

  @override
  void initState() {
    super.initState();
    _mixerService = MultiStreamSoundService();
    _mixerService.addListener(_checkVolumeChanges);
    _updateConfig();
    _initializeMixer();
  }

  /// Prüft, ob sich die Lautstärken geändert haben und triggert den Callback (mit Debounce)
  void _checkVolumeChanges() {
    if (widget.onVolumesChanged == null || _isDisposed) return;
    
    bool changed = false;
    final currentVolumes = <String, double>{};
    
    for (final channel in _mixerService.channels) {
      currentVolumes[channel.sound.id] = channel.volume;
      if (_lastVolumes[channel.sound.id] != channel.volume) {
        changed = true;
      }
    }
    
    if (changed || _lastVolumes.length != currentVolumes.length) {
      _lastVolumes = currentVolumes;
      
      _volumeDebounce?.cancel();
      _volumeDebounce = Timer(const Duration(milliseconds: 500), () {
        if (!_isDisposed) widget.onVolumesChanged!(currentVolumes);
      });
    }
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
    
    // Prüfen ob sich die initialSoundIds geändert haben (wichtig bei asynchronem Laden aus der Datenbank)
    if (!_stringListEquals(oldWidget.initialSoundIds, widget.initialSoundIds)) {
      _updateInitialSoundIds();
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
  
  /// Prüft ob zwei Listen von Strings (IDs) gleich sind
  bool _stringListEquals(List<String>? a, List<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  
  /// Aktualisiert die Sounds wenn sich initialSounds ändert — per Diff, nicht clearAll.
  ///
  /// clearAll() würde laufende Sounds stoppen (Feedback-Schleife: onSoundsChanged
  /// → DB-Save → ViewModel-Reload → notifyListeners → didUpdateWidget → clearAll).
  /// Stattdessen: neue IDs hinzufügen, weggefallene entfernen, laufende in Ruhe lassen.
  Future<void> _updateInitialSounds() async {
    if (_isDisposed) return;

    final newIds = widget.initialSounds?.map((s) => s.id).toSet() ?? {};
    final currentIds = _mixerService.channels.map((c) => c.sound.id).toSet();

    // Entfernte Sounds aus dem Mixer löschen
    for (final id in currentIds.difference(newIds)) {
      if (_isDisposed) return;
      await _mixerService.removeSound(id);
    }

    // Neue Sounds hinzufügen (bereits vorhandene überspringen)
    for (final sound in widget.initialSounds ?? <Sound>[]) {
      if (_isDisposed) return;
      if (!_mixerService.hasSound(sound.id) && sound.isValid) {
        await _mixerService.addSound(
          sound,
          volume: widget.initialVolumes?[sound.id] ?? 0.8,
          isLooping: sound.soundType == SoundType.Ambiente,
          autoPlay: false,
        );
      }
    }

    if (_isDisposed) return;
    setState(() {});
  }

  /// Aktualisiert die Sounds wenn sich initialSoundIds ändert — per Diff, nicht clearAll.
  Future<void> _updateInitialSoundIds() async {
    if (_isDisposed) return;

    final soundRepo = context.read<SoundModelRepository>();
    final newIds = widget.initialSoundIds?.toSet() ?? {};
    final currentIds = _mixerService.channels.map((c) => c.sound.id).toSet();

    // Entfernte Sounds aus dem Mixer löschen
    for (final id in currentIds.difference(newIds)) {
      if (_isDisposed) return;
      await _mixerService.removeSound(id);
    }

    // Neue Sounds hinzufügen
    if (newIds.isNotEmpty) {
      for (final soundId in newIds.difference(currentIds)) {
        if (_isDisposed) return;
        try {
          final sound = await soundRepo.findById(soundId);
          if (_isDisposed) return;
          if (sound != null && sound.isValid) {
            await _mixerService.addSound(
              sound,
              volume: widget.initialVolumes?[soundId] ?? 0.8,
              isLooping: sound.soundType == SoundType.Ambiente,
              autoPlay: false,
            );
          }
        } catch (e) {
          debugPrint('Fehler beim Nachladen des Sounds $soundId: $e');
        }
      }
    }

    if (_isDisposed) return;
    setState(() {});
  }

  Future<void> _initializeMixer() async {
    final soundRepo = context.read<SoundModelRepository>();

    // Direkt übergebene Sound-Objekte laden
    if (widget.initialSounds != null && widget.initialSounds!.isNotEmpty) {
      for (final sound in widget.initialSounds!) {
        if (_isDisposed) return; // Prüfen ob Widget noch existiert
        if (sound.isValid) {
          await _mixerService.addSound(
            sound,
            volume: widget.initialVolumes?[sound.id] ?? 0.8,
            isLooping: sound.soundType == SoundType.Ambiente,
            autoPlay: false,
          );
        }
      }
    }

    // Sound-IDs laden falls vorhanden
    if (widget.initialSoundIds != null && widget.initialSoundIds!.isNotEmpty) {
      
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
              volume: widget.initialVolumes?[soundId] ?? 0.8,
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
    _volumeDebounce?.cancel();
    _mixerService.removeListener(_checkVolumeChanges);
    
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
    final C = context.appColors;
    if (!_isInitialized) {
      return Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: C.green),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _mixerService,
      builder: (context, child) {
        if (_config.maxHeight != null) {
          return ConstrainedBox(
            constraints: BoxConstraints(maxHeight: _config.maxHeight!),
            child: _buildContent(C),
          );
        }
        return _buildContent(C);
      },
    );
  }

  Widget _buildContent(AppColorsExtension C) {
    final isCompact = _config.compactMode;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_config.showHeader)
          _buildMixerHeader(C, isCompact),

        if (_config.showMasterVolume) ...[
          if (_config.showHeader) SizedBox(height: isCompact ? 8 : 12),
          _buildMasterVolumeRow(C, isCompact),
        ],

        if (_config.showDivider && _config.showMasterVolume && _mixerService.channels.isNotEmpty)
          Padding(
            padding: EdgeInsets.symmetric(vertical: isCompact ? 6 : 10),
            child: Divider(height: 1, thickness: 1, color: C.border),
          ),

        if (_mixerService.channels.isEmpty)
          _buildEmptyState(C, isCompact)
        else
          _buildChannelsList(C),

        if (_config.showAddButtons && !_config.readOnly) ...[
          SizedBox(height: isCompact ? 8 : 12),
          _buildAddButtons(C, isCompact),
        ],

        if (_config.showStopAllButton &&
            !_config.showAddButtons &&
            _mixerService.channels.isNotEmpty) ...[
          SizedBox(height: isCompact ? 6 : 10),
          _buildStopAllRow(C, isCompact),
        ],

        if (_config.showChannelCounter) ...[
          SizedBox(height: isCompact ? 6 : 10),
          Center(
            child: Text(
              '${_mixerService.channelCount}/${MultiStreamSoundService.maxChannels} Kanäle',
              style: TextStyle(fontSize: isCompact ? 10 : 12, color: C.textSoft),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMixerHeader(AppColorsExtension C, bool isCompact) {
    final playingCount = _mixerService.playingCount;
    final iconSize = isCompact ? 32.0 : 40.0;

    return Row(
      children: [
        Container(
          width: iconSize,
          height: iconSize,
          decoration: BoxDecoration(
            color: C.greenSoft,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: C.green.withValues(alpha: 0.4)),
          ),
          child: Icon(Icons.graphic_eq, color: C.green, size: isCompact ? 16 : 20),
        ),
        SizedBox(width: isCompact ? 8 : 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sound Mixer',
                style: TextStyle(
                  fontSize: isCompact ? 12 : 14,
                  fontWeight: FontWeight.w500,
                  color: C.text,
                ),
              ),
              Text(
                '$playingCount von ${_mixerService.channelCount} spielen',
                style: TextStyle(fontSize: 10, color: C.textSoft),
              ),
            ],
          ),
        ),
        if (_config.showStopAllButton && _mixerService.channels.isNotEmpty)
          GestureDetector(
            onTap: _mixerService.stopAll,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: C.bgHover,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: C.border),
              ),
              child: Icon(Icons.stop, color: C.textMid, size: 14),
            ),
          ),
      ],
    );
  }

  Widget _buildMasterVolumeRow(AppColorsExtension C, bool isCompact) {
    return Row(
      children: [
        Icon(
          _mixerService.masterVolume == 0 ? Icons.volume_off : Icons.volume_up,
          color: _mixerService.masterVolume > 0 ? C.green : C.textSoft,
          size: 13,
        ),
        const SizedBox(width: 6),
        Text(
          'Master',
          style: TextStyle(fontSize: 11, color: C.textMid),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: C.green,
              inactiveTrackColor: C.border,
              thumbColor: C.text,
              overlayColor: C.green.withValues(alpha: 0.15),
            ),
            child: Slider(
              value: _mixerService.masterVolume,
              min: 0.0,
              max: 1.0,
              onChanged: _mixerService.setMasterVolume,
            ),
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 30,
          child: Text(
            '${(_mixerService.masterVolume * 100).toInt()}%',
            style: TextStyle(fontSize: 10, color: C.textSoft),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(AppColorsExtension C, bool isCompact) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isCompact ? 12 : 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.music_note_outlined, color: C.textSoft, size: isCompact ? 20 : 28),
          SizedBox(height: isCompact ? 4 : 8),
          Text(
            'Keine Sounds aktiv',
            style: TextStyle(fontSize: isCompact ? 11 : 13, color: C.textSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildChannelsList(AppColorsExtension C) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: _mixerService.channels.map((channel) => SoundMixerChannel(
        channel: channel,
        mixerService: _mixerService,
        config: _config,
        onRemove: _config.readOnly ? null : () => _removeChannel(channel.id),
      )).toList(),
    );
  }

  Widget _buildAddButtons(AppColorsExtension C, bool isCompact) {
    final canAdd = _mixerService.channelCount < MultiStreamSoundService.maxChannels;
    return Row(
      children: [
        Expanded(child: _buildAddButton(
          label: 'Ambiente',
          icon: Icons.waves,
          color: C.green,
          onTap: canAdd ? () => _showSoundPicker(SoundType.Ambiente) : null,
          C: C,
        )),
        const SizedBox(width: 8),
        Expanded(child: _buildAddButton(
          label: 'Effekt',
          icon: Icons.music_note,
          color: C.accent,
          onTap: canAdd ? () => _showSoundPicker(SoundType.Effekt) : null,
          C: C,
        )),
      ],
    );
  }

  Widget _buildAddButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
    required AppColorsExtension C,
  }) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: disabled ? C.bgHover : color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: disabled ? C.border : color.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: disabled ? C.textSoft : color, size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: disabled ? C.textSoft : color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStopAllRow(AppColorsExtension C, bool isCompact) {
    return GestureDetector(
      onTap: _mixerService.stopAll,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: isCompact ? 6 : 8),
        decoration: BoxDecoration(
          color: C.bgHover,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: C.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.stop, color: C.textMid, size: 13),
            const SizedBox(width: 5),
            Text('Alle stoppen', style: TextStyle(fontSize: 12, color: C.textMid)),
          ],
        ),
      ),
    );
  }

  Future<void> _showSoundPicker(SoundType filterType) async {
    final savedSoundIds = widget.initialSoundIds ?? [];
    final activeSoundIds = _mixerService.channels.map((c) => c.sound.id).toList();
    final C = context.appColors;

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
            color: C.bgPanel,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: SoundPickerWidget(
            initiallySelectedSoundIds: savedSoundIds,
            onSelectionChanged: (_) {},
          ),
        ),
      ),
    );

    if (result != null) {
      widget.onSoundsChanged?.call(result);
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
            volume: widget.initialVolumes?[soundId] ?? 0.8,
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
    
    // Sicherstellen, dass die ID wirklich aus der Liste gefiltert ist, bevor wir speichern
    final remainingIds = _mixerService.channels
        .map((c) => c.sound.id)
        .where((id) => id != channelId)
        .toList();
        
    widget.onSoundsChanged?.call(remainingIds);
  }
}