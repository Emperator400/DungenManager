// lib/widgets/campaign_heroes_tab.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/player_character.dart';
import '../screens/edit_pc_screen.dart';

class CampaignHeroesTab extends StatefulWidget {
  final Campaign campaign;
  const CampaignHeroesTab({super.key, required this.campaign});

  @override
  State<CampaignHeroesTab> createState() => CampaignHeroesTabState();
}

class CampaignHeroesTabState extends State<CampaignHeroesTab> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<PlayerCharacter>> _pcsFuture;

  @override
  void initState() {
    super.initState();
    loadPcs();
  }

  void loadPcs() {
    setState(() {
      _pcsFuture = dbHelper.getPlayerCharactersForCampaign(widget.campaign.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<PlayerCharacter>>(
      future: _pcsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("Keine Helden für diese Kampagne erstellt."));
        
        final pcs = snapshot.data!;
        return ListView.builder(
          itemCount: pcs.length,
          itemBuilder: (context, index) {
            final pc = pcs[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: const Icon(Icons.account_circle, size: 40),
                title: Text(pc.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${pc.className}, gespielt von ${pc.playerName}"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () async {
                    await Navigator.of(context).push(MaterialPageRoute(
                      builder: (ctx) => EditPlayerCharacterScreen(campaignId: widget.campaign.id, pcToEdit: pc),
                    ));
                    loadPcs();
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}