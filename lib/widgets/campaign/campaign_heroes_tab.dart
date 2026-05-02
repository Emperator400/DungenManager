import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../models/campaign.dart';
import '../../models/player_character.dart';
import '../../screens/characters/edit_pc_screen.dart';
import '../character_list/enhanced_hero_card_widget.dart';
import '../character_list/character_list_helpers.dart';
import '../../theme/app_theme.dart';


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
    final C = context.appColors;
    return Column(
      children: [
        // Suchleiste und Filter
        _buildSearchAndFilterBar(C),

        // Heldenliste
        Expanded(
          child: FutureBuilder<List<PlayerCharacter>>(
            future: _pcsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    color: C.amber,
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
                        color: C.accent.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isNotEmpty || _showFavoritesOnly
                            ? "Keine Helden gefunden, die den Filterkriterien entsprechen."
                            : "Keine Helden für diese Kampagne erstellt.",
                        style: TextStyle(fontSize: 14, color: C.text).copyWith(
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
                          backgroundColor: C.green,
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
                              backgroundColor: C.accent,
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

  Widget _buildSearchAndFilterBar(AppColorsExtension C) {
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
                backgroundColor: C.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          // Suchleiste
          TextField(
            decoration: InputDecoration(
              hintText: 'Helden suchen...',
              hintStyle: TextStyle(fontSize: 12, color: C.textMid).copyWith(color: Colors.white54),
              prefixIcon: Icon(Icons.search, color: C.amber),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: C.red),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                        _refreshPcList();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: C.accent),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: C.accent.withValues(alpha: 0.5)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                borderSide: BorderSide(color: C.amber, width: 2),
              ),
              filled: true,
              fillColor: C.bgPanel.withValues(alpha: 0.3),
            ),
            style: TextStyle(fontSize: 14, color: C.text).copyWith(color: Colors.white),
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
                    color: _showFavoritesOnly ? Colors.white : C.accent,
                  ),
                ),
                selected: _showFavoritesOnly,
                onSelected: (selected) {
                  setState(() {
                    _showFavoritesOnly = selected;
                  });
                  _refreshPcList();
                },
                backgroundColor: C.bgPanel.withValues(alpha: 0.3),
                selectedColor: C.amber,
                checkmarkColor: Colors.white,
                avatar: _showFavoritesOnly
                    ? Icon(Icons.star, size: 16, color: Colors.white)
                    : Icon(Icons.star_border, size: 16, color: C.accent),
              ),

              const SizedBox(width: 12),

              // Sortierung
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: C.accent.withValues(alpha: 0.5),
                    ),
                  ),
                  child: DropdownButtonFormField<SortOption>(
                    value: _sortOption,
                    decoration: InputDecoration(
                      labelText: 'Sortieren nach',
                      labelStyle: TextStyle(fontSize: 12, color: C.textMid).copyWith(
                        color: C.amber,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    dropdownColor: C.bg,
                    style: TextStyle(fontSize: 12, color: C.textMid).copyWith(color: Colors.white),
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
          backgroundColor: context.appColors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Duplizieren: $e'),
          backgroundColor: context.appColors.red,
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
          backgroundColor: context.appColors.red,
        ),
      );
    }
  }

  void _showQuickActions(BuildContext context, PlayerCharacter pc) {
    final C = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: C.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12.0)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Aktionen für ${pc.name}',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text).copyWith(
                color: C.amber,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.edit, color: C.accent),
              title: Text(
                'Bearbeiten',
                style: TextStyle(fontSize: 14, color: C.text).copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _editCharacter(context, pc);
              },
            ),
            ListTile(
              leading: Icon(
                pc.isFavorite ? Icons.star : Icons.star_border,
                color: pc.isFavorite ? C.amber : C.accent,
              ),
              title: Text(
                pc.isFavorite ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen',
                style: TextStyle(fontSize: 14, color: C.text).copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _toggleFavorite(pc);
              },
            ),
            ListTile(
              leading: Icon(Icons.copy, color: C.accent),
              title: Text(
                'Duplizieren',
                style: TextStyle(fontSize: 14, color: C.text).copyWith(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _duplicateCharacter(pc);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: C.red),
              title: Text(
                'Löschen',
                style: TextStyle(fontSize: 14, color: C.text).copyWith(color: C.red),
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

  void _showDeleteConfirmation(BuildContext context, PlayerCharacter pc) {
    final C = context.appColors;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bg,
        title: Text(
          'Löschen bestätigen',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.text).copyWith(color: C.red),
        ),
        content: Text(
          'Möchtest du ${pc.name} wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
          style: TextStyle(fontSize: 14, color: C.text).copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Abbrechen',
              style: TextStyle(fontSize: 14, color: C.text).copyWith(color: C.accent),
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
                    backgroundColor: context.appColors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Fehler beim Löschen: $e'),
                    backgroundColor: context.appColors.red,
                  ),
                );
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
