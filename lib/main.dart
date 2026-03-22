// lib/main.dart

// 1. Dart Core
import 'dart:async';
import 'dart:io';

// 2. Externe Packages
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:provider/provider.dart';

// 3. Eigene Projekte (absolute Pfade von lib/)
import 'screens/campaign/campaign_selection_screen.dart';
import 'screens/navigation/all_screens_screen.dart';
import 'screens/debug/screen_graph_visualization_screen.dart';
import 'inventory_demo_app.dart';
import 'theme/dnd_theme.dart';
import 'services/session_service.dart';
import 'viewmodels/campaign_viewmodel.dart';
import 'viewmodels/wiki_viewmodel.dart';
import 'viewmodels/edit_session_viewmodel.dart';
import 'database/core/database_connection.dart';
import 'database/migrations/database_migration.dart';
import 'database/repositories/campaign_model_repository.dart';
import 'database/repositories/player_character_model_repository.dart';
import 'database/repositories/session_model_repository.dart';
import 'database/repositories/scene_model_repository.dart';
import 'database/repositories/creature_model_repository.dart';
import 'database/repositories/quest_model_repository.dart';
import 'database/repositories/sound_model_repository.dart';
import 'database/repositories/wiki_entry_model_repository.dart';
import 'viewmodels/update_viewmodel.dart';
import 'widgets/update_dialog.dart';

// ============================================================
// APP KONFIGURATION
// ============================================================
// 
// PRODUKTIONS-MODUS: Setze auf `true` für Release-Builds
// - Nutzer wird direkt zur CampaignSelectionScreen geleitet
// 
// ENTWICKLUNGS-MODUS: Setze auf `false` für Entwicklung
// - Zeigt AppSelectionScreen mit allen Debug-Optionen
// 
const bool kIsProductionMode = true;
// ============================================================

/// Hauptfunktion der App
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Datenbank initialisieren
  await _initializeDatabase();
  
  // Audio konfigurieren
  await _configureAudio();
  
  // App starten
  runApp(const DmApp());
}

/// Initialisiert die Datenbank
Future<void> _initializeDatabase() async {
  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    print('🗄️ SQLite FFI für Desktop initialisiert');
  }
  
  // Initialisiere Datenbank und führe Migrationen aus
  try {
    final dbConnection = DatabaseConnection.instance;
    await dbConnection.database;
    print('✅ Datenbank-Verbindung erfolgreich getestet');
    
    // Führe Datenbank-Migrationen aus
    final migration = DatabaseMigration(dbConnection);
    await migration.runMigrations();
    print('✅ Datenbank-Migrationen erfolgreich ausgeführt');
  } catch (e) {
    print('❌ Fehler beim Initialisieren der Datenbank: $e');
    rethrow;
  }
}

/// Konfiguriert den Audio-Kontext für Hintergrundmusik
Future<void> _configureAudio() async {
  try {
    await AudioPlayer.global.setAudioContext(
      AudioContext(
        iOS: AudioContextIOS(
          category: AVAudioSessionCategory.playback,
          options: const {
            AVAudioSessionOptions.mixWithOthers,
            AVAudioSessionOptions.allowBluetoothA2DP,
          },
        ),
        android: AudioContextAndroid(
          isSpeakerphoneOn: true,
          stayAwake: true,
          contentType: AndroidContentType.music,
          usageType: AndroidUsageType.media,
          audioFocus: AndroidAudioFocus.gain,
        ),
      ),
    );
    print('Audio Kontext erfolgreich konfiguriert');
  } catch (e) {
    print('Fehler bei der Audio-Konfiguration: $e');
  }
}

/// Haupt-App Klasse
class DmApp extends StatelessWidget {
  const DmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final sessionService = SessionService();
    final dbConnection = DatabaseConnection.instance;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => CampaignViewModel(
            campaignRepo: CampaignModelRepository(dbConnection),
            characterRepo: PlayerCharacterModelRepository(dbConnection),
            sessionService: sessionService,
          ),
        ),
        ChangeNotifierProvider(
          create: (_) => WikiViewModel(),
        ),
        ChangeNotifierProvider(
          create: (_) => EditSessionViewModel(
            sessionRepository: SessionModelRepository(dbConnection),
          ),
        ),
        Provider<SceneModelRepository>(
          create: (_) => SceneModelRepository(dbConnection),
        ),
        Provider<CreatureModelRepository>(
          create: (_) => CreatureModelRepository(dbConnection),
        ),
        Provider<PlayerCharacterModelRepository>(
          create: (_) => PlayerCharacterModelRepository(dbConnection),
        ),
        Provider<QuestModelRepository>(
          create: (_) => QuestModelRepository(dbConnection),
        ),
        Provider<SoundModelRepository>(
          create: (_) => SoundModelRepository(dbConnection),
        ),
        Provider<WikiEntryModelRepository>(
          create: (_) => WikiEntryModelRepository(dbConnection),
        ),
        // Update ViewModel für Auto-Update-Check
        ChangeNotifierProvider(
          create: (_) {
            final viewModel = UpdateViewModel();
            viewModel.init();
            return viewModel;
          },
        ),
      ],
      child: MaterialApp(
        title: 'Dungeon Manager',
        theme: DnDTheme.darkTheme,
        // Produktionsmodus: Direkt zur CampaignSelectionScreen
        // Entwicklungsmodus: Zeigt AppSelectionScreen
        home: kIsProductionMode 
            ? const CampaignSelectionScreen() 
            : const AppSelectionScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// App Selection Screen - Hauptauswahl zwischen allen Anwendungen (nur für Entwicklung)
class AppSelectionScreen extends StatefulWidget {
  const AppSelectionScreen({super.key});

  @override
  State<AppSelectionScreen> createState() => _AppSelectionScreenState();
}

class _AppSelectionScreenState extends State<AppSelectionScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _updateChecked = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkForUpdates();
  }

  /// Prüft automatisch auf Updates beim Start
  Future<void> _checkForUpdates() async {
    if (_updateChecked) return;
    _updateChecked = true;

    // Kurze Verzögerung damit die UI geladen ist
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final viewModel = context.read<UpdateViewModel>();
    final hasUpdate = await viewModel.checkForUpdate();

    if (hasUpdate && mounted) {
      // Zeige Update-Dialog wenn Update verfügbar
      showUpdateDialogIfNeeded(context);
    }
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeInOut,
      ),
    );

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Titel
                  _buildTitle(),
                  const SizedBox(height: 24.0),
                  
                  // Haupt-App Button
                  _buildAppButton(
                    'Hauptanwendung',
                    Icons.castle,
                    DnDTheme.ancientGold,
                    () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const CampaignSelectionScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Demo App Button
                  _buildAppButton(
                    'Inventar-Demo',
                    Icons.inventory,
                    DnDTheme.arcaneBlue,
                    () => Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => const InventoryDemoApp(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Alle Screens Button
                  _buildAppButton(
                    'Alle Screens',
                    Icons.grid_view,
                    DnDTheme.warningOrange,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AllScreensScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16.0),
                  
                  // Screen Graph Visualizer Button
                  _buildAppButton(
                    'Screen Graph',
                    Icons.account_tree,
                    DnDTheme.mysticalPurple,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const ScreenGraphVisualizationScreen(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32.0),
                  
                  // Hinweis
                  _buildInfoCard(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        border: Border.all(
          color: DnDTheme.ancientGold,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Text(
        'Dungeon Manager',
        style: TextStyle(
          fontSize: 32.0,
          fontWeight: FontWeight.bold,
          color: DnDTheme.ancientGold,
          shadows: [
            Shadow(
              blurRadius: 15.0,
              color: DnDTheme.ancientGold.withOpacity(0.5),
              offset: const Offset(2.0, 2.0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppButton(
    String label,
    IconData icon,
    Color borderColor,
    VoidCallback onPressed,
  ) {
    return Container(
      width: double.infinity,
      height: 80.0,
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        border: Border.all(
          color: borderColor,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 32),
        label: Text(
          label,
          style: const TextStyle(fontSize: 20),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: borderColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.info_outline,
            color: DnDTheme.infoBlue,
            size: 24,
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Hauptanwendung: Vollständiger DM Helper mit allen Features',
            style: TextStyle(
              fontSize: 14,
              color: DnDTheme.infoBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Inventar-Demo: Zeigt das neue erweiterte Inventar-System',
            style: TextStyle(
              fontSize: 14,
              color: DnDTheme.infoBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Alle Screens: Testing-Übersicht aller verfügbaren Screens',
            style: TextStyle(
              fontSize: 14,
              color: DnDTheme.infoBlue,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8.0),
          const Text(
            'Screen Graph: Interaktiver Graph aller Screens und ihrer Verbindungen',
            style: TextStyle(
              fontSize: 14,
              color: DnDTheme.infoBlue,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}