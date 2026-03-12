// lib/screens/session/encounter_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/campaign.dart';
import '../../models/scene.dart';
import '../../models/player_character.dart';
import '../../models/creature.dart';
import '../../models/sound.dart';
import '../../viewmodels/encounter_planning_viewmodel.dart';
import '../../database/repositories/sound_model_repository.dart';
import '../../services/sound_service.dart';

/// Encounter Setup Screen
/// 
/// Screen zum Planen und Zusammenstellen von Kämpfen mit Helden und Monstern.
/// Wird von einer Scene aus aufgerufen und erstellt einen Encounter mit Teilnehmern.
class EncounterSetupScreen extends StatefulWidget {
  final Campaign campaign;
  final Scene scene;
  
  const EncounterSetupScreen({
    super.key, 
    required this.campaign,
    required this.scene,
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
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    _initViewModel();
    _loadSounds();
  }

  void _initViewModel() {
    // ViewModel initialisieren
    _viewModel = EncounterPlanningViewModel(
      campaignId: widget.campaign.id,
      sceneId: widget.scene.id,
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
    // Prüfen ob Titel ausgefüllt ist
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte gib einen Titel für den Kampf ein.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Titel setzen
    _viewModel.setEncounterTitle(_titleController.text.trim());
    _viewModel.setEncounterDescription(_descriptionController.text.trim());

    // Encounter erstellen
    final encounter = await _viewModel.createEncounter();
    
    if (encounter != null && mounted) {
      // Erfolgreich erstellt - zurück zur Scene
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kampf erfolgreich erstellt!'),
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.of(context).pop(encounter);
    } else if (_viewModel.errorMessage != null && mounted) {
      // Fehler anzeigen
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

  void _removeCharacter(String characterId) {
    _viewModel.removeCharacter(characterId);
  }

  void _addMonster(Creature monster) {
    _viewModel.toggleMonsterSelection(monster.id);
  }

  void _removeMonster(String monsterId) {
    _viewModel.removeMonster(monsterId);
  }

  Future<void> _loadSounds() async {
    try {
      final soundRepo = context.read<SoundModelRepository>();
      final allSounds = await soundRepo.findAll();
      
      // Filtere Sounds, die mit der Scene verknüpft sind
      final linkedSounds = allSounds.where((sound) => 
        widget.scene.linkedSoundIds.contains(sound.id)
      ).toList();
      
      setState(() {
        _linkedSounds = linkedSounds;
      });
    } catch (e) {
      print('Fehler beim Laden der Sounds: $e');
    }
  }

  void _togglePlayPause(String soundId, String filePath) async {
    if (_currentPlayingSoundId == soundId && _isPlaying) {
      // Pause
      await SoundService.pauseSound();
      setState(() {
        _isPlaying = false;
      });
    } else {
      // Play
      if (_currentPlayingSoundId != soundId) {
        // Anderer Sound: zuerst stoppen
        await SoundService.stopSound();
      }
      final success = await SoundService.playSound(filePath);
      if (success) {
        setState(() {
          _currentPlayingSoundId = soundId;
          _isPlaying = true;
          _volume = 1.0;
        });
        await SoundService.setVolume(_volume);
      }
    }
  }

  Future<void> _stopSound() async {
    await SoundService.stopSound();
    setState(() {
      _isPlaying = false;
      _currentPlayingSoundId = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kampf planen'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              showDialog(
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
  }

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

  Widget _buildSoundsPanel() {
    return Container(
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
          Row(
            children: [
              const Icon(Icons.music_note, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              const Text(
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
                      ? Colors.green.withOpacity(0.3)
                      : Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isCurrentPlaying 
                        ? Colors.green 
                        : Colors.grey[600]!,
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
                          min: 0.0,
                          max: 1.0,
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
  }

  Widget _buildEncounterInfo() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
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
  }

  Widget _buildAvailableList() {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
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
  }

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
      itemBuilder: (context, index) {
        final character = characters[index];
        return _buildCharacterCard(character);
      },
    );
  }

  Widget _buildCharacterCard(PlayerCharacter character) {
    return Draggable<PlayerCharacter>(
      data: character,
      feedback: Material(
        color: Colors.transparent,
        child: _buildCharacterTile(character, isDragging: true),
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
  }

  Widget _buildCharacterTile(PlayerCharacter character, {bool isDragging = false}) {
    return Card(
      color: Colors.blue[800],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
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
            if (!isDragging)
              Icon(Icons.add_circle_outline, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildMonsterList() {
    final monsters = _viewModel.availableMonsters
        .where((m) => !_viewModel.isMonsterSelected(m.id))
        .toList();

    if (monsters.isEmpty) {
      return const Center(
        child: Text(
          'Keine Gegner verfügbar',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      itemCount: monsters.length,
      itemBuilder: (context, index) {
        final monster = monsters[index];
        return _buildMonsterCard(monster);
      },
    );
  }

  Widget _buildMonsterCard(Creature monster) {
    return Draggable<Creature>(
      data: monster,
      feedback: Material(
        color: Colors.transparent,
        child: _buildMonsterTile(monster, isDragging: true),
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
  }

  Widget _buildMonsterTile(Creature monster, {bool isDragging = false}) {
    return Card(
      color: Colors.red[900],
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            const Icon(Icons.shield, color: Colors.white),
            const SizedBox(width: 12),
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
                    '${monster.type} CR ${monster.challengeRating}',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            if (!isDragging)
              Icon(Icons.add_circle_outline, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedList() {
    final selectedCharacters = _viewModel.selectedCharacters;
    final selectedMonsters = _viewModel.selectedMonsters;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(16.0),
          child: Text(
            'Im Kampf',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),
        Expanded(
          child: DragTarget<Object>(
            onAccept: (data) {
              if (data is PlayerCharacter) {
                _addCharacter(data);
              } else if (data is Creature) {
                _addMonster(data);
              }
            },
            builder: (context, candidateData, rejectedData) => Container(
              decoration: BoxDecoration(
                color: candidateData.isNotEmpty
                    ? Colors.orange.withOpacity(0.2)
                    : Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: selectedCharacters.isEmpty && selectedMonsters.isEmpty
                  ? const Center(
                      child: Text(
                        'Hier Teilnehmer reinziehen oder anklicken',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView(
                      children: [
                        ...selectedCharacters.map((c) => _buildSelectedCharacterTile(c)),
                        ...selectedMonsters.map((m) => _buildSelectedMonsterTile(m)),
                      ],
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSelectedCharacterTile(PlayerCharacter character) {
    return ListTile(
      leading: const Icon(Icons.account_circle, color: Colors.blue),
      title: Text(character.name),
      subtitle: Text('${character.className} Lvl ${character.level}'),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
        onPressed: () => _removeCharacter(character.id),
        tooltip: 'Entfernen',
      ),
    );
  }

  Widget _buildSelectedMonsterTile(Creature monster) {
    return ListTile(
      leading: const Icon(Icons.shield, color: Colors.red),
      title: Text(monster.name),
      subtitle: Text('${monster.type} CR ${monster.challengeRating}'),
      trailing: IconButton(
        icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
        onPressed: () => _removeMonster(monster.id),
        tooltip: 'Entfernen',
      ),
    );
  }

  Widget _buildBottomBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_viewModel.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
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
}