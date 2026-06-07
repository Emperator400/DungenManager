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
import 'package:window_manager/window_manager.dart';
import 'package:firebase_core/firebase_core.dart';

// 3. Eigene Projekte (absolute Pfade von lib/)
import 'screens/campaign/campaign_selection_screen.dart';
import 'screens/navigation/home_screen.dart';
import 'screens/navigation/all_screens_screen.dart';
import 'screens/debug/screen_graph_visualization_screen.dart';
import 'screens/debug/widgets_test_grund.dart';
import 'inventory_demo_app.dart';
import 'theme/dnd_theme.dart';
import 'theme/app_theme.dart';
import 'theme/theme_notifier.dart';
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
import 'database/repositories/encounter_model_repository.dart';
import 'database/repositories/player_model_repository.dart';
import 'database/repositories/ort_model_repository.dart';
import 'viewmodels/player_viewmodel.dart';
import 'services/player_service.dart';
import 'viewmodels/update_viewmodel.dart';
import 'widgets/ui_components/shared/app_logo.dart';
import 'widgets/ui_components/shared/app_title_bar.dart';
import 'widgets/update_dialog.dart';
import 'services/multi_stream_sound_service.dart';
import 'services/image_storage_service.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/campaign_sync_service.dart';
import 'viewmodels/auth_viewmodel.dart';

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

// Custom Window Frame für Desktop initialisieren
  if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
    await windowManager.ensureInitialized();
    const windowOptions = WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(900, 600),
      center: true,
      title: 'DungeonManager',
      titleBarStyle: TitleBarStyle.hidden,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  // Firebase initialisieren (nicht auf Windows — precompilierte Libs inkompatibel mit VS 2026)
  if (!Platform.isWindows) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  // Windows-Session aus SharedPreferences wiederherstellen (vor runApp!)
  await AuthService.restoreSession();

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
    debugPrint('🗄️ SQLite FFI für Desktop initialisiert');
  }
  
  // Initialisiere Datenbank und führe Migrationen aus
  try {
    final dbConnection = DatabaseConnection.instance;
    await dbConnection.database;
    debugPrint('✅ Datenbank-Verbindung erfolgreich getestet');
    
    // Führe Datenbank-Migrationen aus
    final migration = DatabaseMigration(dbConnection);
    await migration.runMigrations();
    debugPrint('✅ Datenbank-Migrationen erfolgreich ausgeführt');
    
    // Migriere alle bestehenden Bilder in den Update-sicheren Documents-Ordner
    await ImageStorageService.migrateExistingImages();
     
  } catch (e) {
    debugPrint('❌ Fehler beim Initialisieren der Datenbank: $e');
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
    debugPrint('Audio Kontext erfolgreich konfiguriert');
  } catch (e) {
    debugPrint('Fehler bei der Audio-Konfiguration: $e');
  }
}

final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

/// Haupt-App Klasse
class DmApp extends StatelessWidget {
  const DmApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dbConnection = DatabaseConnection.instance;
  
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        // Auth + Cloud Sync (muss vor CampaignViewModel stehen)
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(authService: AuthService()),
        ),
        Provider<CampaignSyncService>(
          create: (_) => CampaignSyncService(
            AuthService(),
            OrtModelRepository(dbConnection),
            SceneModelRepository(dbConnection),
            QuestModelRepository(dbConnection),
          ),
        ),
        ChangeNotifierProxyProvider<AuthViewModel, CampaignViewModel>(
          create: (_) => CampaignViewModel(
            campaignRepo: CampaignModelRepository(dbConnection),
            characterRepo: PlayerCharacterModelRepository(dbConnection),
          ),
          update: (context, authVm, vm) {
            vm!.bindCloudSync(authVm.user, context.read<CampaignSyncService>());
            return vm;
          },
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
        Provider<EncounterModelRepository>(
          create: (_) => EncounterModelRepository(dbConnection),
        ),
        Provider<PlayerModelRepository>(
          create: (_) => PlayerModelRepository(dbConnection),
        ),
        ChangeNotifierProvider(
          create: (_) => PlayerViewModel(
            playerService: PlayerService(
              playerRepository: PlayerModelRepository(dbConnection),
              characterRepository: PlayerCharacterModelRepository(dbConnection),
            ),
          ),
        ),
        // Update ViewModel für Auto-Update-Check
        ChangeNotifierProvider(
          create: (_) {
            final viewModel = UpdateViewModel();
            viewModel.init();
            return viewModel;
          },
        ),
        // Multi-Stream Sound Service (Singleton für app-weiten Audio-Mixer)
        ChangeNotifierProvider(
          create: (_) => MultiStreamSoundService(),
        ),
      ],
      child: Consumer<ThemeNotifier>(
        builder: (context, themeNotifier, _) => MaterialApp(
          title: 'Dungeon Manager',
          navigatorKey: _navigatorKey,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: themeNotifier.themeMode,
          home: kIsProductionMode
              ? const HomeScreen()
              : const AppSelectionScreen(),
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
              return Column(
                children: [
                  AppTitleBar(navigatorKey: _navigatorKey),
                  Expanded(child: child!),
                ],
              );
            }
            return child!;
          },
        ),
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
  UpdateViewModel? _updateViewModel;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkForUpdates();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sichere Referenz auf UpdateViewModel speichern (wie von Flutter empfohlen)
    _updateViewModel ??= context.read<UpdateViewModel>();
  }

  /// Prüft automatisch auf Updates beim Start
  Future<void> _checkForUpdates() async {
    if (_updateChecked) return;
    _updateChecked = true;

    // Kurze Verzögerung damit die UI geladen ist
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted || _updateViewModel == null) return;

    final hasUpdate = await _updateViewModel!.checkForUpdate();

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
                  const SizedBox(height: 16.0),
                  _buildAppButton(
                    "sound Mixer Test",
                    Icons.music_note,
                    DnDTheme.infoBlue,
                    () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (context) => const WidgetTestGround()
                     ),
                    )
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
    const accent = Color(0xFF7C3AED);
    return const Column(
      children: [
        AppLogo(size: 64, color: accent),
        SizedBox(height: 16),
        Text(
          'Dungeon Manager',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: accent,
          ),
        ),
      ],
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