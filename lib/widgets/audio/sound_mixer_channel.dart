import 'package:flutter/material.dart';
import '../../models/sound.dart';
import '../../services/multi_stream_sound_service.dart';
import 'sound_mixer_widget.dart';

/// Widget für einen einzelnen Sound-Kanal im Mixer
/// 
/// Zeigt basierend auf der [SoundMixerConfig]:
/// - Play/Pause/Stop Buttons
/// - Lautstärke-Slider
/// - Loop-Toggle (optional)
/// - Sound-Name
/// - Zeitdarstellung (Position / Dauer) (optional)
/// - Skip Forward/Backward Buttons (optional)
/// - Entfernen-Button (optional)
/// - Speed-Control (optional)
/// - Großer zentraler Play-Button (optional für Preview-Modus)
class SoundMixerChannel extends StatefulWidget {
  final SoundChannel channel;
  final MultiStreamSoundService mixerService;
  final SoundMixerConfig config;
  final VoidCallback? onRemove;

  const SoundMixerChannel({
    super.key,
    required this.channel,
    required this.mixerService,
    required this.config,
    this.onRemove,
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

        return _buildModernChannel(channel);
      },
    );
  }

  /// Modernes Spotify-inspiriertes Design
  Widget _buildModernChannel(SoundChannel channel) {
    final isCompact = widget.config.compactMode;
    final padding = isCompact ? 8.0 : 16.0;
    final marginBottom = isCompact ? 6.0 : 12.0;
    final borderRadius = isCompact ? 8.0 : 12.0;
    
    return Container(
      margin: EdgeInsets.only(bottom: marginBottom),
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: ModernAudioColors.surface,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: channel.isPlaying 
              ? ModernAudioColors.accentGreen.withValues(alpha: 0.4)
              : ModernAudioColors.surfaceHighlight.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          if (channel.isPlaying)
            BoxShadow(
              color: ModernAudioColors.accentGreen.withValues(alpha: 0.15),
              blurRadius: 16,
              spreadRadius: 0,
            ),
        ],
      ),
      child: _buildChannelContent(channel),
    );
  }

  /// Gemeinsamer Inhalt
  Widget _buildChannelContent(SoundChannel channel) {
    final isCompact = widget.config.compactMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit Name und Buttons
        Row(
          children: [
            // Play/Pause Button
            _buildPlayPauseButton(channel),
            SizedBox(width: isCompact ? 4 : 6),
            
            // Stop Button
            _buildStopButton(channel),
            SizedBox(width: isCompact ? 4 : 6),
            
            // Sound-Name
            Expanded(
              child: _buildSoundName(channel),
            ),
            
            // Loop Toggle (nur wenn konfiguriert)
            if (widget.config.showLoopToggle)
              _buildLoopButton(channel),
            
            // Remove Button (nur wenn onRemove gesetzt ist)
            if (widget.onRemove != null) ...[  
              SizedBox(width: isCompact ? 2 : 4),
              _buildRemoveButton(),
            ],
          ],
        ),
        
        // Detaillierte Sound-Info (optional)
        if (widget.config.showDetailedInfo && !isCompact) ...[  
          const SizedBox(height: 4),
          _buildDetailedInfo(channel),
        ],
        
        // Zeitdarstellung und Fortschrittsbalken (optional)
        if (widget.config.showTimeDisplay && !isCompact) ...[  
          const SizedBox(height: 8),
          _buildTimeDisplay(channel),
        ],
        
        // Skip-Buttons (optional)
        if (widget.config.showSkipButtons && !isCompact) ...[  
          const SizedBox(height: 8),
          _buildSkipButtons(channel),
        ],
        
        // Speed-Control (optional)
        if (widget.config.showSpeedControl && !isCompact) ...[  
          const SizedBox(height: 8),
          _buildSpeedControl(channel),
        ],
        
        SizedBox(height: isCompact ? 4 : 8),
        
        // Lautstärke-Slider
        _buildVolumeSlider(channel),
        
        // Großer zentraler Play-Button (optional für Preview-Modus)
        if (widget.config.showLargePlayButton && !isCompact) ...[  
          const SizedBox(height: 16),
          _buildLargePlayButton(channel),
        ],
      ],
    );
  }

  /// Sound-Name mit Typ-Anzeige
  Widget _buildSoundName(SoundChannel channel) {
    final isCompact = widget.config.compactMode;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          channel.sound.name,
          style: TextStyle(
            color: ModernAudioColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: isCompact ? 11 : 14,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (!isCompact) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              // Sound-Typ Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: channel.sound.soundType == SoundType.Ambiente
                      ? ModernAudioColors.accentCyan.withValues(alpha: 0.2)
                      : ModernAudioColors.accentGreen.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  channel.sound.soundTypeDisplayName,
                  style: TextStyle(
                    color: channel.sound.soundType == SoundType.Ambiente
                        ? ModernAudioColors.accentCyan
                        : ModernAudioColors.accentGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (channel.isLooping) ...[
                const SizedBox(width: 6),
                const Icon(
                  Icons.loop,
                  color: ModernAudioColors.accentGreen,
                  size: 12,
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }

  /// Lautstärke-Slider
  Widget _buildVolumeSlider(SoundChannel channel) {
    final isCompact = widget.config.compactMode;
    final iconSize = isCompact ? 14.0 : 18.0;
    final trackHeight = isCompact ? 3.0 : 4.0;
    final thumbRadius = isCompact ? 5.0 : 7.0;
    final overlayRadius = isCompact ? 10.0 : 14.0;
    final percentWidth = isCompact ? 32.0 : 40.0;
    final percentFontSize = isCompact ? 9.0 : 12.0;
    
    return Row(
      children: [
        Icon(
          channel.volume == 0 ? Icons.volume_off : Icons.volume_up,
          color: channel.volume > 0 ? ModernAudioColors.accentGreen : ModernAudioColors.textMuted,
          size: iconSize,
        ),
        SizedBox(width: isCompact ? 6 : 8),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: trackHeight,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
              overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
              activeTrackColor: ModernAudioColors.accentGreen,
              inactiveTrackColor: ModernAudioColors.progressBackground,
              thumbColor: ModernAudioColors.textPrimary,
              overlayColor: ModernAudioColors.accentGreen.withValues(alpha: 0.2),
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
        SizedBox(width: isCompact ? 4 : 8),
        SizedBox(
          width: percentWidth,
          child: Text(
            '${(channel.volume * 100).toInt()}%',
            style: TextStyle(
              color: ModernAudioColors.textSecondary,
              fontSize: percentFontSize,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
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

    return _buildModernTimeDisplay(channel, progress, duration);
  }

  /// Moderne Zeitdarstellung (Spotify-Style)
  Widget _buildModernTimeDisplay(SoundChannel channel, double progress, Duration? duration) {
    return Column(
      children: [
        // Fortschrittsbalken
        _buildModernProgressBar(channel, progress, duration),
        const SizedBox(height: 6),
        // Zeit-Text
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formatDuration(channel.currentPosition),
              style: const TextStyle(
                color: ModernAudioColors.textSecondary,
                fontSize: 11,
              ),
            ),
            Text(
              duration != null ? _formatDuration(duration) : '--:--',
              style: const TextStyle(
                color: ModernAudioColors.textMuted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Moderner Fortschrittsbalken (Spotify-Style)
  Widget _buildModernProgressBar(SoundChannel channel, double progress, Duration? duration) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;
        
        return GestureDetector(
          onTapDown: (details) => _handleSeek(details, channel, duration, barWidth),
          onHorizontalDragUpdate: (details) => _handleDragSeek(details, channel, duration, barWidth),
          child: MouseRegion(
            child: Container(
              height: 20,
              width: double.infinity,
              color: Colors.transparent,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.centerLeft,
                children: [
                  // Hintergrund-Balken
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: ModernAudioColors.progressBackground,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Fortschritts-Balken mit Gradient
                  Container(
                    height: 4,
                    width: barWidth * progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          ModernAudioColors.accentGreen,
                          ModernAudioColors.accentGreenLight,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Position-Indicator
                  Positioned(
                    left: (barWidth * progress) - 6,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: ModernAudioColors.textPrimary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
    final isCompact = widget.config.compactMode;
    final size = isCompact ? 28.0 : 40.0;
    final iconSize = isCompact ? 14.0 : 22.0;
    
    return GestureDetector(
      onTap: () => widget.mixerService.togglePlayPause(channel.id),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ModernAudioColors.accentGreen,
          shape: BoxShape.circle,
          boxShadow: [
            if (channel.isPlaying)
              BoxShadow(
                color: ModernAudioColors.accentGreen.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 0,
              ),
          ],
        ),
        child: Icon(
          channel.isPlaying ? Icons.pause : Icons.play_arrow,
          color: ModernAudioColors.background,
          size: iconSize,
        ),
      ),
    );
  }

  /// Stop Button
  Widget _buildStopButton(SoundChannel channel) {
    final isCompact = widget.config.compactMode;
    final size = isCompact ? 24.0 : 36.0;
    final iconSize = isCompact ? 12.0 : 18.0;
    
    return GestureDetector(
      onTap: () => widget.mixerService.stopSound(channel.id),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ModernAudioColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.stop,
          color: ModernAudioColors.textSecondary,
          size: iconSize,
        ),
      ),
    );
  }

  /// Loop Toggle Button
  Widget _buildLoopButton(SoundChannel channel) {
    final isCompact = widget.config.compactMode;
    final size = isCompact ? 24.0 : 36.0;
    final iconSize = isCompact ? 12.0 : 18.0;
    
    return GestureDetector(
      onTap: () => widget.mixerService.setChannelLooping(channel.id, !channel.isLooping),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: channel.isLooping 
              ? ModernAudioColors.accentGreen.withValues(alpha: 0.2)
              : ModernAudioColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.loop,
          color: channel.isLooping 
              ? ModernAudioColors.accentGreen 
              : ModernAudioColors.textMuted,
          size: iconSize,
        ),
      ),
    );
  }

  /// Remove Button
  Widget _buildRemoveButton() {
    final isCompact = widget.config.compactMode;
    final size = isCompact ? 18.0 : 24.0;
    final iconSize = isCompact ? 10.0 : 14.0;
    
    return GestureDetector(
      onTap: widget.onRemove,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: ModernAudioColors.surfaceLight,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Icon(
          Icons.close,
          color: ModernAudioColors.textMuted,
          size: iconSize,
        ),
      ),
    );
  }

  /// Detaillierte Sound-Info (Beschreibung, Kategorie)
  Widget _buildDetailedInfo(SoundChannel channel) {
    final sound = channel.sound;
    
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: ModernAudioColors.surfaceLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sound.description.isNotEmpty) ...[
            Text(
              sound.description,
              style: const TextStyle(
                color: ModernAudioColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (sound.categoryId != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.folder_outlined,
                  color: ModernAudioColors.textMuted,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  sound.categoryId!,
                  style: const TextStyle(
                    color: ModernAudioColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Skip-Buttons (±10 Sekunden)
  Widget _buildSkipButtons(SoundChannel channel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModernSkipButton(
          icon: Icons.replay_10,
          onPressed: () => _skipBackward(channel),
        ),
        const SizedBox(width: 24),
        _buildModernSkipButton(
          icon: Icons.forward_10,
          onPressed: () => _skipForward(channel),
        ),
      ],
    );
  }

  Widget _buildModernSkipButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: ModernAudioColors.surfaceLight,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: ModernAudioColors.textPrimary,
          size: 22,
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
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentSpeed = channel.playbackSpeed ?? 1.0;
    
    return Row(
      children: [
        const Icon(
          Icons.speed,
          color: ModernAudioColors.textMuted,
          size: 16,
        ),
        const SizedBox(width: 8),
        const Text(
          'Speed:',
          style: TextStyle(
            color: ModernAudioColors.textSecondary,
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: speeds.map((speed) {
              final isSelected = (currentSpeed - speed).abs() < 0.01;
              
              return GestureDetector(
                onTap: () => widget.mixerService.setChannelSpeed(channel.id, speed),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? ModernAudioColors.accentGreen
                        : ModernAudioColors.surfaceLight,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: isSelected 
                          ? ModernAudioColors.background
                          : ModernAudioColors.textSecondary,
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: ModernAudioColors.accentGreen,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ModernAudioColors.accentGreen.withValues(alpha: 0.4),
                blurRadius: 20,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Icon(
            channel.isPlaying ? Icons.pause : Icons.play_arrow,
            color: ModernAudioColors.background,
            size: 40,
          ),
        ),
      ),
    );
  }
}