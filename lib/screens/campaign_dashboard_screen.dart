// lib/screens/campaign_dashboard_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import '../widgets/campaign_heroes_tab.dart';
import '../widgets/campaign_sessions_tab.dart';
import '../widgets/campaign_overview_tab.dart';
import '../widgets/campaign_quests_tab.dart';
import '../widgets/character_editor/character_editor_controller.dart' show CharacterType;
import 'edit_pc_screen.dart';
import 'edit_session_screen.dart';
import 'unified_character_editor_screen.dart';

class CampaignDashboardScreen extends StatefulWidget {
  final Campaign campaign;
  const CampaignDashboardScreen({super.key, required this.campaign});

  @override
  State<CampaignDashboardScreen> createState() => _CampaignDashboardScreenState();
}

class _CampaignDashboardScreenState extends State<CampaignDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  final dbHelper = DatabaseHelper.instance;

  final GlobalKey<CampaignHeroesTabState> _heroesKey = GlobalKey();
  final GlobalKey<CampaignSessionsTabState> _sessionsKey = GlobalKey();
  final GlobalKey<CampaignQuestsTabState> _questsKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget? _buildFab() {
    switch (_currentTabIndex) {
      case 1: // Helden-Tab
        return FloatingActionButton(
          tooltip: "Neuen Helden hinzufügen",
          onPressed: () async {
            await Navigator.of(context).push(MaterialPageRoute(
              builder: (ctx) => UnifiedCharacterEditorScreen(
                characterType: CharacterType.player,
                campaignId: widget.campaign.id,
              ),
            ));
            // SICHERHEITS-PRÜFUNG HINZUGEFÜGT
            if (!mounted) return;
            _heroesKey.currentState?.loadPcs();
          },
          child: const Icon(Icons.add),
        );
      case 2: // Sitzungen-Tab
        return FloatingActionButton(
          tooltip: "Neue Sitzung hinzufügen",
          onPressed: () async {
            final newSession = Session(campaignId: widget.campaign.id, title: "Neue Sitzung");
            await dbHelper.insertSession(newSession);
            
            // SICHERHEITS-PRÜFUNG HINZUGEFÜGT
            if (!mounted) return;

            await Navigator.of(context).push(MaterialPageRoute(
              builder: (ctx) => EditSessionScreen(session: newSession),
            ));
            
            // SICHERHEITS-PRÜFUNG HINZUGEFÜGT
            if (!mounted) return;
            _sessionsKey.currentState?.loadSessions();
          },
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campaign.title),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline), text: "Übersicht"),
            Tab(icon: Icon(Icons.groups), text: "Helden"),
            Tab(icon: Icon(Icons.map), text: "Sitzungen"),
            Tab(icon: Icon(Icons.flag), text: "Quests"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CampaignOverviewTab(campaign: widget.campaign),
          CampaignHeroesTab(key: _heroesKey, campaign: widget.campaign),
          CampaignSessionsTab(key: _sessionsKey, campaign: widget.campaign),
          CampaignQuestsTab(key: _questsKey, campaign: widget.campaign),
        ],
      ),
      floatingActionButton: _buildFab(),
    );
  }
}
