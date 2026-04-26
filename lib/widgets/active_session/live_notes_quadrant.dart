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
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fehler beim Speichern: $e', style: const TextStyle(fontSize: 12)),
          backgroundColor: context.appColors.red,
          duration: const Duration(seconds: 2),
        ));
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
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(fontSize: 12, color: C.text, height: 1.5),
              decoration: InputDecoration(
                hintText: 'Schnelle Notizen während des Spiels...',
                hintStyle: TextStyle(fontSize: 12, color: C.textSoft),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: _onTextChanged,
              onEditingComplete: _saveImmediately,
              onSubmitted: (_) => _saveImmediately(),
            ),
          ),
        ),
        _buildStatusBar(C),
      ],
    );
  }

  Widget _buildStatusBar(AppColorsExtension C) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Auto-Save', style: TextStyle(fontSize: 9, color: C.textSoft)),
          _buildSaveIndicator(C),
        ],
      ),
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
          Text('Speichere...', style: TextStyle(fontSize: 9, color: C.textSoft)),
        ],
      );
    }

    if (_hasUnsavedChanges) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: C.amber, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text('Ungespeichert', style: TextStyle(fontSize: 9, color: C.amber)),
        ],
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.check, size: 9, color: C.green),
        const SizedBox(width: 3),
        Text('Gespeichert', style: TextStyle(fontSize: 9, color: C.textSoft)),
      ],
    );
  }
}
