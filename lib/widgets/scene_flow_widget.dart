// lib/widgets/scene_flow_widget.dart
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../database/database_helper.dart';
import '../models/scene.dart';
import '../models/quest.dart';
import '../models/wiki_entry.dart';
import '../screens/edit_campaign_quest_screen.dart';
import '../screens/edit_wiki_entry_screen.dart';

class SceneFlowWidget extends StatefulWidget {
  final String sessionId;
  final String campaignId;
   final VoidCallback onDataChanged;

  const SceneFlowWidget({
    super.key, 
    required this.sessionId, 
    required this.campaignId,
    required this.onDataChanged,
  });

  @override
  State<SceneFlowWidget> createState() => SceneFlowWidgetState();
}

class SceneFlowWidgetState extends State<SceneFlowWidget> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Scene>> _scenesFuture;

  @override
  void initState() {
    super.initState();
    _scenesFuture = dbHelper.getScenesForSession(widget.sessionId);
  }

  @override
  Widget build(BuildContext context) {
    final markdownStyle = MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      blockquote: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey[400], fontStyle: FontStyle.italic),
      blockquoteDecoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(4),
        border: Border(left: BorderSide(width: 5, color: Theme.of(context).primaryColor)),
      ),
    );

    return FutureBuilder<List<Scene>>(
      future: _scenesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final scenes = snapshot.data!;
        if (scenes.isEmpty) return const Center(child: Text("Für diese Sitzung wurden keine Szenen geplant."));

        return ListView.builder(
          itemCount: scenes.length,
          itemBuilder: (context, index) {
            final scene = scenes[index];
            return ExpansionTile(
              title: Text(scene.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              childrenPadding: const EdgeInsets.all(12),
              expandedCrossAxisAlignment: CrossAxisAlignment.start,
              children: [
                MarkdownBody(data: scene.description, styleSheet: markdownStyle),
                _buildLinkedEntries(context, scene.linkedWikiEntryIds),
                _buildLinkedQuests(context, scene.linkedQuestIds),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildLinkedEntries(BuildContext context, List<String> entryIds) {
    if (entryIds.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text("Verknüpfte NPCs/Orte:", style: TextStyle(fontWeight: FontWeight.bold)),
        FutureBuilder<List<WikiEntry>>(
          future: dbHelper.getWikiEntriesByIds(entryIds),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final entries = snapshot.data!;
            if (entries.isEmpty) return const SizedBox.shrink();
            return Wrap(
              spacing: 8.0,
              runSpacing: 4.0,
              children: entries.map((entry) => ActionChip(
                avatar: Icon(_getIconForType(entry.entryType), size: 16),
                label: Text(entry.title),
                onPressed: () => _showEntryPreviewDialog(context, entry),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLinkedQuests(BuildContext context, List<String> questIds) {
    if (questIds.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const Text("Verknüpfte Quests:", style: TextStyle(fontWeight: FontWeight.bold)),
        FutureBuilder<List<Quest>>(
          future: dbHelper.getQuestsByIds(questIds),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            return Wrap(
              spacing: 8.0,
              children: snapshot.data!.map((quest) => ActionChip(
                avatar: const Icon(Icons.flag_outlined, size: 16),
                label: Text(quest.title),
                onPressed: () => _showQuestActionDialog(context, quest),
              )).toList(),
            );
          },
        ),
      ],
    );
  }
  
 void _showQuestActionDialog(BuildContext context, Quest quest) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(quest.title),
        content: Text(quest.description),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text("Schliessen")),
          ElevatedButton(
            child: const Text("Quest annehmen"),
            onPressed: () async {
              await dbHelper.updateCampaignQuest(widget.campaignId, quest.id, QuestStatus.aktiv, '');
              Navigator.of(ctx).pop();
              // KORREKTUR: Rufe den Callback auf, anstatt zu versuchen, den Parent zu finden
              widget.onDataChanged();
            },
          ),
        ],
      ),
    );
  }

  void _showEntryPreviewDialog(BuildContext context, WikiEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(children: [
          Icon(_getIconForType(entry.entryType), size: 24),
          const SizedBox(width: 10),
          Expanded(child: Text(entry.title)),
        ]),
        content: SingleChildScrollView(child: Text(entry.content)),
        actions: <Widget>[
          TextButton(child: const Text('Bearbeiten'), onPressed: () {
            Navigator.of(ctx).pop();
            Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditWikiEntryScreen(entryToEdit: entry)));
          }),
          TextButton(child: const Text('Schliessen'), onPressed: () => Navigator.of(ctx).pop()),
        ],
      ),
    );
  }

  IconData _getIconForType(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person: return Icons.person;
      case WikiEntryType.Place: return Icons.location_on;
      case WikiEntryType.Lore: return Icons.menu_book;
    }
  }
}