// lib/widgets/tools_widget.dart
import 'package:flutter/material.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import 'time_tracker_widget.dart';
import 'quest_log_widget.dart'; // Importiert unser neues Widget

class ToolsWidget extends StatelessWidget {
  final Session session;
  final Campaign campaign;
  final Function(int) onTimeAdd;
  final VoidCallback onDataChanged;

  const ToolsWidget({
    super.key,
    required this.session,
    required this.campaign,
    required this.onTimeAdd,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        // Zeit-Tracker Kachel
        Card(child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: TimeTrackerWidget(totalMinutes: session.inGameTimeInMinutes, onTimeAdd: onTimeAdd),
        )),
        // Quest-Log Kachel (ruft jetzt das neue, saubere Widget auf)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: QuestLogWidget(campaign: campaign, onDataChanged: onDataChanged),
          ),
        ),
      ],
    );
  }
}