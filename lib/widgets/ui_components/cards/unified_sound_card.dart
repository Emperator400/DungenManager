import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';
import '../chips/unified_info_chip.dart';

/// Sound-Typ für UnifiedSoundCard
enum SoundType {
  music,
  ambient,
  sfx,
  voice,
  custom,
}

/// Erweiterung für SoundType
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
        return DnDTheme.arcaneBlue;
      case SoundType.ambient:
        return DnDTheme.mysticalPurple;
      case SoundType.sfx:
        return DnDTheme.ancientGold;
      case SoundType.voice:
        return DnDTheme.emeraldGreen;
      case SoundType.custom:
        return DnDTheme.infoBlue;
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

/// Unified Sound Card
/// 
/// Einheitliche Sound-Karte für Sound-Bibliothek und Sound-Scenes
/// Unterstützt verschiedene Sound-Typen, Lautstärke, Loop-Status
class UnifiedSoundCard extends StatelessWidget {
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

  const UnifiedSoundCard({
    super.key,
    required this.id,
    required this.name,
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

  @override
  Widget build(BuildContext context) {
    final typeColor = soundType.color;

    return Container(
      decoration: _buildDecoration(typeColor),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
          child: Padding(
            padding: EdgeInsets.all(isCompact ? DnDTheme.sm : DnDTheme.md),
            child: isCompact
                ? _buildCompactContent(typeColor)
                : _buildFullContent(typeColor),
          ),
        ),
      ),
    );
  }

  /// Kompakte Darstellung für Listen
  Widget _buildCompactContent(Color typeColor) {
    return Row(
      children: [
        // Play-Button
        _buildPlayButton(typeColor, size: 36),
        
        const SizedBox(width: 8),
        
        // Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: DnDTheme.bodyText2.copyWith(
                  color: isSelected ? DnDTheme.ancientGold : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                soundType.label,
                style: DnDTheme.caption.copyWith(
                  color: typeColor,
                ),
              ),
            ],
          ),
        ),
        
        // Favorit
        if (onToggleFavorite != null)
          IconButton(
            icon: Icon(
              isFavorite ? Icons.star : Icons.star_border,
              color: isFavorite ? DnDTheme.ancientGold : DnDTheme.stoneGrey,
              size: 20,
            ),
            onPressed: onToggleFavorite,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
      ],
    );
  }

  /// Volle Darstellung für Grid
  Widget _buildFullContent(Color typeColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit Icon und Favorit
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                soundType.icon,
                color: typeColor,
                size: 24,
              ),
            ),
            
            const Spacer(),
            
            // Loop-Indikator
            if (isLooping)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: DnDTheme.emeraldGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.loop, size: 12, color: DnDTheme.emeraldGreen),
                    const SizedBox(width: 2),
                    Text(
                      'Loop',
                      style: DnDTheme.caption.copyWith(
                        color: DnDTheme.emeraldGreen,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            
            // Favorit-Button
            if (onToggleFavorite != null) ...[
              const SizedBox(width: 4),
              IconButton(
                icon: Icon(
                  isFavorite ? Icons.star : Icons.star_border,
                  color: isFavorite ? DnDTheme.ancientGold : DnDTheme.stoneGrey,
                ),
                onPressed: onToggleFavorite,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: DnDTheme.sm),
        
        // Name
        Text(
          name,
          style: DnDTheme.headline3.copyWith(
            color: isSelected ? DnDTheme.ancientGold : Colors.white,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Beschreibung
        if (description != null && description!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            description!,
            style: DnDTheme.caption.copyWith(
              color: Colors.white54,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        
        const Spacer(),
        
        // Typ-Chip und Dauer
        Row(
          children: [
            UnifiedInfoChip.type(
              type: soundType.label,
              icon: soundType.icon,
              color: typeColor,
            ),
            
            const Spacer(),
            
            // Dauer
            if (durationSeconds != null)
              Text(
                _formatDuration(durationSeconds!),
                style: DnDTheme.caption.copyWith(
                  color: Colors.white54,
                ),
              ),
          ],
        ),
        
        const SizedBox(height: DnDTheme.sm),
        
        // Play-Controls
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isPlaying) ...[
              if (onPause != null)
                IconButton(
                  icon: const Icon(Icons.pause),
                  color: DnDTheme.ancientGold,
                  onPressed: onPause,
                ),
              if (onStop != null)
                IconButton(
                  icon: const Icon(Icons.stop),
                  color: DnDTheme.errorRed,
                  onPressed: onStop,
                ),
            ] else ...[
              if (onPlay != null)
                ElevatedButton.icon(
                  onPressed: onPlay,
                  icon: const Icon(Icons.play_arrow, size: 18),
                  label: const Text('Abspielen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: typeColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                    ),
                  ),
                ),
            ],
          ],
        ),
        
        // Lautstärke-Indikator
        if (volume < 1.0) ...[
          const SizedBox(height: DnDTheme.xs),
          Row(
            children: [
              Icon(Icons.volume_down, size: 14, color: Colors.white54),
              const SizedBox(width: 4),
              Expanded(
                child: LinearProgressIndicator(
                  value: volume,
                  backgroundColor: Colors.white12,
                  valueColor: AlwaysStoppedAnimation<Color>(typeColor),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Play-Button
  Widget _buildPlayButton(Color typeColor, {double size = 48}) {
    return GestureDetector(
      onTap: isPlaying ? onPause : onPlay,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: typeColor.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: typeColor,
            width: 2,
          ),
        ),
        child: Icon(
          isPlaying ? Icons.pause : Icons.play_arrow,
          color: typeColor,
          size: size * 0.5,
        ),
      ),
    );
  }

  /// Decoration für die Karte
  BoxDecoration _buildDecoration(Color typeColor) {
    return BoxDecoration(
      color: DnDTheme.slateGrey.withOpacity(0.3),
      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      border: Border.all(
        color: isSelected
            ? DnDTheme.ancientGold
            : isPlaying
                ? typeColor
                : typeColor.withOpacity(0.3),
        width: isSelected || isPlaying ? 2 : 1,
      ),
      boxShadow: [
        if (isPlaying)
          BoxShadow(
            color: typeColor.withOpacity(0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
      ],
    );
  }

  /// Dauer formatieren
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }
}

/// Sound-Liste für kompakte Darstellung
class UnifiedSoundListTile extends StatelessWidget {
  final String id;
  final String name;
  final SoundType soundType;
  final bool isPlaying;
  final bool isFavorite;
  final VoidCallback? onTap;
  final VoidCallback? onPlay;
  final VoidCallback? onPause;
  final VoidCallback? onToggleFavorite;

  const UnifiedSoundListTile({
    super.key,
    required this.id,
    required this.name,
    this.soundType = SoundType.custom,
    this.isPlaying = false,
    this.isFavorite = false,
    this.onTap,
    this.onPlay,
    this.onPause,
    this.onToggleFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final typeColor = soundType.color;

    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: typeColor.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          soundType.icon,
          color: typeColor,
        ),
      ),
      title: Text(
        name,
        style: DnDTheme.bodyText2.copyWith(color: Colors.white),
      ),
      subtitle: Text(
        soundType.label,
        style: DnDTheme.caption.copyWith(color: typeColor),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
            ),
            color: typeColor,
            onPressed: isPlaying ? onPause : onPlay,
          ),
          if (onToggleFavorite != null)
            IconButton(
              icon: Icon(
                isFavorite ? Icons.star : Icons.star_border,
                color: isFavorite ? DnDTheme.ancientGold : DnDTheme.stoneGrey,
              ),
              onPressed: onToggleFavorite,
            ),
        ],
      ),
    );
  }
}