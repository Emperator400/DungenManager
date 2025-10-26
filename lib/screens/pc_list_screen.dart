import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/player_character.dart';
import '../screens/unified_character_editor_screen.dart';
import '../widgets/character_list/enhanced_hero_card_widget.dart';
import '../widgets/character_list/character_list_helpers.dart';
import 'edit_pc_screen.dart';
import '../widgets/character_editor/character_editor_controller.dart' show CharacterType;

class PlayerCharacterListScreen extends StatefulWidget {
  final Campaign campaign;

  const PlayerCharacterListScreen({super.key, required this.campaign});

  @override
  State<PlayerCharacterListScreen> createState() => _PlayerCharacterListScreenState();
}

class _PlayerCharacterListScreenState extends State<PlayerCharacterListScreen> {
  final dbHelper = DatabaseHelper.instance;
  late Future<List<PlayerCharacter>> _pcsFuture;
  HeroCardViewMode _viewMode = HeroCardViewMode.compact;
  SortOption _sortOption = SortOption.name;
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _pcsFuture = _loadFilteredCharacters();
  }

  Future<List<PlayerCharacter>> _loadFilteredCharacters() async {
    final allPcs = await dbHelper.getPlayerCharactersForCampaign(widget.campaign.id);
    
    var filteredPcs = allPcs.where((pc) {
      final matchesSearch = _searchQuery.isEmpty ||
          pc.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pc.className.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          pc.playerName.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesFavorite = !_showFavoritesOnly || pc.isFavorite;
      
      return matchesSearch && matchesFavorite;
    }).toList();

    // Sortierung anwenden
    filteredPcs.sort((a, b) => CharacterListHelpers.compareCharacters(a, b, _sortOption));
    
    return filteredPcs;
  }

  void _refreshPcList() {
    setState(() {
      _pcsFuture = _loadFilteredCharacters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Helden: ${widget.campaign.title}"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: _buildSearchAndFilterBar(),
        ),
        actions: [
          // Ansichtswechsel
          PopupMenuButton<HeroCardViewMode>(
            icon: const Icon(Icons.view_list),
            onSelected: (mode) {
              setState(() {
                _viewMode = mode;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: HeroCardViewMode.compact,
                child: Row(
                  children: [
                    Icon(Icons.view_list, size: 16),
                    SizedBox(width: 8),
                    Text('Kompakt'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: HeroCardViewMode.detailed,
                child: Row(
                  children: [
                    Icon(Icons.view_agenda, size: 16),
                    SizedBox(width: 8),
                    Text('Detailliert'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: HeroCardViewMode.grid,
                child: Row(
                  children: [
                    Icon(Icons.grid_view, size: 16),
                    SizedBox(width: 8),
                    Text('Grid'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: HeroCardViewMode.inventory,
                child: Row(
                  children: [
                    Icon(Icons.backpack, size: 16),
                    SizedBox(width: 8),
                    Text('Inventar'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<PlayerCharacter>>(
        future: _pcsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isNotEmpty || _showFavoritesOnly 
                        ? "Keine Helden gefunden, die den Filterkriterien entsprechen."
                        : "Keine Helden für diese Kampagne erstellt.",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (_searchQuery.isNotEmpty || _showFavoritesOnly)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _showFavoritesOnly = false;
                          });
                          _refreshPcList();
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Filter zurücksetzen'),
                      ),
                    ),
                ],
              ),
            );
          }

          final pcs = snapshot.data!;
          return _buildCharacterList(pcs);
        },
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: "Neuen Helden hinzufügen",
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
            builder: (ctx) => EditPlayerCharacterScreen(campaignId: widget.campaign.id),
          ));
          _refreshPcList();
        },
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Suchleiste
          TextField(
            decoration: InputDecoration(
              hintText: 'Helden suchen...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        _refreshPcList();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
              // Kleine Verzögerung für die Suche
              Future.delayed(const Duration(milliseconds: 300), () {
                if (mounted) _refreshPcList();
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter-Row
          Row(
            children: [
              // Favoriten-Filter
              FilterChip(
                label: const Text('Nur Favoriten'),
                selected: _showFavoritesOnly,
                onSelected: (selected) {
                  setState(() {
                    _showFavoritesOnly = selected;
                  });
                  _refreshPcList();
                },
                avatar: _showFavoritesOnly 
                    ? const Icon(Icons.star, size: 16)
                    : const Icon(Icons.star_border, size: 16),
              ),
              
              const SizedBox(width: 12),
              
              // Sortierung
              Expanded(
                child: DropdownButtonFormField<SortOption>(
                  value: _sortOption,
                  decoration: InputDecoration(
                    labelText: 'Sortieren nach',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: SortOption.values.map((option) {
                    return DropdownMenuItem(
                      value: option,
                      child: Text(_getSortOptionLabel(option)),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _sortOption = value;
                      });
                      _refreshPcList();
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterList(List<PlayerCharacter> pcs) {
    switch (_viewMode) {
      case HeroCardViewMode.grid:
        return _buildGridLayout(pcs);
      case HeroCardViewMode.detailed:
        return _buildDetailedList(pcs);
      case HeroCardViewMode.inventory:
        return _buildInventoryList(pcs);
      case HeroCardViewMode.compact:
      default:
        return _buildCompactList(pcs);
    }
  }

  Widget _buildCompactList(List<PlayerCharacter> pcs) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: pcs.length,
      itemBuilder: (context, index) {
        final pc = pcs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: EnhancedHeroCardWidget(
            character: pc,
            viewMode: HeroCardViewMode.compact,
            onTap: () => _showCharacterOptions(context, pc),
            onEdit: () => _editCharacter(context, pc),
            onFavoriteToggle: () => _toggleFavorite(pc),
            onQuickAction: () => _showQuickActions(context, pc),
          ),
        );
      },
    );
  }

  Widget _buildDetailedList(List<PlayerCharacter> pcs) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: pcs.length,
      itemBuilder: (context, index) {
        final pc = pcs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: EnhancedHeroCardWidget(
            character: pc,
            viewMode: HeroCardViewMode.detailed,
            onTap: () => _showCharacterOptions(context, pc),
            onEdit: () => _editCharacter(context, pc),
            onFavoriteToggle: () => _toggleFavorite(pc),
            onQuickAction: () => _showQuickActions(context, pc),
          ),
        );
      },
    );
  }

  Widget _buildGridLayout(List<PlayerCharacter> pcs) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12.0,
          mainAxisSpacing: 12.0,
          childAspectRatio: 0.8,
        ),
        itemCount: pcs.length,
        itemBuilder: (context, index) {
          final pc = pcs[index];
          return EnhancedHeroCardWidget(
            character: pc,
            viewMode: HeroCardViewMode.grid,
            onTap: () => _showCharacterOptions(context, pc),
            onEdit: () => _editCharacter(context, pc),
            onFavoriteToggle: () => _toggleFavorite(pc),
            onQuickAction: () => _showQuickActions(context, pc),
          );
        },
      ),
    );
  }

  Widget _buildInventoryList(List<PlayerCharacter> pcs) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: pcs.length,
      itemBuilder: (context, index) {
        final pc = pcs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: SizedBox(
            height: 300, // Feste Höhe für Inventar-Karten
            child: EnhancedHeroCardWidget(
              character: pc,
              viewMode: HeroCardViewMode.inventory,
              onTap: () => _showCharacterOptions(context, pc),
              onEdit: () => _editCharacter(context, pc),
              onFavoriteToggle: () => _toggleFavorite(pc),
              onQuickAction: () => _showQuickActions(context, pc),
            ),
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
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => UnifiedCharacterEditorScreen(
        characterType: CharacterType.player,
        campaignId: widget.campaign.id,
        pcToEdit: pc,
      ),
    ));
    _refreshPcList();
  }

  void _toggleFavorite(PlayerCharacter pc) async {
    // Hier müsste die Datenbank-Implementierung folgen
    // Für jetzt nur UI-Update
    setState(() {
      // Aktualisiere den lokalen Zustand
    });
    _refreshPcList();
  }

  void _showQuickActions(BuildContext context, PlayerCharacter pc) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktionen für ${pc.name}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Bearbeiten'),
              onTap: () {
                Navigator.pop(context);
                _editCharacter(context, pc);
              },
            ),
            ListTile(
              leading: Icon(
                pc.isFavorite ? Icons.star : Icons.star_border,
                color: pc.isFavorite ? Colors.amber : null,
              ),
              title: Text(pc.isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen'),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(pc);
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Duplizieren'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Duplizieren-Implementierung
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Duplizieren noch nicht implementiert')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Löschen', style: TextStyle(color: Colors.red)),
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
    // Zeige detaillierte Charakter-Informationen
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(pc.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${pc.raceName} ${pc.className} Level ${pc.level}'),
              Text('Spieler: ${pc.playerName}'),
              const SizedBox(height: 8),
              Text('HP: ${pc.maxHp}'),
              Text('AC: ${pc.armorClass}'),
              Text('Initiative: ${pc.initiativeBonus}'),
              if (pc.description != null && pc.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(pc.description!),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _editCharacter(context, pc);
            },
            child: const Text('Bearbeiten'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, PlayerCharacter pc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Löschen bestätigen'),
        content: Text('Möchtest du ${pc.name} wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              // TODO: Datenbank-Löschung implementieren
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Löschen noch nicht implementiert')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}
