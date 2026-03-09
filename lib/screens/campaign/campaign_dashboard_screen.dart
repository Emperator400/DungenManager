// campaign_dashboard_screen.dart alt - nicht verwenden


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/campaign.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/campaign_viewmodel.dart';
import '../../widgets/campaign/campaign_create_dialog_widget.dart';
import '../../widgets/campaign/campaign_tabs_widget.dart';
import '../../widgets/campaign/enhanced_campaign_filter_chips_widget.dart';
import '../../widgets/ui_components/cards/unified_campaign_card.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';

import 'edit_campaign_screen.dart';
import 'session_list_for_campaign_screen.dart';

/// Campaign Dashboard mit moderner Architektur
/// 
/// Nutzt das neue ViewModel-Pattern mit Service-Layer
/// für saubere Trennung von UI und Business Logic.
class CampaignDashboardScreen extends StatefulWidget {
  const CampaignDashboardScreen({Key? key}) : super(key: key);

  /// Factory Methode die den Provider automatisch einrichtet
  static Widget withProvider({Key? key}) {
    return ChangeNotifierProvider(
      create: (context) => CampaignViewModel(),
      child: CampaignDashboardScreen(key: key),
    );
  }

  @override
  State<CampaignDashboardScreen> createState() => _CampaignDashboardScreenState();
}

class _CampaignDashboardScreenState extends State<CampaignDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Search listener für reactive updates
    _searchController.addListener(() {
      context.read<CampaignViewModel>().setSearchQuery(_searchController.text);
    });
    
    // Kampagnen initial laden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Dashboard: Calling initial refresh()');
      context.read<CampaignViewModel>().refresh();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Kampagnen Dashboard'),
        backgroundColor: DnDTheme.dungeonBlack,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DnDTheme.dungeonBlack,
                DnDTheme.stoneGrey.withOpacity(0.3),
              ],
            ),
          ),
        ),
        bottom: CampaignTabsWidget(tabController: _tabController),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateCampaignDialog(),
            tooltip: 'Neue Kampagne',
          ),
          PopupMenuButton<CampaignSortOption>(
            icon: const Icon(Icons.sort),
            onSelected: (option) {
              context.read<CampaignViewModel>().setSortOption(option);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: CampaignSortOption.name,
                child: Text('Nach Name sortieren'),
              ),
              const PopupMenuItem(
                value: CampaignSortOption.createdDate,
                child: Text('Nach Erstellungsdatum'),
              ),
              const PopupMenuItem(
                value: CampaignSortOption.lastActive,
                child: Text('Nach letzter Aktivität'),
              ),
              const PopupMenuItem(
                value: CampaignSortOption.heroCount,
                child: Text('Nach Heldenanzahl'),
              ),
              const PopupMenuItem(
                value: CampaignSortOption.sessionCount,
                child: Text('Nach Session-Anzahl'),
              ),
              const PopupMenuItem(
                value: CampaignSortOption.questCount,
                child: Text('Nach Quest-Anzahl'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Search und Filter
          _buildSearchAndFilter(),
          
          // Campaign Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildCampaignList(), // Alle Kampagnen
                _buildCampaignListByType(CampaignType.homebrew),
                _buildCampaignListByType(CampaignType.module),
                _buildCampaignListByType(CampaignType.adventurePath),
                _buildCampaignListByType(CampaignType.oneShot),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Consumer<CampaignViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const FloatingActionButton(
              onPressed: null,
              child: CircularProgressIndicator(),
            );
          }
          
          // Zeige FloatingActionButton nur wenn Kampagnen existieren
          if (viewModel.campaigns.isNotEmpty && viewModel.filteredCampaigns.isNotEmpty) {
            return FloatingActionButton(
              onPressed: () => _showCreateCampaignDialog(),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add),
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Consumer<CampaignViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor,
                width: 1,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Kampagnen durchsuchen...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: viewModel.searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            viewModel.clearSearch();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  filled: true,
                  fillColor: Theme.of(context).scaffoldBackgroundColor,
                ),
              ),
              
              const SizedBox(height: 12),
              
              EnhancedCampaignFilterChipsWidget(
                viewModel: viewModel,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCampaignList() {
    return Consumer<CampaignViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.isLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (viewModel.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Fehler beim Laden der Kampagnen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  viewModel.error!,
                  style: TextStyle(color: Theme.of(context).disabledColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => viewModel.refresh(),
                  child: const Text('Erneut versuchen'),
                ),
              ],
            ),
          );
        }

        if (viewModel.filteredCampaigns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.campaign_outlined,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  viewModel.searchQuery.isNotEmpty
                      ? 'Keine Kampagnen gefunden'
                      : 'Noch keine Kampagnen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
                if (viewModel.searchQuery.isEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Erstelle deine erste Kampagne',
                    style: TextStyle(color: Theme.of(context).disabledColor),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateCampaignDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Kampagne erstellen'),
                  ),
                ],
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    '${viewModel.filteredCampaigns.length} Kampagnen',
                    style: TextStyle(
                      color: Theme.of(context).disabledColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      viewModel.ascendingOrder 
                          ? Icons.arrow_upward 
                          : Icons.arrow_downward,
                    ),
                    onPressed: () => viewModel.toggleSortOrder(),
                    tooltip: viewModel.ascendingOrder 
                        ? 'Absteigend sortieren' 
                        : 'Aufsteigend sortieren',
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: viewModel.filteredCampaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = viewModel.filteredCampaigns[index];
                    return UnifiedCampaignCard(
                      campaign: campaign,
                      viewModel: viewModel,
                      onNavigate: () => _navigateToCampaign(campaign),
                      onEdit: () => _editCampaign(campaign),
                      onDuplicate: () => _duplicateCampaign(campaign),
                      onToggleFavorite: () => _toggleFavorite(campaign),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCampaignListByType(CampaignType type) {
    return Consumer<CampaignViewModel>(
      builder: (context, viewModel, child) {
        final typeCampaigns = viewModel.filteredCampaigns
            .where((campaign) => campaign.type == type)
            .toList();

        if (typeCampaigns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.folder_open,
                  size: 64,
                  color: Theme.of(context).disabledColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'Keine ${type.name} Kampagnen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).disabledColor,
                  ),
                ),
              ],
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: typeCampaigns.length,
          itemBuilder: (context, index) {
            final campaign = typeCampaigns[index];
            return UnifiedCampaignCard(
              campaign: campaign,
              viewModel: viewModel,
              onNavigate: () => _navigateToCampaign(campaign),
              onEdit: () => _editCampaign(campaign),
              onDuplicate: () => _duplicateCampaign(campaign),
              onToggleFavorite: () => _toggleFavorite(campaign),
            );
          },
        );
      },
    );
  }

  void _showCreateCampaignDialog() {
    final viewModel = context.read<CampaignViewModel>();
    CampaignCreateDialogWidget.show(
      context,
      viewModel: viewModel,
      onSuccess: () => viewModel.refresh(),
    );
  }

  void _editCampaign(Campaign campaign) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: context.read<CampaignViewModel>(),
          child: EditCampaignScreen(campaign: campaign),
        ),
      ),
    );
  }

  Future<void> _duplicateCampaign(Campaign campaign) async {
    final viewModel = context.read<CampaignViewModel>();
    try {
      await viewModel.duplicateCampaign(campaign);
      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Kampagne dupliziert');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Duplizieren: $e');
      }
    }
  }

  Future<void> _toggleFavorite(Campaign campaign) async {
    final viewModel = context.read<CampaignViewModel>();
    try {
      await viewModel.updateCampaign(
        campaign.copyWith(isFavorite: !campaign.isFavorite),
      );
      
      if (mounted) {
        SnackBarHelper.showInfo(
          context,
          campaign.isFavorite 
            ? 'Kampagne von Favoriten entfernt' 
            : 'Kampagne als Favorit markiert',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Aktualisieren: $e');
      }
    }
  }

  Future<void> _toggleActive(Campaign campaign) async {
    final viewModel = context.read<CampaignViewModel>();
    try {
      final newStatus = campaign.status == CampaignStatus.active 
        ? CampaignStatus.paused 
        : CampaignStatus.active;
      
      await viewModel.updateCampaign(
        campaign.copyWith(status: newStatus),
      );
      
      if (mounted) {
        SnackBarHelper.showInfo(
          context,
          newStatus == CampaignStatus.active 
            ? 'Kampagne als aktiv markiert' 
            : 'Kampagne als inaktiv markiert',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Fehler beim Aktualisieren: $e');
      }
    }
  }

  void _navigateToCampaign(Campaign campaign) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionListForCampaignScreen(campaign: campaign),
      ),
    );
  }
}