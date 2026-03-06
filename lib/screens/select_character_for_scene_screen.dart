import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/creature.dart';
import '../database/repositories/creature_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../theme/dnd_theme.dart';

/// Screen zur Auswahl von Charakteren für eine Scene
/// Unterstützt PCs, NPCs und Monster
class SelectCharacterForSceneScreen extends StatefulWidget {
  final List<String> previouslySelectedIds;

  const SelectCharacterForSceneScreen({
    Key? key,
    required this.previouslySelectedIds,
  }) : super(key: key);

  @override
  State<SelectCharacterForSceneScreen> createState() => _SelectCharacterForSceneScreenState();
}

class _SelectCharacterForSceneScreenState extends State<SelectCharacterForSceneScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  // State
  List<Creature> _creatures = [];
  List<Map<String, dynamic>> _playerCharacters = [];
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

      final creatures = await creatureRepo.findAll();
      final pcs = await pcRepo.findAll();

      setState(() {
        _creatures = creatures;
        _playerCharacters = pcs.map((pc) => {
          'id': pc.id,
          'name': pc.name,
          'level': pc.level,
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fehler beim Laden: $e'),
          backgroundColor: Colors.red,
        ),
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

  void _confirmSelection() {
    Navigator.pop(context, _selectedIds);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Charaktere auswählen'),
        backgroundColor: DnDTheme.mysticalPurple,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          TextButton(
            onPressed: _confirmSelection,
            child: Text(
              'Fertig (${_selectedIds.length})',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Suchen...',
                prefixIcon: Icon(Icons.search, color: DnDTheme.mysticalPurple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: DnDTheme.mysticalPurple.withOpacity(0.3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                ),
              ),
              onChanged: (value) {
                setState(() => _searchQuery = value);
              },
            ),
          ),

          // Tabs
          TabBar(
            controller: _tabController,
            labelColor: DnDTheme.mysticalPurple,
            unselectedLabelColor: Colors.grey,
            tabs: [
              Tab(text: 'Player Characters'),
              Tab(text: 'NPCs'),
              Tab(text: 'Monster'),
            ],
          ),

          // Content
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: DnDTheme.mysticalPurple))
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
    if (_filteredPCs.isEmpty) {
      return _buildEmptyState('Keine Player Characters gefunden');
    }

    return ListView.builder(
      itemCount: _filteredPCs.length,
      itemBuilder: (context, index) {
        final pc = _filteredPCs[index];
        final isSelected = _isSelected(pc['id'].toString());
        return _buildCharacterTile(
          id: pc['id'].toString(),
          name: pc['name'].toString(),
          subtitle: 'Level ${pc['level']}',
          type: 'PC',
          isSelected: isSelected,
          onTap: () => _toggleSelection(pc['id'].toString()),
        );
      },
    );
  }

  Widget _buildNPCList() {
    final npcs = _filteredCreatures.where((c) => !c.isPlayer && c.type != null).toList();
    
    if (npcs.isEmpty) {
      return _buildEmptyState('Keine NPCs gefunden');
    }

    return ListView.builder(
      itemCount: npcs.length,
      itemBuilder: (context, index) {
        final npc = npcs[index];
        final isSelected = _isSelected(npc.id);
        final subtitle = npc.challengeRating != null 
            ? 'CR ${npc.challengeRating.toString()}' 
            : (npc.type ?? 'NPC').toString();
        return _buildCharacterTile(
          id: npc.id,
          name: npc.name,
          subtitle: subtitle,
          type: 'NPC',
          isSelected: isSelected,
          onTap: () => _toggleSelection(npc.id),
        );
      },
    );
  }

  Widget _buildMonsterList() {
    final monsters = _filteredCreatures.where((c) => !c.isPlayer && c.type != null).toList();
    
    if (monsters.isEmpty) {
      return _buildEmptyState('Keine Monster gefunden');
    }

    return ListView.builder(
      itemCount: monsters.length,
      itemBuilder: (context, index) {
        final monster = monsters[index];
        final isSelected = _isSelected(monster.id);
        final subtitle = monster.challengeRating != null 
            ? 'CR ${monster.challengeRating.toString()}' 
            : (monster.type ?? 'Monster').toString();
        return _buildCharacterTile(
          id: monster.id,
          name: monster.name,
          subtitle: subtitle,
          type: 'Monster',
          isSelected: isSelected,
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
  }) {
    Color typeColor;
    switch (type) {
      case 'PC':
        typeColor = Colors.green;
        break;
      case 'NPC':
        typeColor = Colors.blue;
        break;
      case 'Monster':
        typeColor = Colors.red;
        break;
      default:
        typeColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: typeColor,
          child: Icon(
            type == 'PC' ? Icons.person : Icons.person_outline,
            color: Colors.white,
          ),
        ),
        title: Text(
          name,
          style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
        ),
        subtitle: Text(subtitle),
        trailing: isSelected
            ? Icon(Icons.check_circle, color: DnDTheme.mysticalPurple)
            : Icon(Icons.radio_button_unchecked, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}