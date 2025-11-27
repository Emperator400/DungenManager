import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/campaign_viewmodel.dart';
import '../widgets/campaign/enhanced_campaign_card_widget.dart';
import '../widgets/campaign/enhanced_campaign_filter_chips_widget.dart';
import '../models/campaign.dart';
import 'enhanced_edit_campaign_screen.dart';
import 'session_list_for_campaign_screen.dart';

/// Enhanced Campaign Dashboard mit moderner Architektur
/// 
/// Nutzt das neue ViewModel-Pattern mit Service-Layer
/// für saubere Trennung von UI und Business Logic.
class EnhancedCampaignDashboardScreen extends StatefulWidget {
  const EnhancedCampaignDashboardScreen({Key? key}) : super(key: key);

  /// Factory Methode die den Provider automatisch einrichtet
  static Widget withProvider({Key? key}) {
    return ChangeNotifierProvider(
      create: (context) => CampaignViewModel(),
      child: EnhancedCampaignDashboardScreen(key: key),
    );
  }

  @override
  State<EnhancedCampaignDashboardScreen> createState() => _EnhancedCampaignDashboardScreenState();
}

class _EnhancedCampaignDashboardScreenState extends State<EnhancedCampaignDashboardScreen>
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
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Übersicht'),
            Tab(icon: Icon(Icons.home), text: 'Homebrew'),
            Tab(icon: Icon(Icons.book), text: 'Module'),
            Tab(icon: Icon(Icons.map), text: 'Paths'),
            Tab(icon: Icon(Icons.flash_on), text: 'One-Shots'),
          ],
          labelColor: Theme.of(context).tabBarTheme.labelColor,
          unselectedLabelColor: Theme.of(context).tabBarTheme.unselectedLabelColor,
          indicatorColor: Theme.of(context).tabBarTheme.indicatorColor,
        ),
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
          // Prüfe sowohl Gesamtanzahl als auch gefilterte Anzahl
          if (viewModel.campaigns.isNotEmpty && viewModel.filteredCampaigns.isNotEmpty) {
            return FloatingActionButton(
              onPressed: () => _showCreateCampaignDialog(),
              backgroundColor: Theme.of(context).primaryColor,
              child: const Icon(Icons.add),
            );
          }
          
          // Kein FloatingActionButton wenn keine Kampagnen existieren
          // (der Button wird im leeren Zustand angezeigt)
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
              // Search Field
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
              
              // Filter Chips
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
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChangeNotifierProvider.value(
                          value: context.read<CampaignViewModel>(),
                          child: const EnhancedEditCampaignScreen(),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Kampagne erstellen'),
                  ),
                ],
              ],
            ),
          );
        }

        // Sort order toggle
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
            
            // Campaign Grid
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
                    return EnhancedCampaignCardWidget(
                      campaign: campaign,
                      onTap: () => _navigateToCampaign(campaign),
                      onEdit: () => _editCampaign(campaign),
                      onDelete: () => _deleteCampaign(campaign),
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
            return EnhancedCampaignCardWidget(
              campaign: campaign,
              onTap: () => _navigateToCampaign(campaign),
              onEdit: () => _editCampaign(campaign),
              onDelete: () => _deleteCampaign(campaign),
              onDuplicate: () => _duplicateCampaign(campaign),
              onToggleFavorite: () => _toggleFavorite(campaign),
            );
          },
        );
      },
    );
  }

  CampaignStatus? _getSelectedStatus(CampaignViewModel viewModel) {
    // Implementiere Status-Filter basierend auf viewModel.state
    return null; // Placeholder
  }

  void _showCreateCampaignDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: context.read<CampaignViewModel>(),
          child: const EnhancedEditCampaignScreen(),
        ),
      ),
    ).then((_) {
      // Kampagnen neu laden, wenn man vom Edit-Screen zurückkommt
      debugPrint('Dashboard: Returned from create campaign screen, calling refresh()');
      context.read<CampaignViewModel>().refresh();
    });
  }

  void _navigateToCampaign(Campaign campaign) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SessionListForCampaignScreen(campaign: campaign),
      ),
    );
  }

  void _editCampaign(Campaign campaign) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider.value(
          value: context.read<CampaignViewModel>(),
          child: EnhancedEditCampaignScreen(campaign: campaign),
        ),
      ),
    ).then((_) {
      // Kampagnen neu laden, wenn man vom Edit-Screen zurückkommt
      debugPrint('Dashboard: Returned from edit campaign screen, calling refresh()');
      context.read<CampaignViewModel>().refresh();
    });
  }

  void _deleteCampaign(Campaign campaign) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kampagne löschen'),
        content: Text(
          'Möchtest du die Kampagne "${campaign.title}" wirklich löschen? '
          'Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<CampaignViewModel>().deleteCampaign(campaign);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }

  void _duplicateCampaign(Campaign campaign) async {
    await context.read<CampaignViewModel>().duplicateCampaign(campaign);
  }

  void _toggleFavorite(Campaign campaign) async {
    await context.read<CampaignViewModel>().toggleFavorite(campaign);
  }
}

/// Dialog zum Erstellen einer neuen Kampagne
class _CreateCampaignDialog extends StatefulWidget {
  @override
  State<_CreateCampaignDialog> createState() => _CreateCampaignDialogState();
}

class _CreateCampaignDialogState extends State<_CreateCampaignDialog> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  CampaignType _selectedType = CampaignType.homebrew;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Neue Kampagne erstellen',
        style: TextStyle(
          color: Theme.of(context).textTheme.titleLarge?.color,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                labelText: 'Titel *',
                hintText: 'Name der Kampagne',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descriptionController,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                labelText: 'Beschreibung *',
                hintText: 'Kurze Beschreibung der Kampagne',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                hintStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<CampaignType>(
              value: _selectedType,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
              decoration: InputDecoration(
                labelText: 'Kampagnen-Typ',
                labelStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(
                    color: Theme.of(context).primaryColor,
                    width: 2,
                  ),
                ),
              ),
              items: CampaignType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(
                    type.displayName,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (type) => setState(() => _selectedType = type!),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Abbrechen',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        ElevatedButton(
          onPressed: _createCampaign,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: const Text('Erstellen'),
        ),
      ],
    );
  }

  void _createCampaign() async {
    if (_titleController.text.trim().isEmpty || 
        _descriptionController.text.trim().isEmpty) {
      return;
    }

    Navigator.pop(context);
    
    await context.read<CampaignViewModel>().createCampaign(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
    );
  }
}

/// Extension für CampaignType Display Names
extension CampaignTypeExtension on CampaignType {
  String get displayName {
    switch (this) {
      case CampaignType.homebrew:
        return 'Homebrew';
      case CampaignType.module:
        return 'Module';
      case CampaignType.adventurePath:
        return 'Adventure Path';
      case CampaignType.oneShot:
        return 'One-Shot';
    }
  }
}
