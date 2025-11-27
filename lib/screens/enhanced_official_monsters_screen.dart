import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/official_monster.dart';
import '../viewmodels/official_monsters_viewmodel.dart';
import '../theme/dnd_theme.dart';

/// Enhanced Screen für offizielle Monster mit modernem Design
class EnhancedOfficialMonstersScreen extends StatefulWidget {
  const EnhancedOfficialMonstersScreen({Key? key}) : super(key: key);

  @override
  State<EnhancedOfficialMonstersScreen> createState() => _EnhancedOfficialMonstersScreenState();
}

class _EnhancedOfficialMonstersScreenState extends State<EnhancedOfficialMonstersScreen> {
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  MonsterSortCriteria _sortCriteria = MonsterSortCriteria.nameAsc;
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    // ViewModel initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OfficialMonstersViewModel>().initialize();
    });
    
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
      final viewModel = context.read<OfficialMonstersViewModel>();
      if (viewModel.hasMoreData && !viewModel.isLoading) {
        viewModel.loadMoreMonsters();
      }
    }
  }

  String _formatChallengeRating(double cr) {
    if (cr == cr.truncate()) {
      return cr.truncate().toString();
    }
    return cr.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Offizielle Monster',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: DnDTheme.mysticalPurple,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Consumer<OfficialMonstersViewModel>(
            builder: (context, viewModel, child) {
              return PopupMenuButton<MonsterSortCriteria>(
                icon: Icon(Icons.sort, color: Colors.white),
                tooltip: 'Sortieren',
                onSelected: (criteria) {
                  setState(() {
                    _sortCriteria = criteria;
                  });
                  viewModel.sortMonsters(criteria);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: MonsterSortCriteria.nameAsc,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 16),
                        const SizedBox(width: 8),
                        Text('Name (A-Z)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: MonsterSortCriteria.nameDesc,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, size: 16),
                        const SizedBox(width: 8),
                        Text('Name (Z-A)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: MonsterSortCriteria.crAsc,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 16),
                        const SizedBox(width: 8),
                        Text('SG (niedrig-hoch)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: MonsterSortCriteria.crDesc,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, size: 16),
                        const SizedBox(width: 8),
                        Text('SG (hoch-niedrig)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: MonsterSortCriteria.hpAsc,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 16),
                        const SizedBox(width: 8),
                        Text('TP (wenig-viel)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: MonsterSortCriteria.hpDesc,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, size: 16),
                        const SizedBox(width: 8),
                        Text('TP (viel-wenig)'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
          Consumer<OfficialMonstersViewModel>(
            builder: (context, viewModel, child) {
              return IconButton(
                icon: viewModel.isImporting 
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.download, color: Colors.white),
                onPressed: viewModel.isImporting ? null : _importMonsters,
                tooltip: 'Monster importieren',
              );
            },
          ),
        ],
      ),
      body: Consumer<OfficialMonstersViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.filteredMonsters.isEmpty) {
            return Center(
              child: CircularProgressIndicator(color: DnDTheme.mysticalPurple),
            );
          }

          final monsters = _isSearchMode && _searchController.text.isNotEmpty
              ? viewModel.searchMonsters(_searchController.text)
              : viewModel.filteredMonsters;

          if (monsters.isEmpty) {
            return _buildEmptyState(viewModel);
          }

          return Column(
            children: [
              // Suchleiste
              Container(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Monster suchen...',
                    prefixIcon: Icon(Icons.search, color: DnDTheme.mysticalPurple),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _isSearchMode = false;
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: DnDTheme.mysticalPurple.withOpacity(0.3)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      borderSide: BorderSide(color: DnDTheme.mysticalPurple),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isSearchMode = value.isNotEmpty;
                    });
                    viewModel.setSearchQuery(value);
                  },
                ),
              ),

              // Filter-Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                height: 60,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildFilterChip(
                      'Alle',
                      viewModel.selectedType == null,
                      () => viewModel.setSelectedType(null),
                    ),
                    ...viewModel.availableTypes.map((type) => _buildFilterChip(
                      type,
                      viewModel.selectedType == type,
                      () => viewModel.setSelectedType(type),
                    )),
                  ],
                ),
              ),

              // Monster-Liste
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: monsters.length + (viewModel.hasMoreData ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == monsters.length) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: CircularProgressIndicator(color: DnDTheme.mysticalPurple),
                        ),
                      );
                    }
                    
                    final monster = monsters[index];
                    return _buildMonsterCard(monster);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(OfficialMonstersViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pets,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Monster gefunden',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Importieren Sie Monster oder passen Sie die Filter an',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _importMonsters,
            icon: Icon(Icons.download),
            label: Text('Monster importieren'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.mysticalPurple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        backgroundColor: Colors.grey.shade200,
        selectedColor: DnDTheme.mysticalPurple.withOpacity(0.2),
        checkmarkColor: DnDTheme.mysticalPurple,
      ),
    );
  }

  Widget _buildMonsterCard(OfficialMonster monster) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _showMonsterDetails(monster),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: DnDTheme.mysticalPurple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Icon(
                      Icons.pets,
                      color: DnDTheme.mysticalPurple,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          monster.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${monster.size} ${monster.type}${monster.subtype != null ? ' (${monster.subtype})' : ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCrColor(monster.challengeRating),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'SG ${_formatChallengeRating(monster.challengeRating)}',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'TP ${monster.hitPoints}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatChip('RK', monster.armorClass.toString()),
                  const SizedBox(width: 8),
                  _buildStatChip('ST', monster.strength.toString()),
                  const SizedBox(width: 8),
                  _buildStatChip('GE', monster.dexterity.toString()),
                  const SizedBox(width: 8),
                  _buildStatChip('KO', monster.constitution.toString()),
                  const SizedBox(width: 8),
                  _buildStatChip('IN', monster.intelligence.toString()),
                  const SizedBox(width: 8),
                  _buildStatChip('WE', monster.wisdom.toString()),
                  const SizedBox(width: 8),
                  _buildStatChip('CH', monster.charisma.toString()),
                ],
              ),
              if (monster.languages.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.language, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        monster.languages,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          fontSize: 10,
          color: Colors.grey.shade700,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getCrColor(double cr) {
    if (cr <= 0.25) return Colors.green;
    if (cr <= 0.5) return Colors.lightGreen;
    if (cr <= 1) return Colors.yellow.shade700;
    if (cr <= 2) return Colors.orange;
    if (cr <= 4) return Colors.deepOrange;
    if (cr <= 8) return Colors.red;
    if (cr <= 12) return Colors.purple;
    if (cr <= 16) return Colors.deepPurple;
    return Colors.black;
  }

  void _showMonsterDetails(OfficialMonster monster) {
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
              _buildInfoRow('RK', monster.armorClass.toString()),
              _buildInfoRow('TP', '${monster.hitPoints} (${monster.hitDice})'),
              _buildInfoRow('Bewegung', monster.speed),
              _buildInfoRow('SG', _formatChallengeRating(monster.challengeRating)),
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
                Text(monster.skills.entries.map((e) => '${e.key} ${e.value}').join(', ')),
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

  Future<void> _importMonsters() async {
    final confirmed = await _showConfirmDialog(
      'Monster importieren',
      'Möchten Sie wirklich alle Monster-Daten von 5e.tools herunterladen und importieren?\n\n'
      'Dabei werden alle bestehenden Monster-Daten überschrieben.',
    );

    if (!confirmed) return;

    final viewModel = context.read<OfficialMonstersViewModel>();
    final success = await viewModel.importMonsters();
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Monster erfolgreich importiert'),
          backgroundColor: Colors.green,
        ),
      );
    }
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
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: DnDTheme.mysticalPurple),
            child: const Text('Bestätigen'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
