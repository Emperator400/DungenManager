// lib/widgets/sounds_tab.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:audioplayers/audioplayers.dart';
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
  final AudioPlayer _previewPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _loadSounds();
  }

  @override
  void dispose() {
    _previewPlayer.dispose();
    super.dispose();
  }

  void _loadSounds() {
    setState(() {
      _soundsFuture = dbHelper.getAllSounds();
    });
  }

  Future<void> _previewSound(Sound sound) async {
    await _previewPlayer.stop();
    await _previewPlayer.play(DeviceFileSource(sound.filePath));
  }

   Future<void> _addNewSound() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio);

    // WICHTIGE PRÜFUNG 1: Existiert der Bildschirm noch nach der Dateiauswahl?
    if (!mounted || result == null || result.files.single.path == null) return;

    File sourceFile = File(result.files.single.path!);
    
    final directory = await getApplicationDocumentsDirectory();
    
    // WICHTIGE PRÜFUNG 2: Existiert der Bildschirm noch nach der Ordnersuche?
    if (!mounted) return;

    final String fileName = p.basename(sourceFile.path);
    final String destinationPath = p.join(directory.path, 'sounds', fileName);
    final destinationDirectory = Directory(p.join(directory.path, 'sounds'));

    if (!await destinationDirectory.exists()) {
      await destinationDirectory.create(recursive: true);
    }
    
    final File destinationFile = await sourceFile.copy(destinationPath);
    
    // WICHTIGE PRÜFUNG 3: Existiert der Bildschirm noch nach dem Dateikopieren?
    if (!mounted) return;

    final soundDetails = await _showSoundDetailsDialog();

    // WICHTIGE PRÜFUNG 4: Existiert der Bildschirm noch nach dem Dialog?
    if (!mounted || soundDetails == null) return;

    final newSound = Sound(
      name: soundDetails['name'],
      filePath: destinationFile.path,
      soundType: soundDetails['type'],
      description: soundDetails['description'],
    );
    await dbHelper.insertSound(newSound);
    _loadSounds(); // setState() ist hier sicher, da kein 'await' mehr folgt
  }


  Future<Map<String, dynamic>?> _showSoundDetailsDialog({Sound? sound}) {
    final nameController = TextEditingController(text: sound?.name ?? '');
    final descriptionController = TextEditingController(text: sound?.description ?? '');
    SoundType selectedType = sound?.soundType ?? SoundType.Ambiente;

    return showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(sound == null ? "Neuen Sound anlegen" : "Sound bearbeiten"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nameController, decoration: const InputDecoration(labelText: "Name des Sounds")),
                  const SizedBox(height: 16),
                  TextField(controller: descriptionController, decoration: const InputDecoration(labelText: "Beschreibung (z.B. wofür er ist)")),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<SoundType>(
                    value: selectedType,
                    decoration: const InputDecoration(labelText: "Sound-Typ"),
                    items: SoundType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.toString().split('.').last))).toList(),
                    onChanged: (val) => setDialogState(() => selectedType = val!),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Abbrechen")),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    Navigator.of(context).pop({'name': nameController.text, 'type': selectedType, 'description': descriptionController.text});
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
                leading: IconButton(
                  icon: const Icon(Icons.play_arrow),
                  tooltip: "Vorschau abspielen",
                  onPressed: () => _previewSound(sound),
                ),
                title: Text(sound.name),
                subtitle: Text(sound.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                  onPressed: () async {
                    final file = File(sound.filePath);
                    if (await file.exists()) await file.delete();
                    await dbHelper.deleteSound(sound.id);
                    _loadSounds();
                  },
                ),
                onTap: () async {
                  final soundDetails = await _showSoundDetailsDialog(sound: sound);
                   if (!mounted || soundDetails == null) return;

                   final updatedSound = Sound(
                    id: sound.id,
                    filePath: sound.filePath,
                    name: soundDetails['name'],
                    soundType: soundDetails['type'],
                    description: soundDetails['description'],
                  );
                  await dbHelper.updateSound(updatedSound);
                  _loadSounds();
                },
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