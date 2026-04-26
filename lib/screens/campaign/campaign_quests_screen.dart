import 'package:flutter/material.dart';
import '../../models/campaign.dart';
import '../../theme/app_theme.dart';
import '../../widgets/campaign/campaign_quests_tab.dart';

class CampaignQuestsScreen extends StatelessWidget {
  const CampaignQuestsScreen({super.key, required this.campaign});

  final Campaign campaign;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(
          'Quests: ${campaign.title}',
          style: TextStyle(color: C.amber, fontWeight: FontWeight.bold),
        ),
        backgroundColor: C.bgPanel,
        elevation: 0,
      ),
      body: CampaignQuestsTab(campaign: campaign),
    );
  }
}
