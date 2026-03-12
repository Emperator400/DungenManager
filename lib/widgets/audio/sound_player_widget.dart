import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/sound.dart';
import '../../services/sound_service.dart';
import '../../theme/dnd_theme.dart';

/// Wiederverwendbares Sound-Player-Widget
/// 
/// Bietet eine vollständige Sound-Player-Oberfläche mit:
/// - Play/Pause/Stop-Steuerung
/// - Lautstärkeregler
/// - Fortschrittsanzeige
/// - Position-Sprung (Seek)
/// - Lautsprecher-Icon
class SoundPlayerWidget extends StatefulWidget {
  final Sound sound;
  final VoidCallback? onClose;
  final bool showCloseButton;
  final bool compactMode;

  const SoundPlayerWidget({
    super.key,
    required this.sound,
    this.onClose,
    this.showCloseButton = true,
    this.compactMode = false,
  });

  @override
  State<SoundPlayerWidget> createState() => _SoundPlayerWidgetState();
}

class _SoundPlayerWidgetState extends State<SoundPlayerWidget> {
  bool _isPlaying = false;
  bool _isLoading = false;
  double _volume = 0.8;
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration?>? _durationSubscription;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }

  /// Lädt initiale Daten und startet Streams
  Future<void> _loadInitialData() async {
    // Aktuellen Playback-Status prüfen
    final isPlaying = await SoundService.isPlaying();
    if (mounted) {
      setState(() {
        _isPlaying = isPlaying;
      });
    }

    // Position-Stream abonnieren
    _positionSubscription = SoundService.getPositionStream().listen((position) {
      if (mounted) {
        setState(() {
          _currentPosition = position;
        });
      }
    });

    // Duration-Stream abonnieren
    _durationSubscription = SoundService.getDurationStream().listen((duration) {
      if (mounted && duration != null) {
        setState(() {
          _totalDuration = duration;
        });
      }
    });
  }

  /// Spielt den Sound ab
  Future<void> _playSound() async {
    setState(() {
      _isLoading = true;
    });

    final success = await SoundService.playSound(widget.sound.filePath);
    
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isPlaying = success;
      });
    }
  }

  /// Pausiert den Sound
  Future<void> _pauseSound() async {
    await SoundService.pauseSound();
    if (mounted) {
      setState(() {
        _isPlaying = false;
      });
    }
  }

  /// Stoppt den Sound
  Future<void> _stopSound() async {
    await SoundService.stopSound();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentPosition = Duration.zero;
      });
    }
  }

  /// Setzt die Lautstärke
  Future<void> _setVolume(double volume) async {
    setState(() {
      _volume = volume;
    });
    await SoundService.setVolume(volume);
  }

  /// Springt zur angegebenen Position
  Future<void> _seekToPosition(double fraction) async {
    final position = Duration(
      milliseconds: (_totalDuration.inMilliseconds * fraction).round(),
    );
    await SoundService.seekTo(position);
  }

  /// Formatiert eine Duration für die Anzeige
  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.compactMode) {
      return _buildCompactPlayer();
    }

    return _buildFullPlayer();
  }

  /// Vollständiger Player mit allen Steuerelementen
  Widget _buildFullPlayer() {
    return Container(
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: DnDTheme.mysticalPurple.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          _buildHeader(),

          // Sound-Info
          _buildSoundInfo(),

          const SizedBox(height: 12),

          // Fortschrittsbalken
          _buildProgressBar(),

          const SizedBox(height: 12),

          // Steuerung
          _buildControls(),

          const SizedBox(height: 8),

          // Lautstärke
          _buildVolumeControl(),

          if (widget.showCloseButton) ...[
            const SizedBox(height: 8),
            _buildCloseButton(),
          ],
        ],
      ),
    );
  }

  /// Kompakter Player für Platzersparnis
  Widget _buildCompactPlayer() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.sm),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Play/Pause Button
          _buildPlayPauseButton(compact: true),

          const SizedBox(width: 8),

          // Sound-Name
          Expanded(
            child: Text(
              widget.sound.name,
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white,
                fontSize: 9,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Lautstärke-Slider
          SizedBox(
            width: 80,
            child: Slider(
              value: _volume,
              min: 0.0,
              max: 1.0,
              onChanged: _setVolume,
              activeColor: DnDTheme.mysticalPurple,
              thumbColor: DnDTheme.ancientGold,
            ),
          ),

          // Stop Button
          if (widget.showCloseButton)
            IconButton(
              icon: const Icon(Icons.stop, color: Colors.white70, size: 18),
              onPressed: _stopSound,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 32,
                minHeight: 32,
              ),
            ),
        ],
      ),
    );
  }

  /// Header mit Sound-Icon und optional Close-Button
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DnDTheme.md, vertical: DnDTheme.sm),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.mysticalPurple.withValues(alpha: 0.8),
          endColor: DnDTheme.mysticalPurple.withValues(alpha: 0.4),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DnDTheme.radiusMedium - 2),
          topRight: Radius.circular(DnDTheme.radiusMedium - 2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.music_note,
            color: DnDTheme.ancientGold,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Sound Player',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Sound-Informationen
  Widget _buildSoundInfo() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DnDTheme.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.sound.name,
            style: DnDTheme.bodyText1.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.sound.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.sound.description,
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white70,
                fontSize: 9,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (widget.sound.categoryId != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: DnDTheme.mysticalPurple,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  widget.sound.categoryId!,
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white70,
                    fontSize: 8,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Fortschrittsbalken
  Widget _buildProgressBar() {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DnDTheme.md),
      child: Column(
        children: [
          // Slider für Position
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: DnDTheme.mysticalPurple,
              inactiveTrackColor: DnDTheme.slateGrey.withValues(alpha: 0.5),
              thumbColor: DnDTheme.ancientGold,
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: _seekToPosition,
            ),
          ),

          // Zeit-Anzeige
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white70,
                  fontSize: 9,
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white70,
                  fontSize: 9,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Wiedergabe-Steuerung
  Widget _buildControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DnDTheme.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Skip Backward Button
          _buildControlButton(
            icon: Icons.replay_10,
            color: DnDTheme.arcaneBlue,
            onPressed: _skipBackward,
          ),

          // Play/Pause Button
          _buildPlayPauseButton(),

          // Stop Button
          _buildControlButton(
            icon: Icons.stop,
            color: DnDTheme.errorRed,
            onPressed: _stopSound,
          ),

          // Skip Forward Button
          _buildControlButton(
            icon: Icons.forward_10,
            color: DnDTheme.arcaneBlue,
            onPressed: _skipForward,
          ),
        ],
      ),
    );
  }

  /// Springt 10 Sekunden zurück
  Future<void> _skipBackward() async {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    final targetPosition = newPosition > Duration.zero ? newPosition : Duration.zero;
    await SoundService.seekTo(targetPosition);
  }

  /// Springt 10 Sekunden vor
  Future<void> _skipForward() async {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    final targetPosition = newPosition < _totalDuration ? newPosition : _totalDuration;
    await SoundService.seekTo(targetPosition);
  }

  /// Play/Pause Button
  Widget _buildPlayPauseButton({bool compact = false}) {
    if (_isLoading) {
      return _buildControlButton(
        icon: Icons.hourglass_empty,
        color: DnDTheme.mysticalPurple,
        onPressed: null,
      );
    }

    return _buildControlButton(
      icon: _isPlaying ? Icons.pause : Icons.play_arrow,
      color: _isPlaying ? DnDTheme.ancientGold : DnDTheme.successGreen,
      onPressed: _isPlaying ? _pauseSound : _playSound,
      size: compact ? 32 : 48,
    );
  }

  /// Generischer Steuerungs-Button
  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    VoidCallback? onPressed,
    double size = 40,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: color.withValues(alpha: 0.3),
          endColor: color.withValues(alpha: 0.1),
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: IconButton(
        icon: Icon(icon, color: color, size: size * 0.5),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }

  /// Lautstärkeregler
  Widget _buildVolumeControl() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DnDTheme.md),
      child: Row(
        children: [
          Icon(
            _volume == 0.0 ? Icons.volume_off : Icons.volume_up,
            color: DnDTheme.mysticalPurple,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                activeTrackColor: DnDTheme.mysticalPurple,
                inactiveTrackColor: DnDTheme.slateGrey.withValues(alpha: 0.5),
                thumbColor: DnDTheme.ancientGold,
              ),
              child: Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                divisions: 20,
                onChanged: _setVolume,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '${(_volume * 100).toInt()}%',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  /// Close Button
  Widget _buildCloseButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DnDTheme.md),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: widget.onClose,
          icon: const Icon(Icons.close, size: 16),
          label: const Text('Schließen'),
          style: ElevatedButton.styleFrom(
            backgroundColor: DnDTheme.stoneGrey,
            foregroundColor: Colors.white70,
            padding: const EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }
}