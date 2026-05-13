import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../database/repositories/player_model_repository.dart';
import '../../models/campaign.dart';
import '../../models/player.dart';
import '../../models/player_character.dart';
import '../../screens/characters/edit_pc_screen.dart';
import '../character_list/enhanced_hero_card_widget.dart';
import '../character_list/character_list_helpers.dart';
import '../../theme/app_theme.dart';


Color _parsePlayerColor(String hex) {
  try {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  } catch (_) {
    return const Color(0xFF6B6B66);
  }
}

class CampaignHeroesTab extends StatefulWidget {
  final Campaign campaign;
  const CampaignHeroesTab({super.key, required this.campaign});

  @override
  State<CampaignHeroesTab> createState() => CampaignHeroesTabState();
}

class CampaignHeroesTabState extends State<CampaignHeroesTab> {
  late final PlayerCharacterModelRepository _pcRepository;
  late final PlayerModelRepository _playerRepository;
  late Future<List<PlayerCharacter>> _pcsFuture;
  Map<String, Player> _playerById = {};
  SortOption _sortOption = SortOption.name;
  String _searchQuery = '';
  bool _showFavoritesOnly = false;
  bool _groupByPlayer = false;

  @override
  void initState() {
    super.initState();
    _pcRepository = PlayerCharacterModelRepository(DatabaseConnection.instance);
    _playerRepository = PlayerModelRepository(DatabaseConnection.instance);
    loadPcs();
  }

  void loadPcs() {
    setState(() {
      _pcsFuture = _loadFilteredCharacters();
    });
  }

  Future<List<PlayerCharacter>> _loadFilteredCharacters() async {
    final results = await Future.wait([
      _pcRepository.findByCampaign(widget.campaign.id),
      _playerRepository.findAll(),
    ]);
    final allPcs = results[0] as List<PlayerCharacter>;
    final players = results[1] as List<Player>;
    _playerById = {for (final p in players) p.id: p};

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
          // Buttons: Neuer Held + Ausleihen
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _createNewCharacter(context),
                  icon: const Icon(Icons.person_add, size: 18),
                  label: const Text('Neuer Held'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _showLendHeroDialog(context),
                  icon: const Icon(Icons.link, size: 18),
                  label: const Text('Ausleihen'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

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

              const SizedBox(width: 8),

              // Gruppierung nach Spieler
              FilterChip(
                label: Text(
                  'Nach Spieler',
                  style: TextStyle(
                    color: _groupByPlayer ? Colors.white : C.accent,
                  ),
                ),
                selected: _groupByPlayer,
                onSelected: (selected) => setState(() => _groupByPlayer = selected),
                backgroundColor: C.bgPanel.withValues(alpha: 0.3),
                selectedColor: C.accent,
                checkmarkColor: Colors.white,
                avatar: Icon(
                  Icons.people_outline,
                  size: 16,
                  color: _groupByPlayer ? Colors.white : C.accent,
                ),
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
    if (_groupByPlayer) return _buildGroupedCharacterList(pcs);
    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: pcs.length,
      itemBuilder: (context, index) {
        final pc = pcs[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: GestureDetector(
            onSecondaryTapUp: (details) =>
                _showHeroContextMenu(context, pc, details.globalPosition),
            child: EnhancedHeroCardWidget(
              character: pc,
              player: pc.playerId != null ? _playerById[pc.playerId] : null,
              onTap: () => _editCharacter(context, pc),
              onEdit: () => _editCharacter(context, pc),
              onFavoriteToggle: () => _toggleFavorite(pc),
              onQuickAction: () => _showQuickActions(context, pc),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGroupedCharacterList(List<PlayerCharacter> pcs) {
    final C = context.appColors;

    // Nach Spieler gruppieren
    final Map<String?, List<PlayerCharacter>> byPlayer = {};
    for (final pc in pcs) {
      final key = pc.playerId?.isNotEmpty == true ? pc.playerId : null;
      byPlayer.putIfAbsent(key, () => []).add(pc);
    }

    // Spieler-Gruppen alphabetisch sortieren
    final playerKeys = byPlayer.keys.where((k) => k != null).toList()
      ..sort((a, b) {
        final pA = _playerById[a]?.name ?? '';
        final pB = _playerById[b]?.name ?? '';
        return pA.compareTo(pB);
      });

    final items = <Widget>[];
    for (final key in playerKeys) {
      final player = _playerById[key];
      final color = player != null ? _parsePlayerColor(player.color) : C.accent;
      final heroes = byPlayer[key]!;

      items.add(_buildPlayerGroupHeader(player?.name ?? 'Unbekannt', color, heroes.length, C));
      for (final pc in heroes) {
        items.add(_buildHeroCard(pc));
      }
      items.add(const SizedBox(height: 8));
    }

    // "Ohne Spieler" am Ende
    if (byPlayer.containsKey(null)) {
      items.add(_buildPlayerGroupHeader('Ohne Spieler', C.textMid, byPlayer[null]!.length, C));
      for (final pc in byPlayer[null]!) {
        items.add(_buildHeroCard(pc));
      }
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: items,
    );
  }

  Widget _buildPlayerGroupHeader(String name, Color color, int count, AppColorsExtension C) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Text(name, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text('($count)', style: TextStyle(color: C.textSoft, fontSize: 12)),
          const SizedBox(width: 8),
          Expanded(child: Divider(color: color.withValues(alpha: 0.3), thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildHeroCard(PlayerCharacter pc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onSecondaryTapUp: (details) =>
            _showHeroContextMenu(context, pc, details.globalPosition),
        child: EnhancedHeroCardWidget(
          character: pc,
          player: pc.playerId != null ? _playerById[pc.playerId] : null,
          onTap: () => _editCharacter(context, pc),
          onEdit: () => _editCharacter(context, pc),
          onFavoriteToggle: () => _toggleFavorite(pc),
          onQuickAction: () => _showQuickActions(context, pc),
        ),
      ),
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

  Future<void> _createNewCharacter(BuildContext context) async {
    final C = context.appColors;
    final playerRepo = PlayerModelRepository(DatabaseConnection.instance);
    final players = await playerRepo.findAllSorted();
    if (!mounted) return;

    if (players.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text(
            'Erst Spieler anlegen (Heimatbildschirm → Spieler)'),
        backgroundColor: C.red,
      ));
      return;
    }

    final picked = await _showPlayerPickerSheet(context, players);
    if (!mounted) return;
    if (picked == null) return; // dismissed

    await Navigator.of(context).push(MaterialPageRoute(
      builder: (ctx) => EditPCScreen(
        campaignId: widget.campaign.id,
        initialPlayerId: picked,
      ),
    ));
    _refreshPcList();
  }

  /// Returns the chosen player id, or null when dismissed.
  Future<String?> _showPlayerPickerSheet(
      BuildContext context, List<Player> players) {
    final C = context.appColors;
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: C.bgPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Für welchen Spieler?',
                    style: TextStyle(
                        color: C.text,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Der Held gehört diesem Spieler und wird der Kampagne zugewiesen.',
                    style: TextStyle(color: C.textSoft, fontSize: 12),
                  ),
                ],
              ),
            ),
            Divider(color: C.border, height: 1),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                children: players.map((p) {
                  final color = _parsePlayerColor(p.color);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 14),
                      ),
                    ),
                    title: Text(p.name,
                        style: TextStyle(
                            color: C.text, fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.pop(ctx, p.id),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
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
        isFavorite: false,
        version: '1.0',
        attackList: pc.attackList,
        inventory: pc.inventory,
        playerId: pc.playerId,
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
              leading: Icon(Icons.link_off, color: C.amber),
              title: Text(
                'Aus Kampagne abziehen',
                style: TextStyle(fontSize: 14, color: C.amber),
              ),
              onTap: () {
                Navigator.pop(context);
                _removeFromCampaign(pc);
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

  Future<void> _removeFromCampaign(PlayerCharacter pc) async {
    try {
      await _pcRepository.removeFromCampaign(pc.id);
      _refreshPcList();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${pc.name} aus der Kampagne abgezogen'),
            backgroundColor: context.appColors.amber,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: context.appColors.red,
          ),
        );
      }
    }
  }

  Future<void> _showLendHeroDialog(BuildContext context) async {
    final C = context.appColors;

    // Alle Helden laden die noch nicht in dieser Kampagne sind
    final all = await _pcRepository.findAll();
    final available = all
        .where((pc) =>
            pc.campaignId == null ||
            pc.campaignId!.isEmpty ||
            pc.campaignId != widget.campaign.id)
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));

    if (!mounted) return;

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Keine verfügbaren Helden — zuerst im Spieler-Profil anlegen'),
          backgroundColor: C.textMid,
        ),
      );
      return;
    }

    final selected = await showDialog<List<String>>(
      context: context,
      builder: (ctx) => _LendHeroDialog(
        available: available,
        campaignTitle: widget.campaign.title,
        playerById: _playerById,
      ),
    );

    if (selected == null || selected.isEmpty || !mounted) return;

    int count = 0;
    for (final id in selected) {
      try {
        await _pcRepository.assignToCampaign(id, widget.campaign.id);
        count++;
      } catch (_) {}
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count Held${count == 1 ? '' : 'en'} ausgeliehen'),
          backgroundColor: context.appColors.green,
        ),
      );
      _refreshPcList();
    }
  }

  Future<void> _showHeroContextMenu(
      BuildContext context, PlayerCharacter pc, Offset globalPosition) async {
    final C = context.appColors;
    final result = await showMenu<String>(
      context: context,
      position: RelativeRect.fromLTRB(
        globalPosition.dx,
        globalPosition.dy,
        globalPosition.dx + 1,
        globalPosition.dy + 1,
      ),
      color: C.bgPanel,
      items: [
        PopupMenuItem<String>(
          value: 'remove',
          child: Row(
            children: [
              Icon(Icons.link_off, color: C.amber, size: 18),
              const SizedBox(width: 8),
              Text('Aus Kampagne abziehen', style: TextStyle(color: C.amber)),
            ],
          ),
        ),
      ],
    );
    if (result == 'remove' && mounted) {
      _removeFromCampaign(pc);
    }
  }
}

// ── DIALOG ────────────────────────────────────────────────────────────────────

class _LendHeroDialog extends StatefulWidget {
  const _LendHeroDialog({
    required this.available,
    required this.campaignTitle,
    required this.playerById,
  });
  final List<PlayerCharacter> available;
  final String campaignTitle;
  final Map<String, Player> playerById;

  @override
  State<_LendHeroDialog> createState() => _LendHeroDialogState();
}

class _LendHeroDialogState extends State<_LendHeroDialog> {
  final Set<String> _selected = {};
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<PlayerCharacter> get _filtered {
    if (_query.isEmpty) return widget.available;
    return widget.available.where((pc) {
      final player = pc.playerId != null ? widget.playerById[pc.playerId] : null;
      return pc.name.toLowerCase().contains(_query) ||
          pc.className.toLowerCase().contains(_query) ||
          (player?.name.toLowerCase().contains(_query) ?? false) ||
          pc.playerName.toLowerCase().contains(_query);
    }).toList();
  }

  // Baut eine gruppierte Liste: Map<spielerName, List<PC>>
  // Key null = "Ohne Spieler"
  List<({String? playerId, String label, Color color, List<PlayerCharacter> heroes})> _buildGroups(
      AppColorsExtension C) {
    final filtered = _filtered;
    final Map<String?, List<PlayerCharacter>> byPlayer = {};
    for (final pc in filtered) {
      final key = pc.playerId?.isNotEmpty == true ? pc.playerId : null;
      byPlayer.putIfAbsent(key, () => []).add(pc);
    }

    final groups = <({String? playerId, String label, Color color, List<PlayerCharacter> heroes})>[];

    // Erst Gruppen mit Spieler, alphabetisch nach Spielername
    final playerKeys = byPlayer.keys.where((k) => k != null).toList()
      ..sort((a, b) {
        final pA = widget.playerById[a]?.name ?? '';
        final pB = widget.playerById[b]?.name ?? '';
        return pA.compareTo(pB);
      });
    for (final key in playerKeys) {
      final player = widget.playerById[key];
      groups.add((
        playerId: key,
        label: player?.name ?? 'Unbekannt',
        color: player != null ? _parsePlayerColor(player.color) : C.accent,
        heroes: byPlayer[key]!..sort((a, b) => a.name.compareTo(b.name)),
      ));
    }

    // Zuletzt "Ohne Spieler"
    if (byPlayer.containsKey(null)) {
      groups.add((
        playerId: null,
        label: 'Ohne Spieler',
        color: C.textMid,
        heroes: byPlayer[null]!..sort((a, b) => a.name.compareTo(b.name)),
      ));
    }
    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final groups = _buildGroups(C);

    return Dialog(
      backgroundColor: C.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: C.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Held ausleihen',
                      style: TextStyle(color: C.text, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 2),
                  Text('Für: ${widget.campaignTitle}',
                      style: TextStyle(color: C.textSoft, fontSize: 12)),
                  const SizedBox(height: 12),
                  // Suchfeld
                  TextField(
                    controller: _searchCtrl,
                    autofocus: false,
                    style: TextStyle(fontSize: 13, color: C.text),
                    decoration: InputDecoration(
                      hintText: 'Name oder Spieler suchen…',
                      hintStyle: TextStyle(color: C.textSoft, fontSize: 13),
                      prefixIcon: Icon(Icons.search, size: 16, color: C.textSoft),
                      suffixIcon: _query.isNotEmpty
                          ? GestureDetector(
                              onTap: () => _searchCtrl.clear(),
                              child: Icon(Icons.close, size: 16, color: C.textSoft),
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: C.bgHover,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: C.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: C.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: C.accent),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(color: C.border, height: 1),

            // Gruppierte Heldenliste
            Flexible(
              child: groups.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Keine Helden gefunden',
                            style: TextStyle(color: C.textSoft, fontSize: 13)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      itemCount: groups.fold<int>(0, (sum, g) => sum + 1 + g.heroes.length),
                      itemBuilder: (ctx, index) {
                        // Index → Gruppe + Item auflösen
                        int cursor = 0;
                        for (final group in groups) {
                          if (index == cursor) {
                            // Gruppen-Header
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                              child: Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: group.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    group.label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: group.color,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '(${group.heroes.length})',
                                    style: TextStyle(fontSize: 10, color: C.textSoft),
                                  ),
                                ],
                              ),
                            );
                          }
                          cursor++;
                          final heroIndex = index - cursor;
                          if (heroIndex < group.heroes.length) {
                            final pc = group.heroes[heroIndex];
                            final isSelected = _selected.contains(pc.id);
                            final hasCampaign = pc.campaignId != null && pc.campaignId!.isNotEmpty;
                            return CheckboxListTile(
                              value: isSelected,
                              activeColor: group.color,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selected.add(pc.id);
                                } else {
                                  _selected.remove(pc.id);
                                }
                              }),
                              title: Text(pc.name,
                                  style: TextStyle(
                                      color: C.text,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                              subtitle: Row(
                                children: [
                                  Text(
                                    'Lvl ${pc.level} ${pc.className}',
                                    style: TextStyle(color: C.textSoft, fontSize: 11),
                                  ),
                                  if (hasCampaign) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 5, vertical: 1),
                                      decoration: BoxDecoration(
                                        color: C.amber.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                            color: C.amber.withValues(alpha: 0.4)),
                                      ),
                                      child: Text(
                                        'bereits in anderer Kampagne',
                                        style: TextStyle(
                                            color: C.amber,
                                            fontSize: 9,
                                            fontWeight: FontWeight.w500),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              secondary: CircleAvatar(
                                backgroundColor: group.color.withValues(alpha: 0.15),
                                radius: 18,
                                child: Text(
                                  pc.name.isNotEmpty ? pc.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                      color: group.color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13),
                                ),
                              ),
                            );
                          }
                          cursor += group.heroes.length;
                        }
                        return const SizedBox.shrink();
                      },
                    ),
            ),

            Divider(color: C.border, height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Abbrechen', style: TextStyle(color: C.textMid)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.pop(context, _selected.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: C.accent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: C.border,
                    ),
                    child: Text(
                      _selected.isEmpty
                          ? 'Auswählen'
                          : '${_selected.length} ausleihen',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
