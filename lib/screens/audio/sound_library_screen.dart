import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../viewmodels/sound_library_viewmodel.dart';
import '../../models/sound.dart';
import '../../theme/dnd_theme.dart';
import '../../widgets/sound_scenes_tab.dart';
import '../../widgets/audio/sound_mixer_widget.dart';
import '../../widgets/ui_components/filter/unified_filter_chip.dart';
import '../../widgets/ui_components/states/loading_state_widget.dart';
import '../../widgets/ui_components/states/empty_state_widget.dart';

/// Sound Library Screen mit integriertem SoundMixerWidget
/// 
/// Zeigt alle Sounds in einer Liste an.
/// Jeder Sound kann einzeln mit dem verbesserten SoundMixerWidget angehört werden.
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
  
  // Aktuell ausgewählter Sound für Vorschau
  Sound? _selectedSoundForPreview;

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
        builder: (context, viewModel, child) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sound & Atmosphäre',
              style: DnDTheme.headline2.copyWith(color: DnDTheme.ancientGold),
            ),
            Text(
              '${viewModel.soundCount} Sounds • ${viewModel.favoriteCount} Favoriten',
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
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
        unselectedLabelStyle: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        tabs: const [
          Tab(icon: Icon(Icons.music_note), text: 'Sounds'),
          Tab(icon: Icon(Icons.movie_filter), text: 'Szenen'),
        ],
      ),
      actions: [
        Consumer<SoundLibraryViewModel>(
          builder: (context, viewModel, child) => Container(
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
          ),
        ),
      ],
    );
  }

  Widget _buildBody() => Consumer<SoundLibraryViewModel>(
    builder: (context, viewModel, child) {
      if (viewModel.hasError) return _buildErrorWidget(viewModel);

      return TabBarView(
        controller: _tabController,
        children: [
          _buildSoundsTab(viewModel),
          _buildScenesTab(viewModel),
        ],
      );
    },
  );

  Widget _buildSoundsTab(SoundLibraryViewModel viewModel) => Column(
    children: [
      // Suchleiste
      _buildSearchBar(viewModel),
      
      // Filter-Chips
      _buildFilterChips(viewModel),
      
      // Sound-Liste
      Expanded(
        child: viewModel.isLoadingSounds
            ? LoadingStateWidget.standard(color: DnDTheme.ancientGold)
            : viewModel.sounds.isEmpty
                ? _buildEmptyState('Keine Sounds gefunden')
                : _buildSoundList(viewModel),
      ),
      
      // Sound-Vorschau mit SoundMixerWidget
      if (_selectedSoundForPreview != null) _buildSoundPreview(),
    ],
  );

  Widget _buildSearchBar(SoundLibraryViewModel viewModel) => Container(
    padding: const EdgeInsets.all(DnDTheme.md),
    decoration: BoxDecoration(
      gradient: DnDTheme.getMysticalGradient(
        startColor: DnDTheme.slateGrey,
        endColor: DnDTheme.stoneGrey,
      ),
      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      border: Border.all(color: DnDTheme.ancientGold.withValues(alpha: 0.3)),
    ),
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
  );

  Widget _buildFilterChips(SoundLibraryViewModel viewModel) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: DnDTheme.md,
      vertical: DnDTheme.sm,
    ),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          UnifiedFilterChip<String>(
            value: 'all',
            label: 'Alle',
            isSelected: viewModel.selectedSoundType == null,
            selectedColor: DnDTheme.ancientGold,
            onSelected: (_) => viewModel.setSoundTypeFilter(null),
          ),
          ...SoundType.values.map((type) => Padding(
            padding: const EdgeInsets.only(left: DnDTheme.xs),
            child: UnifiedFilterChip<String>(
              value: type.name,
              label: type.displayName,
              isSelected: viewModel.selectedSoundType == type,
              selectedColor: type == SoundType.Ambiente 
                  ? DnDTheme.arcaneBlue 
                  : DnDTheme.successGreen,
              onSelected: (_) => viewModel.setSoundTypeFilter(type),
            ),
          )),
        ],
      ),
    ),
  );

  Widget _buildSoundList(SoundLibraryViewModel viewModel) => ListView.builder(
    padding: const EdgeInsets.symmetric(horizontal: DnDTheme.md),
    itemCount: viewModel.sounds.length,
    itemBuilder: (context, index) {
      final sound = viewModel.sounds[index];
      final isSelected = _selectedSoundForPreview?.id == sound.id;
      
      return _buildSoundListItem(sound, isSelected, viewModel);
    },
  );

  Widget _buildSoundListItem(
    Sound sound, 
    bool isSelected, 
    SoundLibraryViewModel viewModel,
  ) => Container(
    margin: const EdgeInsets.only(bottom: DnDTheme.sm),
    decoration: BoxDecoration(
      gradient: DnDTheme.getMysticalGradient(
        startColor: isSelected 
            ? DnDTheme.ancientGold.withValues(alpha: 0.3)
            : DnDTheme.slateGrey.withValues(alpha: 0.3),
        endColor: DnDTheme.stoneGrey.withValues(alpha: 0.3),
      ),
      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      border: Border.all(
        color: isSelected 
            ? DnDTheme.ancientGold
            : DnDTheme.mysticalPurple.withValues(alpha: 0.3),
        width: isSelected ? 2 : 1,
      ),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: DnDTheme.md,
        vertical: DnDTheme.xs,
      ),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSelected ? DnDTheme.ancientGold : DnDTheme.arcaneBlue,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: (isSelected ? DnDTheme.ancientGold : DnDTheme.arcaneBlue)
                  .withValues(alpha: 0.4),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            isSelected ? Icons.equalizer : Icons.play_arrow,
            color: Colors.black,
            size: 24,
          ),
          onPressed: () => _selectSoundForPreview(sound),
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              sound.name,
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Typ-Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DnDTheme.sm, vertical: 2),
            decoration: BoxDecoration(
              color: sound.soundType == SoundType.Ambiente 
                  ? DnDTheme.arcaneBlue.withValues(alpha: 0.2)
                  : DnDTheme.successGreen.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              border: Border.all(
                color: sound.soundType == SoundType.Ambiente 
                    ? DnDTheme.arcaneBlue
                    : DnDTheme.successGreen,
                width: 1,
              ),
            ),
            child: Text(
              sound.soundTypeDisplayName,
              style: DnDTheme.bodyText2.copyWith(
                color: sound.soundType == SoundType.Ambiente 
                    ? DnDTheme.arcaneBlue
                    : DnDTheme.successGreen,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
      subtitle: sound.description.isNotEmpty
          ? Text(
              sound.description,
              style: DnDTheme.bodyText2.copyWith(color: Colors.white54),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Favorit-Button
          IconButton(
            icon: Icon(
              sound.isFavorite ? Icons.favorite : Icons.favorite_border,
              color: sound.isFavorite ? DnDTheme.errorRed : Colors.white54,
              size: 20,
            ),
            onPressed: () => _toggleFavorite(sound, viewModel),
            tooltip: sound.isFavorite 
                ? 'Aus Favoriten entfernen' 
                : 'Zu Favoriten hinzufügen',
          ),
          // Bearbeiten-Button
          IconButton(
            icon: Icon(Icons.edit, color: DnDTheme.arcaneBlue, size: 20),
            onPressed: () => _navigateToEditSound(sound),
            tooltip: 'Bearbeiten',
          ),
        ],
      ),
    ),
  );

  /// Sound-Vorschau mit dem verbesserten SoundMixerWidget
  Widget _buildSoundPreview() => Container(
    decoration: BoxDecoration(
      gradient: DnDTheme.getMysticalGradient(
        startColor: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
        endColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
      ),
      boxShadow: [
        BoxShadow(
          color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
          blurRadius: 10,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header mit Close-Button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: DnDTheme.md, vertical: DnDTheme.sm),
            decoration: BoxDecoration(
              color: DnDTheme.mysticalPurple.withValues(alpha: 0.2),
              border: Border(
                bottom: BorderSide(
                  color: DnDTheme.ancientGold.withValues(alpha: 0.3),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.music_note, color: DnDTheme.ancientGold, size: 16),
                const SizedBox(width: DnDTheme.sm),
                Expanded(
                  child: Text(
                    'Vorschau: ${_selectedSoundForPreview?.name ?? "Unbekannt"}',
                    style: DnDTheme.bodyText2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54, size: 18),
                  onPressed: _closePreview,
                  tooltip: 'Vorschau schließen',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          
          // SoundMixerWidget mit playerPreview Konfiguration
          // Key verwenden um neues Widget zu erzwingen wenn sich der Sound ändert
          Padding(
            padding: const EdgeInsets.all(DnDTheme.sm),
            child: SoundMixerWidget(
              key: ValueKey(_selectedSoundForPreview?.id ?? 'no-sound'),
              initialSounds: _selectedSoundForPreview != null 
                  ? [_selectedSoundForPreview!] 
                  : null,
              config: SoundMixerConfig.playerPreviewConfig,
              keepAlive: false,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildScenesTab(SoundLibraryViewModel viewModel) => Column(
    children: [
      // Search Bar für Szenen
      _buildSceneSearchBar(viewModel),
      
      // Content
      Expanded(
        child: viewModel.isLoadingScenes
            ? LoadingStateWidget.standard(color: DnDTheme.ancientGold)
            : viewModel.scenes.isEmpty
                ? _buildEmptyState('Keine Szenen gefunden')
                : const SoundScenesTab(),
      ),
    ],
  );

  Widget _buildSceneSearchBar(SoundLibraryViewModel viewModel) => Container(
    padding: const EdgeInsets.all(DnDTheme.md),
    decoration: BoxDecoration(
      gradient: DnDTheme.getMysticalGradient(
        startColor: DnDTheme.slateGrey,
        endColor: DnDTheme.stoneGrey,
      ),
      borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
      border: Border.all(color: DnDTheme.ancientGold.withValues(alpha: 0.3)),
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

  Widget _buildEmptyState(String message) => EmptyStateWidget.minimal(
    title: message,
    icon: Icons.music_note,
    iconColor: DnDTheme.mysticalPurple,
  );

  Widget _buildErrorWidget(SoundLibraryViewModel viewModel) => Center(
    child: Container(
      padding: const EdgeInsets.all(DnDTheme.lg),
      decoration: DnDTheme.getDungeonWallDecoration(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, color: DnDTheme.errorRed, size: 48),
          const SizedBox(height: DnDTheme.md),
          Text(
            'Fehler',
            style: DnDTheme.headline3.copyWith(color: DnDTheme.errorRed),
          ),
          const SizedBox(height: DnDTheme.sm),
          Text(
            viewModel.soundError ?? viewModel.sceneError ?? 'Unbekannter Fehler',
            style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
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

  Widget _buildFloatingActionButton() => Consumer<SoundLibraryViewModel>(
    builder: (context, viewModel, child) => Container(
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
    ),
  );

  // ===== Action Methods =====

  void _selectSoundForPreview(Sound sound) {
    setState(() {
      _selectedSoundForPreview = sound;
    });
  }

  void _closePreview() {
    setState(() {
      _selectedSoundForPreview = null;
    });
  }

  Future<void> _toggleFavorite(Sound sound, SoundLibraryViewModel viewModel) async =>
      await viewModel.toggleSoundFavorite(sound.id);

  void _navigateToEditSound(Sound sound) =>
      Navigator.of(context).pushNamed('/edit-sound', arguments: sound);

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
            style: DnDTheme.headline3.copyWith(color: DnDTheme.ancientGold),
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
                      border: Border.all(
                        color: DnDTheme.successGreen.withValues(alpha: 0.3),
                      ),
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
                  items: SoundType.values.map((type) => DropdownMenuItem<SoundType>(
                    value: type,
                    child: Text(
                      type.displayName,
                      style: DnDTheme.bodyText1.copyWith(color: Colors.white),
                    ),
                  )).toList(),
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
              onPressed: isUploading ? null : () => Navigator.of(context).pop(),
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
                
                // Sound hochladen
                final uploadedSound = await _viewModel.uploadSound(
                  selectedFilePath!,
                  selectedType,
                  customName: nameController.text.isNotEmpty 
                      ? nameController.text 
                      : null,
                  description: descriptionController.text,
                );
                
                setDialogState(() => isUploading = false);
                
                if (uploadedSound != null) {
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
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Hochladen'),
            ),
          ],
        ),
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