import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';
import '../../models/scene.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import 'session_quadrant_base.dart';

/// Scene-Flow-Quadrant - Zeigt alle Szenen einer Session an
class SceneFlowQuadrant extends StatelessWidget {
  final ActiveSessionViewModel viewModel;
  final VoidCallback onCreateScene;
  final Function(Scene) onSceneTap;
  final Function(Scene)? onStartEncounter;

  const SceneFlowQuadrant({
    super.key,
    required this.viewModel,
    required this.onCreateScene,
    required this.onSceneTap,
    this.onStartEncounter,
  });

  @override
  Widget build(BuildContext context) {
    final scenes = viewModel.scenes;

    return SessionQuadrantBase(
      title: "Szenen-Ablauf",
      icon: Icons.list_alt,
      color: DnDTheme.arcaneBlue,
      content: scenes.isEmpty 
          ? _buildEmptyState()
          : _buildSceneList(scenes),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 32,
            color: Colors.white38,
          ),
          const SizedBox(height: 8),
          Text(
            'Keine Szenen',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Erstelle deine erste Szene',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white54,
              fontSize: 8,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onCreateScene,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Szene erstellen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.arcaneBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: DnDTheme.sm,
                vertical: 4,
              ),
              textStyle: const TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneList(List<Scene> scenes) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(2),
            itemCount: scenes.length,
            itemBuilder: (context, index) {
              final scene = scenes[index];
              final isActive = viewModel.currentSession.activeSceneId == scene.id;
              
              return _buildSimpleSceneCard(
                scene: scene,
                isActive: isActive,
                onTap: () => onSceneTap(scene),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(2),
          child: ElevatedButton.icon(
            onPressed: onCreateScene,
            icon: const Icon(Icons.add, size: 12),
            label: const Text('Neue Szene'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.arcaneBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: DnDTheme.xs,
                vertical: 4,
              ),
              textStyle: const TextStyle(fontSize: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ),
      ],
    );
  }

  /// Einfache Scene-Card vorerst - wird später durch scene_card_widget.dart ersetzt
  Widget _buildSimpleSceneCard({
    required Scene scene,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Theme(
      data: ThemeData(
        dividerColor: Colors.transparent,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: scene.isCompleted 
                ? DnDTheme.successGreen 
                : DnDTheme.arcaneBlue,
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          ),
          child: Text(
            '${scene.orderIndex + 1}',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 9,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                scene.name,
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 9,
                ),
              ),
            ),
            if (scene.isCompleted)
              Icon(
                Icons.check_circle,
                color: DnDTheme.successGreen,
                size: 12,
              ),
            if (isActive)
              Icon(
                Icons.play_circle_filled,
                color: DnDTheme.ancientGold,
                size: 12,
              ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onTap,
              child: Icon(
                Icons.more_vert,
                color: Colors.white70,
                size: 12,
              ),
            ),
          ],
        ),
        trailing: const SizedBox.shrink(),
        backgroundColor: Colors.transparent,
        children: [
          if (scene.description.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                gradient: DnDTheme.getMysticalGradient(
                  startColor: isActive 
                      ? DnDTheme.ancientGold.withValues(alpha: 0.2)
                      : DnDTheme.slateGrey.withValues(alpha: 0.5),
                  endColor: Colors.transparent,
                ),
                borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                border: Border.all(
                  color: isActive 
                      ? DnDTheme.ancientGold.withValues(alpha: 0.3)
                      : DnDTheme.arcaneBlue.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beschreibung',
                    style: DnDTheme.bodyText2.copyWith(
                      color: DnDTheme.ancientGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scene.description,
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white,
                      fontSize: 9,
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Combat-Szene: Kampf starten Button
          if (scene.sceneType == SceneType.Combat && 
              scene.linkedEncounterId != null && 
              scene.linkedEncounterId!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              child: ElevatedButton.icon(
                onPressed: onStartEncounter != null 
                    ? () => onStartEncounter!(scene)
                    : null,
                icon: const Icon(Icons.gavel, size: 12),
                label: const Text('Kampf starten'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DnDTheme.errorRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  textStyle: const TextStyle(fontSize: 9),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  ),
                ),
              ),
            ),
          ],
          
          // Combat-Szene ohne Encounter: Hinweis anzeigen
          if (scene.sceneType == SceneType.Combat && 
              (scene.linkedEncounterId == null || scene.linkedEncounterId!.isEmpty)) ...[
            const SizedBox(height: 4),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 6),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: DnDTheme.ancientGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                border: Border.all(
                  color: DnDTheme.ancientGold.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: DnDTheme.ancientGold,
                    size: 10,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Kein Encounter geplant',
                      style: DnDTheme.bodyText2.copyWith(
                        color: DnDTheme.ancientGold,
                        fontSize: 8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}