import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Unified Search Bar - Wiederverwendbares Such-Widget
/// 
/// Ein flexibles Such-Widget, das einfach in verschiedenen Screens
/// verwendet werden kann. Unterstützt Echtzeit-Suche, Vorschläge und
/// benutzerdefinierte Result-Widgets.
/// 
/// Beispiel:
/// ```dart
/// UnifiedSearchBar<T>(
///   items: myItems,
///   hintText: 'Suchen...',
///   itemBuilder: (context, item) => MyItemCard(item: item),
///   searchFilter: (item, query) => item.name.contains(query),
///   onItemSelected: (item) => _navigateTo(item),
/// )
/// ```
class UnifiedSearchBar<T> extends StatefulWidget {
  /// Liste aller durchsuchbaren Elemente
  final List<T> items;
  
  /// Widget-Builder für ein einzelnes Element
  final Widget Function(BuildContext context, T item) itemBuilder;
  
  /// Filter-Funktion: Gibt true zurück, wenn Element mit Suchabfrage übereinstimmt
  final bool Function(T item, String query) searchFilter;
  
  /// Callback, wenn ein Element ausgewählt wird
  final void Function(T item) onItemSelected;
  
  /// Platzhalter-Text für Suchfeld
  final String hintText;
  
  /// Icon für Suchfeld
  final IconData searchIcon;
  
  /// Maximale Anzahl von anzuzeigenden Ergebnissen
  final int maxResults;
  
  /// Zeige leere Ergebnisse an
  final bool showEmptyState;
  
  /// Zeige Vorschläge wenn Suchfeld leer ist
  final bool showSuggestionsWhenEmpty;
  
  /// Titel für leeren Zustand
  final String emptyStateTitle;
  
  /// Nachricht für leeren Zustand
  final String emptyStateMessage;

  const UnifiedSearchBar({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.searchFilter,
    required this.onItemSelected,
    this.hintText = 'Suchen...',
    this.searchIcon = Icons.search,
    this.maxResults = 10,
    this.showEmptyState = true,
    this.showSuggestionsWhenEmpty = false,
    this.emptyStateTitle = 'Keine Ergebnisse gefunden',
    this.emptyStateMessage = 'Versuche andere Suchbegriffe',
  });

  @override
  State<UnifiedSearchBar<T>> createState() => _UnifiedSearchBarState<T>();
}

class _UnifiedSearchBarState<T> extends State<UnifiedSearchBar<T>> {
  late TextEditingController _searchController;
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _filteredItems = widget.items.take(widget.maxResults).toList();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _filteredItems = widget.items.take(widget.maxResults).toList();
      });
      return;
    }

    final filtered = widget.items
        .where((item) => widget.searchFilter(item, query))
        .take(widget.maxResults)
        .toList();
    
    setState(() {
      _filteredItems = filtered;
    });
  }

  void _clearSearch() {
    _searchController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Suchfeld
        _buildSearchField(),
        
        // Ergebnisse
        if (_filteredItems.isNotEmpty)
          _buildResults()
        else if (widget.showEmptyState && _searchController.text.isNotEmpty)
          _buildEmptyState(),
      ],
    );
  }

  Widget _buildSearchField() {
    return Container(
      decoration: BoxDecoration(
        color: DnDTheme.slateGrey,
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.5),
          ),
          prefixIcon: Icon(
            widget.searchIcon,
            color: Colors.white.withOpacity(0.7),
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.white.withOpacity(0.7),
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _buildResults() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 400),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        itemCount: _filteredItems.length,
        separatorBuilder: (context, index) => Divider(
          color: Colors.white.withOpacity(0.1),
          height: 1,
        ),
        itemBuilder: (context, index) {
          final item = _filteredItems[index];
          return InkWell(
            onTap: () {
              widget.onItemSelected(item);
              _clearSearch();
            },
            child: widget.itemBuilder(context, item),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.white.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            widget.emptyStateTitle,
            style: DnDTheme.headline3.copyWith(
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            widget.emptyStateMessage,
            style: DnDTheme.bodyText1.copyWith(
              color: Colors.white.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Unified Search Dialog - Vollbild-Suchdialog
/// 
/// Vollbild-Suche mit größerer Anzeige und erweiterten Funktionen.
/// Ideal für mobile Screens mit vielen Elementen.
class UnifiedSearchDialog<T> extends StatefulWidget {
  /// Alle durchsuchbaren Elemente
  final List<T> items;
  
  /// Widget-Builder für ein Element
  final Widget Function(BuildContext context, T item) itemBuilder;
  
  /// Filter-Funktion
  final bool Function(T item, String query) searchFilter;
  
  /// Callback bei Auswahl
  final void Function(T item) onItemSelected;
  
  /// Titel der Suche
  final String title;
  
  /// Platzhalter-Text
  final String hintText;
  
  const UnifiedSearchDialog({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.searchFilter,
    required this.onItemSelected,
    this.title = 'Suchen',
    this.hintText = 'Suchen...',
  });

  @override
  State<UnifiedSearchDialog<T>> createState() => _UnifiedSearchDialogState<T>();

  /// Öffnet den Suchdialog und gibt das ausgewählte Element zurück
  static Future<T?> show<T>({
    required BuildContext context,
    required List<T> items,
    required Widget Function(BuildContext, T) itemBuilder,
    required bool Function(T, String) searchFilter,
    String title = 'Suchen',
    String hintText = 'Suchen...',
  }) {
    return showDialog<T>(
      context: context,
      builder: (context) => UnifiedSearchDialog<T>(
        items: items,
        itemBuilder: itemBuilder,
        searchFilter: searchFilter,
        onItemSelected: (item) {
          Navigator.of(context).pop(item);
        },
        title: title,
        hintText: hintText,
      ),
    );
  }
}

class _UnifiedSearchDialogState<T> extends State<UnifiedSearchDialog<T>> {
  late TextEditingController _searchController;
  List<T> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(_onSearchChanged);
    _filteredItems = widget.items;
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    
    if (query.isEmpty) {
      setState(() {
        _filteredItems = widget.items;
      });
      return;
    }

    final filtered = widget.items
        .where((item) => widget.searchFilter(item, query))
        .toList();
    
    setState(() {
      _filteredItems = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DnDTheme.stoneGrey,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DnDTheme.radiusLarge),
      ),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 600),
        width: double.maxFinite,
        child: Column(
          children: [
            // Header mit Suchfeld
            _buildHeader(),
            
            // Ergebnisse
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DnDTheme.radiusLarge),
          topRight: Radius.circular(DnDTheme.radiusLarge),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: widget.hintText,
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: Colors.white.withOpacity(0.7),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: Colors.white.withOpacity(0.7),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
                filled: true,
                fillColor: DnDTheme.slateGrey,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.of(context).pop(),
            tooltip: 'Schließen',
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    if (_filteredItems.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.white.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Ergebnisse',
              style: DnDTheme.headline3.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Versuche andere Suchbegriffe',
              style: DnDTheme.bodyText1.copyWith(
                color: Colors.white.withOpacity(0.7),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredItems.length,
      separatorBuilder: (context, index) => Divider(
        color: Colors.white.withOpacity(0.1),
      ),
      itemBuilder: (context, index) {
        final item = _filteredItems[index];
        return InkWell(
          onTap: () => widget.onItemSelected(item),
          child: widget.itemBuilder(context, item),
        );
      },
    );
  }
}
