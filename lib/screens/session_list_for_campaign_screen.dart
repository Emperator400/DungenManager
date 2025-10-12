// lib/screens/session_list_for_campaign_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import 'edit_session_screen.dart';
import 'active_session_screen.dart';

class SessionListForCampaignScreen extends StatefulWidget {
  final Campaign campaign;
  const SessionListForCampaignScreen({super.key, required this.campaign});

  @override
  State<SessionListForCampaignScreen> createState() => _SessionListForCampaignScreenState();
}

class _SessionListForCampaignScreenState extends State<SessionListForCampaignScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Session>> _sessionsFuture;

  @override
  void initState() {
    super.initState();
    _sessionsFuture = dbHelper.getSessionsForCampaign(widget.campaign.id);
  }

  void _refreshSessionList() {
    setState(() {
      _sessionsFuture = dbHelper.getSessionsForCampaign(widget.campaign.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Sitzungen: ${widget.campaign.title}")),
      body: FutureBuilder<List<Session>>(
        future: _sessionsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final sessions = snapshot.data ?? [];
          return ListView.builder(
            itemCount: sessions.length,
            itemBuilder: (context, index) {
              final session = sessions[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.map_outlined, size: 40),
                  title: Text(session.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => ActiveSessionScreen(session: session, campaign: widget.campaign))),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () async {
                      // KORREKTUR HIER: Wir übergeben das ganze Session-Objekt
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (ctx) => EditSessionScreen(session: session),
                      ));
                      _refreshSessionList();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Neue Sitzung erstellen",
        child: const Icon(Icons.add),
        onPressed: () async {
          // Wir erstellen erst ein leeres Session-Objekt...
          final newSession = Session(campaignId: widget.campaign.id, title: "Neue Sitzung");
          await dbHelper.insertSession(newSession);
          // ...und öffnen dann den Editor dafür.
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => EditSessionScreen(session: newSession),
          ));
          _refreshSessionList();
        },
      ),
    );
  }
}