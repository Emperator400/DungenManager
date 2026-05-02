import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../models/session.dart';
import '../../models/scene.dart';
import '../../models/sound.dart';
import '../../models/quest.dart';
import '../../models/wiki_entry.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import '../../viewmodels/edit_scene_viewmodel.dart';
import '../../database/repositories/scene_model_repository.dart';
import '../../database/repositories/creature_model_repository.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../database/repositories/quest_model_repository.dart';
import '../../database/repositories/sound_model_repository.dart';
import '../../database/repositories/encounter_model_repository.dart';
import '../../database/repositories/encounter_participant_model_repository.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/wiki_entry_model_repository.dart';
import '../../theme/dnd_theme.dart';
import '../../theme/app_theme.dart';
import '../../widgets/audio/sound_player_widget.dart';
import '../../widgets/active_session/live_notes_quadrant.dart';
import '../../widgets/active_session/atmosphere_quadrant.dart';
import '../../widgets/active_session/quest_list_section.dart';
import 'encounter_setup_screen.dart';
import '../scenes/edit_scene_screen.dart';

class ActiveSessionScreen extends StatefulWidget {
  final Session session;
  final Campaign campaign;

  const ActiveSessionScreen({
    super.key,
    required this.session,
    required this.campaign,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late ActiveSessionViewModel _viewModel;
  int _questUpdateCounter = 0;

  @override
  void initState() {
    super.initState();
    _viewModel = ActiveSessionViewModel(
      session: widget.session,
      campaign: widget.campaign,
    );
    _viewModel.reloadSession();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActiveSessionViewModel>.value(
      value: _viewModel,
      child: Consumer<ActiveSessionViewModel>(
        builder: (context, viewModel, child) {
          final C = context.appColors;

          if (viewModel.error != null) {
            return Scaffold(
              backgroundColor: C.bg,
              body: _buildErrorWidget(viewModel.error!),
            );
          }

          return Scaffold(
            backgroundColor: C.bg,
            body: Column(
              children: [
                _buildTopBar(context, viewModel, C),
                Expanded(
                  child: _buildMainContent(context, viewModel, C),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── TOP BAR ─────────────────────────────────────────────────────────────

  Widget _buildTopBar(
    BuildContext context,
    ActiveSessionViewModel viewModel,
    AppColorsExtension C,
  ) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Back button
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(Icons.chevron_left, size: 20, color: C.textMid),
            ),
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 18, color: C.border),
          const SizedBox(width: 10),
          Text(
            viewModel.currentSession.title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: C.text,
            ),
          ),
          const Spacer(),
          // Live badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: C.greenSoft,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: C.green.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: C.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Aktiv',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: C.green,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Campaign pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: C.bgHover,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: C.border),
            ),
            child: Text(
              viewModel.campaign.title,
              style: TextStyle(fontSize: 11, color: C.textMid),
            ),
          ),
          const SizedBox(width: 8),
          // Kampf button
          GestureDetector(
            onTap: _startEncounter,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: C.red,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.gavel, size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Kampf',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── MAIN CONTENT ─────────────────────────────────────────────────────────

  Widget _buildMainContent(
    BuildContext context,
    ActiveSessionViewModel viewModel,
    AppColorsExtension C,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left panel – scenes
        Expanded(
          child: _buildScenePanel(context, viewModel, C),
        ),
        // Right panel – notes + atmosphere + quests
        Container(
          width: 360,
          decoration: BoxDecoration(
            color: C.bgPanel,
            border: Border(left: BorderSide(color: C.border)),
          ),
          child: _buildRightPanel(viewModel),
        ),
      ],
    );
  }

  // ─── SCENE PANEL (left) ──────────────────────────────────────────────────

  Widget _buildScenePanel(
    BuildContext context,
    ActiveSessionViewModel viewModel,
    AppColorsExtension C,
  ) {
    return Container(
      color: C.bg,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            decoration: BoxDecoration(
              color: C.bgPanel,
              border: Border(bottom: BorderSide(color: C.border)),
            ),
            child: Row(
              children: [
                Icon(Icons.article_outlined, size: 14, color: C.accent),
                const SizedBox(width: 7),
                Text(
                  'Szenen-Ablauf',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: C.text,
                  ),
                ),
                const SizedBox(width: 7),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: C.bgHover,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${viewModel.scenes.length} Szenen',
                    style: TextStyle(fontSize: 10, color: C.textSoft),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => _showResetConfirmDialog(viewModel, C),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: C.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: C.amber.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.restart_alt, size: 12, color: C.amber),
                        const SizedBox(width: 5),
                        Text(
                          'Zurücksetzen',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: C.amber,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _showCreateSceneDialog,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: C.accent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: 12, color: Colors.white),
                        const SizedBox(width: 5),
                        Text(
                          'Neue Szene',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Scene list
          Expanded(
            child: viewModel.scenes.isEmpty
                ? _buildEmptyScenesState(C)
                : _buildSceneList(context, viewModel, C),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyScenesState(AppColorsExtension C) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.article_outlined, size: 32, color: C.textSoft),
          const SizedBox(height: 8),
          Text(
            'Keine Szenen',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: C.textMid,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Erstelle deine erste Szene',
            style: TextStyle(fontSize: 12, color: C.textSoft),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _showCreateSceneDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: C.accent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 14, color: Colors.white),
                  const SizedBox(width: 6),
                  Text(
                    'Szene erstellen',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneList(
    BuildContext context,
    ActiveSessionViewModel viewModel,
    AppColorsExtension C,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: viewModel.scenes.length,
      itemBuilder: (context, index) {
        final scene = viewModel.scenes[index];
        final isActive =
            viewModel.currentSession.activeSceneId == scene.id;
        return _buildNewSceneCard(context, scene, isActive, C);
      },
    );
  }

  Widget _buildNewSceneCard(
    BuildContext context,
    Scene scene,
    bool isActive,
    AppColorsExtension C,
  ) {
    final typeColor = _getSceneTypeColor(scene.sceneType);

    // Outer container provides rounded clipping; inner container carries the
    // left-only colored stripe — avoids Flutter's non-uniform-border + borderRadius artifact.
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? C.green : C.border,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isActive ? C.green.withValues(alpha: 0.06) : C.bgPanel,
          border: Border(left: BorderSide(color: typeColor, width: 3)),
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.only(left: 9, right: 12, top: 2, bottom: 2),
            leading: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: typeColor,
                borderRadius: BorderRadius.circular(6),
              ),
              alignment: Alignment.center,
              child: Text(
                '${scene.orderIndex + 1}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        scene.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: C.text,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            scene.sceneTypeDisplayName,
                            style: TextStyle(fontSize: 11, color: C.textMid),
                          ),
                          if (scene.linkedEncounterId != null) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.gavel, color: C.red, size: 12),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Inline primary action — visible without opening any menu
                if (isActive && scene.linkedEncounterId != null) ...[
                  _buildSceneActionChip(
                    label: 'Kampf',
                    icon: Icons.gavel,
                    color: C.red,
                    onTap: () => _startEncounterForScene(scene),
                  ),
                  const SizedBox(width: 6),
                  _buildSceneActionChip(
                    label: 'Abschließen',
                    icon: Icons.check_circle_outline,
                    color: C.green,
                    onTap: () => _viewModel.completeScene(scene.id),
                  ),
                ] else if (isActive)
                  _buildSceneActionChip(
                    label: 'Abschließen',
                    icon: Icons.check_circle_outline,
                    color: C.green,
                    onTap: () => _viewModel.completeScene(scene.id),
                  )
                else if (!scene.isCompleted)
                  _buildSceneActionChip(
                    label: 'Aktivieren',
                    icon: Icons.play_arrow_rounded,
                    color: C.amber,
                    onTap: () => _viewModel.activateScene(scene.id),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(Icons.check_circle, color: C.green, size: 16),
                  ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showSceneOptions(scene),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(Icons.more_horiz, size: 16, color: C.textMid),
                  ),
                ),
                const SizedBox(width: 2),
              ],
            ),
            backgroundColor: Colors.transparent,
            collapsedBackgroundColor: Colors.transparent,
            iconColor: C.textMid,
            collapsedIconColor: C.textMid,
            children: [
              _buildSceneExpandedContent(context, scene, isActive, C),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSceneActionChip({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.45)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSceneExpandedContent(
    BuildContext context,
    Scene scene,
    bool isActive,
    AppColorsExtension C,
  ) {
    final hasContent = scene.description.isNotEmpty ||
        scene.linkedCharacterIds.isNotEmpty ||
        scene.linkedWikiEntryIds.isNotEmpty ||
        scene.linkedSoundIds.isNotEmpty ||
        scene.linkedQuestIds.isNotEmpty;

    if (!hasContent) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Text(
          'Keine weiteren Details',
          style: TextStyle(fontSize: 12, color: C.textSoft),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: C.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (scene.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('Beschreibung', C),
            const SizedBox(height: 4),
            Text(
              scene.description,
              style: TextStyle(
                  fontSize: 12, color: C.textMid, height: 1.6),
            ),
          ],
          if (scene.linkedCharacterIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('Verknüpfte Charaktere', C),
            const SizedBox(height: 4),
            _buildLinkedCharactersRow(scene),
          ],
          if (scene.linkedWikiEntryIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('Verknüpfte Wiki-Einträge', C),
            const SizedBox(height: 4),
            _buildLinkedWikiEntriesRow(scene),
          ],
          if (scene.linkedSoundIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('Verknüpfte Sounds', C),
            const SizedBox(height: 4),
            _buildLinkedSoundsRow(scene),
          ],
          if (scene.linkedQuestIds.isNotEmpty) ...[
            const SizedBox(height: 10),
            _sectionLabel('Verknüpfte Quests', C),
            const SizedBox(height: 4),
            _buildLinkedQuestsRow(scene),
          ],
          if (scene.estimatedDuration != null ||
              scene.complexity != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (scene.complexity != null)
                  _buildMetaChip(
                    icon: Icons.trending_up,
                    label: scene.complexityDisplayName,
                    color: DnDTheme.mysticalPurple,
                  ),
                if (scene.estimatedDuration != null) ...[
                  const SizedBox(width: 6),
                  _buildMetaChip(
                    icon: Icons.schedule,
                    label: _formatDuration(scene.estimatedDuration!),
                    color: DnDTheme.arcaneBlue,
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionLabel(String text, AppColorsExtension C) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        color: C.textSoft,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildMetaChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 9),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
                fontSize: 9,
                color: color,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getSceneTypeColor(SceneType type) {
    switch (type) {
      case SceneType.Introduction:
        return const Color(0xFF2F6FEB);
      case SceneType.Exploration:
        return const Color(0xFF1A7F4B);
      case SceneType.Combat:
        return const Color(0xFFC93A3A);
      case SceneType.Social:
        return const Color(0xFF7C3AED);
      case SceneType.Puzzle:
        return const Color(0xFFB45309);
      case SceneType.Climax:
        return const Color(0xFF0891B2);
      case SceneType.Resolution:
        return const Color(0xFF6B6B66);
    }
  }

  // ─── RIGHT PANEL ──────────────────────────────────────────────────────────

  Widget _buildRightPanel(ActiveSessionViewModel viewModel) {
    return Column(
      children: [
        // Live-Notizen (fixed height)
        SizedBox(
          height: 190,
          child: LiveNotesQuadrant(viewModel: viewModel),
        ),
        // Atmosphäre (grows with content, capped so quests always have space)
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 100, maxHeight: 380),
          child: _buildAtmosphereSection(viewModel),
        ),
        // Quests (expands to fill remaining space)
        Expanded(
          child: QuestListSection(
            key: ValueKey('quest_list_$_questUpdateCounter'),
            campaignId: viewModel.campaign.id,
            onQuestUpdated: () {
              setState(() {
                _questUpdateCounter++;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAtmosphereSection(ActiveSessionViewModel viewModel) {
    final activeSceneId = viewModel.currentSession.activeSceneId;
    List<String> sceneSoundIds = [];

    if (activeSceneId != null) {
      try {
        final activeScene =
            viewModel.scenes.firstWhere((s) => s.id == activeSceneId);
        sceneSoundIds = activeScene.linkedSoundIds;
      } catch (_) {}
    }

    final sessionSoundIds = viewModel.currentSession.linkedSoundIds;
    final mergedSoundIds = [
      ...sessionSoundIds,
      ...sceneSoundIds.where((id) => !sessionSoundIds.contains(id)),
    ];

    return AtmosphereQuadrant(
      initialSoundIds: mergedSoundIds,
      onSoundsChanged: (ids) => viewModel.updateSessionSounds(ids),
    );
  }

  // ─── ERROR WIDGET ─────────────────────────────────────────────────────────

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: DnDTheme.errorRed, size: 48),
            const SizedBox(height: 16),
            Text(
              'Fehler',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: DnDTheme.errorRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                _viewModel.clearError();
                await _viewModel.triggerDataReload();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.arcaneBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── LINKED SOUNDS ────────────────────────────────────────────────────────

  Widget _buildLinkedSoundsRow(Scene scene) {
    if (scene.linkedSoundIds.isEmpty) return const SizedBox.shrink();

    return FutureBuilder<List<Sound>>(
      future: _loadLinkedSounds(scene.linkedSoundIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(4),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: snapshot.data!
              .map((sound) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: SoundPlayerWidget(
                      sound: sound,
                      compactMode: true,
                      showCloseButton: false,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Future<List<Sound>> _loadLinkedSounds(List<String> soundIds) async {
    final List<Sound> result = [];
    try {
      final soundRepo = context.read<SoundModelRepository>();
      for (final soundId in soundIds) {
        try {
          final sound = await soundRepo.findById(soundId);
          if (sound != null && sound.isValid) result.add(sound);
        } catch (_) {}
      }
    } catch (_) {}
    return result;
  }

  // ─── LINKED CHARACTERS ───────────────────────────────────────────────────

  Widget _buildLinkedCharactersRow(Scene scene) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadLinkedCharacters(scene.linkedCharacterIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final linkedChars = snapshot.data!;
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children: linkedChars.values.map((char) {
            final type = char['type'] as String;
            final name = char['name'] as String;
            final level = char['level'] as String?;
            final color = _getCharacterTypeColor(type);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getCharacterTypeIcon(type), color: color, size: 11),
                  const SizedBox(width: 5),
                  Text(
                    level != null ? '$name ($level)' : name,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadLinkedCharacters(
      List<String> characterIds) async {
    final Map<String, dynamic> result = {};
    try {
      final creatureRepo = context.read<CreatureModelRepository>();
      final pcRepo = context.read<PlayerCharacterModelRepository>();
      for (final charId in characterIds) {
        try {
          final pc = await pcRepo.findById(charId);
          if (pc != null) {
            result[charId] = {
              'name': pc.name,
              'type': 'pc',
              'level': 'Lvl ${pc.level}',
            };
            continue;
          }
        } catch (_) {}
        try {
          final creature = await creatureRepo.findById(charId);
          if (creature != null) {
            result[charId] = {
              'name': creature.name,
              'type':
                  creature.sourceType == 'official' ? 'monster' : 'npc',
              'level': creature.challengeRating != null
                  ? 'CR ${creature.challengeRating}'
                  : null,
            };
          }
        } catch (_) {}
      }
    } catch (_) {}
    return result;
  }

  // ─── LINKED WIKI ENTRIES ─────────────────────────────────────────────────

  Widget _buildLinkedWikiEntriesRow(Scene scene) {
    return FutureBuilder<List<WikiEntry>>(
      future: _loadLinkedWikiEntries(scene.linkedWikiEntryIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return Wrap(
          spacing: 6,
          runSpacing: 4,
          children: snapshot.data!.map((entry) {
            final color = _getWikiEntryTypeColor(entry.entryType);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: color.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_getWikiEntryTypeIcon(entry.entryType),
                      color: color, size: 11),
                  const SizedBox(width: 5),
                  Text(
                    entry.title,
                    style: TextStyle(fontSize: 11, color: color),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<WikiEntry>> _loadLinkedWikiEntries(
      List<String> wikiEntryIds) async {
    final List<WikiEntry> result = [];
    try {
      final wikiRepo = context.read<WikiEntryModelRepository>();
      for (final wikiId in wikiEntryIds) {
        try {
          final entry = await wikiRepo.findById(wikiId);
          if (entry != null) result.add(entry);
        } catch (_) {}
      }
    } catch (_) {}
    return result;
  }

  Color _getWikiEntryTypeColor(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:    return DnDTheme.successGreen;
      case WikiEntryType.Place:     return DnDTheme.arcaneBlue;
      case WikiEntryType.Lore:      return DnDTheme.ancientGold;
      case WikiEntryType.Faction:   return DnDTheme.mysticalPurple;
      case WikiEntryType.Magic:     return const Color(0xFF7C3AED);
      case WikiEntryType.History:   return const Color(0xFFB45309);
      case WikiEntryType.Item:      return DnDTheme.infoBlue;
      case WikiEntryType.Quest:     return DnDTheme.successGreen;
      case WikiEntryType.Creature:  return DnDTheme.errorRed;
    }
  }

  IconData _getWikiEntryTypeIcon(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:    return Icons.person;
      case WikiEntryType.Place:     return Icons.place;
      case WikiEntryType.Lore:      return Icons.book;
      case WikiEntryType.Faction:   return Icons.groups;
      case WikiEntryType.Magic:     return Icons.auto_awesome;
      case WikiEntryType.History:   return Icons.history;
      case WikiEntryType.Item:      return Icons.inventory_2;
      case WikiEntryType.Quest:     return Icons.flag;
      case WikiEntryType.Creature:  return Icons.pets;
    }
  }

  // ─── LINKED QUESTS ────────────────────────────────────────────────────────

  Widget _buildLinkedQuestsRow(Scene scene) {
    return FutureBuilder<List<Quest>>(
      key: ValueKey('quests_${scene.id}_$_questUpdateCounter'),
      future: _loadLinkedQuests(scene.linkedQuestIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          children: snapshot.data!
              .map((quest) => _buildInlineQuestCard(quest))
              .toList(),
        );
      },
    );
  }

  Widget _buildInlineQuestCard(Quest quest) {
    final statusColor = _getQuestStatusColor(quest.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  quest.title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuestActionButton(
                icon: Icons.remove_circle_outline,
                label: 'Aufgegeben',
                color: const Color(0xFFB45309),
                isSelected: quest.status == QuestStatus.abandoned,
                onTap: () => _updateQuestStatus(quest, QuestStatus.abandoned),
              ),
              const SizedBox(width: 5),
              _buildQuestActionButton(
                icon: Icons.play_circle_outline,
                label: 'Aktiv',
                color: const Color(0xFF1A7F4B),
                isSelected: quest.status == QuestStatus.active,
                onTap: () => _updateQuestStatus(quest, QuestStatus.active),
              ),
              const SizedBox(width: 5),
              _buildQuestActionButton(
                icon: Icons.check_circle_outline,
                label: 'Erledigt',
                color: const Color(0xFF1A7F4B),
                isSelected: quest.status == QuestStatus.completed,
                onTap: () => _updateQuestStatus(quest, QuestStatus.completed),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 5),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.2)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: isSelected
                  ? color
                  : color.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? color : color.withValues(alpha: 0.6),
                size: 11,
              ),
              const SizedBox(width: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: isSelected ? color : color.withValues(alpha: 0.7),
                  fontWeight: isSelected
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateQuestStatus(Quest quest, QuestStatus newStatus) async {
    try {
      final questRepo = context.read<QuestModelRepository>();
      final updatedQuest = quest.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      await questRepo.update(updatedQuest);
      setState(() {
        _questUpdateCounter++;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '"${quest.title}" als ${_getQuestStatusText(newStatus)} markiert',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            backgroundColor: _getQuestStatusColor(newStatus),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Aktualisieren: $e'),
            backgroundColor: DnDTheme.errorRed,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<List<Quest>> _loadLinkedQuests(List<String> questIds) async {
    final List<Quest> result = [];
    try {
      final questRepo = context.read<QuestModelRepository>();
      for (final questId in questIds) {
        try {
          final quest = await questRepo.findById(questId);
          if (quest != null) result.add(quest);
        } catch (_) {}
      }
    } catch (_) {}
    return result;
  }

  Color _getQuestStatusColor(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:    return const Color(0xFF1A7F4B);
      case QuestStatus.onHold:    return const Color(0xFF2F6FEB);
      case QuestStatus.completed: return const Color(0xFF1A7F4B);
      case QuestStatus.failed:    return const Color(0xFFC93A3A);
      case QuestStatus.abandoned: return const Color(0xFFB45309);
    }
  }

  String _getQuestStatusText(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:    return 'Aktiv';
      case QuestStatus.onHold:    return 'Pause';
      case QuestStatus.completed: return 'Erledigt';
      case QuestStatus.failed:    return 'Fehlgeschlagen';
      case QuestStatus.abandoned: return 'Aufgegeben';
    }
  }

  // ─── CHARACTER TYPE HELPERS ───────────────────────────────────────────────

  Color _getCharacterTypeColor(String type) {
    switch (type) {
      case 'pc':      return const Color(0xFF1A7F4B);
      case 'npc':     return const Color(0xFF2F6FEB);
      case 'monster': return const Color(0xFFC93A3A);
      default:        return const Color(0xFF6B6B66);
    }
  }

  IconData _getCharacterTypeIcon(String type) {
    switch (type) {
      case 'pc':      return Icons.person;
      case 'npc':     return Icons.person_outline;
      case 'monster': return Icons.pets;
      default:        return Icons.person;
    }
  }

  // ─── DURATION FORMAT ──────────────────────────────────────────────────────

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}min';
    if (hours > 0) return '${hours}h';
    return '${minutes}min';
  }

  // ─── SCENE OPTIONS ────────────────────────────────────────────────────────

  void _showSceneOptions(Scene scene) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: DnDTheme.slateGrey,
            endColor: DnDTheme.stoneGrey,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(DnDTheme.radiusLarge),
            topRight: Radius.circular(DnDTheme.radiusLarge),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    Icon(Icons.edit, color: DnDTheme.arcaneBlue, size: 20),
                title: Text(
                  'Bearbeiten',
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditSceneDialog(scene);
                },
              ),
              Divider(color: DnDTheme.stoneGrey),
              ListTile(
                leading: Icon(Icons.arrow_upward,
                    color: DnDTheme.arcaneBlue, size: 20),
                title: Text(
                  'Nach oben verschieben',
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewModel.moveSceneUp(scene.id);
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_downward,
                    color: DnDTheme.arcaneBlue, size: 20),
                title: Text(
                  'Nach unten verschieben',
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewModel.moveSceneDown(scene.id);
                },
              ),
              Divider(color: DnDTheme.stoneGrey),
              ListTile(
                leading:
                    Icon(Icons.delete, color: DnDTheme.errorRed, size: 20),
                title: Text(
                  'Löschen',
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteSceneConfirm(scene);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateSceneDialog() {
    _showEditSceneDialog(null, isCreate: true);
  }

  void _showResetConfirmDialog(
    ActiveSessionViewModel viewModel,
    AppColorsExtension C,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: C.border),
        ),
        title: Row(
          children: [
            Icon(Icons.restart_alt, color: C.amber, size: 20),
            const SizedBox(width: 8),
            Text(
              'Session zurücksetzen?',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: C.text),
            ),
          ],
        ),
        content: Text(
          'Alle Szenen werden auf "offen" zurückgesetzt und die aktive Szene wird gelöscht.\n\nDie Notizen und Sounds bleiben erhalten.',
          style: TextStyle(fontSize: 13, color: C.textMid, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Abbrechen', style: TextStyle(color: C.textSoft)),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: C.amber),
            icon: const Icon(Icons.restart_alt, size: 14),
            label: const Text('Zurücksetzen', style: TextStyle(fontSize: 13)),
            onPressed: () {
              Navigator.pop(ctx);
              viewModel.resetSession();
            },
          ),
        ],
      ),
    );
  }

  void _showEditSceneDialog(Scene? scene, {bool isCreate = false}) async {
    final sceneRepository = context.read<SceneModelRepository>();
    final creatureRepository = context.read<CreatureModelRepository>();
    final playerCharacterRepository =
        context.read<PlayerCharacterModelRepository>();
    final questRepository = context.read<QuestModelRepository>();
    final soundRepository = context.read<SoundModelRepository>();
    final wikiEntryRepository = context.read<WikiEntryModelRepository>();
    final encounterRepository = context.read<EncounterModelRepository>();

    final sessionId = scene == null ? widget.session.id : null;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (context) => MultiProvider(
          providers: [
            ChangeNotifierProvider(
              create: (_) => EditSceneViewModel(
                sceneRepository: sceneRepository,
                creatureRepository: creatureRepository,
                playerCharacterRepository: playerCharacterRepository,
                questRepository: questRepository,
                soundRepository: soundRepository,
                wikiEntryRepository: wikiEntryRepository,
                encounterRepository: encounterRepository,
              ),
            ),
          ],
          child: EditSceneScreen(
            scene: scene,
            sessionId: sessionId,
          ),
        ),
      ),
    );

    if (result == true) {
      await _viewModel.triggerDataReload();
    }
  }

  void _showDeleteSceneConfirm(Scene scene) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Szene löschen?',
          style: DnDTheme.headline3.copyWith(color: DnDTheme.errorRed),
        ),
        content: Text(
          'Möchtest du "${scene.name}" wirklich löschen?',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(color: DnDTheme.mysticalPurple),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _viewModel.deleteScene(scene.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  // ─── ENCOUNTER ────────────────────────────────────────────────────────────

  void _startEncounter() {
    final activeSceneId = _viewModel.currentSession.activeSceneId;
    if (activeSceneId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte aktiviere zuerst eine Szene!'),
          duration: Duration(seconds: 2),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final activeScene = _viewModel.scenes.firstWhere(
      (scene) => scene.id == activeSceneId,
      orElse: () => throw Exception('Scene nicht gefunden'),
    );

    _startEncounterForScene(activeScene);
  }

  Future<void> _startEncounterForScene(Scene scene) async {
    String? title;
    String? description;
    List<String> characterIds = const [];
    List<String> monsterIds = const [];

    if (scene.linkedEncounterId != null) {
      final encounterRepo = context.read<EncounterModelRepository>();
      final encounter = await encounterRepo.findById(scene.linkedEncounterId!);
      if (encounter != null) {
        title = encounter.title;
        description = encounter.description;

        // Load actual participant records to extract character/creature IDs
        final participantRepo = EncounterParticipantModelRepository(
          DatabaseConnection.instance,
        );
        final participants = await participantRepo.findByEncounter(encounter.id);
        characterIds = participants
            .where((p) => p.characterId != null)
            .map((p) => p.characterId!)
            .toList();
        monsterIds = participants
            .where((p) => p.creatureId != null)
            .map((p) => p.creatureId!)
            .toList();
      }
    }

    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => EncounterSetupScreen(
          campaign: _viewModel.campaign,
          scene: scene,
          encounterTitle: title,
          preselectedDescription: description,
          preselectedCharacterIds: characterIds,
          preselectedMonsterIds: monsterIds,
        ),
      ),
    );
  }
}
