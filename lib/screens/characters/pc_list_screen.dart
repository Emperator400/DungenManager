import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../models/player_character.dart';
import 'edit_pc_screen.dart';
import '../../widgets/ui_components/cards/unified_hero_card.dart';
import '../../widgets/character_list/character_list_helpers.dart';
import '../../theme/app_theme.dart';
import '../../viewmodels/character_editor_viewmodel.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../widgets/ui_components/states/loading_state_widget.dart';
import '../../widgets/ui_components/feedback/snackbar_helper.dart';

class PlayerCharacterListScreen extends StatefulWidget {
  final Campaign campaign;

  const PlayerCharacterListScreen({super.key, required this.campaign});

  @override
  State<PlayerCharacterListScreen> createState() => _PlayerCharacterListScreenState();
}

class _PlayerCharacterListScreenState extends State<PlayerCharacterListScreen> {
  late CharacterEditorViewModel _viewModel;
  SortOption _sortOption = SortOption.name;
  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = CharacterEditorViewModel(
      playerCharacterRepository: PlayerCharacterModelRepository(DatabaseConnection.instance),
    );
    _loadCharacters();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _loadCharacters() async {
    try {
      await _viewModel.loadPlayerCharacters(widget.campaign.id);
      setState(() {});
    } catch (e) {
      if (mounted) SnackBarHelper.showError(context, 'Fehler beim Laden der Helden: $e');
    }
  }

  List<PlayerCharacter> get _filteredCharacters {
    final filteredPcs = _viewModel.playerCharacters.where((pc) {
      final matchesSearch = _searchQuery.isEmpty ||
          pc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pc.className.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pc.playerName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFavorite = !_showFavoritesOnly || pc.isFavorite;
      return matchesSearch && matchesFavorite;
    }).toList();
    filteredPcs.sort((a, b) => CharacterListHelpers.compareCharacters(a, b, _sortOption));
    return filteredPcs;
  }

  Future<void> _refreshCharacterList() => _loadCharacters();

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return ChangeNotifierProvider<CharacterEditorViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: C.bg,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(52),
          child: Container(
            decoration: BoxDecoration(color: C.bgPanel, border: Border(bottom: BorderSide(color: C.border))),
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: SizedBox(width: 30, height: 30, child: Icon(Icons.arrow_back, size: 18, color: C.textMid)),
                    ),
                    Container(width: 1, height: 18, color: C.border, margin: const EdgeInsets.symmetric(horizontal: 8)),
                    Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: C.green.withValues(alpha: 0.18),
                        border: Border.all(color: C.green.withValues(alpha: 0.4)),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Center(child: Icon(Icons.people, size: 14, color: C.green)),
                    ),
                    const SizedBox(width: 8),
                    Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Helden', style: TextStyle(color: C.text, fontWeight: FontWeight.w600, fontSize: 13, height: 1.1)),
                      Text(widget.campaign.title, style: TextStyle(color: C.textSoft, fontSize: 10, height: 1.1)),
                    ]),
                    const Spacer(),
                    GestureDetector(
                      onTap: () async {
                        try {
                          await Navigator.of(context).push(MaterialPageRoute<void>(
                            builder: (ctx) => EditPCScreen(campaignId: widget.campaign.id),
                          ));
                          await _refreshCharacterList();
                        } catch (e) {
                          if (mounted) SnackBarHelper.showError(context, 'Fehler beim Öffnen des Charakter-Editors: $e');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(color: C.green, borderRadius: BorderRadius.circular(7)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.add, size: 13, color: Colors.white),
                          SizedBox(width: 5),
                          Text('Held hinzufügen', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ]),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildSearchAndFilterBar(),
              Expanded(
                child: Consumer<CharacterEditorViewModel>(
                  builder: (context, viewModel, child) {
                    final C = context.appColors;
                    if (viewModel.isLoading) {
                      return LoadingStateWidget.withMessage(message: 'Lade Helden...');
                    }

                    if (viewModel.error != null) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: C.bgPanel,
                            border: Border.all(color: C.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, color: C.red, size: 48),
                              const SizedBox(height: 16),
                              Text(
                                'Fehler beim Laden',
                                style: TextStyle(fontSize: 18, color: C.red),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                viewModel.error!,
                                style: TextStyle(fontSize: 13, color: C.textMid),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  viewModel.clearError();
                                  await _refreshCharacterList();
                                },
                                icon: const Icon(Icons.refresh),
                                label: const Text('Erneut versuchen'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: C.red,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    final filteredPcs = _filteredCharacters;

                    if (filteredPcs.isEmpty) {
                      return Center(
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: C.bgPanel,
                            border: Border.all(color: C.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.people_outline,
                                size: 64,
                                color: const Color(0xFF7C3AED).withValues(alpha: 0.6),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty || _showFavoritesOnly
                                    ? 'Keine Helden gefunden, die den Filterkriterien entsprechen.'
                                    : 'Keine Helden für diese Kampagne erstellt.',
                                style: TextStyle(fontSize: 14, color: C.textMid),
                                textAlign: TextAlign.center,
                              ),
                              if (_searchQuery.isNotEmpty || _showFavoritesOnly)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: ElevatedButton.icon(
                                    onPressed: () async {
                                      setState(() {
                                        _searchQuery = '';
                                        _showFavoritesOnly = false;
                                        _searchController.clear();
                                      });
                                      await _refreshCharacterList();
                                    },
                                    icon: const Icon(Icons.clear),
                                    label: const Text('Filter zurücksetzen'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: C.accent,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }

                    return _buildCharacterList(filteredPcs);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.bgPanel,
        border: Border(bottom: BorderSide(color: C.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Helden suchen...',
              hintStyle: TextStyle(fontSize: 14, color: C.textSoft),
              prefixIcon: Icon(Icons.search, color: C.amber),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: C.red),
                      onPressed: () async {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                        await _refreshCharacterList();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: C.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: C.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: C.amber, width: 2),
              ),
              filled: true,
              fillColor: C.bgHover,
            ),
            style: TextStyle(fontSize: 14, color: C.text),
            onChanged: (value) {
              setState(() => _searchQuery = value);
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) _refreshCharacterList();
              });
            },
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              FilterChip(
                label: Text(
                  'Nur Favoriten',
                  style: TextStyle(
                    color: _showFavoritesOnly ? Colors.white : const Color(0xFF7C3AED),
                  ),
                ),
                selected: _showFavoritesOnly,
                onSelected: (selected) async {
                  setState(() => _showFavoritesOnly = selected);
                  await _refreshCharacterList();
                },
                backgroundColor: C.bgHover,
                selectedColor: C.amber,
                showCheckmark: false,
                avatar: _showFavoritesOnly
                    ? const Icon(Icons.star, size: 16, color: Colors.white)
                    : const Icon(Icons.star_border, size: 16, color: Color(0xFF7C3AED)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: C.border),
                  ),
                  child: DropdownButtonFormField<SortOption>(
                    value: _sortOption,
                    decoration: InputDecoration(
                      labelText: 'Sortieren',
                      labelStyle: TextStyle(fontSize: 14, color: C.amber),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                    dropdownColor: C.bgPanel,
                    style: const TextStyle(fontSize: 14, color: Colors.white),
                    items: SortOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(
                          _getSortOptionLabel(option),
                          style: const TextStyle(fontSize: 14, color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() => _sortOption = value);
                        await _refreshCharacterList();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterList(List<PlayerCharacter> pcs) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: pcs.length,
      itemBuilder: (context, index) {
        final pc = pcs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: UnifiedHeroCard(
            hero: pc,
            onTap: () => _editCharacter(context, pc),
            onEdit: () => _editCharacter(context, pc),
            onToggleFavorite: () => _toggleFavorite(pc),
            onDelete: () => _showDeleteConfirmation(context, pc),
          ),
        );
      },
    );
  }

  String _getSortOptionLabel(SortOption option) {
    return switch (option) {
      SortOption.name => 'Name',
      SortOption.level => 'Level',
      SortOption.className => 'Klasse',
      SortOption.playerName => 'Spieler',
      SortOption.favorites => 'Favoriten',
      SortOption.recentlyEdited => 'Zuletzt bearbeitet',
    };
  }

  void _editCharacter(BuildContext context, PlayerCharacter pc) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (ctx) => EditPCScreen(campaignId: widget.campaign.id, pcToEdit: pc),
      ),
    );
    await _refreshCharacterList();
  }

  void _toggleFavorite(PlayerCharacter pc) async {
    try {
      await _viewModel.toggleFavorite(pc);
      await _refreshCharacterList();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              pc.isFavorite
                  ? '${pc.name} zu Favoriten hinzugefügt'
                  : '${pc.name} aus Favoriten entfernt',
            ),
            backgroundColor: context.appColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Aktualisieren: $e'),
            backgroundColor: context.appColors.red,
          ),
        );
      }
    }
  }

  void _showDeleteConfirmation(BuildContext context, PlayerCharacter pc) {
    final C = context.appColors;
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text(
          'Löschen bestätigen',
          style: TextStyle(fontSize: 18, color: C.red, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Möchten Sie ${pc.name} wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(fontSize: 14, color: C.textMid),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Abbrechen',
              style: TextStyle(fontSize: 16, color: Color(0xFF7C3AED)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await _viewModel.deletePlayerCharacter(pc.id);
                await _refreshCharacterList();
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('${pc.name} wurde gelöscht'),
                      backgroundColor: this.context.appColors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Löschen: $e'),
                      backgroundColor: this.context.appColors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: C.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
