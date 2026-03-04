import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodels/sound_library_viewmodel.dart';
import '../models/sound.dart';
import '../theme/dnd_theme.dart';
import '../widgets/sound_scenes_tab.dart';

/// Enhanced Sound Library Screen mit Provider-Pattern und modernem D&D Design
class EnhancedSoundLibraryScreen extends StatefulWidget {
  const EnhancedSoundLibraryScreen({super.key});

  @override
  State<EnhancedSoundLibraryScreen> createState() => _EnhancedSoundLibraryScreenState();
}

class _EnhancedSoundLibraryScreenState extends State<EnhancedSoundLibraryScreen> 
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
            if (sound.isFavorite)
              Icon(
                Icons.favorite,
                color: DnDTheme.errorRed,
                size: 20,
              ),
            const SizedBox(width: DnDTheme.sm),
            IconButton(
              icon: Icon(
                sound.isFavorite ? Icons.favorite_border : Icons.favorite,
                color: sound.isFavorite ? DnDTheme.errorRed : Colors.white54,
              ),
              onPressed: () => viewModel.toggleSoundFavorite(sound.id),
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
        // TODO: Sound abspielen
        break;
      case 'edit':
        // TODO: Sound bearbeiten
        break;
      case 'delete':
        _showDeleteConfirmation(context, sound);
        break;
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
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ElevatedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.platform.pickFiles(
                    type: FileType.audio,
                    allowMultiple: false,
                  );
                  
                  if (result != null && result.files.single.path != null) {
                    final filePath = result.files.single.path!;
                    final fileName = result.files.single.name;
                    
                    // Name aus Dateiname extrahieren (ohne Extension)
                    nameController.text = fileName.contains('.')
                        ? fileName.substring(0, fileName.lastIndexOf('.'))
                        : fileName;
                  }
                },
                icon: const Icon(Icons.upload_file),
                label: const Text('Datei auswählen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DnDTheme.arcaneBlue,
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(height: DnDTheme.md),
              TextField(
                controller: nameController,
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Name',
                  labelStyle: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: DnDTheme.md),
              DropdownButtonFormField<SoundType>(
                value: selectedType,
                dropdownColor: DnDTheme.stoneGrey,
                decoration: InputDecoration(
                  labelText: 'Typ',
                  labelStyle: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                  ),
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
              TextField(
                controller: descriptionController,
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Beschreibung (optional)',
                  labelStyle: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                descriptionController.dispose();
                Navigator.of(context).pop();
              },
              child: Text(
                'Abbrechen',
                style: DnDTheme.bodyText1.copyWith(
                  color: DnDTheme.mysticalPurple,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                // Prüfen ob ein Dateipfad ausgewählt wurde
                final result = await FilePicker.platform.pickFiles(
                  type: FileType.audio,
                  allowMultiple: false,
                );
                
                if (result != null && result.files.single.path != null) {
                  final filePath = result.files.single.path!;
                  
                  // Sound hochladen
                  final uploadedSound = await _viewModel.uploadSound(
                    filePath,
                    selectedType,
                    customName: nameController.text.isNotEmpty ? nameController.text : null,
                    description: descriptionController.text,
                  );
                  
                  if (uploadedSound != null) {
                    // Dialog schließen und Success-Message zeigen
                    nameController.dispose();
                    descriptionController.dispose();
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
                } else {
                  // Keine Datei ausgewählt
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Bitte wähle zuerst eine Datei aus',
                        style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                      ),
                      backgroundColor: DnDTheme.warningOrange,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DnDTheme.successGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hochladen'),
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
