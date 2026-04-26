import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

enum SoundType { music, ambient, sfx, voice, custom }

extension SoundTypeExtension on SoundType {
  IconData get icon {
    switch (this) {
      case SoundType.music:
        return Icons.music_note;
      case SoundType.ambient:
        return Icons.nights_stay_outlined;
      case SoundType.sfx:
        return Icons.volume_up;
      case SoundType.voice:
        return Icons.record_voice_over;
      case SoundType.custom:
        return Icons.audiotrack;
    }
  }

  Color get color {
    switch (this) {
      case SoundType.music:
        return const Color(0xFF2F6FEB);
      case SoundType.ambient:
        return const Color(0xFF7C3AED);
      case SoundType.sfx:
        return const Color(0xFFF59E0B);
      case SoundType.voice:
        return const Color(0xFF1A7F4B);
      case SoundType.custom:
        return const Color(0xFF0891B2);
    }
  }

  String get label {
    switch (this) {
      case SoundType.music:
        return 'Musik';
      case SoundType.ambient:
        return 'Ambient';
      case SoundType.sfx:
        return 'SFX';
      case SoundType.voice:
        return 'Stimme';
      case SoundType.custom:
        return 'Custom';
    }
  }
}

class UnifiedSoundCard extends StatelessWidget {
  const UnifiedSoundCard({
    required this.id,
    required this.name,
    super.key,
    this.description,
    this.soundType = SoundType.custom,
    this.filePath,
    this.imageUrl,
    this.durationSeconds,
    this.volume = 1.0,
    this.isLooping = false,
    this.isPlaying = false,
    this.isFavorite = false,
    this.onTap,
    this.onPlay,
    this.onPause,
    this.onStop,
    this.onEdit,
    this.onDelete,
    this.onToggleFavorite,
    this.isSelected = false,
    this.isCompact = false,
  });

  final String id;
  final String name;
  final String? description;
  final SoundType soundType;
  final String? filePath;
  final String? imageUrl;
  final int? durationSeconds;
  final double volume;
  final bool isLooping;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onStop;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onToggleFavorite;
  final bool isSelected;
  final bool isCompact;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final typeColor = soundType.color;

    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected
              ? C.amber
              : isPlaying
                  ? typeColor
                  : typeColor.withValues(alpha: 0.3),
          width: isSelected || isPlaying ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
            child: isCompact
                ? _buildCompactContent(typeColor, C)
                : _buildFullContent(typeColor, C),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactContent(Color typeColor, AppColorsExtension C) => Row(
        children: [
          _PlayButton(
            isPlaying: isPlaying,
            typeColor: typeColor,
            size: 36,
            onPlay: onPlay,
            onPause: onPause,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? C.amber : C.text,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  soundType.label,
                  style: TextStyle(fontSize: 11, color: typeColor),
                ),
              ],
            ),
          ),
          if (onToggleFavorite != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? C.amber : C.textSoft,
                size: 20,
              ),
              onPressed: onToggleFavorite,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
        ],
      );

  Widget _buildFullContent(Color typeColor, AppColorsExtension C) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(soundType.icon, color: typeColor, size: 22),
              ),
              const Spacer(),
              if (isLooping)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: C.greenSoft,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.loop, size: 11, color: C.green),
                      const SizedBox(width: 2),
                      Text('Loop', style: TextStyle(fontSize: 10, color: C.green)),
                    ],
                  ),
                ),
              if (onToggleFavorite != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    isFavorite ? Icons.star : Icons.star_border,
                    color: isFavorite ? C.amber : C.textSoft,
                  ),
                  onPressed: onToggleFavorite,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ],
          ),

          const SizedBox(height: 8),

          Text(
            name,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isSelected ? C.amber : C.text,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              description!,
              style: TextStyle(fontSize: 11, color: C.textMid),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          const Spacer(),

          // Type chip + duration
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: typeColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(soundType.icon, size: 10, color: typeColor),
                    const SizedBox(width: 3),
                    Text(
                      soundType.label,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: typeColor),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              if (durationSeconds != null)
                Text(
                  _formatDuration(durationSeconds!),
                  style: TextStyle(fontSize: 11, color: C.textSoft),
                ),
            ],
          ),

          const SizedBox(height: 8),

          // Play controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPlaying) ...[
                if (onPause != null)
                  IconButton(
                    icon: const Icon(Icons.pause),
                    color: C.amber,
                    onPressed: onPause,
                  ),
                if (onStop != null)
                  IconButton(
                    icon: const Icon(Icons.stop),
                    color: C.red,
                    onPressed: onStop,
                  ),
              ] else ...[
                if (onPlay != null)
                  ElevatedButton.icon(
                    onPressed: onPlay,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Abspielen'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: typeColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
              ],
            ],
          ),

          if (volume < 1.0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.volume_down, size: 13, color: C.textSoft),
                const SizedBox(width: 4),
                Expanded(
                  child: LinearProgressIndicator(
                    value: volume,
                    backgroundColor: C.border,
                    valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                    minHeight: 3,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ],
        ],
      );
}

// ── PLAY BUTTON ───────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.isPlaying,
    required this.typeColor,
    required this.size,
    this.onPlay,
    this.onPause,
  });

  final bool isPlaying;
  final Color typeColor;
  final double size;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: isPlaying ? onPause : onPlay,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: typeColor, width: 1.5),
          ),
          child: Icon(
            isPlaying ? Icons.pause : Icons.play_arrow,
            color: typeColor,
            size: size * 0.5,
          ),
        ),
      );
}

// ── LIST TILE ─────────────────────────────────────────────────────────────────

class UnifiedSoundListTile extends StatelessWidget {
  const UnifiedSoundListTile({
    required this.id,
    required this.name,
    super.key,
    this.soundType = SoundType.custom,
    this.isPlaying = false,
    this.isFavorite = false,
    this.onTap,
    this.onPlay,
    this.onPause,
    this.onToggleFavorite,
  });

  final String id;
  final String name;
  final SoundType soundType;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final typeColor = soundType.color;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: typeColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(soundType.icon, color: typeColor),
      ),
      title: Text(
        name,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text),
      ),
      subtitle: Text(
        soundType.label,
        style: TextStyle(fontSize: 11, color: typeColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
            color: typeColor,
            onPressed: isPlaying ? onPause : onPlay,
          ),
          if (onToggleFavorite != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? C.amber : C.textSoft,
              ),
              onPressed: onToggleFavorite,
            ),
        ],
      ),
    );
  }
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

String _formatDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
