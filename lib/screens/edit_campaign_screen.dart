// lib/screens/edit_campaign_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';

class EditCampaignScreen extends StatefulWidget {
  final Campaign? campaignToEdit;

  const EditCampaignScreen({super.key, this.campaignToEdit});

  @override
  State<EditCampaignScreen> createState() => _EditCampaignScreenState();
}

class _EditCampaignScreenState extends State<EditCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.campaignToEdit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.campaignToEdit?.description ?? '');
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final campaign = Campaign(
        id: widget.campaignToEdit?.id,
        title: _titleController.text,
        description: _descriptionController.text,
      );

      if (widget.campaignToEdit != null) {
        await dbHelper.updateCampaign(campaign);
      } else {
        await dbHelper.insertCampaign(campaign);
      }

      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.campaignToEdit == null ? 'Neues Buch erstellen' : 'Buch bearbeiten'),
        actions: [IconButton(icon: const Icon(Icons.save), onPressed: _saveForm)],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titel der Kampagne'),
                validator: (v) => v!.isEmpty ? 'Bitte einen Titel eingeben' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Kurzbeschreibung', alignLabelWithHint: true, border: OutlineInputBorder()),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Bitte eine Beschreibung eingeben' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}