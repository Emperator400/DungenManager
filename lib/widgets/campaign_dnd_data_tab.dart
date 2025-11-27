// lib/widgets/campaign_dnd_data_tab.dart
import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/campaign.dart';
import '../models/official_monster.dart';
import '../models/official_spell.dart';
import '../models/creature.dart';
import '../screens/enhanced_official_monsters_screen.dart';

class CampaignDndDataTab extends StatefulWidget {
  final Campaign campaign;
  const CampaignDndDataTab({super.key, required this.campaign});

  @override
  State<CampaignDndDataTab> createState() => _CampaignDndDataTabState();
}

class _CampaignDndDataTabState extends State<CampaignDndDataTab> {
  final dbHelper = DatabaseHelper.instance;
  List<OfficialMonster> _availableMonsters = [];
  List<OfficialSpell> _availableSpells = [];
  List<Creature> _campaignCreatures = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Lade verfügbare offizielle Monster
      final monsters = await dbHelper.getAllOfficialMonsters();
      _availableMonsters = monsters.map((m) => OfficialMonster.fromMap(m as Map<String, dynamic>)).toList();
      
      // Lade verfügbare offizielle Zauber
      final spells = await dbHelper.getAllOfficialSpells();
      _availableSpells = spells.map((s) => OfficialSpell.fromMap(s as Map<String, dynamic>)).toList();
      
      // Lade Kreaturen der Kampagne (temporär alle Kreaturen)
      final creatures = await dbHelper.getAllCreatures();
      _campaignCreatures = creatures.map((c) => Creature.fromMap(c as Map<String, dynamic>)).toList();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Daten: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addOfficialMonsterToCampaign(OfficialMonster monster) async {
    try {
      // Erstelle eine Creature aus dem offiziellen Monster
      final creature = Creature(
        id: '', // Wird von der Datenbank generiert
        name: monster.name,
        maxHp: monster.hitPoints,
        currentHp: monster.hitPoints,
        armorClass: int.tryParse(monster.armorClass) ?? 10,
        speed: monster.speed,
        strength: monster.strength,
        dexterity: monster.dexterity,
        constitution: monster.constitution,
        intelligence: monster.intelligence,
        wisdom: monster.wisdom,
        charisma: monster.charisma,
        size: monster.size,
        type: monster.type,
        subtype: monster.subtype,
        alignment: monster.alignment,
        challengeRating: monster.challengeRating.round(),
        specialAbilities: monster.specialAbilities.map((a) => '${a.name}: ${a.description}').join('\n'),
        legendaryActions: monster.legendaryActions?.map((a) => '${a.name}: ${a.description}').join('\n'),
        description: monster.description,
        attacks: monster.actions.map((a) => '${a.name}: ${a.description}').join('\n'),
        officialMonsterId: monster.id,
        sourceType: 'official',
        isCustom: false,
      );

      // Speichere die Kreatur
      await dbHelper.insertCreature(creature);
      
      // Aktualisiere die Kampagne mit der neuen Monster-ID
      final updatedMonsters = List<String>.from(widget.campaign.availableMonsters);
      if (!updatedMonsters.contains(monster.id)) {
        updatedMonsters.add(monster.id);
        
        final updatedCampaign = widget.campaign.copyWith(
          settings: widget.campaign.settings.copyWith(
            availableMonsters: updatedMonsters,
          ),
          updatedAt: DateTime.now(),
        );
        
        await dbHelper.updateCampaign(updatedCampaign);
      }
      
      // Lade die Daten neu
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${monster.name} wurde zur Kampagne hinzugefügt')),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Hinzufügen: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
            TabBar(
            isScrollable: true,
            tabs: [
              Tab(icon: const Icon(Icons.pets), text: "Monster"),
              Tab(icon: const Icon(Icons.auto_fix_high), text: "Zauber"),
              Tab(icon: const Icon(Icons.inventory_2), text: "Gegenstände"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildMonsterTab(),
                _buildSpellTab(),
                _buildItemTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonsterTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton.icon(
            onPressed: () async {
              final selectedMonster = await Navigator.of(context).push<OfficialMonster?>(
                MaterialPageRoute(
                  builder: (ctx) => const EnhancedOfficialMonstersScreen(),
                ),
              );
              
              if (selectedMonster != null && mounted) {
                await _addOfficialMonsterToCampaign(selectedMonster);
              }
            },
            icon: const Icon(Icons.add),
            label: const Text("Monster aus Bibliothek hinzufügen"),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _availableMonsters.length,
            itemBuilder: (context, index) {
              final monster = _availableMonsters[index];
              final isInCampaign = widget.campaign.availableMonsters.contains(monster.id);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.macro_off),
                  title: Text(monster.name),
                  subtitle: Text('${monster.type} ${monster.subtype ?? ''} • CR ${monster.challengeRating}'),
                  trailing: isInCampaign
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => _addOfficialMonsterToCampaign(monster),
                        ),
                  onTap: () => _showMonsterDetails(monster),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSpellTab() {
    return const Center(
      child: Text('Zauber-Integration kommt bald...'),
    );
  }

  Widget _buildItemTab() {
    return const Center(
      child: Text('Gegenstands-Integration kommt bald...'),
    );
  }

  void _showMonsterDetails(OfficialMonster monster) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(monster.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Größe: ${monster.size}'),
              Text('Typ: ${monster.type} ${monster.subtype ?? ''}'),
              Text('Gesinnung: ${monster.alignment}'),
              Text('RK: ${monster.armorClass}'),
              Text('TP: ${monster.hitPoints} (${monster.hitDice})'),
              Text('Bewegung: ${monster.speed}'),
              const SizedBox(height: 8),
              const Text('Attribute:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('ST: ${monster.strength} • GE: ${monster.dexterity} • KO: ${monster.constitution}'),
              Text('IN: ${monster.intelligence} • WE: ${monster.wisdom} • CH: ${monster.charisma}'),
              const SizedBox(height: 8),
              if (monster.specialAbilities.isNotEmpty) ...[
                const Text('Besondere Fähigkeiten:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...monster.specialAbilities.map((ability) => 
                  Text('• ${ability.name}: ${ability.description}')
                ),
              ],
              if (monster.actions.isNotEmpty) ...[
                const Text('Aktionen:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...monster.actions.map((action) => 
                  Text('• ${action.name}: ${action.description}')
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Schließen'),
          ),
          if (!widget.campaign.availableMonsters.contains(monster.id))
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _addOfficialMonsterToCampaign(monster);
              },
              child: const Text('Zur Kampagne hinzufügen'),
            ),
        ],
      ),
    );
  }
}
