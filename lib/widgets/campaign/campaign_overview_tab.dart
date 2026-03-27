// lib/widgets/campaign/campaign_overview_tab.dart
import 'package:flutter/material.dart';
import '../../models/campaign.dart';
import '../../screens/bestiary/bestiary_screen.dart';
import '../../screens/lore/lore_keeper_screen.dart';
import '../../screens/quests/quest_library_screen.dart';
import '../../screens/items/item_library_screen.dart';
import '../../screens/audio/sound_library_screen.dart';


class CampaignOverviewTab extends StatelessWidget {
  final Campaign campaign;
  const CampaignOverviewTab({super.key, required this.campaign});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Card(
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Kampagnen-Übersicht", style: Theme.of(context).textTheme.titleLarge),
                const Divider(height: 20),
                Text(campaign.description),
              ],
            ),
          ),
        ),
        const Padding(padding: EdgeInsets.symmetric(vertical: 16.0), child: Divider()),
        Text("Globale Bibliotheken", style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey)),
        const SizedBox(height: 8),
        _buildDashboardTile(context, Icons.book, "Bestiarium", "Alle Monster & NSCs", () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const BestiaryScreen()))),
        _buildDashboardTile(context, Icons.landscape, "Lore Keeper", "Orte, Gegenstände & Weltenwissen", () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const LoreKeeperScreen()))),
        _buildDashboardTile(context, Icons.flag, "Quest-Bibliothek", "Vorlagen für Quests", () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const QuestLibraryScreen()))),
        _buildDashboardTile(context, Icons.shield, "Ausrüstungskammer", "Alle Gegenstände verwalten", () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const ItemLibraryScreen()))),
        _buildDashboardTile(context, Icons.graphic_eq, "Sound-Bibliothek", "Musik & Effekte verwalten", () => Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const SoundLibraryScreen()))),
 
      ],
    );
  }

  Widget _buildDashboardTile(BuildContext context, IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: Icon(icon, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
        trailing: const Icon(Icons.arrow_forward_ios),
      ),
    );
  }
}