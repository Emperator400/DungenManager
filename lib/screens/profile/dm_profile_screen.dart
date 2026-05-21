import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../theme/app_theme.dart';
import '../../viewmodels/dm_profile_viewmodel.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart' show SnackBarHelper;

class DmProfileScreen extends StatefulWidget {
  const DmProfileScreen({super.key});

  @override
  State<DmProfileScreen> createState() => _DmProfileScreenState();
}

class _DmProfileScreenState extends State<DmProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _systemCtrl;
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _bioCtrl = TextEditingController();
    _systemCtrl = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _bioCtrl.dispose();
    _systemCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final vm = context.read<DmProfileViewModel>();
    await vm.loadProfile();
    if (!mounted) return;
    final p = vm.profile;
    if (p != null) {
      _nameCtrl.text = p.dmName;
      _bioCtrl.text = p.bio ?? '';
      _systemCtrl.text = p.favoriteSystem ?? '';
    }
  }

  void _startEdit() => setState(() => _editing = true);

  void _cancelEdit() {
    final p = context.read<DmProfileViewModel>().profile;
    if (p != null) {
      _nameCtrl.text = p.dmName;
      _bioCtrl.text = p.bio ?? '';
      _systemCtrl.text = p.favoriteSystem ?? '';
    }
    setState(() => _editing = false);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final vm = context.read<DmProfileViewModel>();
    final ok = await vm.saveProfile(
      dmName: _nameCtrl.text.trim(),
      bio: _bioCtrl.text,
      favoriteSystem: _systemCtrl.text,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) _editing = false;
    });
    if (!ok) {
      SnackBarHelper.showError(context, vm.error ?? 'Fehler beim Speichern');
    }
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return;
    final path = result.files.first.path;
    if (path == null) return;
    if (!mounted) return;
    final vm = context.read<DmProfileViewModel>();
    final ok = await vm.updateAvatar(path);
    if (mounted && !ok) {
      SnackBarHelper.showError(context, vm.error ?? 'Fehler beim Speichern des Avatars');
    }
  }

  Future<void> _clearAvatar() async {
    final vm = context.read<DmProfileViewModel>();
    await vm.clearAvatar();
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bgPanel,
        foregroundColor: C.text,
        title: Text('DM-Profil', style: TextStyle(color: C.text, fontWeight: FontWeight.w600)),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: C.border),
        ),
        actions: _buildAppBarActions(C),
      ),
      body: Consumer<DmProfileViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return Center(child: CircularProgressIndicator(color: C.accent));
          }
          if (vm.profile == null) {
            return Center(
              child: Text('Profil konnte nicht geladen werden.', style: TextStyle(color: C.textMid)),
            );
          }
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _AvatarSection(
                  avatarPath: vm.profile!.avatarPath,
                  editing: _editing,
                  onPick: _pickAvatar,
                  onClear: _clearAvatar,
                  C: C,
                ),
                const SizedBox(height: 28),
                _Section(
                  label: 'DM-Name',
                  child: _editing
                      ? TextFormField(
                          controller: _nameCtrl,
                          style: TextStyle(color: C.text),
                          decoration: _inputDeco(C, 'Dein Name oder Alias'),
                          validator: (v) =>
                              v == null || v.trim().isEmpty ? 'Name darf nicht leer sein' : null,
                        )
                      : _ReadonlyValue(
                          value: vm.profile!.dmName.isEmpty ? '— nicht gesetzt —' : vm.profile!.dmName,
                          C: C,
                        ),
                ),
                const SizedBox(height: 20),
                _Section(
                  label: 'Lieblingssystem',
                  child: _editing
                      ? TextFormField(
                          controller: _systemCtrl,
                          style: TextStyle(color: C.text),
                          decoration: _inputDeco(C, 'z.B. D&D 5e, Pathfinder 2e …'),
                        )
                      : _ReadonlyValue(
                          value: vm.profile!.favoriteSystem ?? '— nicht gesetzt —',
                          C: C,
                        ),
                ),
                const SizedBox(height: 20),
                _Section(
                  label: 'Über mich',
                  child: _editing
                      ? TextFormField(
                          controller: _bioCtrl,
                          style: TextStyle(color: C.text),
                          decoration: _inputDeco(C, 'Kurze Bio oder Notizen…'),
                          maxLines: 5,
                        )
                      : _ReadonlyValue(
                          value: vm.profile!.bio ?? '— nicht gesetzt —',
                          C: C,
                          multiLine: true,
                        ),
                ),
                const SizedBox(height: 32),
                if (vm.stats != null) _StatsRow(stats: vm.stats!, C: C),
              ],
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildAppBarActions(AppColorsExtension C) {
    if (_saving) {
      return [
        const Padding(
          padding: EdgeInsets.all(16),
          child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      ];
    }
    if (_editing) {
      return [
        TextButton(
          onPressed: _cancelEdit,
          child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
        ),
        TextButton(
          onPressed: _save,
          child: Text('Speichern', style: TextStyle(color: C.accent, fontWeight: FontWeight.w600)),
        ),
      ];
    }
    return [
      IconButton(
        icon: Icon(Icons.edit_outlined, color: C.textMid),
        tooltip: 'Bearbeiten',
        onPressed: _startEdit,
      ),
    ];
  }

  InputDecoration _inputDeco(AppColorsExtension C, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: C.textSoft),
        filled: true,
        fillColor: C.bgPanel,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
      );
}

// ── AVATAR ────────────────────────────────────────────────────────────────────

class _AvatarSection extends StatelessWidget {
  const _AvatarSection({
    required this.avatarPath,
    required this.editing,
    required this.onPick,
    required this.onClear,
    required this.C,
  });

  final String? avatarPath;
  final bool editing;
  final VoidCallback onPick;
  final VoidCallback onClear;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              _buildCircle(),
              if (editing)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: onPick,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: C.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: C.bg, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 15),
                    ),
                  ),
                ),
            ],
          ),
          if (editing && avatarPath != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onClear,
              child: Text('Bild entfernen', style: TextStyle(color: C.textSoft, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCircle() {
    final hasImage = avatarPath != null && avatarPath!.isNotEmpty;
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: C.bgPanel,
        border: Border.all(color: C.border, width: 2),
        image: hasImage && File(avatarPath!).existsSync()
            ? DecorationImage(image: FileImage(File(avatarPath!)), fit: BoxFit.cover)
            : null,
      ),
      child: hasImage
          ? null
          : Icon(Icons.person, size: 40, color: C.textSoft),
    );
  }
}

// ── STATS ─────────────────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats, required this.C});

  final DmProfileStats stats;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: C.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Stat(label: 'Kampagnen', value: '${stats.campaignCount}', C: C),
          _Divider(C: C),
          _Stat(label: 'Sitzungen', value: '${stats.sessionCount}', C: C),
          _Divider(C: C),
          _Stat(label: 'Charaktere', value: '${stats.characterCount}', C: C),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.C});

  final String label;
  final String value;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Text(
            value,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.text),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: C.textSoft)),
        ],
      );
}

class _Divider extends StatelessWidget {
  const _Divider({required this.C});
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 32, color: C.border);
}

// ── HELPERS ───────────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: C.textMid, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _ReadonlyValue extends StatelessWidget {
  const _ReadonlyValue({required this.value, required this.C, this.multiLine = false});

  final String value;
  final AppColorsExtension C;
  final bool multiLine;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: C.bgPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: C.border),
        ),
        child: Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: value.startsWith('—') ? C.textSoft : C.text,
          ),
          maxLines: multiLine ? null : 1,
        ),
      );
}
