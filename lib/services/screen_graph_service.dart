import 'dart:io';
import 'package:collection/collection.dart';
import '../models/screen_node.dart';

/// Service für die Analyse und Extraktion aller Screens und ihrer Navigation-Verbindungen
class ScreenGraphService {
  /// Analysiert alle Screens im Projekt und erstellt einen Graph
  /// @param basePath Pfad zum lib/screens Verzeichnis
  Future<Map<String, ScreenNode>> analyzeScreens(String basePath) async {
    var screens = <String, ScreenNode>{};
    
    // Alle .dart Dateien im screens Verzeichnis finden
    final directory = Directory(basePath);
    if (!await directory.exists()) {
      print('Verzeichnis nicht gefunden: $basePath');
      return screens;
    }
    
    final files = directory
        .listSync(recursive: false, followLinks: false)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .toList();
    
    // Screens analysieren
    for (var file in files) {
      final fileName = file.uri.pathSegments.last;
      final content = await file.readAsString();
      
      final screenName = _extractScreenName(fileName, content);
      final category = _extractCategory(fileName);
      
      screens[screenName] = ScreenNode(
        name: screenName,
        fileName: fileName,
        category: category,
        requiresParameters: _requiresParameters(content),
        parameterInfo: _extractParameterInfo(content),
        connections: _extractConnections(content),
      );
    }
    
    // Verbindungen aktualisieren mit Ziel-Screens
    screens = _resolveConnections(screens);
    
    return screens;
  }
  
  /// Extrahiert den Screen-Namen aus Dateiname und Inhalt
  String _extractScreenName(String fileName, String content) {
    // Versuche den Class-Namen zu extrahieren
    final classMatch = RegExp(r'class\s+(\w+Screen)').firstMatch(content);
    if (classMatch != null) {
      return classMatch.group(1)!;
    }
    
    // Fallback: Dateiname ohne _screen.dart
    return fileName
        .replaceAll('_screen.dart', '')
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }
  
  /// Extrahiert die Kategorie basierend auf dem Dateinamen
  String _extractCategory(String fileName) {
    if (fileName.contains('quest')) return 'Quest Management';
    if (fileName.contains('wiki') || fileName.contains('lore')) return 'Wiki/Lore';
    if (fileName.contains('character') || fileName.contains('pc')) return 'Character';
    if (fileName.contains('monster') || fileName.contains('creature') || fileName.contains('bestiary')) return 'Bestiary';
    if (fileName.contains('item')) return 'Item';
    if (fileName.contains('sound') || fileName.contains('audio')) return 'Audio';
    if (fileName.contains('session') || fileName.contains('scene')) return 'Session';
    if (fileName.contains('campaign')) return 'Campaign';
    if (fileName.contains('navigation')) return 'Navigation';
    if (fileName.contains('link') || fileName.contains('add') || fileName.contains('edit')) return 'Utility';
    return 'Other';
  }
  
  /// Überprüft ob der Screen Parameter benötigt
  bool _requiresParameters(String content) {
    return content.contains('required') || 
           content.contains('final Campaign?') ||
           content.contains('final Quest?') ||
           content.contains('final Session?') ||
           content.contains('final PlayerCharacter?') ||
           content.contains('final Creature?');
  }
  
  /// Extrahiert Parameter-Informationen
  String? _extractParameterInfo(String content) {
    final params = <String>[];
    
    if (content.contains('final Campaign?')) params.add('Campaign');
    if (content.contains('final Quest?')) params.add('Quest');
    if (content.contains('final Session?')) params.add('Session');
    if (content.contains('final PlayerCharacter?')) params.add('PlayerCharacter');
    if (content.contains('final Creature?')) params.add('Creature');
    
    if (params.isNotEmpty) {
      return 'Benötigt: ${params.join(', ')}';
    }
    return null;
  }
  
  /// Extrahiert alle Navigation-Verbindungen aus dem Code
  List<ScreenConnection> _extractConnections(String content) {
    final connections = <ScreenConnection>[];
    
    // Navigator.push Aufrufe finden
    final navigatorPattern = RegExp(r'Navigator\.of\(context\)\.push\([^)]*MaterialPageRoute\([^)]*builder:[^)]*=>\s*([A-Z]\w*)');
    final matches = navigatorPattern.allMatches(content);
    
    for (var match in matches) {
      final targetScreen = match.group(1);
      if (targetScreen != null) {
        connections.add(ScreenConnection(
          targetScreen: targetScreen,
          type: ConnectionType.navigation,
        ));
      }
    }
    
    // Button-Actions finden
    final buttonPattern = RegExp(r'onPressed:[^}]*=>\s*(?:_navigateToScreen|Navigator)\([^)]*([A-Z]\w+Screen)');
    final buttonMatches = buttonPattern.allMatches(content);
    
    for (var match in buttonMatches) {
      final targetScreen = match.group(1);
      if (targetScreen != null && !connections.any((c) => c.targetScreen == targetScreen)) {
        connections.add(ScreenConnection(
          targetScreen: targetScreen,
          triggerAction: 'Button Press',
          type: ConnectionType.action,
        ));
      }
    }
    
    return connections;
  }
  
  /// Löst die Verbindungen auf und fügt Beschreibungen hinzu
  Map<String, ScreenNode> _resolveConnections(Map<String, ScreenNode> screens) {
    var result = <String, ScreenNode>{};
    for (var screen in screens.values) {
      final updatedConnections = screen.connections.map((connection) {
        final target = screens.values.firstWhereOrNull(
          (s) => s.name.contains(connection.targetScreen) || 
                 s.fileName.contains(connection.targetScreen.toLowerCase())
        );
        
        return ScreenConnection(
          targetScreen: connection.targetScreen,
          triggerAction: connection.triggerAction,
          description: target != null 
            ? 'Navigate to ${target.name}'
            : 'Unknown screen: ${connection.targetScreen}',
          type: connection.type,
        );
      }).toList();
      
      result[screen.name] = screen.copyWith(connections: updatedConnections);
    }
    
    return result;
  }
  
  /// Erstellt statische Screen-Daten für manuelle Analyse
  Map<String, ScreenNode> getManualScreenData() {
    return {
      'EnhancedMainNavigationScreen': ScreenNode(
        name: 'Enhanced Main Navigation',
        fileName: 'enhanced_main_navigation_screen.dart',
        category: 'Navigation',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedCampaignDashboardScreen',
            triggerAction: 'Kampagnen Button',
            description: 'Navigate to Campaign Dashboard',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedQuestLibraryScreen',
            triggerAction: 'Quests Button',
            description: 'Navigate to Quest Library',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedLoreKeeperScreen',
            triggerAction: 'Wiki Button',
            description: 'Navigate to Wiki/Lore Keeper',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedItemLibraryScreen',
            triggerAction: 'Items Button',
            description: 'Navigate to Item Library',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedBestiaryScreen',
            triggerAction: 'Bestiary Button',
            description: 'Navigate to Bestiary',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedSoundLibraryScreen',
            triggerAction: 'Sounds Button',
            description: 'Navigate to Sound Library',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedOfficialMonstersScreen',
            triggerAction: 'Monsters Button',
            description: 'Navigate to Official Monsters',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedPlayerCharacterListScreen',
            triggerAction: 'Characters Button',
            description: 'Navigate to Character List',
            type: ConnectionType.deepLink,
          ),
          ScreenConnection(
            targetScreen: 'SessionListForCampaignScreen',
            triggerAction: 'Sessions Button',
            description: 'Navigate to Session List',
            type: ConnectionType.deepLink,
          ),
        ],
      ),
      
      'EnhancedCampaignDashboardScreen': ScreenNode(
        name: 'Campaign Dashboard',
        fileName: 'enhanced_campaign_dashboard_screen.dart',
        category: 'Campaign',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedEditCampaignScreen',
            triggerAction: 'Create/Edit Campaign',
            description: 'Open Campaign Editor',
            type: ConnectionType.navigation,
          ),
          ScreenConnection(
            targetScreen: 'SessionListForCampaignScreen',
            triggerAction: 'View Sessions',
            description: 'Navigate to Campaign Sessions',
            type: ConnectionType.deepLink,
          ),
        ],
      ),
      
      'EnhancedQuestLibraryScreen': ScreenNode(
        name: 'Quest Library',
        fileName: 'enhanced_quest_library_screen.dart',
        category: 'Quest Management',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedEditQuestScreen',
            triggerAction: 'Create/Edit Quest',
            description: 'Open Quest Editor',
            type: ConnectionType.navigation,
          ),
          ScreenConnection(
            targetScreen: 'AddQuestFromLibraryScreen',
            triggerAction: 'Add Quest',
            description: 'Add Quest to Campaign',
            type: ConnectionType.deepLink,
          ),
          ScreenConnection(
            targetScreen: 'LinkQuestToSceneScreen',
            triggerAction: 'Link to Scene',
            description: 'Link Quest to Scene',
            type: ConnectionType.deepLink,
          ),
        ],
      ),
      
      'EnhancedLoreKeeperScreen': ScreenNode(
        name: 'Lore Keeper',
        fileName: 'enhanced_lore_keeper_screen.dart',
        category: 'Wiki/Lore',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedEditWikiEntryScreen',
            triggerAction: 'Create/Edit Entry',
            description: 'Open Wiki Entry Editor',
            type: ConnectionType.navigation,
          ),
          ScreenConnection(
            targetScreen: 'LinkWikiEntriesScreen',
            triggerAction: 'Link Entries',
            description: 'Link Wiki Entries',
            type: ConnectionType.navigation,
          ),
          ScreenConnection(
            targetScreen: 'LinkEntryToSceneScreen',
            triggerAction: 'Link to Scene',
            description: 'Link Wiki Entry to Scene',
            type: ConnectionType.deepLink,
          ),
        ],
      ),
      
      'EnhancedItemLibraryScreen': ScreenNode(
        name: 'Item Library',
        fileName: 'enhanced_item_library_screen.dart',
        category: 'Item',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedEditItemScreen',
            triggerAction: 'Create/Edit Item',
            description: 'Open Item Editor',
            type: ConnectionType.navigation,
          ),
          ScreenConnection(
            targetScreen: 'AddItemFromLibraryScreen',
            triggerAction: 'Add to Character',
            description: 'Add Item to Character',
            type: ConnectionType.deepLink,
          ),
        ],
      ),
      
      'EnhancedBestiaryScreen': ScreenNode(
        name: 'Bestiary',
        fileName: 'enhanced_bestiary_screen.dart',
        category: 'Bestiary',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedEditCreatureScreen',
            triggerAction: 'Create/Edit Creature',
            description: 'Open Creature Editor',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedOfficialMonstersScreen': ScreenNode(
        name: 'Official Monsters',
        fileName: 'enhanced_official_monsters_screen.dart',
        category: 'Bestiary',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedEditCreatureScreen',
            triggerAction: 'Import Monster',
            description: 'Import and Edit Monster',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedSoundLibraryScreen': ScreenNode(
        name: 'Sound Library',
        fileName: 'enhanced_sound_library_screen.dart',
        category: 'Audio',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedEditSoundScreen',
            triggerAction: 'Create/Edit Sound',
            description: 'Open Sound Editor',
            type: ConnectionType.navigation,
          ),
          ScreenConnection(
            targetScreen: 'AddSoundToSceneScreen',
            triggerAction: 'Add to Scene',
            description: 'Add Sound to Scene',
            type: ConnectionType.deepLink,
          ),
        ],
      ),
      
      'SessionListForCampaignScreen': ScreenNode(
        name: 'Session List',
        fileName: 'enhanced_session_list_for_campaign_screen.dart',
        category: 'Session',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Campaign',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedEditSessionScreen',
            triggerAction: 'Create/Edit Session',
            description: 'Open Session Editor',
            type: ConnectionType.navigation,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedActiveSessionScreen',
            triggerAction: 'Start Session',
            description: 'Navigate to Active Session',
            type: ConnectionType.deepLink,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedEditSceneScreen',
            triggerAction: 'Manage Scenes',
            description: 'Open Scene Editor',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedUnifiedCharacterEditorScreen': ScreenNode(
        name: 'Unified Character Editor',
        fileName: 'enhanced_unified_character_editor_screen.dart',
        category: 'Character',
        requiresParameters: true,
        parameterInfo: 'Benötigt: CharacterType',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedEditPCScreen',
            triggerAction: 'Edit PC',
            description: 'Open Player Character Editor',
            type: ConnectionType.deepLink,
          ),
          ScreenConnection(
            targetScreen: 'EncounterSetupScreen',
            triggerAction: 'Setup Encounter',
            description: 'Open Encounter Setup',
            type: ConnectionType.deepLink,
          ),
        ],
      ),
      
      'AllScreensScreen': ScreenNode(
        name: 'All Screens (Testing)',
        fileName: 'all_screens_screen.dart',
        category: 'Testing',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedCampaignDashboardScreen',
            triggerAction: 'Test Campaign Screens',
            description: 'Navigate to Campaign Dashboard',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedQuestLibraryScreen',
            triggerAction: 'Test Quest Screens',
            description: 'Navigate to Quest Library',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedLoreKeeperScreen',
            triggerAction: 'Test Wiki Screens',
            description: 'Navigate to Wiki',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedBestiaryScreen',
            triggerAction: 'Test Bestiary Screens',
            description: 'Navigate to Bestiary',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedItemLibraryScreen',
            triggerAction: 'Test Item Screens',
            description: 'Navigate to Item Library',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedSoundLibraryScreen',
            triggerAction: 'Test Audio Screens',
            description: 'Navigate to Sound Library',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedUnifiedCharacterEditorScreen',
            triggerAction: 'Test Character Screens',
            description: 'Navigate to Character Editor',
            type: ConnectionType.action,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedMainNavigationScreen',
            triggerAction: 'Test Navigation',
            description: 'Navigate to Main Navigation',
            type: ConnectionType.action,
          ),
        ],
      ),
      
      // Edit Screens
      'EnhancedEditCampaignScreen': ScreenNode(
        name: 'Edit Campaign',
        fileName: 'enhanced_edit_campaign_screen.dart',
        category: 'Campaign',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Campaign (optional)',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedCampaignDashboardScreen',
            triggerAction: 'Save/Back',
            description: 'Return to Dashboard',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedEditQuestScreen': ScreenNode(
        name: 'Edit Quest',
        fileName: 'enhanced_edit_quest_screen.dart',
        category: 'Quest Management',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Quest (optional)',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedQuestLibraryScreen',
            triggerAction: 'Save/Back',
            description: 'Return to Quest Library',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedEditWikiEntryScreen': ScreenNode(
        name: 'Edit Wiki Entry',
        fileName: 'enhanced_edit_wiki_entry_screen.dart',
        category: 'Wiki/Lore',
        requiresParameters: true,
        parameterInfo: 'Benötigt: WikiEntry, ParentCategory (optional)',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedLoreKeeperScreen',
            triggerAction: 'Save/Back',
            description: 'Return to Wiki',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedEditItemScreen': ScreenNode(
        name: 'Edit Item',
        fileName: 'enhanced_edit_item_screen.dart',
        category: 'Item',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Item (optional)',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedItemLibraryScreen',
            triggerAction: 'Save/Back',
            description: 'Return to Item Library',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedEditCreatureScreen': ScreenNode(
        name: 'Edit Creature',
        fileName: 'enhanced_edit_creature_screen.dart',
        category: 'Bestiary',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Creature (optional)',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedBestiaryScreen',
            triggerAction: 'Save/Back',
            description: 'Return to Bestiary',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedEditSoundScreen': ScreenNode(
        name: 'Edit Sound',
        fileName: 'enhanced_edit_sound_screen.dart',
        category: 'Audio',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Sound (optional)',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedSoundLibraryScreen',
            triggerAction: 'Save/Back',
            description: 'Return to Sound Library',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedEditSessionScreen': ScreenNode(
        name: 'Edit Session',
        fileName: 'enhanced_edit_session_screen.dart',
        category: 'Session',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Session (optional)',
        connections: [
          ScreenConnection(
            targetScreen: 'SessionListForCampaignScreen',
            triggerAction: 'Save/Back',
            description: 'Return to Session List',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedEditSceneScreen': ScreenNode(
        name: 'Edit Scene',
        fileName: 'enhanced_edit_scene_screen.dart',
        category: 'Session',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Scene (optional)',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedActiveSessionScreen',
            triggerAction: 'Save/Back',
            description: 'Return to Active Session',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedEditPCScreen': ScreenNode(
        name: 'Edit Player Character',
        fileName: 'enhanced_edit_pc_screen.dart',
        category: 'Character',
        requiresParameters: true,
        parameterInfo: 'Benötigt: PlayerCharacter (optional)',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedPlayerCharacterListScreen',
            triggerAction: 'Save/Back',
            description: 'Return to Character List',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedActiveSessionScreen': ScreenNode(
        name: 'Active Session',
        fileName: 'enhanced_active_session_screen.dart',
        category: 'Session',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Campaign, Session',
        connections: [
          ScreenConnection(
            targetScreen: 'SessionListForCampaignScreen',
            triggerAction: 'End Session',
            description: 'Return to Session List',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'EnhancedPlayerCharacterListScreen': ScreenNode(
        name: 'Player Character List',
        fileName: 'enhanced_pc_list_screen.dart',
        category: 'Character',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Campaign',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedEditPCScreen',
            triggerAction: 'Create/Edit PC',
            description: 'Open PC Editor',
            type: ConnectionType.navigation,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedUnifiedCharacterEditorScreen',
            triggerAction: 'Unified Editor',
            description: 'Open Unified Editor',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      // Utility Screens
      'AddQuestFromLibraryScreen': ScreenNode(
        name: 'Add Quest from Library',
        fileName: 'add_quest_from_library_screen.dart',
        category: 'Utility',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Campaign',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedQuestLibraryScreen',
            triggerAction: 'Cancel',
            description: 'Return to Quest Library',
            type: ConnectionType.modal,
          ),
        ],
      ),
      
      'AddItemFromLibraryScreen': ScreenNode(
        name: 'Add Item from Library',
        fileName: 'add_item_from_library_screen.dart',
        category: 'Utility',
        requiresParameters: true,
        parameterInfo: 'Benötigt: PlayerCharacter',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedItemLibraryScreen',
            triggerAction: 'Cancel',
            description: 'Return to Item Library',
            type: ConnectionType.modal,
          ),
        ],
      ),
      
      'AddSoundToSceneScreen': ScreenNode(
        name: 'Add Sound to Scene',
        fileName: 'add_sound_to_scene_screen.dart',
        category: 'Utility',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Scene',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedSoundLibraryScreen',
            triggerAction: 'Cancel',
            description: 'Return to Sound Library',
            type: ConnectionType.modal,
          ),
        ],
      ),
      
      'LinkQuestToSceneScreen': ScreenNode(
        name: 'Link Quest to Scene',
        fileName: 'link_quest_to_scene_screen.dart',
        category: 'Utility',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Quest, Scene',
        connections: [],
      ),
      
      'LinkEntryToSceneScreen': ScreenNode(
        name: 'Link Entry to Scene',
        fileName: 'link_entry_to_scene_screen.dart',
        category: 'Utility',
        requiresParameters: true,
        parameterInfo: 'Benötigt: WikiEntry, Scene',
        connections: [],
      ),
      
      'LinkWikiEntriesScreen': ScreenNode(
        name: 'Link Wiki Entries',
        fileName: 'link_wiki_entries_screen.dart',
        category: 'Utility',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedLoreKeeperScreen',
            triggerAction: 'Back',
            description: 'Return to Wiki',
            type: ConnectionType.modal,
          ),
        ],
      ),
      
      'EditCampaignQuestScreen': ScreenNode(
        name: 'Edit Campaign Quest',
        fileName: 'edit_campaign_quest_screen.dart',
        category: 'Quest Management',
        requiresParameters: true,
        parameterInfo: 'Benötigt: CampaignQuest',
        connections: [
          ScreenConnection(
            targetScreen: 'SessionListForCampaignScreen',
            triggerAction: 'Back',
            description: 'Return to Session List',
            type: ConnectionType.modal,
          ),
        ],
      ),
      
      'EncounterSetupScreen': ScreenNode(
        name: 'Encounter Setup',
        fileName: 'encounter_setup_screen.dart',
        category: 'Character',
        requiresParameters: true,
        parameterInfo: 'Benötigt: Campaign, Creatures',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedActiveSessionScreen',
            triggerAction: 'Start Encounter',
            description: 'Start Active Session',
            type: ConnectionType.navigation,
          ),
        ],
      ),
      
      'InitiativeTrackerScreen': ScreenNode(
        name: 'Initiative Tracker',
        fileName: 'initiative_tracker_screen.dart',
        category: 'Session',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedActiveSessionScreen',
            triggerAction: 'Back',
            description: 'Return to Active Session',
            type: ConnectionType.modal,
          ),
        ],
      ),
      
      'CampaignSelectionScreen': ScreenNode(
        name: 'Campaign Selection',
        fileName: 'campaign_selection_screen.dart',
        category: 'Campaign',
        connections: [
          ScreenConnection(
            targetScreen: 'EnhancedMainNavigationScreen',
            triggerAction: 'Select Campaign',
            description: 'Navigate to Main Navigation',
            type: ConnectionType.navigation,
          ),
          ScreenConnection(
            targetScreen: 'EnhancedEditCampaignScreen',
            triggerAction: 'Create New Campaign',
            description: 'Create New Campaign',
            type: ConnectionType.navigation,
          ),
        ],
      ),
    };
  }
}
