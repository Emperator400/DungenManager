import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/sound.dart';
import '../../theme/app_colors_map.dart';
import '../../theme/app_theme.dart';
import '../../theme/theme_notifier.dart';
import '../../viewmodels/edit_sound_viewmodel.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/shared/app_icon.dart';

// ── KATEGORIE FARB-KONFIGURATION ─────────────────────────────────────────────

const _katCfg = <SoundType, TypeColorConfig>{
  SoundType.Ambiente: TypeColorConfig(
    color:   Color(0xFF0891B2),
    bgLight: Color(0xFFECFBFF),
    bgDark:  Color(0xFF0A1F28),
    dot:     Color(0xFF0891B2),
  ),
  SoundType.Effekt: TypeColorConfig(
    color:   Color(0xFFC93A3A),
    bgLight: Color(0xFFFDF0F0),
    bgDark:  Color(0xFF2A1212),
    dot:     Color(0xFFC93A3A),
  ),
};

TypeColorConfig _cfg(SoundType t) =>
    _katCfg[t] ?? _katCfg[SoundType.Ambiente]!;

// ── SCREEN ────────────────────────────────────────────────────────────────────

class EditSoundScreen extends StatefulWidget {
  const EditSoundScreen({super.key, this.sound});

  final Sound? sound;

  @override
  State<EditSoundScreen> createState() => _EditSoundScreenState();
}

class _EditSoundScreenState extends State<EditSoundScreen> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _filePathCtrl;
  late final TextEditingController _descCtrl;
  final TextEditingController _tagCtrl = TextEditingController();

  late SoundType _type;
  late List<String> _tags;
  bool _saving = false;

  bool get _isNew => widget.sound == null;

  @override
  void initState() {
    super.initState();
    final s = widget.sound;
    _nameCtrl    = TextEditingController(text: s?.name ?? '');
    _filePathCtrl = TextEditingController(text: s?.filePath ?? '');
    _descCtrl    = TextEditingController(text: s?.description ?? '');
    _type        = s?.soundType ?? SoundType.Ambiente;
    _tags        = List<String>.from(s?.tagList ?? []);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _filePathCtrl.dispose();
    _descCtrl.dispose();
    _tagCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'wav', 'ogg', 'flac', 'm4a', 'aac'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.single.path;
      if (path != null) {
        setState(() => _filePathCtrl.text = path);
        // Auto-fill name from filename if still empty
        if (_nameCtrl.text.trim().isEmpty) {
          final filename = path.split(RegExp(r'[/\\]')).last;
          final nameWithoutExt = filename.contains('.')
              ? filename.substring(0, filename.lastIndexOf('.'))
              : filename;
          setState(() => _nameCtrl.text = nameWithoutExt);
        }
      }
    }
  }

  Widget _buildFilePickerRow(AppColorsExtension C) {
    final hasFile = _filePathCtrl.text.isNotEmpty;
    final label = hasFile
        ? _filePathCtrl.text.split(RegExp(r'[/\\]')).last
        : (_isNew ? 'Datei auswählen...' : 'Keine Datei');
    final buttonLabel = _isNew ? 'Durchsuchen' : 'Ändern';

    return GestureDetector(
      onTap: _pickFile,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: C.bgPanel,
          border: Border.all(color: hasFile ? C.accent : C.border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            AppIcon(AppIconName.file, size: 13,
                color: hasFile ? C.accent : C.textSoft),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: hasFile ? C.text : C.textSoft,
                  overflow: TextOverflow.ellipsis,
                ),
                maxLines: 1,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: C.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Text(
                buttonLabel,
                style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w500, color: C.accent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTag() {
    final tag = _tagCtrl.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagCtrl.clear();
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      SnackBarHelper.showError(context, 'Name darf nicht leer sein');
      return;
    }
    if (_filePathCtrl.text.trim().isEmpty && _isNew) {
      SnackBarHelper.showError(context, 'Dateipfad ist erforderlich');
      return;
    }

    setState(() => _saving = true);
    try {
      final vm = context.read<EditSoundViewModel>();
      vm.updateName(_nameCtrl.text.trim());
      vm.updateFilePath(_filePathCtrl.text.trim());
      vm.updateDescription(_descCtrl.text.trim());
      vm.updateSoundType(_type);
      vm.updateTags(_tags.isEmpty ? null : _tags.join(','));

      final ok = await vm.saveSound();
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
      } else if (vm.errorMessage != null) {
        SnackBarHelper.showError(context, vm.errorMessage!);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _duplicate() async {
    final vm = context.read<EditSoundViewModel>();
    await vm.duplicateSound();
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final C       = context.appColors;
    final isDark  = context.watch<ThemeNotifier>().isDark;
    final typeCfg = _cfg(_type);

    return Stack(
      children: [
        // Dimmed backdrop — tap closes the panel
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: SizedBox.expand(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.35),
            ),
          ),
        ),

        // Side panel
        Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: C.bgPanel,
            child: Container(
              width: 420,
              constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.9),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: C.border)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                    blurRadius: 32,
                    offset: const Offset(-8, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(C, isDark, typeCfg),
                  Expanded(child: _buildBody(C, isDark, typeCfg)),
                  _buildFooter(C),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── HEADER ────────────────────────────────────────────────────────────────

  Widget _buildHeader(
      AppColorsExtension C, bool isDark, TypeColorConfig typeCfg) {
    return SafeArea(
      bottom: false,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: C.border))),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: typeCfg.color.withValues(alpha: 0.12),
                border: Border.all(
                    color: typeCfg.color.withValues(alpha: 0.27)),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: AppIcon(AppIconName.music,
                    size: 14, color: typeCfg.color),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _isNew ? 'Neuer Sound' : 'Sound bearbeiten',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: C.text),
                  ),
                  if (!_isNew)
                    Text(
                      widget.sound!.name,
                      style:
                          TextStyle(fontSize: 11, color: C.textSoft),
                    ),
                ],
              ),
            ),
            _SmallIconBtn(
                icon: AppIconName.close,
                C: C,
                onTap: () => Navigator.of(context).pop()),
          ],
        ),
      ),
    );
  }

  // ── BODY ──────────────────────────────────────────────────────────────────

  Widget _buildBody(
      AppColorsExtension C, bool isDark, TypeColorConfig typeCfg) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGrundinformationen(C, isDark),
          const SizedBox(height: 12),
          _buildDateiSection(C),
          const SizedBox(height: 12),
          _buildSoundDetails(C),
        ],
      ),
    );
  }

  Widget _buildGrundinformationen(AppColorsExtension C, bool isDark) {
    return _Section(C: C, children: [
      _SectionTitle('Grundinformationen', C),
      _FieldLabel('Name *', C),
      _InputField(ctrl: _nameCtrl, hint: 'Sound-Name', C: C),
      const SizedBox(height: 12),
      _FieldLabel('Sound-Typ', C),
      Row(
        children: SoundType.values.map((t) {
          final cfg   = _cfg(t);
          final aktiv = _type == t;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  right: t != SoundType.values.last ? 6 : 0),
              child: GestureDetector(
                onTap: () => setState(() => _type = t),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: aktiv
                        ? (isDark ? cfg.bgDark : cfg.bgLight)
                        : Colors.transparent,
                    border: Border.all(
                        color: aktiv ? cfg.dot : C.border),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                            color: cfg.dot, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        t.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: aktiv
                              ? FontWeight.w500
                              : FontWeight.w400,
                          color: aktiv ? cfg.color : C.textMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    ]);
  }

  Widget _buildDateiSection(AppColorsExtension C) {
    final sound = widget.sound;
    return _Section(C: C, children: [
      _SectionTitle('Datei', C),
      _FieldLabel('Dateipfad', C),
      _buildFilePickerRow(C),
      if (_filePathCtrl.text.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(
          _filePathCtrl.text,
          style: TextStyle(fontSize: 10, color: C.textSoft),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
      if (!_isNew && sound != null) ...[
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
                child: _InfoChip(
                    icon: Icons.access_time,
                    label: 'Dauer',
                    value: sound.formattedDuration,
                    C: C)),
            const SizedBox(width: 8),
            Expanded(
                child: _InfoChip(
                    icon: Icons.storage,
                    label: 'Größe',
                    value: sound.formattedFileSize,
                    C: C)),
          ],
        ),
      ],
    ]);
  }

  Widget _buildSoundDetails(AppColorsExtension C) {
    return _Section(C: C, children: [
      _SectionTitle('Sound-Details', C),
      _FieldLabel('Beschreibung', C),
      _TextAreaField(
          ctrl: _descCtrl,
          hint: 'Beschreibung des Sounds...',
          C: C),
      const SizedBox(height: 12),
      _FieldLabel('Tags', C),
      if (_tags.isNotEmpty)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Wrap(
            spacing: 5,
            runSpacing: 5,
            children: _tags
                .map((t) => _RemovableTag(
                      label: t,
                      C: C,
                      onRemove: () => setState(() => _tags.remove(t)),
                    ))
                .toList(),
          ),
        ),
      Row(
        children: [
          Expanded(
            child: _InputField(
              ctrl: _tagCtrl,
              hint: 'Tag hinzufügen...',
              C: C,
              onSubmitted: (_) => _addTag(),
            ),
          ),
          const SizedBox(width: 6),
          _SmallIconBtn(icon: AppIconName.plus, C: C, onTap: _addTag),
        ],
      ),
    ]);
  }

  // ── FOOTER ────────────────────────────────────────────────────────────────

  Widget _buildFooter(AppColorsExtension C) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration:
          BoxDecoration(border: Border(top: BorderSide(color: C.border))),
      child: Row(
        children: [
          if (!_isNew) ...[
            OutlinedButton.icon(
              onPressed: _saving ? null : _duplicate,
              icon: AppIcon(AppIconName.copy, size: 12, color: C.textMid),
              label: Text('Duplizieren',
                  style: TextStyle(fontSize: 12, color: C.textMid)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: C.border),
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: C.border),
                foregroundColor: C.textMid,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
              ),
              child: const Text('Abbrechen',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      width: 13,
                      height: 13,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : AppIcon(AppIconName.save, size: 13,
                      color: Colors.white),
              label: Text(
                _isNew ? 'Erstellen' : 'Speichern',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: C.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(7)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── SHARED SMALL WIDGETS ──────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  const _Section({required this.C, required this.children});

  final AppColorsExtension C;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: C.bgHover,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children),
      );
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label, this.C);

  final String label;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: C.textSoft,
              letterSpacing: 0.5),
        ),
      );
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label, this.C);

  final String label;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Text(
          label.toUpperCase(),
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: C.textSoft,
              letterSpacing: 0.4),
        ),
      );
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.ctrl,
    required this.hint,
    required this.C,
    this.onSubmitted,
  });

  final TextEditingController ctrl;
  final String hint;
  final AppColorsExtension C;
  final void Function(String)? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        style: TextStyle(fontSize: 13, color: C.text),
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: C.textSoft),
          filled: true,
          fillColor: C.bgHover,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: C.accent),
          ),
        ),
      );
}

class _TextAreaField extends StatelessWidget {
  const _TextAreaField(
      {required this.ctrl, required this.hint, required this.C});

  final TextEditingController ctrl;
  final String hint;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => TextField(
        controller: ctrl,
        minLines: 3,
        maxLines: 5,
        style: TextStyle(fontSize: 13, color: C.text),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(fontSize: 13, color: C.textSoft),
          filled: true,
          fillColor: C.bgHover,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: C.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: C.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(7),
            borderSide: BorderSide(color: C.accent),
          ),
        ),
      );
}

class _RemovableTag extends StatelessWidget {
  const _RemovableTag(
      {required this.label, required this.C, required this.onRemove});

  final String label;
  final AppColorsExtension C;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.only(left: 8, top: 3, bottom: 3, right: 4),
        decoration: BoxDecoration(
          color: C.bgPanel,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(fontSize: 11, color: C.textMid)),
            const SizedBox(width: 3),
            GestureDetector(
              onTap: onRemove,
              child: Icon(Icons.close, size: 13, color: C.textSoft),
            ),
          ],
        ),
      );
}

class _InfoChip extends StatelessWidget {
  const _InfoChip(
      {required this.icon,
      required this.label,
      required this.value,
      required this.C});

  final IconData icon;
  final String label;
  final String value;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: C.bgPanel,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Row(
          children: [
            Icon(icon, size: 12, color: C.textSoft),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 9,
                        color: C.textSoft,
                        letterSpacing: 0.3)),
                Text(value,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: C.text)),
              ],
            ),
          ],
        ),
      );
}

class _SmallIconBtn extends StatefulWidget {
  const _SmallIconBtn(
      {required this.icon, required this.C, required this.onTap});

  final AppIconName icon;
  final AppColorsExtension C;
  final VoidCallback onTap;

  @override
  State<_SmallIconBtn> createState() => _SmallIconBtnState();
}

class _SmallIconBtnState extends State<_SmallIconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: _hovered ? widget.C.bgHover : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: AppIcon(widget.icon,
                  size: 14, color: widget.C.textMid),
            ),
          ),
        ),
      );
}
