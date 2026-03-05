import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/campaign.dart';
import '../models/session.dart';
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
              const SizedBox(height: DnDTheme.md),
              
              // Main Content Grid
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: DnDTheme.md,
                  mainAxisSpacing: DnDTheme.md,
                  children: [
                    _buildSessionQuadrant(
                      title: "Szenen-Ablauf",
                      icon: Icons.list_alt,
                      color: DnDTheme.arcaneBlue,
                      content: _buildPlaceholderWidget(
                        "Szenen-Ablauf",
                        "Diese Funktion wird in Zukunft verfügbar sein",
                        Icons.list_alt,
                      ),
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
      padding: const EdgeInsets.all(DnDTheme.md),
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
              size: 24,
            ),
          ),
          const SizedBox(width: DnDTheme.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kampagne: ${viewModel.campaign.title}',
                  style: DnDTheme.bodyText1.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Session-Laufzeit: ${viewModel.getFormattedInGameTime()}',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: DnDTheme.md,
              vertical: DnDTheme.sm,
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
                  size: 16,
                ),
                const SizedBox(width: DnDTheme.xs),
                Text(
                  'Aktiv',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
            padding: const EdgeInsets.all(DnDTheme.md),
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
                    size: 20,
                  ),
                ),
                const SizedBox(width: DnDTheme.sm),
                Expanded(
                  child: Text(
                    title,
                    style: DnDTheme.bodyText1.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(DnDTheme.sm),
              child: content,
            ),
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
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Live-Notizen hier eintragen...',
                hintStyle: TextStyle(color: Colors.white54),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(DnDTheme.sm),
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
            padding: const EdgeInsets.all(DnDTheme.sm),
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
                  'Automatisch gespeichert',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: DnDTheme.sm,
                    vertical: DnDTheme.xs,
                  ),
                  decoration: BoxDecoration(
                    color: DnDTheme.successGreen,
                    borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  ),
                  child: Text(
                    'Speichern',
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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
            crossAxisSpacing: DnDTheme.sm,
            mainAxisSpacing: DnDTheme.sm,
            childAspectRatio: 1.5,
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
        const SizedBox(height: DnDTheme.sm),
        Container(
          padding: const EdgeInsets.all(DnDTheme.sm),
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
                ),
              ),
              const SizedBox(height: DnDTheme.xs),
              Row(
                children: [
                  Icon(
                    Icons.circle,
                    color: DnDTheme.successGreen,
                    size: 12,
                  ),
                  const SizedBox(width: DnDTheme.xs),
                  Text(
                    'Session läuft aktiv',
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
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
              size: 24,
            ),
            const SizedBox(height: DnDTheme.xs),
            Text(
              label,
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
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
            size: 48,
            color: Colors.white38,
          ),
          const SizedBox(height: DnDTheme.md),
          Text(
            title,
            style: DnDTheme.bodyText1.copyWith(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: DnDTheme.sm),
          Text(
            description,
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white54,
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
