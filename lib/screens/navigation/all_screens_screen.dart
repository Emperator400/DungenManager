import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';

// Import aller Screens
import '../campaign/campaign_selection_screen.dart';
import '../campaign/campaign_dashboard_screen.dart';
import 'main_navigation_screen.dart';
// Nicht existierende Screens auskommentiert:
// import '../bestiary/enhanced_bestiary_screen.dart'; // Datei existiert nicht noch
// import '../items/enhanced_item_library_screen.dart'; // Datei existiert nicht noch
// import '../lore_keeper/enhanced_lore_keeper_screen.dart'; // Datei existiert nicht noch
// import '../bestiary/enhanced_official_monsters_screen.dart'; // Datei existiert nicht noch
// import '../quest_library/enhanced_quest_library_screen.dart'; // Datei existiert nicht noch
// import '../sound_library/enhanced_sound_library_screen.dart'; // Datei existiert nicht noch

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
          title: 'Enhanced Campaign Dashboard',
          description: 'Zentrale Verwaltung aller Kampagnen mit Filter-Chips und Quick-Actions',
          onTap: () => _navigateToScreen(context, () => _placeholderScreen('Enhanced Campaign Dashboard')),
          needsParams: true,
          paramWarning: '⚠️ Screen wird noch migriert',
        ),
import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';

// Import aller Screens
import '../campaign/campaign_selection_screen.dart';
import '../campaign/campaign_dashboard_screen.dart';
import 'main_navigation_screen.dart';
// Nicht existierende Screens auskommentiert:
// import '../bestiary/enhanced_bestiary_screen.dart'; // Datei existiert nicht noch
// import '../items/enhanced_item_library_screen.dart'; // Datei existiert nicht noch
// import '../lore_keeper/enhanced_lore_keeper_screen.dart'; // Datei existiert nicht noch
// import '../bestiary/enhanced_official_monsters_screen.dart'; // Datei existiert nicht noch
// import '../quest_library/enhanced_quest_library_screen.dart'; // Datei existiert nicht noch
// import '../sound_library/enhanced_sound_library_screen.dart'; // Datei existiert nicht noch

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
  ++++ REPLACE
import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';

// Import aller Screens
import '../campaign/campaign_selection_screen.dart';
import '../campaign/campaign_dashboard_screen.dart';
import 'main_navigation_screen.dart';
// Nicht existierende Screens auskommentiert:
// import '../bestiary/enhanced_bestiary_screen.dart'; // Datei existiert nicht noch
// import '../items/enhanced_item_library_screen.dart'; // Datei existiert nicht noch
// import '../lore_keeper/enhanced_lore_keeper_screen.dart'; // Datei existiert nicht noch
// import '../bestiary/enhanced_official_monsters_screen.dart'; // Datei existiert nicht noch
// import '../quest_library/enhanced_quest_library_screen.dart'; // Datei existiert nicht noch
// import '../sound_library/enhanced_sound_library_screen.dart'; // Datei existiert nicht noch

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
  -------
          context: context,
          title: '⚔️ Combat Testing Arena',
          description: 'Test-Bereich für Kampf-Mechaniken und Initiative-Systeme',
          onTap: () => _navigateToScreen(context, () => _combatTestingArena()),
          needsParams: false,
        ),
        _buildScreenCard(
          context: context,
          title: '🎒 Inventory Management Test',
          description: 'Testing-Screen für Item-Management, Ausrüstung und Inventar-Systeme',
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
          description: 'Zentrale 2x5 Grid Navigation mit allen Hauptbereichen',
          onTap: () => _navigateToScreen(context, () => const EnhancedMainNavigationScreen()),
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

  Widget _characterTestingSuite() {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      appBar: AppBar(
        title: const Text('🧑 Character Editor Testing Suite'),
        backgroundColor: DnDTheme.emeraldGreen,
        foregroundColor: DnDTheme.dungeonBlack,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DnDTheme.md),
        children: [
          _buildTestSection('Character Creation Tests'),
          _buildTestSection('Character Stats Tests'),
          _buildTestSection('Combat System Tests'),
          _buildTestSection('Inventory Management Tests'),
          _buildTestSection('Character Development Tests'),
        ],
      ),
    );
  }

  Widget _characterTypeSelector() {
    String? selectedType;
    
    return StatefulBuilder(
      builder: (context, setState) {
        return Scaffold(
          backgroundColor: DnDTheme.dungeonBlack,
          appBar: AppBar(
            title: const Text('🔧 Character Type Selector'),
            backgroundColor: DnDTheme.emeraldGreen,
            foregroundColor: DnDTheme.dungeonBlack,
          ),
          body: Column(
            children: [
              if (selectedType != null)
                Container(
                  margin: const EdgeInsets.all(DnDTheme.md),
                  padding: const EdgeInsets.all(DnDTheme.md),
                  decoration: DnDTheme.getFantasyCardDecoration(
                    borderColor: DnDTheme.ancientGold,
                  ),
                  child: Text(
                    'Ausgewählt: $selectedType',
                    style: DnDTheme.headline3.copyWith(
                      color: DnDTheme.ancientGold,
                    ),
                  ),
                ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(DnDTheme.md),
                  children: [
                    _buildCharacterTypeCard('Player Character', 'Held für D&D Abenteuer', () {
                      setState(() => selectedType = 'Player Character');
                      _showTestDialog(context, 'Player Character', 'Ein heldenhafter Abenteurer mit speziellen Fähigkeiten und Wachstumspotenzial.');
                    }),
                    _buildCharacterTypeCard('NPC', 'Nicht-Spieler-Charakter', () {
                      setState(() => selectedType = 'NPC');
                      _showTestDialog(context, 'NPC', 'Ein Charakter der von der Spielleitung kontrolliert wird, mit festgelegten Stats.');
                    }),
                    _buildCharacterTypeCard('Monster', 'Gegnerische Kreaturen', () {
                      setState(() => selectedType = 'Monster');
                      _showTestDialog(context, 'Monster', 'Ein feindliches Wesen mit speziellen Angriffen und Resistenzen.');
                    }),
                    _buildCharacterTypeCard('Creature', 'Neutrale Tiere/Wesen', () {
                      setState(() => selectedType = 'Creature');
                      _showTestDialog(context, 'Creature', 'Ein neutrales Wesen das sowohl freundlich als auch feindlich sein kann.');
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

  Widget _characterStatsDemo() {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      appBar: AppBar(
        title: const Text('📊 Character Stats Demo'),
        backgroundColor: DnDTheme.emeraldGreen,
        foregroundColor: DnDTheme.dungeonBlack,
      ),
      body: ListView(
        padding: const EdgeInsets.all(DnDTheme.md),
        children: [
          _buildStatsCard('Strength (STR)', '18 (+4)', Icons.fitness_center),
          _buildStatsCard('Dexterity (DEX)', '16 (+3)', Icons.directions_run),
          _buildStatsCard('Constitution (CON)', '14 (+2)', Icons.favorite),
          _buildStatsCard('Intelligence (INT)', '12 (+1)', Icons.psychology),
          _buildStatsCard('Wisdom (WIS)', '10 (+0)', Icons.visibility),
          _buildStatsCard('Charisma (CHA)', '8 (-1)', Icons.people),
        ],
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
                    _buildCombatTestCard('Damage Calculation', 'Teste Schadensberechnung', () {
                      final dice = (1 + (DateTime.now().millisecond % 8)).toString();
                      final result = 'Schaden: 2d8 = $dice + STR Bonus (4) = ${int.parse(dice) + 4}';
                      setState(() => lastResult = result);
                      _showTestDialog(context, 'Damage Calculation', result);
                    }),
                    _buildCombatTestCard('Saving Throws', 'Teste Rettungswürfe', () {
                      final roll = (1 + (DateTime.now().millisecond % 20)).toString();
                      final result = 'CON Rettungswurf: $roll + CON Bonus (2) = ${int.parse(roll) + 2}';
                      setState(() => lastResult = result);
                      _showTestDialog(context, 'Saving Throw Test', result);
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
    double currentWeight = 45.5;
    double maxWeight = 150.0;
    
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
              Container(
                margin: const EdgeInsets.all(DnDTheme.md),
                padding: const EdgeInsets.all(DnDTheme.md),
                decoration: DnDTheme.getFantasyCardDecoration(
                  borderColor: DnDTheme.emeraldGreen,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Inventar (${inventory.length} Items):',
                      style: DnDTheme.headline3.copyWith(
                        color: DnDTheme.emeraldGreen,
                      ),
                    ),
                    const SizedBox(height: DnDTheme.sm),
                    Text(
                      inventory.join(', '),
                      style: DnDTheme.bodyText1.copyWith(
                        color: DnDTheme.emeraldGreen,
                      ),
                    ),
                    const SizedBox(height: DnDTheme.sm),
                    Text(
                      'Gewicht: ${currentWeight.toStringAsFixed(1)} / ${maxWeight.toStringAsFixed(1)} kg',
                      style: DnDTheme.bodyText2.copyWith(
                        color: currentWeight > maxWeight * 0.8 
                          ? DnDTheme.warningOrange 
                          : DnDTheme.emeraldGreen,
                      ),
                    ),
                  ],
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
                        currentWeight += 5.0;
                        lastResult = '$newItem zum Inventar hinzugefügt';
                      });
                      _showTestDialog(context, 'Item Pickup', '$newItem wurde erfolgreich aufgenommen!');
                    }),
                    _buildInventoryTestCard('Equipment Test', 'Teste Ausrüstung', () {
                      if (inventory.isNotEmpty) {
                        final item = inventory.last;
                        setState(() {
                          lastResult = '$item ausgerüstet';
                        });
                        _showTestDialog(context, 'Equipment Test', '$item wurde ausgerüstet und ist bereit für den Kampf!');
                      }
                    }),
                    _buildInventoryTestCard('Weight Limit', 'Teste Tragkraft', () {
                      final percentage = (currentWeight / maxWeight * 100).toStringAsFixed(1);
                      final status = currentWeight > maxWeight * 0.8 
                        ? 'WARNUNG: Inventar fast voll!' 
                        : currentWeight > maxWeight * 0.6 
                          ? 'Achtung: Inventar zur Hälfte voll'
                          : 'Inventar hat noch Platz';
                      setState(() {
                        lastResult = '$percentage% genutzt - $status';
                      });
                      _showTestDialog(context, 'Weight Limit', 'Aktuelle Belastung: $percentage%\n$status');
                    }),
                    _buildInventoryTestCard('Item Usage', 'Teste Item-Nutzung', () {
                      if (inventory.isNotEmpty) {
                        final item = inventory.removeAt(0);
                        setState(() {
                          currentWeight = (currentWeight - 3.0).clamp(0.0, maxWeight);
                          lastResult = '$item verwendet und entfernt';
                        });
                        _showTestDialog(context, 'Item Usage', '$item wurde verwendet und aus dem Inventar entfernt.');
                      } else {
                        _showTestDialog(context, 'Item Usage', 'Keine Items im Inventar zum Verwenden!');
                      }
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

  Widget _buildTestSection(String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      padding: const EdgeInsets.all(DnDTheme.md),
      decoration: DnDTheme.getFantasyCardDecoration(
        borderColor: DnDTheme.emeraldGreen,
      ),
      child: Text(
        title,
        style: DnDTheme.headline3.copyWith(
          color: DnDTheme.emeraldGreen,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildCharacterTypeCard(String type, String description, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.sm),
      decoration: DnDTheme.getFantasyCardDecoration(
        borderColor: DnDTheme.emeraldGreen,
      ),
      child: ListTile(
        title: Text(
          type,
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

  Widget _buildStatsCard(String stat, String value, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.sm),
      decoration: DnDTheme.getFantasyCardDecoration(
        borderColor: DnDTheme.emeraldGreen,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: DnDTheme.emeraldGreen,
          size: 28,
        ),
        title: Text(
          stat,
          style: DnDTheme.bodyText1.copyWith(
            color: DnDTheme.emeraldGreen,
          ),
        ),
        trailing: Text(
          value,
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.emeraldGreen,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
