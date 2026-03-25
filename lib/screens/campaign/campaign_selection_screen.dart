import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/campaign_viewmodel.dart';
import '../../viewmodels/update_viewmodel.dart';
import '../../widgets/update_dialog.dart';
import '../../widgets/campaign/campaign_create_dialog_widget.dart';
import '../../widgets/campaign/enhanced_campaign_filter_chips_widget.dart';
import '../../widgets/ui_components/cards/unified_campaign_card.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';
import '../../widgets/ui_components/states/empty_state_widget.dart';
import '../../widgets/ui_components/states/error_state_widget.dart';
import '../../widgets/ui_components/states/loading_state_widget.dart';

import './edit_campaign_screen.dart';
import '../navigation/main_navigation_screen.dart';

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
  bool _updateChecked = false;
  UpdateViewModel? _updateViewModel;

  @override
  void initState() {
    super.initState();
    // Lade Kampagnen beim Start des Screens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CampaignViewModel>().loadCampaigns();
      _checkForUpdates();
    });
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
      await showUpdateDialogIfNeeded(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return const _CampaignSelectionLayout();
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
                _buildFilterSection(context, viewModel),
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
        IconButton(
          onPressed: () => _checkForUpdatesManually(context),
          icon: const Icon(Icons.system_update_alt, color: Colors.white),
          tooltip: 'Nach Updates suchen',
        ),
        IconButton(
          onPressed: () => _showSearchDialog(context),
          icon: const Icon(Icons.search, color: Colors.white),
          tooltip: 'Kampagnen suchen',
        ),
      ],
    );
  }

  Widget _buildFilterSection(BuildContext context, CampaignViewModel viewModel) {
    return Card(
      margin: const EdgeInsets.all(16),
      color: DnDTheme.stoneGrey.withValues(alpha: 0.1),
      child: EnhancedCampaignFilterChipsWidget(viewModel: viewModel),
    );
  }

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

  Widget _buildLoadingState() {
    return LoadingStateWidget.withMessage(
      message: 'Kampagnen werden geladen...',
      color: DnDTheme.ancientGold,
    );
  }

  Widget _buildErrorState(BuildContext context, CampaignViewModel viewModel) {
    return ErrorStateWidget.withRetry(
      title: 'Fehler beim Laden',
      message: viewModel.error,
      onRetry: viewModel.refresh,
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget.withCreate(
      title: 'Noch keine Kampagnen',
      message: 'Erstelle deine erste Kampagne, um dein D&D Abenteuer zu beginnen!',
      icon: Icons.campaign_outlined,
      iconColor: DnDTheme.ancientGold,
      onCreate: () => _showCreateCampaignDialog(context),
      buttonText: 'Erste Kampagne erstellen',
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return EmptyStateWidget.withClearFilters(
      title: 'Keine Kampagnen gefunden',
      message: 'Versuche andere Suchbegriffe oder passe die Filter an.',
      icon: Icons.search_off,
      iconColor: DnDTheme.infoBlue,
      onClearFilters: () {
        final viewModel = context.read<CampaignViewModel>();
        viewModel.clearSearch();
      },
    );
  }

  Widget _buildCampaignList(
    BuildContext context,
    List<Campaign> campaigns,
    CampaignViewModel viewModel,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: campaigns.length,
      itemBuilder: (ctx, index) {
        final campaign = campaigns[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: UnifiedCampaignCard(
            campaign: campaign,
            viewModel: viewModel,
            onNavigate: () => _navigateToCampaign(context, campaign),
            onEdit: () => _editCampaign(context, campaign),
            onDuplicate: () => _duplicateCampaign(context, campaign, viewModel),
            onToggleFavorite: () => _toggleFavorite(context, campaign, viewModel),
          ),
        );
      },
    );
  }

  void _editCampaign(BuildContext context, Campaign campaign) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: context.read<CampaignViewModel>(),
          child: EditCampaignScreen(campaign: campaign),
        ),
      ),
    );
  }

  Future<void> _duplicateCampaign(
    BuildContext context,
    Campaign campaign,
    CampaignViewModel viewModel,
  ) async {
    try {
      await viewModel.duplicateCampaign(campaign);
      if (context.mounted) {
        SnackBarHelper.showSuccess(context, 'Kampagne dupliziert');
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Duplizieren: $e');
      }
    }
  }

  Future<void> _toggleFavorite(
    BuildContext context,
    Campaign campaign,
    CampaignViewModel viewModel,
  ) async {
    try {
      await viewModel.updateCampaign(
        campaign.copyWith(isFavorite: !campaign.isFavorite),
      );
      
      if (context.mounted) {
        SnackBarHelper.showInfo(
          context,
          campaign.isFavorite 
            ? 'Kampagne von Favoriten entfernt' 
            : 'Kampagne als Favorit markiert',
        );
      }
    } catch (e) {
      if (context.mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Aktualisieren: $e');
      }
    }
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    return Consumer<CampaignViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.campaigns.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return FloatingActionButton.extended(
          onPressed: () => _showCreateCampaignDialog(context),
          backgroundColor: DnDTheme.ancientGold,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Neue Kampagne'),
        );
      },
    );
  }

  void _navigateToCampaign(BuildContext context, Campaign campaign) async {
    final viewModel = context.read<CampaignViewModel>();
    await viewModel.selectCampaign(campaign);

    if (!context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedMainNavigationScreen(
          campaign: campaign,
        ),
      ),
    );
  }

  void _showCreateCampaignDialog(BuildContext context) {
    final viewModel = context.read<CampaignViewModel>();
    CampaignCreateDialogWidget.show(
      context,
      viewModel: viewModel,
      onSuccess: () => viewModel.refresh(),
    );
  }

  /// Prüft manuell auf Updates und zeigt das Ergebnis an
  Future<void> _checkForUpdatesManually(BuildContext context) async {
    final viewModel = context.read<UpdateViewModel>();
    
    // Zeige Lade-Indikator
    SnackBarHelper.showInfo(context, 'Prüfe auf Updates...');
    
    // Prüfe auf Updates
    await viewModel.checkForUpdate();
    
    if (!context.mounted) return;
    
    if (viewModel.availableUpdate != null) {
      // Zeige das vollständige UpdateDialog Widget mit Patchnotes
      await showUpdateDialogIfNeeded(context, forceShow: true);
    } else if (viewModel.errorMessage != null) {
      // Fehler beim Prüfen
      SnackBarHelper.showError(context, 'Fehler beim Prüfen: ${viewModel.errorMessage}');
    } else {
      // Kein Update verfügbar
      SnackBarHelper.showSuccess(context, 'Du verwendest bereits die neueste Version!');
    }
  }

  void _showSearchDialog(BuildContext context) async {
    final viewModel = context.read<CampaignViewModel>();
    
    final selectedCampaign = await showDialog<Campaign>(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Kampagnen suchen'),
        backgroundColor: DnDTheme.stoneGrey,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: viewModel.campaigns.map((campaign) {
                return ListTile(
                  title: Text(campaign.title),
                  subtitle: Text(campaign.description),
                  onTap: () {
                    Navigator.of(context).pop(campaign);
                  },
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
    
    if (selectedCampaign != null) {
      _navigateToCampaign(context, selectedCampaign);
    }
  }
}
