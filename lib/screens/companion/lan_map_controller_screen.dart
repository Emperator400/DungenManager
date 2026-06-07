import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/companion_map_state.dart';
import '../../theme/dnd_theme.dart';
import '../../viewmodels/lan_map_viewmodel.dart';

// ── Entry point — provides the ViewModel ─────────────────────────────────────

class LanMapControllerScreen extends StatelessWidget {
  const LanMapControllerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LanMapViewModel(),
      child: const _LanMapControllerView(),
    );
  }
}

// ── Inner stateful view ───────────────────────────────────────────────────────

class _LanMapControllerView extends StatefulWidget {
  const _LanMapControllerView();

  @override
  State<_LanMapControllerView> createState() => _LanMapControllerViewState();
}

class _LanMapControllerViewState extends State<_LanMapControllerView> {
  final TransformationController _tc = TransformationController();
  static const int _cols = 20;
  static const int _rows = 20;

  @override
  void initState() {
    super.initState();
    _tc.addListener(_onTransform);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LanMapViewModel>().startServer();
    });
  }

  @override
  void dispose() {
    _tc.removeListener(_onTransform);
    _tc.dispose();
    super.dispose();
  }

  void _onTransform() {
    final vm = context.read<LanMapViewModel>();
    if (vm.isRunning) vm.syncViewport(_tc.value);
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LanMapViewModel>();
    return Scaffold(
      backgroundColor: DnDTheme.stoneGrey,
      appBar: _buildAppBar(context, vm),
      body: Row(
        children: [
          _buildSidebar(context, vm),
          Expanded(child: _buildMapArea(context, vm)),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, LanMapViewModel vm) {
    return AppBar(
      backgroundColor: DnDTheme.stoneGrey,
      title: const Text('Karte teilen'),
      actions: [
        if (vm.isRunning)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Chip(
              backgroundColor: DnDTheme.successGreen.withValues(alpha: 0.2),
              label: Text(
                '${vm.clientCount} Zuschauer',
                style: TextStyle(color: DnDTheme.successGreen, fontSize: 12),
              ),
              avatar: Icon(Icons.circle, size: 10, color: DnDTheme.successGreen),
            ),
          ),
        IconButton(
          icon: const Icon(Icons.stop_circle_outlined),
          tooltip: 'Server stoppen',
          onPressed: vm.isRunning ? () => _confirmStop(context, vm) : null,
        ),
      ],
    );
  }

  // ── Sidebar ───────────────────────────────────────────────────────────────

  Widget _buildSidebar(BuildContext context, LanMapViewModel vm) {
    return SizedBox(
      width: 220,
      child: Container(
        color: DnDTheme.stoneGrey.withValues(alpha: 0.9),
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _sectionHeader('Server'),
            _buildConnectionCard(context, vm),
            const SizedBox(height: 16),
            _sectionHeader('Karte'),
            _buildImageButton(context, vm),
            const SizedBox(height: 16),
            _sectionHeader('Werkzeug'),
            _buildPaintModeButtons(vm),
            const SizedBox(height: 8),
            _buildFogControls(vm),
            const SizedBox(height: 16),
            _sectionHeader('Token'),
            _buildTokenControls(context, vm),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.bold,
        color: DnDTheme.ancientGold,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _buildConnectionCard(BuildContext context, LanMapViewModel vm) {
    if (!vm.isRunning) {
      return const Center(
        child: SizedBox(
          width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: vm.serverUrl));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('URL kopiert'), duration: Duration(seconds: 1)),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    vm.serverUrl,
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.copy, size: 14),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: QrImageView(
            data: vm.serverUrl,
            size: 140,
            backgroundColor: Colors.white,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(
              dataModuleShape: QrDataModuleShape.square,
              color: Colors.black,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageButton(BuildContext context, LanMapViewModel vm) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: DnDTheme.ancientGold,
        side: BorderSide(color: DnDTheme.ancientGold.withValues(alpha: 0.5)),
      ),
      icon: const Icon(Icons.image_outlined, size: 16),
      label: Text(
        vm.imagePath == null ? 'Bild wählen' : 'Bild ändern',
        style: const TextStyle(fontSize: 13),
      ),
      onPressed: () => _pickImage(context, vm),
    );
  }

  Widget _buildPaintModeButtons(LanMapViewModel vm) {
    return SegmentedButton<String>(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) =>
          states.contains(WidgetState.selected)
            ? DnDTheme.mysticalPurple.withValues(alpha: 0.4)
            : Colors.transparent),
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
      segments: const [
        ButtonSegment(
          value: 'reveal',
          icon: Icon(Icons.visibility, size: 14),
          label: Text('Enthüllen', style: TextStyle(fontSize: 10)),
        ),
        ButtonSegment(
          value: 'cover',
          icon: Icon(Icons.visibility_off, size: 14),
          label: Text('Decken', style: TextStyle(fontSize: 10)),
        ),
        ButtonSegment(
          value: 'token',
          icon: Icon(Icons.person_pin_circle_outlined, size: 14),
          label: Text('Token', style: TextStyle(fontSize: 10)),
        ),
      ],
      selected: {vm.paintMode},
      onSelectionChanged: (s) => vm.setPaintMode(s.first),
    );
  }

  Widget _buildFogControls(LanMapViewModel vm) {
    return Column(
      children: [
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Nebel aktiv', style: TextStyle(fontSize: 13)),
          value: vm.fogEnabled,
          onChanged: (_) => vm.toggleFog(),
          activeColor: DnDTheme.mysticalPurple,
        ),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: DnDTheme.successGreen,
                  side: BorderSide(color: DnDTheme.successGreen.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                onPressed: vm.revealAll,
                child: const Text('Alles', style: TextStyle(fontSize: 11)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: DnDTheme.errorRed,
                  side: BorderSide(color: DnDTheme.errorRed.withValues(alpha: 0.4)),
                  padding: const EdgeInsets.symmetric(vertical: 4),
                ),
                onPressed: vm.coverAll,
                child: const Text('Alles decken', style: TextStyle(fontSize: 11)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTokenControls(BuildContext context, LanMapViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: 'Kürzel (max. 2)',
            labelStyle: const TextStyle(fontSize: 12),
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
            counterText: '',
          ),
          maxLength: 2,
          onChanged: (v) => vm.tokenLabel = v,
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            '#e74c3c', '#3498db', '#2ecc71', '#f39c12', '#9b59b6', '#ecf0f1',
          ].map((c) {
            final selected = vm.tokenColor == c;
            return GestureDetector(
              onTap: () => vm.setTokenColor(c),
              child: Container(
                width: 26, height: 26,
                decoration: BoxDecoration(
                  color: Color(int.parse('0xFF${c.substring(1)}')),
                  shape: BoxShape.circle,
                  border: selected ? Border.all(color: Colors.white, width: 2) : null,
                ),
              ),
            );
          }).toList(),
        ),
        if (vm.tokens.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('${vm.tokens.length} Token gesetzt',
              style: const TextStyle(fontSize: 11, color: Colors.white54)),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: DnDTheme.errorRed,
              padding: EdgeInsets.zero,
            ),
            onPressed: () {
              for (final t in List<MapToken>.from(vm.tokens)) vm.removeToken(t.id);
            },
            child: const Text('Alle entfernen', style: TextStyle(fontSize: 11)),
          ),
        ],
      ],
    );
  }

  // ── Map area ──────────────────────────────────────────────────────────────

  Widget _buildMapArea(BuildContext context, LanMapViewModel vm) {
    if (vm.imagePath == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              'Kein Bild – bitte über die Seitenleiste wählen',
              style: TextStyle(color: Colors.white38),
            ),
          ],
        ),
      );
    }

    return InteractiveViewer(
      transformationController: _tc,
      minScale: 0.2,
      maxScale: 8.0,
      child: _MapContent(
        imagePath: vm.imagePath!,
        revealedCells: vm.revealedCells,
        fogEnabled: vm.fogEnabled,
        tokens: vm.tokens,
        cols: _cols,
        rows: _rows,
        onCellTap: (nx, ny) {
          if (vm.paintMode == 'token') {
            vm.placeToken(nx, ny);
          } else {
            final col = (nx * _cols).floor().clamp(0, _cols - 1);
            final row = (ny * _rows).floor().clamp(0, _rows - 1);
            vm.paintCell(row * _cols + col);
          }
        },
      ),
    );
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _pickImage(BuildContext context, LanMapViewModel vm) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.single.path == null) return;
    vm.setImage(result.files.single.path!);
  }

  Future<void> _confirmStop(BuildContext context, LanMapViewModel vm) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Server stoppen?'),
        content: const Text('Alle verbundenen Browser werden getrennt.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Stoppen', style: TextStyle(color: DnDTheme.errorRed)),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<LanMapViewModel>().stopServer();
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

// ── Map content widget (inside InteractiveViewer) ─────────────────────────────

class _MapContent extends StatelessWidget {
  final String imagePath;
  final Set<int> revealedCells;
  final bool fogEnabled;
  final List<MapToken> tokens;
  final int cols, rows;
  final void Function(double nx, double ny) onCellTap;

  const _MapContent({
    required this.imagePath,
    required this.revealedCells,
    required this.fogEnabled,
    required this.tokens,
    required this.cols,
    required this.rows,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return GestureDetector(
          onTapUp: (d) {
            final nx = (d.localPosition.dx / w).clamp(0.0, 1.0);
            final ny = (d.localPosition.dy / h).clamp(0.0, 1.0);
            onCellTap(nx, ny);
          },
          child: SizedBox(
            width: w,
            height: h,
            child: Stack(
              children: [
                // Map image
                Positioned.fill(
                  child: Image.file(
                    File(imagePath),
                    fit: BoxFit.fill,
                    gaplessPlayback: true,
                  ),
                ),
                // Fog + grid overlay
                Positioned.fill(
                  child: CustomPaint(
                    painter: _FogPainter(
                      revealedCells: revealedCells,
                      fogEnabled: fogEnabled,
                      cols: cols,
                      rows: rows,
                    ),
                  ),
                ),
                // Tokens — t.x/t.y sind normalisierte Koordinaten (0.0–1.0)
                ...tokens.map((t) {
                  final size = (w / cols) * 0.8 * t.size;
                  final left = t.x * w - size / 2;
                  final top  = t.y * h - size / 2;
                  return Positioned(
                    left: left,
                    top: top,
                    width: size,
                    height: size,
                    child: _TokenDot(token: t, size: size),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TokenDot extends StatelessWidget {
  final MapToken token;
  final double size;

  const _TokenDot({required this.token, required this.size});

  @override
  Widget build(BuildContext context) {
    final color = _parseColor(token.color);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 4)],
      ),
      child: Center(
        child: Text(
          token.label.length > 2 ? token.label.substring(0, 2).toUpperCase() : token.label.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.35,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static Color _parseColor(String hex) {
    try {
      return Color(int.parse('0xFF${hex.replaceFirst('#', '')}'));
    } catch (_) {
      return Colors.red;
    }
  }
}

class _FogPainter extends CustomPainter {
  final Set<int> revealedCells;
  final bool fogEnabled;
  final int cols, rows;

  const _FogPainter({
    required this.revealedCells,
    required this.fogEnabled,
    required this.cols,
    required this.rows,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width  / cols;
    final ch = size.height / rows;

    if (fogEnabled) {
      final fogPaint = Paint()..color = Colors.black.withValues(alpha: 0.8);
      for (int r = 0; r < rows; r++) {
        for (int c = 0; c < cols; c++) {
          if (!revealedCells.contains(r * cols + c)) {
            canvas.drawRect(Rect.fromLTWH(c * cw, r * ch, cw, ch), fogPaint);
          }
        }
      }
    }

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    for (int c = 0; c <= cols; c++) {
      canvas.drawLine(Offset(c * cw, 0), Offset(c * cw, size.height), gridPaint);
    }
    for (int r = 0; r <= rows; r++) {
      canvas.drawLine(Offset(0, r * ch), Offset(size.width, r * ch), gridPaint);
    }
  }

  @override
  bool shouldRepaint(_FogPainter old) =>
      old.fogEnabled != fogEnabled ||
      old.revealedCells != revealedCells;
}
