import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/active_session_viewmodel.dart';

class LiveNotesQuadrant extends StatefulWidget {
  final ActiveSessionViewModel viewModel;

  const LiveNotesQuadrant({
    super.key,
    required this.viewModel,
  });

  @override
  State<LiveNotesQuadrant> createState() => _LiveNotesQuadrantState();
}

class _LiveNotesQuadrantState extends State<LiveNotesQuadrant> {
  late TextEditingController _controller;
  Timer? _debounceTimer;
  bool _isSaving = false;
  bool _hasUnsavedChanges = false;
  String? _lastSavedText;

  static const int _debounceDelayMs = 1500;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.viewModel.currentSession.liveNotes);
    _lastSavedText = widget.viewModel.currentSession.liveNotes;
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void didUpdateWidget(LiveNotesQuadrant oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.viewModel != widget.viewModel) {
      oldWidget.viewModel.removeListener(_onViewModelChanged);
      widget.viewModel.addListener(_onViewModelChanged);
      _syncWithViewModel();
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.viewModel.removeListener(_onViewModelChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onViewModelChanged() => _syncWithViewModel();

  void _syncWithViewModel() {
    final viewModelNotes = widget.viewModel.currentSession.liveNotes;
    if (viewModelNotes != _lastSavedText &&
        viewModelNotes != _controller.text &&
        !_hasUnsavedChanges) {
      _controller.text = viewModelNotes;
      _lastSavedText = viewModelNotes;
    }
  }

  void _onTextChanged(String value) {
    _hasUnsavedChanges = value != _lastSavedText;
    _debounceTimer?.cancel();
    if (_hasUnsavedChanges) {
      _debounceTimer = Timer(
        const Duration(milliseconds: _debounceDelayMs),
        () => _saveNotes(value),
      );
    }
    setState(() {});
  }

  Future<void> _saveNotes(String notes) async {
    if (!_hasUnsavedChanges || _isSaving) return;
    setState(() => _isSaving = true);
    try {
      await widget.viewModel.updateLiveNotes(notes);
      _lastSavedText = notes;
      _hasUnsavedChanges = false;
      if (mounted) setState(() => _isSaving = false);
    } catch (e) {
      debugPrint('LiveNotesQuadrant: Fehler beim Speichern: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern der Notizen: $e'),
            backgroundColor: context.appColors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _saveImmediately() async {
    _debounceTimer?.cancel();
    if (_hasUnsavedChanges) await _saveNotes(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
          child: Row(
            children: [
              Icon(Icons.edit_note, size: 13, color: C.amber),
              const SizedBox(width: 6),
              Text(
                'Live-Notizen',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.text),
              ),
            ],
          ),
        ),
        Expanded(
          child: TextField(
            controller: _controller,
            maxLines: null,
            expands: true,
            textAlignVertical: TextAlignVertical.top,
            style: TextStyle(fontSize: 12, color: C.text, height: 1.6),
            decoration: InputDecoration(
              hintText: 'Notizen während der Session...',
              hintStyle: TextStyle(color: C.textSoft, fontSize: 12),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 14),
              filled: false,
            ),
            onChanged: _onTextChanged,
            onTapOutside: (_) => _saveImmediately(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Auto-Save', style: TextStyle(fontSize: 10, color: C.textSoft)),
              _buildSaveIndicator(C),
            ],
          ),
        ),
        Divider(height: 1, thickness: 1, color: C.border),
      ],
    );
  }

  Widget _buildSaveIndicator(AppColorsExtension C) {
    if (_isSaving) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 8,
            height: 8,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: C.textSoft),
          ),
          const SizedBox(width: 4),
          Text('Speichere...', style: TextStyle(fontSize: 10, color: C.textSoft)),
        ],
      );
    }
    if (_hasUnsavedChanges) {
      return Text('Ungespeichert', style: TextStyle(fontSize: 10, color: C.amber));
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check, size: 10, color: C.green),
        const SizedBox(width: 3),
        Text('Gespeichert', style: TextStyle(fontSize: 10, color: C.green)),
      ],
    );
  }
}
