// lib/screens/official_monsters_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/official_monster.dart';
import '../game_data/dnd_data_importer.dart';

class OfficialMonstersScreen extends StatefulWidget {
  const OfficialMonstersScreen({super.key});

  @override
  _OfficialMonstersScreenState createState() => _OfficialMonstersScreenState();
}

class _OfficialMonstersScreenState extends State<OfficialMonstersScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final DndDataImporter _importer = DndDataImporter();
  
  List<Map<String, dynamic>> _monsters = [];
  List<Map<String, dynamic>> _filteredMonsters = [];
  bool _isLoading = false;
  bool _isImporting = false;
  String _searchQuery = '';
  String? _selectedType;
  double? _minCr;
  double? _maxCr;
  int _currentPage = 0;
  final int _itemsPerPage = 20;
  bool _hasMoreData = true;

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadMonsters();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadMoreMonsters();
    }
  }

  Future<void> _loadMonsters({bool reset = false}) async {
    if (reset) {
      setState(() {
        _currentPage = 0;
        _hasMoreData = true;
        _monsters.clear();
        _filteredMonsters.clear();
      });
    }

    if (!_hasMoreData || _isLoading) return;

    setState(() => _isLoading = true);

    try {
      final monsters = await _db.getAllOfficialMonsters(
        page: _currentPage,
        limit: _itemsPerPage,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        type: _selectedType,
        minCr: _minCr,
        maxCr: _maxCr,
      );

      setState(() {
        _monsters.addAll(monsters);
        _filteredMonsters = List.from(_monsters);
        _hasMoreData = monsters.length >= _itemsPerPage;
        _currentPage++;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Fehler beim Laden der Monster: $e');
    }
  }

  Future<void> _loadMoreMonsters() async {
    await _loadMonsters();
  }

  Future<void> _importMonsters() async {
    if (_isImporting) return;

    final confirmed = await _showConfirmDialog(
      'Monster importieren',
      'Möchtest du wirklich alle Monster-Daten von 5e.tools herunterladen und importieren?\n\n'
      'Dabei werden alle bestehenden Monster-Daten überschrieben.',
    );

    if (!confirmed) return;

    setState(() => _isImporting = true);

    try {
      final count = await _importer.importMonsters();
      _showSuccess('$count Monster erfolgreich importiert');
      await _loadMonsters(reset: true);
    } catch (e) {
      _showError('Fehler beim Import: $e');
    } finally {
      setState(() => _isImporting = false);
    }
  }

  void _filterMonsters() {
    setState(() {
      _filteredMonsters = _monsters.where((monster) {
        final name = monster['name']?.toString().toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        final matchesSearch = query.isEmpty || name.contains(query);
        
        final type = monster['type']?.toString();
        final matchesType = _selectedType == null || type == _selectedType;
        
        final cr = (monster['challenge_rating'] as num?)?.toDouble() ?? 0.0;
        final matchesCr = (_minCr == null || cr >= _minCr!) && 
                         (_maxCr == null || cr <= _maxCr!);
        
        return matchesSearch && matchesType && matchesCr;
      }).toList();
    });
  }

  void _showMonsterDetails(Map<String, dynamic> monsterData) {
    final monster = OfficialMonster.fromMap(monsterData);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(monster.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoRow('Typ', '${monster.size} ${monster.type}${monster.subtype != null ? ' (${monster.subtype})' : ''}'),
              _buildInfoRow('Ausrichtung', monster.alignment),
              _buildInfoRow('RK', monster.armorClass),
              _buildInfoRow('TP', '${monster.hitPoints} (${monster.hitDice})'),
              _buildInfoRow('Bewegung', monster.speed),
              _buildInfoRow('SG', monster.challengeRating.toString()),
              _buildInfoRow('EP', monster.xp.toString()),
              const SizedBox(height: 16),
              
              const Text('Attributswerte', style: TextStyle(fontWeight: FontWeight.bold)),
              _buildStatsRow('ST', monster.strength),
              _buildStatsRow('GE', monster.dexterity),
              _buildStatsRow('KO', monster.constitution),
              _buildStatsRow('IN', monster.intelligence),
              _buildStatsRow('WE', monster.wisdom),
              _buildStatsRow('CH', monster.charisma),
              const SizedBox(height: 16),
              
              if (monster.savingThrows.isNotEmpty) ...[
                const Text('Rettungswürfe', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(monster.savingThrows.join(', ')),
                const SizedBox(height: 8),
              ],
              
              if (monster.skills.isNotEmpty) ...[
                const Text('Fertigkeiten', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(monster.skills.entries.map((e) => '${e.key} ${e.value > 0 ? '+' : ''}${e.value}').join(', ')),
                const SizedBox(height: 8),
              ],
              
              if (monster.damageImmunities.isNotEmpty) ...[
                const Text('Schadensimmunitäten', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(monster.damageImmunities.join(', ')),
                const SizedBox(height: 8),
              ],
              
              if (monster.damageResistances.isNotEmpty) ...[
                const Text('Schadensresistenzen', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(monster.damageResistances.join(', ')),
                const SizedBox(height: 8),
              ],
              
              if (monster.damageVulnerabilities.isNotEmpty) ...[
                const Text('Schadensverwundbarkeiten', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(monster.damageVulnerabilities.join(', ')),
                const SizedBox(height: 8),
              ],
              
              if (monster.conditionImmunities.isNotEmpty) ...[
                const Text('Zustandsimmunitäten', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(monster.conditionImmunities.join(', ')),
                const SizedBox(height: 8),
              ],
              
              if (monster.senses.isNotEmpty) ...[
                const Text('Sinne', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(monster.senses.entries.map((e) => '${e.key} ${e.value}').join(', ')),
                const SizedBox(height: 8),
              ],
              
              if (monster.languages.isNotEmpty) ...[
                const Text('Sprachen', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(monster.languages),
                const SizedBox(height: 8),
              ],
              
              if (monster.specialAbilities.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Besondere Eigenschaften', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ...monster.specialAbilities.map((ability) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(ability.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(ability.description),
                    ],
                  ),
                )),
              ],
              
              if (monster.actions.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Aktionen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ...monster.actions.map((action) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(action.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(action.description),
                    ],
                  ),
                )),
              ],
              
              if (monster.legendaryActions != null && monster.legendaryActions!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('Legendäre Aktionen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ...monster.legendaryActions!.map((action) => Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${action.name} (${action.cost} Aktion${action.cost != 1 ? 'en' : ''})', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(action.description),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 100, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String stat, int value) {
    final modifier = ((value - 10) / 2).floor();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 30, child: Text(stat, style: const TextStyle(fontWeight: FontWeight.bold))),
          Text('$value (${modifier >= 0 ? '+' : ''}$modifier)'),
        ],
      ),
    );
  }

  Future<void> _showFilterDialog() async {
    final types = await _getMonsterTypes();
    
    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Monster filtern'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: 'Typ'),
                value: _selectedType,
                items: [
                  const DropdownMenuItem(value: null, child: Text('Alle Typen')),
                  ...types.map((type) => DropdownMenuItem(value: type, child: Text(type))),
                ],
                onChanged: (value) => setState(() => _selectedType = value),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Min. SG'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setState(() => _minCr = double.tryParse(value));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Max. SG'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      onChanged: (value) {
                        setState(() => _maxCr = double.tryParse(value));
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Abbrechen'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                this.setState(() {
                  _currentPage = 0;
                  _hasMoreData = true;
                  _monsters.clear();
                });
                _loadMonsters();
              },
              child: const Text('Anwenden'),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<String>> _getMonsterTypes() async {
    final types = <String>{};
    final monsters = await _db.getAllOfficialMonsters(limit: 1000);
    for (final monster in monsters) {
      final type = monster['type']?.toString();
      if (type != null) types.add(type);
    }
    return types.toList()..sort();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bestätigen'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Offizielle Monster'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: _isImporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            onPressed: _importMonsters,
            tooltip: 'Monster importieren',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Suchen',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                            _filterMonsters();
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                  _filterMonsters();
                });
              },
            ),
          ),
          Expanded(
            child: _isLoading && _monsters.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredMonsters.isEmpty
                    ? const Center(child: Text('Keine Monster gefunden'))
                    : ListView.builder(
                        controller: _scrollController,
                        itemCount: _filteredMonsters.length + (_hasMoreData ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _filteredMonsters.length) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          final monster = _filteredMonsters[index];
                          return ListTile(
                            title: Text(monster['name']?.toString() ?? 'Unbekannt'),
                            subtitle: Text(
                              '${monster['type']?.toString() ?? 'Unbekannt'} • '
                              'SG ${monster['challenge_rating']?.toString() ?? '0'} • '
                              'TP ${monster['hit_points']?.toString() ?? '0'}'
                            ),
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () => _showMonsterDetails(monster),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
