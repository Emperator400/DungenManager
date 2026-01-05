// lib/main.dart

// 1. Dart Core
import 'dart:io';

// 2. Externe Packages
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';

// 3. Eigene Projekte (absolute Pfade von lib/)
import 'screens/campaign_selection_screen.dart';
import 'screens/all_screens_screen.dart';
import 'screens/screen_graph_visualization_screen.dart';
import 'inventory_demo_app.dart';
import 'theme/dnd_theme.dart';
import 'services/wiki_service_locator.dart';
import 'viewmodels/campaign_viewmodel.dart';
import 'database/core/database_connection.dart';
import 'database/repositories/campaign_model_repository.dart';
import 'database/repositories/player_character_model_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // KORREKTUR: Database Factory MUSS vor Service Initialisierung stehen
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // Datenbank-Reset für Schema-Korrekturen (Version 3)
  await _resetDatabaseForSchemaFix();
  
  // Initialisiere alle Service Locator NACH der Database Factory Initialisierung
  await _initializeServices();
  
  await AudioPlayer.global.setAudioContext( AudioContext(
    iOS: AudioContextIOS(
      category: AVAudioSessionCategory.playback,
      options: {AVAudioSessionOptions.mixWithOthers},
    ),
    android: AudioContextAndroid(
      isSpeakerphoneOn: true,
      stayAwake: true,
      contentType: AndroidContentType.music,
      usageType: AndroidUsageType.media,
      audioFocus: AndroidAudioFocus.gain,
    ),
  ));
  
  runApp(const DmApp());
}

/// Setzt die Datenbank zurück für Schema-Korrekturen (löscht Datei komplett)
Future<void> _resetDatabaseForSchemaFix() async {
  try {
    print('🔄 Lösche alte Datenbank-Datei für Schema-Korrekturen...');
    
    // Lösche die Datenbank-Datei komplett
    await DatabaseConnection.instance.deleteDatabaseFile();
    
    print('✅ Datenbank-Datei wurde gelöscht - neue wird beim Start erstellt');
  } catch (e) {
    print('⚠️ Fehler beim Löschen der Datenbank: $e');
    // App trotzdem starten
  }
}

/// Initialisiert alle Service Locator
Future<void> _initializeServices() async {
  try {
    // Initialisiere nur Wiki Service (hat async initialize)
    final wikiLocator = WikiServiceLocator();
    await wikiLocator.initialize();
    
    print('Wiki Service Locator erfolgreich initialisiert');
  } catch (e) {
    print('Fehler bei der Service-Initialisierung: $e');
    // App trotzdem starten, aber mit Fehlermeldung
  }
}

class DmApp extends StatelessWidget {
  const DmApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CampaignViewModel>(
      create: (_) => CampaignViewModel(
        campaignRepo: CampaignModelRepository(DatabaseConnection.instance),
        characterRepo: PlayerCharacterModelRepository(DatabaseConnection.instance),
      ),
      child: MaterialApp(
        title: 'Dungeon Manager',
        theme: DnDTheme.darkTheme,
        home: const AppSelectionScreen(), // Auswahl zwischen Haupt-App und Demo
      ),
    );
  }
}

class AppSelectionScreen extends StatelessWidget {
  const AppSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(DnDTheme.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Titel mit mystischem Effekt
                Container(
                  decoration: DnDTheme.getMysticalBorder(borderColor: DnDTheme.ancientGold),
                  padding: const EdgeInsets.all(DnDTheme.md),
                  child: Text(
                    'Dungeon Manager',
                    style: DnDTheme.headline1.copyWith(
                      color: DnDTheme.ancientGold,
                      shadows: [
                        Shadow(
                          blurRadius: 15,
                          color: DnDTheme.ancientGold.withValues(alpha: 0.5),
                          offset: const Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: DnDTheme.lg),
                Text(
                  'Wählen Sie eine Anwendung',
                  style: DnDTheme.headline3.copyWith(
                    color: DnDTheme.mysticalPurple,
                  ),
                ),
                const SizedBox(height: DnDTheme.xxl),
                
                // Haupt-App Button mit Fantasy-Style
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: DnDTheme.getFantasyCardDecoration(
                    borderColor: DnDTheme.ancientGold,
                    isLegendary: true,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const CampaignSelectionScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.castle, size: 32),
                    label: const Text(
                      'Hauptanwendung',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: DnDTheme.ancientGold,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DnDTheme.lg),
                
                // Demo Button mit Fantasy-Style
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: DnDTheme.getFantasyCardDecoration(
                    borderColor: DnDTheme.arcaneBlue,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const InventoryDemoApp(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.inventory, size: 32),
                    label: const Text(
                      'Inventar-Demo',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: DnDTheme.arcaneBlue,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DnDTheme.lg),
                
                // Alle Screens Button mit Fantasy-Style
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: DnDTheme.getFantasyCardDecoration(
                    borderColor: DnDTheme.warningOrange,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AllScreensScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.grid_view, size: 32),
                    label: const Text(
                      'Alle Screens',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: DnDTheme.warningOrange,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DnDTheme.lg),
                
                // Screen Graph Visualizer Button mit Fantasy-Style
                Container(
                  width: double.infinity,
                  height: 80,
                  decoration: DnDTheme.getFantasyCardDecoration(
                    borderColor: DnDTheme.mysticalPurple,
                  ),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ScreenGraphVisualizationScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.account_tree, size: 32),
                    label: const Text(
                      'Screen Graph',
                      style: TextStyle(fontSize: 20),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: DnDTheme.mysticalPurple,
                      elevation: 0,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: DnDTheme.xl),
                
                // Hinweis mit mystischem Design
                Container(
                  padding: const EdgeInsets.all(DnDTheme.md),
                  decoration: DnDTheme.getDungeonWallDecoration(),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: DnDTheme.infoBlue,
                        size: 24,
                      ),
                      const SizedBox(height: DnDTheme.sm),
                      Text(
                        'Hauptanwendung: Volles DM Helper mit allen Features\n'
                        'Inventar-Demo: Zeigt das neue erweiterte Inventar-System\n'
                        'Alle Screens: Testing-Übersicht aller 29 verfügbaren Screens\n'
                        'Screen Graph: Interaktiver Graph aller Screens und ihrer Verbindungen',
                        textAlign: TextAlign.center,
                        style: DnDTheme.bodyText2.copyWith(
                          color: DnDTheme.infoBlue,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
