import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../models/campaign.dart';
import '../models/player_character.dart';
import '../screens/characters/edit_pc_screen.dart';
import '../widgets/character_list/enhanced_hero_card_widget.dart';
import '../widgets/character_list/character_list_helpers.dart';


class CampaignHeroesTab extends StatefulWidget {
  final Campaign campaign;
  const CampaignHeroesTab({super.key, required this.campaign});

  @override
  State<CampaignHeroesTab> createState() => CampaignHeroesTabState();
}

class CampaignHeroesTabState extends State<CampaignHeroesTab> {
  late final PlayerCharacterModelRepository _pcRepository;
  late Future<List<PlayerCharacter>> _pcsFuture;
  HeroCardViewMode _viewMode = HeroCardViewMode.compact;
  SortOption _sortOption = SortOption.name;
  String _searchQuery = '';
  bool _showFavoritesOnly = false;

  @override
  void initState() {
    super.initState();
    _pcRepository = PlayerCharacterModelRepository(DatabaseConnection.instance);
    loadPcs();
  }

  void loadPcs() {
    setState(() {
      _pcsFuture = _loadFilteredCharacters();
    });
  }

  Future<List<PlayerCharacter>> _loadFilteredCharacters() async {
    final allPcs = await _pcRepository.findByCampaign(widget.campaign.id);
    
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
    loadPcs();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Suchleiste und Filter
        _buildSearchAndFilterBar(),
        
        // Heldenliste
        Expanded(
          child: FutureBuilder<List<PlayerCharacter>>(
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
                      const SizedBox(height: 16),
                      // Helden erstellen Button wenn keine Helden vorhanden
                      ElevatedButton.icon(
                        onPressed: () => _createNewCharacter(context),
                        icon: const Icon(Icons.person_add),
                        label: const Text('Ersten Held erstellen'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
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
        ),
      ],
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Helden erstellen Button
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12.0),
            child: ElevatedButton.icon(
              onPressed: () => _createNewCharacter(context),
              icon: const Icon(Icons.person_add, size: 20),
              label: const Text(
                'Neuen Held erstellen',
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
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
                  initialValue: _sortOption,
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
              
              const SizedBox(width: 12),
              
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
      builder: (ctx) => EditPCScreen(
        campaignId: widget.campaign.id,
        pcToEdit: pc,
      ),
    ));
    _refreshPcList();
  }

  void _createNewCharacter(BuildContext context) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => EditPCScreen(
        campaignId: widget.campaign.id,
      ),
    ));
    _refreshPcList();
  }

  void _duplicateCharacter(PlayerCharacter pc) async {
    try {
      final newId = const Uuid().v4();
      final duplicatedPc = PlayerCharacter(
        id: newId,
        campaignId: widget.campaign.id,
        name: '${pc.name} (Kopie)',
        playerName: pc.playerName,
        className: pc.className,
        raceName: pc.raceName,
        level: pc.level,
        maxHp: pc.maxHp,
        armorClass: pc.armorClass,
        initiativeBonus: pc.initiativeBonus,
        strength: pc.strength,
        dexterity: pc.dexterity,
        constitution: pc.constitution,
        intelligence: pc.intelligence,
        wisdom: pc.wisdom,
        charisma: pc.charisma,
        proficientSkills: pc.proficientSkills,
        size: pc.size,
        type: pc.type,
        subtype: pc.subtype,
        alignment: pc.alignment,
        description: pc.description,
        specialAbilities: pc.specialAbilities,
        attacks: pc.attacks,
        gold: pc.gold,
        silver: pc.silver,
        copper: pc.copper,
        sourceType: 'custom',
        sourceId: null,
        isFavorite: false, // Nicht als Favorit beim Duplizieren
        version: '1.0',
        attackList: pc.attackList,
        inventory: pc.inventory,
      );

      await _pcRepository.create(duplicatedPc);
      _refreshPcList();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${pc.name} wurde dupliziert')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Duplizieren: $e')),
      );
    }
  }

  void _toggleFavorite(PlayerCharacter pc) async {
    try {
      // Toggle den Favoriten-Status in der Datenbank
      await _pcRepository.toggleFavorite(pc.id);
      _refreshPcList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Aktualisieren des Favoriten: $e')),
      );
    }
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
                _duplicateCharacter(pc);
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
              try {
                await _pcRepository.delete(pc.id);
                _refreshPcList();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${pc.name} wurde gelöscht')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Fehler beim Löschen: $e')),
                );
              }
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