import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/session.dart';
import '../viewmodels/edit_session_viewmodel.dart';
import '../theme/dnd_theme.dart';

/// Enhanced Screen zur Bearbeitung von Sessions mit modernem Design
class EnhancedEditSessionScreen extends StatefulWidget {
  final Session? session;

  const EnhancedEditSessionScreen({
    Key? key,
    this.session,
  }) : super(key: key);

  @override
  State<EnhancedEditSessionScreen> createState() => _EnhancedEditSessionScreenState();
}

class _EnhancedEditSessionScreenState extends State<EnhancedEditSessionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _campaignIdController = TextEditingController();
  final _liveNotesController = TextEditingController();
  int _inGameTimeInMinutes = 480; // 8 Stunden Standard

  @override
  void initState() {
    super.initState();
    // ViewModel initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditSessionViewModel>().initialize(widget.session);
      _controllersFromViewModel();
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
                      decoration: _buildInputDecoration('Notizen während der Session', Icons.edit_note),
                      maxLines: 8,
                      onChanged: (_) => _updateViewModel(),
                    ),
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
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildActionButtons(EditSessionViewModel viewModel) {
    return Row(
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
}
