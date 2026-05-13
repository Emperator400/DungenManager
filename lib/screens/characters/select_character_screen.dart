import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/creature_model_repository.dart';
import '../../database/repositories/player_character_model_repository.dart';
import '../../database/repositories/player_model_repository.dart';
import '../../models/creature.dart';
import '../../models/player.dart';
import '../../theme/app_theme.dart';

Color _parseHexColor(String hex) {
  try {
    return Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
  } catch (_) {
    return const Color(0xFF6B6B66);
  }
}

class SelectCharacterForSceneScreen extends StatefulWidget {
  const SelectCharacterForSceneScreen({
    super.key,
    required this.previouslySelectedIds,
  });

  final List<String> previouslySelectedIds;

  @override
  State<SelectCharacterForSceneScreen> createState() =>
      _SelectCharacterForSceneScreenState();
}

class _SelectCharacterForSceneScreenState extends State<SelectCharacterForSceneScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<Creature> _creatures = [];
  List<Map<String, dynamic>> _playerCharacters = [];
  Map<String, Player> _playerById = {};
  List<String> _selectedIds = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedIds = List.from(widget.previouslySelectedIds);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final creatureRepo = context.read<CreatureModelRepository>();
      final pcRepo = context.read<PlayerCharacterModelRepository>();
      final playerRepo = PlayerModelRepository(DatabaseConnection.instance);
      final results = await Future.wait([
        creatureRepo.findAll(),
        pcRepo.findAll(),
        playerRepo.findAll(),
      ]);
      final creatures = results[0] as List<Creature>;
      final pcs = results[1] as List;
      final players = results[2] as List<Player>;
      if (!mounted) return;
      setState(() {
        _creatures = creatures;
        _playerCharacters = pcs
            .map((pc) => {
                  'id': pc.id as String,
                  'name': pc.name as String,
                  'level': pc.level as int,
                  'playerId': pc.playerId as String?,
                })
            .toList();
        _playerById = {for (final p in players) p.id: p};
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden: $e'), backgroundColor: context.appColors.red),
      );
    }
  }

  List<Creature> get _filteredCreatures {
    if (_searchQuery.isEmpty) return _creatures;
    return _creatures
        .where((c) => c.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  List<Map<String, dynamic>> get _filteredPCs {
    if (_searchQuery.isEmpty) return _playerCharacters;
    return _playerCharacters
        .where((pc) => pc['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  bool _isSelected(String id) => _selectedIds.contains(id);

  void _confirmSelection() => Navigator.pop(context, _selectedIds);

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Charaktere auswählen'),
        backgroundColor: C.bgPanel,
        foregroundColor: C.text,
        actions: [
          TextButton(
            onPressed: _confirmSelection,
            child: Text(
              'Fertig (${_selectedIds.length})',
              style: TextStyle(color: C.amber, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suchen...',
                prefixIcon: Icon(Icons.search, color: C.accent),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: C.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: C.accent),
                ),
                filled: true,
                fillColor: C.bgHover,
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: C.accent,
            unselectedLabelColor: C.textMid,
            indicatorColor: C.accent,
            tabs: const [
              Tab(text: 'Player Characters'),
              Tab(text: 'NPCs'),
              Tab(text: 'Monster'),
            ],
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: C.accent))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPCList(),
                      _buildNPCList(),
                      _buildMonsterList(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPCList() {
    if (_filteredPCs.isEmpty) return _buildEmptyState('Keine Player Characters gefunden');
    return ListView.builder(
      itemCount: _filteredPCs.length,
      itemBuilder: (context, index) {
        final pc = _filteredPCs[index];
        final id = pc['id'].toString();
        final playerId = pc['playerId'] as String?;
        final player = playerId != null ? _playerById[playerId] : null;
        final playerColor = player != null ? _parseHexColor(player.color) : null;
        final subtitle = [
          'Level ${pc['level']}',
          if (player != null) player.name,
        ].join(' · ');
        return _buildCharacterTile(
          id: id,
          name: pc['name'].toString(),
          subtitle: subtitle,
          type: 'PC',
          isSelected: _isSelected(id),
          onTap: () => _toggleSelection(id),
          playerColor: playerColor,
        );
      },
    );
  }

  Widget _buildNPCList() {
    final npcs = _filteredCreatures.where((c) {
      if (c.isPlayer) return false;
      final typeLower = c.type?.toLowerCase();
      if (typeLower == null || typeLower.isEmpty) return true;
      return typeLower == 'humanoid' || typeLower == 'npc';
    }).toList();

    if (npcs.isEmpty) {
      return _buildEmptyState('Keine NPCs gefunden\n(Tip: NPCs haben den Typ "Humanoid")');
    }
    return ListView.builder(
      itemCount: npcs.length,
      itemBuilder: (context, index) {
        final npc = npcs[index];
        final subtitle = npc.challengeRating != null
            ? 'CR ${npc.challengeRating} • ${npc.type ?? "Humanoid"}'
            : (npc.type ?? 'Humanoid');
        return _buildCharacterTile(
          id: npc.id,
          name: npc.name,
          subtitle: subtitle,
          type: 'NPC',
          isSelected: _isSelected(npc.id),
          onTap: () => _toggleSelection(npc.id),
        );
      },
    );
  }

  Widget _buildMonsterList() {
    final monsters = _filteredCreatures.where((c) {
      if (c.isPlayer) return false;
      final typeLower = c.type?.toLowerCase();
      if (typeLower == null || typeLower.isEmpty) return false;
      return typeLower != 'humanoid' && typeLower != 'npc';
    }).toList();

    if (monsters.isEmpty) {
      return _buildEmptyState(
        'Keine Monster gefunden\n(Tip: Monster haben einen anderen Typ als "Humanoid"\nz.B. Beast, Dragon, Undead, etc.)',
      );
    }
    return ListView.builder(
      itemCount: monsters.length,
      itemBuilder: (context, index) {
        final monster = monsters[index];
        final subtitle = monster.challengeRating != null
            ? 'CR ${monster.challengeRating} • ${monster.type ?? "Unbekannt"}'
            : (monster.type ?? 'Monster');
        return _buildCharacterTile(
          id: monster.id,
          name: monster.name,
          subtitle: subtitle,
          type: 'Monster',
          isSelected: _isSelected(monster.id),
          onTap: () => _toggleSelection(monster.id),
        );
      },
    );
  }

  Widget _buildCharacterTile({
    required String id,
    required String name,
    required String subtitle,
    required String type,
    required bool isSelected,
    required VoidCallback onTap,
    Color? playerColor,
  }) {
    final C = context.appColors;
    final typeColor = switch (type) {
      'PC' => playerColor ?? C.green,
      'NPC' => C.accent,
      _ => C.red,
    };
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor.withValues(alpha: type == 'PC' && playerColor != null ? 0.2 : 1.0),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: type == 'PC' && playerColor != null ? playerColor : Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: Text(subtitle),
        trailing: Icon(
          isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isSelected ? C.accent : C.textSoft,
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    final C = context.appColors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: C.textSoft),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: C.textSoft),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
