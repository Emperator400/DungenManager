import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/active_session_viewmodel.dart';
import 'session_quadrant_base.dart';

/// Live-Notizen-Quadrant - Ermöglicht schnelle Notizen während der Session
/// 
/// Features:
/// - Auto-Save mit Debouncing (speichert nach 1.5 Sekunden Inaktivität)
/// - Visuelles Feedback für Speicherstatus
/// - Synchronisation mit ViewModel-Updates
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
  
  /// Debounce-Zeit in Millisekunden
  static const int _debounceDelayMs = 1500;

  @override
  void initState() {
    super.initState();
    print('🟢 [LiveNotes] initState aufgerufen');
    print('🟢 [LiveNotes] Session ID: ${widget.viewModel.currentSession.id}');
    print('🟢 [LiveNotes] Aktuelle LiveNotes: "${widget.viewModel.currentSession.liveNotes}"');
    
    _controller = TextEditingController(text: widget.viewModel.currentSession.liveNotes);
    _lastSavedText = widget.viewModel.currentSession.liveNotes;
    
    // Listener für ViewModel-Änderungen
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void didUpdateWidget(LiveNotesQuadrant oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Wenn sich das ViewModel geändert hat, Listener aktualisieren
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

  /// Wird aufgerufen, wenn sich das ViewModel ändert
  void _onViewModelChanged() {
    _syncWithViewModel();
  }

  /// Synchronisiert den Controller mit dem ViewModel
  void _syncWithViewModel() {
    final viewModelNotes = widget.viewModel.currentSession.liveNotes;
    
    // Nur aktualisieren, wenn sich die Notizen von außen geändert haben
    // und der Benutzer gerade nicht tippt
    if (viewModelNotes != _lastSavedText && 
        viewModelNotes != _controller.text &&
        !_hasUnsavedChanges) {
      _controller.text = viewModelNotes;
      _lastSavedText = viewModelNotes;
    }
  }

  /// Behandelt Änderungen im Textfeld
  void _onTextChanged(String value) {
    _hasUnsavedChanges = value != _lastSavedText;
    
    // Abbrechen des bisherigen Timers
    _debounceTimer?.cancel();
    
    if (_hasUnsavedChanges) {
      // Neuen Timer starten für Auto-Save
      _debounceTimer = Timer(
        const Duration(milliseconds: _debounceDelayMs),
        () => _saveNotes(value),
      );
    }
    
    setState(() {});
  }

  /// Speichert die Notizen in der Datenbank
  Future<void> _saveNotes(String notes) async {
    print('🔵 [LiveNotes] _saveNotes aufgerufen');
    print('🔵 [LiveNotes] hasUnsavedChanges: $_hasUnsavedChanges, isSaving: $_isSaving');
    
    if (!_hasUnsavedChanges || _isSaving) {
      print('🔵 [LiveNotes] Speichern übersprungen (keine Änderungen oder bereits am Speichern)');
      return;
    }
    
    setState(() {
      _isSaving = true;
    });
    
    try {
      print('🔵 [LiveNotes] Rufe viewModel.updateLiveNotes auf...');
      await widget.viewModel.updateLiveNotes(notes);
      _lastSavedText = notes;
      _hasUnsavedChanges = false;
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
      
      print('✅ [LiveNotes] Notizen erfolgreich gespeichert');
    } catch (e) {
      print('❌ [LiveNotes] Fehler beim Speichern: $e');
      
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        
        // Fehler-Feedback anzeigen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Speichern der Notizen: $e'),
            backgroundColor: DnDTheme.errorRed,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// Sofortiges Speichern (z.B. beim Verlassen des Feldes)
  Future<void> _saveImmediately() async {
    _debounceTimer?.cancel();
    
    if (_hasUnsavedChanges) {
      await _saveNotes(_controller.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SessionQuadrantBase(
      title: "Live-Notizen",
      icon: Icons.note_alt,
      color: DnDTheme.ancientGold,
      content: _buildContent(),
    );
  }

  Widget _buildContent() {
    return Container(
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        border: Border.all(
          color: DnDTheme.ancientGold.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'Live-Notizen...',
                hintStyle: TextStyle(color: Colors.white54, fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(8),
              ),
              onChanged: _onTextChanged,
              onEditingComplete: _saveImmediately,
              onSubmitted: (_) => _saveImmediately(),
            ),
          ),
          _buildStatusBar(),
        ],
      ),
    );
  }

  Widget _buildStatusBar() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.ancientGold.withValues(alpha: 0.2),
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(DnDTheme.radiusSmall),
          bottomRight: Radius.circular(DnDTheme.radiusSmall),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Auto-Save',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
              fontSize: 8,
            ),
          ),
          _buildSaveIndicator(),
        ],
      ),
    );
  }

  Widget _buildSaveIndicator() {
    if (_isSaving) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: DnDTheme.mysticalPurple,
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 8,
              height: 8,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'Speichere...',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 8,
              ),
            ),
          ],
        ),
      );
    }
    
    if (_hasUnsavedChanges) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: DnDTheme.ancientGold.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
        ),
        child: Text(
          'Ungespeichert',
          style: DnDTheme.bodyText2.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 8,
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: DnDTheme.successGreen,
        borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check,
            size: 8,
            color: Colors.white,
          ),
          const SizedBox(width: 2),
          Text(
            'Gespeichert',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 8,
            ),
          ),
        ],
      ),
    );
  }
}