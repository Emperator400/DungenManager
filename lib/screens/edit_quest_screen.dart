// lib/screens/edit_quest_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/quest.dart';

class EditQuestScreen extends StatefulWidget {
  final Quest? questToEdit;

  const EditQuestScreen({super.key, this.questToEdit});

  @override
  State<EditQuestScreen> createState() => _EditQuestScreenState();
}

class _EditQuestScreenState extends State<EditQuestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _goalController;
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.questToEdit?.title ?? '');
    _descriptionController = TextEditingController(text: widget.questToEdit?.description ?? '');
    _goalController = TextEditingController(text: widget.questToEdit?.goal ?? '');
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final quest = Quest(
        id: widget.questToEdit?.id,
        title: _titleController.text,
        description: _descriptionController.text,
        goal: _goalController.text,
      );

      if (widget.questToEdit != null) {
        await dbHelper.updateQuest(quest);
      } else {
        await dbHelper.insertQuest(quest);
      }
      
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.questToEdit == null ? 'Neue Quest-Vorlage' : 'Quest-Vorlage bearbeiten'),
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
                decoration: const InputDecoration(labelText: 'Titel der Quest'),
                validator: (v) => v!.isEmpty ? 'Bitte einen Titel eingeben' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Beschreibung / Quest-Haken', alignLabelWithHint: true, border: OutlineInputBorder()),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? 'Bitte eine Beschreibung eingeben' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _goalController,
                decoration: const InputDecoration(labelText: 'Ziel der Quest', alignLabelWithHint: true, border: OutlineInputBorder()),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Bitte ein Ziel eingeben' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}