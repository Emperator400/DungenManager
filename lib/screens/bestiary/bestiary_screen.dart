import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/bestiary_viewmodel.dart';
import '../../widgets/bestiary/bestiary_search_filter_bar.dart';
import '../../widgets/bestiary/bestiary_creatures_tab.dart';
import '../../widgets/bestiary/bestiary_importer_tab.dart';
import '../../widgets/bestiary/bestiary_fab.dart';
import '../../widgets/bestiary/bestiary_dialogs.dart';

class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> 
    with TickerProviderStateMixin {
  late BestiaryViewModel _viewModel;
  late TabController _tabController;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = BestiaryViewModel();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      await _viewModel.loadCreatures();
      await _viewModel.loadDndData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _importFrom5eTools() async {
    try {
      final count = await _viewModel.importMonstersFrom5eTools();
      await _viewModel.loadDndData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count Monster von 5e.tools importiert'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Import: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<BestiaryViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: DnDTheme.dungeonBlack,
        appBar: AppBar(
          title: Text(
            "Bestiarum",
            style: DnDTheme.headline2.copyWith(
              color: DnDTheme.ancientGold,
            ),
          ),
          backgroundColor: DnDTheme.stoneGrey,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: true,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(120),
            child: BestiarySearchFilterBar(searchController: _searchController),
          ),
          actions: [
            Container(
              margin: const EdgeInsets.only(right: DnDTheme.sm),
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.arcaneBlue,
                width: 2,
              ),
              child: IconButton(
                icon: const Icon(Icons.download),
                tooltip: "Monster importieren",
                onPressed: () => showBestiaryImportDialog(
                  context: context,
                  viewModel: _viewModel,
                  onImport: _importFrom5eTools,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: DnDTheme.sm),
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.errorRed,
                width: 2,
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: "Bestiarum zurücksetzen",
                onPressed: () => showBestiaryResetDialog(
                  context: context,
                  viewModel: _viewModel,
                ),
              ),
            ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            BestiaryCreaturesTab(
              tabType: BestiaryTabType.all,
              title: "Alle Kreaturen",
              searchController: _searchController,
              onDataChanged: _loadData,
            ),
            BestiaryCreaturesTab(
              tabType: BestiaryTabType.custom,
              title: "Eigene Kreaturen",
              searchController: _searchController,
              onDataChanged: _loadData,
            ),
            BestiaryCreaturesTab(
              tabType: BestiaryTabType.official,
              title: "Offizielle Monster",
              searchController: _searchController,
              onDataChanged: _loadData,
            ),
            BestiaryImporterTab(
              viewModel: _viewModel,
              onDataChanged: _loadData,
            ),
          ],
        ),
        floatingActionButton: BestiaryFab(
          tabController: _tabController,
          onDataChanged: _loadData,
        ),
      ),
    );
  }
}