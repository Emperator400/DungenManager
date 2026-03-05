import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import '../models/scene.dart';
import '../viewmodels/active_session_viewmodel.dart';
import '../theme/dnd_theme.dart';
import 'encounter_setup_screen.dart';

/// Enhanced Active Session Screen mit Provider-Pattern und modernem D&D Design
class EnhancedActiveSessionScreen extends StatefulWidget {
  final Session session;
  final Campaign campaign;

  const EnhancedActiveSessionScreen({
    super.key,
    required this.session,
    required this.campaign,
  });

  @override
  State<EnhancedActiveSessionScreen> createState() => _EnhancedActiveSessionScreenState();
}

class _EnhancedActiveSessionScreenState extends State<EnhancedActiveSessionScreen> {
  late ActiveSessionViewModel _viewModel;
  final GlobalKey<State> _sceneFlowKey = GlobalKey();
  double _quadrantScale = 0.9; // 50% - 100% der verfügbaren Größe

  @override
  void initState() {
    super.initState();
    _viewModel = ActiveSessionViewModel(
      session: widget.session,
      campaign: widget.campaign,
    );
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
              const SizedBox(height: 4),
              
              // Main Content Grid
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Berechne optimale Größe für 2x2 Grid mit Scale-Faktor
                    final availableWidth = (constraints.maxWidth / 2 - 2) * _quadrantScale;
                    final availableHeight = (constraints.maxHeight / 2 - 2) * _quadrantScale;
                    final aspectRatio = availableWidth / availableHeight;
                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 2,
                      mainAxisSpacing: 2,
                      childAspectRatio: aspectRatio.clamp(0.3, 3.0),
                      children: [
                    _buildSessionQuadrant(
                      title: "Szenen-Ablauf",
                      icon: Icons.list_alt,
                      color: DnDTheme.arcaneBlue,
                      content: _buildSceneFlowWidget(viewModel),
                    ),
                    _buildSessionQuadrant(
                      title: "Live-Notizen",
                      icon: Icons.note_alt,
                      color: DnDTheme.ancientGold,
                      content: _buildLiveNotesWidget(viewModel),
                    ),
                    _buildSessionQuadrant(
                      title: "Session-Werkzeuge",
                      icon: Icons.construction,
                      color: DnDTheme.mysticalPurple,
                      content: _buildToolsWidget(viewModel),
                    ),
                    _buildSessionQuadrant(
                      title: "Atmosphäre",
                      icon: Icons.music_note,
                      color: DnDTheme.successGreen,
                      content: _buildPlaceholderWidget(
                        "Sound Mixer",
                        "Diese Funktion wird in Zukunft verfügbar sein",
                        Icons.music_note,
                      ),
                    ),
                      ],
                    );
                  },
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kampagne: ${viewModel.campaign.title}',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Session-Laufzeit: ${viewModel.getFormattedInGameTime()}',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white70,
                    fontSize: 9,
                  ),
                ),
              ],
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
          padding: const EdgeInsets.all(2),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateSceneDialog(),
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
  
  Widget _buildSceneCard({
    required Scene scene,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: isActive 
                ? DnDTheme.ancientGold.withValues(alpha: 0.3)
                : DnDTheme.slateGrey,
            endColor: isActive 
                ? DnDTheme.ancientGold.withValues(alpha: 0.1)
                : DnDTheme.stoneGrey,
          ),
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          border: Border.all(
            color: isActive 
                ? DnDTheme.ancientGold
                : DnDTheme.arcaneBlue.withValues(alpha: 0.3),
            width: isActive ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Order Index
            Container(
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
            const SizedBox(width: 8),
            // Scene Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    scene.name,
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        scene.sceneTypeDisplayName,
                        style: DnDTheme.bodyText2.copyWith(
                          color: Colors.white70,
                          fontSize: 7,
                        ),
                      ),
                      // Encounter Link Indicator
                      if (scene.linkedEncounterId != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.gavel,
                          color: DnDTheme.errorRed,
                          size: 8,
                        ),
                      ],
                      // Character Links Indicator
                      if (scene.linkedCharacterIds.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.people,
                          color: DnDTheme.mysticalPurple,
                          size: 8,
                        ),
                        Text(
                          '(${scene.linkedCharacterIds.length})',
                          style: DnDTheme.bodyText2.copyWith(
                            color: DnDTheme.mysticalPurple,
                            fontSize: 7,
                          ),
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
                    size: 12,
                  ),
                if (isActive)
                  Icon(
                    Icons.play_circle_filled,
                    color: DnDTheme.ancientGold,
                    size: 12,
                  ),
                const SizedBox(width: 4),
                Icon(
                  Icons.more_vert,
                  color: Colors.white70,
                  size: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
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
                leading: Icon(Icons.play_arrow, color: DnDTheme.ancientGold, size: 20),
                title: Text(
                  'Als aktiv setzen',
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewModel.setActiveScene(scene.id);
                },
              ),
              ListTile(
                leading: Icon(
                  scene.isCompleted ? Icons.check_circle_outline : Icons.check_circle,
                  color: DnDTheme.successGreen,
                  size: 20,
                ),
                title: Text(
                  scene.isCompleted ? 'Als offen markieren' : 'Als abgeschlossen markieren',
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _viewModel.markSceneCompleted(scene.id, !scene.isCompleted);
                },
              ),
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
    final newScene = Scene(
      sessionId: widget.session.id,
      orderIndex: _viewModel.scenes.length,
      name: 'Neue Szene',
      description: '',
      sceneType: SceneType.Exploration,
      estimatedDuration: const Duration(minutes: 30),
    );
    
    _showEditSceneDialog(newScene, isCreate: true);
  }

  void _showEditSceneDialog(Scene scene, {bool isCreate = false}) {
    showDialog(
      context: context,
      builder: (context) => _SceneEditDialog(
        scene: scene,
        onSave: (updatedScene) async {
          if (isCreate) {
            await _viewModel.createScene(
              name: updatedScene.name,
              description: updatedScene.description,
              sceneType: updatedScene.sceneType,
              estimatedDuration: updatedScene.estimatedDuration,
              complexity: updatedScene.complexity,
            );
          } else {
            _viewModel.updateScene(updatedScene);
          }
        },
      ),
    );
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
              onChanged: (value) {
                // Debounced update could be implemented here
              },
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

  Widget _buildToolsWidget(ActiveSessionViewModel viewModel) {
    return Column(
      children: [
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1.0,
            children: [
              _buildToolButton(
                icon: Icons.access_time,
                label: '+15 Min',
                color: DnDTheme.successGreen,
                onTap: () => viewModel.addInGameTime(15),
              ),
              _buildToolButton(
                icon: Icons.timer,
                label: '+30 Min',
                color: DnDTheme.arcaneBlue,
                onTap: () => viewModel.addInGameTime(30),
              ),
              _buildToolButton(
                icon: Icons.hourglass_full,
                label: '+1 Std',
                color: DnDTheme.mysticalPurple,
                onTap: () => viewModel.addInGameTime(60),
              ),
              _buildToolButton(
                icon: Icons.refresh,
                label: 'Neu laden',
                color: DnDTheme.ancientGold,
                onTap: () {
                  // Widget neu erstellen, da reloadScenes nicht existiert
                  setState(() {});
                  viewModel.triggerDataReload();
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Container(
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
                    '${(_quadrantScale * 100).toInt()}%',
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
                  value: _quadrantScale,
                  min: 0.5,
                  max: 1.0,
                  divisions: 10,
                  onChanged: (value) {
                    setState(() {
                      _quadrantScale = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildToolButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: color.withValues(alpha: 0.8),
            endColor: color.withValues(alpha: 0.4),
          ),
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
          border: Border.all(
            color: color.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(height: 2),
            Text(
            label,
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
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
            size: 24,
            color: Colors.white38,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white54,
              fontSize: 8,
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
              onPressed: () {
                _viewModel.clearError();
                _viewModel.triggerDataReload();
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
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (ctx) => EncounterSetupScreen(campaign: _viewModel.campaign),
      ),
    );
  }
}

/// Dialog zum Bearbeiten einer Scene
class _SceneEditDialog extends StatefulWidget {
  final Scene scene;
  final Function(Scene) onSave;

  const _SceneEditDialog({
    required this.scene,
    required this.onSave,
  });

  @override
  State<_SceneEditDialog> createState() => _SceneEditDialogState();
}

class _SceneEditDialogState extends State<_SceneEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late SceneType _sceneType;
  late Complexity? _complexity;
  late int _durationMinutes;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.scene.name);
    _descriptionController = TextEditingController(text: widget.scene.description);
    _sceneType = widget.scene.sceneType;
    _complexity = widget.scene.complexity;
    _durationMinutes = widget.scene.estimatedDuration?.inMinutes ?? 30;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DnDTheme.stoneGrey,
      title: Text(
        'Szene bearbeiten',
        style: DnDTheme.headline3.copyWith(
          color: DnDTheme.ancientGold,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name
            TextField(
              controller: _nameController,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Name',
                labelStyle: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  borderSide: const BorderSide(color: DnDTheme.mysticalPurple),
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: DnDTheme.md),
            
            // Typ
            Text(
              'Typ',
              style: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DnDTheme.xs),
            DropdownButtonFormField<SceneType>(
              value: _sceneType,
              dropdownColor: DnDTheme.stoneGrey,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  borderSide: const BorderSide(color: DnDTheme.mysticalPurple),
                ),
              ),
              items: SceneType.values.map((type) {
                return DropdownMenuItem<SceneType>(
                  value: type,
                  child: Text(
                    _getSceneTypeDisplayName(type),
                    style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _sceneType = value!;
                });
              },
            ),
            const SizedBox(height: DnDTheme.md),
            
            // Komplexität
            Text(
              'Komplexität',
              style: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DnDTheme.xs),
            DropdownButtonFormField<Complexity?>(
              value: _complexity,
              dropdownColor: DnDTheme.stoneGrey,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  borderSide: const BorderSide(color: DnDTheme.mysticalPurple),
                ),
              ),
              items: [
                const DropdownMenuItem<Complexity?>(
                  value: null,
                  child: Text(
                    'Nicht festgelegt',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                ...Complexity.values.map((complexity) {
                  return DropdownMenuItem<Complexity>(
                    value: complexity,
                    child: Text(
                      _getComplexityDisplayName(complexity),
                      style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                    ),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() {
                  _complexity = value;
                });
              },
            ),
            const SizedBox(height: DnDTheme.md),
            
            // Geschätzte Dauer
            Text(
              'Geschätzte Dauer',
              style: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DnDTheme.xs),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _durationMinutes.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    label: '$_durationMinutes Min',
                    onChanged: (value) {
                      setState(() {
                        _durationMinutes = value.toInt();
                      });
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DnDTheme.sm,
                    vertical: DnDTheme.xs,
                  ),
                  decoration: BoxDecoration(
                    color: DnDTheme.arcaneBlue,
                    borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  ),
                  child: Text(
                    '$_durationMinutes Min',
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: DnDTheme.md),
            
            // Beschreibung
            Text(
              'Beschreibung',
              style: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.ancientGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: DnDTheme.xs),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Beschreibe die Szene...',
                hintStyle: DnDTheme.bodyText2.copyWith(color: Colors.white54),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  borderSide: const BorderSide(color: DnDTheme.mysticalPurple),
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              ),
            ),
          ],
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
          onPressed: () {
            final updatedScene = widget.scene.copyWith(
              name: _nameController.text,
              description: _descriptionController.text,
              sceneType: _sceneType,
              complexity: _complexity,
              estimatedDuration: Duration(minutes: _durationMinutes),
            );
            widget.onSave(updatedScene);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: DnDTheme.ancientGold,
            foregroundColor: DnDTheme.dungeonBlack,
          ),
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  String _getSceneTypeDisplayName(SceneType type) {
    switch (type) {
      case SceneType.Introduction:
        return 'Einführung';
      case SceneType.Exploration:
        return 'Erforschung';
      case SceneType.Combat:
        return 'Kampf';
      case SceneType.Social:
        return 'Sozial';
      case SceneType.Puzzle:
        return 'Rätsel';
      case SceneType.Climax:
        return 'Höhepunkt';
      case SceneType.Resolution:
        return 'Auflösung';
    }
  }

  String _getComplexityDisplayName(Complexity complexity) {
    switch (complexity) {
      case Complexity.Easy:
        return 'Einfach';
      case Complexity.Medium:
        return 'Mittel';
      case Complexity.Hard:
        return 'Schwer';
      case Complexity.Legendary:
        return 'Legendär';
    }
  }
}
