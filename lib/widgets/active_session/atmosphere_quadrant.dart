import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';
import 'session_quadrant_base.dart';

/// Atmosphäre-Quadrant - Placeholder für zukünftige Sound Mixer Funktionalität
class AtmosphereQuadrant extends StatelessWidget {
  const AtmosphereQuadrant({super.key});

  @override
  Widget build(BuildContext context) {
    return SessionQuadrantBase(
      title: "Atmosphäre",
      icon: Icons.music_note,
      color: DnDTheme.successGreen,
      content: _buildPlaceholderContent(),
    );
  }

  Widget _buildPlaceholderContent() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note,
            size: 24,
            color: Colors.white38,
          ),
          SizedBox(height: 4),
          Text(
            'Sound Mixer',
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2),
          Text(
            'Diese Funktion wird in Zukunft verfügbar sein',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 8,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}