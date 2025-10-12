// lib/screens/active_session_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import 'encounter_setup_screen.dart';
import '../widgets/livenotes_widget.dart';
import '../widgets/scene_flow_widget.dart';
import '../widgets/tools_widget.dart';
import '../widgets/quest_log_widget.dart';
import '../widgets/sound_mixer_widget.dart';

class ActiveSessionScreen extends StatefulWidget {
  final Session session;
  final Campaign campaign;
  const ActiveSessionScreen({super.key, required this.session, required this.campaign});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Session _currentSession;

  // NEU: Ein Key für unser SceneFlowWidget, um es gezielt neu zu laden
  final GlobalKey<SceneFlowWidgetState> _sceneFlowKey = GlobalKey();
  // Ein Key für das QuestLogWidget (indirekt über ToolsWidget)
  final GlobalKey<QuestLogWidgetState> _questLogKey = GlobalKey();


  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
  }

  void _addInGameTime(int minutesToAdd) async {
    setState(() {
      _currentSession = Session(
        id: _currentSession.id,
        campaignId: _currentSession.campaignId,
        title: _currentSession.title,
        inGameTimeInMinutes: _currentSession.inGameTimeInMinutes + minutesToAdd,
        liveNotes: _currentSession.liveNotes,
      );
    });
    await dbHelper.updateSession(_currentSession);
  }
  
  // Diese Methode kann jetzt gezielt die Kind-Widgets neu laden
  void _reloadData() {
    _sceneFlowKey.currentState?.initState();
    _questLogKey.currentState?.reloadQuests();
    print("Data reloaded in ActiveSessionScreen!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_currentSession.title)),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(8),
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        children: [
          _buildQuadrant(title: "Szenen-Ablauf", icon: Icons.list_alt, content: SceneFlowWidget(
            key: _sceneFlowKey, // Key übergeben
            sessionId: _currentSession.id, 
            campaignId: widget.campaign.id, 
            onDataChanged: _reloadData // Callback übergeben
          )),
          Card(elevation: 4, clipBehavior: Clip.antiAlias, child: LiveNotesWidget(session: _currentSession)),
          _buildQuadrant(title: "Werkzeuge", icon: Icons.construction, content: ToolsWidget(
            session: _currentSession,
            campaign: widget.campaign,
            onTimeAdd: _addInGameTime,
            onDataChanged: _reloadData, // Callback übergeben
          )),
          _buildQuadrant(
            title: "Atmosphäre",
            icon: Icons.music_note,
            content: const SoundMixerWidget(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.play_arrow),
        label: const Text("Kampf"),
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => EncounterSetupScreen(campaign: widget.campaign))),
      ),
    );
  }

  Widget _buildQuadrant({required String title, required IconData icon, required Widget content}) {
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor.withOpacity(0.2),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [
              Icon(icon, size: 18, color: Colors.grey[400]),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ]),
          ),
          Expanded(child: Padding(padding: const EdgeInsets.all(8.0), child: content)),
        ],
      ),
    );
  }
}