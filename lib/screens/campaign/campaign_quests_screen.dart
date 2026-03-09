import 'package:flutter/material.dart';
import '../../models/campaign.dart';
import '../../widgets/campaign_quests_tab.dart';
import '../../theme/dnd_theme.dart';

/// Screen zur Verwaltung von Quests innerhalb einer Kampagne
/// Wraps the CampaignQuestsTab widget in a Scaffold
class CampaignQuestsScreen extends StatelessWidget {
  final Campaign campaign;

  const CampaignQuestsScreen({
    Key? key,
    required this.campaign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Quests: ${campaign.title}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: DnDTheme.dungeonBlack,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DnDTheme.dungeonBlack,
                DnDTheme.stoneGrey.withOpacity(0.3),
              ],
            ),
          ),
        ),
      ),
      body: CampaignQuestsTab(campaign: campaign),
    );
  }
}