import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/campaign.dart';
import '../models/session.dart';
import '../models/scene.dart';
import '../viewmodels/session_list_for_campaign_viewmodel.dart';
import '../database/repositories/scene_model_repository.dart';
import '../database/repositories/creature_model_repository.dart';
import '../database/repositories/player_character_model_repository.dart';
import '../theme/dnd_theme.dart';
import 'enhanced_edit_session_screen.dart';
import 'enhanced_active_session_screen.dart';

/// Enhanced Screen für die Session-Liste einer Kampagne mit modernem Design
class EnhancedSessionListForCampaignScreen extends StatefulWidget {
  final Campaign campaign;

  const EnhancedSessionListForCampaignScreen({
    Key? key,
    required this.campaign,
  }) : super(key: key);

  @override
  State<EnhancedSessionListForCampaignScreen> createState() => _EnhancedSessionListForCampaignScreenState();
}

class _EnhancedSessionListForCampaignScreenState extends State<EnhancedSessionListForCampaignScreen> {
  final _searchController = TextEditingController();
  SessionSortCriteria _sortCriteria = SessionSortCriteria.titleAsc;
  bool _isSearchMode = false;

  @override
  void initState() {
    super.initState();
    // ViewModel initialisieren
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionListForCampaignViewModel>().initialize(widget.campaign);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDuration(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours}h ${mins}min';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Sitzungen: ${widget.campaign.title}',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: DnDTheme.mysticalPurple,
        iconTheme: IconThemeData(color: Colors.white),
        actions: [
          Consumer<SessionListForCampaignViewModel>(
            builder: (context, viewModel, child) {
              return PopupMenuButton<SessionSortCriteria>(
                icon: Icon(Icons.sort, color: Colors.white),
                tooltip: 'Sortieren',
                onSelected: (criteria) {
                  setState(() {
                    _sortCriteria = criteria;
                  });
                  viewModel.sortSessions(criteria);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: SessionSortCriteria.titleAsc,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 16),
                        const SizedBox(width: 8),
                        Text('Titel (A-Z)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SessionSortCriteria.titleDesc,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, size: 16),
                        const SizedBox(width: 8),
                        Text('Titel (Z-A)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SessionSortCriteria.durationAsc,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_upward, size: 16),
                        const SizedBox(width: 8),
                        Text('Dauer (kurz-lang)'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: SessionSortCriteria.durationDesc,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_downward, size: 16),
                        const SizedBox(width: 8),
                        Text('Dauer (lang-kurz)'),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<SessionListForCampaignViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading && viewModel.sessions.isEmpty) {
            return Center(child: CircularProgressIndicator(color: DnDTheme.mysticalPurple));
          }

          final sessions = _isSearchMode && _searchController.text.isNotEmpty
              ? viewModel.searchSessions(_searchController.text)
              : viewModel.sessions;

          if (sessions.isEmpty) {
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
                    hintText: 'Sessions suchen...',
                    prefixIcon: Icon(Icons.search, color: DnDTheme.mysticalPurple),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
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
                  },
                ),
              ),

              // Session-Liste
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final session = sessions[index];
                    return _buildSessionCard(session, viewModel);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: Consumer<SessionListForCampaignViewModel>(
        builder: (context, viewModel, child) {
          return Hero(
            tag: 'session_list_fab',
            child: FloatingActionButton.extended(
              heroTag: 'session_list_fab',
              onPressed: viewModel.isLoading ? null : _createNewSession,
              backgroundColor: DnDTheme.mysticalPurple,
              icon: Icon(Icons.add, color: Colors.white),
              label: Text(
                'Neue Session',
                style: TextStyle(color: Colors.white),
              ),
              tooltip: 'Neue Session erstellen',
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(SessionListForCampaignViewModel viewModel) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Sessions gefunden',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Erstellen Sie Ihre erste Session für diese Kampagne',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _createNewSession,
            icon: Icon(Icons.add),
            label: Text('Erste Session erstellen'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DnDTheme.mysticalPurple,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionCard(Session session, SessionListForCampaignViewModel viewModel) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12.0),
        onTap: () => _openSession(session),
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
                      Icons.event,
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
                          session.title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height:4),
                        Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDuration(session.inGameTimeInMinutes),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert),
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          _editSession(session);
                          break;
                        case 'duplicate':
                          _duplicateSession(session);
                          break;
                        case 'delete':
                          _deleteSession(session);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 16),
                            const SizedBox(width: 8),
                            Text('Bearbeiten'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(
                          children: [
                            Icon(Icons.copy, size: 16),
                            const SizedBox(width: 8),
                            Text('Duplizieren'),
                          ],
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Text('Löschen', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (session.liveNotes.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                  child: Text(
                    session.liveNotes,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              // Scene Character Summary
              if (session.sceneIds.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSceneCharacterSummary(session),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Baut eine Zusammenfassung der Charaktere in den Scenes
  Widget _buildSceneCharacterSummary(Session session) {
    return FutureBuilder<Set<String>>(
      future: _loadAllSceneCharacters(session),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final characterIds = snapshot.data!;
        return FutureBuilder<Map<String, dynamic>>(
          future: _loadCharacterDetails(characterIds.toList()),
          builder: (context, charSnapshot) {
            if (!charSnapshot.hasData || charSnapshot.data!.isEmpty) {
              return const SizedBox.shrink();
            }

            final characters = charSnapshot.data!;
            return Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: DnDTheme.mysticalPurple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6.0),
                border: Border.all(
                  color: DnDTheme.mysticalPurple.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.people,
                        color: DnDTheme.mysticalPurple,
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Beteiligte Charaktere',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: DnDTheme.mysticalPurple,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: characters.values.map((char) {
                      final type = char['type'] as String;
                      final name = char['name'] as String;
                      
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: _getCharacterTypeColor(type).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4.0),
                          border: Border.all(
                            color: _getCharacterTypeColor(type).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _getCharacterTypeIcon(type),
                              color: _getCharacterTypeColor(type),
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Lädt alle Charakter-IDs aus allen Scenes einer Session
  Future<Set<String>> _loadAllSceneCharacters(Session session) async {
    final Set<String> characterIds = {};
    
    try {
      final sceneRepo = context.read<SceneModelRepository>();
      
      for (final sceneId in session.sceneIds) {
        try {
          final scene = await sceneRepo.findById(sceneId);
          if (scene != null) {
            characterIds.addAll(scene.linkedCharacterIds);
          }
        } catch (e) {
          print('Fehler beim Laden von Scene $sceneId: $e');
        }
      }
    } catch (e) {
      print('Fehler beim Laden der Scene-Charaktere: $e');
    }
    
    return characterIds;
  }

  /// Lädt Details zu einer Liste von Charakter-IDs
  Future<Map<String, dynamic>> _loadCharacterDetails(List<String> characterIds) async {
    final Map<String, dynamic> result = {};
    
    try {
      final creatureRepo = context.read<CreatureModelRepository>();
      final pcRepo = context.read<PlayerCharacterModelRepository>();
      
      for (final charId in characterIds) {
        // Versuche zuerst als Player Character zu laden
        try {
          final pc = await pcRepo.findById(charId);
          if (pc != null) {
            result[charId] = {
              'name': pc.name,
              'type': 'pc',
            };
            continue;
          }
        } catch (e) {
          // Nicht gefunden, versuche als Creature
        }
        
        // Versuche als Creature zu laden
        try {
          final creature = await creatureRepo.findById(charId);
          if (creature != null) {
            result[charId] = {
              'name': creature.name,
              'type': creature.sourceType == 'official' ? 'monster' : 'npc',
            };
          }
        } catch (e) {
          // Nicht gefunden, überspringen
        }
      }
    } catch (e) {
      print('Fehler beim Laden der Charakterdetails: $e');
    }
    
    return result;
  }

  /// Gibt die Farbe für den Charaktertyp zurück
  Color _getCharacterTypeColor(String type) {
    switch (type) {
      case 'pc':
        return Colors.green.shade600;
      case 'npc':
        return Colors.blue.shade600;
      case 'monster':
        return Colors.red.shade600;
      default:
        return Colors.grey;
    }
  }

  /// Gibt das Icon für den Charaktertyp zurück
  IconData _getCharacterTypeIcon(String type) {
    switch (type) {
      case 'pc':
        return Icons.person;
      case 'npc':
        return Icons.person_outline;
      case 'monster':
        return Icons.pets;
      default:
        return Icons.person;
    }
  }

  Future<void> _createNewSession() async {
    final viewModel = context.read<SessionListForCampaignViewModel>();
    final newSession = await viewModel.createSession();
    
    if (newSession != null) {
      _editSession(newSession);
    }
  }

  void _openSession(Session session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedActiveSessionScreen(
          session: session,
          campaign: widget.campaign,
        ),
      ),
    );
  }

  void _editSession(Session session) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EnhancedEditSessionScreen(session: session),
      ),
    ).then((_) {
      // Liste aktualisieren nach dem Bearbeiten
      context.read<SessionListForCampaignViewModel>().refreshSessions();
    });
  }

  Future<void> _duplicateSession(Session session) async {
    final viewModel = context.read<SessionListForCampaignViewModel>();
    final duplicated = await viewModel.duplicateSession(session);
    
    if (duplicated != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session dupliziert'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _deleteSession(Session session) async {
    final confirmed = await _showDeleteConfirmation(session);
    if (!confirmed) return;

    final viewModel = context.read<SessionListForCampaignViewModel>();
    final success = await viewModel.deleteSession(session.id);
    
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Session gelöscht'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<bool> _showDeleteConfirmation(Session session) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Session löschen'),
          content: Text('Möchten Sie die Session "${session.title}" wirklich löschen?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Löschen'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }
}
