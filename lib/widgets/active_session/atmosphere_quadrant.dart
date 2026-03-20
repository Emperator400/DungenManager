import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';
import '../audio/sound_mixer_widget.dart';
import 'session_quadrant_base.dart';

/// Atmosphäre-Quadrant - Sound Mixer für die Active Session
/// 
/// Bietet Multi-Stream Audio-Wiedergabe mit:
/// - Mehrere gleichzeitige Sounds
/// - Individuelle Lautstärke pro Kanal
/// - Master-Lautstärke-Steuerung
/// - Loop-Steuerung
class AtmosphereQuadrant extends StatelessWidget {
  /// Optional: Liste von Sound-IDs die automatisch geladen werden sollen
  final List<String>? initialSoundIds;
  
  const AtmosphereQuadrant({
    super.key,
    this.initialSoundIds,
  });

  @override
  Widget build(BuildContext context) {
    return SessionQuadrantBase(
      title: "Atmosphäre",
      icon: Icons.music_note,
      color: DnDTheme.successGreen,
      content: _buildMixerContent(),
    );
  }

  Widget _buildMixerContent() {
    return SoundMixerWidget(
      initialSoundIds: initialSoundIds,
    );
  }
}