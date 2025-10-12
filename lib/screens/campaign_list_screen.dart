// lib/screens/campaign_list_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import 'edit_campaign_screen.dart'; 
import 'campaign_dashboard_screen.dart'; // Dieser Import ist jetzt wichtig

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
    _campaignsFuture = dbHelper.getAllCampaigns();
  }

  void _refreshCampaigns() {
    setState(() {
      _campaignsFuture = dbHelper.getAllCampaigns();
    });
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
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Keine Kampagnen erstellt."),
                  SizedBox(height: 10),
                  Text("Klicke auf '+' um zu beginnen!", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          final campaigns = snapshot.data!;
          return ListView.builder(
            itemCount: campaigns.length,
            itemBuilder: (context, index) {
              final campaign = campaigns[index];
              return Card( // Wir packen die ListTile in eine Card für schöneres Design
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.book, size: 40, color: Colors.brown),
                  title: Text(campaign.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(campaign.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: "Kampagne bearbeiten",
                    onPressed: (){
                       Navigator.of(context).push(MaterialPageRoute(
                         builder: (ctx) => EditCampaignScreen(campaignToEdit: campaign),
                       )).then((_) => _refreshCampaigns());
                    },
                  ),
                  // ==========================================================
                  // HIER IST DIE HINZUGEFÜGTE FUNKTION
                  // ==========================================================
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => CampaignDashboardScreen(campaign: campaign),
                    ));
                  },
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