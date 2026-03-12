import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import 'session_quadrant_base.dart';

/// Live-Notizen-Quadrant - Ermöglicht schnelle Notizen während der Session
class LiveNotesQuadrant extends StatelessWidget {
  final ActiveSessionViewModel viewModel;

  const LiveNotesQuadrant({
    super.key,
    required this.viewModel,
  });

  @override
  Widget build(BuildContext context) {
    return SessionQuadrantBase(
      title: "Live-Notizen",
      icon: Icons.note_alt,
      color: DnDTheme.ancientGold,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: DnDTheme.ancientGold.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: TextFormField(
              initialValue: viewModel.currentSession.liveNotes,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white, fontSize: 10),
              decoration: const InputDecoration(
                hintText: 'Live-Notizen...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 10),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(4),
              ),
              onFieldSubmitted: (value) async {
                await viewModel.updateLiveNotes(value);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              gradient: DnDTheme.getMysticalGradient(
                startColor: DnDTheme.ancientGold.withValues(alpha: 0.2),
                endColor: DnDTheme.stoneGrey,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(DnDTheme.radiusSmall),
                bottomRight: Radius.circular(DnDTheme.radiusSmall),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Auto-Save',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white70,
                    fontSize: 8,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: DnDTheme.successGreen,
                    borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  ),
                  child: Text(
                    'Save',
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}