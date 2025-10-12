// lib/screens/edit_campaign_quest_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/quest.dart';

class EditCampaignQuestScreen extends StatefulWidget {
  final CampaignQuest campaignQuest;
  final String campaignId;

  const EditCampaignQuestScreen({super.key, required this.campaignQuest, required this.campaignId});

  @override
  State<EditCampaignQuestScreen> createState() => _EditCampaignQuestScreenState();
}

class _EditCampaignQuestScreenState extends State<EditCampaignQuestScreen> {
  final dbHelper = DatabaseHelper.instance;
  late QuestStatus _selectedStatus;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.campaignQuest.status;
    _notesController = TextEditingController(text: widget.campaignQuest.notes ?? '');
  }

  void _saveChanges() async {
    await dbHelper.updateCampaignQuest(
      widget.campaignId,
      widget.campaignQuest.quest.id,
      _selectedStatus,
      _notesController.text,
    );
    if (mounted) Navigator.of(context).pop();
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
          Text("Beschreibung", style: Theme.of(context).textTheme.titleMedium),
          Text(quest.description),
          const Divider(height: 24),
          Text("Ziel", style: Theme.of(context).textTheme.titleMedium),
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