import 'dart:math';

import 'package:flutter/material.dart';

import '../../models/ort.dart';
import '../../theme/app_theme.dart';

class OrtGraphView extends StatefulWidget {
  final List<Ort> orte;
  final Ort? selectedOrt;
  final void Function(Ort) onSelect;

  const OrtGraphView({
    super.key,
    required this.orte,
    required this.selectedOrt,
    required this.onSelect,
  });

  @override
  State<OrtGraphView> createState() => _OrtGraphViewState();
}

class _OrtGraphViewState extends State<OrtGraphView> {
  static const double _nodeW = 130;
  static const double _nodeH = 52;

  // Pan-Offset der gesamten Canvas
  Offset _panOffset = Offset.zero;

  // Position jedes Orts relativ zur Canvas-Mitte
  final Map<String, Offset> _positions = {};

  @override
  void initState() {
    super.initState();
    _initPositions(widget.orte);
  }

  @override
  void didUpdateWidget(OrtGraphView old) {
    super.didUpdateWidget(old);
    final n = widget.orte.length;
    for (int i = 0; i < n; i++) {
      final ort = widget.orte[i];
      if (!_positions.containsKey(ort.id)) {
        _positions[ort.id] = _circularPos(i, n);
      }
    }
    _positions.removeWhere(
      (id, _) => !widget.orte.any((o) => o.id == id),
    );
  }

  void _initPositions(List<Ort> orte) {
    _positions.clear();
    for (int i = 0; i < orte.length; i++) {
      _positions[orte[i].id] = _circularPos(i, orte.length);
    }
  }

  Offset _circularPos(int i, int n) {
    if (n <= 1) return Offset.zero;
    final radius = min(70.0 + n * 26.0, 260.0);
    final angle = (2 * pi * i) / n - pi / 2;
    return Offset(radius * cos(angle), radius * sin(angle));
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    if (widget.orte.isEmpty) {
      return Center(
        child: Text(
          'Noch keine Orte',
          style: TextStyle(fontSize: 13, color: C.textSoft),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final center = Offset(
          constraints.maxWidth / 2,
          constraints.maxHeight / 2,
        );

        return ClipRect(
          child: GestureDetector(
          // Pan auf dem Hintergrund = Canvas verschieben
          onPanUpdate: (d) => setState(() => _panOffset += d.delta),
          child: Container(
            color: Colors.transparent,
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                // Dot-Grid
                Positioned.fill(
                  child: ClipRect(
                    child: CustomPaint(
                      painter: _DotGridPainter(C, _panOffset),
                    ),
                  ),
                ),
                // Verbindungs-Kanten (unter den Nodes)
                Positioned.fill(
                  child: ClipRect(
                    child: CustomPaint(
                      painter: _EdgePainter(
                        orte: widget.orte,
                        positions: _positions,
                        center: center,
                        panOffset: _panOffset,
                        C: C,
                      ),
                    ),
                  ),
                ),
                // Ort-Nodes
                ...widget.orte.map((ort) {
                  final rel = _positions[ort.id] ?? Offset.zero;
                  final screenPos = center + _panOffset + rel;

                  return Positioned(
                    left: screenPos.dx - _nodeW / 2,
                    top: screenPos.dy - _nodeH / 2,
                    child: GestureDetector(
                      // Pan auf Node = nur diesen Node verschieben
                      onPanUpdate: (d) => setState(() {
                        _positions[ort.id] = (_positions[ort.id] ?? Offset.zero) + d.delta;
                      }),
                      child: _OrtNode(
                        ort: ort,
                        selected: widget.selectedOrt?.id == ort.id,
                        onTap: () => widget.onSelect(ort),
                        width: _nodeW,
                        height: _nodeH,
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        );
      },
    );
  }
}

// ── DOT GRID ──────────────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter(this.C, this.offset);

  final AppColorsExtension C;
  final Offset offset;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = C.border.withValues(alpha: 0.45);
    const spacing = 28.0;
    // Offset-basiert damit das Raster beim Panen mitläuft
    final ox = offset.dx % spacing;
    final oy = offset.dy % spacing;
    final cols = (size.width / spacing).ceil() + 2;
    final rows = (size.height / spacing).ceil() + 2;
    for (int x = -1; x <= cols; x++) {
      for (int y = -1; y <= rows; y++) {
        canvas.drawCircle(
          Offset(x * spacing + ox, y * spacing + oy),
          1.2,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter old) => old.offset != offset;
}

// ── EDGE PAINTER ─────────────────────────────────────────────────────────────

class _EdgePainter extends CustomPainter {
  const _EdgePainter({
    required this.orte,
    required this.positions,
    required this.center,
    required this.panOffset,
    required this.C,
  });

  final List<Ort> orte;
  final Map<String, Offset> positions;
  final Offset center;
  final Offset panOffset;
  final AppColorsExtension C;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = C.border.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final seen = <String>{};
    for (final ort in orte) {
      for (final targetId in ort.connectedOrtIds) {
        final edgeKey = [ort.id, targetId]..sort();
        final key = edgeKey.join('-');
        if (seen.contains(key)) continue;
        seen.add(key);

        final target = orte.firstWhere(
          (o) => o.id == targetId,
          orElse: () => ort,
        );
        if (target.id == ort.id) continue;

        final from = center + panOffset + (positions[ort.id] ?? Offset.zero);
        final to = center + panOffset + (positions[target.id] ?? Offset.zero);
        canvas.drawLine(from, to, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.positions != positions || old.panOffset != panOffset;
}

// ── ORT NODE ──────────────────────────────────────────────────────────────────

class _OrtNode extends StatefulWidget {
  const _OrtNode({
    required this.ort,
    required this.selected,
    required this.onTap,
    required this.width,
    required this.height,
  });

  final Ort ort;
  final bool selected;
  final VoidCallback onTap;
  final double width;
  final double height;

  @override
  State<_OrtNode> createState() => _OrtNodeState();
}

class _OrtNodeState extends State<_OrtNode> {
  bool _hovered = false;

  Color _typeColor(AppColorsExtension C) {
    switch (widget.ort.type) {
      case OrtType.dungeon:    return C.red;
      case OrtType.city:       return C.green;
      case OrtType.building:   return C.accent;
      case OrtType.wilderness: return C.amber;
      case OrtType.other:      return C.textSoft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final color = _typeColor(C);
    final selected = widget.selected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: widget.width,
          height: widget.height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.12)
                : _hovered
                    ? C.bgHover
                    : C.bgPanel,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : C.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: selected ? 0.18 : 0.07),
                blurRadius: selected ? 10 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(width: 4, color: color),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.ort.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: selected ? color : C.text,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          widget.ort.type.label,
                          style: TextStyle(fontSize: 10, color: C.textSoft),
                        ),
                        if (widget.ort.hasBeenVisited) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: C.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
            ],
          ),
        ),
      ),
    );
  }
}
