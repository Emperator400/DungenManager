// lib/screens/add_quest_from_library_screen.dart
import 'package:flutter/material.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/quest_model_repository.dart';
import '../../models/quest.dart';
import '../../widgets/quest_library/enhanced_quest_card_widget.dart';
import '../../screens/quests/quest_library_screen.dart';
import '../../theme/dnd_theme.dart';

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

    try {
      for (final questId in _selectedQuestIds) {
        // Versuche zuerst, die ID als int zu parsen
        final intId = int.tryParse(questId);
        if (intId == null) {
          print('❌ [AddQuestScreen] Ungültige Quest-ID: $questId');
          continue;
        }

        // Finde den Quest direkt über findById
        final quest = await _questRepository.findById(intId.toString());
        if (quest == null) {
          print('❌ [AddQuestScreen] Quest nicht gefunden: $questId');
          continue;
        }

        print('✅ [AddQuestScreen] Quest gefunden: ${quest.id} - ${quest.title}');
        final updatedQuest = quest.copyWith(campaignId: widget.campaignId);
        await _questRepository.update(updatedQuest);
        print('✅ [AddQuestScreen] Quest aktualisiert: ${updatedQuest.id} - campaignId: ${updatedQuest.campaignId}');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$_selectedQuestIds.length Quest(s) erfolgreich zur Kampagne hinzugefügt'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      print('❌ [AddQuestScreen] Fehler beim Hinzufügen: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  void _navigateToQuestLibrary() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const QuestLibraryScreen(),
      ),
    );
    
    if (result == true) {
      // Quests wurden in der Bibliothek geändert, lade neu
      setState(() {
        _allQuestsFuture = _questRepository.findAll();
      });
    }
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DnDTheme.mysticalPurple,
            DnDTheme.arcaneBlue,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 24),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quests zur Kampagne hinzufügen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Wähle Quests aus der Bibliothek aus',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedQuestIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: DnDTheme.ancientGold,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.black87, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${_selectedQuestIds.length}',
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      body: Container(
        decoration: BoxDecoration(
          gradient: DnDTheme.getMysticalGradient(),
        ),
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder(
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
            ),
          ],
        ),
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