// lib/widgets/sounds_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../database/database_helper.dart';
import '../models/sound.dart';

class SoundsTab extends StatefulWidget {
  const SoundsTab({super.key});

  @override
  State<SoundsTab> createState() => _SoundsTabState();
}

class _SoundsTabState extends State<SoundsTab> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Sound>> _soundsFuture;

  @override
  void initState() {
    super.initState();
    _loadSounds();
  }

  void _loadSounds() {
    setState(() {
      _soundsFuture = dbHelper.getAllSounds();
    });
  }

  Future<void> _addNewSound() async {
    // 1. Datei auswählen
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.audio,
    );

    if (result != null) {
      File sourceFile = File(result.files.single.path!);
      
      // 2. Ziel-Pfad im App-Verzeichnis bestimmen
      final directory = await getApplicationDocumentsDirectory();
      final String fileName = p.basename(sourceFile.path);
      final String destinationPath = p.join(directory.path, 'sounds', fileName);
      final destinationDirectory = Directory(p.join(directory.path, 'sounds'));

      // Erstelle das 'sounds'-Verzeichnis, falls es nicht existiert
      if (!await destinationDirectory.exists()) {
        await destinationDirectory.create(recursive: true);
      }
      
      // 3. Datei kopieren
      final File destinationFile = await sourceFile.copy(destinationPath);

      // 4. Dialog für Name und Typ anzeigen
      final soundDetails = await _showSoundDetailsDialog();

      if (soundDetails != null) {
        final newSound = Sound(
          name: soundDetails['name'],
          filePath: destinationFile.path,
          soundType: soundDetails['type'],
        );
        await dbHelper.insertSound(newSound);
        _loadSounds(); // Liste aktualisieren
      }
    }
  }

  Future<Map<String, dynamic>?> _showSoundDetailsDialog() {
    final nameController = TextEditingController();
    SoundType selectedType = SoundType.Ambiente;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Sound benennen"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name des Sounds")),
                const SizedBox(height: 16),
                DropdownButtonFormField<SoundType>(
                  value: selectedType,
                  items: SoundType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.toString().split('.').last))).toList(),
                  onChanged: (val) => setDialogState(() => selectedType = val!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Abbrechen")),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    Navigator.of(context).pop({'name': nameController.text, 'type': selectedType});
                  }
                },
                child: const Text("Speichern"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Sound>>(
        future: _soundsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final sounds = snapshot.data!;
          if (sounds.isEmpty) return const Center(child: Text("Keine Sounds in der Bibliothek."));
          
          return ListView.builder(
            itemCount: sounds.length,
            itemBuilder: (context, index) {
              final sound = sounds[index];
              return ListTile(
                leading: Icon(sound.soundType == SoundType.Ambiente ? Icons.music_note : Icons.volume_up),
                title: Text(sound.name),
                subtitle: Text(sound.soundType.toString().split('.').last),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    // Hier löschen wir auch die Datei vom Gerät
                    final file = File(sound.filePath);
                    if (await file.exists()) await file.delete();
                    await dbHelper.deleteSound(sound.id);
                    _loadSounds();
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNewSound,
        child: const Icon(Icons.add),
        tooltip: "Neuen Sound importieren",
      ),
    );
  }
}