import 'package:flutter/material.dart';
import '../../services/wiki_entry_service.dart';
import '../../models/wiki_entry.dart';
import '../../models/map_location.dart';
import '../../theme/app_theme.dart';

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
        final C = context.appColors;
        Navigator.of(context).pop(savedEntry);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.entry != null ? 'Eintrag aktualisiert' : 'Eintrag erstellt',
            ),
            backgroundColor: C.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: context.appColors.red,
          ),
        );
      }
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

  Future<bool> _showDiscardChangesDialog() {
    final C = context.appColors;
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: const Text(
          'Änderungen verwerfen?',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFEA580C)),
        ),
        content: const Text(
          'Möchtest du die nicht gespeicherten Änderungen wirklich verwerfen?',
          style: TextStyle(fontSize: 16, color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'Abbrechen',
              style: TextStyle(fontSize: 16, color: Color(0xFF7C3AED)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Verwerfen',
              style: TextStyle(fontSize: 16, color: Color(0xFFEA580C)),
            ),
          ),
        ],
      ),
    ).then((value) => value ?? false);
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
        appBar: AppBar(
          title: Text(
            widget.entry != null ? 'Wiki-Eintrag bearbeiten' : 'Neuer Wiki-Eintrag',
            style: TextStyle(fontSize: 22, color: C.amber, fontWeight: FontWeight.bold),
          ),
          backgroundColor: C.bgPanel,
          foregroundColor: Colors.white,
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ElevatedButton.icon(
                  onPressed: _saveEntry,
                  icon: const Icon(Icons.save),
                  label: const Text('Speichern'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
          ],
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
      hintStyle: const TextStyle(fontSize: 14, color: Colors.white54),
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
            style: const TextStyle(fontSize: 16, color: Colors.white),
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
                        style: const TextStyle(fontSize: 14, color: Colors.white),
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
                return Colors.white70;
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
            style: const TextStyle(fontSize: 16, color: Colors.white),
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
                  style: const TextStyle(fontSize: 16, color: Colors.white),
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
                  backgroundColor: const Color(0xFF7C3AED),
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
                color: _location != null ? C.accent : Colors.white70,
              ),
              title: Text(
                _location != null ? 'Standort festlegt' : 'Kein Standort',
                style: const TextStyle(fontSize: 16, color: Colors.white),
              ),
              subtitle: Text(
                _location != null
                    ? 'Lat: ${_location!.latitude.toStringAsFixed(4)}, Lng: ${_location!.longitude.toStringAsFixed(4)}'
                    : 'Füge einen Standort für zukünftige Karten hinzu',
                style: const TextStyle(fontSize: 14, color: Colors.white70),
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
        title: const Text(
          'Globaler Eintrag',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        subtitle: const Text(
          'Soll dieser Eintrag für alle Kampagnen sichtbar sein?',
          style: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        value: _isGlobal,
        onChanged: (value) => setState(() => _isGlobal = value),
        secondary: Icon(Icons.public, color: _isGlobal ? C.accent : Colors.white70),
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
      WikiEntryType.Lore => const Color(0xFF7C3AED),
      WikiEntryType.Faction => const Color(0xFFEA580C),
      WikiEntryType.Magic => C.accent,
      WikiEntryType.History => C.amber,
      WikiEntryType.Item => C.accent,
      WikiEntryType.Quest => const Color(0xFF7C3AED),
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
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    decoration: fieldDeco.copyWith(labelText: 'Breitengrad'),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                    decoration: fieldDeco.copyWith(labelText: 'Längengrad'),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _mapIdController,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: fieldDeco.copyWith(labelText: 'Karten-ID'),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _markerTypeController,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: fieldDeco.copyWith(
                labelText: 'Marker-Typ',
                hintText: 'city, dungeon, npc, etc.',
                hintStyle: const TextStyle(fontSize: 14, color: Colors.white54),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _zoomController,
              style: const TextStyle(fontSize: 16, color: Colors.white),
              decoration: fieldDeco.copyWith(labelText: 'Zoom-Level'),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Abbrechen',
            style: TextStyle(fontSize: 16, color: Color(0xFF7C3AED)),
          ),
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
