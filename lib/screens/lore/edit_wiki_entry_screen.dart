import 'package:flutter/material.dart';
import '../../models/map_location.dart';
import '../../models/wiki_entry.dart';
import '../../services/wiki_entry_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_components/feedback/confirmation_dialog.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';

class EditWikiEntryScreen extends StatefulWidget {
  final WikiEntry? entry;
  final String? campaignId;

  const EditWikiEntryScreen({super.key, this.entry, this.campaignId});

  @override
  State<EditWikiEntryScreen> createState() => _EditWikiEntryScreenState();
}

class _EditWikiEntryScreenState extends State<EditWikiEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _tagController = TextEditingController();
  final _scrollController = ScrollController();

  final wikiService = WikiEntryService();

  WikiEntryType _selectedType = WikiEntryType.Lore;
  List<String> _tags = [];
  MapLocation? _location;

  bool _isLoading = false;
  bool _isGlobal = true;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    if (widget.entry != null) {
      final entry = widget.entry!;
      _titleController.text = entry.title;
      _contentController.text = entry.content;
      _selectedType = entry.entryType;
      _tags = List.from(entry.tags);
      _location = entry.location;
      _isGlobal = entry.isGlobal;
    } else if (widget.campaignId != null) {
      _isGlobal = false;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _tagController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = widget.entry != null
          ? await wikiService.updateWikiEntry(
              widget.entry!.copyWith(
                title: _titleController.text.trim(),
                content: _contentController.text.trim(),
                entryType: _selectedType,
                tags: _tags,
                location: _location,
                campaignId: _isGlobal ? null : widget.campaignId,
              ),
            )
          : await wikiService.createWikiEntry(
              WikiEntry.create(
                title: _titleController.text.trim(),
                content: _contentController.text.trim(),
                entryType: _selectedType,
                tags: _tags,
                location: _location,
                campaignId: _isGlobal ? null : widget.campaignId,
              ),
            );

      if (!result.isSuccess) throw Exception(result.userMessage);

      final savedEntry = result.data!;
      if (mounted) {
        SnackBarHelper.showSuccess(context, widget.entry != null ? 'Eintrag aktualisiert' : 'Eintrag erstellt');
        Navigator.of(context).pop(savedEntry);
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() => _tags.add(tag));
      _tagController.clear();
    }
  }

  void _removeTag(String tag) => setState(() => _tags.remove(tag));

  void _showLocationDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => LocationDialog(
        initialLocation: _location,
        onSave: (location) => setState(() => _location = location),
      ),
    );
  }

  Future<bool> _showDiscardChangesDialog() async {
    final result = await ConfirmationDialog.showWarning(
      context: context,
      title: 'Änderungen verwerfen?',
      message: 'Möchtest du die nicht gespeicherten Änderungen wirklich verwerfen?',
      confirmText: 'Verwerfen',
    );
    return result ?? false;
  }

  bool _hasUnsavedChanges() {
    if (widget.entry == null) {
      return _titleController.text.isNotEmpty ||
          _contentController.text.isNotEmpty ||
          _tags.isNotEmpty ||
          _location != null;
    }
    return _titleController.text.trim() != widget.entry!.title ||
        _contentController.text.trim() != widget.entry!.content ||
        _selectedType != widget.entry!.entryType ||
        !_listEquals(_tags, widget.entry!.tags) ||
        _location != widget.entry!.location;
  }

  bool _listEquals<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges()) {
          final shouldDiscard = await _showDiscardChangesDialog();
          if (shouldDiscard && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) Navigator.of(context).pop();
            });
          }
        }
      },
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
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
                    GestureDetector(
                      onTap: () async {
                        if (_hasUnsavedChanges()) {
                          final discard = await _showDiscardChangesDialog();
                          if (discard && mounted) Navigator.of(context).pop();
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                      child: SizedBox(width: 30, height: 30, child: Icon(Icons.arrow_back, size: 18, color: C.textMid)),
                    ),
                    Container(width: 1, height: 18, color: C.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: C.amber.withValues(alpha: 0.18),
                        border: Border.all(color: C.amber.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(child: Icon(Icons.menu_book, size: 14, color: C.amber)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.entry != null ? 'Wiki-Eintrag bearbeiten' : 'Neuer Wiki-Eintrag',
                      style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    const Spacer(),
                    if (_isLoading)
                      SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: C.accent))
                    else
                      GestureDetector(
                        onTap: _saveEntry,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(7)),
                          child: const Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.save, size: 13, color: Colors.white),
                            SizedBox(width: 5),
                            Text('Speichern', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ]),
                        ),
                      ),
                  ]),
                ),
              ),
            ),
          ),
        ),
        body: Form(
          key: _formKey,
          child: Scrollbar(
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),
                  _buildTypeSection(),
                  const SizedBox(height: 24),
                  _buildContentSection(),
                  const SizedBox(height: 24),
                  _buildTagsSection(),
                  const SizedBox(height: 24),
                  _buildLocationSection(),
                  if (widget.campaignId != null) ...[
                    const SizedBox(height: 24),
                    _buildCampaignSection(),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    final C = context.appColors;
    return Row(
      children: [
        Icon(icon, color: C.amber),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(fontSize: 18, color: C.amber, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  InputDecoration _fieldDecoration({
    required String label,
    String? hint,
    Color? labelColor,
  }) {
    final C = context.appColors;
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(fontSize: 14, color: labelColor ?? C.amber),
      hintStyle: TextStyle(fontSize: 14, color: C.textSoft),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: C.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: C.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: C.amber, width: 2),
      ),
      filled: true,
      fillColor: C.bgHover,
    );
  }

  Widget _buildBasicInfoSection() {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.info_outline, 'Grundinformationen'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _titleController,
            style: TextStyle(fontSize: 14, color: C.text),
            decoration: _fieldDecoration(
              label: 'Titel *',
              hint: 'z.B. "Drache von Neverwinter"',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Bitte gib einen Titel ein';
              return null;
            },
            textInputAction: TextInputAction.next,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeSection() {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.category, 'Eintragstyp'),
          const SizedBox(height: 16),
          SegmentedButton<WikiEntryType>(
            segments: WikiEntryType.values
                .map((type) => ButtonSegment(
                      value: type,
                      label: Text(
                        _getTypeDisplayName(type),
                        style: TextStyle(fontSize: 14, color: C.text),
                      ),
                      icon: Icon(_getTypeIcon(type), color: _getTypeColor(type)),
                    ))
                .toList(),
            selected: {_selectedType},
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return _getTypeColor(_selectedType).withValues(alpha: 0.3);
                }
                return C.bgHover;
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) return _getTypeColor(_selectedType);
                return C.textMid;
              }),
            ),
            onSelectionChanged: (selection) => setState(() => _selectedType = selection.first),
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.article, 'Inhalt'),
          const SizedBox(height: 16),
          TextFormField(
            controller: _contentController,
            style: TextStyle(fontSize: 14, color: C.text),
            decoration: _fieldDecoration(
              label: 'Beschreibung *',
              hint: 'Gib hier alle wichtigen Informationen ein...',
            ),
            maxLines: 8,
            minLines: 4,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Bitte gib einen Inhalt ein';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTagsSection() {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.local_offer, 'Tags'),
          const SizedBox(height: 8),
          Text(
            'Füge Tags hinzu, um deinen Eintrag leichter zu finden und zu organisieren',
            style: TextStyle(fontSize: 14, color: C.textSoft),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tagController,
                  style: TextStyle(fontSize: 14, color: C.text),
                  decoration: _fieldDecoration(
                    label: 'Neuer Tag',
                    hint: 'z.B. "wichtig", "NPC", "Ort"',
                  ),
                  onFieldSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: _addTag,
                icon: const Icon(Icons.add),
                tooltip: 'Tag hinzufügen',
                style: IconButton.styleFrom(
                  backgroundColor: C.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: _tags
                  .map((tag) => Chip(
                        label: Text(
                          tag,
                          style: TextStyle(fontSize: 12, color: C.amber),
                        ),
                        backgroundColor: C.amber.withValues(alpha: 0.1),
                        side: BorderSide(color: C.amber.withValues(alpha: 0.3)),
                        onDeleted: () => _removeTag(tag),
                        deleteIcon: Icon(Icons.close, size: 16, color: C.amber),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(Icons.location_on, 'Standort (Optional)'),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: C.bgHover,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _location != null ? C.accent : C.border,
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.location_on,
                color: _location != null ? C.accent : C.textMid,
              ),
              title: Text(
                _location != null ? 'Standort festlegt' : 'Kein Standort',
                style: TextStyle(fontSize: 14, color: C.text),
              ),
              subtitle: Text(
                _location != null
                    ? 'Lat: ${_location!.latitude.toStringAsFixed(4)}, Lng: ${_location!.longitude.toStringAsFixed(4)}'
                    : 'Füge einen Standort für zukünftige Karten hinzu',
                style: TextStyle(fontSize: 13, color: C.textMid),
              ),
              trailing: Icon(Icons.edit, color: C.accent),
              onTap: _showLocationDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignSection() {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: C.border),
      ),
      child: SwitchListTile(
        title: Text('Globaler Eintrag', style: TextStyle(fontSize: 14, color: C.text)),
        subtitle: Text('Soll dieser Eintrag für alle Kampagnen sichtbar sein?',
            style: TextStyle(fontSize: 13, color: C.textMid)),
        value: _isGlobal,
        onChanged: (value) => setState(() => _isGlobal = value),
        secondary: Icon(Icons.public, color: _isGlobal ? C.accent : C.textMid),
      ),
    );
  }

  String _getTypeDisplayName(WikiEntryType type) {
    return switch (type) {
      WikiEntryType.Person => 'NPC',
      WikiEntryType.Place => 'Ort',
      WikiEntryType.Lore => 'Lore',
      WikiEntryType.Faction => 'Fraktion',
      WikiEntryType.Magic => 'Magie',
      WikiEntryType.History => 'Geschichte',
      WikiEntryType.Item => 'Gegenstand',
      WikiEntryType.Quest => 'Quest',
      WikiEntryType.Creature => 'Kreatur',
    };
  }

  IconData _getTypeIcon(WikiEntryType type) {
    return switch (type) {
      WikiEntryType.Person => Icons.person,
      WikiEntryType.Place => Icons.location_on,
      WikiEntryType.Lore => Icons.menu_book,
      WikiEntryType.Faction => Icons.groups,
      WikiEntryType.Magic => Icons.auto_fix_high,
      WikiEntryType.History => Icons.history,
      WikiEntryType.Item => Icons.inventory_2,
      WikiEntryType.Quest => Icons.task_alt,
      WikiEntryType.Creature => Icons.cruelty_free,
    };
  }

  Color _getTypeColor(WikiEntryType type) {
    final C = context.appColors;
    return switch (type) {
      WikiEntryType.Person => C.accent,
      WikiEntryType.Place => C.green,
      WikiEntryType.Lore => C.accent,
      WikiEntryType.Faction => const Color(0xFFEA580C),
      WikiEntryType.Magic => C.accent,
      WikiEntryType.History => C.amber,
      WikiEntryType.Item => C.accent,
      WikiEntryType.Quest => C.accent,
      WikiEntryType.Creature => C.red,
    };
  }
}

class LocationDialog extends StatefulWidget {
  final MapLocation? initialLocation;
  final void Function(MapLocation) onSave;

  const LocationDialog({super.key, required this.onSave, this.initialLocation});

  @override
  State<LocationDialog> createState() => _LocationDialogState();
}

class _LocationDialogState extends State<LocationDialog> {
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _mapIdController = TextEditingController();
  final _markerTypeController = TextEditingController();
  final _zoomController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialLocation != null) {
      final loc = widget.initialLocation!;
      _latController.text = loc.latitude.toString();
      _lngController.text = loc.longitude.toString();
      _mapIdController.text = loc.mapId;
      _markerTypeController.text = loc.markerType ?? '';
      _zoomController.text = loc.zoomLevel.toString();
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lngController.dispose();
    _mapIdController.dispose();
    _markerTypeController.dispose();
    _zoomController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final fieldDeco = InputDecoration(
      labelStyle: TextStyle(fontSize: 14, color: C.amber),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: C.bgHover,
    );

    return AlertDialog(
      backgroundColor: C.bgPanel,
      title: Text(
        'Standort bearbeiten',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: C.amber),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    style: TextStyle(fontSize: 14, color: C.text),
                    decoration: fieldDeco.copyWith(labelText: 'Breitengrad'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    style: TextStyle(fontSize: 14, color: C.text),
                    decoration: fieldDeco.copyWith(labelText: 'Längengrad'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _mapIdController,
              style: TextStyle(fontSize: 14, color: C.text),
              decoration: fieldDeco.copyWith(labelText: 'Karten-ID'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _markerTypeController,
              style: TextStyle(fontSize: 14, color: C.text),
              decoration: fieldDeco.copyWith(
                labelText: 'Marker-Typ',
                hintText: 'city, dungeon, npc, etc.',
                hintStyle: TextStyle(fontSize: 14, color: C.textSoft),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _zoomController,
              style: TextStyle(fontSize: 14, color: C.text),
              decoration: fieldDeco.copyWith(labelText: 'Zoom-Level'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
        ),
        ElevatedButton(
          onPressed: () {
            final location = MapLocation(
              latitude: double.tryParse(_latController.text) ?? 0.0,
              longitude: double.tryParse(_lngController.text) ?? 0.0,
              mapId: _mapIdController.text.trim().isNotEmpty
                  ? _mapIdController.text.trim()
                  : 'default',
              markerType: _markerTypeController.text.trim().isNotEmpty
                  ? _markerTypeController.text.trim()
                  : null,
              zoomLevel: int.tryParse(_zoomController.text) ?? 10,
            );
            widget.onSave(location);
            Navigator.of(context).pop();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: C.green,
            foregroundColor: Colors.white,
          ),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
