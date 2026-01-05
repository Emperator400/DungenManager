import 'package:flutter/material.dart';
import '../services/wiki_entry_service.dart';
import '../models/wiki_entry.dart';
import '../models/map_location.dart';

/// Enhanced Edit Wiki Entry Screen mit Tag-Management und Location-Unterstützung
/// 
/// Verwendet WikiEntryService für CRUD-Operationen mit ServiceResult Pattern.
class EnhancedEditWikiEntryScreen extends StatefulWidget {
  final WikiEntry? entry;
  final String? campaignId;

  const EnhancedEditWikiEntryScreen({
    super.key,
    this.entry,
    this.campaignId,
  });

  @override
  State<EnhancedEditWikiEntryScreen> createState() => _EnhancedEditWikiEntryScreenState();
}

class _EnhancedEditWikiEntryScreenState extends State<EnhancedEditWikiEntryScreen> {
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

    setState(() {
      _isLoading = true;
    });

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

      if (!result.isSuccess) {
        throw Exception(result.userMessage);
      }

      final savedEntry = result.data!;

      if (mounted) {
        Navigator.of(context).pop(savedEntry);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                content: Text(widget.entry != null ? 'Eintrag aktualisiert' : 'Eintrag erstellt'),
                duration: const Duration(seconds: 2),
              ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
                content: Text('Fehler: $e'),
                backgroundColor: Colors.red,
              ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_tags.contains(tag)) {
      setState(() {
        _tags.add(tag);
      });
      _tagController.clear();
    }
  }

  void _removeTag(String tag) {
    setState(() {
      _tags.remove(tag);
    });
  }

  void _showLocationDialog() {
    showDialog<void>(
      context: context,
      builder: (context) => LocationDialog(
        initialLocation: _location,
        onSave: (location) {
          setState(() {
            _location = location;
          });
        },
      ),
    );
  }

  Future<bool> _showDiscardChangesDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Änderungen verwerfen?'),
        content: const Text('Möchtest du die nicht gespeicherten Änderungen wirklich verwerfen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Verwerfen',
              style: TextStyle(color: Colors.red),
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
    return PopScope(
      canPop: !_hasUnsavedChanges(),
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges()) {
          final shouldDiscard = await _showDiscardChangesDialog();
          if (shouldDiscard && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                Navigator.of(context).pop();
              }
            });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.entry != null ? 'Wiki-Eintrag bearbeiten' : 'Neuer Wiki-Eintrag'),
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              TextButton(
                onPressed: _saveEntry,
                child: const Text('Speichern'),
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

  Widget _buildBasicInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Grundinformationen',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _titleController,
          decoration: const InputDecoration(
            labelText: 'Titel *',
            hintText: 'z.B. "Drache von Neverwinter"',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitte gib einen Titel ein';
            }
            return null;
          },
          textInputAction: TextInputAction.next,
        ),
      ],
    );
  }

  Widget _buildTypeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Eintragstyp',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<WikiEntryType>(
          segments: WikiEntryType.values.map((type) => ButtonSegment(
            value: type,
            label: Text(_getTypeDisplayName(type)),
            icon: Icon(_getTypeIcon(type)),
          )).toList(),
          selected: {_selectedType},
          onSelectionChanged: (selection) {
            setState(() {
              _selectedType = selection.first;
            });
          },
        ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Inhalt',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contentController,
          decoration: const InputDecoration(
            labelText: 'Beschreibung *',
            hintText: 'Gib hier alle wichtigen Informationen ein...',
            border: OutlineInputBorder(),
          ),
          maxLines: 8,
          minLines: 4,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitte gib einen Inhalt ein';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tags',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Füge Tags hinzu, um deinen Eintrag leichter zu finden und zu organisieren',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: 'Neuer Tag',
                  hintText: 'z.B. "wichtig", "NPC", "Ort"',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (_) => _addTag(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _addTag,
              icon: const Icon(Icons.add),
              tooltip: 'Tag hinzufügen',
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _tags.map((tag) => Chip(
              label: Text(tag),
              onDeleted: () => _removeTag(tag),
              deleteIcon: const Icon(Icons.close, size: 16),
            )).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildLocationSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Standort (Optional)',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: ListTile(
            leading: Icon(
              Icons.location_on,
              color: _location != null ? Theme.of(context).primaryColor : Colors.grey,
            ),
            title: Text(_location != null 
                ? 'Standort festgelegt' 
                : 'Kein Standort'),
            subtitle: Text(_location != null 
                ? 'Lat: ${_location!.latitude.toStringAsFixed(4)}, Lng: ${_location!.longitude.toStringAsFixed(4)}'
                : 'Füge einen Standort für zukünftige Karten hinzu'),
            trailing: const Icon(Icons.edit),
            onTap: _showLocationDialog,
          ),
        ),
      ],
    );
  }

  Widget _buildCampaignSection() {
    return Card(
      child: SwitchListTile(
        title: const Text('Globaler Eintrag'),
        subtitle: const Text('Soll dieser Eintrag für alle Kampagnen sichtbar sein?'),
        value: _isGlobal,
        onChanged: (value) {
          setState(() {
            _isGlobal = value;
          });
        },
        secondary: const Icon(Icons.public),
      ),
    );
  }

  String _getTypeDisplayName(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return 'NPC';
      case WikiEntryType.Place:
        return 'Ort';
      case WikiEntryType.Lore:
        return 'Lore';
      case WikiEntryType.Faction:
        return 'Fraktion';
      case WikiEntryType.Magic:
        return 'Magie';
      case WikiEntryType.History:
        return 'Geschichte';
      case WikiEntryType.Item:
        return 'Gegenstand';
      case WikiEntryType.Quest:
        return 'Quest';
      case WikiEntryType.Creature:
        return 'Kreatur';
    }
  }

  IconData _getTypeIcon(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return Icons.person;
      case WikiEntryType.Place:
        return Icons.location_on;
      case WikiEntryType.Lore:
        return Icons.menu_book;
      case WikiEntryType.Faction:
        return Icons.groups;
      case WikiEntryType.Magic:
        return Icons.auto_fix_high;
      case WikiEntryType.History:
        return Icons.history;
      case WikiEntryType.Item:
        return Icons.inventory_2;
      case WikiEntryType.Quest:
        return Icons.task_alt;
      case WikiEntryType.Creature:
        return Icons.cruelty_free;
    }
  }
}

/// Dialog für Standort-Eingabe
class LocationDialog extends StatefulWidget {
  final MapLocation? initialLocation;
  final void Function(MapLocation) onSave;

  const LocationDialog({
    super.key,
    required this.onSave,
    this.initialLocation,
  });

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
    return AlertDialog(
      title: const Text('Standort bearbeiten'),
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
                    decoration: const InputDecoration(
                      labelText: 'Breitengrad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    decoration: const InputDecoration(
                      labelText: 'Längengrad',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mapIdController,
              decoration: const InputDecoration(
                labelText: 'Karten-ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _markerTypeController,
              decoration: const InputDecoration(
                labelText: 'Marker-Typ',
                hintText: 'city, dungeon, npc, etc.',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _zoomController,
              decoration: const InputDecoration(
                labelText: 'Zoom-Level',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ), // KORREKTUR: Schließende Klammer für SizedBox
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            final location = MapLocation(
              latitude: double.tryParse(_latController.text) ?? 0.0,
              longitude: double.tryParse(_lngController.text) ?? 0.0,
              mapId: _mapIdController.text.trim().isNotEmpty ? _mapIdController.text.trim() : 'default',
              markerType: _markerTypeController.text.trim().isNotEmpty ? _markerTypeController.text.trim() : null,
              zoomLevel: int.tryParse(_zoomController.text) ?? 10,
            );
            widget.onSave(location);
            Navigator.of(context).pop();
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
