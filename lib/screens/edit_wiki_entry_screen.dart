// lib/screens/edit_wiki_entry_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/wiki_entry.dart';

class EditWikiEntryScreen extends StatefulWidget {
  final WikiEntry? entryToEdit;

  const EditWikiEntryScreen({super.key, this.entryToEdit});

  @override
  State<EditWikiEntryScreen> createState() => _EditWikiEntryScreenState();
}

class _EditWikiEntryScreenState extends State<EditWikiEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  WikiEntryType _selectedType = WikiEntryType.Lore;
  final dbHelper = DatabaseHelper.instance;

  @override
  void initState() {
    super.initState();
    if (widget.entryToEdit != null) {
      _titleController = TextEditingController(text: widget.entryToEdit!.title);
      _contentController = TextEditingController(text: widget.entryToEdit!.content);
      _selectedType = widget.entryToEdit!.entryType;
    } else {
      _titleController = TextEditingController();
      _contentController = TextEditingController();
    }
  }

  void _saveForm() async {
    if (_formKey.currentState!.validate()) {
      final entry = WikiEntry(
        id: widget.entryToEdit?.id,
        title: _titleController.text,
        content: _contentController.text,
        entryType: _selectedType,
      );

      if (widget.entryToEdit != null) {
        await dbHelper.updateWikiEntry(entry);
      } else {
        await dbHelper.insertWikiEntry(entry);
      }
      
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entryToEdit == null ? 'Neuer Wiki-Eintrag' : 'Wiki-Eintrag bearbeiten'),
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
                decoration: const InputDecoration(labelText: 'Titel'),
                validator: (v) => v!.isEmpty ? 'Titel darf nicht leer sein' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<WikiEntryType>(
                value: _selectedType,
                decoration: const InputDecoration(labelText: 'Typ des Eintrags'),
                items: WikiEntryType.values.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type.toString().split('.').last));
                }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() { _selectedType = newValue; });
                  }
                },
              ),
              const SizedBox(height: 16),
              // Der Switch für "Spielercharakter" wurde hier entfernt.
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Inhalt', alignLabelWithHint: true, border: OutlineInputBorder()),
                maxLines: 15,
                validator: (v) => v!.isEmpty ? 'Inhalt darf nicht leer sein' : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}