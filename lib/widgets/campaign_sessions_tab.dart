// lib/widgets/campaign_sessions_tab.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import '../screens/edit_session_screen.dart';
import '../screens/active_session_screen.dart';

class CampaignSessionsTab extends StatefulWidget {
  final Campaign campaign;
  const CampaignSessionsTab({super.key, required this.campaign});

  @override
  State<CampaignSessionsTab> createState() => CampaignSessionsTabState();
}

class CampaignSessionsTabState extends State<CampaignSessionsTab> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Session>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    loadSessions();
  }

  void loadSessions() {
    setState(() {
      _sessionsFuture = dbHelper.getSessionsForCampaign(widget.campaign.id);
    });
  }

  // NEUE METHODE: Zeigt einen Bestätigungs-Dialog und löscht die Sitzung
  Future<void> _deleteSession(Session session) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Sitzung löschen?"),
        content: Text("Möchtest du die Sitzung '${session.title}' und alle zugehörigen Szenen wirklich endgültig löschen?"),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Abbrechen")),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Löschen", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await dbHelper.deleteSession(session.id);
      // TODO: Auch alle Szenen dieser Session löschen
      loadSessions();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Session>>(
      future: _sessionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Keine Sitzungen für diese Kampagne erstellt."));
        }
        final sessions = snapshot.data!;
        return ListView.builder(
          itemCount: sessions.length,
          itemBuilder: (context, index) {
            final session = sessions[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.map_outlined, size: 40),
                title: Text(session.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (ctx) => ActiveSessionScreen(session: session, campaign: widget.campaign),
                  ));
                },
                // Das Trailing ist jetzt ein Pop-up-Menü für mehr Aktionen
                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => EditSessionScreen(session: session),
                      )).then((_) => loadSessions());
                    } else if (value == 'delete') {
                      _deleteSession(session);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'edit',
                      child: ListTile(leading: Icon(Icons.edit_note), title: Text('Planen')),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(leading: Icon(Icons.delete_forever, color: Colors.red), title: Text('Löschen', style: TextStyle(color: Colors.red))),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}