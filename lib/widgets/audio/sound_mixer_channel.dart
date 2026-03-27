import 'package:flutter/material.dart';
import '../../services/multi_stream_sound_service.dart';
import '../../theme/dnd_theme.dart';

/// Widget für einen einzelnen Sound-Kanal im Mixer
/// 
/// Zeigt:
/// - Play/Pause/Stop Buttons
/// - Lautstärke-Slider
/// - Loop-Toggle
/// - Sound-Name
/// - Zeitdarstellung (Position / Dauer)
/// - Skip Forward/Backward Buttons (optional)
/// - Entfernen-Button (optional)
/// - Speed-Control (optional)
/// - Großer zentraler Play-Button (optional für Preview-Modus)
class SoundMixerChannel extends StatefulWidget {
  final SoundChannel channel;
  final MultiStreamSoundService mixerService;
  final VoidCallback? onRemove;
  final bool compactMode;
  
  /// Zeigt Skip-Buttons (±10 Sekunden) an
  final bool showSkipButtons;
  
  /// Zeigt detaillierte Sound-Info (Beschreibung, Kategorie) an
  final bool showDetailedInfo;
  
  /// Zeigt Speed-Control (0.5x - 2.0x) an
  final bool showSpeedControl;
  
  /// Zeigt großen zentralen Play-Button für bessere Usability im Preview-Modus
  final bool showLargePlayButton;

  const SoundMixerChannel({
    super.key,
    required this.channel,
    required this.mixerService,
    this.onRemove,
    this.compactMode = false,
    this.showSkipButtons = false,
    this.showDetailedInfo = false,
    this.showSpeedControl = false,
    this.showLargePlayButton = false,
  });

  @override
  State<SoundMixerChannel> createState() => _SoundMixerChannelState();
}

class _SoundMixerChannelState extends State<SoundMixerChannel> {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.mixerService,
      builder: (context, child) {
        final channel = widget.mixerService.getChannel(widget.channel.id);
        if (channel == null) return const SizedBox.shrink();

        return Container(
          margin: EdgeInsets.only(bottom: widget.compactMode ? 4 : 8),
          padding: EdgeInsets.all(widget.compactMode ? 6 : 8),
          decoration: BoxDecoration(
            gradient: DnDTheme.getMysticalGradient(
              startColor: DnDTheme.slateGrey.withValues(alpha: 0.8),
              endColor: DnDTheme.stoneGrey.withValues(alpha: 0.6),
            ),
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            border: Border.all(
              color: channel.isPlaying 
                  ? DnDTheme.successGreen.withValues(alpha: 0.5)
                  : DnDTheme.mysticalPurple.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header mit Name und Buttons
              Row(
                children: [
                  // Play/Pause Button
                  _buildPlayPauseButton(channel),
                  const SizedBox(width: 6),
                  
                  // Stop Button
                  _buildStopButton(channel),
                  const SizedBox(width: 6),
                  
                  // Sound-Name
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          channel.sound.name,
                          style: DnDTheme.bodyText2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: widget.compactMode ? 10 : 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (!widget.compactMode)
                          Text(
                            channel.sound.soundTypeDisplayName,
                            style: DnDTheme.bodyText2.copyWith(
                              color: Colors.white54,
                              fontSize: 9,
                            ),
                          ),
                      ],
                    ),
                  ),
                  
                  // Loop Toggle
                  _buildLoopButton(channel),
                  
                  // Remove Button (nur wenn onRemove gesetzt ist)
                  if (widget.onRemove != null) ...[
                    const SizedBox(width: 4),
                    _buildRemoveButton(),
                  ],
                ],
              ),
              
              // Detaillierte Sound-Info (optional)
              if (widget.showDetailedInfo && !widget.compactMode) ...[
                const SizedBox(height: 4),
                _buildDetailedInfo(channel),
              ],
              
              // Zeitdarstellung und Fortschrittsbalken (nur im nicht-kompakten Modus)
              if (!widget.compactMode) ...[
                const SizedBox(height: 6),
                _buildTimeDisplay(channel),
              ],
              
              // Skip-Buttons (optional, nur im nicht-kompakten Modus)
              if (widget.showSkipButtons && !widget.compactMode) ...[
                const SizedBox(height: 4),
                _buildSkipButtons(channel),
              ],
              
              // Speed-Control (optional, nur im nicht-kompakten Modus)
              if (widget.showSpeedControl && !widget.compactMode) ...[
                const SizedBox(height: 6),
                _buildSpeedControl(channel),
              ],
              
              const SizedBox(height: 6),
              
              // Lautstärke-Slider
              _buildVolumeSlider(channel),
              
              // Großer zentraler Play-Button (optional für Preview-Modus)
              if (widget.showLargePlayButton && !widget.compactMode) ...[
                const SizedBox(height: 12),
                _buildLargePlayButton(channel),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Lautstärke-Slider
  Widget _buildVolumeSlider(SoundChannel channel) {
    final isCompact = widget.compactMode;
    
    return Row(
      children: [
        Icon(
          channel.volume == 0 ? Icons.volume_off : Icons.volume_up,
          color: DnDTheme.mysticalPurple,
          size: isCompact ? 12 : 14,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: isCompact ? 2 : 3,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: isCompact ? 4 : 6),
              overlayShape: RoundSliderOverlayShape(overlayRadius: isCompact ? 8 : 10),
              activeTrackColor: DnDTheme.mysticalPurple,
              inactiveTrackColor: DnDTheme.slateGrey.withValues(alpha: 0.5),
              thumbColor: DnDTheme.ancientGold,
            ),
            child: Slider(
              value: channel.volume,
              min: 0.0,
              max: 1.0,
              onChanged: (value) {
                widget.mixerService.setChannelVolume(channel.id, value);
              },
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '${(channel.volume * 100).toInt()}%',
          style: DnDTheme.bodyText2.copyWith(
            color: Colors.white70,
            fontSize: isCompact ? 8 : 9,
          ),
        ),
      ],
    );
  }

  /// Zeitdarstellung mit Fortschrittsbalken (klickbar/ziehbar)
  Widget _buildTimeDisplay(SoundChannel channel) {
    final position = channel.currentPosition;
    final duration = channel.totalDuration;
    
    // Fortschritt berechnen (0.0 bis 1.0)
    double progress = 0.0;
    if (duration != null && duration.inMilliseconds > 0) {
      progress = (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    }

    return Column(
      children: [
        // Zeit-Text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(position),
              style: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.ancientGold,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Loop-Indikator wenn aktiv
            if (channel.isLooping)
              Row(
                children: [
                  Icon(
                    Icons.loop,
                    color: DnDTheme.arcaneBlue,
                    size: 10,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    'Loop',
                    style: DnDTheme.bodyText2.copyWith(
                      color: DnDTheme.arcaneBlue,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            Text(
              duration != null ? _formatDuration(duration) : '--:--',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        // Klickbarer Fortschrittsbalken
        _buildSeekableProgressBar(channel, progress, duration),
      ],
    );
  }

  /// Klickbarer/ziehbarer Fortschrittsbalken
  Widget _buildSeekableProgressBar(SoundChannel channel, double progress, Duration? duration) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        
        return GestureDetector(
          onTapDown: (details) => _handleSeek(details, channel, duration, barWidth),
          onHorizontalDragUpdate: (details) => _handleDragSeek(details, channel, duration, barWidth),
          child: Container(
            height: 16, // Größer für bessere Touch-Zielgröße
            width: double.infinity,
            color: Colors.transparent, // Für Touch-Erkennung
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                // Hintergrund-Balken
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: DnDTheme.slateGrey.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Fortschritts-Balken
                Container(
                  height: 3,
                  width: barWidth * progress,
                  decoration: BoxDecoration(
                    color: channel.isPlaying ? DnDTheme.successGreen : DnDTheme.mysticalPurple,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Position-Indicator (kleiner Kreis) - korrekt positioniert
                Positioned(
                  left: (barWidth * progress) - 5, // 5 = halbe Breite des Indikators
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: DnDTheme.ancientGold,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Verarbeitet Tap auf Fortschrittsbalken
  void _handleSeek(TapDownDetails details, SoundChannel channel, Duration? duration, double barWidth) {
    if (duration == null || duration.inMilliseconds <= 0) return;
    
    final seekProgress = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
    final seekPosition = Duration(
      milliseconds: (duration.inMilliseconds * seekProgress).round(),
    );
    
    widget.mixerService.seekTo(channel.id, seekPosition);
  }

  /// Verarbeitet Ziehen auf Fortschrittsbalken
  void _handleDragSeek(DragUpdateDetails details, SoundChannel channel, Duration? duration, double barWidth) {
    if (duration == null || duration.inMilliseconds <= 0) return;
    
    final seekProgress = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
    final seekPosition = Duration(
      milliseconds: (duration.inMilliseconds * seekProgress).round(),
    );
    
    widget.mixerService.seekTo(channel.id, seekPosition);
  }

  /// Formatiert eine Duration als mm:ss oder hh:mm:ss
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    } else {
      return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
  }

  /// Play/Pause Button
  Widget _buildPlayPauseButton(SoundChannel channel) {
    final size = widget.compactMode ? 26.0 : 32.0;
    final iconSize = widget.compactMode ? 14.0 : 18.0;
    
    return GestureDetector(
      onTap: () => widget.mixerService.togglePlayPause(channel.id),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: channel.isPlaying 
                ? DnDTheme.ancientGold.withValues(alpha: 0.4)
                : DnDTheme.successGreen.withValues(alpha: 0.3),
            endColor: channel.isPlaying 
                ? DnDTheme.ancientGold.withValues(alpha: 0.2)
                : DnDTheme.successGreen.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(widget.compactMode ? 4 : 6),
          border: Border.all(
            color: channel.isPlaying 
                ? DnDTheme.ancientGold.withValues(alpha: 0.6)
                : DnDTheme.successGreen.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Icon(
          channel.isPlaying ? Icons.pause : Icons.play_arrow,
          color: channel.isPlaying ? DnDTheme.ancientGold : DnDTheme.successGreen,
          size: iconSize,
        ),
      ),
    );
  }

  /// Stop Button
  Widget _buildStopButton(SoundChannel channel) {
    final size = widget.compactMode ? 22.0 : 28.0;
    final iconSize = widget.compactMode ? 12.0 : 16.0;
    
    return GestureDetector(
      onTap: () => widget.mixerService.stopSound(channel.id),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: DnDTheme.errorRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(widget.compactMode ? 4 : 6),
          border: Border.all(
            color: DnDTheme.errorRed.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.stop,
          color: DnDTheme.errorRed,
          size: iconSize,
        ),
      ),
    );
  }

  /// Loop Toggle Button
  Widget _buildLoopButton(SoundChannel channel) {
    final size = widget.compactMode ? 22.0 : 28.0;
    final iconSize = widget.compactMode ? 12.0 : 16.0;
    
    return GestureDetector(
      onTap: () => widget.mixerService.setChannelLooping(channel.id, !channel.isLooping),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: channel.isLooping 
              ? DnDTheme.arcaneBlue.withValues(alpha: 0.3)
              : DnDTheme.slateGrey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(widget.compactMode ? 4 : 6),
          border: Border.all(
            color: channel.isLooping 
                ? DnDTheme.arcaneBlue.withValues(alpha: 0.6)
                : Colors.white24,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.loop,
          color: channel.isLooping ? DnDTheme.arcaneBlue : Colors.white54,
          size: iconSize,
        ),
      ),
    );
  }

  /// Remove Button
  Widget _buildRemoveButton() {
    final size = widget.compactMode ? 20.0 : 24.0;
    final iconSize = widget.compactMode ? 12.0 : 14.0;
    
    return GestureDetector(
      onTap: widget.onRemove,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: DnDTheme.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.close,
          color: Colors.white54,
          size: iconSize,
        ),
      ),
    );
  }

  /// Detaillierte Sound-Info (Beschreibung, Kategorie)
  Widget _buildDetailedInfo(SoundChannel channel) {
    final sound = channel.sound;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Beschreibung
        if (sound.description.isNotEmpty) ...[
          Text(
            sound.description,
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontSize: 9,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        // Kategorie
        if (sound.categoryId != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.category,
                color: DnDTheme.mysticalPurple,
                size: 10,
              ),
              const SizedBox(width: 4),
              Text(
                sound.categoryId!,
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white54,
                  fontSize: 8,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Skip-Buttons (±10 Sekunden)
  Widget _buildSkipButtons(SoundChannel channel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Skip Backward (-10s)
        _buildSkipButton(
          icon: Icons.replay_10,
          color: DnDTheme.arcaneBlue,
          onPressed: () => _skipBackward(channel),
        ),
        
        const SizedBox(width: 16),
        
        // Skip Forward (+10s)
        _buildSkipButton(
          icon: Icons.forward_10,
          color: DnDTheme.arcaneBlue,
          onPressed: () => _skipForward(channel),
        ),
      ],
    );
  }

  /// Einzelner Skip-Button
  Widget _buildSkipButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: color.withValues(alpha: 0.3),
            endColor: color.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: 20,
        ),
      ),
    );
  }

  /// Springt 10 Sekunden zurück
  void _skipBackward(SoundChannel channel) {
    final duration = channel.totalDuration;
    if (duration == null) return;
    
    final newPosition = channel.currentPosition - const Duration(seconds: 10);
    final targetPosition = newPosition > Duration.zero ? newPosition : Duration.zero;
    widget.mixerService.seekTo(channel.id, targetPosition);
  }

  /// Springt 10 Sekunden vor
  void _skipForward(SoundChannel channel) {
    final duration = channel.totalDuration;
    if (duration == null) return;
    
    final newPosition = channel.currentPosition + const Duration(seconds: 10);
    final targetPosition = newPosition < duration ? newPosition : duration;
    widget.mixerService.seekTo(channel.id, targetPosition);
  }

  /// Speed-Control (0.5x - 2.0x)
  Widget _buildSpeedControl(SoundChannel channel) {
    // Verfügbare Geschwindigkeiten
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentSpeed = channel.playbackSpeed ?? 1.0;
    
    return Row(
      children: [
        Icon(
          Icons.speed,
          color: DnDTheme.ancientGold,
          size: 14,
        ),
        const SizedBox(width: 6),
        Text(
          'Speed:',
          style: DnDTheme.bodyText2.copyWith(
            color: Colors.white70,
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: speeds.map((speed) {
              final isSelected = (currentSpeed - speed).abs() < 0.01;
              
              return GestureDetector(
                onTap: () => widget.mixerService.setChannelSpeed(channel.id, speed),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? DnDTheme.ancientGold.withValues(alpha: 0.3)
                        : DnDTheme.slateGrey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isSelected 
                          ? DnDTheme.ancientGold.withValues(alpha: 0.6)
                          : Colors.white24,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    '${speed}x',
                    style: DnDTheme.bodyText2.copyWith(
                      color: isSelected ? DnDTheme.ancientGold : Colors.white70,
                      fontSize: 10,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Großer zentraler Play-Button für bessere Usability im Preview-Modus
  Widget _buildLargePlayButton(SoundChannel channel) {
    return Center(
      child: GestureDetector(
        onTap: () => widget.mixerService.togglePlayPause(channel.id),
        child: Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: DnDTheme.getMysticalGradient(
              startColor: channel.isPlaying 
                  ? DnDTheme.ancientGold.withValues(alpha: 0.5)
                  : DnDTheme.successGreen.withValues(alpha: 0.5),
              endColor: channel.isPlaying 
                  ? DnDTheme.ancientGold.withValues(alpha: 0.3)
                  : DnDTheme.successGreen.withValues(alpha: 0.3),
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: channel.isPlaying 
                  ? DnDTheme.ancientGold.withValues(alpha: 0.8)
                  : DnDTheme.successGreen.withValues(alpha: 0.8),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: channel.isPlaying 
                    ? DnDTheme.ancientGold.withValues(alpha: 0.3)
                    : DnDTheme.successGreen.withValues(alpha: 0.3),
                blurRadius: 12,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(
            channel.isPlaying ? Icons.pause : Icons.play_arrow,
            color: channel.isPlaying ? DnDTheme.ancientGold : DnDTheme.successGreen,
            size: 36,
          ),
        ),
      ),
    );
  }
}
