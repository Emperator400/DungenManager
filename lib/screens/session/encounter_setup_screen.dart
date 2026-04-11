// lib/screens/session/encounter_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/campaign.dart';
import '../../models/scene.dart';
import '../../models/player_character.dart';
import '../../models/creature.dart';
import '../../models/sound.dart';
import '../../models/attack.dart';
import '../../viewmodels/encounter_planning_viewmodel.dart';
import '../../database/repositories/sound_model_repository.dart';
import '../../database/core/database_connection.dart';
import '../../services/sound_service.dart';
import '../../theme/dnd_theme.dart';
import 'encounter_tracker_screen.dart' as encounter_tracker;
import '../bestiary/bestiary_screen.dart';

/// Encounter Setup Screen
///
/// Screen zum Planen und Zusammenstellen von Kämpfen mit Helden und Monstern.
/// Wird von einer Scene aus aufgerufen und erstellt einen Encounter mit Teilnehmern.
class EncounterSetupScreen extends StatefulWidget {
  final Campaign campaign;
  final Scene scene;
  final String? encounterTitle;
  final List<String> preselectedCharacterIds;
  final List<String> preselectedMonsterIds;
  final String? preselectedDescription;

  const EncounterSetupScreen({
    super.key,
    required this.campaign,
    required this.scene,
    this.encounterTitle,
    this.preselectedCharacterIds = const [],
    this.preselectedMonsterIds = const [],
    this.preselectedDescription,
  });

  @override
  State<EncounterSetupScreen> createState() => _EncounterSetupScreenState();
}

class _EncounterSetupScreenState extends State<EncounterSetupScreen> {
  late final EncounterPlanningViewModel _viewModel;
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  List<Sound> _linkedSounds = [];
  String? _currentPlayingSoundId;
  bool _isPlaying = false;
  double _volume = 1;

  @override
  void initState() {
    super.initState();

    if (widget.encounterTitle != null && widget.encounterTitle!.isNotEmpty) {
      _titleController.text = widget.encounterTitle!;
    }

    _initViewModel();
    _loadSounds();
  }

  void _initViewModel() {
    if (widget.preselectedDescription != null &&
        widget.preselectedDescription!.isNotEmpty) {
      _descriptionController.text = widget.preselectedDescription!;
    }

    _viewModel = EncounterPlanningViewModel(
      campaignId: widget.campaign.id,
      sceneId: widget.scene.id,
      preselectedCharacterIds: widget.preselectedCharacterIds,
      preselectedMonsterIds: widget.preselectedMonsterIds,
      preselectedDescription: widget.preselectedDescription,
    );

    _viewModel.loadData();
    _viewModel.addListener(_onViewModelChanged);
  }

  void _onViewModelChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _viewModel.removeListener(_onViewModelChanged);
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _startEncounter() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib einen Titel für den Kampf ein.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    _viewModel.setEncounterTitle(_titleController.text.trim());
    _viewModel.setEncounterDescription(_descriptionController.text.trim());

    final encounter = await _viewModel.createEncounter();

    if (encounter != null && mounted) {
      await _stopSound();

      // Hole Initiative-Werte vom ViewModel
      final initiativeValues = _viewModel.getInitiativeMapForTracker();

      Navigator.of(context).pushReplacement<void, void>(
        MaterialPageRoute<void>(
          builder: (context) => encounter_tracker.EncounterTrackerScreen(
            encounterId: encounter.id,
            encounterTitle: encounter.title,
            initialInitiativeValues: initiativeValues,
          ),
        ),
      );
    } else if (_viewModel.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_viewModel.errorMessage!),
          duration: const Duration(seconds: 3),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _addCharacter(PlayerCharacter character) {
    _viewModel.toggleCharacterSelection(character.id);
  }

  void _addMonster(Creature monster) {
    _viewModel.addMonster(monster.id);
  }

  Future<void> _loadSounds() async {
    try {
      // Repository direkt erstellen statt context.read<>() in initState zu verwenden
      final soundRepo = SoundModelRepository(DatabaseConnection.instance);
      final allSounds = await soundRepo.findAll();

      final linkedSounds =
          allSounds.where((sound) => widget.scene.linkedSoundIds.contains(sound.id)).toList();

      if (mounted) {
        setState(() {
          _linkedSounds = linkedSounds;
        });
      }
    } catch (e) {
      debugPrint('Fehler beim Laden der Sounds: $e');
    }
  }

  void _togglePlayPause(String soundId, String filePath) async {
    if (_currentPlayingSoundId == soundId && _isPlaying) {
      await SoundService.pauseSound();
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    } else {
      if (_currentPlayingSoundId != soundId) {
        await SoundService.stopSound();
      }
      final success = await SoundService.playSound(filePath);
      if (success && mounted) {
        setState(() {
          _currentPlayingSoundId = soundId;
          _isPlaying = true;
          _volume = 1;
        });
        await SoundService.setVolume(_volume);
      }
    }
  }

  Future<void> _stopSound() async {
    await SoundService.stopSound();
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _currentPlayingSoundId = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Kampf planen'),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Kampf planen'),
                    content: const Text(
                      'Wähle Helden und Monster für den Kampf aus. '
                      'Du kannst sie durch Drag & Drop oder Klick hinzufügen.\n\n'
                      'Gib dem Kampf einen Titel und starte ihn dann.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _buildBottomBar(),
      );

  Widget _buildBody() {
    if (_viewModel.isLoading && _viewModel.availableCharacters.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_viewModel.errorMessage != null && _viewModel.availableCharacters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_viewModel.errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _viewModel.loadData(),
              child: const Text('Erneut laden'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildEncounterInfo(),
        if (_linkedSounds.isNotEmpty) _buildSoundsPanel(),
        Expanded(
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: _buildAvailableList(),
              ),
              const VerticalDivider(width: 16),
              Expanded(
                flex: 3,
                child: _buildSelectedList(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSoundsPanel() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[850],
          border: Border(
            bottom: BorderSide(color: Colors.grey[700]!, width: 1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.music_note, color: Colors.green, size: 20),
                SizedBox(width: 8),
                Text(
                  'Verknüpfte Sounds',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _linkedSounds.map((sound) {
                final isCurrentPlaying = _currentPlayingSoundId == sound.id;
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCurrentPlaying
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.grey[800],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCurrentPlaying ? Colors.green : Colors.grey[600]!,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(
                          _currentPlayingSoundId == sound.id && _isPlaying
                              ? Icons.pause
                              : Icons.play_arrow,
                          color: Colors.white,
                          size: 16,
                        ),
                        onPressed: () => _togglePlayPause(sound.id, sound.filePath),
                        tooltip: isCurrentPlaying && _isPlaying ? 'Pausieren' : 'Abspielen',
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          sound.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isCurrentPlaying) ...[
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 80,
                          child: Slider(
                            value: _volume,
                            onChanged: (value) async {
                              setState(() {
                                _volume = value;
                              });
                              await SoundService.setVolume(_volume);
                            },
                            min: 0,
                            max: 1,
                            divisions: 10,
                            activeColor: Colors.green,
                            inactiveColor: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.stop, color: Colors.red, size: 16),
                          onPressed: _stopSound,
                          tooltip: 'Stoppen',
                        ),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );

  Widget _buildEncounterInfo() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Kampf-Titel',
                border: OutlineInputBorder(),
                hintText: 'z.B. Der grüne Drache',
              ),
              onChanged: (value) => _viewModel.setEncounterTitle(value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Beschreibung (optional)',
                border: OutlineInputBorder(),
                hintText: 'z.B. Ein wilder Drache greift die Helden an...',
              ),
              maxLines: 2,
              onChanged: (value) => _viewModel.setEncounterDescription(value),
            ),
          ],
        ),
      );

  Widget _buildAvailableList() => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Verfügbar',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(),
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Helden'),
                      Tab(text: 'Gegner'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildCharacterList(),
                        _buildMonsterList(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );

  Widget _buildCharacterList() {
    final characters = _viewModel.availableCharacters
        .where((c) => !_viewModel.isCharacterSelected(c.id))
        .toList();

    if (characters.isEmpty) {
      return const Center(
        child: Text(
          'Keine Helden verfügbar',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: characters.length,
      itemBuilder: (context, index) => _buildCharacterCard(characters[index]),
    );
  }

  Widget _buildCharacterCard(PlayerCharacter character) =>
      Draggable<PlayerCharacter>(
        data: character,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 300,
            child: _buildCharacterTile(character, isDragging: true),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildCharacterTile(character),
        ),
        child: GestureDetector(
          onTap: () => _addCharacter(character),
          child: _buildCharacterTile(character),
        ),
      );

  Widget _buildCharacterTile(PlayerCharacter character, {bool isDragging = false}) =>
      Card(
        color: Colors.blue[800],
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.account_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      character.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${character.className} Lvl ${character.level}',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              if (!isDragging) const Icon(Icons.add_circle_outline, color: Colors.white),
            ],
          ),
        ),
      );

  Widget _buildMonsterList() {
    // Monster nicht mehr ausblenden, damit sie mehrfach geklickt werden können
    final monsters = _viewModel.availableMonsters.toList();

    if (monsters.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.pets_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'Keine Gegner verfügbar',
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            const SizedBox(height: 8),
            const Text(
              'Importiere oder erstelle Monster im Bestiarium',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (ctx) => const BestiaryScreen(),
                  ),
                );
                // Nach Rückkehr aus dem Bestiarium: Daten neu laden
                _viewModel.loadData();
              },
              icon: const Icon(Icons.auto_stories),
              label: const Text('Bestiarium öffnen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: monsters.length,
      itemBuilder: (context, index) => _buildMonsterCard(monsters[index]),
    );
  }

  Widget _buildMonsterCard(Creature monster) => Draggable<Creature>(
        data: monster,
        feedback: Material(
          color: Colors.transparent,
          child: SizedBox(
            width: 300,
            child: _buildMonsterTile(monster, isDragging: true),
          ),
        ),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _buildMonsterTile(monster),
        ),
        child: GestureDetector(
          onTap: () => _addMonster(monster),
          child: _buildMonsterTile(monster),
        ),
      );

  Widget _buildMonsterTile(Creature monster, {bool isDragging = false}) {
    final crText = monster.challengeRating?.toString() ?? '?';
    final typeText = monster.type ?? 'Unbekannt';
    
    // Zeigt an, wie oft das Monster bereits hinzugefügt wurde
    final count = _viewModel.getMonsterCount(monster.id);

    return Card(
      color: Colors.red[900],
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shield, color: Colors.white),
                if (count > 0 && !isDragging)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        count.toString(),
                        style: TextStyle(
                          color: Colors.red[900],
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    monster.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$typeText CR $crText',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (!isDragging) const Icon(Icons.add_circle_outline, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedList() {
    final selectedCharacters = _viewModel.selectedCharacters;
    final selectedMonsters = _viewModel.selectedMonsters;
    final sortedParticipants = _viewModel.getSortedParticipantsByInitiative();

    return Column(
      children: [
        // Header mit Initiative-Buttons
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Text(
                'Im Kampf',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              // Alle würfeln Button
              if (_viewModel.totalParticipants > 0) ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.casino, size: 18),
                  label: const Text('Alle würfeln'),
                  onPressed: () {
                    _viewModel.rollInitiativeForAll();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DnDTheme.ancientGold,
                    foregroundColor: DnDTheme.dungeonBlack,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                // Zurücksetzen Button
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.grey),
                  onPressed: () {
                    _viewModel.clearAllInitiatives();
                  },
                  tooltip: 'Initiative zurücksetzen',
                ),
              ],
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: DragTarget<Object>(
            onAcceptWithDetails: (details) {
              final data = details.data;
              if (data is PlayerCharacter) {
                _addCharacter(data);
              } else if (data is Creature) {
                _addMonster(data);
              }
            },
            builder: (context, candidateData, rejectedData) => Container(
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty
                    ? Colors.orange.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: selectedCharacters.isEmpty && selectedMonsters.isEmpty
                  ? const Center(
                      child: Text(
                        'Hier Teilnehmer reinziehen oder anklicken',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: sortedParticipants.length,
                      itemBuilder: (context, index) {
                        final participant = sortedParticipants[index];
                        final isCharacter = participant['type'] == 'character';
                        
                        if (isCharacter) {
                          final character = selectedCharacters.firstWhere(
                            (c) => c.id == participant['id'],
                            orElse: () => selectedCharacters.first,
                          );
                          return _buildSelectedCharacterTileWithInitiative(
                            character, 
                            index + 1,
                            participant['initiative'] as int,
                            participant['initiativeSet'] as bool,
                          );
                        } else {
                          final monster = selectedMonsters.firstWhere(
                            (m) => m.id == participant['id'],
                            orElse: () => selectedMonsters.first,
                          );
                          return _buildSelectedMonsterTileWithInitiative(
                            monster,
                            index + 1,
                            participant['initiative'] as int,
                            participant['initiativeSet'] as bool,
                          );
                        }
                      },
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedCharacterTileWithInitiative(
    PlayerCharacter character, 
    int position,
    int initiative,
    bool initiativeSet,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue[800]?.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue[700] ?? Colors.blue,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Erste Zeile: Position, Name, Initiative, Entfernen
            Row(
              children: [
                // Position
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#$position',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Icon
                const Icon(Icons.account_circle, color: Colors.blue, size: 32),
                const SizedBox(width: 8),
                // Name und Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        character.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${character.className} Lvl ${character.level}',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Initiative-Eingabe
                _buildInitiativeInput(
                  character.id,
                  initiative,
                  initiativeSet,
                  isCharacter: true,
                ),
                const SizedBox(width: 8),
                // Entfernen Button
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _viewModel.removeCharacterWithInitiative(character.id),
                  tooltip: 'Entfernen',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            // Zweite Zeile: Stats (HP, AC, Attribute)
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildStatChip('HP', '${character.maxHp}', Colors.green),
                _buildStatChip('AC', '${character.armorClass}', Colors.orange),
                _buildAbilityChip('STR', character.strength),
                _buildAbilityChip('DEX', character.dexterity),
                _buildAbilityChip('CON', character.constitution),
                _buildAbilityChip('INT', character.intelligence),
                _buildAbilityChip('WIS', character.wisdom),
                _buildAbilityChip('CHA', character.charisma),
              ],
            ),
            // Dritte Zeile: Angriffe (falls vorhanden)
            if (character.attackList.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: character.attackList.take(4).map((attack) => 
                  _buildAttackChip(attack.name, attack.totalDamage)
                ).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedMonsterTileWithInitiative(
    Creature monster,
    int position,
    int initiative,
    bool initiativeSet,
  ) {
    final crText = monster.challengeRating?.toString() ?? '?';
    final typeText = monster.type ?? 'Unbekannt';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.red[900]?.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.red[700] ?? Colors.red,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            // Erste Zeile: Position, Name, Initiative, Entfernen
            Row(
              children: [
                // Position
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.grey[700],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '#$position',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Icon
                const Icon(Icons.shield, color: Colors.red, size: 32),
                const SizedBox(width: 8),
                // Name und Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        monster.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '$typeText CR $crText',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                // Initiative-Eingabe
                _buildInitiativeInput(
                  monster.id,
                  initiative,
                  initiativeSet,
                  isCharacter: false,
                ),
                const SizedBox(width: 8),
                // Entfernen Button
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                  onPressed: () => _viewModel.removeMonsterWithInitiative(monster.id),
                  tooltip: 'Entfernen',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            // Zweite Zeile: Stats (HP, AC, Attribute)
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildStatChip('HP', '${monster.maxHp}', Colors.green),
                _buildStatChip('AC', '${monster.armorClass}', Colors.orange),
                _buildAbilityChip('STR', monster.strength),
                _buildAbilityChip('DEX', monster.dexterity),
                _buildAbilityChip('CON', monster.constitution),
                _buildAbilityChip('INT', monster.intelligence),
                _buildAbilityChip('WIS', monster.wisdom),
                _buildAbilityChip('CHA', monster.charisma),
              ],
            ),
            // Dritte Zeile: Angriffe (falls vorhanden)
            if (monster.attackList.isNotEmpty) ...[
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: monster.attackList.take(4).map((attack) => 
                  _buildAttackChip(attack.name, attack.totalDamage)
                ).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Helper für Stat-Chips (HP, AC)
  Widget _buildStatChip(String label, String value, Color color) {
    // Nicht-const Variablen um const-Evaluation zu verhindern
    final padding = EdgeInsets.symmetric(horizontal: 6, vertical: 2);
    final bgColor = color.withValues(alpha: 0.2);
    final borderColor = color.withValues(alpha: 0.5);
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Helper für Ability-Score-Chips mit Modifier
  Widget _buildAbilityChip(String label, int score) {
    final modifier = ((score - 10) ~/ 2);
    final modText = modifier >= 0 ? '+$modifier' : '$modifier';
    // Nicht-const Variablen um const-Evaluation zu verhindern
    final padding = EdgeInsets.symmetric(horizontal: 4, vertical: 2);
    final bgColor = Colors.grey[800] ?? Color(0xFF424242);
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '$label $score ($modText)',
        style: TextStyle(
          color: Colors.white70,
          fontSize: 9,
        ),
      ),
    );
  }

  /// Helper für Attack-Chips
  Widget _buildAttackChip(String name, String damage) {
    // Nicht-const Variablen um const-Evaluation zu verhindern
    final padding = EdgeInsets.symmetric(horizontal: 6, vertical: 2);
    final bgColor = Colors.purple[900]?.withValues(alpha: 0.3) ?? Color(0x4D4A148C);
    final borderColor = Colors.purple[700] ?? Color(0xFF7B1FA2);
    final textColor = Colors.purple[200] ?? Color(0xFFCE93D8);
    
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        damage.isNotEmpty ? '$name ($damage)' : name,
        style: TextStyle(
          color: textColor,
          fontSize: 9,
        ),
      ),
    );
  }

  /// Erstellt die InputDecoration für das Initiative-Feld
  /// Als separate Methode um const-Evaluation zu vermeiden
  InputDecoration _createInitInputDecoration(Color fillColor) {
    // Verwende nicht-const Variablen um const-Evaluation zu verhindern
    final hintColor = Colors.grey[600] ?? Color(0xFF9E9E9E);
    final borderColor = Colors.grey[600] ?? Color(0xFF757575);
    // Nicht-const EdgeInsets um const-Evaluation zu verhindern
    final contentPadding = EdgeInsets.symmetric(horizontal: 4, vertical: 8);
    // Nicht-const Farbe um const-Evaluation zu verhindern
    final goldColor = Color(0xFFD4AF37);
    
    return InputDecoration(
      hintText: 'Init',
      hintStyle: TextStyle(color: hintColor, fontSize: 10),
      contentPadding: contentPadding,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: BorderSide(color: goldColor, width: 2), // Gold
      ),
      filled: true,
      fillColor: fillColor,
    );
  }

  Widget _buildInitiativeInput(
    String id,
    int initiative,
    bool initiativeSet, {
    required bool isCharacter,
  }) {
    final controller = TextEditingController(
      text: initiativeSet ? initiative.toString() : '',
    );
    
    // Dynamische Farbe basierend auf initiativeSet
    final textColor = initiativeSet ? DnDTheme.ancientGold : Colors.grey;
    // Nicht-const Farbe für fillColor (verwendet nicht-const Fallback)
    final fillColor = Colors.grey[850] ?? Color(0xFF424242);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Initiative-Eingabefeld
        SizedBox(
          width: 50,
          height: 36,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            decoration: _createInitInputDecoration(fillColor),
            onSubmitted: (value) {
              final intValue = int.tryParse(value);
              if (intValue != null) {
                if (isCharacter) {
                  _viewModel.setCharacterInitiative(id, intValue);
                } else {
                  _viewModel.setMonsterInitiative(id, intValue);
                }
              }
            },
          ),
        ),
        const SizedBox(width: 4),
        // Würfel-Button
        InkWell(
          onTap: () {
            if (isCharacter) {
              _viewModel.rollInitiativeForCharacter(id);
            } else {
              _viewModel.rollInitiativeForMonster(id);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DnDTheme.ancientGold.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: DnDTheme.ancientGold.withValues(alpha: 0.5)),
            ),
            child: Icon(
              Icons.casino,
              color: DnDTheme.ancientGold,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar() => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_viewModel.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _viewModel.errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ElevatedButton.icon(
              icon: _viewModel.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.play_arrow),
              label: Text(
                'Kampf starten (${_viewModel.totalParticipants} Teilnehmer)',
              ),
              onPressed: _viewModel.isLoading ? null : _startEncounter,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      );
}