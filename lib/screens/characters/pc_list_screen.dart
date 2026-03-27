import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../models/player_character.dart';
import 'edit_pc_screen.dart';
import '../../widgets/ui_components/cards/unified_hero_card.dart';
import '../../widgets/character_list/character_list_helpers.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/character_editor_viewmodel.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/player_character_model_repository.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Helden: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  List<PlayerCharacter> get _filteredCharacters {
    final allPcs = _viewModel.playerCharacters;
    
    var filteredPcs = allPcs.where((pc) {
      final matchesSearch = _searchQuery.isEmpty ||
          (pc.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (pc.className?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
          (pc.playerName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      
      final matchesFavorite = !_showFavoritesOnly || (pc.isFavorite ?? false);
      
      return matchesSearch && matchesFavorite;
    }).toList();

    filteredPcs.sort((a, b) => CharacterListHelpers.compareCharacters(a, b, _sortOption));
    
    return filteredPcs;
  }

  Future<void> _refreshCharacterList() async {
    await _loadCharacters();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<CharacterEditorViewModel>.value(
      value: _viewModel,
      child: Scaffold(
        backgroundColor: DnDTheme.dungeonBlack,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(
            widget.campaign.title,
            style: DnDTheme.headline2.copyWith(
              color: DnDTheme.ancientGold,
            ),
          ),
          backgroundColor: DnDTheme.stoneGrey,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          top: false,
          child: Column(
            children: [
              // Suchleiste direkt im Body
              _buildSearchAndFilterBar(),
              // Liste der Helden
              Expanded(
                child: Consumer<CharacterEditorViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: DnDTheme.ancientGold,
                    ),
                    const SizedBox(height: DnDTheme.md),
                    Text(
                      'Lade Helden...',
                      style: DnDTheme.bodyText1.copyWith(
                        color: DnDTheme.ancientGold,
                      ),
                    ),
                  ],
                ),
              );
            }

            if (viewModel.error != null) {
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
                        'Fehler beim Laden',
                        style: DnDTheme.headline3.copyWith(
                          color: DnDTheme.errorRed,
                        ),
                      ),
                      const SizedBox(height: DnDTheme.sm),
                      Text(
                        viewModel.error!,
                        style: DnDTheme.bodyText2.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: DnDTheme.md),
                      ElevatedButton.icon(
                        onPressed: () async {
                          viewModel.clearError();
                          await _refreshCharacterList();
                        },
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

            final filteredPcs = _filteredCharacters;
            
            if (filteredPcs.isEmpty) {
              return Center(
                child: Container(
                  padding: const EdgeInsets.all(DnDTheme.lg),
                  decoration: DnDTheme.getDungeonWallDecoration(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: DnDTheme.mysticalPurple.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: DnDTheme.md),
                      Text(
                        _searchQuery.isNotEmpty || _showFavoritesOnly 
                            ? "Keine Helden gefunden, die den Filterkriterien entsprechen."
                            : "Keine Helden für diese Kampagne erstellt.",
                        style: DnDTheme.bodyText1.copyWith(
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      if (_searchQuery.isNotEmpty || _showFavoritesOnly)
                        Padding(
                          padding: const EdgeInsets.only(top: DnDTheme.md),
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
                              backgroundColor: DnDTheme.arcaneBlue,
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                gradient: DnDTheme.getMysticalGradient(
                  startColor: DnDTheme.dungeonBlack,
                  endColor: DnDTheme.stoneGrey,
                ),
              ),
              child: _buildCharacterList(filteredPcs),
            );
          },
        ),
              ),
            ],
          ),
        ),
        floatingActionButton: Container(
          margin: const EdgeInsets.only(bottom: 16, right: 16),
          child: FloatingActionButton.extended(
            tooltip: "Neuen Helden hinzufügen",
            backgroundColor: DnDTheme.successGreen,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text('Held hinzufügen'),
            onPressed: () async {
              print('DEBUG: FloatingActionButton pressed - Opening Enhanced Edit PC Screen');
              try {
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (ctx) => EditPCScreen(
                      campaignId: widget.campaign.id,
                    ),
                  ),
                );
                print('DEBUG: Enhanced Edit PC Screen closed');
                await _refreshCharacterList();
                print('DEBUG: Character list refreshed successfully');
              } catch (e) {
                print('DEBUG: Error opening Enhanced Edit PC Screen: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Öffnen des Charakter-Editors: $e'),
                      backgroundColor: DnDTheme.errorRed,
                    ),
                  );
                }
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        border: Border(
          bottom: BorderSide(
            color: DnDTheme.mysticalPurple.withValues(alpha: 0.3),
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
              hintText: 'Helden suchen...',
              hintStyle: DnDTheme.bodyText2.copyWith(
                color: Colors.white54,
              ),
              prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: DnDTheme.errorRed),
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
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) _refreshCharacterList();
              });
            },
          ),
          
          const SizedBox(height: DnDTheme.sm),
          
          Row(
            children: [
              FilterChip(
                label: Text(
                  'Nur Favoriten',
                  style: TextStyle(
                    color: _showFavoritesOnly ? Colors.white : DnDTheme.mysticalPurple,
                  ),
                ),
                selected: _showFavoritesOnly,
                onSelected: (selected) async {
                  setState(() {
                    _showFavoritesOnly = selected;
                  });
                  await _refreshCharacterList();
                },
                backgroundColor: DnDTheme.slateGrey.withValues(alpha: 0.3),
                selectedColor: DnDTheme.ancientGold,
                showCheckmark: false,
                avatar: _showFavoritesOnly 
                    ? Icon(Icons.star, size: 16, color: Colors.white)
                    : Icon(Icons.star_border, size: 16, color: DnDTheme.mysticalPurple),
              ),
              
              const SizedBox(width: DnDTheme.sm),
              
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                    border: Border.all(
                      color: DnDTheme.mysticalPurple.withValues(alpha: 0.5),
                    ),
                  ),
                  child: DropdownButtonFormField<SortOption>(
                    value: _sortOption,
                    decoration: InputDecoration(
                      labelText: 'Sortieren',
                      labelStyle: DnDTheme.bodyText2.copyWith(
                        color: DnDTheme.ancientGold,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: DnDTheme.sm,
                        vertical: DnDTheme.xs,
                      ),
                    ),
                    dropdownColor: DnDTheme.stoneGrey,
                    style: DnDTheme.bodyText2.copyWith(color: Colors.white),
                    items: SortOption.values.map((option) {
                      return DropdownMenuItem(
                        value: option,
                        child: Text(
                          _getSortOptionLabel(option),
                          style: DnDTheme.bodyText2.copyWith(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        setState(() {
                          _sortOption = value;
                        });
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
      padding: const EdgeInsets.all(DnDTheme.sm),
      itemCount: pcs.length,
      itemBuilder: (context, index) {
        final pc = pcs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: DnDTheme.md),
          child: UnifiedHeroCard(
            hero: pc,
            onTap: () => _editCharacter(context, pc),
            onEdit: () => _editCharacter(context, pc),
            onToggleFavorite: () => _toggleFavorite(pc),
            onQuickAction: () => _showQuickActions(context, pc),
            onDelete: () => _showDeleteConfirmation(context, pc),
          ),
        );
      },
    );
  }

  String _getSortOptionLabel(SortOption option) {
    switch (option) {
      case SortOption.name:
        return 'Name';
      case SortOption.level:
        return 'Level';
      case SortOption.className:
        return 'Klasse';
      case SortOption.playerName:
        return 'Spieler';
      case SortOption.favorites:
        return 'Favoriten';
      case SortOption.recentlyEdited:
        return 'Zuletzt bearbeitet';
    }
  }

  void _editCharacter(BuildContext context, PlayerCharacter pc) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => EditPCScreen(
          campaignId: widget.campaign.id,
          pcToEdit: pc,
        ),
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
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Aktualisieren: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  void _showQuickActions(BuildContext context, PlayerCharacter pc) {
    showModalBottomSheet(
      context: context,
      backgroundColor: DnDTheme.stoneGrey,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(DnDTheme.radiusMedium)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(DnDTheme.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktionen für ${pc.name}',
              style: DnDTheme.headline3.copyWith(
                color: DnDTheme.ancientGold,
              ),
            ),
            const SizedBox(height: DnDTheme.md),
            ListTile(
              leading: Icon(Icons.edit, color: DnDTheme.arcaneBlue),
              title: Text(
                'Bearbeiten',
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _editCharacter(context, pc);
              },
            ),
            ListTile(
              leading: Icon(
                pc.isFavorite ? Icons.star : Icons.star_border,
                color: pc.isFavorite ? DnDTheme.ancientGold : DnDTheme.mysticalPurple,
              ),
              title: Text(
                pc.isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(pc);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: DnDTheme.infoBlue),
              title: Text(
                'Duplizieren',
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Duplizieren wird in Kürze implementiert'),
                    backgroundColor: DnDTheme.infoBlue,
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: DnDTheme.errorRed),
              title: Text(
                'Löschen',
                style: DnDTheme.bodyText1.copyWith(color: DnDTheme.errorRed),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, pc);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCharacterOptions(BuildContext context, PlayerCharacter pc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          pc.name,
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.ancientGold,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${pc.raceName} ${pc.className} Level ${pc.level}',
                style: DnDTheme.bodyText1.copyWith(color: Colors.white),
              ),
              Text(
                'Spieler: ${pc.playerName}',
                style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
              ),
              const SizedBox(height: DnDTheme.sm),
              Text(
                'HP: ${pc.maxHp}',
                style: DnDTheme.bodyText2.copyWith(color: DnDTheme.successGreen),
              ),
              Text(
                'AC: ${pc.armorClass}',
                style: DnDTheme.bodyText2.copyWith(color: DnDTheme.infoBlue),
              ),
              Text(
                'Initiative: ${pc.initiativeBonus}',
                style: DnDTheme.bodyText2.copyWith(color: DnDTheme.arcaneBlue),
              ),
              if (pc.description != null && pc.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: DnDTheme.sm),
                  child: Text(
                    pc.description!,
                    style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Schließen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editCharacter(context, pc);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.arcaneBlue,
              foregroundColor: Colors.white,
            ),
            child: const Text('Bearbeiten'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PlayerCharacter pc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Löschen bestätigen',
          style: DnDTheme.headline3.copyWith(
            color: DnDTheme.errorRed,
          ),
        ),
        content: Text(
          'Möchten Sie ${pc.name} wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(
                color: DnDTheme.mysticalPurple,
              ),
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
                      backgroundColor: DnDTheme.successGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text('Fehler beim Löschen: $e'),
                      backgroundColor: DnDTheme.errorRed,
                    ),
                  );
                }
              }
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