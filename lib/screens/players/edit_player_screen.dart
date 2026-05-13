import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/player.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/player_viewmodel.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart' show SnackBarHelper;

// D&D-Farbvorschläge für Spieler
const List<Color> _kSwatches = [
  Color(0xFF2F6FEB),
  Color(0xFF1A7F4B),
  Color(0xFF7C3AED),
  Color(0xFFB45309),
  Color(0xFFC93A3A),
  Color(0xFF0891B2),
  Color(0xFFBE185D),
  Color(0xFF065F46),
  Color(0xFF6B6B66),
  Color(0xFF92400E),
];

String _colorToHex(Color c) {
  final hex = c.toARGB32().toRadixString(16).padLeft(8, '0');
  return '#${hex.substring(2)}';
}

Color _hexToColor(String hex) {
  try {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return _kSwatches.first;
  }
}

class EditPlayerScreen extends StatefulWidget {
  final Player? player;
  const EditPlayerScreen({super.key, this.player});

  @override
  State<EditPlayerScreen> createState() => _EditPlayerScreenState();
}

class _EditPlayerScreenState extends State<EditPlayerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _notesCtrl;
  late Color _selectedColor;
  bool _saving = false;

  bool get _isEdit => widget.player != null;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.player?.name ?? '');
    _notesCtrl = TextEditingController(text: widget.player?.notes ?? '');
    _selectedColor = widget.player != null
        ? _hexToColor(widget.player!.color)
        : _kSwatches.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final vm = context.read<PlayerViewModel>();
    final bool ok;
    if (_isEdit) {
      final updated = widget.player!.copyWith(
        name: _nameCtrl.text.trim(),
        color: _colorToHex(_selectedColor),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        updatedAt: DateTime.now(),
      );
      ok = await vm.updatePlayer(updated);
    } else {
      final player = Player.create(
        name: _nameCtrl.text.trim(),
        color: _colorToHex(_selectedColor),
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      );
      ok = await vm.createPlayer(player);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      SnackBarHelper.showError(context, vm.error ?? 'Fehler beim Speichern');
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bgPanel,
        foregroundColor: C.text,
        title: Text(
          _isEdit ? 'Spieler bearbeiten' : 'Neuer Spieler',
          style: TextStyle(color: C.text, fontWeight: FontWeight.w600),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: C.border),
        ),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text('Speichern', style: TextStyle(color: C.accent, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _Section(label: 'Name', child: TextFormField(
              controller: _nameCtrl,
              style: TextStyle(color: C.text),
              decoration: _inputDecoration(C, 'Name des Spielers'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name darf nicht leer sein' : null,
            )),
            const SizedBox(height: 20),
            _Section(
              label: 'Farbe',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _kSwatches.map((color) {
                  final selected = _selectedColor.toARGB32() == color.toARGB32();
                  return GestureDetector(
                    onTap: () => setState(() => _selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: selected
                            ? Border.all(color: C.text, width: 3)
                            : Border.all(color: C.border),
                      ),
                      child: selected
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),
            _Section(
              label: 'Notizen (optional)',
              child: TextFormField(
                controller: _notesCtrl,
                style: TextStyle(color: C.text),
                decoration: _inputDecoration(C, 'z.B. bevorzugter Spielstil...'),
                maxLines: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(AppColorsExtension C, String hint) =>
      InputDecoration(
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
        Text(label, style: TextStyle(color: C.textMid, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
