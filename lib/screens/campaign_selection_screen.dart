import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/campaign.dart';
import '../viewmodels/campaign_viewmodel.dart';
import '../widgets/campaign/enhanced_campaign_card_widget.dart';
import '../widgets/campaign/enhanced_campaign_filter_chips_widget.dart';
import '../theme/dnd_theme.dart';
import 'enhanced_main_navigation_screen.dart';
import 'enhanced_edit_campaign_screen.dart';

/// Campaign Selection Screen - Startseite der Anwendung
/// 
/// Zeigt alle verfügbaren Kampagnen mit Filter- und Suchfunktionen.
/// Ermöglicht die Auswahl einer Kampagne für den Zugriff auf
/// kampagnenspezifische Inhalte und Funktionen.
class CampaignSelectionScreen extends StatefulWidget {
  const CampaignSelectionScreen({super.key});

  @override
  State<CampaignSelectionScreen> createState() => _CampaignSelectionScreenState();
}

class _CampaignSelectionScreenState extends State<CampaignSelectionScreen> {
  @override
  void initState() {
    super.initState();
    
    // Kampagnen werden automatisch im ViewModel geladen
    // Kein manueller refresh() Aufruf mehr nötig
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        // Navigation zur kampagnenspezifischen Hauptseite mit demselben ViewModel
        return _CampaignSelectionLayout();
      },
    );
  }
}

class _CampaignSelectionLayout extends StatelessWidget {
  const _CampaignSelectionLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      appBar: _buildAppBar(context),
      body: Consumer<CampaignViewModel>(
        builder: (context, viewModel, child) {
          return RefreshIndicator(
            onRefresh: () async => viewModel.refresh(),
            color: DnDTheme.ancientGold,
            child: Column(
              children: [
                // Filter und Suche Bereich
                _buildFilterSection(context, viewModel),
                
                // Kampagnen Liste oder Status
                Expanded(
                  child: _buildContent(context, viewModel),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  /// App Bar mit Titel und Quick Actions
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: DnDTheme.ancientGold.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.campaign,
              color: DnDTheme.ancientGold,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Kampagnen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Consumer<CampaignViewModel>(
                builder: (context, viewModel, child) {
                  return Text(
                    '${viewModel.campaigns.length} Kampagnen',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      backgroundColor: DnDTheme.dungeonBlack,
      elevation: 0,
      actions: [
        // Import Button
        IconButton(
          onPressed: () => _showImportDialog(context),
          icon: const Icon(Icons.upload_file, color: Colors.white),
          tooltip: 'Kampagne importieren',
        ),
        // Search Button
        IconButton(
          onPressed: () => _showSearchDialog(context),
          icon: const Icon(Icons.search, color: Colors.white),
          tooltip: 'Kampagnen suchen',
        ),
      ],
    );
  }

  /// Filter und Suche Bereich
  Widget _buildFilterSection(BuildContext context, CampaignViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: DnDTheme.stoneGrey.withValues(alpha: 0.1),
      child: EnhancedCampaignFilterChipsWidget(viewModel: viewModel),
    );
  }

  /// Hauptinhalt - entweder Kampagnenliste oder Status-Meldungen
  Widget _buildContent(BuildContext context, CampaignViewModel viewModel) {
    if (viewModel.isLoading) {
      return _buildLoadingState();
    }

    if (viewModel.error != null) {
      return _buildErrorState(context, viewModel);
    }

    final filteredCampaigns = viewModel.filteredCampaigns;
    
    if (filteredCampaigns.isEmpty) {
      if (viewModel.campaigns.isEmpty) {
        return _buildEmptyState(context);
      } else {
        return _buildNoResultsState(context);
      }
    }

    return _buildCampaignList(context, filteredCampaigns, viewModel);
  }

  /// Ladezustand anzeigen
  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(DnDTheme.ancientGold),
          ),
          SizedBox(height: 16),
          Text(
            'Kampagnen werden geladen...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  /// Fehlerzustand anzeigen
  Widget _buildErrorState(BuildContext context, CampaignViewModel viewModel) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: DnDTheme.getDungeonWallDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: DnDTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              'Fehler beim Laden',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.errorRed,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              viewModel.error!,
              textAlign: TextAlign.center,
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: viewModel.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.errorRed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Leerer Zustand - keine Kampagnen vorhanden
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        margin: const EdgeInsets.all(16),
        decoration: DnDTheme.getDungeonWallDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.campaign_outlined,
              size: 80,
              color: DnDTheme.ancientGold.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 24),
            Text(
              'Noch keine Kampagnen',
              style: DnDTheme.headline2.copyWith(
                color: DnDTheme.ancientGold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Erstelle deine erste Kampagne, um dein D&D Abenteuer zu beginnen!',
              textAlign: TextAlign.center,
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateCampaignDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Erste Kampagne erstellen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.ancientGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Keine Suchergebnisse
  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        margin: const EdgeInsets.all(16),
        decoration: DnDTheme.getDungeonWallDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: DnDTheme.infoBlue.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Kampagnen gefunden',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.infoBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versuche andere Suchbegriffe oder passe die Filter an.',
              textAlign: TextAlign.center,
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: () {
                // Filter zurücksetzen über ViewModel
                final viewModel = context.read<CampaignViewModel>();
                viewModel.clearSearch();
              },
              icon: const Icon(Icons.clear_all),
              label: const Text('Filter zurücksetzen'),
              style: TextButton.styleFrom(
                foregroundColor: DnDTheme.infoBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Kampagnen-Liste mit Cards
  Widget _buildCampaignList(
    BuildContext context,
    List<Campaign> campaigns,
    CampaignViewModel viewModel,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: campaigns.length,
      itemBuilder: (context, index) {
        final campaign = campaigns[index];
        return EnhancedCampaignCardWidget(
          campaign: campaign,
          onTap: () => _navigateToCampaign(context, campaign),
          onEdit: () => _editCampaign(context, campaign),
          onDelete: () => _deleteCampaign(context, campaign, viewModel),
          onDuplicate: () => _duplicateCampaign(context, campaign, viewModel),
        );
      },
    );
  }

  /// Floating Action Button für neue Kampagne
  Widget _buildFloatingActionButton(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateCampaignDialog(context),
      backgroundColor: DnDTheme.ancientGold,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add),
      label: const Text('Neue Kampagne'),
    );
  }

  /// Navigation zur kampagnenspezifischen Hauptseite
  void _navigateToCampaign(BuildContext context, Campaign campaign) async {
    // Kampagne im ViewModel auswählen
    final viewModel = context.read<CampaignViewModel>();
    await viewModel.selectCampaign(campaign);

    // Navigation zur kampagnenspezifischen Hauptnavigation mit demselben Provider
    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedMainNavigationScreen(
          campaign: campaign,
        ),
      ),
    );
  }

  /// Kampagne bearbeiten
  void _editCampaign(BuildContext context, Campaign campaign) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: context.read<CampaignViewModel>(),
          child: EnhancedEditCampaignScreen(campaign: campaign),
        ),
      ),
    );
  }

  /// Kampagne löschen mit Bestätigung
  void _deleteCampaign(
    BuildContext context,
    Campaign campaign,
    CampaignViewModel viewModel,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Kampagne löschen',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Möchtest du die Kampagne "${campaign.title}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: const TextStyle(color: Colors.white70),
        ),
        backgroundColor: DnDTheme.stoneGrey,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await viewModel.deleteCampaign(campaign);
            },
            style: TextButton.styleFrom(
              foregroundColor: DnDTheme.errorRed,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  /// Kampagne duplizieren
  void _duplicateCampaign(
    BuildContext context,
    Campaign campaign,
    CampaignViewModel viewModel,
  ) async {
    await viewModel.duplicateCampaign(campaign);
  }

  /// Dialog für neue Kampagne erstellen
  void _showCreateCampaignDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Neue Kampagne erstellen',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Titel',
                hintText: 'Name der Kampagne...',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                hintText: 'Kurze Beschreibung der Kampagne...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        backgroundColor: DnDTheme.stoneGrey,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.trim().isNotEmpty && descriptionController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  
                  // Erstelle Kampagne direkt über ViewModel
                  await context.read<CampaignViewModel>().createCampaign(
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                  );
                }
              },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }

  /// Import-Dialog (placeholder)
  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Kampagne importieren',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Import-Funktion wird in zukünftigen Versionen verfügbar.',
          style: TextStyle(color: Colors.white70),
        ),
        backgroundColor: DnDTheme.stoneGrey,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  /// Such-Dialog (alternativ zur Filter-Chip-Suche)
  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Kampagnen suchen',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Suchbegriff',
            hintText: 'Kampagnen durchsuchen...',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
          onSubmitted: (value) {
            Navigator.of(context).pop();
            final viewModel = context.read<CampaignViewModel>();
            viewModel.setSearchQuery(value);
          },
        ),
        backgroundColor: DnDTheme.stoneGrey,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              final viewModel = context.read<CampaignViewModel>();
              viewModel.setSearchQuery(searchController.text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: Colors.white,
            ),
            child: const Text('Suchen'),
          ),
        ],
      ),
    );
  }
}
