import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sound.dart';
import '../viewmodels/edit_sound_viewmodel.dart';
import '../theme/dnd_theme.dart';

/// Enhanced Screen zur Bearbeitung von Sounds mit modernem Design
class EnhancedEditSoundScreen extends StatefulWidget {
  final Sound? sound;

  const EnhancedEditSoundScreen({
    Key? key,
    this.sound,
  }) : super(key: key);

  @override
  State<EnhancedEditSoundScreen> createState() => _EnhancedEditSoundScreenState();
}

class _EnhancedEditSoundScreenState extends State<EnhancedEditSoundScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _filePathController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  SoundType _selectedSoundType = SoundType.Ambiente;
  Duration? _duration;

  @override
  void initState() {
    super.initState();
    // ViewModel initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EditSoundViewModel>().initialize(widget.sound);
      _controllersFromViewModel();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _filePathController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _controllersFromViewModel() {
    final viewModel = context.read<EditSoundViewModel>();
    final sound = viewModel.sound;
    
    if (sound != null) {
      _nameController.text = sound!.name;
      _filePathController.text = sound!.filePath;
      _descriptionController.text = sound!.description;
      _tagsController.text = sound!.tags ?? '';
      _selectedSoundType = sound!.soundType;
      _duration = sound!.duration;
    }
  }

  void _updateViewModel() {
    final viewModel = context.read<EditSoundViewModel>();
    
    viewModel.updateName(_nameController.text);
    viewModel.updateFilePath(_filePathController.text);
    viewModel.updateDescription(_descriptionController.text);
    viewModel.updateSoundType(_selectedSoundType);
    viewModel.updateTags(_tagsController.text.isEmpty ? null : _tagsController.text);
    viewModel.updateDuration(_duration);
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Unbekannt';
    
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.sound == null ? 'Neuer Sound' : 'Sound bearbeiten',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: DnDTheme.mysticalPurple,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Consumer<EditSoundViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: Icon(Icons.save, color: Colors.white),
                onPressed: viewModel.canSave ? _saveSound : null,
                tooltip: 'Speichern',
              );
            },
          ),
        ],
      ),
      body: Consumer<EditSoundViewModel>(
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
                          controller: _nameController,
                          decoration: _buildInputDecoration('Name', Icons.title),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Name ist erforderlich';
                            }
                            return null;
                          },
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _filePathController,
                          decoration: _buildInputDecoration('Dateipfad', Icons.audio_file),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Dateipfad ist erforderlich';
                            }
                            return null;
                          },
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: 12),
                        Consumer<EditSoundViewModel>(
                          builder: (context, viewModel, child) {
                            return DropdownButtonFormField<SoundType>(
                              value: _selectedSoundType,
                              decoration: _buildInputDecoration('Sound-Typ', Icons.category),
                              items: SoundType.values.map((type) {
                                return DropdownMenuItem(
                                  value: type,
                                  child: Text(type.name),
                                );
                              }).toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() {
                                    _selectedSoundType = value;
                                  });
                                  _updateViewModel();
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Sound-Details
                  _buildSectionCard(
                    title: 'Sound-Details',
                    icon: Icons.music_note,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _descriptionController,
                          decoration: _buildInputDecoration('Beschreibung', Icons.description),
                          maxLines: 3,
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _tagsController,
                          decoration: _buildInputDecoration('Tags (kommagetrennt)', Icons.tag),
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: 12),
                        Consumer<EditSoundViewModel>(
                          builder: (context, viewModel, child) {
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Dauer: ${_formatDuration(_duration)}',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    if (_duration != null)
                                      ElevatedButton.icon(
                                        onPressed: () {
                                          setState(() {
                                            _duration = null;
                                          });
                                          _updateViewModel();
                                        },
                                        icon: Icon(Icons.clear, size: 16),
                                        label: Text('Entfernen'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.grey,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          final pickedDuration = await _showDurationPicker();
                                          if (pickedDuration != null) {
                                            setState(() {
                                              _duration = pickedDuration;
                                            });
                                            _updateViewModel();
                                          }
                                        },
                                        child: Text('Dauer wählen'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: DnDTheme.mysticalPurple,
                                        ),
                                      ),
                                    ),
                                    if (viewModel.sound?.fileSize != null) ...[
                                      const SizedBox(width: 12),
                                      Text(
                                        'Größe: ${viewModel.sound!.formattedFileSize}',
                                        style: TextStyle(color: Colors.grey.shade600),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            );
                          },
                        ),
                      ],
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

  Widget _buildActionButtons(EditSoundViewModel viewModel) {
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
            onPressed: viewModel.canSave ? _saveSound : null,
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
              onPressed: _duplicateSound,
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

  Future<Duration?> _showDurationPicker() async {
    // Simple Duration picker implementation
    final TextEditingController minutesController = TextEditingController(text: '0');
    final TextEditingController secondsController = TextEditingController(text: '0');

    return showDialog<Duration>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Dauer auswählen'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: minutesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Minuten',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(':', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: secondsController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Sekunden',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () {
                final minutes = int.tryParse(minutesController.text) ?? 0;
                final seconds = int.tryParse(secondsController.text) ?? 0;
                Navigator.pop(context, Duration(minutes: minutes, seconds: seconds));
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveSound() async {
    final viewModel = context.read<EditSoundViewModel>();
    
    if (!_formKey.currentState!.validate()) return;

    final success = await viewModel.saveSound();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sound erfolgreich gespeichert'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _duplicateSound() async {
    final viewModel = context.read<EditSoundViewModel>();
    await viewModel.duplicateSound();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sound dupliziert'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}
