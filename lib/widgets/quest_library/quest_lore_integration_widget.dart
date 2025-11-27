import 'package:flutter/material.dart';
import '../../models/quest.dart';
import '../../models/wiki_entry.dart';
import '../../services/quest_lore_integration_service.dart';
import '../../theme/dnd_theme.dart';

/// Widget für die Anzeige und Verwaltung von Quest-Wiki-Integration
class QuestLoreIntegrationWidget extends StatefulWidget {
  final Quest quest;
  final void Function(Quest)? onQuestUpdated;
  final void Function(WikiEntry)? onWikiEntrySelected;
  final bool enableAutoFeatures;

  const QuestLoreIntegrationWidget({
    super.key,
    required this.quest,
    this.enableAutoFeatures = false,
    this.onQuestUpdated,
    this.onWikiEntrySelected,
  });

  @override
  State<QuestLoreIntegrationWidget> createState() => _QuestLoreIntegrationWidgetState();
}

class _QuestLoreIntegrationWidgetState extends State<QuestLoreIntegrationWidget> {
  final QuestLoreIntegrationService _loreService = QuestLoreIntegrationService();
  List<WikiEntry> _linkedWikiEntries = [];
  List<WikiEntry> _suggestedEntries = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadWikiEntries();
  }

  @override
  void didUpdateWidget(QuestLoreIntegrationWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.quest.id != widget.quest.id) {
      _loadWikiEntries();
    }
  }

  Future<void> _loadWikiEntries() async {
    setState(() => _isLoading = true);
    
    try {
      final linkedEntries = await _loreService.getWikiEntriesForQuest(widget.quest.id.toString());
      List<WikiEntry> suggestedEntries = [];
      
      // Nur vorgeschlagene Einträge laden, wenn Auto-Features aktiviert sind
      if (widget.enableAutoFeatures) {
        suggestedEntries = await _loreService.findRelevantWikiEntries(widget.quest);
      }
      
      setState(() {
        _linkedWikiEntries = linkedEntries;
        _suggestedEntries = suggestedEntries.where((entry) => 
            !_linkedWikiEntries.any((linked) => linked.id == entry.id)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Laden der Wiki-Einträge: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _linkWikiEntry(WikiEntry entry) async {
    try {
      final updatedQuest = await _loreService.linkWikiEntryToQuest(
        widget.quest.id.toString(), 
        entry.id
      );
      
      setState(() {
        _linkedWikiEntries.add(entry);
        _suggestedEntries.removeWhere((e) => e.id == entry.id);
      });
      
      widget.onQuestUpdated?.call(updatedQuest);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${entry.title}" mit Quest verknüpft'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Verknüpfen: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _unlinkWikiEntry(WikiEntry entry) async {
    try {
      final updatedQuest = await _loreService.unlinkWikiEntryFromQuest(
        widget.quest.id.toString(), 
        entry.id
      );
      
      setState(() {
        _linkedWikiEntries.removeWhere((e) => e.id == entry.id);
        _suggestedEntries.insert(0, entry);
      });
      
      widget.onQuestUpdated?.call(updatedQuest);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Verknüpfung zu "${entry.title}" entfernt'),
            backgroundColor: DnDTheme.ancientGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Entfernen der Verknüpfung: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _suggestWikiLinks() async {
    try {
      final updatedQuest = await _loreService.suggestWikiLinks(widget.quest);
      await _loadWikiEntries(); // Neu laden
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wiki-Verknüpfungen wurden vorgeschlagen'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
      
      widget.onQuestUpdated?.call(updatedQuest);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Vorschlagen von Verknüpfungen: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _createWikiEntries() async {
    try {
      final createdEntries = await _loreService.createWikiEntriesFromQuest(widget.quest);
      await _loadWikiEntries(); // Neu laden
      
      if (mounted) {
        final count = createdEntries.length;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$count Wiki-Einträge aus Quest erstellt'),
            backgroundColor: DnDTheme.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Fehler beim Erstellen der Wiki-Einträge: $e'),
            backgroundColor: DnDTheme.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(DnDTheme.mysticalPurple),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header mit Aktionen
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.link,
                      color: DnDTheme.mysticalPurple,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Wiki-Integration',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: DnDTheme.mysticalPurple,
                      ),
                    ),
                    const Spacer(),
                    // Auto-Features nur anzeigen, wenn aktiviert
                    if (widget.enableAutoFeatures && _suggestedEntries.isNotEmpty) ...[
                      TextButton.icon(
                        onPressed: _suggestWikiLinks,
                        icon: const Icon(Icons.auto_awesome, size: 16),
                        label: const Text('Auto-Verknüpfen'),
                        style: TextButton.styleFrom(
                          foregroundColor: DnDTheme.ancientGold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (widget.enableAutoFeatures) ...[
                      TextButton.icon(
                        onPressed: _createWikiEntries,
                        icon: const Icon(Icons.add_circle_outline, size: 16),
                        label: const Text('Wiki-Einträge erstellen'),
                        style: TextButton.styleFrom(
                          foregroundColor: DnDTheme.mysticalPurple,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Verknüpfe diese Quest mit relevanten Wiki-Einträgen oder erstelle neue Einträge aus Quest-Informationen.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Verknüpfte Einträge
        if (_linkedWikiEntries.isNotEmpty) ...[
          _buildSectionHeader('Verknüpfte Wiki-Einträge (${_linkedWikiEntries.length})'),
          const SizedBox(height: 8),
          ..._linkedWikiEntries.map((entry) => _buildLinkedEntryCard(entry)),
          const SizedBox(height: 16),
        ],
        
        // Vorgeschlagene Einträge
        if (_suggestedEntries.isNotEmpty) ...[
          _buildSectionHeader('Vorgeschlagene Wiki-Einträge (${_suggestedEntries.length})'),
          const SizedBox(height: 8),
          ..._suggestedEntries.map((entry) => _buildSuggestedEntryCard(entry)),
          const SizedBox(height: 16),
        ],
        
        // Keine Einträge gefunden
        if (_linkedWikiEntries.isEmpty && _suggestedEntries.isEmpty) ...[
          _buildEmptyState(),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: DnDTheme.mysticalPurple,
        ),
      ),
    );
  }

  Widget _buildLinkedEntryCard(WikiEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEntryTypeColor(entry.entryType),
          child: Icon(
            _getEntryTypeIcon(entry.entryType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${entry.entryType.toString().split('.').last} • ${_formatDate(entry.updatedAt)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => widget.onWikiEntrySelected?.call(entry),
              icon: const Icon(Icons.visibility, size: 20),
              tooltip: 'Wiki-Eintrag ansehen',
            ),
            IconButton(
              onPressed: () => _unlinkWikiEntry(entry),
              icon: const Icon(Icons.link_off, size: 20),
              tooltip: 'Verknüpfung entfernen',
              color: Colors.orange,
            ),
          ],
        ),
        onTap: () => widget.onWikiEntrySelected?.call(entry),
      ),
    );
  }

  Widget _buildSuggestedEntryCard(WikiEntry entry) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.grey[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getEntryTypeColor(entry.entryType),
          child: Icon(
            _getEntryTypeIcon(entry.entryType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          entry.title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          '${entry.entryType.toString().split('.').last} • ${_formatDate(entry.updatedAt)}',
          style: TextStyle(color: Colors.grey[600]),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => widget.onWikiEntrySelected?.call(entry),
              icon: const Icon(Icons.visibility, size: 20),
              tooltip: 'Wiki-Eintrag ansehen',
            ),
            IconButton(
              onPressed: () => _linkWikiEntry(entry),
              icon: const Icon(Icons.link, size: 20),
              tooltip: 'Mit Quest verknüpfen',
              color: DnDTheme.ancientGold,
            ),
          ],
        ),
        onTap: () => widget.onWikiEntrySelected?.call(entry),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.link_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Wiki-Einträge gefunden',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Erstelle Wiki-Einträge aus Quest-Informationen oder verknüpfe manuell vorhandene Einträge.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.enableAutoFeatures) ...[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _createWikiEntries,
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Wiki-Einträge aus Quest erstellen'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DnDTheme.mysticalPurple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getEntryTypeColor(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return Colors.blue;
      case WikiEntryType.Place:
        return Colors.green;
      case WikiEntryType.Faction:
        return Colors.purple;
      case WikiEntryType.Item:
        return Colors.orange;
      case WikiEntryType.Lore:
        return DnDTheme.mysticalPurple;
      default:
        return Colors.grey;
    }
  }

  IconData _getEntryTypeIcon(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return Icons.person;
      case WikiEntryType.Place:
        return Icons.place;
      case WikiEntryType.Faction:
        return Icons.group;
      case WikiEntryType.Item:
        return Icons.inventory_2;
      case WikiEntryType.Lore:
        return Icons.book;
      default:
        return Icons.category;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} Tage';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} Stunden';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} Minuten';
    } else {
      return 'Gerade eben';
    }
  }
}
