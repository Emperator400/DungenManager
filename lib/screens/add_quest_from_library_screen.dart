// lib/screens/add_quest_from_library_screen.dart
import 'package:flutter/material.dart';
import '../database/core/database_connection.dart';
import '../database/repositories/quest_model_repository.dart';
import '../models/quest.dart';
import '../widgets/quest_library/enhanced_quest_card_widget.dart';
import '../screens/enhanced_quest_library_screen.dart';
import '../theme/dnd_theme.dart';

class AddQuestFromLibraryScreen extends StatefulWidget {
  final String campaignId;
  const AddQuestFromLibraryScreen({super.key, required this.campaignId});

  @override
  State<AddQuestFromLibraryScreen> createState() => _AddQuestFromLibraryScreenState();
}

class _AddQuestFromLibraryScreenState extends State<AddQuestFromLibraryScreen> {
  late QuestModelRepository _questRepository;
  late Future<List<Quest>> _allQuestsFuture;
  late Future<List<Map<String, dynamic>>> _linkedQuestsFuture;
  
  final List<String> _selectedQuestIds = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _questRepository = QuestModelRepository(DatabaseConnection.instance);
    _allQuestsFuture = _questRepository.findAll();
    _linkedQuestsFuture = _questRepository.findAll().then((quests) => 
      quests.where((q) => q.campaignId == widget.campaignId)
        .map((q) => {'questId': q.id.toString()})
        .toList()
    );
    _scrollController.addListener(() {
      setState(() {
        // Fab visibility handled in _buildFloatingActionButton
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _addQuestsToCampaign() async {
    if (_selectedQuestIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bitte wähle mindestens eine Quest aus'),
          backgroundColor: DnDTheme.errorRed,
        ),
      );
      return;
    }

    for (final questId in _selectedQuestIds) {
      // Finde den Quest und aktualisiere seine campaignId
      final quests = await _questRepository.findAll();
      final quest = quests.firstWhere((q) => q.id.toString() == questId);
      final updatedQuest = quest.copyWith(campaignId: widget.campaignId);
      await _questRepository.update(updatedQuest);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _navigateToQuestLibrary() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const EnhancedQuestLibraryScreen(),
      ),
    );
    
    if (result == true) {
      // Quests wurden in der Bibliothek geändert, lade neu
      setState(() {
        _allQuestsFuture = _questRepository.findAll();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Quests zur Kampagne hinzufügen"),
        backgroundColor: DnDTheme.stoneGrey,
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          if (_selectedQuestIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: DnDTheme.ancientGold,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_selectedQuestIds.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: "Auswahl hinzufügen",
            onPressed: _addQuestsToCampaign,
          ),
        ],
      ),
      backgroundColor: DnDTheme.dungeonBlack,
      body: FutureBuilder(
        // Wir warten auf beide Abfragen
        future: Future.wait([_allQuestsFuture, _linkedQuestsFuture]),
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(DnDTheme.ancientGold),
              ),
            );
          }

          final allQuests = snapshot.data![0] as List<Quest>;
          final linkedQuests = snapshot.data![1] as List<Map<String, dynamic>>;
          final linkedQuestIds = linkedQuests.map((q) => q['questId'] as String).toSet();

          // Wir zeigen nur Quests an, die noch NICHT Teil der Kampagne sind
          final availableQuests = allQuests.where((q) => !linkedQuestIds.contains(q.id.toString())).toList();

          if (availableQuests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 64,
                    color: DnDTheme.successGreen,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Alle verfügbaren Quests wurden bereits hinzugefügt",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: DnDTheme.successGreen,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Erstelle neue Quests in der Quest-Bibliothek",
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Header mit Anzahl und Aktionen
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [DnDTheme.stoneGrey, DnDTheme.dungeonBlack],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.library_books,
                      color: DnDTheme.ancientGold,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${availableQuests.length} verfügbare Quests',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _navigateToQuestLibrary,
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Neue Quest erstellen'),
                      style: TextButton.styleFrom(
                        foregroundColor: DnDTheme.ancientGold,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Quest-Liste
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: availableQuests.length,
                  itemBuilder: (context, index) {
                    final quest = availableQuests[index];
                    final isSelected = _selectedQuestIds.contains(quest.id.toString());
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: EnhancedQuestCardWidget(
                        quest: quest,
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedQuestIds.remove(quest.id.toString());
                            } else {
                              _selectedQuestIds.add(quest.id.toString());
                            }
                          });
                        },
                        showActions: false, // Keine Bearbeiten/Löschen-Buttons
                        customTrailing: Checkbox(
                          value: isSelected,
                          onChanged: (bool? value) {
                            setState(() {
                              if (value == true) {
                                _selectedQuestIds.add(quest.id.toString());
                              } else {
                                _selectedQuestIds.remove(quest.id.toString());
                              }
                            });
                          },
                          activeColor: DnDTheme.ancientGold,
                        ),
                        isSelected: isSelected,
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildFloatingActionButton() {
    if (_selectedQuestIds.isEmpty) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      backgroundColor: DnDTheme.ancientGold,
      foregroundColor: Colors.white,
      icon: const Icon(Icons.add_task),
      label: Text('${_selectedQuestIds.length} Quest(s) hinzufügen'),
      onPressed: _addQuestsToCampaign,
    );
  }
}
