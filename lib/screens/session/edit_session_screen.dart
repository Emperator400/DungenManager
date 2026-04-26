import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/session.dart';
import '../../models/sound.dart';
import '../../viewmodels/edit_session_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/audio/sound_picker_widget.dart';
import '../../services/sound_service.dart';

class EditSessionScreen extends StatefulWidget {
  final Session? session;
  final bool isNewSession;

  const EditSessionScreen({
    super.key,
    this.session,
    this.isNewSession = false,
  });

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _campaignIdController = TextEditingController();
  final _liveNotesController = TextEditingController();
  int _inGameTimeInMinutes = 480;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final viewModel = context.read<EditSessionViewModel>();
      await viewModel.initialize(widget.session, isNewSession: widget.isNewSession);
      _controllersFromViewModel();
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
      _titleController.text = session.title;
      _campaignIdController.text = session.campaignId;
      _liveNotesController.text = session.liveNotes;
      _inGameTimeInMinutes = session.inGameTimeInMinutes;
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
    final C = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.session == null ? 'Neue Session' : 'Session bearbeiten',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF7C3AED),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<EditSessionViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: const Icon(Icons.save, color: Colors.white),
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
            return const Center(child: CircularProgressIndicator(color: Color(0xFF7C3AED)));
          }

          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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

                  _buildSectionCard(
                    title: 'Grundinformationen',
                    icon: Icons.info_outline,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          style: const TextStyle(color: Colors.white),
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
                          style: const TextStyle(color: Colors.white),
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
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    activeTrackColor: const Color(0xFF7C3AED),
                                    inactiveTrackColor: Colors.grey.shade300,
                                    thumbColor: const Color(0xFF7C3AED),
                                    overlayColor: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                                  ),
                                  child: Slider(
                                    value: _inGameTimeInMinutes.toDouble(),
                                    min: 30,
                                    max: 1440,
                                    divisions: 141,
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

                  _buildSectionCard(
                    title: 'Live-Notes',
                    icon: Icons.note_alt,
                    child: TextFormField(
                      controller: _liveNotesController,
                      style: const TextStyle(color: Colors.white),
                      decoration: _buildInputDecoration('Notizen während der Session', Icons.edit_note),
                      maxLines: 8,
                      onChanged: (_) => _updateViewModel(),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Consumer<EditSessionViewModel>(
                    builder: (context, viewModel, child) {
                      return _buildSectionCard(
                        title: 'Sounds',
                        icon: Icons.music_note,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (viewModel.linkedSounds.isNotEmpty)
                              Column(
                                children: viewModel.linkedSounds.map((sound) {
                                  return Container(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: C.bgHover,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.music_note, color: Color(0xFF7C3AED)),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                sound.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                              if (sound.description.isNotEmpty)
                                                Text(
                                                  sound.description,
                                                  style: const TextStyle(
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
                                          icon: Icon(Icons.play_arrow, color: C.accent),
                                          onPressed: () => _playSound(sound),
                                          tooltip: 'Abspielen',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white70),
                                          onPressed: () => viewModel.removeLinkedSound(sound.id),
                                          tooltip: 'Entfernen',
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            if (viewModel.linkedSounds.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Keine Sounds verlinkt',
                                  style: TextStyle(color: Colors.white54),
                                ),
                              ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => _showSoundPicker(context),
                              icon: const Icon(Icons.add, color: Colors.white),
                              label: const Text('Sounds hinzufügen'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7C3AED),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 24),

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
    final C = context.appColors;
    return Card(
      elevation: 2,
      color: C.bgPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF7C3AED), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
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
    final C = context.appColors;
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      hintStyle: const TextStyle(color: Colors.white54),
      prefixIcon: Icon(icon, color: const Color(0xFF7C3AED)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: BorderSide(color: const Color(0xFF7C3AED).withValues(alpha: 0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8.0),
        borderSide: const BorderSide(color: Color(0xFF7C3AED)),
      ),
      filled: true,
      fillColor: C.bgHover,
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
                child: const Text('Abbrechen'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: viewModel.canSave ? _saveSession : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C3AED),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
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
                  icon: const Icon(Icons.copy, color: Colors.white),
                  label: const Text('Duplizieren'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
          ],
        ),
        if (viewModel.isEditing) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _deleteSession(viewModel),
              icon: const Icon(Icons.delete, color: Colors.white),
              label: const Text(
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
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
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
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Session dupliziert'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _deleteSession(EditSessionViewModel viewModel) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Session löschen'),
        content: Text(
          'Möchtest du die Session "${viewModel.session?.title}" wirklich löschen?\n\n'
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await viewModel.deleteSession();
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session erfolgreich gelöscht'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fehler beim Löschen der Session'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showSoundPicker(BuildContext context) {
    final C = context.appColors;
    final viewModel = context.read<EditSessionViewModel>();
    final initialSoundIds = viewModel.session?.linkedSoundIds ?? [];
    showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: C.bg,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
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
        const SnackBar(
          content: Text('Fehler beim Abspielen des Sounds'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
