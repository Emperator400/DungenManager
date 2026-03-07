import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/bestiary_viewmodel.dart';
import '../../viewmodels/campaign_viewmodel.dart';
import '../../viewmodels/character_editor_viewmodel.dart';
import '../../viewmodels/item_library_viewmodel.dart';
import '../../viewmodels/official_monsters_viewmodel.dart';
import '../../viewmodels/quest_library_viewmodel.dart';
import '../../viewmodels/session_list_for_campaign_viewmodel.dart';
import '../../viewmodels/sound_library_viewmodel.dart';
import '../../viewmodels/wiki_viewmodel.dart';

// Screens
import '../bestiary/bestiary_screen.dart';
import '../campaign/campaign_dashboard_screen.dart';
import '../items/item_library_screen.dart';
import '../lore/lore_keeper_screen.dart';
import '../bestiary/official_monsters_screen.dart';
import '../characters/pc_list_screen.dart';
import '../quests/quest_library_screen.dart';
import '../audio/sound_library_screen.dart';
import '../campaign/session_list_for_campaign_screen.dart';

/// Enhanced Main Navigation Screen
/// 
/// Zentrale Navigation für alle D&D Kampagnen-Management Funktionen
class EnhancedMainNavigationScreen extends StatelessWidget {
  final Campaign? campaign;
  
  const EnhancedMainNavigationScreen({
    Key? key, 
    this.campaign,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // CampaignViewModel von übergeordnetem Provider übernehmen
        if (campaign != null)
          ChangeNotifierProvider<CampaignViewModel>.value(
            value: context.read<CampaignViewModel>(),
          ),
        // Alle ViewModels registrieren
        ChangeNotifierProvider(create: (_) => QuestLibraryViewModel()),
        ChangeNotifierProvider(create: (_) => WikiViewModel()),
        ChangeNotifierProvider(create: (_) => ItemLibraryViewModel()),
        ChangeNotifierProvider(create: (_) => BestiaryViewModel()),
        ChangeNotifierProvider(create: (_) => SoundLibraryViewModel()),
        ChangeNotifierProvider(create: (_) => OfficialMonstersViewModel()),
      ],
      child: _MainNavigationLayout(campaign: campaign),
    );
  }
}

class _MainNavigationLayout extends StatelessWidget {
  final Campaign? campaign;
  
  const _MainNavigationLayout({Key? key, this.campaign}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          
          if (campaign != null) _buildCampaignSection(context, campaign!),
          _buildContentSection(context),
          _buildToolsSection(context),
          
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: DnDTheme.mysticalPurple,
      flexibleSpace: FlexibleSpaceBar(
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              campaign?.title ?? 'Dungeon Manager',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            if (campaign != null) ...[
              const SizedBox(height: 2),
              Text(
                'Kampagnen-Hub',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
        titlePadding: const EdgeInsets.only(left: 16, bottom: 8),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DnDTheme.mysticalPurple,
                DnDTheme.mysticalPurple.withOpacity(0.8),
              ],
            ),
          ),
        ),
      ),
      actions: [
        if (campaign != null)
          IconButton(
            icon: const Icon(Icons.play_circle, color: Colors.white),
            onPressed: () => _navigateToScreen(context, ScreenType.sessions, campaign: campaign),
            tooltip: 'Sessions',
          ),
        IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () => _showSettingsDialog(context),
          tooltip: 'Einstellungen',
        ),
      ],
    );
  }

  Widget _buildCampaignSection(BuildContext context, Campaign campaign) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              DnDTheme.ancientGold.withOpacity(0.1),
              DnDTheme.ancientGold.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: DnDTheme.ancientGold.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.campaign, color: DnDTheme.ancientGold, size: 20),
                const SizedBox(width: 6),
                Text(
                  'Aktuelle Kampagne',
                  style: DnDTheme.headline3.copyWith(
                    color: DnDTheme.ancientGold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CampaignInfoRow(
              icon: Icons.title,
              label: 'Name',
              value: campaign.title,
            ),
            const SizedBox(height: 6),
            _CampaignInfoRow(
              icon: Icons.description,
              label: 'Beschreibung',
              value: campaign.description?.isNotEmpty == true 
                  ? campaign.description! 
                  : 'Keine Beschreibung',
            ),
            const SizedBox(height: 6),
            _CampaignInfoRow(
              icon: Icons.calendar_today,
              label: 'Erstellt am',
              value: _formatDate(campaign.createdAt),
            ),
            const SizedBox(height: 12),
            _CampaignActionButtons(context, campaign),
          ],
        ),
      ),
    );
  }

  Widget _buildContentSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inhaltsbibliotheken',
              style: DnDTheme.headline3.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            
            if (campaign != null) _ContentListItem(
              title: 'Helden',
              subtitle: 'Charaktere erstellen & verwalten',
              icon: Icons.person,
              color: DnDTheme.emeraldGreen,
              onTap: () => _navigateToScreen(context, ScreenType.characters, campaign: campaign),
            ),
            _ContentListItem(
              title: 'Wiki',
              subtitle: 'Wissen & Lore',
              icon: Icons.menu_book,
              color: DnDTheme.mysticalPurple,
              onTap: () => _navigateToScreen(context, ScreenType.wiki),
            ),
            _ContentListItem(
              title: 'Items',
              subtitle: 'Ausrüstung',
              icon: Icons.inventory_2,
              color: DnDTheme.stoneGrey,
              onTap: () => _navigateToScreen(context, ScreenType.items),
            ),
            _ContentListItem(
              title: 'Bestiarium',
              subtitle: 'Monster & Kreaturen',
              icon: Icons.pets,
              color: DnDTheme.arcaneBlue,
              onTap: () => _navigateToScreen(context, ScreenType.bestiary),
            ),
            _ContentListItem(
              title: 'Sounds',
              subtitle: 'Audio Bibliothek',
              icon: Icons.music_note,
              color: DnDTheme.deepRed,
              onTap: () => _navigateToScreen(context, ScreenType.sounds),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsSection(BuildContext context) {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tools & Referenzen',
              style: DnDTheme.headline3.copyWith(
                color: Colors.white,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            _ContentListItem(
              title: 'Offizielle Monster',
              subtitle: '5e SRD Datenbank',
              icon: Icons.auto_awesome,
              color: DnDTheme.mysticalPurple,
              onTap: () => _navigateToScreen(context, ScreenType.monsters),
            ),
            _ContentListItem(
              title: 'Alle Kampagnen',
              subtitle: 'Kampagnenübersicht',
              icon: Icons.dashboard,
              color: DnDTheme.ancientGold,
              onTap: () => _navigateToScreen(context, ScreenType.campaigns),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Helper Widgets
// ============================================================================

class _CampaignInfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _CampaignInfoRow({
    Key? key,
    required this.icon,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: DnDTheme.ancientGold.withOpacity(0.7)),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: DnDTheme.ancientGold.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _CampaignActionButtons extends StatelessWidget {
  final BuildContext context;
  final Campaign campaign;

  const _CampaignActionButtons(
    this.context, 
    this.campaign, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _navigateToScreen(context, ScreenType.sessions, campaign: campaign),
            icon: const Icon(Icons.play_circle),
            label: const Text('Sessions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.infoBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _navigateToScreen(context, ScreenType.campaigns),
            icon: const Icon(Icons.edit),
            label: const Text('Bearbeiten'),
            style: OutlinedButton.styleFrom(
              foregroundColor: DnDTheme.ancientGold,
              side: BorderSide(color: DnDTheme.ancientGold),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}

class _ContentListItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ContentListItem({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.6), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceholderScreen extends StatelessWidget {
  final String title;

  const _PlaceholderScreen({Key? key, required this.title}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: DnDTheme.mysticalPurple,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.construction,
            size: 80,
            color: DnDTheme.ancientGold.withValues(alpha: 0.6),
          ),
          const SizedBox(height: DnDTheme.lg),
          Text(
            'In Arbeit',
            style: DnDTheme.headline2.copyWith(
              color: DnDTheme.ancientGold,
            ),
          ),
          const SizedBox(height: DnDTheme.sm),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Dieser Bereich wird aktuell überarbeitet.\nDemnächst verfügbar!',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Navigation & Helper Functions
// ============================================================================

enum ScreenType {
  campaigns,
  quests,
  wiki,
  characters,
  party,
  items,
  bestiary,
  sessions,
  sounds,
  monsters,
}

void _navigateToScreen(BuildContext context, ScreenType screenType, {Campaign? campaign}) {
  Widget screen;

  switch (screenType) {
    case ScreenType.campaigns:
      screen = ChangeNotifierProvider<CampaignViewModel>(
        create: (_) => CampaignViewModel(),
        child: const CampaignDashboardScreen(),
      );
      break;
    case ScreenType.quests:
      screen = const QuestLibraryScreen();
      break;
    case ScreenType.wiki:
      screen = const LoreKeeperScreen();
      break;
    case ScreenType.characters:
      if (campaign != null) {
        screen = ChangeNotifierProvider(
          create: (_) => CharacterEditorViewModel(),
          child: PlayerCharacterListScreen(campaign: campaign),
        );
      } else {
        screen = const _PlaceholderScreen(title: 'Helden - Keine Kampagne ausgewählt');
      }
      break;
    case ScreenType.party:
      screen = const _PlaceholderScreen(title: 'Gruppe');
      break;
    case ScreenType.items:
      screen = const ItemLibraryScreen();
      break;
    case ScreenType.bestiary:
      screen = const BestiaryScreen();
      break;
    case ScreenType.sessions:
      if (campaign != null) {
        screen = ChangeNotifierProvider<SessionListForCampaignViewModel>(
          create: (_) => SessionListForCampaignViewModel(),
          child: SessionListForCampaignScreen(campaign: campaign),
        );
      } else {
        screen = const _PlaceholderScreen(title: 'Sessions - Keine Kampagne ausgewählt');
      }
      break;
    case ScreenType.sounds:
      screen = const SoundLibraryScreen();
      break;
    case ScreenType.monsters:
      screen = const OfficialMonstersScreen();
      break;
  }

  Navigator.of(context).push(
    MaterialPageRoute(builder: (context) => screen),
  );
}

void _showSettingsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Einstellungen'),
      content: const Text('Einstellungen werden in zukünftigen Versionen verfügbar sein.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Unbekannt';
  return '${date.day}.${date.month}.${date.year}';
}
