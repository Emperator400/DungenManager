import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';
import '../../models/scene.dart';
import '../../models/wiki_entry.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import '../lore_keeper/wiki_entry_popup_dialog.dart';
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
          
          // Wiki-Einträge anzeigen
          if (scene.linkedWikiEntryIds.isNotEmpty) ...[
            const SizedBox(height: 4),
            _buildWikiEntriesSection(scene),
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

  /// Baut die Wiki-Einträge-Sektion für eine Szene
  Widget _buildWikiEntriesSection(Scene scene) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: DnDTheme.mysticalPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.menu_book,
                color: DnDTheme.mysticalPurple,
                size: 10,
              ),
              const SizedBox(width: 4),
              Text(
                'Wiki-Einträge',
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.mysticalPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FutureBuilder<List<WikiEntry>>(
            future: viewModel.getWikiEntriesForScene(scene),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(4),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                );
              }
              
              final entries = snapshot.data ?? [];
              if (entries.isEmpty) {
                return Text(
                  'Keine Einträge gefunden',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white38,
                    fontSize: 8,
                    fontStyle: FontStyle.italic,
                  ),
                );
              }
              
              return Wrap(
                spacing: 4,
                runSpacing: 4,
                children: entries.map((entry) => _buildWikiEntryChip(entry, context)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Baut einen klickbaren Chip für einen Wiki-Eintrag
  Widget _buildWikiEntryChip(WikiEntry entry, BuildContext context) {
    return InkWell(
      onTap: () => _showWikiEntryPopup(entry, context),
      borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: _getTypeColor(entry).withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          border: Border.all(
            color: _getTypeColor(entry).withValues(alpha: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getTypeIcon(entry),
              size: 10,
              color: _getTypeColor(entry),
            ),
            const SizedBox(width: 3),
            Text(
              entry.title,
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.open_in_new,
              size: 8,
              color: _getTypeColor(entry).withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  /// Zeigt das Wiki-Eintrag-Popup an
  void _showWikiEntryPopup(WikiEntry entry, BuildContext context) {
    WikiEntryPopupDialog.show(
      context: context,
      entry: entry,
      onOpenFull: () {
        Navigator.of(context).pop();
        // Navigation zum LoreKeeperScreen könnte hier ergänzt werden
      },
    );
  }

  /// Gibt die Farbe für einen Wiki-Eintragstyp zurück
  Color _getTypeColor(WikiEntry entry) {
    switch (entry.entryType) {
      case WikiEntryType.Person:
        return DnDTheme.arcaneBlue;
      case WikiEntryType.Place:
        return DnDTheme.successGreen;
      case WikiEntryType.Lore:
        return DnDTheme.mysticalPurple;
      case WikiEntryType.Faction:
        return DnDTheme.warningOrange;
      case WikiEntryType.Magic:
        return DnDTheme.infoBlue;
      case WikiEntryType.History:
        return DnDTheme.ancientGold;
      case WikiEntryType.Item:
        return DnDTheme.arcaneBlue;
      case WikiEntryType.Quest:
        return DnDTheme.mysticalPurple;
      case WikiEntryType.Creature:
        return DnDTheme.errorRed;
    }
  }

  /// Gibt das Icon für einen Wiki-Eintragstyp zurück
  IconData _getTypeIcon(WikiEntry entry) {
    switch (entry.entryType) {
      case WikiEntryType.Person:
        return Icons.person;
      case WikiEntryType.Place:
        return Icons.location_on;
      case WikiEntryType.Lore:
        return Icons.menu_book;
      case WikiEntryType.Faction:
        return Icons.groups;
      case WikiEntryType.Magic:
        return Icons.auto_fix_high;
      case WikiEntryType.History:
        return Icons.history;
      case WikiEntryType.Item:
        return Icons.inventory_2;
      case WikiEntryType.Quest:
        return Icons.task_alt;
      case WikiEntryType.Creature:
        return Icons.cruelty_free;
    }
  }
}
