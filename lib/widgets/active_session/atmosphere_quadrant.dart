import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../audio/sound_mixer_widget.dart';

class AtmosphereQuadrant extends StatelessWidget {
  final List<String>? initialSoundIds;
  final Function(List<String>)? onSoundsChanged;

  const AtmosphereQuadrant({
    super.key,
    this.initialSoundIds,
    this.onSoundsChanged,
  });

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(
            children: [
              Icon(Icons.music_note, size: 13, color: C.accent),
              const SizedBox(width: 6),
              Text(
                'Atmosphäre',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: SoundMixerWidget(
            initialSoundIds: initialSoundIds,
            onSoundsChanged: onSoundsChanged,
            config: const SoundMixerConfig(
              compactMode: true,
              showAddButtons: true,
              showSingleAddButton: true,
              showMasterVolume: true,
              showStopAllButton: true,
              showChannelCounter: false,
              readOnly: false,
              showDivider: false,
              showHeader: false,
              showTimeDisplay: false,
              showLoopToggle: false,
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: C.border),
      ],
    );
  }
}
