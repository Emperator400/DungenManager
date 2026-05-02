import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/scene.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import 'session_quadrant_base.dart';

/// Scene-Flow-Quadrant - Zeigt alle Szenen einer Session an
class SceneFlowQuadrant extends StatelessWidget {
  final ActiveSessionViewModel viewModel;
  final VoidCallback onCreateScene;
  final Function(Scene) onSceneTap;

  const SceneFlowQuadrant({
    super.key,
    required this.viewModel,
    required this.onCreateScene,
    required this.onSceneTap,
  });

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final scenes = viewModel.scenes;

    return SessionQuadrantBase(
      title: "Szenen-Ablauf",
      icon: Icons.list_alt,
      color: C.accent,
      content: scenes.isEmpty
          ? _buildEmptyState(context, C)
          : _buildSceneList(context, scenes, C),
    );
  }

  Widget _buildEmptyState(BuildContext context, AppColorsExtension C) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.list_alt,
            size: 32,
            color: C.textSoft,
          ),
          const SizedBox(height: 8),
          Text(
            'Keine Szenen',
            style: TextStyle(
              fontSize: 10,
              color: C.textMid,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Erstelle deine erste Szene',
            style: TextStyle(
              fontSize: 8,
              color: C.textSoft,
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: onCreateScene,
            icon: const Icon(Icons.add, size: 14),
            label: const Text('Szene erstellen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: C.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              textStyle: const TextStyle(fontSize: 9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneList(BuildContext context, List<Scene> scenes, AppColorsExtension C) {
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
                context: context,
                scene: scene,
                isActive: isActive,
                onTap: () => onSceneTap(scene),
                C: C,
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
              backgroundColor: C.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
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
    required BuildContext context,
    required Scene scene,
    required bool isActive,
    required VoidCallback onTap,
    required AppColorsExtension C,
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
            color: scene.isCompleted ? C.green : C.accent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${scene.orderIndex + 1}',
            style: TextStyle(
              fontSize: 9,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                scene.name,
                style: TextStyle(
                  fontSize: 9,
                  color: C.text,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (scene.isCompleted)
              Icon(
                Icons.check_circle,
                color: C.green,
                size: 12,
              ),
            if (isActive)
              Icon(
                Icons.play_circle_filled,
                color: C.amber,
                size: 12,
              ),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onTap,
              child: Icon(
                Icons.more_vert,
                color: C.textSoft,
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
                color: isActive
                    ? C.amber.withValues(alpha: 0.1)
                    : C.bgPanel,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? C.amber.withValues(alpha: 0.3)
                      : C.border,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beschreibung',
                    style: TextStyle(
                      fontSize: 8,
                      color: C.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    scene.description,
                    style: TextStyle(
                      fontSize: 9,
                      color: C.text,
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
