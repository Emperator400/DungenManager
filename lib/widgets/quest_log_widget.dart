// lib/widgets/quest_log_widget.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/quest.dart';
import '../screens/edit_campaign_quest_screen.dart';

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
  final dbHelper = DatabaseHelper.instance;
  late Future<List<CampaignQuest>> _campaignQuestsFuture;

  @override
  void initState() {
    super.initState();
    _campaignQuestsFuture = dbHelper.getQuestsForCampaign(widget.campaign.id);
  }

  // Diese Methode kann von aussen aufgerufen werden, um ein Neuladen zu erzwingen
  void reloadQuests() {
    setState(() {
      _campaignQuestsFuture = dbHelper.getQuestsForCampaign(widget.campaign.id);
    });
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
            if(status == QuestStatus.abgeschlossen) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                  child: Text(_getGermanStatusName(status), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                ...groupedQuests[status]!.map((cq) => ListTile(
                  title: Text(cq.quest.title, style: const TextStyle(fontSize: 14)),
                  dense: true,
                  onTap: () async {
                    await Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => EditCampaignQuestScreen(campaignId: widget.campaign.id, campaignQuest: cq)));
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
      case QuestStatus.verfuegbar: return "Verfügbar";
      case QuestStatus.aktiv: return "Aktiv";
      case QuestStatus.gescheitert: return "Gescheitert";
      case QuestStatus.abgeschlossen: return "Abgeschlossen";
    }
  }
}