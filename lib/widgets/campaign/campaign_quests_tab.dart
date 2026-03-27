import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../database/core/database_connection.dart';
import '../../database/repositories/quest_model_repository.dart';
import '../../models/campaign.dart';
import '../../models/quest.dart';
import '../../models/campaign_quest.dart';
import '../../screens/quests/add_quest_screen.dart';
import '../../screens/quests/edit_campaign_quest_screen.dart';
import '../../screens/quests/edit_quest_screen.dart';
import '../../viewmodels/edit_quest_viewmodel.dart';
import '../../theme/dnd_theme.dart';

class CampaignQuestsTab extends StatefulWidget {
  final Campaign campaign;
  const CampaignQuestsTab({super.key, required this.campaign});

  @override
  State<CampaignQuestsTab> createState() => CampaignQuestsTabState();
}

class CampaignQuestsTabState extends State<CampaignQuestsTab> {
  late final QuestModelRepository _questRepository;
  late Future<List<CampaignQuest>> _campaignQuestsFuture;

  @override
  void initState() {
    super.initState();
    _questRepository = QuestModelRepository(DatabaseConnection.instance);
    _loadQuests();
  }

  void _loadQuests() {
    setState(() {
      _campaignQuestsFuture = _loadQuestsData();
    });
  }

  Future<List<CampaignQuest>> _loadQuestsData() async {
    try {
      print('📋 [CampaignQuestsTab] Lade Quests für Kampagne: ${widget.campaign.id}');
      
      // Lade alle Quests aus der Datenbank
      final allQuests = await _questRepository.findAll();
      print('📋 [CampaignQuestsTab] ${allQuests.length} Quests insgesamt gefunden');
      
      // Filtere Quests, die zur Kampagne gehören
      final campaignQuests = allQuests.where((q) => q.campaignId == widget.campaign.id).toList();
      print('📋 [CampaignQuestsTab] ${campaignQuests.length} Quests für diese Kampagne gefunden');
      
      // Konvertiere zu CampaignQuest Objekten
      return campaignQuests.map((q) => CampaignQuest(
        quest: q,
        campaignId: widget.campaign.id,
        status: q.status,  // Status aus dem Quest übernehmen
      )).toList();
    } catch (e) {
      print('❌ Fehler beim Laden der CampaignQuests: $e');
      return <CampaignQuest>[];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      body: FutureBuilder<List<CampaignQuest>>(
        future: _campaignQuestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(DnDTheme.ancientGold),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 64,
                    color: DnDTheme.arcaneBlue.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "Dieser Kampagne wurden noch keine Quests hinzugefügt.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }
          
          final allQuests = snapshot.data!;

          // Logik zum Gruppieren der Quests nach Status
          final groupedQuests = <QuestStatus, List<CampaignQuest>>{};
          for (final quest in allQuests) {
            (groupedQuests[quest.status] ??= []).add(quest);
          }

          // Sortierte Liste der Status, damit 'active' immer oben ist
          final sortedStatuses = groupedQuests.keys.toList()
            ..sort((a, b) {
              if (a == QuestStatus.active) return -1;
              if (b == QuestStatus.active) return 1;
              if (a == QuestStatus.onHold) return -1;
              if (b == QuestStatus.onHold) return 1;
              return a.index.compareTo(b.index);
            });

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: sortedStatuses.length,
            itemBuilder: (context, index) {
              final status = sortedStatuses[index];
              final questsInGroup = groupedQuests[status]!;
              return _buildQuestGroup(status, questsInGroup);
            },
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 16, right: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton.extended(
              heroTag: 'create_quest',
              icon: const Icon(Icons.add),
              label: const Text("Neue Quest erstellen"),
              backgroundColor: DnDTheme.ancientGold,
              foregroundColor: Colors.black87,
              onPressed: () => _createNewQuest(),
            ),
            const SizedBox(width: 12),
            FloatingActionButton.extended(
              heroTag: 'add_from_library',
              icon: const Icon(Icons.library_add),
              label: const Text("Aus Bibliothek"),
              backgroundColor: DnDTheme.arcaneBlue,
              foregroundColor: Colors.white,
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (ctx) => AddQuestFromLibraryScreen(campaignId: widget.campaign.id),
                )).then((_) => _loadQuests());
              },
            ),
          ],
        ),
      ),
    );
  }

  void _createNewQuest() async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider<EditQuestViewModel>(
          create: (_) => EditQuestViewModel(),
          child: Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                context.read<EditQuestViewModel>().initialize(null, campaignId: widget.campaign.id);
              });
              return const EditQuestScreen();
            },
          ),
        ),
      ),
    );
    
    // Quests neu laden nach der Erstellung
    _loadQuests();
  }

  // Helfer-Widget, um eine Gruppe von Quests anzuzeigen
  Widget _buildQuestGroup(QuestStatus status, List<CampaignQuest> quests) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            DnDTheme.stoneGrey.withOpacity(0.9),
            DnDTheme.dungeonBlack.withOpacity(0.95),
          ],
        ),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.6),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor(status).withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: _getStatusColor(status).withOpacity(0.2),
          splashColor: _getStatusColor(status).withOpacity(0.1),
        ),
        child: ExpansionTile(
          iconColor: _getStatusColor(status),
          collapsedIconColor: _getStatusColor(status),
          title: Text(
            "${_getGermanStatusName(status)} (${quests.length})",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.white,
              shadows: [
                Shadow(
                  color: _getStatusColor(status).withOpacity(0.5),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
          subtitle: Text(
            _getStatusDescription(status),
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          initiallyExpanded: status == QuestStatus.active || status == QuestStatus.onHold,
          children: quests.asMap().entries.map((entry) {
            final index = entry.key;
            final cq = entry.value;
            return Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: _getStatusColor(status).withOpacity(0.2),
                    width: 1,
                  ),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(status).withOpacity(0.3),
                        _getStatusColor(status).withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStatusColor(status).withOpacity(0.5),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  cq.quest.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  cq.quest.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 13,
                  ),
                ),
                trailing: Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: _getStatusColor(status),
                ),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (ctx) => EditCampaignQuestScreen(campaignId: widget.campaign.id, campaignQuest: cq),
                  )).then((_) => _loadQuests());
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Color _getStatusColor(QuestStatus status) {
    switch (status) {
      case QuestStatus.active:
        return DnDTheme.arcaneBlue;
      case QuestStatus.onHold:
        return DnDTheme.ancientGold;
      case QuestStatus.completed:
        return DnDTheme.successGreen;
      case QuestStatus.failed:
        return DnDTheme.errorRed;
      case QuestStatus.abandoned:
        return DnDTheme.stoneGrey;
    }
  }

  String _getStatusDescription(QuestStatus status) {
    switch (status) {
      case QuestStatus.onHold: return "Diese Quests sind vorübergehend pausiert";
      case QuestStatus.active: return "Aktive Quests in dieser Kampagne";
      case QuestStatus.completed: return "Erfolgreich abgeschlossene Quests";
      case QuestStatus.failed: return "Quests, die fehlgeschlagen sind";
      case QuestStatus.abandoned: return "Quests, die aufgegeben wurden";
    }
  }

  String _getGermanStatusName(QuestStatus status) {
    switch (status) {
      case QuestStatus.onHold: return "Pausierte Quests";
      case QuestStatus.active: return "Aktive Quests";
      case QuestStatus.completed: return "Abgeschlossene Quests";
      case QuestStatus.failed: return "Gescheiterte Quests";
      case QuestStatus.abandoned: return "Aufgegebene Quests";
    }
  }
}