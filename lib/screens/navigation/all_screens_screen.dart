import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';

// Import aller Screens
import '../campaign/campaign_selection_screen.dart';
import '../campaign/campaign_dashboard_screen.dart';
import 'main_navigation_screen.dart';

// Quest Screens
import '../quests/quest_library_screen.dart';
import '../quests/add_quest_screen.dart';
import '../quests/edit_quest_screen.dart';
import '../quests/edit_campaign_quest_screen.dart';
import '../quests/link_quest_screen.dart';

// Character Screens
import '../characters/character_editor_screen.dart';
import '../characters/edit_pc_screen.dart';
import '../characters/pc_list_screen.dart';
import '../characters/select_character_screen.dart';

// Bestiary Screens
import '../bestiary/bestiary_screen.dart';
import '../bestiary/edit_creature_screen.dart';
import '../bestiary/official_monsters_screen.dart';

// Item Screens
import '../items/item_library_screen.dart';
import '../items/edit_item_screen.dart';
import '../items/add_item_screen.dart';

// Lore Screens
import '../lore/lore_keeper_screen.dart';
import '../lore/edit_wiki_entry_screen.dart';
import '../lore/link_entry_screen.dart';
import '../lore/link_wiki_entries_screen.dart';

// Session Screens
import '../session/session_list_screen.dart';
import '../session/active_session_screen.dart';
import '../session/edit_session_screen.dart';
import '../session/encounter_setup_screen.dart';
import '../session/initiative_tracker_screen.dart';

// Audio Screens
import '../audio/sound_library_screen.dart';
import '../audio/add_sound_screen.dart';
import '../audio/edit_sound_screen.dart';

// Debug Screens
import '../debug/screen_graph_visualization_screen.dart';

class AllScreensScreen extends StatelessWidget {
  const AllScreensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      appBar: AppBar(
        title: Text(
          'Alle Screens - UI Testing',
          style: DnDTheme.headline2.copyWith(color: DnDTheme.ancientGold),
        ),
        backgroundColor: DnDTheme.stoneGrey,
        foregroundColor: DnDTheme.ancientGold,
        elevation: 4,
        iconTheme: const IconThemeData(color: DnDTheme.ancientGold),
      ),
      body: ListView(
        padding: const EdgeInsets.all(DnDTheme.md),
        children: [
          _buildSectionHeader('🎯 KAMPAGNEN-MANAGEMENT'),
          _buildCampaignScreens(context),
          
          _buildSectionHeader('📜 QUEST-MANAGEMENT'),
          _buildQuestScreens(context),
          
          _buildSectionHeader('📚 WIKI/LORE MANAGEMENT'),
          _buildWikiScreens(context),
          
          _buildSectionHeader('🧑‍🤝‍🧑 CHARACTER MANAGEMENT'),
          _buildCharacterScreens(context),
          
          _buildSectionHeader('⚔️ BESTIARY & MONSTER MANAGEMENT'),
          _buildBestiaryScreens(context),
          
          _buildSectionHeader('🎒 ITEM MANAGEMENT'),
          _buildItemScreens(context),
          
          _buildSectionHeader('🎵 AUDIO MANAGEMENT'),
          _buildAudioScreens(context),
          
          _buildSectionHeader('🎮 SESSION MANAGEMENT'),
          _buildSessionScreens(context),
          
          _buildSectionHeader('🧑‍🤝‍🧑 CHARACTER MANAGEMENT TESTING'),
          _buildCharacterTestingScreens(context),
          
          _buildSectionHeader('🔧 MAIN NAVIGATION'),
          _buildMainNavigationScreens(context),
          
          _buildSectionHeader('🔍 DEBUG TOOLS'),
          _buildDebugScreens(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: DnDTheme.md),
      child: Container(
        padding: const EdgeInsets.all(DnDTheme.md),
        decoration: DnDTheme.getMysticalBorder(borderColor: DnDTheme.mysticalPurple),
        child: Text(
          title,
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.mysticalPurple,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildScreenCard({
    required BuildContext context,
    required String title,
    required String description,
    required VoidCallback onTap,
    bool needsParams = false,
    String? paramWarning,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.sm),
      decoration: DnDTheme.getFantasyCardDecoration(
        borderColor: needsParams ? DnDTheme.warningOrange : DnDTheme.emeraldGreen,
      ),
      child: ListTile(
        title: Text(
          title,
          style: DnDTheme.headline3.copyWith(
            color: needsParams ? DnDTheme.warningOrange : DnDTheme.emeraldGreen,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: DnDTheme.bodyText2,
            ),
            if (needsParams && paramWarning != null) ...[
              const SizedBox(height: DnDTheme.xs),
              Text(
                paramWarning,
                style: DnDTheme.bodyText2.copyWith(
                  color: DnDTheme.warningOrange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          needsParams ? Icons.warning : Icons.play_arrow,
          color: needsParams ? DnDTheme.warningOrange : DnDTheme.emeraldGreen,
          size: 28,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildCampaignScreens(BuildContext context) {
    return Column(
      children: [
        _buildScreenCard(
          context: context,
          title: 'Campaign Selection',
          description: 'Screen zur Auswahl einer Kampagne',
          onTap: () => _navigateToScreen(context, () => const CampaignSelectionScreen()),
        ),
        _buildScreenCard(
          context: context,
          title: 'Campaign Dashboard',
          description: 'Zentrale Verwaltung aller Kampagnen',
          onTap: () => _navigateToScreen(context, () => const CampaignDashboardScreen()),
        ),
      ],
    );
  }

  Widget _buildQuestScreens(BuildContext context) {
    return Column(
      children: [
        _buildScreenCard(
          context: context,
          title: 'Quest Library',
          description: 'Verwaltung aller Quests',
          onTap: () => _navigateToScreen(context, () => const QuestLibraryScreen()),
        ),
        _buildScreenCard(
          context: context,
          title: 'Add Quest',
          description: 'Quest zur Kampagne hinzufügen',
          onTap: () => _placeholderScreen('Add Quest - Needs Campaign ID'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt campaignId Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Edit Quest',
          description: 'Quest bearbeiten',
          onTap: () => _placeholderScreen('Edit Quest - Needs Quest'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Quest Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Edit Campaign Quest',
          description: 'Kampagnen-Quest bearbeiten',
          onTap: () => _placeholderScreen('Edit Campaign Quest - Needs Params'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt campaignId und questId Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Link Quest',
          description: 'Quests verlinken',
          onTap: () => _placeholderScreen('Link Quest - Needs Params'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Parameter',
        ),
      ],
    );
  }

  Widget _buildWikiScreens(BuildContext context) {
    return Column(
      children: [
        _buildScreenCard(
          context: context,
          title: 'Lore Keeper',
          description: 'Wiki und Lore-Verwaltung',
          onTap: () => _navigateToScreen(context, () => const LoreKeeperScreen()),
        ),
        _buildScreenCard(
          context: context,
          title: 'Edit Wiki Entry',
          description: 'Wiki-Eintrag bearbeiten',
          onTap: () => _placeholderScreen('Edit Wiki Entry - Needs Entry'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Entry Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Link Entry',
          description: 'Wiki-Einträge verlinken',
          onTap: () => _placeholderScreen('Link Entry - Needs Params'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Link Wiki Entries',
          description: 'Mehrere Einträge verlinken',
          onTap: () => _placeholderScreen('Link Wiki Entries - Needs Params'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Parameter',
        ),
      ],
    );
  }

  Widget _buildCharacterScreens(BuildContext context) {
    return Column(
      children: [
        _buildScreenCard(
          context: context,
          title: 'Character Editor',
          description: 'Charakter-Editor',
          onTap: () => _placeholderScreen('Character Editor - Needs Character'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Character Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Edit PC',
          description: 'Player Character bearbeiten',
          onTap: () => _placeholderScreen('Edit PC - Needs Character'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Character Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'PC List',
          description: 'Liste aller Player Characters',
          onTap: () => _placeholderScreen('PC List - Needs Campaign'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Campaign Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Select Character',
          description: 'Charakter auswählen',
          onTap: () => _navigateToScreen(context, () => const SelectCharacterScreen()),
        ),
      ],
    );
  }

  Widget _buildBestiaryScreens(BuildContext context) {
    return Column(
      children: [
        _buildScreenCard(
          context: context,
          title: 'Bestiary',
          description: 'Monster-Bestiarium',
          onTap: () => _navigateToScreen(context, () => const BestiaryScreen()),
        ),
        _buildScreenCard(
          context: context,
          title: 'Edit Creature',
          description: 'Kreatur bearbeiten',
          onTap: () => _placeholderScreen('Edit Creature - Needs Creature'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Creature Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Official Monsters',
          description: 'Offizielle 5e Monster',
          onTap: () => _navigateToScreen(context, () => const OfficialMonstersScreen()),
        ),
      ],
    );
  }

  Widget _buildItemScreens(BuildContext context) {
    return Column(
      children: [
        _buildScreenCard(
          context: context,
          title: 'Item Library',
          description: 'Item-Bibliothek',
          onTap: () => _navigateToScreen(context, () => const ItemLibraryScreen()),
        ),
        _buildScreenCard(
          context: context,
          title: 'Edit Item',
          description: 'Item bearbeiten',
          onTap: () => _placeholderScreen('Edit Item - Needs Item'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Item Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Add Item',
          description: 'Neues Item hinzufügen',
          onTap: () => _placeholderScreen('Add Item - Needs Campaign'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Campaign Parameter',
        ),
      ],
    );
  }

  Widget _buildAudioScreens(BuildContext context) {
    return Column(
      children: [
        _buildScreenCard(
          context: context,
          title: 'Sound Library',
          description: 'Audio-Bibliothek',
          onTap: () => _navigateToScreen(context, () => const SoundLibraryScreen()),
        ),
        _buildScreenCard(
          context: context,
          title: 'Add Sound',
          description: 'Neues Audio hinzufügen',
          onTap: () => _navigateToScreen(context, () => const AddSoundScreen()),
        ),
        _buildScreenCard(
          context: context,
          title: 'Edit Sound',
          description: 'Audio bearbeiten',
          onTap: () => _placeholderScreen('Edit Sound - Needs Sound'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Sound Parameter',
        ),
      ],
    );
  }

  Widget _buildSessionScreens(BuildContext context) {
    return Column(
      children: [
        _buildScreenCard(
          context: context,
          title: 'Session List',
          description: 'Liste aller Sessions',
          onTap: () => _navigateToScreen(context, () => const SessionListScreen()),
        ),
        _buildScreenCard(
          context: context,
          title: 'Active Session',
          description: 'Aktive Session',
          onTap: () => _placeholderScreen('Active Session - Needs Session'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Session Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Edit Session',
          description: 'Session bearbeiten',
          onTap: () => _placeholderScreen('Edit Session - Needs Session'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Session Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Encounter Setup',
          description: 'Begegnung einrichten',
          onTap: () => _placeholderScreen('Encounter Setup - Needs Session'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Session Parameter',
        ),
        _buildScreenCard(
          context: context,
          title: 'Initiative Tracker',
          description: 'Initiative-Tracker',
          onTap: () => _placeholderScreen('Initiative Tracker - Needs Session'),
          needsParams: true,
          paramWarning: '⚠️ Benötigt Session Parameter',
        ),
      ],
    );
  }

  Widget _buildCharacterTestingScreens(BuildContext context) {
    return Column(
      children: [
        _buildScreenCard(
          context: context,
          title: '⚔️ Combat Testing Arena',
          description: 'Test-Bereich für Kampf-Mechaniken und Initiative-Systeme',
          onTap: () => _navigateToScreen(context, () => _combatTestingArena()),
          needsParams: false,
        ),
        _buildScreenCard(
          context: context,
          title: '🎒 Inventory Management Test',
          description: 'Testing-Screen für Item-Management',
          onTap: () => _navigateToScreen(context, () => _inventoryManagementTest()),
          needsParams: false,
        ),
      ],
    );
  }

  Widget _buildMainNavigationScreens(BuildContext context) {
    return Column(
      children: [
        _buildScreenCard(
          context: context,
          title: 'Enhanced Main Navigation',
          description: 'Zentrale Navigation mit allen Hauptbereichen',
          onTap: () => _navigateToScreen(context, () => const EnhancedMainNavigationScreen()),
        ),
      ],
    );
  }

  Widget _buildDebugScreens(BuildContext context) {
    return Column(
      children: [
        _buildScreenCard(
          context: context,
          title: 'Screen Graph Visualization',
          description: 'Visualisierung aller Screens und deren Beziehungen',
          onTap: () => _navigateToScreen(context, () => const ScreenGraphVisualizationScreen()),
          needsParams: false,
        ),
      ],
    );
  }

  void _navigateToScreen(BuildContext context, Widget Function() screenBuilder) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => screenBuilder(),
      ),
    );
  }

  Widget _combatTestingArena() {
    String? lastResult;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          backgroundColor: DnDTheme.dungeonBlack,
          appBar: AppBar(
            title: const Text('⚔️ Combat Testing Arena'),
            backgroundColor: DnDTheme.emeraldGreen,
            foregroundColor: DnDTheme.dungeonBlack,
          ),
          body: Column(
            children: [
              if (lastResult != null)
                Container(
                  margin: const EdgeInsets.all(DnDTheme.md),
                  padding: const EdgeInsets.all(DnDTheme.md),
                  decoration: DnDTheme.getFantasyCardDecoration(
                    borderColor: DnDTheme.ancientGold,
                  ),
                  child: Text(
                    'Letztes Ergebnis: $lastResult',
                    style: DnDTheme.bodyText1.copyWith(
                      color: DnDTheme.ancientGold,
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(DnDTheme.md),
                  children: [
                    _buildCombatTestCard('Initiative Test', 'Teste Initiative-System', () {
                      final roll = (1 + (DateTime.now().millisecond % 20)).toString();
                      final result = 'Initiative-Wurf: $roll + DEX Bonus (3) = ${int.parse(roll) + 3}';
                      setState(() => lastResult = result);
                      _showTestDialog(context, 'Initiative Test', result);
                    }),
                    _buildCombatTestCard('Attack Roll Test', 'Teste Angriffswürfe', () {
                      final roll = (1 + (DateTime.now().millisecond % 20)).toString();
                      final result = 'Attack-Wurf: $roll + STR Bonus (4) = ${int.parse(roll) + 4}';
                      setState(() => lastResult = result);
                      _showTestDialog(context, 'Attack Roll Test', result);
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _inventoryManagementTest() {
    List<String> inventory = ['Schwert', 'Rüstung', 'Trank', 'Karte'];
    String? lastResult;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          backgroundColor: DnDTheme.dungeonBlack,
          appBar: AppBar(
            title: const Text('🎒 Inventory Management Test'),
            backgroundColor: DnDTheme.emeraldGreen,
            foregroundColor: DnDTheme.dungeonBlack,
          ),
          body: Column(
            children: [
              if (lastResult != null)
                Container(
                  margin: const EdgeInsets.all(DnDTheme.md),
                  padding: const EdgeInsets.all(DnDTheme.md),
                  decoration: DnDTheme.getFantasyCardDecoration(
                    borderColor: DnDTheme.ancientGold,
                  ),
                  child: Text(
                    'Letzte Aktion: $lastResult',
                    style: DnDTheme.bodyText1.copyWith(
                      color: DnDTheme.ancientGold,
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(DnDTheme.md),
                  children: [
                    _buildInventoryTestCard('Item Pickup', 'Teste Item-Aufnahme', () {
                      final newItem = ['Schild', 'Helme', 'Stiefel', 'Handschuhe'][DateTime.now().millisecond % 4];
                      setState(() {
                        inventory.add(newItem);
                        lastResult = '$newItem zum Inventar hinzugefügt';
                      });
                      _showTestDialog(context, 'Item Pickup', '$newItem wurde erfolgreich aufgenommen!');
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCombatTestCard(String title, String description, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.sm),
      decoration: DnDTheme.getFantasyCardDecoration(
        borderColor: DnDTheme.emeraldGreen,
      ),
      child: ListTile(
        title: Text(
          title,
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.emeraldGreen,
          ),
        ),
        subtitle: Text(
          description,
          style: DnDTheme.bodyText2,
        ),
        trailing: Icon(
          Icons.play_arrow,
          color: DnDTheme.emeraldGreen,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInventoryTestCard(String title, String description, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.sm),
      decoration: DnDTheme.getFantasyCardDecoration(
        borderColor: DnDTheme.emeraldGreen,
      ),
      child: ListTile(
        title: Text(
          title,
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.emeraldGreen,
          ),
        ),
        subtitle: Text(
          description,
          style: DnDTheme.bodyText2,
        ),
        trailing: Icon(
          Icons.play_arrow,
          color: DnDTheme.emeraldGreen,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showTestDialog(BuildContext context, String title, String description) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          title,
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Text(
          description,
          style: DnDTheme.bodyText1.copyWith(
            color: DnDTheme.emeraldGreen,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: DnDTheme.emeraldGreen,
            ),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _placeholderScreen(String title) {
    return Builder(
      builder: (context) {
        return Scaffold(
          backgroundColor: DnDTheme.dungeonBlack,
          appBar: AppBar(
            title: Text(title),
            backgroundColor: DnDTheme.stoneGrey,
            foregroundColor: DnDTheme.warningOrange,
          ),
          body: Center(
            child: Container(
              padding: const EdgeInsets.all(DnDTheme.xl),
              decoration: DnDTheme.getFantasyCardDecoration(
                borderColor: DnDTheme.warningOrange,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.construction,
                    size: 64,
                    color: DnDTheme.warningOrange,
                  ),
                  const SizedBox(height: DnDTheme.md),
                  Text(
                    'In Arbeit',
                    style: DnDTheme.headline2.copyWith(
                      color: DnDTheme.warningOrange,
                    ),
                  ),
                  const SizedBox(height: DnDTheme.sm),
                  Text(
                    '$title benötigt spezielle Parameter\nfür die vollständige Funktionalität.',
                    textAlign: TextAlign.center,
                    style: DnDTheme.bodyText1.copyWith(
                      color: DnDTheme.warningOrange,
                    ),
                  ),
                  const SizedBox(height: DnDTheme.lg),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DnDTheme.warningOrange,
                      foregroundColor: DnDTheme.dungeonBlack,
                    ),
                    child: const Text('Zurück'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}