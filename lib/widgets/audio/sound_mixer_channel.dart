import 'package:flutter/material.dart';
import '../../models/sound.dart';
import '../../services/multi_stream_sound_service.dart';
import '../../theme/app_theme.dart';
import 'sound_mixer_widget.dart';

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
        return _buildModernChannel(context, channel);
      },
    );
  }

  Widget _buildModernChannel(BuildContext context, SoundChannel channel) {
    final C = context.appColors;
    final isCompact = widget.config.compactMode;

    if (isCompact) return _buildCompactChannel(C, channel);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.bgHover,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: channel.isPlaying ? C.green.withValues(alpha: 0.4) : C.border,
        ),
      ),
      child: _buildChannelContent(C, channel),
    );
  }

  Widget _buildCompactChannel(AppColorsExtension C, SoundChannel channel) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: C.bgHover,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: channel.isPlaying ? C.green.withValues(alpha: 0.4) : C.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => widget.mixerService.togglePlayPause(channel.id),
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: channel.isPlaying ? C.green.withValues(alpha: 0.15) : C.bgActive,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: channel.isPlaying ? C.green.withValues(alpha: 0.4) : C.border,
                    ),
                  ),
                  child: Icon(
                    channel.isPlaying ? Icons.pause : Icons.play_arrow,
                    color: channel.isPlaying ? C.green : C.textMid,
                    size: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      channel.sound.name,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: C.text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      channel.sound.soundTypeDisplayName,
                      style: TextStyle(fontSize: 9, color: C.textSoft),
                    ),
                  ],
                ),
              ),
              if (widget.config.showLoopToggle)
                GestureDetector(
                  onTap: () => widget.mixerService.setChannelLooping(channel.id, !channel.isLooping),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(
                      Icons.loop,
                      size: 13,
                      color: channel.isLooping ? C.green : C.textSoft,
                    ),
                  ),
                ),
              if (widget.onRemove != null)
                GestureDetector(
                  onTap: widget.onRemove,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Icon(Icons.close, size: 12, color: C.textSoft),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                channel.volume == 0 ? Icons.volume_off : Icons.volume_up,
                color: channel.volume > 0 ? C.green : C.textSoft,
                size: 12,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                    activeTrackColor: C.green,
                    inactiveTrackColor: C.border,
                    thumbColor: C.text,
                    overlayColor: C.green.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: channel.volume,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (value) => widget.mixerService.setChannelVolume(channel.id, value),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              SizedBox(
                width: 28,
                child: Text(
                  '${(channel.volume * 100).toInt()}%',
                  style: TextStyle(fontSize: 9, color: C.textSoft),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChannelContent(AppColorsExtension C, SoundChannel channel) {
    final isCompact = widget.config.compactMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildPlayPauseButton(C, channel),
            SizedBox(width: isCompact ? 4 : 6),
            _buildStopButton(C, channel),
            SizedBox(width: isCompact ? 4 : 6),
            Expanded(child: _buildSoundName(C, channel)),
            if (widget.config.showLoopToggle) _buildLoopButton(C, channel),
            if (widget.onRemove != null) ...[
              SizedBox(width: isCompact ? 2 : 4),
              _buildRemoveButton(C),
            ],
          ],
        ),
        if (widget.config.showDetailedInfo && !isCompact) ...[
          const SizedBox(height: 4),
          _buildDetailedInfo(C, channel),
        ],
        if (widget.config.showTimeDisplay && !isCompact) ...[
          const SizedBox(height: 8),
          _buildTimeDisplay(C, channel),
        ],
        if (widget.config.showSkipButtons && !isCompact) ...[
          const SizedBox(height: 8),
          _buildSkipButtons(C, channel),
        ],
        if (widget.config.showSpeedControl && !isCompact) ...[
          const SizedBox(height: 8),
          _buildSpeedControl(C, channel),
        ],
        SizedBox(height: isCompact ? 4 : 8),
        _buildVolumeSlider(C, channel),
        if (widget.config.showLargePlayButton && !isCompact) ...[
          const SizedBox(height: 16),
          _buildLargePlayButton(C, channel),
        ],
      ],
    );
  }

  Widget _buildSoundName(AppColorsExtension C, SoundChannel channel) {
    final isCompact = widget.config.compactMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          channel.sound.name,
          style: TextStyle(
            color: C.text,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: channel.sound.soundType == SoundType.Ambiente
                      ? C.accent.withValues(alpha: 0.15)
                      : C.green.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  channel.sound.soundTypeDisplayName,
                  style: TextStyle(
                    color: channel.sound.soundType == SoundType.Ambiente ? C.accent : C.green,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (channel.isLooping) ...[
                const SizedBox(width: 6),
                Icon(Icons.loop, color: C.green, size: 12),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildVolumeSlider(AppColorsExtension C, SoundChannel channel) {
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
          color: channel.volume > 0 ? C.green : C.textSoft,
          size: iconSize,
        ),
        SizedBox(width: isCompact ? 6 : 8),
        Expanded(
          child: SliderTheme(
            data: SliderThemeData(
              trackHeight: trackHeight,
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: thumbRadius),
              overlayShape: RoundSliderOverlayShape(overlayRadius: overlayRadius),
              activeTrackColor: C.green,
              inactiveTrackColor: C.border,
              thumbColor: C.text,
              overlayColor: C.green.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: channel.volume,
              min: 0.0,
              max: 1.0,
              onChanged: (value) => widget.mixerService.setChannelVolume(channel.id, value),
            ),
          ),
        ),
        SizedBox(width: isCompact ? 4 : 8),
        SizedBox(
          width: percentWidth,
          child: Text(
            '${(channel.volume * 100).toInt()}%',
            style: TextStyle(
              color: C.textMid,
              fontSize: percentFontSize,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildTimeDisplay(AppColorsExtension C, SoundChannel channel) {
    final duration = channel.totalDuration;
    double progress = 0.0;
    if (duration != null && duration.inMilliseconds > 0) {
      progress = (channel.currentPosition.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
    }
    return _buildModernTimeDisplay(C, channel, progress, duration);
  }

  Widget _buildModernTimeDisplay(AppColorsExtension C, SoundChannel channel, double progress, Duration? duration) {
    return Column(
      children: [
        _buildModernProgressBar(C, channel, progress, duration),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_formatDuration(channel.currentPosition), style: TextStyle(color: C.textMid, fontSize: 11)),
            Text(
              duration != null ? _formatDuration(duration) : '--:--',
              style: TextStyle(color: C.textSoft, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernProgressBar(AppColorsExtension C, SoundChannel channel, double progress, Duration? duration) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barWidth = constraints.maxWidth;

        return GestureDetector(
          onTapDown: (details) => _handleSeek(details, channel, duration, barWidth),
          onHorizontalDragUpdate: (details) => _handleDragSeek(details, channel, duration, barWidth),
          child: Container(
            height: 20,
            width: double.infinity,
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.centerLeft,
              children: [
                Container(
                  height: 3,
                  width: double.infinity,
                  decoration: BoxDecoration(color: C.border, borderRadius: BorderRadius.circular(2)),
                ),
                Container(
                  height: 3,
                  width: barWidth * progress,
                  decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(2)),
                ),
                Positioned(
                  left: (barWidth * progress) - 6,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: C.text, shape: BoxShape.circle),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleSeek(TapDownDetails details, SoundChannel channel, Duration? duration, double barWidth) {
    if (duration == null || duration.inMilliseconds <= 0) return;
    final seekProgress = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
    widget.mixerService.seekTo(channel.id, Duration(milliseconds: (duration.inMilliseconds * seekProgress).round()));
  }

  void _handleDragSeek(DragUpdateDetails details, SoundChannel channel, Duration? duration, double barWidth) {
    if (duration == null || duration.inMilliseconds <= 0) return;
    final seekProgress = (details.localPosition.dx / barWidth).clamp(0.0, 1.0);
    widget.mixerService.seekTo(channel.id, Duration(milliseconds: (duration.inMilliseconds * seekProgress).round()));
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildPlayPauseButton(AppColorsExtension C, SoundChannel channel) {
    final isCompact = widget.config.compactMode;
    final size = isCompact ? 28.0 : 40.0;
    final iconSize = isCompact ? 14.0 : 22.0;

    return GestureDetector(
      onTap: () => widget.mixerService.togglePlayPause(channel.id),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: C.green, shape: BoxShape.circle),
        child: Icon(
          channel.isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildStopButton(AppColorsExtension C, SoundChannel channel) {
    final isCompact = widget.config.compactMode;
    final size = isCompact ? 24.0 : 36.0;
    final iconSize = isCompact ? 12.0 : 18.0;

    return GestureDetector(
      onTap: () => widget.mixerService.stopSound(channel.id),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: C.bgActive, shape: BoxShape.circle),
        child: Icon(Icons.stop, color: C.textMid, size: iconSize),
      ),
    );
  }

  Widget _buildLoopButton(AppColorsExtension C, SoundChannel channel) {
    final isCompact = widget.config.compactMode;
    final size = isCompact ? 24.0 : 36.0;
    final iconSize = isCompact ? 12.0 : 18.0;

    return GestureDetector(
      onTap: () => widget.mixerService.setChannelLooping(channel.id, !channel.isLooping),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: channel.isLooping ? C.green.withValues(alpha: 0.15) : C.bgActive,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.loop,
          color: channel.isLooping ? C.green : C.textSoft,
          size: iconSize,
        ),
      ),
    );
  }

  Widget _buildRemoveButton(AppColorsExtension C) {
    final isCompact = widget.config.compactMode;
    final size = isCompact ? 18.0 : 24.0;
    final iconSize = isCompact ? 10.0 : 14.0;

    return GestureDetector(
      onTap: widget.onRemove,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: C.bgActive, borderRadius: BorderRadius.circular(4)),
        child: Icon(Icons.close, color: C.textSoft, size: iconSize),
      ),
    );
  }

  Widget _buildDetailedInfo(AppColorsExtension C, SoundChannel channel) {
    final sound = channel.sound;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(color: C.bgActive, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (sound.description.isNotEmpty) ...[
            Text(
              sound.description,
              style: TextStyle(color: C.textMid, fontSize: 11),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (sound.categoryId != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.folder_outlined, color: C.textSoft, size: 12),
                const SizedBox(width: 4),
                Text(sound.categoryId!, style: TextStyle(color: C.textSoft, fontSize: 10)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSkipButtons(AppColorsExtension C, SoundChannel channel) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildModernSkipButton(C, icon: Icons.replay_10, onPressed: () => _skipBackward(channel)),
        const SizedBox(width: 24),
        _buildModernSkipButton(C, icon: Icons.forward_10, onPressed: () => _skipForward(channel)),
      ],
    );
  }

  Widget _buildModernSkipButton(AppColorsExtension C, {required IconData icon, required VoidCallback onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: C.bgActive, shape: BoxShape.circle),
        child: Icon(icon, color: C.text, size: 22),
      ),
    );
  }

  void _skipBackward(SoundChannel channel) {
    if (channel.totalDuration == null) return;
    final newPosition = channel.currentPosition - const Duration(seconds: 10);
    widget.mixerService.seekTo(channel.id, newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  void _skipForward(SoundChannel channel) {
    final duration = channel.totalDuration;
    if (duration == null) return;
    final newPosition = channel.currentPosition + const Duration(seconds: 10);
    widget.mixerService.seekTo(channel.id, newPosition < duration ? newPosition : duration);
  }

  Widget _buildSpeedControl(AppColorsExtension C, SoundChannel channel) {
    const speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    final currentSpeed = channel.playbackSpeed;

    return Row(
      children: [
        Icon(Icons.speed, color: C.textSoft, size: 16),
        const SizedBox(width: 8),
        Text('Speed:', style: TextStyle(color: C.textMid, fontSize: 12)),
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
                    color: isSelected ? C.green : C.bgActive,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: isSelected ? Colors.white : C.textMid,
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

  Widget _buildLargePlayButton(AppColorsExtension C, SoundChannel channel) {
    return Center(
      child: GestureDetector(
        onTap: () => widget.mixerService.togglePlayPause(channel.id),
        child: Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(color: C.green, shape: BoxShape.circle),
          child: Icon(
            channel.isPlaying ? Icons.pause : Icons.play_arrow,
            color: Colors.white,
            size: 40,
          ),
        ),
      ),
    );
  }
}
