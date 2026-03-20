import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/session.dart';
import '../../models/sound.dart';
import '../../viewmodels/edit_session_viewmodel.dart';
import '../../theme/dnd_theme.dart';
import '../../widgets/audio/sound_picker_widget.dart';
import '../../services/sound_service.dart';

/// Enhanced Screen zur Bearbeitung von Sessions mit modernem Design
class EditSessionScreen extends StatefulWidget {
  final Session? session;
  final bool isNewSession;

  const EditSessionScreen({
    Key? key,
    this.session,
    this.isNewSession = false,
  }) : super(key: key);

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _campaignIdController = TextEditingController();
  final _liveNotesController = TextEditingController();
  int _inGameTimeInMinutes = 480; // 8 Stunden Standard

  @override
  void initState() {
    super.initState();
    // ViewModel initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<EditSessionViewModel>();
      await viewModel.initialize(widget.session, isNewSession: widget.isNewSession);
      _controllersFromViewModel();
      // Verlinkte Sounds laden
      await viewModel.loadLinkedSounds();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _campaignIdController.dispose();
    _liveNotesController.dispose();
    super.dispose();
  }

  void _controllersFromViewModel() {
    final viewModel = context.read<EditSessionViewModel>();
    final session = viewModel.session;
    
    if (session != null) {
      _titleController.text = session!.title;
      _campaignIdController.text = session!.campaignId;
      _liveNotesController.text = session!.liveNotes;
      _inGameTimeInMinutes = session!.inGameTimeInMinutes;
    }
  }

  void _updateViewModel() {
    final viewModel = context.read<EditSessionViewModel>();
    
    viewModel.updateTitle(_titleController.text);
    viewModel.updateCampaignId(_campaignIdController.text);
    viewModel.updateLiveNotes(_liveNotesController.text);
    viewModel.updateInGameTimeInMinutes(_inGameTimeInMinutes);
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.session == null ? 'Neue Session' : 'Session bearbeiten',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: DnDTheme.mysticalPurple,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Consumer<EditSessionViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: Icon(Icons.save, color: Colors.white),
                onPressed: viewModel.canSave ? _saveSession : null,
                tooltip: 'Speichern',
              );
            },
          ),
        ],
      ),
      body: Consumer<EditSessionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return Center(child: CircularProgressIndicator(color: DnDTheme.mysticalPurple));
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Fehlermeldung
                  if (viewModel.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade200),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: Colors.red.shade600, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: TextStyle(color: Colors.red.shade800),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: viewModel.clearError,
                            color: Colors.red.shade600,
                          ),
                        ],
                      ),
                    ),

                  // Grundinformationen
                  _buildSectionCard(
                    title: 'Grundinformationen',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          style: TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration('Titel', Icons.title),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Titel ist erforderlich';
                            }
                            return null;
                          },
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _campaignIdController,
                          style: TextStyle(color: Colors.white),
                          decoration: _buildInputDecoration('Campaign ID', Icons.campaign),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Campaign ID ist erforderlich';
                            }
                            return null;
                          },
                          onChanged: (_) => _updateViewModel(),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Session-Details
                  _buildSectionCard(
                    title: 'Session-Details',
                    icon: Icons.schedule,
                    child: Column(
                      children: [
                        Consumer<EditSessionViewModel>(
                          builder: (context, viewModel, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Spielzeit: ${_formatDuration(_inGameTimeInMinutes)}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: DnDTheme.mysticalPurple,
                                    inactiveTrackColor: Colors.grey.shade300,
                                    thumbColor: DnDTheme.mysticalPurple,
                                    overlayColor: DnDTheme.mysticalPurple.withOpacity(0.2),
                                  ),
                                  child: Slider(
                                    value: _inGameTimeInMinutes.toDouble(),
                                    min: 30, // 30 Minuten
                                    max: 1440, // 24 Stunden
                                    divisions: 141, // 10-Minuten-Schritte
                                    onChanged: (value) {
                                      setState(() {
                                        _inGameTimeInMinutes = value.round();
                                      });
                                      _updateViewModel();
                                    },
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('30min', style: TextStyle(color: Colors.grey.shade600)),
                                    Text('24h', style: TextStyle(color: Colors.grey.shade600)),
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Live-Notes
                  _buildSectionCard(
                    title: 'Live-Notes',
                    icon: Icons.note_alt,
                    child: TextFormField(
                      controller: _liveNotesController,
                      style: TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Notizen während der Session', Icons.edit_note),
                      maxLines: 8,
                      onChanged: (_) => _updateViewModel(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sounds
                  Consumer<EditSessionViewModel>(
                    builder: (context, viewModel, child) {
                      return _buildSectionCard(
                        title: 'Sounds',
                        icon: Icons.music_note,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Anzeige der verlinkten Sounds mit Play-Buttons
                              if (viewModel.linkedSounds.isNotEmpty)
                                Column(
                                  children: viewModel.linkedSounds.map((sound) {
                                    return Container(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: DnDTheme.slateGrey,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: DnDTheme.mysticalPurple.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.music_note, color: DnDTheme.mysticalPurple),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  sound.name,
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.white,
                                                  ),
                                                ),
                                                if (sound.description.isNotEmpty)
                                                  Text(
                                                    sound.description,
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      color: Colors.white70,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.play_arrow, color: DnDTheme.arcaneBlue),
                                            onPressed: () => _playSound(sound),
                                            tooltip: 'Abspielen',
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.close, color: Colors.white70),
                                            onPressed: () => viewModel.removeLinkedSound(sound.id),
                                            tooltip: 'Entfernen',
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                            
                              if (viewModel.linkedSounds.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  child: Text(
                                    'Keine Sounds verlinkt',
                                    style: TextStyle(color: Colors.white54),
                                  ),
                                ),
                            
                              const SizedBox(height: 12),
                            
                              // Button zum Hinzufügen von Sounds
                              ElevatedButton.icon(
                                onPressed: () => _showSoundPicker(context),
                                icon: Icon(Icons.add, color: Colors.white),
                                label: Text('Sounds hinzufügen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DnDTheme.mysticalPurple,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                              ),
                            ],
                          ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Aktionen
                  _buildActionButtons(viewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      color: DnDTheme.stoneGrey,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: DnDTheme.mysticalPurple, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white70),
      hintStyle: TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: DnDTheme.mysticalPurple),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: DnDTheme.mysticalPurple.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: DnDTheme.mysticalPurple),
      ),
      filled: true,
      fillColor: DnDTheme.slateGrey,
    );
  }

  Widget _buildActionButtons(EditSessionViewModel viewModel) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade400),
                ),
                child: Text('Abbrechen'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: viewModel.canSave ? _saveSession : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: DnDTheme.mysticalPurple,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  'Speichern',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 12),
            if (viewModel.isEditing)
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _duplicateSession,
                  icon: Icon(Icons.copy, color: Colors.white),
                  label: Text('Duplizieren'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
        
        // Löschen-Button (nur beim Bearbeiten einer existierenden Session)
        if (viewModel.isEditing) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _deleteSession(viewModel),
              icon: Icon(Icons.delete, color: Colors.white),
              label: Text(
                'Session löschen',
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade700,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _saveSession() async {
    final viewModel = context.read<EditSessionViewModel>();
    
    if (!_formKey.currentState!.validate()) return;

    final success = await viewModel.saveSession();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session erfolgreich gespeichert'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _duplicateSession() async {
    final viewModel = context.read<EditSessionViewModel>();
    await viewModel.duplicateSession();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Session dupliziert'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _deleteSession(EditSessionViewModel viewModel) async {
    // Bestätigungsdialog anzeigen
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Session löschen'),
        content: Text(
          'Möchtest du die Session "${viewModel.session?.title}" wirklich löschen?\n\n'
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.deleteSession();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session erfolgreich gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Zurück zur Liste mit Refresh-Flag
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Löschen der Session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSoundPicker(BuildContext context) {
    final viewModel = context.read<EditSessionViewModel>();
    final initialSoundIds = viewModel.session?.linkedSoundIds ?? [];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: DnDTheme.dungeonBlack,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(DnDTheme.radiusMedium),
              topRight: Radius.circular(DnDTheme.radiusMedium),
            ),
          ),
          child: SoundPickerWidget(
            initiallySelectedSoundIds: initialSoundIds,
            onSelectionChanged: (selectedIds) {
              viewModel.updateLinkedSoundIds(selectedIds);
            },
          ),
        ),
      ),
    ).then((selectedIds) {
      if (selectedIds is List<String> && mounted) {
        viewModel.updateLinkedSoundIds(selectedIds);
        setState(() {});
      }
    });
  }

  Future<void> _playSound(Sound sound) async {
    final success = await SoundService.playSound(sound.filePath);
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Abspielen des Sounds'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
