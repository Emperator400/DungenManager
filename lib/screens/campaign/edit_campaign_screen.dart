import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/campaign_viewmodel.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';

class EditCampaignScreen extends StatefulWidget {
  const EditCampaignScreen({super.key, this.campaign});

  final Campaign? campaign;

  @override
  State<EditCampaignScreen> createState() => _EditCampaignScreenState();
}

class _EditCampaignScreenState extends State<EditCampaignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  late CampaignStatus _status;
  late CampaignType _type;
  String? _dungeonMasterId;
  late CampaignSettings _settings;

  @override
  void initState() {
    super.initState();
    _status = widget.campaign?.status ?? CampaignStatus.planning;
    _type = widget.campaign?.type ?? CampaignType.homebrew;
    _dungeonMasterId = widget.campaign?.dungeonMasterId;
    _settings = widget.campaign?.settings ?? const CampaignSettings();
    if (widget.campaign != null) {
      _titleController.text = widget.campaign!.title;
      _descriptionController.text = widget.campaign!.description;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _titleController.text.trim().isNotEmpty &&
      _descriptionController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(52),
        child: Consumer<CampaignViewModel>(
          builder: (context, vm, _) => Container(
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
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: C.amber.withValues(alpha: 0.18),
                        border: Border.all(color: C.amber.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(child: Icon(Icons.campaign, size: 14, color: C.amber)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.campaign == null ? 'Neue Kampagne' : 'Kampagne bearbeiten',
                      style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _canSave && !vm.isLoading ? _saveCampaign : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                        decoration: BoxDecoration(
                          color: _canSave && !vm.isLoading ? C.green : C.bgHover,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: vm.isLoading
                            ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: C.text, strokeWidth: 2))
                            : Row(mainAxisSize: MainAxisSize.min, children: [
                                Icon(Icons.save, size: 13, color: _canSave ? Colors.white : C.textSoft),
                                const SizedBox(width: 5),
                                Text('Speichern', style: TextStyle(color: _canSave ? Colors.white : C.textSoft, fontSize: 12, fontWeight: FontWeight.w600)),
                              ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Consumer<CampaignViewModel>(
        builder: (context, viewModel, child) => Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (viewModel.error != null)
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
                          child: Text(viewModel.error!, style: TextStyle(color: C.red)),
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
                        controller: _titleController,
                        decoration: _buildInputDecoration('Titel', Icons.title),
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Titel ist erforderlich' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: _buildInputDecoration('Beschreibung', Icons.description),
                        maxLines: 4,
                        validator: (value) =>
                            (value == null || value.trim().isEmpty) ? 'Beschreibung ist erforderlich' : null,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: _buildStatusDropdown()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTypeDropdown()),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Kampagnen-Einstellungen',
                  icon: Icons.settings,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildSettingsField(
                              label: 'Start-Level',
                              icon: Icons.trending_up,
                              value: _settings.startingLevel,
                              min: 1,
                              max: 20,
                              onChanged: (v) =>
                                  setState(() => _settings = _settings.copyWith(startingLevel: v)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSettingsField(
                              label: 'Max-Level',
                              icon: Icons.trending_up,
                              value: _settings.maxPlayerLevel,
                              min: 1,
                              max: 20,
                              onChanged: (v) =>
                                  setState(() => _settings = _settings.copyWith(maxPlayerLevel: v)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        initialValue: _settings.partySize,
                        decoration: _buildInputDecoration('Party-Größe', Icons.group),
                        onChanged: (v) =>
                            setState(() => _settings = _settings.copyWith(partySize: v)),
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Benutzerdefinierte Inhalte zulassen'),
                        subtitle: const Text('Spieler können eigene Inhalte erstellen'),
                        value: _settings.allowCustomContent,
                        activeColor: context.appColors.amber,
                        onChanged: (v) =>
                            setState(() => _settings = _settings.copyWith(allowCustomContent: v)),
                      ),
                      SwitchListTile(
                        title: const Text('Öffentlich'),
                        subtitle: const Text('Kampagne für andere sichtbar'),
                        value: _settings.isPublic,
                        activeColor: context.appColors.amber,
                        onChanged: (v) =>
                            setState(() => _settings = _settings.copyWith(isPublic: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionCard(
                  title: 'Zusätzliche Informationen',
                  icon: Icons.info,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.group, color: C.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Spieler: ${widget.campaign?.playerCount ?? 0}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          if ((widget.campaign?.playerCount ?? 0) > 0)
                            TextButton.icon(
                              onPressed: _showPlayerDialog,
                              icon: const Icon(Icons.edit, size: 16),
                              label: const Text('Spieler verwalten'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.event, color: C.amber),
                          const SizedBox(width: 8),
                          Text(
                            'Sessions: ${widget.campaign?.sessionCount ?? 0}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          if ((widget.campaign?.sessionCount ?? 0) > 0)
                            TextButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.chevron_right, size: 16),
                              label: const Text('Anzeigen'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _buildActionButtons(viewModel),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final C = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: C.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: C.amber, size: 22),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: C.text),
                ),
              ],
            ),
            const SizedBox(height: 20),
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
      labelStyle: TextStyle(color: C.textMid),
      prefixIcon: Icon(icon, color: C.amber),
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
        borderSide: BorderSide(color: C.amber),
      ),
      filled: true,
      fillColor: C.bgHover,
      hintStyle: TextStyle(color: C.textSoft),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<CampaignStatus>(
      value: _status,
      decoration: _buildInputDecoration('Status', Icons.flag),
      items: CampaignStatus.values.map((status) {
        final isSelected = _status == status;
        return DropdownMenuItem(
          value: status,
          child: Row(
            children: [
              Icon(_getStatusIcon(status), size: 18),
              const SizedBox(width: 8),
              Text(
                _getLocalizedStatus(status),
                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _status = v);
      },
    );
  }

  Widget _buildTypeDropdown() {
    return DropdownButtonFormField<CampaignType>(
      value: _type,
      decoration: _buildInputDecoration('Typ', Icons.category),
      items: CampaignType.values.map((type) {
        final isSelected = _type == type;
        return DropdownMenuItem(
          value: type,
          child: Row(
            children: [
              Icon(_getTypeIcon(type), size: 18),
              const SizedBox(width: 8),
              Text(
                _getLocalizedType(type),
                style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (v) {
        if (v != null) setState(() => _type = v);
      },
    );
  }

  Widget _buildSettingsField({
    required String label,
    required IconData icon,
    required int value,
    required int min,
    required int max,
    required void Function(int) onChanged,
  }) {
    final C = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: C.textMid, fontSize: 12)),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: C.amber,
                  inactiveTrackColor: C.border,
                  thumbColor: C.amber,
                  trackHeight: 4,
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max - min,
                  label: value.toString(),
                  onChanged: (v) => onChanged(v.toInt()),
                ),
              ),
            ),
            SizedBox(
              width: 40,
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: TextStyle(color: C.text, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(CampaignViewModel viewModel) {
    if (widget.campaign == null) return const SizedBox.shrink();
    final C = context.appColors;
    return OutlinedButton.icon(
      onPressed: _duplicateCampaign,
      icon: Icon(Icons.copy, size: 16, color: C.textMid),
      label: Text('Kampagne duplizieren', style: TextStyle(color: C.textMid)),
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: C.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  IconData _getStatusIcon(CampaignStatus status) => switch (status) {
        CampaignStatus.planning => Icons.edit_note,
        CampaignStatus.active => Icons.play_circle,
        CampaignStatus.paused => Icons.pause_circle,
        CampaignStatus.completed => Icons.check_circle,
        CampaignStatus.cancelled => Icons.cancel,
      };

  IconData _getTypeIcon(CampaignType type) => switch (type) {
        CampaignType.homebrew => Icons.home,
        CampaignType.module => Icons.book,
        CampaignType.adventurePath => Icons.map,
        CampaignType.oneShot => Icons.flash_on,
      };

  String _getLocalizedStatus(CampaignStatus status) => switch (status) {
        CampaignStatus.planning => 'Planung',
        CampaignStatus.active => 'Aktiv',
        CampaignStatus.paused => 'Pausiert',
        CampaignStatus.completed => 'Abgeschlossen',
        CampaignStatus.cancelled => 'Abgebrochen',
      };

  String _getLocalizedType(CampaignType type) => switch (type) {
        CampaignType.homebrew => 'Homebrew',
        CampaignType.module => 'Module',
        CampaignType.adventurePath => 'Adventure Path',
        CampaignType.oneShot => 'One-Shot',
      };

  void _showPlayerDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Spieler verwalten'),
        content: SizedBox(
          width: 300,
          height: 200,
          child: Column(
            children: [
              const Text('Spieler-Management-Funktion wird in zukünftiger Version implementiert.'),
              const SizedBox(height: 20),
              Text(
                'Aktuelle Spieleranzahl: ${widget.campaign?.playerCount ?? 0}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveCampaign() async {
    if (!_formKey.currentState!.validate()) return;
    final viewModel = context.read<CampaignViewModel>();
    if (widget.campaign == null) {
      await viewModel.createCampaign(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
      );
    } else {
      await viewModel.updateCampaign(
        widget.campaign!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          status: _status,
          type: _type,
          dungeonMasterId: _dungeonMasterId,
          settings: _settings,
          updatedAt: DateTime.now(),
        ),
      );
    }
    if (viewModel.error == null && context.mounted) Navigator.pop(context);
  }

  Future<void> _duplicateCampaign() async {
    if (widget.campaign == null) return;
    final viewModel = context.read<CampaignViewModel>();
    await viewModel.duplicateCampaign(widget.campaign!);
    if (viewModel.error == null && context.mounted) {
      SnackBarHelper.showSuccess(context, 'Kampagne dupliziert');
    }
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
