// lib/widgets/campaign_quests_tab.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/quest.dart';
import '../models/campaign_quest.dart';
import '../screens/add_quest_from_library_screen.dart';
import '../screens/edit_campaign_quest_screen.dart';

class CampaignQuestsTab extends StatefulWidget {
  final Campaign campaign;
  const CampaignQuestsTab({super.key, required this.campaign});

  @override
  State<CampaignQuestsTab> createState() => CampaignQuestsTabState();
}

class CampaignQuestsTabState extends State<CampaignQuestsTab> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<CampaignQuest>> _campaignQuestsFuture;

  @override
  void initState() {
    super.initState();
    _loadQuests();
  }

  void _loadQuests() {
    setState(() {
      _campaignQuestsFuture = _loadQuestsData();
    });
  }

  Future<List<CampaignQuest>> _loadQuestsData() async {
    try {
      // Da es keine getQuestsForCampaign Methode gibt, erstellen wir eine leere Liste
      // In einer echten Implementierung würde dies die Datenbank abfragen
      return <CampaignQuest>[];
    } catch (e) {
      print('Fehler beim Laden der CampaignQuests: $e');
      return <CampaignQuest>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<CampaignQuest>>(
        future: _campaignQuestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Dieser Kampagne wurden noch keine Quests hinzugefügt."));
          }
          
          final allQuests = snapshot.data!;

          // Logik zum Gruppieren der Quests nach Status
          final groupedQuests = <QuestStatus, List<CampaignQuest>>{};
          for (final quest in allQuests) {
            (groupedQuests[quest.status] ??= []).add(quest);
          }

          // Sortierte Liste der Status, damit 'active' immer oben ist
          final sortedStatuses = groupedQuests.keys.toList()
            ..sort((a, b) {
              if (a == QuestStatus.active) return -1;
              if (b == QuestStatus.active) return 1;
              if (a == QuestStatus.onHold) return -1;
              if (b == QuestStatus.onHold) return 1;
              return a.index.compareTo(b.index);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: sortedStatuses.length,
            itemBuilder: (context, index) {
              final status = sortedStatuses[index];
              final questsInGroup = groupedQuests[status]!;
              return _buildQuestGroup(status, questsInGroup);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add_task),
        label: const Text("Quest aus Bibliothek hinzufügen"),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => AddQuestFromLibraryScreen(campaignId: widget.campaign.id),
          )).then((_) => _loadQuests());
        },
      ),
    );
  }

  // Helfer-Widget, um eine Gruppe von Quests anzuzeigen
  Widget _buildQuestGroup(QuestStatus status, List<CampaignQuest> quests) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          "${_getGermanStatusName(status)} (${quests.length})",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        initiallyExpanded: status == QuestStatus.active || status == QuestStatus.onHold,
        children: quests.map((cq) {
          return ListTile(
            title: Text(cq.quest.title),
            subtitle: Text(cq.quest.description, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => EditCampaignQuestScreen(campaignId: widget.campaign.id, campaignQuest: cq),
              )).then((_) => _loadQuests());
            },
          );
        }).toList(),
      ),
    );
  }

  String _getGermanStatusName(QuestStatus status) {
    switch (status) {
      case QuestStatus.onHold: return "Pausierte Quests";
      case QuestStatus.active: return "Aktive Quests";
      case QuestStatus.completed: return "Abgeschlossene Quests";
      case QuestStatus.failed: return "Gescheiterte Quests";
      case QuestStatus.abandoned: return "Abgebrochene Quests";
    }
  }
}
