import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/sound.dart';
import '../../services/sound_service.dart';
import '../../theme/app_theme.dart';

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

  Future<void> _loadInitialData() async {
    final isPlaying = await SoundService.isPlaying();
    if (mounted) setState(() => _isPlaying = isPlaying);

    _positionSubscription = SoundService.getPositionStream().listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });

    _durationSubscription = SoundService.getDurationStream().listen((duration) {
      if (mounted && duration != null) setState(() => _totalDuration = duration);
    });
  }

  Future<void> _playSound() async {
    setState(() => _isLoading = true);
    final success = await SoundService.playSound(widget.sound.filePath);
    if (mounted) setState(() { _isLoading = false; _isPlaying = success; });
  }

  Future<void> _pauseSound() async {
    await SoundService.pauseSound();
    if (mounted) setState(() => _isPlaying = false);
  }

  Future<void> _stopSound() async {
    await SoundService.stopSound();
    if (mounted) setState(() { _isPlaying = false; _currentPosition = Duration.zero; });
  }

  Future<void> _setVolume(double volume) async {
    setState(() => _volume = volume);
    await SoundService.setVolume(volume);
  }

  Future<void> _seekToPosition(double fraction) async {
    final position = Duration(milliseconds: (_totalDuration.inMilliseconds * fraction).round());
    await SoundService.seekTo(position);
  }

  Future<void> _skipBackward() async {
    final newPosition = _currentPosition - const Duration(seconds: 10);
    await SoundService.seekTo(newPosition > Duration.zero ? newPosition : Duration.zero);
  }

  Future<void> _skipForward() async {
    final newPosition = _currentPosition + const Duration(seconds: 10);
    await SoundService.seekTo(newPosition < _totalDuration ? newPosition : _totalDuration);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return widget.compactMode ? _buildCompactPlayer(context) : _buildFullPlayer(context);
  }

  Widget _buildCompactPlayer(BuildContext context) {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: C.bgHover,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: _isPlaying ? C.green.withValues(alpha: 0.4) : C.border,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _isLoading ? null : (_isPlaying ? _pauseSound : _playSound),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: _isPlaying ? C.green.withValues(alpha: 0.15) : C.bgActive,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: _isPlaying ? C.green.withValues(alpha: 0.4) : C.border,
                ),
              ),
              child: _isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(5),
                      child: CircularProgressIndicator(color: C.accent, strokeWidth: 1.5),
                    )
                  : Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: _isPlaying ? C.green : C.textMid,
                      size: 14,
                    ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.sound.name,
              style: TextStyle(fontSize: 12, color: C.text),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            width: 72,
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                activeTrackColor: C.accent,
                inactiveTrackColor: C.border,
                thumbColor: C.accent,
              ),
              child: Slider(
                value: _volume,
                min: 0.0,
                max: 1.0,
                onChanged: _setVolume,
              ),
            ),
          ),
          if (widget.showCloseButton)
            GestureDetector(
              onTap: _stopSound,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: C.bgActive,
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(color: C.border),
                ),
                child: Icon(Icons.stop, color: C.textMid, size: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFullPlayer(BuildContext context) {
    final C = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFullHeader(C),
          _buildSoundInfo(C),
          const SizedBox(height: 12),
          _buildProgressBar(C),
          const SizedBox(height: 12),
          _buildControls(C),
          const SizedBox(height: 8),
          _buildVolumeControl(C),
          if (widget.showCloseButton) ...[
            const SizedBox(height: 8),
            _buildCloseButton(C),
          ],
        ],
      ),
    );
  }

  Widget _buildFullHeader(AppColorsExtension C) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Row(
        children: [
          Icon(Icons.music_note, color: C.accent, size: 14),
          const SizedBox(width: 8),
          Text(
            'Sound Player',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundInfo(AppColorsExtension C) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.sound.name,
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (widget.sound.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              widget.sound.description,
              style: TextStyle(fontSize: 11, color: C.textSoft),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProgressBar(AppColorsExtension C) {
    final progress = _totalDuration.inMilliseconds > 0
        ? _currentPosition.inMilliseconds / _totalDuration.inMilliseconds
        : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: [
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              activeTrackColor: C.accent,
              inactiveTrackColor: C.border,
              thumbColor: C.accent,
            ),
            child: Slider(
              value: progress.clamp(0.0, 1.0),
              onChanged: _seekToPosition,
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(_currentPosition), style: TextStyle(fontSize: 10, color: C.textSoft)),
              Text(_formatDuration(_totalDuration), style: TextStyle(fontSize: 10, color: C.textSoft)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(AppColorsExtension C) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildIconButton(icon: Icons.replay_10, color: C.textMid, onTap: _skipBackward),
          _buildPlayPauseButton(C),
          _buildIconButton(icon: Icons.stop, color: C.red, onTap: _stopSound),
          _buildIconButton(icon: Icons.forward_10, color: C.textMid, onTap: _skipForward),
        ],
      ),
    );
  }

  Widget _buildPlayPauseButton(AppColorsExtension C) {
    if (_isLoading) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: C.bgHover,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: C.border),
        ),
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(color: C.accent, strokeWidth: 2),
          ),
        ),
      );
    }
    return GestureDetector(
      onTap: _isPlaying ? _pauseSound : _playSound,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _isPlaying ? C.green.withValues(alpha: 0.15) : C.accent.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isPlaying ? C.green.withValues(alpha: 0.4) : C.accent.withValues(alpha: 0.35),
          ),
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: _isPlaying ? C.green : C.accent,
          size: 22,
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 18),
      ),
    );
  }

  Widget _buildVolumeControl(AppColorsExtension C) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(
            _volume == 0.0 ? Icons.volume_off : Icons.volume_up,
            color: C.textMid,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderThemeData(
                trackHeight: 2,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
                activeTrackColor: C.accent,
                inactiveTrackColor: C.border,
                thumbColor: C.accent,
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
            style: TextStyle(fontSize: 10, color: C.textSoft),
          ),
        ],
      ),
    );
  }

  Widget _buildCloseButton(AppColorsExtension C) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: C.border),
          ),
          alignment: Alignment.center,
          child: Text('Schließen', style: TextStyle(fontSize: 13, color: C.textMid)),
        ),
      ),
    );
  }
}
