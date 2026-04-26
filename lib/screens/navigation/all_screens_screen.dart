import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

// Import aller Screens
import '../campaign/campaign_selection_screen.dart';
import 'main_navigation_screen.dart';

// Quest Screens
import '../quests/quest_library_screen.dart';

// Bestiary Screens
import '../bestiary/bestiary_screen.dart';
import '../bestiary/official_monsters_screen.dart';

// Item Screens
import '../items/item_library_screen.dart';

// Lore Screens
import '../lore/lore_keeper_screen.dart';

// Audio Screens
import '../audio/sound_library_screen.dart';

// Debug Screens
import '../debug/screen_graph_visualization_screen.dart';

class AllScreensScreen extends StatelessWidget {
  const AllScreensScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: AppBar(
        title: Text(
          'Alle Screens - UI Testing',
          style: TextStyle(fontSize: 22, color: C.amber, fontWeight: FontWeight.bold),
        ),
        backgroundColor: C.bgPanel,
        foregroundColor: C.amber,
        elevation: 4,
        iconTheme: IconThemeData(color: C.amber),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionHeader(context, '🎯 KAMPAGNEN-MANAGEMENT'),
          _buildCampaignScreens(context),

          _buildSectionHeader(context, '📜 QUEST-MANAGEMENT'),
          _buildQuestScreens(context),

          _buildSectionHeader(context, '📚 WIKI/LORE MANAGEMENT'),
          _buildWikiScreens(context),

          _buildSectionHeader(context, '🧑‍🤝‍🧑 CHARACTER MANAGEMENT'),
          _buildCharacterScreens(context),

          _buildSectionHeader(context, '⚔️ BESTIARY & MONSTER MANAGEMENT'),
          _buildBestiaryScreens(context),

          _buildSectionHeader(context, '🎒 ITEM MANAGEMENT'),
          _buildItemScreens(context),

          _buildSectionHeader(context, '🎵 AUDIO MANAGEMENT'),
          _buildAudioScreens(context),

          _buildSectionHeader(context, '🎮 SESSION MANAGEMENT'),
          _buildSessionScreens(context),

          _buildSectionHeader(context, '🧑‍🤝‍🧑 CHARACTER MANAGEMENT TESTING'),
          _buildCharacterTestingScreens(context),

          _buildSectionHeader(context, '🔧 MAIN NAVIGATION'),
          _buildMainNavigationScreens(context),

          _buildSectionHeader(context, '🔍 DEBUG TOOLS'),
          _buildDebugScreens(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final C = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: C.bgPanel,
          border: Border.all(color: const Color(0xFF7C3AED)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF7C3AED),
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
    final C = context.appColors;
    const orange = Color(0xFFEA580C);
    const green = Color(0xFF22C55E);
    final borderColor = needsParams ? orange : green;
    final textColor = needsParams ? orange : green;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              description,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            if (needsParams && paramWarning != null) ...[
              const SizedBox(height: 4),
              Text(
                paramWarning,
                style: const TextStyle(
                  fontSize: 14,
                  color: orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        trailing: Icon(
          needsParams ? Icons.warning : Icons.play_arrow,
          color: textColor,
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
          onTap: () => _placeholderScreen('Select Character - Coming Soon'),
          needsParams: true,
          paramWarning: '⚠️ Screen wird noch migriert',
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
          onTap: () => _placeholderScreen('Add Sound - Coming Soon'),
          needsParams: true,
          paramWarning: '⚠️ Screen wird noch migriert',
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
          onTap: () => _placeholderScreen('Session List - Coming Soon'),
          needsParams: true,
          paramWarning: '⚠️ Screen wird noch migriert',
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
        ),
        _buildScreenCard(
          context: context,
          title: '🎒 Inventory Management Test',
          description: 'Testing-Screen für Item-Management',
          onTap: () => _navigateToScreen(context, () => _inventoryManagementTest()),
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
        ),
      ],
    );
  }

  void _navigateToScreen(BuildContext context, Widget Function() screenBuilder) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => screenBuilder(),
      ),
    );
  }

  Widget _combatTestingArena() {
    String? lastResult;

    return StatefulBuilder(
      builder: (context, setState) {
        final C = context.appColors;
        return Scaffold(
          backgroundColor: C.bg,
          appBar: AppBar(
            title: const Text('⚔️ Combat Testing Arena'),
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.black,
          ),
          body: Column(
            children: [
              if (lastResult != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: C.bgPanel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.amber, width: 2),
                  ),
                  child: Text(
                    'Letztes Ergebnis: $lastResult',
                    style: TextStyle(fontSize: 14, color: C.amber),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildCombatTestCard(context, 'Initiative Test', 'Teste Initiative-System', () {
                      final roll = (1 + (DateTime.now().millisecond % 20)).toString();
                      final result = 'Initiative-Wurf: $roll + DEX Bonus (3) = ${int.parse(roll) + 3}';
                      setState(() => lastResult = result);
                      _showTestDialog(context, 'Initiative Test', result);
                    }),
                    _buildCombatTestCard(context, 'Attack Roll Test', 'Teste Angriffswürfe', () {
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
        final C = context.appColors;
        return Scaffold(
          backgroundColor: C.bg,
          appBar: AppBar(
            title: const Text('🎒 Inventory Management Test'),
            backgroundColor: const Color(0xFF22C55E),
            foregroundColor: Colors.black,
          ),
          body: Column(
            children: [
              if (lastResult != null)
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: C.bgPanel,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.amber, width: 2),
                  ),
                  child: Text(
                    'Letzte Aktion: $lastResult',
                    style: TextStyle(fontSize: 14, color: C.amber),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildInventoryTestCard(context, 'Item Pickup', 'Teste Item-Aufnahme', () {
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

  Widget _buildCombatTestCard(BuildContext context, String title, String description, VoidCallback onTap) {
    final C = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22C55E), width: 2),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        trailing: const Icon(Icons.play_arrow, color: Color(0xFF22C55E)),
        onTap: onTap,
      ),
    );
  }

  Widget _buildInventoryTestCard(BuildContext context, String title, String description, VoidCallback onTap) {
    final C = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF22C55E), width: 2),
      ),
      child: ListTile(
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF22C55E)),
        ),
        subtitle: Text(
          description,
          style: const TextStyle(fontSize: 14, color: Colors.white70),
        ),
        trailing: const Icon(Icons.play_arrow, color: Color(0xFF22C55E)),
        onTap: onTap,
      ),
    );
  }

  void _showTestDialog(BuildContext context, String title, String description) {
    final C = context.appColors;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text(
          title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: C.amber),
        ),
        content: Text(
          description,
          style: const TextStyle(fontSize: 14, color: Color(0xFF22C55E)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF22C55E),
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
        final C = context.appColors;
        return Scaffold(
          backgroundColor: C.bg,
          appBar: AppBar(
            title: Text(title),
            backgroundColor: C.bgPanel,
            foregroundColor: const Color(0xFFEA580C),
          ),
          body: Center(
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: C.bgPanel,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEA580C), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.construction,
                    size: 64,
                    color: Color(0xFFEA580C),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'In Arbeit',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFEA580C),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$title benötigt spezielle Parameter\nfür die vollständige Funktionalität.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: Color(0xFFEA580C)),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEA580C),
                      foregroundColor: Colors.black,
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
