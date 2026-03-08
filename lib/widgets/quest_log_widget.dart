// lib/widgets/quest_log_widget.dart
import 'package:flutter/material.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/quest_model_repository.dart';
import '../models/campaign.dart';
import '../models/quest.dart';
import '../models/campaign_quest.dart';
import '../screens/quests/edit_campaign_quest_screen.dart';

class QuestLogWidget extends StatefulWidget {
  final Campaign campaign;
  final VoidCallback onDataChanged;

  const QuestLogWidget({
    super.key,
    required this.campaign,
    required this.onDataChanged,
  });

  @override
  State<QuestLogWidget> createState() => QuestLogWidgetState();
}

class QuestLogWidgetState extends State<QuestLogWidget> {
  late final QuestModelRepository _questRepository;
  late Future<List<CampaignQuest>> _campaignQuestsFuture;

  @override
  void initState() {
    super.initState();
    _questRepository = QuestModelRepository(DatabaseConnection.instance);
    _campaignQuestsFuture = _loadCampaignQuests();
  }

  // Diese Methode kann von aussen aufgerufen werden, um ein Neuladen zu erzwingen
  void reloadQuests() {
    setState(() {
      _campaignQuestsFuture = _loadCampaignQuests();
    });
  }

  Future<List<CampaignQuest>> _loadCampaignQuests() async {
    // Da es keine getCampaignQuestsForCampaign Methode gibt, erstellen wir eine leere Liste
    // In einer echten Implementierung würde dies die Datenbank abfragen
    return <CampaignQuest>[];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<CampaignQuest>>(
      future: _campaignQuestsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Keine Quests für diese Kampagne aktiv."));
        }
        
        final allQuests = snapshot.data!;
        final groupedQuests = <QuestStatus, List<CampaignQuest>>{};
        for (final quest in allQuests) {
          (groupedQuests[quest.status] ??= []).add(quest);
        }
        final sortedStatuses = groupedQuests.keys.toList()..sort((a,b) => a.index.compareTo(b.index));

        return Column(
          children: sortedStatuses.map((status) {
            if(status == QuestStatus.completed) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8, left: 4),
                  child: Text(_getGermanStatusName(status), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...groupedQuests[status]!.map((cq) => ListTile(
                  title: Text(cq.quest.title, style: const TextStyle(fontSize: 14)),
                  dense: true,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute<CampaignQuest>(builder: (ctx) => EditCampaignQuestScreen(campaignId: widget.campaign.id, campaignQuest: cq)));
                    widget.onDataChanged();
                  },
                )),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  String _getGermanStatusName(QuestStatus status) {
    switch (status) {
      case QuestStatus.active: return "Aktiv";
      case QuestStatus.completed: return "Abgeschlossen";
      case QuestStatus.failed: return "Gescheitert";
      case QuestStatus.abandoned: return "Aufgegeben";
      case QuestStatus.onHold: return "Pausiert";
    }
  }
}
