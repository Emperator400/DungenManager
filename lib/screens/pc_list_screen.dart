// lib/screens/pc_list_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/player_character.dart';
import 'edit_pc_screen.dart';

class PlayerCharacterListScreen extends StatefulWidget {
  final Campaign campaign;

  const PlayerCharacterListScreen({super.key, required this.campaign});

  @override
  State<PlayerCharacterListScreen> createState() => _PlayerCharacterListScreenState();
}

class _PlayerCharacterListScreenState extends State<PlayerCharacterListScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<PlayerCharacter>> _pcsFuture;

  @override
  void initState() {
    super.initState();
    _pcsFuture = dbHelper.getPlayerCharactersForCampaign(widget.campaign.id);
  }

  void _refreshPcList() {
    setState(() {
      _pcsFuture = dbHelper.getPlayerCharactersForCampaign(widget.campaign.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Helden: ${widget.campaign.title}"),
      ),
      body: FutureBuilder<List<PlayerCharacter>>(
        future: _pcsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Keine Helden für diese Kampagne erstellt."));
          }
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
                      _refreshPcList();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Neuen Helden hinzufügen",
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => EditPlayerCharacterScreen(campaignId: widget.campaign.id),
          ));
          _refreshPcList();
        },
      ),
    );
  }
}