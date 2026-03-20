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
import '../../database/repositories/wiki_entry_model_repository.dart';
import '../../theme/dnd_theme.dart';
import '../../widgets/audio/sound_player_widget.dart';
import '../../widgets/active_session/live_notes_quadrant.dart';
import '../../widgets/active_session/atmosphere_quadrant.dart';
import '../../widgets/active_session/quest_list_section.dart';
import 'encounter_setup_screen.dart';
import '../scenes/edit_scene_screen.dart';

/// Enhanced Active Session Screen mit Provider-Pattern und modernem D&D Design
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
  final GlobalKey<State> _sceneFlowKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _viewModel = ActiveSessionViewModel(
      session: widget.session,
      campaign: widget.campaign,
    );
    // Session beim Öffnen neu aus der Datenbank laden
    _viewModel.reloadSession();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ActiveSessionViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: DnDTheme.dungeonBlack,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<ActiveSessionViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                viewModel.currentSession.title,
                style: DnDTheme.headline2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
              ),
              Text(
                'In-Game Zeit: ${viewModel.getFormattedInGameTime()}',
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
      backgroundColor: DnDTheme.stoneGrey,
      foregroundColor: Colors.white,
      elevation: 4,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: DnDTheme.stoneGrey,
            endColor: DnDTheme.slateGrey,
          ),
        ),
      ),
      actions: [
        Consumer<ActiveSessionViewModel>(
          builder: (context, viewModel, child) {
            return Container(
              margin: const EdgeInsets.only(right: DnDTheme.sm),
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.arcaneBlue,
                width: 2,
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: DnDTheme.stoneGrey,
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit_title',
                    child: Row(
                      children: [
                        Icon(Icons.edit, color: DnDTheme.ancientGold, size: 20),
                        const SizedBox(width: DnDTheme.sm),
                        Text(
                          'Titel bearbeiten',
                          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'add_time_15',
                    child: Row(
                      children: [
                        Icon(Icons.add, color: DnDTheme.successGreen, size: 20),
                        const SizedBox(width: DnDTheme.sm),
                        Text(
                          '+15 Min',
                          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'add_time_30',
                    child: Row(
                      children: [
                        Icon(Icons.add, color: DnDTheme.successGreen, size: 20),
                        const SizedBox(width: DnDTheme.sm),
                        Text(
                          '+30 Min',
                          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'add_time_60',
                    child: Row(
                      children: [
                        Icon(Icons.add, color: DnDTheme.successGreen, size: 20),
                        const SizedBox(width: DnDTheme.sm),
                        Text(
                          '+1 Std',
                          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<ActiveSessionViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.error != null) {
          return _buildErrorWidget(viewModel.error!);
        }

        return Padding(
          padding: const EdgeInsets.all(DnDTheme.md),
          child: Column(
            children: [
              // Session Info Bar
              _buildSessionInfoBar(viewModel),
              const SizedBox(height: 8),
              
              // Main Content - 2 Column Layout
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Linke Seite: Szenen-Ablauf (volle Höhe)
                    Expanded(
                      flex: 1,
                      child: _buildSceneFlowPanel(viewModel),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Rechte Seite: Scrollbare Sidebar mit Live-Notizen, Atmosphäre und Quests
                    Expanded(
                      flex: 1,
                      child: _buildScrollableSidebar(viewModel),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSessionInfoBar(ActiveSessionViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DnDTheme.sm, vertical: 4),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.ancientGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: DnDTheme.ancientGold,
              shape: BoxShape.circle,
              border: Border.all(
                color: DnDTheme.stoneGrey,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.play_circle_filled,
              color: DnDTheme.dungeonBlack,
              size: 16,
            ),
          ),
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Kampagne: ${viewModel.campaign.title}',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              gradient: DnDTheme.getMysticalGradient(
                startColor: DnDTheme.arcaneBlue,
                endColor: DnDTheme.mysticalPurple,
              ),
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              border: Border.all(
                color: DnDTheme.ancientGold.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: DnDTheme.xs),
                Text(
                  'Aktiv',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Baut das Szenen-Ablauf Panel (linke Seite, volle Höhe)
  Widget _buildSceneFlowPanel(ActiveSessionViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.arcaneBlue.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DnDTheme.arcaneBlue.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DnDTheme.radiusMedium),
                topRight: Radius.circular(DnDTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.list_alt, color: DnDTheme.arcaneBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Szenen-Ablauf',
                  style: DnDTheme.bodyText1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${viewModel.scenes.length} Szenen',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildSceneFlowWidget(viewModel),
          ),
        ],
      ),
    );
  }

  /// Baut das Live-Notizen Panel (rechts oben)
  Widget _buildLiveNotesPanel(ActiveSessionViewModel viewModel) {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.ancientGold.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DnDTheme.ancientGold.withValues(alpha: 0.2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DnDTheme.radiusMedium),
                topRight: Radius.circular(DnDTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.note_alt, color: DnDTheme.ancientGold, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Live-Notizen',
                  style: DnDTheme.bodyText1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: _buildLiveNotesWidget(viewModel),
          ),
        ],
      ),
    );
  }

  /// Baut das Atmosphäre Panel (rechts unten) mit Sound Mixer
  Widget _buildAtmospherePanel(ActiveSessionViewModel viewModel) {
    // Hole verknüpfte Sounds der aktiven Szene
    final activeSceneId = viewModel.currentSession.activeSceneId;
    List<String> linkedSoundIds = [];
    
    if (activeSceneId != null) {
      final activeScene = viewModel.scenes.firstWhere(
        (scene) => scene.id == activeSceneId,
        orElse: () => throw Exception('Scene nicht gefunden'),
      );
      linkedSoundIds = activeScene.linkedSoundIds;
    }
    
    return AtmosphereQuadrant(
      initialSoundIds: linkedSoundIds,
    );
  }

  /// Baut die scrollbare rechte Sidebar mit Live-Notizen, Atmosphäre und Quests
  Widget _buildScrollableSidebar(ActiveSessionViewModel viewModel) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Live-Notizen (350px Höhe)
          SizedBox(
            height: 350,
            child: _buildLiveNotesPanel(viewModel),
          ),
          
          const SizedBox(height: 8),
          
          // Atmosphäre (450px Höhe) - Sound Mixer
          SizedBox(
            height: 450,
            child: _buildAtmospherePanel(viewModel),
          ),
          
          const SizedBox(height: 8),
          
          // Quest-Liste (350px Höhe)
          SizedBox(
            height: 350,
            child: QuestListSection(
              campaignId: viewModel.campaign.id,
              onQuestUpdated: () {
                // Szenen neu laden um Quest-Status in Szenen-Karten zu aktualisieren
                _viewModel.triggerDataReload();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneFlowWidget(ActiveSessionViewModel viewModel) {
    final scenes = viewModel.scenes;
    
    if (scenes.isEmpty) {
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
              onPressed: () => _showCreateSceneDialog(),
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
    
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
      padding: const EdgeInsets.all(2),
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
          ),
        ),
        // Add Scene Button
        Padding(
          padding: const EdgeInsets.all(8),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateSceneDialog(),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Neue Szene', style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.arcaneBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildSceneCard({
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
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
              fontSize: 14,
            ),
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scene.name,
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        scene.sceneTypeDisplayName,
                        style: DnDTheme.bodyText2.copyWith(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      // Encounter Link Indicator
                      if (scene.linkedEncounterId != null) ...[
                        const SizedBox(width: 6),
                        Icon(
                          Icons.gavel,
                          color: DnDTheme.errorRed,
                          size: 14,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Status Icons
            Row(
              children: [
                if (scene.isCompleted)
                  Icon(
                    Icons.check_circle,
                    color: DnDTheme.successGreen,
                    size: 18,
                  ),
                if (isActive)
                  Icon(
                    Icons.play_circle_filled,
                    color: DnDTheme.ancientGold,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onTap,
                  child: Icon(
                    Icons.more_vert,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: const SizedBox.shrink(), // Wir haben unsere eigenen Icons
        backgroundColor: Colors.transparent,
        children: [
          // Expanded Content
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                // Beschreibung
                if (scene.description.isNotEmpty) ...[
                  Text(
                    'Beschreibung',
                    style: DnDTheme.bodyText2.copyWith(
                      color: DnDTheme.ancientGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    scene.description,
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                // Verknüpfte Quests
                if (scene.linkedQuestIds.isNotEmpty) ...[
                  Text(
                    'Verknüpfte Quests',
                    style: DnDTheme.bodyText2.copyWith(
                      color: DnDTheme.ancientGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildLinkedQuestsRow(scene),
                  const SizedBox(height: 12),
                ],
                // Verknüpfte Sounds
                if (scene.linkedSoundIds.isNotEmpty) ...[
                  Text(
                    'Verknüpfte Sounds',
                    style: DnDTheme.bodyText2.copyWith(
                      color: DnDTheme.ancientGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildLinkedSoundsRow(scene),
                  const SizedBox(height: 12),
                ],
                // Verknüpfte Charaktere
                if (scene.linkedCharacterIds.isNotEmpty) ...[
                  Text(
                    'Verknüpfte Charaktere',
                    style: DnDTheme.bodyText2.copyWith(
                      color: DnDTheme.ancientGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildLinkedCharactersRow(scene),
                  const SizedBox(height: 12),
                ],
                // Verknüpfte Wiki-Einträge
                if (scene.linkedWikiEntryIds.isNotEmpty) ...[
                  Text(
                    'Verknüpfte Wiki-Einträge',
                    style: DnDTheme.bodyText2.copyWith(
                      color: DnDTheme.ancientGold,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  _buildLinkedWikiEntriesRow(scene),
                  const SizedBox(height: 12),
                ],
                // Zusätzliche Details
                Row(
                  children: [
                    // Komplexität
                    if (scene.complexity != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: DnDTheme.mysticalPurple.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                          border: Border.all(
                            color: DnDTheme.mysticalPurple.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.trending_up,
                              color: DnDTheme.mysticalPurple,
                              size: 8,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              scene.complexityDisplayName,
                              style: DnDTheme.bodyText2.copyWith(
                                color: Colors.white,
                                fontSize: 7,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                    ],
                    // Geschätzte Dauer
                    if (scene.estimatedDuration != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: DnDTheme.arcaneBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                          border: Border.all(
                            color: DnDTheme.arcaneBlue.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              color: DnDTheme.arcaneBlue,
                              size: 8,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              _formatDuration(scene.estimatedDuration!),
                              style: DnDTheme.bodyText2.copyWith(
                                color: Colors.white,
                                fontSize: 7,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Formatiert eine Duration für die Anzeige
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    
    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}min';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}min';
    }
  }

  /// Baut eine Reihe mit verknüpften Sounds mit voller Playback-Steuerung
  Widget _buildLinkedSoundsRow(Scene scene) {
    if (scene.linkedSoundIds.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<List<Sound>>(
      future: _loadLinkedSounds(scene.linkedSoundIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(4),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Fehler beim Laden der Sounds',
              style: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.errorRed,
                fontSize: 8,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final linkedSounds = snapshot.data!;
        return Column(
          children: linkedSounds.map((sound) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: SoundPlayerWidget(
                sound: sound,
                compactMode: true,
                showCloseButton: false,
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Lädt die Details der verknüpften Sounds
  Future<List<Sound>> _loadLinkedSounds(List<String> soundIds) async {
    final List<Sound> result = [];
    
    try {
      final soundRepo = context.read<SoundModelRepository>();
      
      for (final soundId in soundIds) {
        try {
          final sound = await soundRepo.findById(soundId);
          // Nur gültige Sounds hinzufügen
          if (sound != null && sound.isValid) {
            result.add(sound);
          }
        } catch (e) {
          // Nicht gefunden oder ungültig, überspringen
          print('Sound $soundId konnte nicht geladen werden: $e');
        }
      }
    } catch (e) {
      print('Fehler beim Laden der Sounds: $e');
    }
    
    return result;
  }

  /// Baut eine Reihe mit verknüpften Charakteren
  Widget _buildLinkedCharactersRow(Scene scene) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadLinkedCharacters(scene.linkedCharacterIds),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final linkedChars = snapshot.data!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: DnDTheme.mysticalPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            border: Border.all(
              color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: linkedChars.values.map((char) {
              final type = char['type'] as String;
              final name = char['name'] as String;
              final level = char['level'] as String?;
              
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCharacterTypeColor(type).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  border: Border.all(
                    color: _getCharacterTypeColor(type).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getCharacterTypeIcon(type),
                      color: _getCharacterTypeColor(type),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      name,
                      style: DnDTheme.bodyText2.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                    if (level != null) ...[
                      const SizedBox(width: 4),
                      Text(
                        '($level)',
                        style: DnDTheme.bodyText2.copyWith(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Lädt die Details der verknüpften Charaktere
  Future<Map<String, dynamic>> _loadLinkedCharacters(List<String> characterIds) async {
    final Map<String, dynamic> result = {};
    
    try {
      final creatureRepo = context.read<CreatureModelRepository>();
      final pcRepo = context.read<PlayerCharacterModelRepository>();
      
      for (final charId in characterIds) {
        // Versuche zuerst als Player Character zu laden
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
        } catch (e) {
          // Nicht gefunden, versuche als Creature
        }
        
        // Versuche als Creature zu laden
        try {
          final creature = await creatureRepo.findById(charId);
          if (creature != null) {
            final level = creature.challengeRating != null 
                ? 'CR ${creature.challengeRating}' 
                : null;
            result[charId] = {
              'name': creature.name,
              'type': creature.sourceType == 'official' ? 'monster' : 'npc',
              'level': level,
            };
          }
        } catch (e) {
          // Nicht gefunden, überspringen
        }
      }
    } catch (e) {
      print('Fehler beim Laden der Charaktere: $e');
    }
    
    return result;
  }

  /// Baut eine Reihe mit verknüpften Wiki-Einträgen
  Widget _buildLinkedWikiEntriesRow(Scene scene) {
    return FutureBuilder<List<WikiEntry>>(
      future: _loadLinkedWikiEntries(scene.linkedWikiEntryIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(4),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Fehler beim Laden der Wiki-Einträge',
              style: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.errorRed,
                fontSize: 10,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final linkedWikiEntries = snapshot.data!;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: DnDTheme.mysticalPurple.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            border: Border.all(
              color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 6,
            children: linkedWikiEntries.map((wikiEntry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _getWikiEntryTypeColor(wikiEntry.entryType).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  border: Border.all(
                    color: _getWikiEntryTypeColor(wikiEntry.entryType).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getWikiEntryTypeIcon(wikiEntry.entryType),
                      color: _getWikiEntryTypeColor(wikiEntry.entryType),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      wikiEntry.title,
                      style: DnDTheme.bodyText2.copyWith(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Lädt die Details der verknüpften Wiki-Einträge
  Future<List<WikiEntry>> _loadLinkedWikiEntries(List<String> wikiEntryIds) async {
    final List<WikiEntry> result = [];
    
    try {
      final wikiEntryRepo = context.read<WikiEntryModelRepository>();
      
      for (final wikiId in wikiEntryIds) {
        try {
          final wikiEntry = await wikiEntryRepo.findById(wikiId);
          if (wikiEntry != null) {
            result.add(wikiEntry);
          }
        } catch (e) {
          // Nicht gefunden, überspringen
          print('Wiki-Eintrag $wikiId konnte nicht geladen werden: $e');
        }
      }
    } catch (e) {
      print('Fehler beim Laden der Wiki-Einträge: $e');
    }
    
    return result;
  }

  /// Gibt die Farbe für den Wiki-Eintrag-Typ zurück
  Color _getWikiEntryTypeColor(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return DnDTheme.successGreen;
      case WikiEntryType.Place:
        return DnDTheme.arcaneBlue;
      case WikiEntryType.Lore:
        return DnDTheme.ancientGold;
      case WikiEntryType.Faction:
        return DnDTheme.mysticalPurple;
      case WikiEntryType.Magic:
        return Colors.purple;
      case WikiEntryType.History:
        return Colors.orange;
      case WikiEntryType.Item:
        return DnDTheme.infoBlue;
      case WikiEntryType.Quest:
        return DnDTheme.successGreen;
      case WikiEntryType.Creature:
        return DnDTheme.errorRed;
    }
  }

  /// Gibt das Icon für den Wiki-Eintrag-Typ zurück
  IconData _getWikiEntryTypeIcon(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return Icons.person;
      case WikiEntryType.Place:
        return Icons.place;
      case WikiEntryType.Lore:
        return Icons.book;
      case WikiEntryType.Faction:
        return Icons.groups;
      case WikiEntryType.Magic:
        return Icons.auto_awesome;
      case WikiEntryType.History:
        return Icons.history;
      case WikiEntryType.Item:
        return Icons.inventory_2;
      case WikiEntryType.Quest:
        return Icons.flag;
      case WikiEntryType.Creature:
        return Icons.pets;
    }
  }

  /// Baut eine Liste mit verknüpften Quests mit vollständigen Informationen
  Widget _buildLinkedQuestsRow(Scene scene) {
    return FutureBuilder<List<Quest>>(
      future: _loadLinkedQuests(scene.linkedQuestIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(4),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(4),
            child: Text(
              'Fehler beim Laden der Quests',
              style: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.errorRed,
                fontSize: 8,
              ),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final linkedQuests = snapshot.data!;
        return Column(
          children: linkedQuests.map((quest) {
            return _buildQuestCard(quest);
          }).toList(),
        );
      },
    );
  }

  /// Baut eine vollständige Quest-Karte mit allen Informationen
  Widget _buildQuestCard(Quest quest) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey.withValues(alpha: 0.8),
          endColor: DnDTheme.stoneGrey.withValues(alpha: 0.8),
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: _getQuestStatusColor(quest.status).withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Titel und Status
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: _getQuestStatusColor(quest.status).withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getQuestStatusColor(quest.status),
                    width: 2,
                  ),
                ),
                child: Icon(
                  _getQuestStatusIcon(quest.status),
                  color: _getQuestStatusColor(quest.status),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: DnDTheme.headline3.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        Text(
                          _getQuestStatusText(quest.status),
                          style: DnDTheme.bodyText1.copyWith(
                            color: _getQuestStatusColor(quest.status),
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (quest.location != null && quest.location!.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Icon(
                            Icons.location_on,
                            color: Colors.white54,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            quest.location!,
                            style: DnDTheme.bodyText1.copyWith(
                              color: Colors.white54,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Beschreibung
          if (quest.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              quest.description,
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
                fontSize: 14,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          // Aktionen
          const SizedBox(height: 14),
          Row(
            children: [
              // Als aufgegeben markieren
              Expanded(
                child: _buildQuestActionButton(
                  icon: Icons.remove_circle_outline,
                  label: 'Aufgegeben',
                  color: Colors.orange,
                  isSelected: quest.status == QuestStatus.abandoned,
                  onTap: () => _updateQuestStatus(quest, QuestStatus.abandoned),
                ),
              ),
              const SizedBox(width: 8),
              // Als aktiv markieren
              Expanded(
                child: _buildQuestActionButton(
                  icon: Icons.play_circle_outline,
                  label: 'Aktiv',
                  color: DnDTheme.ancientGold,
                  isSelected: quest.status == QuestStatus.active,
                  onTap: () => _updateQuestStatus(quest, QuestStatus.active),
                ),
              ),
              const SizedBox(width: 8),
              // Als erledigt markieren
              Expanded(
                child: _buildQuestActionButton(
                  icon: Icons.check_circle_outline,
                  label: 'Erledigt',
                  color: DnDTheme.successGreen,
                  isSelected: quest.status == QuestStatus.completed,
                  onTap: () => _updateQuestStatus(quest, QuestStatus.completed),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Baut einen Quest-Aktions-Button
  Widget _buildQuestActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: isSelected ? color.withValues(alpha: 0.4) : color.withValues(alpha: 0.1),
            endColor: isSelected ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.05),
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : color.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? color : color.withValues(alpha: 0.7),
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: DnDTheme.bodyText1.copyWith(
                color: isSelected ? color : Colors.white70,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Aktualisiert den Status eines Quests
  Future<void> _updateQuestStatus(Quest quest, QuestStatus newStatus) async {
    try {
      final questRepo = context.read<QuestModelRepository>();
      
      // Quest mit neuem Status erstellen
      final updatedQuest = quest.copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );
      
      // In der Datenbank aktualisieren
      await questRepo.update(updatedQuest);
      
      // UI aktualisieren
      setState(() {});
      
      // Feedback anzeigen
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                _getQuestStatusIcon(newStatus),
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '"${quest.title}" als ${_getQuestStatusText(newStatus)} markiert',
                style: const TextStyle(color: Colors.white, fontSize: 11),
              ),
            ],
          ),
          backgroundColor: _getQuestStatusColor(newStatus),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Fehler beim Aktualisieren des Quest-Status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Fehler beim Aktualisieren des Quests'),
          backgroundColor: DnDTheme.errorRed,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Lädt die Details der verknüpften Quests
  Future<List<Quest>> _loadLinkedQuests(List<String> questIds) async {
    final List<Quest> result = [];
    
    try {
      final questRepo = context.read<QuestModelRepository>();
      
      for (final questId in questIds) {
        try {
          final quest = await questRepo.findById(questId);
          if (quest != null) {
            result.add(quest);
          }
        } catch (e) {
          // Nicht gefunden, überspringen
          print('Quest $questId konnte nicht geladen werden: $e');
        }
      }
    } catch (e) {
      print('Fehler beim Laden der Quests: $e');
    }
    
    return result;
  }

  /// Gibt die Farbe für den Quest-Status zurück
  Color _getQuestStatusColor(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return Colors.grey;
      case QuestStatus.onHold:
        return DnDTheme.arcaneBlue;
      case QuestStatus.completed:
        return DnDTheme.successGreen;
      case QuestStatus.failed:
        return DnDTheme.errorRed;
      case QuestStatus.abandoned:
        return Colors.orange;
    }
  }

  /// Gibt das Icon für den Quest-Status zurück
  IconData _getQuestStatusIcon(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return Icons.flag_outlined;
      case QuestStatus.onHold:
        return Icons.play_arrow;
      case QuestStatus.completed:
        return Icons.check_circle;
      case QuestStatus.failed:
        return Icons.cancel;
      case QuestStatus.abandoned:
        return Icons.remove_circle;
    }
  }

  /// Gibt den Text für den Quest-Status zurück
  String _getQuestStatusText(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return 'Aktiv';
      case QuestStatus.onHold:
        return 'In Arbeit';
      case QuestStatus.completed:
        return 'Abgeschlossen';
      case QuestStatus.failed:
        return 'Fehlgeschlagen';
      case QuestStatus.abandoned:
        return 'Aufgegeben';
    }
  }

  /// Gibt die Farbe für den Charaktertyp zurück
  Color _getCharacterTypeColor(String type) {
    switch (type) {
      case 'pc':
        return DnDTheme.successGreen;
      case 'npc':
        return DnDTheme.arcaneBlue;
      case 'monster':
        return DnDTheme.errorRed;
      default:
        return Colors.grey;
    }
  }

  /// Gibt das Icon für den Charaktertyp zurück
  IconData _getCharacterTypeIcon(String type) {
    switch (type) {
      case 'pc':
        return Icons.person;
      case 'npc':
        return Icons.person_outline;
      case 'monster':
        return Icons.pets;
      default:
        return Icons.person;
    }
  }

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
                leading: Icon(Icons.edit, color: DnDTheme.arcaneBlue, size: 20),
                title: Text(
                  'Bearbeiten',
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showEditSceneDialog(scene);
                },
              ),
              ListTile(
                leading: Icon(Icons.play_circle_filled, color: DnDTheme.ancientGold, size: 20),
                title: Text(
                  'Scene aktivieren',
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                ),
                subtitle: Text(
                  'Aktiviert Scene und ihre Quests',
                  style: DnDTheme.bodyText2.copyWith(color: Colors.white54, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewModel.activateScene(scene.id);
                },
              ),
              ListTile(
                leading: Icon(Icons.check_circle, color: DnDTheme.successGreen, size: 20),
                title: Text(
                  'Scene abschließen',
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                ),
                subtitle: Text(
                  'Schließt Scene, Quests und Encounters',
                  style: DnDTheme.bodyText2.copyWith(color: Colors.white54, fontSize: 11),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewModel.completeScene(scene.id);
                },
              ),
              Divider(color: DnDTheme.stoneGrey),
              ListTile(
                leading: Icon(Icons.arrow_upward, color: DnDTheme.arcaneBlue, size: 20),
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
                leading: Icon(Icons.arrow_downward, color: DnDTheme.arcaneBlue, size: 20),
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
                leading: Icon(Icons.delete, color: DnDTheme.errorRed, size: 20),
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
    // Übergebe null und sessionId - der EditSceneViewModel erstellt die neue Scene
    _showEditSceneDialog(null, isCreate: true);
  }

  void _showEditSceneDialog(Scene? scene, {bool isCreate = false}) async {
    // Repositories VOR dem Navigator aus dem Context lesen
    final sceneRepository = context.read<SceneModelRepository>();
    final creatureRepository = context.read<CreatureModelRepository>();
    final playerCharacterRepository = context.read<PlayerCharacterModelRepository>();
    final questRepository = context.read<QuestModelRepository>();
    final soundRepository = context.read<SoundModelRepository>();
    final wikiEntryRepository = context.read<WikiEntryModelRepository>();
    
    // Für neue Scenes: sessionId übergeben, für existierende: nicht
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
      // Scene wurde gespeichert, Daten neu laden
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
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.errorRed,
          ),
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
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
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

  Widget _buildSessionQuadrant({
    required String title,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              gradient: DnDTheme.getMysticalGradient(
                startColor: color.withValues(alpha: 0.8),
                endColor: color.withValues(alpha: 0.4),
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(DnDTheme.radiusMedium),
                topRight: Radius.circular(DnDTheme.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 10,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                  title,
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
                  ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildLiveNotesWidget(ActiveSessionViewModel viewModel) {
    return LiveNotesQuadrant(viewModel: viewModel);
  }

  Widget _buildFloatingActionButton() {
    return Container(
      decoration: DnDTheme.getMysticalBorder(
        borderColor: DnDTheme.errorRed,
        width: 3,
      ),
      child: FloatingActionButton.extended(
        heroTag: 'active_session_fab',
        onPressed: _startEncounter,
        backgroundColor: DnDTheme.errorRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.play_arrow),
        label: const Text('Kampf'),
      ),
    );
  }

  Widget _buildPlaceholderWidget(String title, String description, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: Colors.white38,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white54,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(DnDTheme.lg),
        decoration: DnDTheme.getDungeonWallDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: DnDTheme.errorRed,
              size: 48,
            ),
            const SizedBox(height: DnDTheme.md),
            Text(
              'Fehler',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.errorRed,
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              error,
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DnDTheme.md),
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

  Future<void> _handleMenuAction(String action) async {
    switch (action) {
      case 'edit_title':
        _showEditTitleDialog();
        break;
      case 'add_time_15':
        await _viewModel.addInGameTime(15);
        break;
      case 'add_time_30':
        await _viewModel.addInGameTime(30);
        break;
      case 'add_time_60':
        await _viewModel.addInGameTime(60);
        break;
    }
  }

  void _showEditTitleDialog() {
    final controller = TextEditingController(text: _viewModel.currentSession.title);
    
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Session-Titel bearbeiten',
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: TextFormField(
          controller: controller,
          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Titel',
            labelStyle: DnDTheme.bodyText2.copyWith(
              color: DnDTheme.ancientGold,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              borderSide: const BorderSide(color: DnDTheme.mysticalPurple),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              borderSide: BorderSide(
                color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              borderSide: const BorderSide(color: DnDTheme.ancientGold, width: 2),
            ),
            filled: true,
            fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await _viewModel.updateSessionTitle(controller.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: DnDTheme.dungeonBlack,
            ),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
  }

  void _startEncounter() {
    // Prüfe ob eine aktive Scene existiert
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

    // Finde die aktive Scene
    final activeScene = _viewModel.scenes.firstWhere(
      (scene) => scene.id == activeSceneId,
      orElse: () => throw Exception('Scene nicht gefunden'),
    );

    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => EncounterSetupScreen(
          campaign: _viewModel.campaign,
          scene: activeScene,
        ),
      ),
    );
  }
}
