import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../models/campaign.dart';
import '../../models/player_character.dart';
import '../../screens/characters/edit_pc_screen.dart';
import '../character_list/enhanced_hero_card_widget.dart';
import '../character_list/character_list_helpers.dart';
import '../../theme/dnd_theme.dart';


class CampaignHeroesTab extends StatefulWidget {
  final Campaign campaign;
  const CampaignHeroesTab({super.key, required this.campaign});

  @override
  State<CampaignHeroesTab> createState() => CampaignHeroesTabState();
}

class CampaignHeroesTabState extends State<CampaignHeroesTab> {
  late final PlayerCharacterModelRepository _pcRepository;
  late Future<List<PlayerCharacter>> _pcsFuture;
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
                return Center(
                  child: CircularProgressIndicator(
                    color: DnDTheme.ancientGold,
                  ),
                );
              }
              
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: DnDTheme.mysticalPurple.withOpacity(0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _showFavoritesOnly 
                            ? "Keine Helden gefunden, die den Filterkriterien entsprechen."
                            : "Keine Helden für diese Kampagne erstellt.",
                        style: DnDTheme.bodyText1.copyWith(
                          color: Colors.white70,
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
                          backgroundColor: DnDTheme.successGreen,
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: DnDTheme.arcaneBlue,
                              foregroundColor: Colors.white,
                            ),
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
                backgroundColor: DnDTheme.successGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          
          // Suchleiste
          TextField(
            decoration: InputDecoration(
              hintText: 'Helden suchen...',
              hintStyle: DnDTheme.bodyText2.copyWith(color: Colors.white54),
              prefixIcon: Icon(Icons.search, color: DnDTheme.ancientGold),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: DnDTheme.errorRed),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        _refreshPcList();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(color: DnDTheme.mysticalPurple),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(color: DnDTheme.mysticalPurple.withOpacity(0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                borderSide: BorderSide(color: DnDTheme.ancientGold, width: 2),
              ),
              filled: true,
              fillColor: DnDTheme.slateGrey.withOpacity(0.3),
            ),
            style: DnDTheme.bodyText1.copyWith(color: Colors.white),
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
                label: Text(
                  'Nur Favoriten',
                  style: TextStyle(
                    color: _showFavoritesOnly ? Colors.white : DnDTheme.mysticalPurple,
                  ),
                ),
                selected: _showFavoritesOnly,
                onSelected: (selected) {
                  setState(() {
                    _showFavoritesOnly = selected;
                  });
                  _refreshPcList();
                },
                backgroundColor: DnDTheme.slateGrey.withOpacity(0.3),
                selectedColor: DnDTheme.ancientGold,
                checkmarkColor: Colors.white,
                avatar: _showFavoritesOnly 
                    ? Icon(Icons.star, size: 16, color: Colors.white)
                    : Icon(Icons.star_border, size: 16, color: DnDTheme.mysticalPurple),
              ),
              
              const SizedBox(width: 12),
              
              // Sortierung
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
                    border: Border.all(
                      color: DnDTheme.mysticalPurple.withOpacity(0.5),
                    ),
                  ),
                  child: DropdownButtonFormField<SortOption>(
                    value: _sortOption,
                    decoration: InputDecoration(
                      labelText: 'Sortieren nach',
                      labelStyle: DnDTheme.bodyText2.copyWith(
                        color: DnDTheme.ancientGold,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    dropdownColor: DnDTheme.stoneGrey,
                    style: DnDTheme.bodyText2.copyWith(color: Colors.white),
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
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCharacterList(List<PlayerCharacter> pcs) {
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: pcs.length,
      itemBuilder: (context, index) {
        final pc = pcs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: EnhancedHeroCardWidget(
            character: pc,
            onTap: () => _editCharacter(context, pc),
            onEdit: () => _editCharacter(context, pc),
            onFavoriteToggle: () => _toggleFavorite(pc),
            onQuickAction: () => _showQuickActions(context, pc),
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
        SnackBar(
          content: Text('${pc.name} wurde dupliziert'),
          backgroundColor: DnDTheme.successGreen,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Duplizieren: $e'),
          backgroundColor: DnDTheme.errorRed,
        ),
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
        SnackBar(
          content: Text('Fehler beim Aktualisieren des Favoriten: $e'),
          backgroundColor: DnDTheme.errorRed,
        ),
      );
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
        padding: const EdgeInsets.all(16.0),
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
            const SizedBox(height: 16),
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
                _duplicateCharacter(pc);
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
    // Zeige detaillierte Charakter-Informationen
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
              const SizedBox(height: 8),
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
              if (pc.description != null && pc.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  pc.description!,
                  style: DnDTheme.bodyText2.copyWith(color: Colors.white70),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Schließen',
              style: DnDTheme.bodyText1.copyWith(color: DnDTheme.mysticalPurple),
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
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Löschen bestätigen',
          style: DnDTheme.headline3.copyWith(color: DnDTheme.errorRed),
        ),
        content: Text(
          'Möchtest du ${pc.name} wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: DnDTheme.bodyText1.copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: DnDTheme.bodyText1.copyWith(color: DnDTheme.mysticalPurple),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _pcRepository.delete(pc.id);
                _refreshPcList();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${pc.name} wurde gelöscht'),
                    backgroundColor: DnDTheme.successGreen,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler beim Löschen: $e'),
                    backgroundColor: DnDTheme.errorRed,
                  ),
                );
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