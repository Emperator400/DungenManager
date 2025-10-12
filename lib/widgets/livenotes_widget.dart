// lib/widgets/livenotes_widget.dart
import 'dart:async';
import 'package:flutter/material.dart';
import '../models/session.dart';
import '../database/database_helper.dart';

enum SaveStatus { saved, unsaved, saving }

class LiveNotesWidget extends StatefulWidget {
  final Session session;
  const LiveNotesWidget({super.key, required this.session});

  @override
  State<LiveNotesWidget> createState() => _LiveNotesWidgetState();
}

class _LiveNotesWidgetState extends State<LiveNotesWidget> {
  final dbHelper = DatabaseHelper.instance;
  late final TextEditingController _liveNotesController;
  Timer? _debounce;
  SaveStatus _notesSaveStatus = SaveStatus.saved;
  late Session _currentSession;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _liveNotesController = TextEditingController(text: _currentSession.liveNotes);
    _liveNotesController.addListener(_onNotesChanged);
  }

  @override
  void dispose() {
    _liveNotesController.removeListener(_onNotesChanged);
    _liveNotesController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onNotesChanged() {
    if (_notesSaveStatus == SaveStatus.saved) {
      setState(() {
        _notesSaveStatus = SaveStatus.unsaved;
      });
    }
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(seconds: 2), _saveLiveNotes);
  }

  void _saveLiveNotes() async {
    if (_currentSession.liveNotes == _liveNotesController.text) return;
    
    setState(() { _notesSaveStatus = SaveStatus.saving; });

    final updatedSession = Session(
      id: _currentSession.id,
      campaignId: _currentSession.campaignId,
      title: _currentSession.title,
      inGameTimeInMinutes: _currentSession.inGameTimeInMinutes,
      liveNotes: _liveNotesController.text,
    );
    
    await dbHelper.updateSession(updatedSession);
    
    if (!mounted) return;

    setState(() {
      _currentSession = updatedSession;
      _notesSaveStatus = SaveStatus.saved;
    });
    print("Live notes auto-saved!");
  }

  Widget _buildSaveStatusIndicator() {
    switch (_notesSaveStatus) {
      case SaveStatus.saved:
        return const Row(children: [
          Icon(Icons.check_circle, color: Colors.green, size: 16),
          SizedBox(width: 4),
          Text("Gespeichert", style: TextStyle(color: Colors.grey, fontSize: 12)),
        ]);
      case SaveStatus.unsaved:
        return const Text("...", style: TextStyle(color: Colors.grey, fontSize: 16));
      case SaveStatus.saving:
        return const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).primaryColor.withOpacity(0.2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(children: [
            Icon(Icons.edit, size: 18, color: Colors.grey[400]),
            const SizedBox(width: 8),
            const Expanded(child: Text("Live-Notizen", style: TextStyle(fontWeight: FontWeight.bold))),
            _buildSaveStatusIndicator(),
          ]),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _liveNotesController,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: "Schnelle Notizen während des Spiels...",
              ),
            ),
          ),
        ),
      ],
    );
  }
}