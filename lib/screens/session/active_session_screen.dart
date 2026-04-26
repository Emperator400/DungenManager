import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../database/repositories/creature_model_repository.dart';
import '../../database/repositories/encounter_model_repository.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../database/repositories/quest_model_repository.dart';
import '../../database/repositories/scene_model_repository.dart';
import '../../database/repositories/sound_model_repository.dart';
import '../../database/repositories/wiki_entry_model_repository.dart';
import '../../models/campaign.dart';
import '../../models/quest.dart';
import '../../models/scene.dart';
import '../../models/session.dart';
import '../../models/sound.dart';
import '../../models/wiki_entry.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import '../../viewmodels/edit_scene_viewmodel.dart';
import '../../widgets/active_session/live_notes_quadrant.dart';
import '../../widgets/active_session/quest_list_section.dart';
import '../../widgets/audio/sound_mixer_widget.dart';
import '../../widgets/lore_keeper/wiki_entry_popup_dialog.dart';
import '../scenes/edit_scene_screen.dart';
import 'encounter_setup_screen.dart' as encounter_setup;

class ActiveSessionScreen extends StatefulWidget {
  final Campaign campaign;
  final Session session;

  const ActiveSessionScreen({
    required this.session,
    required this.campaign,
    super.key,
  });

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  late ActiveSessionViewModel _viewModel;
  int _questUpdateCounter = 0;
  final Set<String> _expandedSceneIds = {};

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
    _viewModel.stopSessionSound();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return ChangeNotifierProvider<ActiveSessionViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: C.bg,
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() => Consumer<ActiveSessionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.error != null) {
            return _buildErrorWidget(viewModel.error!);
          }
          return Column(
            children: [
              _buildTopBar(viewModel),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 62, child: _buildSceneFlowPanel(viewModel)),
                    Container(width: 1, color: context.appColors.border),
                    Expanded(flex: 38, child: _buildRightPane(viewModel)),
                  ],
                ),
              ),
            ],
          );
        },
      );

  Widget _buildTopBar(ActiveSessionViewModel viewModel) {
    final C = context.appColors;
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(Icons.arrow_back_ios, size: 16, color: C.textMid),
            ),
          ),
          Container(width: 1, height: 18, color: C.border, margin: const EdgeInsets.symmetric(horizontal: 10)),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.currentSession.title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: C.text),
              ),
              Row(
                children: [
                  Icon(Icons.access_time, size: 11, color: C.textSoft),
                  const SizedBox(width: 4),
                  Text(
                    'In-Game Zeit: ${viewModel.getFormattedInGameTime()}',
                    style: TextStyle(fontSize: 11, color: C.textSoft),
                  ),
                ],
              ),
            ],
          ),
          const Spacer(),
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
                  decoration: BoxDecoration(color: C.green, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
                Text('Aktiv', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: C.green)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: C.bgHover,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: C.border),
            ),
            child: Text(viewModel.campaign.title, style: TextStyle(fontSize: 11, color: C.textMid)),
          ),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: C.textMid, size: 18),
            color: C.bgPanel,
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              PopupMenuItem(value: 'edit_title', child: Row(children: [Icon(Icons.edit, color: C.amber, size: 16), const SizedBox(width: 8), Text('Titel bearbeiten', style: TextStyle(color: C.text, fontSize: 13))])),
              PopupMenuItem(value: 'add_time_15', child: Row(children: [Icon(Icons.add, color: C.green, size: 16), const SizedBox(width: 8), Text('+15 Min', style: TextStyle(color: C.text, fontSize: 13))])),
              PopupMenuItem(value: 'add_time_30', child: Row(children: [Icon(Icons.add, color: C.green, size: 16), const SizedBox(width: 8), Text('+30 Min', style: TextStyle(color: C.text, fontSize: 13))])),
              PopupMenuItem(value: 'add_time_60', child: Row(children: [Icon(Icons.add, color: C.green, size: 16), const SizedBox(width: 8), Text('+1 Std', style: TextStyle(color: C.text, fontSize: 13))])),
            ],
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _startEncounter,
            icon: const Icon(Icons.gavel, size: 13),
            label: const Text('Kampf', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: C.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneFlowPanel(ActiveSessionViewModel viewModel) {
    final C = context.appColors;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: C.bgPanel,
            border: Border(bottom: BorderSide(color: C.border)),
          ),
          child: Row(
            children: [
              Icon(Icons.list_alt, color: C.accent, size: 14),
              const SizedBox(width: 7),
              Text('Szenen-Ablauf', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.text)),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                decoration: BoxDecoration(color: C.bgHover, borderRadius: BorderRadius.circular(4)),
                child: Text('${viewModel.scenes.length} Szenen', style: TextStyle(fontSize: 10, color: C.textSoft)),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _showCreateSceneDialog,
                icon: const Icon(Icons.add, size: 12),
                label: const Text('Neue Szene', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: C.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  elevation: 0,
                ),
              ),
            ],
          ),
        ),
        Expanded(child: _buildSceneFlowWidget(viewModel)),
      ],
    );
  }

  Widget _buildRightPane(ActiveSessionViewModel viewModel) {
    final C = context.appColors;
    return Container(
      color: C.bgPanel,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLiveNotesSection(viewModel),
            _buildAtmosphereSection(viewModel),
            _buildQuestSection(viewModel),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveNotesSection(ActiveSessionViewModel viewModel) {
    final C = context.appColors;
    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
            child: Row(
              children: [
                Icon(Icons.sticky_note_2_outlined, color: C.amber, size: 13),
                const SizedBox(width: 6),
                Text('Live-Notizen', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text)),
              ],
            ),
          ),
          SizedBox(height: 180, child: _buildLiveNotesWidget(viewModel)),
        ],
      ),
    );
  }

  Widget _buildAtmosphereSection(ActiveSessionViewModel viewModel) {
    final C = context.appColors;
    final activeSceneId = viewModel.currentSession.activeSceneId;
    Map<String, double> soundVolumes = {};
    if (activeSceneId != null) {
      final sceneIndex = viewModel.scenes.indexWhere((s) => s.id == activeSceneId);
      if (sceneIndex != -1) soundVolumes = viewModel.scenes[sceneIndex].soundVolumes;
    }
    final preloadedSounds = activeSceneId != null ? viewModel.sceneSoundsFor(activeSceneId) : <Sound>[];

    return Container(
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: C.border))),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note, color: C.accent, size: 13),
              const SizedBox(width: 6),
              Text('Atmosphäre', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text)),
            ],
          ),
          const SizedBox(height: 10),
          SoundMixerWidget(
            key: ValueKey('atmosphere_${activeSceneId ?? "none"}'),
            initialSounds: preloadedSounds.isNotEmpty ? preloadedSounds : null,
            initialVolumes: soundVolumes,
            config: const SoundMixerConfig(
              compactMode: true,
              showAddButtons: true,
              showMasterVolume: true,
              showStopAllButton: true,
              showChannelCounter: false,
              readOnly: false,
              showDivider: false,
              showHeader: false,
            ),
            onSoundsChanged: activeSceneId != null
                ? (soundIds) => viewModel.updateSceneSounds(activeSceneId, soundIds)
                : null,
            onVolumesChanged: activeSceneId != null
                ? (volumes) => viewModel.updateSceneSoundVolumes(activeSceneId, volumes)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestSection(ActiveSessionViewModel viewModel) {
    final C = context.appColors;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Row(
            children: [
              Icon(Icons.flag_outlined, color: const Color(0xFF7c3aed), size: 13),
              const SizedBox(width: 6),
              Text('Quests', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text)),
            ],
          ),
        ),
        SizedBox(
          height: 380,
          child: QuestListSection(
            key: ValueKey('quest_list_$_questUpdateCounter'),
            campaignId: viewModel.campaign.id,
            onQuestUpdated: () => setState(() => _questUpdateCounter++),
          ),
        ),
      ],
    );
  }

  Widget _buildSceneFlowWidget(ActiveSessionViewModel viewModel) =>
      _buildSceneListContent(viewModel, viewModel.scenes);

  Widget _buildSceneListContent(ActiveSessionViewModel viewModel, List<Scene> scenes) {
    final C = context.appColors;
    if (scenes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.list_alt, size: 32, color: C.textSoft),
            const SizedBox(height: 8),
            Text(
              'Keine Szenen',
              style: TextStyle(color: C.text, fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Erstelle deine erste Szene',
              style: TextStyle(color: C.textMid, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _showCreateSceneDialog,
              icon: const Icon(Icons.add, size: 14),
              label: const Text('Szene erstellen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: C.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                textStyle: const TextStyle(fontSize: 9),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: scenes.length,
      itemBuilder: (context, index) {
        final scene = scenes[index];
        final isActive = viewModel.currentSession.activeSceneId == scene.id;
        return _buildSceneCard(
          scene: scene,
          isActive: isActive,
          onTap: () => _showSceneOptions(scene),
        );
      },
    );
  }

  Widget _buildSceneCard({
    required Scene scene,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final C = context.appColors;
    final typeColor = _sceneTypeColor(scene.sceneType);
    final isExpanded = _expandedSceneIds.contains(scene.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Left type-color strip ──
            Container(width: 3, color: typeColor),
            // ── Content ──
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header row (always visible) ──
                  GestureDetector(
                    onTap: () => setState(() {
                      if (isExpanded) {
                        _expandedSceneIds.remove(scene.id);
                      } else {
                        _expandedSceneIds.add(scene.id);
                      }
                    }),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: scene.isCompleted ? C.green : typeColor,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${scene.orderIndex + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(scene.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: C.text)),
                        Row(
                          children: [
                            Text(scene.sceneTypeDisplayName, style: TextStyle(fontSize: 11, color: C.textMid)),
                            if (scene.linkedEncounterId != null) ...[
                              const SizedBox(width: 6),
                              Icon(Icons.gavel, color: C.red, size: 12),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (scene.isCompleted) Icon(Icons.check_circle, color: C.green, size: 16),
                  if (isActive) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.play_circle_filled, color: C.amber, size: 16),
                  ],
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Icon(Icons.more_horiz, color: C.textSoft, size: 16),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: C.textSoft,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          // ── Expanded content ──
          if (isExpanded) ...[
            Divider(height: 1, thickness: 1, color: C.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (scene.description.isNotEmpty) ...[
                    _sceneSectionLabel('Beschreibung', C),
                    Text(scene.description, style: TextStyle(fontSize: 12, color: C.textMid, height: 1.6)),
                    const SizedBox(height: 10),
                  ],
                  if (scene.linkedQuestIds.isNotEmpty) ...[
                    _sceneSectionLabel('Verknüpfte Quests', C),
                    _buildLinkedQuestsRow(scene),
                    const SizedBox(height: 10),
                  ],
                  if (scene.linkedSoundIds.isNotEmpty) ...[
                    _sceneSectionLabel('Verknüpfte Sounds', C),
                    _buildLinkedSoundsRow(scene),
                    const SizedBox(height: 10),
                  ],
                  if (scene.linkedCharacterIds.isNotEmpty) ...[
                    _sceneSectionLabel('Verknüpfte Charaktere', C),
                    _buildLinkedCharactersRow(scene),
                    const SizedBox(height: 10),
                  ],
                  if (scene.linkedWikiEntryIds.isNotEmpty) ...[
                    _sceneSectionLabel('Verknüpfte Wiki-Einträge', C),
                    _buildLinkedWikiEntriesRow(scene),
                    const SizedBox(height: 10),
                  ],
                  if (scene.sceneType == SceneType.Combat &&
                      scene.linkedEncounterId != null &&
                      scene.linkedEncounterId!.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _startEncounterForScene(scene),
                        icon: const Icon(Icons.gavel, size: 14),
                        label: const Text('Kampf starten'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: C.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (scene.complexity != null || scene.estimatedDuration != null) ...[
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 4,
                      children: [
                        if (scene.complexity != null)
                          _sceneBadge(scene.complexityDisplayName, const Color(0xFF7C3AED), Icons.trending_up),
                        if (scene.estimatedDuration != null)
                          _sceneBadge(_formatDuration(scene.estimatedDuration!), C.accent, Icons.schedule),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
                ],          // closes outer Column.children
              ),            // closes outer Column
            ),              // closes Expanded
          ],                // closes Row.children
        ),                  // closes Row
      ),                    // closes IntrinsicHeight
    );
  }

  Widget _sceneSectionLabel(String label, AppColorsExtension C) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          label,
          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: C.textMid, letterSpacing: 0.4),
        ),
      );

  Widget _sceneBadge(String text, Color color, IconData icon) => Container(
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
            Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w500)),
          ],
        ),
      );

  Color _sceneTypeColor(SceneType type) => switch (type) {
        SceneType.Introduction => const Color(0xFF2f6feb),
        SceneType.Social => const Color(0xFF7c3aed),
        SceneType.Exploration => const Color(0xFF1a7f4b),
        SceneType.Combat => const Color(0xFFc93a3a),
        SceneType.Puzzle => const Color(0xFFb45309),
        SceneType.Climax => const Color(0xFF0891b2),
        SceneType.Resolution => const Color(0xFF6b7280),
      };

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}min';
    if (hours > 0) return '${hours}h';
    return '${minutes}min';
  }

  Widget _buildLinkedSoundsRow(Scene scene) {
    if (scene.linkedSoundIds.isEmpty) return const SizedBox.shrink();
    final viewModel = context.read<ActiveSessionViewModel>();
    final preloadedSounds = viewModel.sceneSoundsFor(scene.id);
    return SoundMixerWidget(
      size: SoundMixerSize.minimal,
      key: ValueKey('mixer_${scene.id}'),
      initialSounds: preloadedSounds.isNotEmpty ? preloadedSounds : null,
      initialVolumes: scene.soundVolumes,
      onSoundsChanged: (soundIds) => viewModel.updateSceneSounds(scene.id, soundIds),
      onVolumesChanged: (volumes) => viewModel.updateSceneSoundVolumes(scene.id, volumes),
    );
  }

  Widget _buildLinkedCharactersRow(Scene scene) {
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: _loadLinkedCharacters(scene.linkedCharacterIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        final C = context.appColors;
        return Wrap(
          spacing: 5,
          runSpacing: 5,
          children: snapshot.data!.values.map((char) {
            final name = char['name'] as String;
            final level = char['level'] as String?;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: C.bgHover,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: C.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_outline, color: C.textSoft, size: 10),
                  const SizedBox(width: 5),
                  Text(
                    level != null ? '$name ($level)' : name,
                    style: TextStyle(fontSize: 11, color: C.textMid),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<Map<String, Map<String, dynamic>>> _loadLinkedCharacters(List<String> characterIds) async {
    final result = <String, Map<String, dynamic>>{};
    try {
      final creatureRepo = context.read<CreatureModelRepository>();
      final pcRepo = context.read<PlayerCharacterModelRepository>();
      for (final charId in characterIds) {
        try {
          final pc = await pcRepo.findById(charId);
          if (pc != null) {
            result[charId] = {'name': pc.name, 'type': 'pc', 'level': 'Lvl ${pc.level}'};
            continue;
          }
        } catch (_) {}
        try {
          final creature = await creatureRepo.findById(charId);
          if (creature != null) {
            result[charId] = {
              'name': creature.name,
              'type': creature.sourceType == 'official' ? 'monster' : 'npc',
              'level': creature.challengeRating != null ? 'CR ${creature.challengeRating}' : null,
            };
          }
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Charaktere: $e');
    }
    return result;
  }

  Widget _buildLinkedWikiEntriesRow(Scene scene) {
    return FutureBuilder<List<WikiEntry>>(
      future: _loadLinkedWikiEntries(scene.linkedWikiEntryIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: context.appColors.textSoft),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        const purple = Color(0xFF7C3AED);
        return Wrap(
          spacing: 5,
          runSpacing: 5,
          children: snapshot.data!.map((wikiEntry) => GestureDetector(
            onTap: () => WikiEntryPopupDialog.show(context: context, entry: wikiEntry),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: purple.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.book_outlined, color: purple, size: 10),
                  const SizedBox(width: 5),
                  Text(wikiEntry.title, style: const TextStyle(fontSize: 11, color: purple)),
                ],
              ),
            ),
          )).toList(),
        );
      },
    );
  }

  Future<List<WikiEntry>> _loadLinkedWikiEntries(List<String> wikiEntryIds) async {
    final result = <WikiEntry>[];
    try {
      final wikiEntryRepo = context.read<WikiEntryModelRepository>();
      for (final wikiId in wikiEntryIds) {
        try {
          final wikiEntry = await wikiEntryRepo.findById(wikiId);
          if (wikiEntry != null) result.add(wikiEntry);
        } catch (e) {
          debugPrint('Wiki-Eintrag $wikiId konnte nicht geladen werden: $e');
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Wiki-Einträge: $e');
    }
    return result;
  }

  Widget _buildLinkedQuestsRow(Scene scene) {
    return FutureBuilder<List<Quest>>(
      key: ValueKey('quests_${scene.id}_$_questUpdateCounter'),
      future: _loadLinkedQuests(scene.linkedQuestIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 16,
            width: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: context.appColors.textSoft),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
        return Wrap(
          spacing: 5,
          runSpacing: 5,
          children: snapshot.data!.map((quest) {
            final statusColor = _getQuestStatusColor(quest.status);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
                border: Border.all(color: statusColor.withValues(alpha: 0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.flag_outlined, color: statusColor, size: 10),
                  const SizedBox(width: 5),
                  Text(quest.title, style: TextStyle(fontSize: 11, color: context.appColors.textMid)),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<List<Quest>> _loadLinkedQuests(List<String> questIds) async {
    final result = <Quest>[];
    try {
      final questRepo = context.read<QuestModelRepository>();
      for (final questId in questIds) {
        try {
          final quest = await questRepo.findById(questId);
          if (quest != null) result.add(quest);
        } catch (e) {
          debugPrint('Quest $questId konnte nicht geladen werden: $e');
        }
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Quests: $e');
    }
    return result;
  }

  Color _getQuestStatusColor(QuestStatus status) {
    final C = context.appColors;
    return switch (status) {
      QuestStatus.active => C.green,
      QuestStatus.onHold => C.textMid,
      QuestStatus.completed => C.green,
      QuestStatus.failed => C.red,
      QuestStatus.abandoned => C.amber,
    };
  }

  void _showSceneOptions(Scene scene) {
    final C = context.appColors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: C.bgHover,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit, color: C.accent, size: 20),
                title: Text('Bearbeiten', style: TextStyle(fontSize: 14, color: C.text)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditSceneDialog(scene);
                },
              ),
              ListTile(
                leading: Icon(Icons.play_circle_filled, color: C.amber, size: 20),
                title: Text('Szene aktivieren', style: TextStyle(fontSize: 14, color: C.text)),
                subtitle: Text('Aktiviert Szene und ihre Quests', style: TextStyle(color: C.textSoft, fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _viewModel.activateScene(scene.id);
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: C.green, size: 20),
                title: Text('Szene abschließen', style: TextStyle(fontSize: 14, color: C.text)),
                subtitle: Text('Schließt Szene, Quests und Encounters', style: TextStyle(color: C.textSoft, fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  _viewModel.completeScene(scene.id);
                },
              ),
              Divider(color: C.border),
              ListTile(
                leading: Icon(Icons.arrow_upward, color: C.accent, size: 20),
                title: Text('Nach oben verschieben', style: TextStyle(fontSize: 14, color: C.text)),
                onTap: () {
                  Navigator.pop(context);
                  _viewModel.moveSceneUp(scene.id);
                },
              ),
              ListTile(
                leading: Icon(Icons.arrow_downward, color: C.accent, size: 20),
                title: Text('Nach unten verschieben', style: TextStyle(fontSize: 14, color: C.text)),
                onTap: () {
                  Navigator.pop(context);
                  _viewModel.moveSceneDown(scene.id);
                },
              ),
              Divider(color: C.border),
              ListTile(
                leading: Icon(Icons.delete, color: C.red, size: 20),
                title: Text('Löschen', style: TextStyle(fontSize: 14, color: C.red)),
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

  void _showEditSceneDialog(Scene? scene, {bool isCreate = false}) async {
    final sceneRepository = context.read<SceneModelRepository>();
    final creatureRepository = context.read<CreatureModelRepository>();
    final playerCharacterRepository = context.read<PlayerCharacterModelRepository>();
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
          child: EditSceneScreen(scene: scene, sessionId: sessionId),
        ),
      ),
    );

    if (result == true) {
      await _viewModel.triggerDataReload();
    }
  }

  void _showDeleteSceneConfirm(Scene scene) {
    final C = context.appColors;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text(
          'Szene löschen?',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: C.red),
        ),
        content: Text(
          'Möchtest du "${scene.name}" wirklich löschen?',
          style: TextStyle(fontSize: 14, color: C.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _viewModel.deleteScene(scene.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: C.red, foregroundColor: Colors.white),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNotesWidget(ActiveSessionViewModel viewModel) =>
      LiveNotesQuadrant(viewModel: viewModel);



  Widget _buildErrorWidget(String error) {
    final C = context.appColors;
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: C.bgPanel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: C.accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: C.red, size: 48),
            const SizedBox(height: 16),
            Text(
              'Fehler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: C.red),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: TextStyle(fontSize: 13, color: C.textMid),
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
                backgroundColor: C.accent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'edit_title':
        _showEditTitleDialog();
      case 'add_time_15':
        await _viewModel.addInGameTime(15);
      case 'add_time_30':
        await _viewModel.addInGameTime(30);
      case 'add_time_60':
        await _viewModel.addInGameTime(60);
    }
  }

  void _showEditTitleDialog() {
    final C = context.appColors;
    final controller = TextEditingController(text: _viewModel.currentSession.title);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text(
          'Session-Titel bearbeiten',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: C.amber),
        ),
        content: TextFormField(
          controller: controller,
          style: TextStyle(color: C.text, fontSize: 14),
          decoration: InputDecoration(
            labelText: 'Titel',
            labelStyle: TextStyle(color: C.amber),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF7C3AED)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: const Color(0xFF7C3AED).withValues(alpha: 0.5)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: C.amber, width: 2),
            ),
            filled: true,
            fillColor: C.bgHover.withValues(alpha: 0.3),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen', style: TextStyle(color: Color(0xFF7C3AED))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _viewModel.updateSessionTitle(controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.amber,
              foregroundColor: C.bg,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  Future<void> _startEncounter() async {
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
    String? encounterTitle;
    if (activeScene.linkedEncounterId != null && activeScene.linkedEncounterId!.isNotEmpty) {
      try {
        final encounterRepo = context.read<EncounterModelRepository>();
        final encounter = await encounterRepo.findById(activeScene.linkedEncounterId!);
        if (encounter != null) encounterTitle = encounter.title;
      } catch (e) {
        debugPrint('Fehler beim Laden des Encounters: $e');
      }
    }
    encounterTitle ??= activeScene.name;
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => encounter_setup.EncounterSetupScreen(
          campaign: _viewModel.campaign,
          scene: activeScene,
          encounterTitle: encounterTitle,
          preselectedCharacterIds: activeScene.linkedCharacterIds,
          preselectedDescription: activeScene.description.isNotEmpty ? activeScene.description : null,
        ),
      ),
    );
  }

  Future<void> _startEncounterForScene(Scene scene) async {
    String? encounterTitle;
    if (scene.linkedEncounterId != null && scene.linkedEncounterId!.isNotEmpty) {
      try {
        final encounterRepo = context.read<EncounterModelRepository>();
        final encounter = await encounterRepo.findById(scene.linkedEncounterId!);
        if (encounter != null) encounterTitle = encounter.title;
      } catch (e) {
        debugPrint('Fehler beim Laden des Encounters: $e');
      }
    }
    encounterTitle ??= scene.name;
    if (!mounted) return;
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => encounter_setup.EncounterSetupScreen(
          campaign: _viewModel.campaign,
          scene: scene,
          encounterTitle: encounterTitle,
          preselectedCharacterIds: scene.linkedCharacterIds,
          preselectedDescription: scene.description.isNotEmpty ? scene.description : null,
        ),
      ),
    );
  }
}
