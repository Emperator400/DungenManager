import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';

/// Wiederverwendbares Widget für die Kampagnen-Tabs
/// 
/// Zeigt die 5 Tabs für verschiedene Kampagnentypen
class CampaignTabsWidget extends StatelessWidget implements PreferredSizeWidget {
  final TabController tabController;

  const CampaignTabsWidget({
    super.key,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    return TabBar(
      controller: tabController,
      tabs: const [
        Tab(icon: Icon(Icons.dashboard), text: 'Übersicht'),
        Tab(icon: Icon(Icons.home), text: 'Homebrew'),
        Tab(icon: Icon(Icons.book), text: 'Module'),
        Tab(icon: Icon(Icons.map), text: 'Paths'),
        Tab(icon: Icon(Icons.flash_on), text: 'One-Shots'),
      ],
      labelColor: Theme.of(context).tabBarTheme.labelColor ?? DnDTheme.ancientGold,
      unselectedLabelColor: Theme.of(context).tabBarTheme.unselectedLabelColor ?? Colors.grey[400],
      indicatorColor: Theme.of(context).tabBarTheme.indicatorColor ?? DnDTheme.ancientGold,
      indicatorSize: TabBarIndicatorSize.tab,
      indicatorWeight: 3,
      dividerColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      labelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 14,
      ),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.normal,
        fontSize: 14,
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + 48);
}
