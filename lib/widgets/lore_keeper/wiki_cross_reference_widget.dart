import 'package:flutter/material.dart';
import '../../models/wiki_link.dart';
import '../../models/wiki_entry.dart';
import '../../models/linked_wiki_entry.dart';
import '../../services/wiki_link_service.dart';
import '../../theme/dnd_theme.dart';

/// Widget für die Anzeige von Cross-References und Backlinks
class WikiCrossReferenceWidget extends StatefulWidget {
  final WikiEntry entry;
  final Function(String)? onEntryTap;

  const WikiCrossReferenceWidget({
    Key? key,
    required this.entry,
    this.onEntryTap,
  }) : super(key: key);

  @override
  State<WikiCrossReferenceWidget> createState() => _WikiCrossReferenceWidgetState();
}

class _WikiCrossReferenceWidgetState extends State<WikiCrossReferenceWidget>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final WikiLinkService _wikiLinkService = WikiLinkService();
  
  List<LinkedWikiEntry> _outgoingLinks = [];
  List<LinkedWikiEntry> _backlinks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadReferences();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReferences() async {
    setState(() => _isLoading = true);
    
    try {
      final outgoingResult = await _wikiLinkService.getLinkedEntriesWithDetails(widget.entry.id);
      final backlinksResult = await _wikiLinkService.getBacklinksWithDetails(widget.entry.id);
      
      final outgoing = outgoingResult.data ?? <Map<String, dynamic>>[];
      final backlinks = backlinksResult.data ?? <Map<String, dynamic>>[];
      
      setState(() {
        _outgoingLinks = outgoing.map((item) => LinkedWikiEntry.fromMap(item)).toList();
        _backlinks = backlinks.map((item) => LinkedWikiEntry.fromMap(item)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildTabBar(),
        _buildContent(),
      ],
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: DnDTheme.ancientGold,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white70,
        tabs: [
          Tab(
            text: 'Verweise (${_outgoingLinks.length})',
            icon: const Icon(Icons.arrow_forward, size: 16),
          ),
          Tab(
            text: 'Backlinks (${_backlinks.length})',
            icon: const Icon(Icons.arrow_back, size: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(DnDTheme.ancientGold),
          ),
        ),
      );
    }

    return Expanded(
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildLinksList(_outgoingLinks, 'verweist auf'),
          _buildLinksList(_backlinks, 'verweist von'),
        ],
      ),
    );
  }

  Widget _buildLinksList(List<LinkedWikiEntry> links, String description) {
    if (links.isEmpty) {
      return _buildEmptyState('Keine $description gefunden');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: links.length,
      itemBuilder: (context, index) => _buildLinkCard(links[index]),
    );
  }

  Widget _buildLinkCard(LinkedWikiEntry linkedEntry) {
    final link = linkedEntry.link;
    final targetEntry = linkedEntry.targetEntry;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getTypeColor(targetEntry.entryType),
          child: Icon(
            _getTypeIcon(targetEntry.entryType),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          targetEntry.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getTypeDisplayName(targetEntry.entryType),
              style: TextStyle(
                color: _getTypeColor(targetEntry.entryType),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _getLinkTypeDescription(link.linkType),
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.open_in_new, size: 16),
          onPressed: () => widget.onEntryTap?.call(targetEntry.id),
          tooltip: 'Öffnen',
        ),
        onTap: () => widget.onEntryTap?.call(targetEntry.id),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.link_off,
            size: 64,
            color: Colors.white70.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Color _getTypeColor(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return Colors.blue;
      case WikiEntryType.Place:
        return Colors.green;
      case WikiEntryType.Faction:
        return Colors.orange;
      case WikiEntryType.Magic:
        return Colors.purple;
      case WikiEntryType.History:
        return Colors.brown;
      case WikiEntryType.Item:
        return Colors.teal;
      case WikiEntryType.Quest:
        return Colors.indigo;
      case WikiEntryType.Creature:
        return Colors.red;
      case WikiEntryType.Lore:
        return DnDTheme.ancientGold;
    }
  }

  IconData _getTypeIcon(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return Icons.person;
      case WikiEntryType.Place:
        return Icons.place;
      case WikiEntryType.Faction:
        return Icons.group;
      case WikiEntryType.Magic:
        return Icons.auto_awesome;
      case WikiEntryType.History:
        return Icons.history;
      case WikiEntryType.Item:
        return Icons.inventory_2;
      case WikiEntryType.Quest:
        return Icons.task;
      case WikiEntryType.Creature:
        return Icons.pets;
      case WikiEntryType.Lore:
        return Icons.menu_book;
    }
  }

  String _getTypeDisplayName(WikiEntryType type) {
    switch (type) {
      case WikiEntryType.Person:
        return 'Person';
      case WikiEntryType.Place:
        return 'Ort';
      case WikiEntryType.Faction:
        return 'Fraktion';
      case WikiEntryType.Magic:
        return 'Magie';
      case WikiEntryType.History:
        return 'Geschichte';
      case WikiEntryType.Item:
        return 'Gegenstand';
      case WikiEntryType.Quest:
        return 'Quest';
      case WikiEntryType.Creature:
        return 'Kreatur';
      case WikiEntryType.Lore:
        return 'Lore';
    }
  }

  String _getLinkTypeDescription(WikiLinkType type) {
    switch (type) {
      case WikiLinkType.reference:
        return 'Normaler Verweis';
      case WikiLinkType.parent:
        return 'Parent-Beziehung';
      case WikiLinkType.related:
        return 'Verwandter Eintrag';
      case WikiLinkType.seeAlso:
        return '"Siehe auch" Verweis';
    }
  }
}

/// Widget für die Anzeige des Beziehungsgraphen
class WikiRelationshipGraphWidget extends StatelessWidget {
  final WikiEntry entry;
  final Function(String)? onEntryTap;

  const WikiRelationshipGraphWidget({
    Key? key,
    required this.entry,
    this.onEntryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beziehungsgraph',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visualisierung der Verbindungen dieses Eintrags mit anderen Wiki-Seiten.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          // Placeholder für Graph-Visualisierung
          Container(
            height: 200,
            decoration: BoxDecoration(
              color: DnDTheme.dungeonBlack,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white12),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.graphic_eq,
                    size: 48,
                    color: Colors.white70,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Graph-Visualisierung\n(in Kürze verfügbar)',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget für die Anzeige von broken links
class WikiBrokenLinksWidget extends StatelessWidget {
  final List<String> brokenLinks;
  final VoidCallback? onRefresh;

  const WikiBrokenLinksWidget({
    Key? key,
    required this.brokenLinks,
    this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (brokenLinks.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Alle Links sind gültig',
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.orange,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '${brokenLinks.length} fehlerhafte Links gefunden',
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (onRefresh != null)
                TextButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Aktualisieren'),
                ),
            ],
          ),
        ),
        ...brokenLinks.map((link) => _buildBrokenLinkItem(link)).toList(),
      ],
    );
  }

  Widget _buildBrokenLinkItem(String link) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.link_off,
            color: Colors.orange,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '[[$link]]',
              style: const TextStyle(
                color: Colors.orange,
                fontFamily: 'monospace',
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              // TODO: Erstelle neuen Eintrag aus broken link
            },
            child: const Text('Erstellen'),
          ),
        ],
      ),
    );
  }
}
