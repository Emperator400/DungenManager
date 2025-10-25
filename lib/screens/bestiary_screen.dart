// lib/screens/bestiary_screen.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/creature.dart';
import '../game_data/dnd_data_importer.dart';
import 'edit_creature_screen.dart';
import 'unified_character_editor_screen.dart';

class BestiaryScreen extends StatefulWidget {
  const BestiaryScreen({super.key});

  @override
  State<BestiaryScreen> createState() => _BestiaryScreenState();
}

class _BestiaryScreenState extends State<BestiaryScreen> 
    with SingleTickerProviderStateMixin {
  final dbHelper = DatabaseHelper.instance;
  final dataImporter = DndDataImporter();
  late TabController _tabController;
  late Future<List<Creature>> _customCreaturesFuture;
  late Future<List<Creature>> _officialCreaturesFuture;
  late Future<List<Creature>> _allCreaturesFuture;
  
  // D&D-Daten Variablen
  List<Map<String, dynamic>> _availableMonsters = [];
  List<Map<String, dynamic>> _availableSpells = [];
  bool _isLoadingDndData = true;
  
  // Filter und Suchvariablen
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedSourceType = 'all';
  String _selectedType = 'all';
  String _selectedSize = 'all';
  bool _showFavoritesOnly = false;
  bool _sortByChallengeRating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCreatures();
    _loadDndData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadCreatures() {
    setState(() {
      _customCreaturesFuture = dbHelper.getCreaturesBySourceType('custom');
      _officialCreaturesFuture = dbHelper.getCreaturesBySourceType('official');
      _allCreaturesFuture = dbHelper.getAllCreatures();
    });
  }

  Future<void> _refreshCreatureList() async {
    _loadCreatures();
  }

  Future<void> _loadDndData() async {
    setState(() => _isLoadingDndData = true);
    
    try {
      // Lade verfügbare offizielle Monster
      final monsters = await dbHelper.getAllOfficialMonsters();
      _availableMonsters = monsters;
      
      // Lade verfügbare offizielle Zauber
      final spells = await dbHelper.getAllOfficialSpells();
      _availableSpells = spells;
      
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden der D&D-Daten: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDndData = false);
      }
    }
  }

  List<Creature> _filterCreatures(List<Creature> creatures) {
    return creatures.where((creature) {
      // Suchfilter
      if (_searchQuery.isNotEmpty) {
        final searchLower = _searchQuery.toLowerCase();
        final matchesName = creature.name.toLowerCase().contains(searchLower);
        final matchesType = creature.type?.toLowerCase().contains(searchLower) ?? false;
        final matchesSubtype = creature.subtype?.toLowerCase().contains(searchLower) ?? false;
        if (!matchesName && !matchesType && !matchesSubtype) return false;
      }

      // Source Type Filter
      if (_selectedSourceType != 'all' && creature.sourceType != _selectedSourceType) {
        return false;
      }

      // Type Filter
      if (_selectedType != 'all' && creature.type != _selectedType) {
        return false;
      }

      // Size Filter
      if (_selectedSize != 'all' && creature.size != _selectedSize) {
        return false;
      }

      // Favorites Filter
      if (_showFavoritesOnly && !creature.isFavorite) {
        return false;
      }

      return true;
    }).toList();
  }

  List<Creature> _sortCreatures(List<Creature> creatures) {
    final sorted = List<Creature>.from(creatures);
    
    if (_sortByChallengeRating) {
      sorted.sort((a, b) {
        final aCr = a.challengeRating ?? 0;
        final bCr = b.challengeRating ?? 0;
        return aCr.compareTo(bCr);
      });
    } else {
      sorted.sort((a, b) => a.name.compareTo(b.name));
    }
    
    return sorted;
  }

  void _showMigrationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Unified Bestiarum Migration"),
          content: const Text(
            "Möchtest du die Migration auf das neue Unified Bestiarum durchführen? "
            "Dabei werden bestehende Kreaturen auf das neue Schema migriert und "
            "offizielle Monster mit der Datenbank synchronisiert."
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Migration wird durchgeführt..."),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                try {
                  await dataImporter.migrateCreaturesToUnifiedSchema();
                  await dataImporter.syncOfficialMonstersToCreatures();
                  _refreshCreatureList();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Migration erfolgreich abgeschlossen!"),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text("Fehler bei der Migration: $e"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
              child: const Text("Migration starten"),
            ),
          ],
        );
      },
    );
  }

  void _resetBestiary() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Bestiarum zurücksetzen?"),
          content: const Text(
            "Bist du sicher, dass du alle Kreaturen im Bestiarum löschen möchtest? "
            "Diese Aktion kann nicht rückgängig gemacht werden."
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Abbrechen"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await dbHelper.deleteAllCreatures();
                _refreshCreatureList();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Bestiarum wurde erfolgreich zurückgesetzt"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Löschen"),
            ),
          ],
        );
      },
    );
  }

  bool _isImporting = false;

  Future<void> _import5eToolsMonsters() async {
    if (_isImporting) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Monster von 5e.tools importieren"),
        content: const Text(
          "Möchtest du wirklich alle Monster-Daten von 5e.tools herunterladen und importieren?\n\n"
          "Dabei werden alle bestehenden offiziellen Monster-Daten überschrieben.\n\n"
          "Dieser Vorgang kann einige Minuten dauern."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.blue),
            child: const Text("Importieren"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isImporting = true);

    try {
      final count = await dataImporter.importMonsters();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("$count Monster erfolgreich von 5e.tools importiert"),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshCreatureList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fehler beim Import: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isImporting = false);
      }
    }
  }

  Future<void> _importAllMonsters() async {
    if (_availableMonsters.isEmpty) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Keine Monster zum Importieren verfügbar. Bitte zuerst Monster von 5e.tools importieren.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Alle Monster importieren"),
        content: Text(
          "Möchtest du wirklich alle ${_availableMonsters.length} verfügbaren Monster in dein Bestiarum importieren?\n\n"
          "Bereits vorhandene Monster werden übersprungen."
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Abbrechen"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text("Alle importieren"),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    // Lade bestehende Kreaturen
    final existingCreatures = await dbHelper.getAllCreatures();
    final existingMonsterIds = existingCreatures
        .where((c) => c.officialMonsterId != null)
        .map((c) => c.officialMonsterId!)
        .toSet();

    int importedCount = 0;
    int skippedCount = 0;

    try {
      for (final monster in _availableMonsters) {
        final monsterId = monster['id']?.toString();
        
        // Überspringen, wenn bereits vorhanden
        if (monsterId != null && existingMonsterIds.contains(monsterId)) {
          skippedCount++;
          continue;
        }

        final creature = Creature(
          id: null,
          name: monster['name']?.toString() ?? 'Unbekannt',
          maxHp: int.tryParse(monster['hit_points']?.toString() ?? '0') ?? 0,
          currentHp: int.tryParse(monster['hit_points']?.toString() ?? '0') ?? 0,
          armorClass: int.tryParse(monster['armor_class']?.toString() ?? '10') ?? 10,
          speed: monster['speed']?.toString() ?? '',
          strength: int.tryParse(monster['strength']?.toString() ?? '10') ?? 10,
          dexterity: int.tryParse(monster['dexterity']?.toString() ?? '10') ?? 10,
          constitution: int.tryParse(monster['constitution']?.toString() ?? '10') ?? 10,
          intelligence: int.tryParse(monster['intelligence']?.toString() ?? '10') ?? 10,
          wisdom: int.tryParse(monster['wisdom']?.toString() ?? '10') ?? 10,
          charisma: int.tryParse(monster['charisma']?.toString() ?? '10') ?? 10,
          size: monster['size']?.toString(),
          type: monster['type']?.toString(),
          subtype: monster['subtype']?.toString(),
          alignment: monster['alignment']?.toString(),
          challengeRating: (monster['challenge_rating'] as num?)?.toDouble()?.round(),
          sourceType: 'official',
          officialMonsterId: monsterId,
          description: monster['description']?.toString(),
        );

        await dbHelper.insertCreature(creature);
        importedCount++;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$importedCount Monster erfolgreich importiert, $skippedCount übersprungen (bereits vorhanden)',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        await _refreshCreatureList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Fehler beim Import: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildCreatureCard(Creature creature) {
    final isOfficial = creature.sourceType == 'official';
    final isCustom = creature.sourceType == 'custom';
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: _getSourceColor(creature.sourceType),
          child: Icon(
            isOfficial ? Icons.public : (isCustom ? Icons.person : Icons.sync),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          creature.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("HP: ${creature.currentHp}/${creature.maxHp} | AC: ${creature.armorClass}"),
            if (creature.type != null)
              Text("Typ: ${creature.type}${creature.subtype != null ? ' (${creature.subtype})' : ''}"),
            if (creature.challengeRating != null)
              Text("CR: ${creature.challengeRating} | Größe: ${creature.size ?? 'Medium'}"),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                creature.isFavorite ? Icons.star : Icons.star_border,
                color: creature.isFavorite ? Colors.amber : null,
              ),
              onPressed: () async {
                final updatedCreature = creature.copyWith(isFavorite: !creature.isFavorite);
                await dbHelper.updateCreature(updatedCreature);
                _refreshCreatureList();
              },
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => UnifiedCharacterEditorScreen(
                    characterType: creature.type == 'Humanoid' ? CharacterType.npc : CharacterType.monster,
                    creatureToEdit: creature,
                  ),
                ));
                _refreshCreatureList();
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () async {
                await dbHelper.deleteCreature(creature.id);
                _refreshCreatureList();
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getSourceColor(String sourceType) {
    switch (sourceType) {
      case 'official':
        return Colors.blue;
      case 'custom':
        return Colors.green;
      case 'hybrid':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Widget _buildFilterPanel() {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Suchfeld
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Suchen',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 16),
            
            // Filter Optionen
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSourceType,
                    decoration: const InputDecoration(
                      labelText: 'Quelle',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Alle Quellen')),
                      DropdownMenuItem(value: 'custom', child: Text('Benutzerdefiniert')),
                      DropdownMenuItem(value: 'official', child: Text('Offiziell')),
                      DropdownMenuItem(value: 'hybrid', child: Text('Hybrid')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSourceType = value ?? 'all';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(
                      labelText: 'Typ',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Alle Typen')),
                      DropdownMenuItem(value: 'Humanoid', child: Text('Humanoid')),
                      DropdownMenuItem(value: 'humanoid (goblinoid)', child: Text('Humanoid (Goblinoid)')),
                      DropdownMenuItem(value: 'humanoid (orc)', child: Text('Humanoid (Ork)')),
                      DropdownMenuItem(value: 'Beast', child: Text('Tier')),
                      DropdownMenuItem(value: 'Dragon', child: Text('Drache')),
                      DropdownMenuItem(value: 'Undead', child: Text('Untot')),
                      DropdownMenuItem(value: 'Fiend', child: Text('Teufel')),
                      DropdownMenuItem(value: 'Celestial', child: Text('Himmelswesen')),
                      DropdownMenuItem(value: 'Elemental', child: Text('Elementar')),
                      DropdownMenuItem(value: 'Fey', child: Text('Feenwesen')),
                      DropdownMenuItem(value: 'Giant', child: Text('Riese')),
                      DropdownMenuItem(value: 'Monstrosity', child: Text('Monstrosität')),
                      DropdownMenuItem(value: 'Ooze', child: Text('Schleim')),
                      DropdownMenuItem(value: 'Plant', child: Text('Pflanze')),
                      DropdownMenuItem(value: 'Construct', child: Text('Konstrukt')),
                      DropdownMenuItem(value: 'Aberration', child: Text('Aberration')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedType = value ?? 'all';
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _selectedSize,
                    decoration: const InputDecoration(
                      labelText: 'Größe',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text('Alle Größen')),
                      DropdownMenuItem(value: 'Tiny', child: Text('Winzig')),
                      DropdownMenuItem(value: 'Small', child: Text('Klein')),
                      DropdownMenuItem(value: 'Medium', child: Text('Mittel')),
                      DropdownMenuItem(value: 'Large', child: Text('Groß')),
                      DropdownMenuItem(value: 'Huge', child: Text('Riesig')),
                      DropdownMenuItem(value: 'Gargantuan', child: Text('Gigantisch')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedSize = value ?? 'all';
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CheckboxListTile(
                    title: const Text('Nur Favoriten'),
                    value: _showFavoritesOnly,
                    onChanged: (value) {
                      setState(() {
                        _showFavoritesOnly = value ?? false;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // Sortierung
            CheckboxListTile(
              title: const Text('Nach Challenge Rating sortieren'),
              value: _sortByChallengeRating,
              onChanged: (value) {
                setState(() {
                  _sortByChallengeRating = value ?? false;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatureList(List<Creature> creatures) {
    final filteredCreatures = _filterCreatures(creatures);
    final sortedCreatures = _sortCreatures(filteredCreatures);
    
    if (sortedCreatures.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            "Keine Kreaturen gefunden, die den Filterkriterien entsprechen.",
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: _refreshCreatureList,
      child: ListView.builder(
        padding: const EdgeInsets.only(bottom: 80),
        itemCount: sortedCreatures.length,
        itemBuilder: (context, index) {
          return _buildCreatureCard(sortedCreatures[index]);
        },
      ),
    );
  }

  Widget _buildDndDataTab() {
    if (_isLoadingDndData) {
      return const Center(child: CircularProgressIndicator());
    }

    return _buildDndMonsterTab();
  }

  Widget _buildDndMonsterTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _import5eToolsMonsters,
                  icon: const Icon(Icons.download),
                  label: const Text("Monster von 5e.tools importieren"),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _importAllMonsters,
                  icon: const Icon(Icons.library_add),
                  label: const Text("Alle importieren"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: FutureBuilder<List<Creature>>(
            future: dbHelper.getAllCreatures(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text("Fehler: ${snapshot.error}"));
              }

              final existingCreatures = snapshot.data ?? [];
              final existingMonsterIds = existingCreatures
                  .where((c) => c.officialMonsterId != null)
                  .map((c) => c.officialMonsterId!)
                  .toSet();

              return ListView.builder(
                itemCount: _availableMonsters.length,
                itemBuilder: (context, index) {
                  final monster = _availableMonsters[index];
                  final monsterId = monster['id']?.toString();
                  final isAlreadyImported = monsterId != null && existingMonsterIds.contains(monsterId);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    color: isAlreadyImported ? Colors.grey.withValues(alpha: 0.1) : null,
                    child: ListTile(
                      leading: Icon(
                        Icons.pets,
                        color: isAlreadyImported ? Colors.grey : null,
                      ),
                      title: Text(
                        monster['name']?.toString() ?? 'Unbekannt',
                        style: TextStyle(
                          color: isAlreadyImported ? Colors.grey : null,
                          fontStyle: isAlreadyImported ? FontStyle.italic : null,
                        ),
                      ),
                      subtitle: Text(
                        '${monster['type']?.toString() ?? 'Unbekannt'} • '
                        'SG ${monster['challenge_rating']?.toString() ?? '0'} • '
                        'TP ${monster['hit_points']?.toString() ?? '0'}',
                        style: TextStyle(
                          color: isAlreadyImported ? Colors.grey.shade600 : null,
                        ),
                      ),
                      trailing: isAlreadyImported
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _addMonsterToBestiary(monster),
                            ),
                      onTap: () => _showMonsterDetails(monster),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDndSpellTab() {
    return const Center(
      child: Text('Zauber-Integration kommt bald...'),
    );
  }

  Widget _buildDndItemTab() {
    return const Center(
      child: Text('Gegenstands-Integration kommt bald...'),
    );
  }

  Future<void> _addMonsterToBestiary(Map<String, dynamic> monsterData) async {
    try {
      // Prüfen, ob das Monster bereits im Bestiarum vorhanden ist
      final monsterId = monsterData['id']?.toString();
      final existingCreatures = await dbHelper.getAllCreatures();
      final alreadyExists = existingCreatures.any((creature) => 
        creature.officialMonsterId == monsterId || 
        (creature.sourceType == 'official' && creature.name == monsterData['name']?.toString())
      );

      if (alreadyExists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dieses Monster ist bereits im Bestiarum vorhanden'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      final creature = Creature(
        id: null,
        name: monsterData['name']?.toString() ?? 'Unbekannt',
        maxHp: int.tryParse(monsterData['hit_points']?.toString() ?? '0') ?? 0,
        currentHp: int.tryParse(monsterData['hit_points']?.toString() ?? '0') ?? 0,
        armorClass: int.tryParse(monsterData['armor_class']?.toString() ?? '10') ?? 10,
        speed: monsterData['speed']?.toString() ?? '',
        strength: int.tryParse(monsterData['strength']?.toString() ?? '10') ?? 10,
        dexterity: int.tryParse(monsterData['dexterity']?.toString() ?? '10') ?? 10,
        constitution: int.tryParse(monsterData['constitution']?.toString() ?? '10') ?? 10,
        intelligence: int.tryParse(monsterData['intelligence']?.toString() ?? '10') ?? 10,
        wisdom: int.tryParse(monsterData['wisdom']?.toString() ?? '10') ?? 10,
        charisma: int.tryParse(monsterData['charisma']?.toString() ?? '10') ?? 10,
        size: monsterData['size']?.toString(),
        type: monsterData['type']?.toString(),
        subtype: monsterData['subtype']?.toString(),
        alignment: monsterData['alignment']?.toString(),
        challengeRating: (monsterData['challenge_rating'] as num?)?.toDouble()?.round(),
        sourceType: 'official',
        officialMonsterId: monsterData['id']?.toString(),
        description: monsterData['description']?.toString(),
      );

      await dbHelper.insertCreature(creature);
      
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${creature.name} wurde zum Bestiarum hinzugefügt')),
        );
        await _refreshCreatureList();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Hinzufügen: $e')),
        );
      }
    }
  }

  void _showMonsterDetails(Map<String, dynamic> monsterData) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(monsterData['name']?.toString() ?? 'Unbekannt'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Größe: ${monsterData['size']?.toString() ?? 'Unbekannt'}'),
              Text('Typ: ${monsterData['type']?.toString() ?? 'Unbekannt'}'),
              Text('Gesinnung: ${monsterData['alignment']?.toString() ?? 'Unbekannt'}'),
              Text('RK: ${monsterData['armor_class']?.toString() ?? 'Unbekannt'}'),
              Text('TP: ${monsterData['hit_points']?.toString() ?? 'Unbekannt'}'),
              Text('Bewegung: ${monsterData['speed']?.toString() ?? 'Unbekannt'}'),
              const SizedBox(height: 8),
              const Text('Attribute:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('ST: ${monsterData['strength']?.toString() ?? '10'} • GE: ${monsterData['dexterity']?.toString() ?? '10'} • KO: ${monsterData['constitution']?.toString() ?? '10'}'),
              Text('IN: ${monsterData['intelligence']?.toString() ?? '10'} • WE: ${monsterData['wisdom']?.toString() ?? '10'} • CH: ${monsterData['charisma']?.toString() ?? '10'}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Schließen'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              // Kleine Verzögerung, um sicherzustellen, dass der Dialog geschlossen ist
              Future.delayed(const Duration(milliseconds: 100), () {
                if (mounted) {
                  _addMonsterToBestiary(monsterData);
                }
              });
            },
            child: const Text('Zum Bestiarum hinzufügen'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Unified Bestiarum"),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: "Alle", icon: Icon(Icons.list)),
              Tab(text: "Benutzerdefiniert", icon: Icon(Icons.person)),
              Tab(text: "Offiziell", icon: Icon(Icons.public)),
              Tab(text: "Importer", icon: Icon(Icons.download)),
            ],
          ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: "Unified Bestiarum Migration",
            onPressed: _showMigrationDialog,
          ),
          IconButton(
            icon: _isImporting 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.download),
            tooltip: "Monster von 5e.tools importieren",
            onPressed: _import5eToolsMonsters,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Bestiarum zurücksetzen",
            onPressed: _resetBestiary,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Alle Tab
          _buildTabWithFab(
            child: Column(
              children: [
                _buildFilterPanel(),
                Expanded(
                  child: FutureBuilder<List<Creature>>(
                    future: _allCreaturesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Fehler: ${snapshot.error}"));
                      } else {
                        final creatures = snapshot.data ?? [];
                        return _buildCreatureList(creatures);
                      }
                    },
                  ),
                ),
              ],
            ),
            fabBuilder: () => FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                if (!mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const UnifiedCharacterEditorScreen(
                    characterType: CharacterType.monster,
                  ),
                ));
                if (mounted) _refreshCreatureList();
              },
            ),
          ),
          
          // Benutzerdefiniert Tab
          _buildTabWithFab(
            child: Column(
              children: [
                _buildFilterPanel(),
                Expanded(
                  child: FutureBuilder<List<Creature>>(
                    future: _customCreaturesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Fehler: ${snapshot.error}"));
                      } else {
                        final creatures = snapshot.data ?? [];
                        return _buildCreatureList(creatures);
                      }
                    },
                  ),
                ),
              ],
            ),
            fabBuilder: () => FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                if (!mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const UnifiedCharacterEditorScreen(
                    characterType: CharacterType.monster,
                  ),
                ));
                if (mounted) _refreshCreatureList();
              },
            ),
          ),
          
          // Offiziell Tab
          _buildTabWithFab(
            child: Column(
              children: [
                _buildFilterPanel(),
                Expanded(
                  child: FutureBuilder<List<Creature>>(
                    future: _officialCreaturesFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return Center(child: Text("Fehler: ${snapshot.error}"));
                      } else {
                        final creatures = snapshot.data ?? [];
                        return _buildCreatureList(creatures);
                      }
                    },
                  ),
                ),
              ],
            ),
            fabBuilder: () => FloatingActionButton(
              child: const Icon(Icons.add),
              onPressed: () async {
                if (!mounted) return;
                await Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => const UnifiedCharacterEditorScreen(
                    characterType: CharacterType.monster,
                  ),
                ));
                if (mounted) _refreshCreatureList();
              },
            ),
          ),
          
          // Importer Tab (ohne Filter und ohne FAB)
          _buildDndDataTab(),
        ],
      ),
    );
  }

  Widget _buildTabWithFab({required Widget child, required Widget Function() fabBuilder}) {
    return Stack(
      children: [
        child,
        Positioned(
          right: 16,
          bottom: 16,
          child: fabBuilder(),
        ),
      ],
    );
  }
}
