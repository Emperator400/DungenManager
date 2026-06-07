import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../theme/app_theme.dart';
import '../../utils/color_utils.dart';
import '../../viewmodels/campaign_viewmodel.dart';
import '../ui_components/feedback/snackbar_helper.dart';

// ── CONSTANTS ─────────────────────────────────────────────────────────────────

const _kSystems = ['D&D 5e', 'Homebrew', 'Pathfinder', 'Call of Cthulhu', 'Shadowrun'];

const _kAccentColors = [
  '#7c3aed', '#2f6feb', '#1a7f4b', '#b45309',
  '#c93a3a', '#0891b2', '#be185d', '#065f46',
];

const _kStatusCfg = <CampaignStatus, _StatusStyle>{
  CampaignStatus.planning:   _StatusStyle(color: Color(0xFF7C3AED), label: 'Planung'),
  CampaignStatus.active:     _StatusStyle(color: Color(0xFF1A7F4B), label: 'Aktiv'),
  CampaignStatus.paused:     _StatusStyle(color: Color(0xFFB45309), label: 'Pausiert'),
  CampaignStatus.completed:  _StatusStyle(color: Color(0xFF6B6B66), label: 'Abgeschlossen'),
  CampaignStatus.cancelled:  _StatusStyle(color: Color(0xFFC93A3A), label: 'Abgebrochen'),
};

class _StatusStyle {
  const _StatusStyle({required this.color, required this.label});
  final Color color;
  final String label;
}

// ── PUBLIC API ────────────────────────────────────────────────────────────────

abstract final class CampaignEditModal {
  static Future<void> show(
    BuildContext context, {
    Campaign? campaign,
    bool isTemplate = false,
  }) =>
      showDialog<void>(
        context: context,
        barrierColor: Colors.black54,
        builder: (ctx) => ChangeNotifierProvider.value(
          value: context.read<CampaignViewModel>(),
          child: _CampaignEditModal(campaign: campaign, isTemplate: isTemplate),
        ),
      );
}

// ── MODAL ─────────────────────────────────────────────────────────────────────

class _CampaignEditModal extends StatefulWidget {
  const _CampaignEditModal({this.campaign, this.isTemplate = false});
  final Campaign? campaign;
  final bool isTemplate;

  @override
  State<_CampaignEditModal> createState() => _CampaignEditModalState();
}

class _CampaignEditModalState extends State<_CampaignEditModal> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late CampaignStatus _status;
  late String _system;
  late String _accentColor;
  String? _coverImagePath;
  late bool _syncEnabled;
  Campaign? _templateSource;

  bool get _isNew => widget.campaign == null;

  @override
  void initState() {
    super.initState();
    _nameCtrl        = TextEditingController(text: widget.campaign?.title ?? '');
    _descCtrl        = TextEditingController(text: widget.campaign?.description ?? '');
    _status          = widget.campaign?.status ?? CampaignStatus.planning;
    _system          = widget.campaign?.system ?? 'D&D 5e';
    _accentColor     = widget.campaign?.accentColor ?? '#7c3aed';
    _coverImagePath  = widget.campaign?.coverImagePath;
    _syncEnabled     = widget.campaign?.syncEnabled ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty;

  Color get _color => ColorUtils.fromHex(_accentColor) ?? const Color(0xFF7C3AED);

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Container(
            color: C.bgPanel,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(C),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        if (_isNew && !widget.isTemplate) ...[
                          _buildTemplateSection(C),
                          const SizedBox(height: 14),
                        ],
                        _buildNameField(C),
                        const SizedBox(height: 14),
                        _buildDescField(C),
                        if (_templateSource == null) ...[
                          const SizedBox(height: 14),
                          _buildSystemStatusRow(C),
                          const SizedBox(height: 14),
                          _buildColorPicker(C),
                          const SizedBox(height: 14),
                          _buildImagePicker(C),
                          const SizedBox(height: 14),
                          _buildSyncToggle(C),
                        ],
                        const SizedBox(height: 14),
                        _buildPreview(C),
                        if (!_isNew) ...[
                          const SizedBox(height: 14),
                          _buildStats(C),
                        ],
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                _buildFooter(C),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── HEADER ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(AppColorsExtension C) => Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Row(
        children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _color.withValues(alpha: 0.3)),
            ),
            child: Icon(Icons.auto_stories, size: 14, color: _color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isNew
                      ? (_templateSource != null
                          ? 'Aus Vorlage erstellen'
                          : widget.isTemplate
                              ? 'Neue Vorlage'
                              : 'Neue Kampagne')
                      : 'Kampagne bearbeiten',
                  style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600, color: C.text,
                  ),
                ),
                if (!_isNew)
                  Text(
                    widget.campaign!.title,
                    style: TextStyle(fontSize: 11, color: C.textSoft),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: C.textMid),
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
            ),
          ),
        ],
      ),
    );

  // ── FIELDS ─────────────────────────────────────────────────────────────────

  Widget _buildTemplateSection(AppColorsExtension C) {
    final templates = context.read<CampaignViewModel>().templates;
    if (templates.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('Von Vorlage starten', C),
        const SizedBox(height: 5),
        DecoratedBox(
          decoration: BoxDecoration(
            color: C.bgHover,
            borderRadius: BorderRadius.circular(7),
            border: Border.all(color: C.border),
          ),
          child: DropdownButton<Campaign?>(
            value: _templateSource,
            isExpanded: true,
            underline: const SizedBox.shrink(),
            dropdownColor: C.bgPanel,
            style: TextStyle(fontSize: 13, color: C.text),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            items: [
              DropdownMenuItem<Campaign?>(
                child: Text(
                  'Keine (leere Kampagne)',
                  style: TextStyle(color: C.textSoft, fontSize: 13),
                ),
              ),
              ...templates.map(
                (t) => DropdownMenuItem<Campaign?>(
                  value: t,
                  child: Text(t.title, style: TextStyle(color: C.text, fontSize: 13)),
                ),
              ),
            ],
            onChanged: (t) {
              setState(() {
                _templateSource = t;
                if (t != null) {
                  _nameCtrl.text = '${t.title} — Gruppe 1';
                  _accentColor = t.accentColor;
                  _system = t.system;
                }
              });
            },
          ),
        ),
        if (_templateSource != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                Icon(Icons.copy_outlined, size: 12, color: C.accent),
                const SizedBox(width: 4),
                Text(
                  'Alle Inhalte der Vorlage werden übernommen.',
                  style: TextStyle(fontSize: 11, color: C.textMid),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildNameField(AppColorsExtension C) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('Name *', C),
          const SizedBox(height: 5),
          TextField(
            controller: _nameCtrl,
            style: TextStyle(fontSize: 13, color: C.text),
            decoration: _inputDeco(C, 'Kampagnen-Name'),
            onChanged: (_) => setState(() {}),
          ),
        ],
      );

  Widget _buildDescField(AppColorsExtension C) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('Beschreibung', C),
          const SizedBox(height: 5),
          TextField(
            controller: _descCtrl,
            style: TextStyle(fontSize: 13, color: C.text),
            decoration: _inputDeco(C, 'Kurze Beschreibung der Kampagne...'),
            maxLines: 3,
          ),
        ],
      );

  Widget _buildSystemStatusRow(AppColorsExtension C) => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('System', C),
                const SizedBox(height: 5),
                _Dropdown<String>(
                  value: _system,
                  items: _kSystems,
                  label: (s) => s,
                  C: C,
                  onChanged: (v) => setState(() => _system = v),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('Status', C),
                const SizedBox(height: 5),
                _Dropdown<CampaignStatus>(
                  value: _status,
                  items: CampaignStatus.values,
                  label: (s) => _kStatusCfg[s]?.label ?? s.name,
                  C: C,
                  onChanged: (v) => setState(() => _status = v),
                ),
              ],
            ),
          ),
        ],
      );

  Widget _buildColorPicker(AppColorsExtension C) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label('Farbe', C),
          const SizedBox(height: 8),
          Row(
            children: _kAccentColors.map((hex) {
              final selected = _accentColor == hex;
              final col = ColorUtils.fromHex(hex)!;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _accentColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    width: 30, height: 30,
                    decoration: BoxDecoration(
                      color: col,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: selected ? C.text : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: selected
                          ? [BoxShadow(color: col.withValues(alpha: 0.4), blurRadius: 6)]
                          : null,
                    ),
                    child: selected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );

  Widget _buildImagePicker(AppColorsExtension C) {
    final hasImage = _coverImagePath != null && File(_coverImagePath!).existsSync();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('Titelbild', C),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickCoverImage,
          child: Container(
            height: 80,
            decoration: BoxDecoration(
              color: C.bgHover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: C.border),
            ),
            child: hasImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(_coverImagePath!), fit: BoxFit.cover),
                        Positioned(
                          top: 6, right: 6,
                          child: GestureDetector(
                            onTap: () => setState(() => _coverImagePath = null),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.close, size: 12, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, size: 20, color: C.textSoft),
                      const SizedBox(width: 8),
                      Text(
                        'Bild auswählen',
                        style: TextStyle(fontSize: 13, color: C.textSoft),
                      ),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncToggle(AppColorsExtension C) => Row(
        children: [
          Icon(
            _syncEnabled ? Icons.cloud_outlined : Icons.cloud_off_outlined,
            size: 16,
            color: _syncEnabled ? C.textMid : C.textSoft.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cloud-Sync',
                  style: TextStyle(fontSize: 13, color: C.text),
                ),
                Text(
                  _syncEnabled
                      ? 'Wird bei der Synchronisierung hochgeladen'
                      : 'Wird nicht hochgeladen',
                  style: TextStyle(fontSize: 11, color: C.textSoft),
                ),
              ],
            ),
          ),
          Switch(
            value: _syncEnabled,
            onChanged: (v) => setState(() => _syncEnabled = v),
            activeThumbColor: C.accent,
          ),
        ],
      );

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );
    if (result != null && result.files.single.path != null) {
      setState(() => _coverImagePath = result.files.single.path);
    }
  }

  Widget _buildPreview(AppColorsExtension C) {
    final title = _nameCtrl.text.trim();
    final statusStyle = _kStatusCfg[_status]!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: C.bgHover,
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'VORSCHAU',
            style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w500,
              color: C.textSoft, letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: _color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: _color.withValues(alpha: 0.3)),
                ),
                child: Center(
                  child: Text(
                    title.isNotEmpty ? title[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700, color: _color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isNotEmpty ? title : 'Kampagnen-Name',
                      style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: C.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(_system, style: TextStyle(fontSize: 11, color: C.textSoft)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Text('·', style: TextStyle(color: C.border)),
                        ),
                        _StatusBadge(style: statusStyle),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats(AppColorsExtension C) {
    final stats = context.read<CampaignViewModel>().getStatsForCampaign(widget.campaign!.id);
    final items = [
      (Icons.person_outline, 'Spieler', '${stats['heroCount'] ?? 0}'),
      (Icons.play_circle_outline, 'Sessions', '${stats['sessionCount'] ?? 0}'),
    ];
    return Row(
      children: items.expand((item) => [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: C.bgHover,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: C.border),
            ),
            child: Row(
              children: [
                Icon(item.$1, size: 13, color: C.textSoft),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.$2, style: TextStyle(fontSize: 10, color: C.textSoft)),
                    Text(
                      item.$3,
                      style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: C.text,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (item != items.last) const SizedBox(width: 8),
      ]).toList(),
    );
  }

  // ── FOOTER ─────────────────────────────────────────────────────────────────

  Widget _buildFooter(AppColorsExtension C) => Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: C.border)),
      ),
      child: Row(
        children: [
          if (!_isNew)
            OutlinedButton.icon(
              onPressed: _duplicate,
              icon: const Icon(Icons.copy, size: 13),
              label: const Text('Duplizieren', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                foregroundColor: C.red,
                side: BorderSide(color: C.border),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ),
            ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: C.textMid,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            ),
            child: const Text('Abbrechen', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Consumer<CampaignViewModel>(
            builder: (context, vm, _) => FilledButton.icon(
              onPressed: (_canSave && !vm.isLoading) ? _save : null,
              icon: vm.isLoading
                  ? const SizedBox(
                      width: 14, height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.save, size: 14),
              label: Text(_isNew ? 'Erstellen' : 'Speichern',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: C.accent,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ),
            ),
          ),
        ],
      ),
    );

  // ── ACTIONS ────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    final vm = context.read<CampaignViewModel>();
    final title = _nameCtrl.text.trim();
    final desc  = _descCtrl.text.trim();

    if (_isNew) {
      if (_templateSource != null) {
        await vm.createCopyFromTemplate(_templateSource!, title: title);
      } else if (widget.isTemplate) {
        await vm.createTemplate(
          title: title,
          description: desc,
          accentColor: _accentColor,
          system: _system,
        );
      } else {
        await vm.createCampaign(
          title: title,
          description: desc,
          accentColor: _accentColor,
          system: _system,
          status: _status,
          coverImagePath: _coverImagePath,
        );
      }
    } else {
      await vm.updateCampaign(
        widget.campaign!.copyWith(
          title: title,
          description: desc,
          accentColor: _accentColor,
          system: _system,
          status: _status,
          updatedAt: DateTime.now(),
          coverImagePath: _coverImagePath,
          syncEnabled: _syncEnabled,
        ),
      );
    }
    if (!mounted) {
      return;
    }
    if (vm.error == null) {
      Navigator.of(context).pop();
    } else {
      SnackBarHelper.showError(context, vm.error!);
    }
  }

  Future<void> _duplicate() async {
    if (widget.campaign == null) {
      return;
    }
    final vm = context.read<CampaignViewModel>();
    await vm.duplicateCampaign(widget.campaign!);
    if (!mounted) {
      return;
    }
    Navigator.of(context).pop();
    if (vm.error == null) {
      SnackBarHelper.showSuccess(context, 'Kampagne dupliziert');
    }
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  InputDecoration _inputDeco(AppColorsExtension C, String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: C.textSoft, fontSize: 13),
        filled: true,
        fillColor: C.bgHover,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
          borderSide: BorderSide(color: C.accent, width: 1.5),
        ),
      );
}

// ── REUSABLE HELPERS ──────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  const _Label(this.text, this.C);
  final String text;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11, fontWeight: FontWeight.w500,
          color: C.textSoft, letterSpacing: 0.4,
        ),
      );
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.value,
    required this.items,
    required this.label,
    required this.C,
    required this.onChanged,
  });
  final T value;
  final List<T> items;
  final String Function(T) label;
  final AppColorsExtension C;
  final void Function(T) onChanged;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: C.bgHover,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: C.border),
        ),
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          dropdownColor: C.bgPanel,
          style: TextStyle(fontSize: 13, color: C.text),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          items: items.map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(label(item), style: TextStyle(color: C.text, fontSize: 13)),
            ),
          ).toList(),
          onChanged: (v) {
            if (v != null) {
              onChanged(v);
            }
          },
        ),
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.style});
  final _StatusStyle style;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: style.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5, height: 5,
              decoration: BoxDecoration(
                color: style.color, shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              style.label,
              style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w500, color: style.color,
              ),
            ),
          ],
        ),
      );
}
