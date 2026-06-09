import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

import '../../services/resource_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';

/// Zeigt die lokale Ressourcen-Bibliothek.
///
/// [pickMode] = false → Verwaltungs-Screen (von HomeScreen aufrufbar)
/// [pickMode] = true  → Auswahl-Dialog, gibt `resource://filename` zurück
class ResourceLibraryScreen extends StatefulWidget {
  const ResourceLibraryScreen({super.key, this.pickMode = false});

  final bool pickMode;

  @override
  State<ResourceLibraryScreen> createState() => _ResourceLibraryScreenState();
}

class _ResourceLibraryScreenState extends State<ResourceLibraryScreen> {
  List<ResourceEntry> _entries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await ResourceService.listAll();
    if (mounted) setState(() { _entries = entries; _loading = false; });
  }

  // ── Import ────────────────────────────────────────────────────────────────

  Future<void> _importFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    final srcPath = result.files.single.path!;
    final suggested = p.basename(srcPath);

    if (!mounted) return;
    final name = await _showNameDialog(suggested);
    if (name == null || name.isEmpty) return;

    try {
      final ref = await ResourceService.importFile(srcPath, name);
      if (!mounted) return;
      if (widget.pickMode) {
        Navigator.of(context).pop(ref);
      } else {
        await _load();
        if (mounted) SnackBarHelper.showSuccess(context, '"$name" importiert');
      }
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler beim Importieren: $e');
    }
  }

  Future<String?> _showNameDialog(String suggested) {
    final ctrl = TextEditingController(text: suggested);
    final C = context.appColors;
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text('Dateiname', style: TextStyle(color: C.text, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: C.text),
          decoration: InputDecoration(
            hintText: 'z.B. weltkarte.jpg',
            hintStyle: TextStyle(color: C.textSoft),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: C.border),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: C.accent),
            ),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(ctrl.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Abbrechen', style: TextStyle(color: C.textSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text('Importieren', style: TextStyle(color: C.accent)),
          ),
        ],
      ),
    );
  }

  // ── Delete ────────────────────────────────────────────────────────────────

  Future<void> _deleteEntry(ResourceEntry entry) async {
    final C = context.appColors;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text('Löschen?', style: TextStyle(color: C.text, fontSize: 15)),
        content: Text(
          '"${entry.filename}" wird aus der Bibliothek entfernt.\n'
          'Kampagnen die diese Ressource verwenden zeigen kein Bild mehr.',
          style: TextStyle(color: C.textSoft, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Abbrechen', style: TextStyle(color: C.textSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text('Löschen', style: TextStyle(color: C.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ResourceService.deleteFile(entry.filename);
    await _load();
  }

  // ── Rename ────────────────────────────────────────────────────────────────

  Future<void> _renameEntry(ResourceEntry entry) async {
    final C = context.appColors;
    final ctrl = TextEditingController(text: entry.filename);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text('Umbenennen', style: TextStyle(color: C.text, fontSize: 15)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(color: C.text),
          decoration: InputDecoration(
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: C.border)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: C.accent)),
          ),
          onSubmitted: (_) => Navigator.of(ctx).pop(ctrl.text.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Abbrechen', style: TextStyle(color: C.textSoft)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(ctrl.text.trim()),
            child: Text('Speichern', style: TextStyle(color: C.accent)),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == entry.filename) return;
    try {
      await ResourceService.renameFile(entry.filename, newName);
      await _load();
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler beim Umbenennen: $e');
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        backgroundColor: C.bgPanel,
        surfaceTintColor: Colors.transparent,
        leading: widget.pickMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: Text(
          widget.pickMode ? 'Ressource auswählen' : 'Ressourcen-Bibliothek',
          style: TextStyle(color: C.text, fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          TextButton.icon(
            onPressed: _importFile,
            icon: Icon(Icons.add, size: 18, color: C.accent),
            label: Text('Importieren', style: TextStyle(color: C.accent, fontSize: 13)),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: C.accent))
          : _entries.isEmpty
              ? _buildEmpty(C)
              : _buildGrid(C),
    );
  }

  Widget _buildEmpty(AppColorsExtension C) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: C.textSoft),
            const SizedBox(height: 12),
            Text(
              'Noch keine Ressourcen',
              style: TextStyle(color: C.textSoft, fontSize: 14),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _importFile,
              child: Text('Jetzt importieren', style: TextStyle(color: C.accent)),
            ),
          ],
        ),
      );

  Widget _buildGrid(AppColorsExtension C) => GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.85,
        ),
        itemCount: _entries.length,
        itemBuilder: (_, i) => _ResourceTile(
          entry: _entries[i],
          pickMode: widget.pickMode,
          onTap: () => _onTap(_entries[i]),
          onRename: () => _renameEntry(_entries[i]),
          onDelete: () => _deleteEntry(_entries[i]),
        ),
      );

  void _onTap(ResourceEntry entry) {
    if (widget.pickMode) {
      Navigator.of(context)
          .pop('${ResourceService.scheme}${entry.filename}');
    } else {
      _showPreview(entry);
    }
  }

  void _showPreview(ResourceEntry entry) {
    final C = context.appColors;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(entry.filename,
                  style: TextStyle(color: C.text, fontSize: 13)),
            ),
            Image.file(File(entry.absolutePath), fit: BoxFit.contain),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Schließen', style: TextStyle(color: C.textSoft)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kachel ────────────────────────────────────────────────────────────────────

class _ResourceTile extends StatelessWidget {
  const _ResourceTile({
    required this.entry,
    required this.pickMode,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  final ResourceEntry entry;
  final bool pickMode;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return GestureDetector(
      onTap: onTap,
      onLongPress: pickMode ? null : () => _showMenu(context, C),
      child: Container(
        decoration: BoxDecoration(
          color: C.bgPanel,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: C.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(7)),
                child: Image.file(
                  File(entry.absolutePath),
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(Icons.broken_image_outlined,
                        color: C.textSoft, size: 32),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Text(
                entry.filename,
                style: TextStyle(color: C.text, fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMenu(BuildContext context, AppColorsExtension C) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: C.bgPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.drive_file_rename_outline, color: C.accent),
              title: Text('Umbenennen', style: TextStyle(color: C.text)),
              onTap: () {
                Navigator.of(context).pop();
                onRename();
              },
            ),
            ListTile(
              leading: Icon(Icons.delete_outline, color: C.red),
              title: Text('Löschen', style: TextStyle(color: C.red)),
              onTap: () {
                Navigator.of(context).pop();
                onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── Statische Helfer-Methode für anderen Screens ──────────────────────────────

/// Öffnet die Ressourcen-Bibliothek im Pick-Modus.
/// Gibt `resource://filename.ext` zurück oder null.
Future<String?> pickResource(BuildContext context) {
  return Navigator.of(context).push<String>(
    MaterialPageRoute(
      builder: (_) => const ResourceLibraryScreen(pickMode: true),
      fullscreenDialog: true,
    ),
  );
}
