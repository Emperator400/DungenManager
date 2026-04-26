import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class UnifiedSearchBar<T> extends StatefulWidget {
  const UnifiedSearchBar({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.searchFilter,
    required this.onItemSelected,
    this.hintText = 'Suchen...',
    this.maxResults = 10,
    this.showEmptyState = true,
    this.emptyStateTitle = 'Keine Ergebnisse gefunden',
    this.emptyStateMessage = 'Versuche andere Suchbegriffe',
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool Function(T item, String query) searchFilter;
  final void Function(T item) onItemSelected;
  final String hintText;
  final int maxResults;
  final bool showEmptyState;
  final String emptyStateTitle;
  final String emptyStateMessage;

  @override
  State<UnifiedSearchBar<T>> createState() => _UnifiedSearchBarState<T>();
}

class _UnifiedSearchBarState<T> extends State<UnifiedSearchBar<T>> {
  final _ctrl = TextEditingController();
  List<T> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items.take(widget.maxResults).toList();
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _ctrl.text.trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items.take(widget.maxResults).toList()
          : widget.items
              .where((i) => widget.searchFilter(i, q))
              .take(widget.maxResults)
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _SearchField(ctrl: _ctrl, hint: widget.hintText, C: C),
        if (_filtered.isNotEmpty)
          _Results(
            items: _filtered,
            itemBuilder: widget.itemBuilder,
            onSelected: (item) {
              widget.onItemSelected(item);
              _ctrl.clear();
              FocusScope.of(context).unfocus();
            },
            C: C,
          )
        else if (widget.showEmptyState && _ctrl.text.isNotEmpty)
          _EmptyState(
            title: widget.emptyStateTitle,
            message: widget.emptyStateMessage,
            C: C,
          ),
      ],
    );
  }
}

class UnifiedSearchDialog<T> extends StatefulWidget {
  const UnifiedSearchDialog({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.searchFilter,
    required this.onItemSelected,
    this.title = 'Suchen',
    this.hintText = 'Suchen...',
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final bool Function(T item, String query) searchFilter;
  final void Function(T item) onItemSelected;
  final String title;
  final String hintText;

  static Future<T?> show<T>({
    required BuildContext context,
    required List<T> items,
    required Widget Function(BuildContext, T) itemBuilder,
    required bool Function(T, String) searchFilter,
    String title = 'Suchen',
    String hintText = 'Suchen...',
  }) =>
      showDialog<T>(
        context: context,
        builder: (_) => UnifiedSearchDialog<T>(
          items: items,
          itemBuilder: itemBuilder,
          searchFilter: searchFilter,
          onItemSelected: (item) => Navigator.of(context).pop(item),
          title: title,
          hintText: hintText,
        ),
      );

  @override
  State<UnifiedSearchDialog<T>> createState() =>
      _UnifiedSearchDialogState<T>();
}

class _UnifiedSearchDialogState<T> extends State<UnifiedSearchDialog<T>> {
  final _ctrl = TextEditingController();
  List<T> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
    _ctrl.addListener(_onChanged);
  }

  @override
  void dispose() {
    _ctrl
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    final q = _ctrl.text.trim();
    setState(() {
      _filtered = q.isEmpty
          ? widget.items
          : widget.items.where((i) => widget.searchFilter(i, q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Dialog(
      backgroundColor: C.bgPanel,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: C.border),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 560),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: C.text,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Icon(Icons.close, size: 18, color: C.textSoft),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: _SearchField(ctrl: _ctrl, hint: widget.hintText, C: C),
            ),
            Divider(height: 1, color: C.border),
            Expanded(
              child: _filtered.isEmpty
                  ? _EmptyState(
                      title: 'Keine Ergebnisse',
                      message: 'Versuche andere Suchbegriffe',
                      C: C,
                    )
                  : _Results(
                      items: _filtered,
                      itemBuilder: widget.itemBuilder,
                      onSelected: widget.onItemSelected,
                      C: C,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PRIVATE HELPERS ───────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.ctrl, required this.hint, required this.C});

  final TextEditingController ctrl;
  final String hint;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Container(
        height: 38,
        decoration: BoxDecoration(
          color: C.bgPanel,
          border: Border.all(color: C.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            const SizedBox(width: 10),
            Icon(Icons.search, size: 16, color: C.textSoft),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: ctrl,
                style: TextStyle(fontSize: 13, color: C.text),
                decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(fontSize: 13, color: C.textSoft),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            if (ctrl.text.isNotEmpty)
              GestureDetector(
                onTap: ctrl.clear,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(Icons.close, size: 14, color: C.textSoft),
                ),
              )
            else
              const SizedBox(width: 10),
          ],
        ),
      );
}

class _Results<T> extends StatelessWidget {
  const _Results({
    required this.items,
    required this.itemBuilder,
    required this.onSelected,
    required this.C,
  });

  final List<T> items;
  final Widget Function(BuildContext, T) itemBuilder;
  final void Function(T) onSelected;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => ListView.separated(
        shrinkWrap: true,
        physics: const ClampingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: items.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: C.border),
        itemBuilder: (ctx, i) => InkWell(
          onTap: () => onSelected(items[i]),
          child: itemBuilder(ctx, items[i]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.title,
    required this.message,
    required this.C,
  });

  final String title;
  final String message;
  final AppColorsExtension C;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 40, color: C.border),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: C.textMid,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              style: TextStyle(fontSize: 12, color: C.textSoft),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
