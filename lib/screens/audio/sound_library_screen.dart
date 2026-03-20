import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../viewmodels/sound_library_viewmodel.dart';
import '../../viewmodels/edit_sound_viewmodel.dart';
import '../../models/sound.dart';
import '../../theme/dnd_theme.dart';
import '../../widgets/sound_scenes_tab.dart';
import '../../widgets/audio/sound_player_widget.dart';
import 'edit_sound_screen.dart';

/// Enhanced Sound Library Screen mit Provider-Pattern und modernem D&D Design
class SoundLibraryScreen extends StatefulWidget {
  const SoundLibraryScreen({super.key});

  @override
  State<SoundLibraryScreen> createState() => _SoundLibraryScreenState();
}

class _SoundLibraryScreenState extends State<SoundLibraryScreen> 
    with TickerProviderStateMixin {
  late SoundLibraryViewModel _viewModel;
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _sceneSearchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = SoundLibraryViewModel();
    _tabController = TabController(length: 2, vsync: this);
    _viewModel.initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    _tabController.dispose();
    _searchController.dispose();
    _sceneSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SoundLibraryViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: DnDTheme.dungeonBlack,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<SoundLibraryViewModel>(
        builder: (context, viewModel, child) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sound & Atmosphäre',
                style: DnDTheme.headline2.copyWith(
                  color: DnDTheme.ancientGold,
                ),
              ),
              Text(
                '${viewModel.soundCount} Sounds • ${viewModel.favoriteCount} Favoriten',
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          );
        },
      ),
      backgroundColor: DnDTheme.stoneGrey,
      foregroundColor: Colors.white,
      elevation: 4,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: DnDTheme.stoneGrey,
            endColor: DnDTheme.slateGrey,
          ),
        ),
      ),
      bottom: TabBar(
        controller: _tabController,
        onTap: (index) => _viewModel.setCurrentTabIndex(index),
        indicatorColor: DnDTheme.ancientGold,
        labelStyle: DnDTheme.bodyText1.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: DnDTheme.bodyText1.copyWith(
          color: Colors.white70,
        ),
        tabs: const [
          Tab(
            icon: Icon(Icons.music_note),
            text: 'Sounds',
          ),
          Tab(
            icon: Icon(Icons.movie_filter),
            text: 'Szenen',
          ),
        ],
      ),
      actions: [
        Consumer<SoundLibraryViewModel>(
          builder: (context, viewModel, child) {
            return Container(
              margin: const EdgeInsets.only(right: DnDTheme.sm),
              decoration: DnDTheme.getMysticalBorder(
                borderColor: DnDTheme.arcaneBlue,
                width: 2,
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: DnDTheme.stoneGrey,
                onSelected: _handleMenuAction,
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'reset_filters',
                    child: Row(
                      children: [
                        Icon(Icons.refresh, color: DnDTheme.ancientGold, size: 20),
                        const SizedBox(width: DnDTheme.sm),
                        Text(
                          'Filter zurücksetzen',
                          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'toggle_favorites',
                    child: Row(
                      children: [
                        Icon(
                          viewModel.showFavoritesOnly 
                              ? Icons.favorite 
                              : Icons.favorite_border,
                          color: DnDTheme.errorRed,
                          size: 20,
                        ),
                        const SizedBox(width: DnDTheme.sm),
                        Text(
                          viewModel.showFavoritesOnly 
                              ? 'Alle anzeigen' 
                              : 'Nur Favoriten',
                          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Consumer<SoundLibraryViewModel>(
      builder: (context, viewModel, child) {
        if (viewModel.hasError) {
          return _buildErrorWidget(viewModel);
        }

        return TabBarView(
          controller: _tabController,
          children: [
            _buildSoundsTab(viewModel),
            _buildScenesTab(viewModel),
          ],
        );
      },
    );
  }

  Widget _buildSoundsTab(SoundLibraryViewModel viewModel) {
    return Column(
      children: [
        // Search und Filter Bar
        _buildSoundFilterBar(viewModel),
        
        // Sound Type Filter Chips
        _buildSoundTypeFilterChips(viewModel),
        
        // Content
        Expanded(
          child: viewModel.isLoadingSounds
              ? _buildLoadingWidget('Sounds werden geladen...')
              : viewModel.sounds.isEmpty
                  ? _buildEmptyState('Keine Sounds gefunden')
                  : _buildSoundsList(viewModel),
        ),
      ],
    );
  }

  Widget _buildScenesTab(SoundLibraryViewModel viewModel) {
    return Column(
      children: [
        // Search Bar für Szenen
        _buildSceneSearchBar(viewModel),
        
        // Content
        Expanded(
          child: viewModel.isLoadingScenes
              ? _buildLoadingWidget('Szenen werden geladen...')
              : viewModel.scenes.isEmpty
                  ? _buildEmptyState('Keine Szenen gefunden')
                  : SoundScenesTab(), // Bestehendes Widget wiederverwenden
        ),
      ],
    );
  }

  Widget _buildSoundFilterBar(SoundLibraryViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.ancientGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Sounds suchen...',
                hintStyle: DnDTheme.bodyText2.copyWith(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
                suffixIcon: viewModel.soundSearchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: DnDTheme.errorRed),
                        onPressed: () {
                          _searchController.clear();
                          viewModel.setSoundSearchQuery('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  borderSide: BorderSide(
                    color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                  borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                ),
                filled: true,
                fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
              ),
              onChanged: (value) => viewModel.setSoundSearchQuery(value),
            ),
          ),
          const SizedBox(width: DnDTheme.sm),
          Container(
            decoration: BoxDecoration(
              gradient: DnDTheme.getMysticalGradient(
                startColor: DnDTheme.arcaneBlue,
                endColor: DnDTheme.mysticalPurple,
              ),
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            ),
            child: IconButton(
              icon: const Icon(Icons.sort, color: Colors.white),
              onPressed: () => _showSortOptions(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSceneSearchBar(SoundLibraryViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.ancientGold.withValues(alpha: 0.3),
        ),
      ),
      child: TextField(
        controller: _sceneSearchController,
        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Szenen suchen...',
          hintStyle: DnDTheme.bodyText2.copyWith(color: Colors.white54),
          prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
          suffixIcon: viewModel.sceneSearchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: DnDTheme.errorRed),
                  onPressed: () {
                    _sceneSearchController.clear();
                    viewModel.setSceneSearchQuery('');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            borderSide: BorderSide(color: DnDTheme.mysticalPurple),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            borderSide: BorderSide(
              color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
            borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
          ),
          filled: true,
          fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
        ),
        onChanged: (value) => viewModel.setSceneSearchQuery(value),
      ),
    );
  }

  Widget _buildSoundTypeFilterChips(SoundLibraryViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DnDTheme.md, vertical: DnDTheme.sm),
      child: Wrap(
        spacing: DnDTheme.sm,
        children: [
          FilterChip(
            label: Text(
              'Alle',
              style: DnDTheme.bodyText2.copyWith(
                color: viewModel.selectedSoundType == null ? Colors.white : Colors.white70,
              ),
            ),
            backgroundColor: viewModel.selectedSoundType == null
                ? DnDTheme.ancientGold
                : DnDTheme.slateGrey,
            selected: viewModel.selectedSoundType == null,
            onSelected: (_) => viewModel.setSoundTypeFilter(null),
          ),
          ...SoundType.values.map((type) => FilterChip(
            label: Text(
              type.displayName,
              style: DnDTheme.bodyText2.copyWith(
                color: viewModel.selectedSoundType == type ? Colors.white : Colors.white70,
              ),
            ),
            backgroundColor: viewModel.selectedSoundType == type
                ? DnDTheme.ancientGold
                : DnDTheme.slateGrey,
            selected: viewModel.selectedSoundType == type,
            onSelected: (_) => viewModel.setSoundTypeFilter(type),
          )),
        ],
      ),
    );
  }

  Widget _buildSoundsList(SoundLibraryViewModel viewModel) {
    return ListView.builder(
      padding: const EdgeInsets.all(DnDTheme.md),
      itemCount: viewModel.sounds.length,
      itemBuilder: (context, index) {
        final sound = viewModel.sounds[index];
        return _buildSoundCard(sound, viewModel);
      },
    );
  }

  Widget _buildSoundCard(Sound sound, SoundLibraryViewModel viewModel) {
    return Container(
      margin: const EdgeInsets.only(bottom: DnDTheme.md),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: sound.isFavorite 
              ? DnDTheme.ancientGold.withValues(alpha: 0.5)
              : DnDTheme.mysticalPurple.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: sound.isFavorite 
                ? DnDTheme.ancientGold.withValues(alpha: 0.1)
                : DnDTheme.mysticalPurple.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(DnDTheme.md),
        leading: Container(
          decoration: BoxDecoration(
            gradient: DnDTheme.getMysticalGradient(
              startColor: sound.soundType == SoundType.Ambiente 
                  ? DnDTheme.successGreen 
                  : DnDTheme.arcaneBlue,
              endColor: sound.soundType == SoundType.Ambiente 
                  ? DnDTheme.successGreen.withValues(alpha: 0.5)
                  : DnDTheme.arcaneBlue.withValues(alpha: 0.5),
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(
            sound.soundType == SoundType.Ambiente 
                ? Icons.waves 
                : Icons.volume_up,
            color: Colors.white,
            size: 24,
          ),
        ),
        title: Text(
          sound.name,
          style: DnDTheme.bodyText1.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sound.soundTypeDisplayName,
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white70,
              ),
            ),
            if (sound.description.isNotEmpty) ...[
              const SizedBox(height: DnDTheme.xs),
              Text(
                sound.description,
                style: DnDTheme.bodyText2.copyWith(
                  color: Colors.white54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Direkter Play-Button
            Container(
              decoration: BoxDecoration(
                gradient: DnDTheme.getMysticalGradient(
                  startColor: DnDTheme.successGreen.withValues(alpha: 0.3),
                  endColor: DnDTheme.successGreen.withValues(alpha: 0.1),
                ),
                borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                border: Border.all(
                  color: DnDTheme.successGreen.withValues(alpha: 0.5),
                ),
              ),
              child: IconButton(
                icon: const Icon(Icons.play_arrow, color: DnDTheme.successGreen),
                onPressed: () => _playSound(sound),
                tooltip: 'Abspielen',
              ),
            ),
            
            const SizedBox(width: DnDTheme.sm),
            
            if (sound.isFavorite)
              Icon(
                Icons.favorite,
                color: DnDTheme.errorRed,
                size: 20,
              ),
            const SizedBox(width: DnDTheme.xs),
            IconButton(
              icon: Icon(
                sound.isFavorite ? Icons.favorite_border : Icons.favorite,
                color: sound.isFavorite ? DnDTheme.errorRed : Colors.white54,
              ),
              onPressed: () => viewModel.toggleSoundFavorite(sound.id),
              tooltip: sound.isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten',
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white54),
              color: DnDTheme.stoneGrey,
              onSelected: (action) => _handleSoundAction(action, sound),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'play',
                  child: Row(
                    children: [
                      Icon(Icons.play_arrow, color: DnDTheme.successGreen, size: 20),
                      const SizedBox(width: DnDTheme.sm),
                      Text(
                        'Abspielen',
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: DnDTheme.arcaneBlue, size: 20),
                      const SizedBox(width: DnDTheme.sm),
                      Text(
                        'Bearbeiten',
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: DnDTheme.errorRed, size: 20),
                      const SizedBox(width: DnDTheme.sm),
                      Text(
                        'Löschen',
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(DnDTheme.lg),
        decoration: DnDTheme.getDungeonWallDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.music_note,
              color: DnDTheme.mysticalPurple,
              size: 48,
            ),
            const SizedBox(height: DnDTheme.md),
            Text(
              message,
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              'Versuche es mit anderen Filtern',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingWidget(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            color: DnDTheme.ancientGold,
            strokeWidth: 3,
          ),
          const SizedBox(height: DnDTheme.md),
          Text(
            message,
            style: DnDTheme.bodyText1.copyWith(
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(SoundLibraryViewModel viewModel) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(DnDTheme.lg),
        decoration: DnDTheme.getDungeonWallDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              color: DnDTheme.errorRed,
              size: 48,
            ),
            const SizedBox(height: DnDTheme.md),
            Text(
              'Fehler',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.errorRed,
              ),
            ),
            const SizedBox(height: DnDTheme.sm),
            Text(
              viewModel.soundError ?? viewModel.sceneError ?? 'Unbekannter Fehler',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: DnDTheme.md),
            ElevatedButton.icon(
              onPressed: () => viewModel.refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('Erneut versuchen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.arcaneBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Consumer<SoundLibraryViewModel>(
      builder: (context, viewModel, child) {
        return Container(
          decoration: DnDTheme.getMysticalBorder(
            borderColor: DnDTheme.successGreen,
            width: 3,
          ),
          child: FloatingActionButton.extended(
            onPressed: () => _showAddSoundDialog(context),
            backgroundColor: DnDTheme.successGreen,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Sound'),
          ),
        );
      },
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'reset_filters':
        _viewModel.resetSoundFilters();
        break;
      case 'toggle_favorites':
        _viewModel.toggleFavoritesFilter();
        break;
    }
  }

  void _handleSoundAction(String action, Sound sound) {
    switch (action) {
      case 'play':
        _playSound(sound);
        break;
      case 'edit':
        _navigateToEditSound(sound);
        break;
      case 'delete':
        _showDeleteConfirmation(context, sound);
        break;
    }
  }

  /// Spielt einen Sound ab oder zeigt den Player an
  Future<void> _playSound(Sound sound) async {
    // Zeige den Player als BottomSheet
    _showSoundPlayerBottomSheet(sound);
  }
  
  /// Zeigt den Sound-Player als BottomSheet
  void _showSoundPlayerBottomSheet(Sound sound) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(DnDTheme.md),
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(
            startColor: DnDTheme.dungeonBlack,
            endColor: DnDTheme.stoneGrey,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(DnDTheme.radiusLarge),
            topRight: Radius.circular(DnDTheme.radiusLarge),
          ),
          border: Border.all(
            color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle-Bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: DnDTheme.md),
                decoration: BoxDecoration(
                  color: DnDTheme.ancientGold.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Titel
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.music_note,
                    color: DnDTheme.ancientGold,
                    size: 20,
                  ),
                  const SizedBox(width: DnDTheme.sm),
                  Text(
                    'Sound Player',
                    style: DnDTheme.headline3.copyWith(
                      color: DnDTheme.ancientGold,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: DnDTheme.md),
              
              // Sound Player Widget
              SoundPlayerWidget(
                sound: sound,
                showCloseButton: true,
                onClose: () => Navigator.of(context).pop(),
              ),
              
              const SizedBox(height: DnDTheme.lg),
            ],
          ),
        ),
      ),
    );
  }

  /// Navigiert zum Edit-Sound-Screen
  Future<void> _navigateToEditSound(Sound sound) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => EditSoundViewModel(),
          child: EditSoundScreen(sound: sound),
        ),
      ),
    );
    
    // Wenn ein Sound bearbeitet wurde, Liste aktualisieren
    if (result == true && mounted) {
      await _viewModel.loadSounds();
    }
  }

  void _showSortOptions(BuildContext context) {
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Sortierung',
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(
                'Name (A-Z)',
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
            ListTile(
              title: Text(
                'Typ',
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSoundDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    SoundType selectedType = SoundType.Ambiente;
    String? selectedFilePath;
    bool isUploading = false;
    
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: DnDTheme.stoneGrey,
          title: Text(
            'Sound hochladen',
            style: DnDTheme.headline3.copyWith(
              color: DnDTheme.ancientGold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Datei-Auswahl Button
                ElevatedButton.icon(
                  onPressed: () async {
                    final result = await FilePicker.platform.pickFiles(
                      type: FileType.audio,
                      allowMultiple: false,
                    );
                    
                    if (result != null && result.files.single.path != null) {
                      final fileName = result.files.single.name;
                      selectedFilePath = result.files.single.path!;
                      
                      // Name aus Dateiname extrahieren (ohne Extension)
                      final extractedName = fileName.contains('.')
                          ? fileName.substring(0, fileName.lastIndexOf('.'))
                          : fileName;
                      
                      setDialogState(() {
                        nameController.text = extractedName;
                      });
                    }
                  },
                  icon: const Icon(Icons.upload_file),
                  label: Text(selectedFilePath != null ? 'Datei ändern' : 'Datei auswählen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedFilePath != null 
                        ? DnDTheme.successGreen 
                        : DnDTheme.arcaneBlue,
                    foregroundColor: Colors.white,
                  ),
                ),
                
                // Anzeige der ausgewählten Datei
                if (selectedFilePath != null) ...[
                  const SizedBox(height: DnDTheme.sm),
                  Container(
                    padding: const EdgeInsets.all(DnDTheme.sm),
                    decoration: BoxDecoration(
                      color: DnDTheme.successGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                      border: Border.all(color: DnDTheme.successGreen.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: DnDTheme.successGreen, size: 16),
                        const SizedBox(width: DnDTheme.xs),
                        Expanded(
                          child: Text(
                            'Datei ausgewählt',
                            style: DnDTheme.bodyText2.copyWith(color: DnDTheme.successGreen),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                
                const SizedBox(height: DnDTheme.md),
                
                // Name Feld
                TextField(
                  controller: nameController,
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Name *',
                    labelStyle: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(
                        color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                    ),
                    filled: true,
                    fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                  ),
                ),
                
                const SizedBox(height: DnDTheme.md),
                
                // Typ Dropdown
                DropdownButtonFormField<SoundType>(
                  value: selectedType,
                  dropdownColor: DnDTheme.stoneGrey,
                  decoration: InputDecoration(
                    labelText: 'Typ',
                    labelStyle: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(
                        color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                    ),
                    filled: true,
                    fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                  ),
                  items: SoundType.values.map((type) {
                    return DropdownMenuItem<SoundType>(
                      value: type,
                      child: Text(
                        type.displayName,
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                    );
                  }).toList(),
                  onChanged: (SoundType? value) {
                    if (value != null) {
                      setDialogState(() => selectedType = value);
                    }
                  },
                ),
                
                const SizedBox(height: DnDTheme.md),
                
                // Beschreibung Feld
                TextField(
                  controller: descriptionController,
                  style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Beschreibung (optional)',
                    labelStyle: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(
                        color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                      borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                    ),
                    filled: true,
                    fillColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUploading ? null : () {
                Navigator.of(context).pop();
              },
              child: Text(
                'Abbrechen',
                style: DnDTheme.bodyText1.copyWith(
                  color: isUploading ? Colors.white38 : DnDTheme.mysticalPurple,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isUploading || selectedFilePath == null ? null : () async {
                if (selectedFilePath == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bitte wähle zuerst eine Datei aus',
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                      backgroundColor: DnDTheme.warningOrange,
                    ),
                  );
                  return;
                }
                
                setDialogState(() => isUploading = true);
                
                // Sound hochladen mit dem gespeicherten Dateipfad
                final uploadedSound = await _viewModel.uploadSound(
                  selectedFilePath!,
                  selectedType,
                  customName: nameController.text.isNotEmpty ? nameController.text : null,
                  description: descriptionController.text,
                );
                
                setDialogState(() => isUploading = false);
                
                if (uploadedSound != null) {
                  // Dialog schließen und Success-Message zeigen
                  Navigator.of(context).pop();
                  
                  if (!mounted) return;
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Sound "${uploadedSound.name}" erfolgreich hochgeladen',
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                      backgroundColor: DnDTheme.successGreen,
                    ),
                  );
                } else {
                  // Error-Message zeigen
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _viewModel.soundError ?? 'Fehler beim Hochladen',
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                      backgroundColor: DnDTheme.errorRed,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.successGreen,
                foregroundColor: Colors.white,
                disabledBackgroundColor: DnDTheme.slateGrey,
              ),
              child: isUploading 
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Hochladen'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Sound sound) {
    showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Sound löschen',
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.errorRed,
          ),
        ),
        content: Text(
          'Möchtest du "${sound.name}" wirklich löschen?',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _viewModel.deleteSound(sound.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

// Extension für SoundType Display Name
extension SoundTypeExtension on SoundType {
  String get displayName {
    switch (this) {
      case SoundType.Ambiente:
        return 'Ambiente';
      case SoundType.Effekt:
        return 'Effekt';
    }
  }
}

// Extension für Sound Display Name
extension SoundExtension on Sound {
  String get soundTypeDisplayName {
    return soundType.displayName;
  }
}