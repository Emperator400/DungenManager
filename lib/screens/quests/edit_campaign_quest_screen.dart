// lib/screens/edit_campaign_quest_screen.dart
import 'package:flutter/material.dart';
import '../../database/core/database_connection.dart';
import '../../models/quest.dart';
import '../../models/campaign_quest.dart';

class EditCampaignQuestScreen extends StatefulWidget {
  final CampaignQuest campaignQuest;
  final String campaignId;

  const EditCampaignQuestScreen({super.key, required this.campaignQuest, required this.campaignId});

  @override
  State<EditCampaignQuestScreen> createState() => _EditCampaignQuestScreenState();
}

class _EditCampaignQuestScreenState extends State<EditCampaignQuestScreen> {
  late QuestStatus _selectedStatus;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.campaignQuest.status;
    _notesController = TextEditingController(text: widget.campaignQuest.notes ?? '');
  }

  Future<void> _saveChanges() async {
    final updatedCampaignQuest = widget.campaignQuest.copyWith(
      status: _selectedStatus,
      notes: _notesController.text,
    );
    
    await _updateCampaignQuest(updatedCampaignQuest);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _updateCampaignQuest(CampaignQuest campaignQuest) async {
    final db = await DatabaseConnection.instance.database;
    await db.update(
      'campaign_quests',
      campaignQuest.toMap(),
      where: 'campaignId = ? AND questId = ?',
      whereArgs: [campaignQuest.campaignId, campaignQuest.questId],
    );
  }

  @override
  Widget build(BuildContext context) {
    final quest = widget.campaignQuest.quest;
    return Scaffold(
      appBar: AppBar(
        title: Text(quest.title),
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Text('Beschreibung', style: Theme.of(context).textTheme.titleMedium),
          Text(quest.description),
          const Divider(height: 24),
          Text('Ziel', style: Theme.of(context).textTheme.titleMedium),
          Text(quest.goal),
          const Divider(height: 24),
          // Dropdown zum Ändern des Status
          DropdownButtonFormField<QuestStatus>(
            value: _selectedStatus,
            decoration: const InputDecoration(labelText: 'Status der Quest'),
            items: QuestStatus.values.map((status) {
              return DropdownMenuItem(value: status, child: Text(status.toString().split('.').last));
            }).toList(),
            onChanged: (newValue) {
              if (newValue != null) {
                setState(() { _selectedStatus = newValue; });
              }
            },
          ),
          const SizedBox(height: 16),
          // Textfeld für deine privaten Notizen zum Quest-Fortschritt
          TextFormField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'DM-Notizen zum Fortschritt',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
            maxLines: 10,
          ),
        ],
      ),
    );
  }
}
