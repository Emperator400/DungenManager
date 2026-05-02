import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/session.dart';
import '../../models/sound.dart';
import '../../viewmodels/edit_session_viewmodel.dart';
import '../../theme/app_theme.dart';
import '../../widgets/audio/sound_picker_widget.dart';
import '../../widgets/ui_components/feedback/confirmation_dialog.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
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
      backgroundColor: C.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Consumer<EditSessionViewModel>(
          builder: (context, vm, _) => _buildTopBar(context, vm, C),
        ),
      ),
      body: Consumer<EditSessionViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

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
                        border: Border.all(color: C.red.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error, color: C.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(child: Text(viewModel.errorMessage!, style: TextStyle(color: C.red))),
                          IconButton(
                            icon: Icon(Icons.close, size: 16, color: C.red),
                            onPressed: viewModel.clearError,
                          ),
                        ],
                      ),
                    ),

                  _EditorCard(
                    title: 'Grundinformationen',
                    C: C,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        style: TextStyle(color: C.text),
                        decoration: _inputDecoration('Titel', Icons.title, C),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Titel ist erforderlich';
                          return null;
                        },
                        onChanged: (_) => _updateViewModel(),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _campaignIdController,
                        style: TextStyle(color: C.text),
                        decoration: _inputDecoration('Campaign ID', Icons.campaign, C),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return 'Campaign ID ist erforderlich';
                          return null;
                        },
                        onChanged: (_) => _updateViewModel(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _EditorCard(
                    title: 'Session-Details',
                    C: C,
                    children: [
                      Consumer<EditSessionViewModel>(
                        builder: (context, viewModel, child) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spielzeit: ${_formatDuration(_inGameTimeInMinutes)}',
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: C.text),
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: C.accent,
                                inactiveTrackColor: C.border,
                                thumbColor: C.accent,
                                overlayColor: C.accent.withValues(alpha: 0.2),
                              ),
                              child: Slider(
                                value: _inGameTimeInMinutes.toDouble(),
                                min: 30,
                                max: 1440,
                                divisions: 141,
                                onChanged: (value) {
                                  setState(() => _inGameTimeInMinutes = value.round());
                                  _updateViewModel();
                                },
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('30min', style: TextStyle(fontSize: 11, color: C.textSoft)),
                                Text('24h', style: TextStyle(fontSize: 11, color: C.textSoft)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  _EditorCard(
                    title: 'Live-Notes',
                    C: C,
                    children: [
                      TextFormField(
                        controller: _liveNotesController,
                        style: TextStyle(color: C.text),
                        decoration: _inputDecoration('Notizen während der Session', Icons.edit_note, C),
                        maxLines: 8,
                        onChanged: (_) => _updateViewModel(),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Consumer<EditSessionViewModel>(
                    builder: (context, viewModel, child) => _EditorCard(
                      title: 'Sounds',
                      C: C,
                      children: [
                        if (viewModel.linkedSounds.isNotEmpty)
                          ...viewModel.linkedSounds.map((sound) => _buildSoundRow(sound, viewModel, C)),
                        if (viewModel.linkedSounds.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text('Keine Sounds verlinkt', style: TextStyle(color: C.textSoft, fontSize: 13)),
                          ),
                        const SizedBox(height: 10),
                        GestureDetector(
                          onTap: () => _showSoundPicker(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                            decoration: BoxDecoration(
                              color: C.accent.withValues(alpha: 0.12),
                              border: Border.all(color: C.accent.withValues(alpha: 0.3)),
                              borderRadius: BorderRadius.circular(7),
                            ),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Icon(Icons.add, size: 14, color: C.accent),
                              const SizedBox(width: 6),
                              Text('Sounds hinzufügen', style: TextStyle(color: C.accent, fontSize: 13, fontWeight: FontWeight.w500)),
                            ]),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  Consumer<EditSessionViewModel>(
                    builder: (context, viewModel, child) => _buildBottomActions(viewModel, C),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, EditSessionViewModel vm, AppColorsExtension C) {
    final title = widget.session == null ? 'Neue Session' : 'Session bearbeiten';
    final subtitle = vm.session?.title ?? '';
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 52,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(children: [
              _IconBtn(icon: Icons.arrow_back, color: C.textMid, onTap: () => Navigator.of(context).pop()),
              Container(width: 1, height: 18, color: C.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: C.accent.withValues(alpha: 0.15),
                  border: Border.all(color: C.accent.withValues(alpha: 0.35)),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(child: Icon(Icons.event, size: 14, color: C.accent)),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(title, style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13, height: 1.1)),
                  if (subtitle.isNotEmpty)
                    Text(subtitle, style: TextStyle(color: C.textSoft, fontSize: 10, height: 1.1)),
                ],
              ),
              const Spacer(),
              _SaveBtn(canSave: vm.canSave, onSave: _saveSession, C: C),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSoundRow(Sound sound, EditSessionViewModel viewModel, AppColorsExtension C) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: C.bgHover,
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: C.border),
      ),
      child: Row(
        children: [
          Icon(Icons.music_note, color: C.accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sound.name, style: TextStyle(fontWeight: FontWeight.w600, color: C.text, fontSize: 13)),
                if (sound.description.isNotEmpty)
                  Text(sound.description,
                      style: TextStyle(fontSize: 11, color: C.textMid),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          _IconBtn(icon: Icons.play_arrow, color: C.accent, onTap: () => _playSound(sound)),
          _IconBtn(icon: Icons.close, color: C.textMid, onTap: () => viewModel.removeLinkedSound(sound.id)),
        ],
      ),
    );
  }

  Widget _buildBottomActions(EditSessionViewModel viewModel, AppColorsExtension C) {
    if (!viewModel.isEditing) return const SizedBox.shrink();
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _duplicateSession,
                icon: Icon(Icons.copy, size: 16, color: C.textMid),
                label: Text('Duplizieren', style: TextStyle(color: C.textMid)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: C.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _deleteSession(viewModel),
                icon: Icon(Icons.delete_outline, size: 16, color: C.red),
                label: Text('Session löschen', style: TextStyle(color: C.red)),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: C.red.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon, AppColorsExtension C) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: C.textMid, fontSize: 13),
      hintStyle: TextStyle(color: C.textSoft),
      prefixIcon: Icon(icon, color: C.accent, size: 18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: C.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: C.accent),
      ),
      filled: true,
      fillColor: C.bgHover,
    );
  }

  Future<void> _saveSession() async {
    final viewModel = context.read<EditSessionViewModel>();
    if (!_formKey.currentState!.validate()) return;
    final success = await viewModel.saveSession();
    if (success && mounted) {
      SnackBarHelper.showSuccess(context, 'Session erfolgreich gespeichert');
      Navigator.pop(context, true);
    }
  }

  Future<void> _duplicateSession() async {
    final viewModel = context.read<EditSessionViewModel>();
    await viewModel.duplicateSession();
    if (!mounted) return;
    SnackBarHelper.showSuccess(context, 'Session dupliziert');
  }

  Future<void> _deleteSession(EditSessionViewModel viewModel) async {
    final confirmed = await ConfirmationDialog.showDelete(
      context: context,
      title: 'Session löschen',
      message: 'Möchtest du die Session "${viewModel.session?.title}" wirklich löschen?\n\n'
          'Diese Aktion kann nicht rückgängig gemacht werden.',
    );
    if (confirmed != true) return;
    final success = await viewModel.deleteSession();
    if (!mounted) return;
    if (success) {
      SnackBarHelper.showSuccess(context, 'Session erfolgreich gelöscht');
      Navigator.pop(context, true);
    } else {
      SnackBarHelper.showError(context, 'Fehler beim Löschen der Session');
    }
  }

  void _showSoundPicker(BuildContext context) {
    final viewModel = context.read<EditSessionViewModel>();
    final initialSoundIds = viewModel.session?.linkedSoundIds ?? [];
    final C = context.appColors;
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
            onSelectionChanged: (selectedIds) => viewModel.updateLinkedSoundIds(selectedIds),
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
      SnackBarHelper.showError(context, 'Fehler beim Abspielen des Sounds');
    }
  }
}

// ── LOCAL WIDGETS ────────────────────────────────────────────────────────────

class _EditorCard extends StatelessWidget {
  const _EditorCard({required this.title, required this.C, required this.children});
  final String title;
  final AppColorsExtension C;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border.all(color: C.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title.isNotEmpty) ...[
            Text(title.toUpperCase(),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: C.textMid, letterSpacing: 0.4)),
            const SizedBox(height: 12),
          ],
          ...children,
        ],
      ),
    );
  }
}

class _SaveBtn extends StatelessWidget {
  const _SaveBtn({required this.canSave, required this.onSave, required this.C});
  final bool canSave;
  final VoidCallback onSave;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: canSave ? onSave : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: canSave ? C.green : C.bgHover,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.save, size: 13, color: canSave ? Colors.white : C.textSoft),
          const SizedBox(width: 5),
          Text('Speichern',
              style: TextStyle(color: canSave ? Colors.white : C.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.color, required this.onTap});
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(width: 30, height: 30, child: Icon(icon, size: 18, color: color)),
    );
  }
}
