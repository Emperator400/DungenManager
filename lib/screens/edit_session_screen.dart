// lib/screens/edit_session_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/session.dart';
import '../models/scene.dart';
import 'edit_scene_screen.dart';

class EditSessionScreen extends StatefulWidget {
  final Session session;
  const EditSessionScreen({super.key, required this.session});

  @override
  State<EditSessionScreen> createState() => _EditSessionScreenState();
}

class _EditSessionScreenState extends State<EditSessionScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Scene>> _scenesFuture;
  
  // NEU: Ein Controller für den Session-Titel
  late TextEditingController _titleController;
  late Session _currentSession;

  @override
  void initState() {
    super.initState();
    _currentSession = widget.session;
    _titleController = TextEditingController(text: _currentSession.title);
    _loadScenes();
  }

  void _loadScenes() {
    setState(() {
      _scenesFuture = dbHelper.getScenesForSession(widget.session.id);
    });
  }

  // NEUE METHODE: Speichert Änderungen am Session-Titel
  void _saveSessionTitle() async {
    final updatedSession = Session(
      id: _currentSession.id,
      campaignId: _currentSession.campaignId,
      title: _titleController.text,
    );
    await dbHelper.updateSession(updatedSession);
    setState(() {
      _currentSession = updatedSession;
    });
    // Optional: Feedback für den Nutzer
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Titel gespeichert."), duration: Duration(seconds: 1)));
  }

  void _addScene() async {
    final newScene = Scene(sessionId: widget.session.id, orderIndex: 999);
    await dbHelper.insertScene(newScene);
    _loadScenes();
  }
  
  void _onReorder(List<Scene> scenes, int oldIndex, int newIndex) async {
    setState(() {
      if (newIndex > oldIndex) newIndex -= 1;
      final Scene item = scenes.removeAt(oldIndex);
      scenes.insert(newIndex, item);
    });
    await dbHelper.updateSceneOrder(scenes);
    _loadScenes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plane: ${_currentSession.title}"),
        // NEU: Ein Speicher-Knopf für den Titel
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            tooltip: "Sitzungs-Titel speichern",
            onPressed: _saveSessionTitle,
          ),
        ],
      ),
      body: Column( // Wir packen alles in eine Column
        children: [
          // NEU: Das Textfeld für den Titel
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Titel der Sitzung"),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          const Divider(),
          // Die Liste der Szenen füllt den Rest des Platzes
          Expanded(
            child: FutureBuilder<List<Scene>>(
              future: _scenesFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final scenes = snapshot.data!;
                return ReorderableListView(
                  padding: const EdgeInsets.all(8.0),
                  onReorder: (oldIndex, newIndex) => _onReorder(scenes, oldIndex, newIndex),
                  children: scenes.map((scene) => Card(
                    key: ValueKey(scene.id),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle),
                      title: Text(scene.title),
                      subtitle: Text(scene.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () async {
                          await dbHelper.deleteScene(scene.id);
                          _loadScenes();
                        },
                      ),
                      onTap: () async {
                        await Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => EditSceneScreen(scene: scene),
                        ));
                        _loadScenes();
                      },
                    ),
                  )).toList(),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addScene,
        tooltip: 'Neue Szene',
        child: const Icon(Icons.add),
      ),
    );
  }
}