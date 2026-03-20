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
/// - Entfernen-Button
class SoundMixerChannel extends StatefulWidget {
  final SoundChannel channel;
  final MultiStreamSoundService mixerService;
  final VoidCallback onRemove;

  const SoundMixerChannel({
    super.key,
    required this.channel,
    required this.mixerService,
    required this.onRemove,
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
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
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
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                  const SizedBox(width: 4),
                  
                  // Remove Button
                  _buildRemoveButton(),
                ],
              ),
              
              const SizedBox(height: 6),
              
              // Zeitdarstellung und Fortschrittsbalken
              _buildTimeDisplay(channel),
              
              const SizedBox(height: 6),
              
              // Lautstärke-Slider
              Row(
                children: [
                  Icon(
                    channel.volume == 0 ? Icons.volume_off : Icons.volume_up,
                    color: DnDTheme.mysticalPurple,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: SliderTheme(
                      data: SliderThemeData(
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
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
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
    return GestureDetector(
      onTap: () => widget.mixerService.togglePlayPause(channel.id),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: channel.isPlaying 
                ? DnDTheme.ancientGold.withValues(alpha: 0.4)
                : DnDTheme.successGreen.withValues(alpha: 0.3),
            endColor: channel.isPlaying 
                ? DnDTheme.ancientGold.withValues(alpha: 0.2)
                : DnDTheme.successGreen.withValues(alpha: 0.1),
          ),
          borderRadius: BorderRadius.circular(6),
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
          size: 18,
        ),
      ),
    );
  }

  /// Stop Button
  Widget _buildStopButton(SoundChannel channel) {
    return GestureDetector(
      onTap: () => widget.mixerService.stopSound(channel.id),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: DnDTheme.errorRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: DnDTheme.errorRed.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: const Icon(
          Icons.stop,
          color: DnDTheme.errorRed,
          size: 16,
        ),
      ),
    );
  }

  /// Loop Toggle Button
  Widget _buildLoopButton(SoundChannel channel) {
    return GestureDetector(
      onTap: () => widget.mixerService.setChannelLooping(channel.id, !channel.isLooping),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: channel.isLooping 
              ? DnDTheme.arcaneBlue.withValues(alpha: 0.3)
              : DnDTheme.slateGrey.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(6),
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
          size: 16,
        ),
      ),
    );
  }

  /// Remove Button
  Widget _buildRemoveButton() {
    return GestureDetector(
      onTap: widget.onRemove,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: DnDTheme.errorRed.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.close,
          color: Colors.white54,
          size: 14,
        ),
      ),
    );
  }
}