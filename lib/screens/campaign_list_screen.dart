// lib/screens/campaign_list_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import 'edit_campaign_screen.dart'; 
import 'campaign_dashboard_screen.dart';

class CampaignListScreen extends StatefulWidget {
  const CampaignListScreen({super.key});

  @override
  State<CampaignListScreen> createState() => _CampaignListScreenState();
}

class _CampaignListScreenState extends State<CampaignListScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<Campaign>> _campaignsFuture;

  @override
  void initState() {
    super.initState();
    _refreshCampaigns();
  }

  void _refreshCampaigns() {
    setState(() {
      _campaignsFuture = dbHelper.getAllCampaigns();
    });
  }

  // NEUE METHODE: Zeigt den Bestätigungs-Dialog und löscht die Kampagne
  Future<void> _deleteCampaign(Campaign campaign) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Kampagne löschen?"),
        content: Text("Möchtest du die Kampagne '${campaign.title}' und ALLE zugehörigen Helden, Sitzungen, Szenen etc. wirklich endgültig löschen? Diese Aktion kann nicht rückgängig gemacht werden."),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Abbrechen")),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text("Endgültig Löschen", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await dbHelper.deleteCampaignAndAssociatedData(campaign.id);
      _refreshCampaigns();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Meine Kampagnen"),
      ),
      body: FutureBuilder<List<Campaign>>(
        future: _campaignsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center( /* ... "Keine Kampagnen"-Text ... */ );
          }
          final campaigns = snapshot.data!;
          return ListView.builder(
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.book, size: 40, color: Colors.brown),
                  title: Text(campaign.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(campaign.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => CampaignDashboardScreen(campaign: campaign),
                    ));
                  },
                  // GEÄNDERT: Ein sauberes Menü für Aktionen
                  trailing: PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (ctx) => EditCampaignScreen(campaignToEdit: campaign),
                        )).then((_) => _refreshCampaigns());
                      } else if (value == 'delete') {
                        _deleteCampaign(campaign);
                      }
                    },
                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                      const PopupMenuItem<String>(
                        value: 'edit',
                        child: ListTile(leading: Icon(Icons.edit_note), title: Text('Bearbeiten')),
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
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Neue Kampagne erstellen",
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => const EditCampaignScreen(),
          )).then((_) => _refreshCampaigns());
        },
      ),
    );
  }
}