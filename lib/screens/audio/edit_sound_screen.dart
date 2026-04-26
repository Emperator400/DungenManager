import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/sound.dart';
import '../../viewmodels/edit_sound_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_components/states/loading_state_widget.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';

class EditSoundScreen extends StatefulWidget {
  const EditSoundScreen({super.key, this.sound});

  final Sound? sound;

  @override
  State<EditSoundScreen> createState() => _EditSoundScreenState();
}

class _EditSoundScreenState extends State<EditSoundScreen> {
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
      _nameController.text = sound.name;
      _filePathController.text = sound.filePath;
      _descriptionController.text = sound.description;
      _tagsController.text = sound.tags ?? '';
      _selectedSoundType = sound.soundType;
      _duration = sound.duration;
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
    final C = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.sound == null ? 'Neuer Sound' : 'Sound bearbeiten'),
        backgroundColor: C.bgPanel,
        actions: [
          Consumer<EditSoundViewModel>(
            builder: (context, viewModel, child) => IconButton(
              icon: const Icon(Icons.save),
              onPressed: viewModel.canSave ? _saveSound : null,
              tooltip: 'Speichern',
            ),
          ),
        ],
      ),
      body: Consumer<EditSoundViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) return const LoadingStateWidget();
          return Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (viewModel.errorMessage != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: C.red.withValues(alpha: 0.1),
                        border: Border.all(color: C.red.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: C.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              viewModel.errorMessage!,
                              style: TextStyle(color: C.red),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 16),
                            onPressed: viewModel.clearError,
                            color: C.red,
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
                          controller: _nameController,
                          decoration: _buildInputDecoration('Name', Icons.title),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Name ist erforderlich' : null,
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _filePathController,
                          decoration: _buildInputDecoration('Dateipfad', Icons.audio_file),
                          validator: (value) =>
                              (value == null || value.trim().isEmpty) ? 'Dateipfad ist erforderlich' : null,
                          onChanged: (_) => _updateViewModel(),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<SoundType>(
                          value: _selectedSoundType,
                          decoration: _buildInputDecoration('Sound-Typ', Icons.category),
                          items: SoundType.values
                              .map((type) => DropdownMenuItem(value: type, child: Text(type.name)))
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedSoundType = value);
                              _updateViewModel();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                          builder: (context, vm, child) => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Dauer: ${_formatDuration(_duration)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: C.text,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  if (_duration != null)
                                    ElevatedButton.icon(
                                      onPressed: () {
                                        setState(() => _duration = null);
                                        _updateViewModel();
                                      },
                                      icon: const Icon(Icons.clear, size: 16),
                                      label: const Text('Entfernen'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: C.bgActive,
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
                                        final picked = await _showDurationPicker();
                                        if (picked != null) {
                                          setState(() => _duration = picked);
                                          _updateViewModel();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF7C3AED),
                                      ),
                                      child: const Text('Dauer wählen'),
                                    ),
                                  ),
                                  if (vm.sound?.fileSize != null) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      'Größe: ${vm.sound!.formattedFileSize}',
                                      style: TextStyle(color: C.textSoft),
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: C.bgPanel,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF7C3AED), size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: C.text),
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
      prefixIcon: Icon(icon, color: const Color(0xFF7C3AED)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFF7C3AED)),
      ),
      filled: true,
      fillColor: C.bgHover,
    );
  }

  Widget _buildActionButtons(EditSoundViewModel viewModel) {
    final C = context.appColors;
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: C.border),
            ),
            child: const Text('Abbrechen'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: viewModel.canSave ? _saveSound : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text('Speichern', style: TextStyle(color: Colors.white)),
          ),
        ),
        if (viewModel.isEditing) ...[
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _duplicateSound,
              icon: const Icon(Icons.copy, color: Colors.white),
              label: const Text('Duplizieren'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA580C),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<Duration?> _showDurationPicker() async {
    final minutesController = TextEditingController(text: '0');
    final secondsController = TextEditingController(text: '0');
    return showDialog<Duration>(
      context: context,
      builder: (context) => AlertDialog(
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
      ),
    );
  }

  Future<void> _saveSound() async {
    final viewModel = context.read<EditSoundViewModel>();
    if (!_formKey.currentState!.validate()) return;
    final success = await viewModel.saveSound();
    if (!mounted) return;
    if (success) {
      SnackBarHelper.showSuccess(context, 'Sound erfolgreich gespeichert');
      Navigator.pop(context, true);
    }
  }

  Future<void> _duplicateSound() async {
    final viewModel = context.read<EditSoundViewModel>();
    await viewModel.duplicateSound();
    if (!mounted) return;
    SnackBarHelper.showInfo(context, 'Sound dupliziert');
  }
}
