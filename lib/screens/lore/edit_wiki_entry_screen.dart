import 'package:flutter/material.dart';
import '../../services/wiki_entry_service.dart';
import '../../models/wiki_entry.dart';
import '../../models/map_location.dart';
import '../../theme/dnd_theme.dart';

/// Enhanced Edit Wiki Entry Screen mit Enhanced Design, Tag-Management und Location-Unterstützung
/// 
/// Verwendet WikiEntryService für CRUD-Operationen mit ServiceResult Pattern.
class EditWikiEntryScreen extends StatefulWidget {
  final WikiEntry? entry;
  final String? campaignId;
  
  const EditWikiEntryScreen({
    super.key,
    this.entry,
    this.campaignId,
  });

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
            backgroundColor: DnDTheme.successGreen,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: DnDTheme.errorRed,
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
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Änderungen verwerfen?',
          style: DnDTheme.headline3.copyWith(color: DnDTheme.warningOrange),
        ),
        content: Text(
          'Möchtest du die nicht gespeicherten Änderungen wirklich verwerfen?',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              'Verwerfen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.warningOrange,
              ),
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
        backgroundColor: DnDTheme.dungeonBlack,
        appBar: AppBar(
          title: Text(
            widget.entry != null ? 'Wiki-Eintrag bearbeiten' : 'Neuer Wiki-Eintrag',
            style: DnDTheme.headline2.copyWith(
              color: DnDTheme.ancientGold,
            ),
          ),
          backgroundColor: DnDTheme.stoneGrey,
          foregroundColor: Colors.white,
          actions: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(DnDTheme.md),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DnDTheme.ancientGold,
                  ),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.save),
                label: const Text('Speichern'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DnDTheme.successGreen,
                  foregroundColor: Colors.white,
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
              padding: const EdgeInsets.all(DnDTheme.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: DnDTheme.lg),
                  _buildTypeSection(),
                  const SizedBox(height: DnDTheme.lg),
                  _buildContentSection(),
                  const SizedBox(height: DnDTheme.lg),
                  _buildTagsSection(),
                  const SizedBox(height: DnDTheme.lg),
                  _buildLocationSection(),
                  if (widget.campaignId != null) ...[
                    const SizedBox(height: DnDTheme.lg),
                    _buildCampaignSection(),
                  ],
                  const SizedBox(height: DnDTheme.xl),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: DnDTheme.ancientGold),
              const SizedBox(width: DnDTheme.sm),
              Text(
                'Grundinformationen',
                style: DnDTheme.headline3.copyWith(
                  color: DnDTheme.ancientGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DnDTheme.md),
          TextFormField(
            controller: _titleController,
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Titel *',
              hintText: 'z.B. "Drache von Neverwinter"',
              labelStyle: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.ancientGold,
              ),
              hintStyle: DnDTheme.bodyText2.copyWith(
                color: Colors.white54,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(color: DnDTheme.mysticalPurple),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(
                  color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
              ),
              filled: true,
              fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
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
      ),
    );
  }

  Widget _buildTypeSection() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.category, color: DnDTheme.ancientGold),
              const SizedBox(width: DnDTheme.sm),
              Text(
                'Eintragstyp',
                style: DnDTheme.headline3.copyWith(
                  color: DnDTheme.ancientGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DnDTheme.md),
          SegmentedButton<WikiEntryType>(
            segments: WikiEntryType.values.map((type) => ButtonSegment(
              value: type,
              label: Text(_getTypeDisplayName(type), style: DnDTheme.bodyText2.copyWith(color: Colors.white)),
              icon: Icon(_getTypeIcon(type), color: _getTypeColor(type)),
            )).toList(),
            selected: {_selectedType},
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return _getTypeColor(_selectedType).withValues(alpha: 0.3);
                }
                return DnDTheme.slateGrey.withValues(alpha: 0.3);
              }),
              foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
                if (states.contains(WidgetState.selected)) {
                  return _getTypeColor(_selectedType);
                }
                return Colors.white70;
              }),
            ),
            onSelectionChanged: (selection) {
              setState(() {
                _selectedType = selection.first;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.article, color: DnDTheme.ancientGold),
              const SizedBox(width: DnDTheme.sm),
              Text(
                'Inhalt',
                style: DnDTheme.headline3.copyWith(
                  color: DnDTheme.ancientGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DnDTheme.md),
          TextFormField(
            controller: _contentController,
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Beschreibung *',
              hintText: 'Gib hier alle wichtigen Informationen ein...',
              labelStyle: DnDTheme.bodyText2.copyWith(
                color: DnDTheme.ancientGold,
              ),
              hintStyle: DnDTheme.bodyText2.copyWith(
                color: Colors.white54,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(color: DnDTheme.mysticalPurple),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(
                  color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
              ),
              filled: true,
              fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
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
      ),
    );
  }

  Widget _buildTagsSection() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.local_offer, color: DnDTheme.ancientGold),
              const SizedBox(width: DnDTheme.sm),
              Text(
                'Tags',
                style: DnDTheme.headline3.copyWith(
                  color: DnDTheme.ancientGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DnDTheme.sm),
          Text(
            'Füge Tags hinzu, um deinen Eintrag leichter zu finden und zu organisieren',
            style: DnDTheme.bodyText2.copyWith(
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: DnDTheme.md),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _tagController,
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Neuer Tag',
                    hintText: 'z.B. "wichtig", "NPC", "Ort"',
                    labelStyle: DnDTheme.bodyText2.copyWith(
                      color: DnDTheme.ancientGold,
                    ),
                    hintStyle: DnDTheme.bodyText2.copyWith(
                      color: Colors.white54,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(
                        color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                    ),
                    filled: true,
                    fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                  ),
                  onFieldSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: DnDTheme.sm),
              IconButton.filled(
                onPressed: _addTag,
                icon: const Icon(Icons.add),
                tooltip: 'Tag hinzufügen',
                style: IconButton.styleFrom(
                  backgroundColor: DnDTheme.mysticalPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          if (_tags.isNotEmpty) ...[
            const SizedBox(height: DnDTheme.md),
            Wrap(
              spacing: DnDTheme.xs,
              runSpacing: DnDTheme.xs,
              children: _tags.map((tag) => Chip(
                label: Text(tag, style: DnDTheme.caption.copyWith(color: DnDTheme.ancientGold)),
                backgroundColor: DnDTheme.ancientGold.withValues(alpha: 0.1),
                side: BorderSide(color: DnDTheme.ancientGold.withValues(alpha: 0.3)),
                onDeleted: () => _removeTag(tag),
                deleteIcon: Icon(Icons.close, size: 16, color: DnDTheme.ancientGold),
              )).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: DnDTheme.ancientGold),
              const SizedBox(width: DnDTheme.sm),
              Text(
                'Standort (Optional)',
                style: DnDTheme.headline3.copyWith(
                  color: DnDTheme.ancientGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: DnDTheme.md),
          Container(
            decoration: BoxDecoration(
              color: DnDTheme.slateGrey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
              border: Border.all(
                color: _location != null 
                    ? DnDTheme.arcaneBlue 
                    : DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                width: 1,
              ),
            ),
            child: ListTile(
              leading: Icon(
                Icons.location_on,
                color: _location != null ? DnDTheme.arcaneBlue : Colors.white70,
              ),
              title: Text(
                _location != null ? 'Standort festlegt' : 'Kein Standort',
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              subtitle: Text(
                _location != null 
                    ? 'Lat: ${_location!.latitude.toStringAsFixed(4)}, Lng: ${_location!.longitude.toStringAsFixed(4)}'
                    : 'Füge einen Standort für zukünftige Karten hinzu',
                style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
              ),
              trailing: Icon(Icons.edit, color: DnDTheme.arcaneBlue),
              onTap: _showLocationDialog,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampaignSection() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: SwitchListTile(
        title: Text(
          'Globaler Eintrag',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
        ),
        subtitle: Text(
          'Soll dieser Eintrag für alle Kampagnen sichtbar sein?',
          style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
        ),
        value: _isGlobal,
        onChanged: (value) {
          setState(() {
            _isGlobal = value;
          });
        },
        secondary: Icon(Icons.public, color: _isGlobal ? DnDTheme.arcaneBlue : Colors.white70),
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

  Color _getTypeColor(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return DnDTheme.arcaneBlue;
      case WikiEntryType.Place:
        return DnDTheme.successGreen;
      case WikiEntryType.Lore:
        return DnDTheme.mysticalPurple;
      case WikiEntryType.Faction:
        return DnDTheme.warningOrange;
      case WikiEntryType.Magic:
        return DnDTheme.infoBlue;
      case WikiEntryType.History:
        return DnDTheme.ancientGold;
      case WikiEntryType.Item:
        return DnDTheme.arcaneBlue;
      case WikiEntryType.Quest:
        return DnDTheme.mysticalPurple;
      case WikiEntryType.Creature:
        return DnDTheme.errorRed;
    }
  }
}

/// Enhanced Dialog für Standort-Eingabe
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
      backgroundColor: DnDTheme.stoneGrey,
      title: Text(
        'Standort bearbeiten',
        style: DnDTheme.headline3.copyWith(
          color: DnDTheme.ancientGold,
        ),
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
                    style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Breitengrad',
                      labelStyle: DnDTheme.bodyText2.copyWith(
                        color: DnDTheme.ancientGold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      ),
                      filled: true,
                      fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: DnDTheme.sm),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Längengrad',
                      labelStyle: DnDTheme.bodyText2.copyWith(
                        color: DnDTheme.ancientGold,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      ),
                      filled: true,
                      fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: DnDTheme.sm),
            TextFormField(
              controller: _mapIdController,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Karten-ID',
                labelStyle: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            TextFormField(
              controller: _markerTypeController,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Marker-Typ',
                hintText: 'city, dungeon, npc, etc.',
                labelStyle: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
                hintStyle: DnDTheme.bodyText2.copyWith(
                  color: Colors.white54,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            TextFormField(
              controller: _zoomController,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Zoom-Level',
                labelStyle: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Abbrechen',
            style: DnDTheme.bodyText1.copyWith(
              color: DnDTheme.mysticalPurple,
            ),
          ),
        ),
        ElevatedButton(
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
          style: ElevatedButton.styleFrom(
            backgroundColor: DnDTheme.successGreen,
            foregroundColor: Colors.white,
          ),
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}