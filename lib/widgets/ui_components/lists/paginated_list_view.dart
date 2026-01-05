import 'package:flutter/material.dart';

/// Wiederverwendbare paginierte ListView
/// 
/// Bietet eine performante ListView mit Pagination, Loading-States
/// und automatischem Laden weiterer Elemente beim Scrollen.
class PaginatedListView<T> extends StatefulWidget {
  /// Alle Elemente
  final List<T> items;
  
  /// Widget-Builder für ein Element
  final Widget Function(BuildContext context, T item) itemBuilder;
  
  /// Ob mehr Elemente geladen werden
  final bool isLoadingMore;
  
  /// Ob alle Elemente geladen wurden
  final bool hasReachedEnd;
  
  /// Callback zum Laden weiterer Elemente
  final VoidCallback? onLoadMore;
  
  /// Separator zwischen Elementen
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  
  /// Padding für die Liste
  final EdgeInsetsGeometry? padding;
  
  /// Widget für leeren Zustand
  final Widget? emptyState;
  
  /// Widget für Ladezustand
  final Widget? loadingState;
  
  /// Item-Anzahl pro Seite (für Pagination)
  final int pageSize;
  
  /// Schwellenwert für Load More (wie viele Elemente vor Ende laden)
  final int loadMoreThreshold;

  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.onLoadMore,
    this.separatorBuilder,
    this.padding,
    this.emptyState,
    this.loadingState,
    this.pageSize = 20,
    this.loadMoreThreshold = 5,
  });

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (widget.onLoadMore == null) return;
    if (widget.isLoadingMore) return;
    if (widget.hasReachedEnd) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final delta = maxScroll - currentScroll;

    if (delta <= widget.loadMoreThreshold * 100) {
      widget.onLoadMore!();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Leerer Zustand
    if (widget.items.isEmpty && !widget.isLoadingMore) {
      return widget.emptyState ?? _buildDefaultEmptyState();
    }

    return Column(
      children: [
        // Liste
        Expanded(
          child: ListView.separated(
            controller: _scrollController,
            padding: widget.padding,
            itemCount: widget.items.length + (widget.isLoadingMore ? 1 : 0),
            separatorBuilder: widget.separatorBuilder ?? 
              (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              // Lade-Indicator am Ende
              if (index == widget.items.length) {
                return _buildLoadingIndicator();
              }
              
              return widget.itemBuilder(context, widget.items[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDefaultEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Elemente',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
