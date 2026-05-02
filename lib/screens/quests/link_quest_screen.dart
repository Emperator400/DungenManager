// lib/screens/link_quest_to_scene_screen.dart
import 'package:flutter/material.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/quest_model_repository.dart';
import '../../models/quest.dart';
import '../../theme/app_theme.dart';

class LinkQuestToSceneScreen extends StatefulWidget {
  final List<String> previouslyLinkedIds;
  const LinkQuestToSceneScreen({super.key, required this.previouslyLinkedIds});

  @override
  State<LinkQuestToSceneScreen> createState() => _LinkQuestToSceneScreenState();
}

class _LinkQuestToSceneScreenState extends State<LinkQuestToSceneScreen> {
  late QuestModelRepository _questRepository;
  late Set<String> _selectedIds;

  @override
  void initState() {
    super.initState();
    _questRepository = QuestModelRepository(DatabaseConnection.instance);
    _selectedIds = widget.previouslyLinkedIds.toSet();
  }

  void _handleSave() {
    Navigator.of(context).pop(_selectedIds.toList());
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: _buildQuestList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.accent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
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
                  'Quest verknüpfen',
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
                  'Wähle Quests aus, die mit dieser Szene verknüpft werden sollen',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: C.amber,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.black87, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${_selectedIds.length}',
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

  Widget _buildQuestList() {
    final C = context.appColors;
    return FutureBuilder<List<Quest>>(
      future: _questRepository.findAll(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(C.amber),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: C.red),
                const SizedBox(height: 16),
                Text(
                  'Fehler beim Laden',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: C.red,
                  ),
                ),
              ],
            ),
          );
        }

        final quests = snapshot.data ?? [];

        if (quests.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.assignment_outlined, size: 64, color: C.textSoft),
                const SizedBox(height: 16),
                Text(
                  'Keine Quests vorhanden',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: C.textMid,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Erstelle zuerst Quests in der Quest-Bibliothek',
                  style: TextStyle(fontSize: 14, color: C.textSoft),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.list_alt, color: C.amber),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${quests.length} Quests verfügbar',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (_selectedIds.isNotEmpty)
                    TextButton.icon(
                      onPressed: _handleSave,
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Fertig'),
                      style: TextButton.styleFrom(foregroundColor: C.amber),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: quests.length,
                itemBuilder: (context, index) {
                  final quest = quests[index];
                  final questIdString = quest.id.toString();
                  final isSelected = _selectedIds.contains(questIdString);
                  return _buildQuestCard(quest, isSelected);
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestCard(Quest quest, bool isSelected) {
    final C = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: () {
          final questIdString = quest.id.toString();
          setState(() {
            if (isSelected) {
              _selectedIds.remove(questIdString);
            } else {
              _selectedIds.add(questIdString);
            }
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? C.accent.withValues(alpha: 0.25)
                : C.bgPanel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? C.accent : C.amber.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: C.amber.withValues(alpha: 0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? C.accent
                      : C.accent.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      quest.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? C.accent : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (quest.description.length > 50)
                      Text(
                        '${quest.description.substring(0, 50)}...',
                        style: TextStyle(
                          fontSize: 13,
                          color: isSelected
                              ? C.accent.withValues(alpha: 0.8)
                              : C.textSoft,
                        ),
                      ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildQuestTypeChip(quest.questType),
                        const SizedBox(width: 8),
                        _buildDifficultyChip(quest.difficulty),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestTypeChip(QuestType type) {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: C.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: C.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        _getQuestTypeDisplayName(type),
        style: TextStyle(
          color: C.accent,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDifficultyChip(QuestDifficulty difficulty) {
    final color = _getDifficultyColor(difficulty);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        _getDifficultyDisplayName(difficulty),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _getQuestTypeDisplayName(QuestType type) {
    return switch (type) {
      QuestType.main => 'Hauptquest',
      QuestType.side => 'Nebenquest',
      QuestType.personal => 'Persönlich',
      QuestType.faction => 'Fraktions-Quest',
    };
  }

  String _getDifficultyDisplayName(QuestDifficulty difficulty) {
    return switch (difficulty) {
      QuestDifficulty.easy => 'Leicht',
      QuestDifficulty.medium => 'Mittel',
      QuestDifficulty.hard => 'Schwer',
      QuestDifficulty.deadly => 'Tödlich',
      QuestDifficulty.epic => 'Episch',
      QuestDifficulty.legendary => 'Legendär',
    };
  }

  Color _getDifficultyColor(QuestDifficulty difficulty) {
    final C = context.appColors;
    return switch (difficulty) {
      QuestDifficulty.easy => C.green,
      QuestDifficulty.medium => C.accent,
      QuestDifficulty.hard => C.amber,
      QuestDifficulty.deadly => C.red,
      QuestDifficulty.epic => C.accent,
      QuestDifficulty.legendary => C.amber,
    };
  }
}
