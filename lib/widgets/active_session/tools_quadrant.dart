import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import 'session_quadrant_base.dart';
import 'tool_button.dart';

/// Tools-Quadrant - Zeigt verschiedene Session-Werkzeuge an
class ToolsQuadrant extends StatelessWidget {
  final ActiveSessionViewModel viewModel;
  final double quadrantScale;
  final Function(double) onScaleChanged;

  const ToolsQuadrant({
    super.key,
    required this.viewModel,
    required this.quadrantScale,
    required this.onScaleChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SessionQuadrantBase(
      title: "Session-Werkzeuge",
      icon: Icons.construction,
      color: DnDTheme.mysticalPurple,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1.0,
            children: [
              ToolButton(
                icon: Icons.access_time,
                label: '+15 Min',
                color: DnDTheme.successGreen,
                onTap: () => viewModel.addInGameTime(15),
              ),
              ToolButton(
                icon: Icons.timer,
                label: '+30 Min',
                color: DnDTheme.arcaneBlue,
                onTap: () => viewModel.addInGameTime(30),
              ),
              ToolButton(
                icon: Icons.hourglass_full,
                label: '+1 Std',
                color: DnDTheme.mysticalPurple,
                onTap: () => viewModel.addInGameTime(60),
              ),
              ToolButton(
                icon: Icons.refresh,
                label: 'Neu laden',
                color: DnDTheme.ancientGold,
                onTap: () async {
                  await viewModel.triggerDataReload();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        _buildSessionStatusSection(),
      ],
    );
  }

  Widget _buildSessionStatusSection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: DnDTheme.ancientGold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session-Status',
            style: DnDTheme.bodyText2.copyWith(
              color: DnDTheme.ancientGold,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                Icons.circle,
                color: DnDTheme.successGreen,
                size: 8,
              ),
              const SizedBox(width: 4),
              Text(
                'Session aktiv',
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white70,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Scale Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Größe',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.arcaneBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
              Text(
                '${(quadrantScale * 100).toInt()}%',
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white70,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 2,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 8),
              activeTrackColor: DnDTheme.arcaneBlue,
              inactiveTrackColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              thumbColor: DnDTheme.ancientGold,
            ),
            child: Slider(
              value: quadrantScale,
              min: 0.5,
              max: 1.0,
              divisions: 10,
              onChanged: onScaleChanged,
            ),
          ),
        ],
      ),
    );
  }
}