import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../models/ort.dart';
import '../../theme/app_theme.dart';

class OrtGraphView extends StatefulWidget {
  final List<Ort> orte;
  final Ort? selectedOrt;
  final void Function(Ort) onSelect;

  /// Called after a node has been dragged to a new position.
  /// [x] and [y] are canvas-space coordinates (unscaled, relative to canvas
  /// origin) that should be persisted to the Ort.
  final void Function(String ortId, double x, double y)? onPositionChanged;

  /// Called when the user double-taps on empty canvas space.
  /// [x] and [y] are canvas-space coordinates where the new Ort should be
  /// placed. The caller is responsible for showing a creation dialog.
  final void Function(double x, double y)? onAddOrtAt;

  const OrtGraphView({
    super.key,
    required this.orte,
    required this.selectedOrt,
    required this.onSelect,
    this.onPositionChanged,
    this.onAddOrtAt,
  });

  @override
  State<OrtGraphView> createState() => _OrtGraphViewState();
}

class _OrtGraphViewState extends State<OrtGraphView> {
  static const double _nodeW = 130;
  static const double _nodeH = 52;
  static const double _minScale = 0.35;
  static const double _maxScale = 2.5;

  // Pan offset in screen pixels. The canvas origin appears at
  // (center + _panOffset) on screen.
  Offset _panOffset = Offset.zero;

  // Per-node positions in canvas units (unscaled, relative to canvas origin).
  final Map<String, Offset> _positions = {};

  // Current zoom level.
  double _scale = 1.0;

  // Gesture tracking for combined pan+pinch.
  double _scaleAtStart = 1.0;
  Offset _panOffsetAtStart = Offset.zero;
  Offset _focalAtStart = Offset.zero;

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
        _positions[ort.id] = (ort.mapX != null && ort.mapY != null)
            ? Offset(ort.mapX!, ort.mapY!)
            : _circularPos(i, n);
      }
    }
    _positions.removeWhere(
      (id, _) => !widget.orte.any((o) => o.id == id),
    );
  }

  void _initPositions(List<Ort> orte) {
    _positions.clear();
    for (int i = 0; i < orte.length; i++) {
      final ort = orte[i];
      _positions[ort.id] = (ort.mapX != null && ort.mapY != null)
          ? Offset(ort.mapX!, ort.mapY!)
          : _circularPos(i, orte.length);
    }
  }

  Offset _circularPos(int i, int n) {
    if (n <= 1) return Offset.zero;
    final radius = min(70.0 + n * 26.0, 260.0);
    final angle = (2 * pi * i) / n - pi / 2;
    return Offset(radius * cos(angle), radius * sin(angle));
  }

  // ── GESTURE HANDLERS ────────────────────────────────────────────────────────

  void _onScaleStart(ScaleStartDetails d) {
    _scaleAtStart = _scale;
    _panOffsetAtStart = _panOffset;
    _focalAtStart = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d, Offset center) {
    final newScale = (_scaleAtStart * d.scale).clamp(_minScale, _maxScale);

    // Keep the focal canvas point fixed on screen.
    // focalCanvas is the canvas-space point under the finger at gesture start.
    final focalCanvas =
        (_focalAtStart - center - _panOffsetAtStart) / _scaleAtStart;

    // New panOffset so that focalCanvas appears at d.localFocalPoint.
    final newPanOffset = d.localFocalPoint - center - focalCanvas * newScale;

    setState(() {
      _scale = newScale;
      _panOffset = newPanOffset;
    });
  }

  void _onScrollZoom(PointerScrollEvent e, Offset center) {
    final zoomFactor = e.scrollDelta.dy > 0 ? 0.9 : 1.1;
    final newScale = (_scale * zoomFactor).clamp(_minScale, _maxScale);

    // Zoom toward the mouse cursor position.
    final mouseCanvas = (e.localPosition - center - _panOffset) / _scale;
    setState(() {
      _panOffset = e.localPosition - center - mouseCanvas * newScale;
      _scale = newScale;
    });
  }

  // ── COORDINATE HELPERS ───────────────────────────────────────────────────────

  // Screen position of a canvas point (rel = position in canvas units).
  Offset _toScreen(Offset center, Offset rel) =>
      center + _panOffset + rel * _scale;

  // Canvas position from a screen coordinate.
  Offset _toCanvas(Offset center, Offset screen) =>
      (screen - center - _panOffset) / _scale;

  // ── BUILD ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;

    if (widget.orte.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 40, color: C.textSoft),
            const SizedBox(height: 8),
            Text(
              'Noch keine Orte',
              style: TextStyle(fontSize: 13, color: C.textSoft),
            ),
            const SizedBox(height: 4),
            Text(
              'Doppelklick zum Anlegen',
              style: TextStyle(fontSize: 11, color: C.textSoft.withValues(alpha: 0.6)),
            ),
          ],
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
          child: Listener(
            onPointerSignal: (e) {
              if (e is PointerScrollEvent) _onScrollZoom(e, center);
            },
            child: GestureDetector(
              onScaleStart: _onScaleStart,
              onScaleUpdate: (d) => _onScaleUpdate(d, center),
              onDoubleTapDown: widget.onAddOrtAt == null
                  ? null
                  : (d) {
                      final canvas = _toCanvas(center, d.localPosition);
                      widget.onAddOrtAt!(canvas.dx, canvas.dy);
                    },
              child: Container(
                color: Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.hardEdge,
                  children: [
                    // Dot-Grid (background)
                    Positioned.fill(
                      child: ClipRect(
                        child: CustomPaint(
                          painter:
                              _DotGridPainter(C, _panOffset, _scale),
                        ),
                      ),
                    ),

                    // Hint text when addOrtAt is available
                    if (widget.onAddOrtAt != null)
                      Positioned(
                        right: 12,
                        bottom: 10,
                        child: Text(
                          'Doppelklick → Ort anlegen',
                          style: TextStyle(
                            fontSize: 10,
                            color: C.textSoft.withValues(alpha: 0.45),
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
                            scale: _scale,
                            C: C,
                          ),
                        ),
                      ),
                    ),

                    // Ort-Nodes
                    ...widget.orte.map((ort) {
                      final rel = _positions[ort.id] ?? Offset.zero;
                      final screenPos = _toScreen(center, rel);

                      return Positioned(
                        left: screenPos.dx - _nodeW / 2,
                        top: screenPos.dy - _nodeH / 2,
                        child: GestureDetector(
                          // Node drag: delta is in screen px → convert to canvas.
                          onPanUpdate: (d) => setState(() {
                            _positions[ort.id] =
                                (_positions[ort.id] ?? Offset.zero) +
                                    d.delta / _scale;
                          }),
                          onPanEnd: (_) {
                            final pos = _positions[ort.id];
                            if (pos != null) {
                              widget.onPositionChanged
                                  ?.call(ort.id, pos.dx, pos.dy);
                            }
                          },
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
          ),
        );
      },
    );
  }
}

// ── DOT GRID ──────────────────────────────────────────────────────────────────

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter(this.C, this.offset, this.scale);

  final AppColorsExtension C;
  final Offset offset;
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = C.border.withValues(alpha: 0.45);
    const baseSpacing = 28.0;
    final spacing = baseSpacing * scale;
    final ox = (size.width / 2 + offset.dx) % spacing;
    final oy = (size.height / 2 + offset.dy) % spacing;
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
  bool shouldRepaint(_DotGridPainter old) =>
      old.offset != offset || old.scale != scale;
}

// ── EDGE PAINTER ─────────────────────────────────────────────────────────────

class _EdgePainter extends CustomPainter {
  const _EdgePainter({
    required this.orte,
    required this.positions,
    required this.center,
    required this.panOffset,
    required this.scale,
    required this.C,
  });

  final List<Ort> orte;
  final Map<String, Offset> positions;
  final Offset center;
  final Offset panOffset;
  final double scale;
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

        final from =
            center + panOffset + (positions[ort.id] ?? Offset.zero) * scale;
        final to =
            center + panOffset + (positions[target.id] ?? Offset.zero) * scale;
        canvas.drawLine(from, to, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_EdgePainter old) =>
      old.positions != positions ||
      old.panOffset != panOffset ||
      old.scale != scale;
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
      case OrtType.region:     return AppColors.typGeschichte;
      case OrtType.other:      return C.textSoft;
      case OrtType.token:      return const Color(0xFF9b59b6);
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
