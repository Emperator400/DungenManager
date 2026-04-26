import 'dart:math';
import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/screen_node.dart';
import '../../services/screen_graph_service.dart';

class ScreenGraphVisualizationScreen extends StatefulWidget {
  const ScreenGraphVisualizationScreen({super.key});

  @override
  State<ScreenGraphVisualizationScreen> createState() => _ScreenGraphVisualizationScreenState();
}

class _ScreenGraphVisualizationScreenState extends State<ScreenGraphVisualizationScreen> {
  final ScreenGraphService _screenGraphService = ScreenGraphService();
  Map<String, ScreenNode> _screens = {};
  String _selectedCategory = 'All';
  bool _showConnections = true;
  bool _showParameters = true;
  String _selectedScreen = '';

  static const Color _warningOrange = Color(0xFFEA580C);
  static const Color _mysticalPurple = Color(0xFF7C3AED);

  @override
  void initState() {
    super.initState();
    _loadScreens();
  }

  Future<void> _loadScreens() async {
    final screens = _screenGraphService.getManualScreenData();
    if (mounted) {
      setState(() {
        _screens = screens;
      });
    }
  }

  List<ScreenNode> get _filteredScreens {
    if (_selectedCategory == 'All') {
      return _screens.values.toList();
    }
    return _screens.values.where((s) => s.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Scaffold(
      backgroundColor: C.bg,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildFilterBar(context),
          Expanded(
            child: _screens.isEmpty
                ? _buildLoadingIndicator(C)
                : Row(
                    children: [
                      Expanded(child: _buildGraphArea(context)),
                      if (_selectedScreen.isNotEmpty) _buildScreenDetails(context),
                    ],
                  ),
          ),
          _buildLegend(context),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final C = context.appColors;
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Screen Navigation Graph',
            style: TextStyle(color: C.amber, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${_screens.length} Screens mit Navigation-Verbindungen',
            style: TextStyle(color: C.amber.withValues(alpha: 0.7), fontSize: 12),
          ),
        ],
      ),
      backgroundColor: _mysticalPurple,
      elevation: 4,
      actions: [
        IconButton(
          icon: Icon(_showConnections ? Icons.link : Icons.link_off, color: C.amber),
          onPressed: () => setState(() => _showConnections = !_showConnections),
          tooltip: 'Verbindungen anzeigen/ausblenden',
        ),
        IconButton(
          icon: Icon(_showParameters ? Icons.visibility : Icons.visibility_off, color: C.amber),
          onPressed: () => setState(() => _showParameters = !_showParameters),
          tooltip: 'Parameter anzeigen/ausblenden',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: C.amber),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'refresh',
              child: Row(children: [Icon(Icons.refresh, color: C.green), const SizedBox(width: 8), const Text('Aktualisieren')]),
            ),
            PopupMenuItem(
              value: 'listView',
              child: Row(children: [Icon(Icons.list, color: C.green), const SizedBox(width: 8), const Text('Listenansicht')]),
            ),
            PopupMenuItem(
              value: 'info',
              child: Row(children: [Icon(Icons.info, color: C.green), const SizedBox(width: 8), const Text('Info')]),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.bgPanel.withValues(alpha: 0.5),
        border: Border(
          bottom: BorderSide(color: _mysticalPurple.withValues(alpha: 0.3)),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip(context, 'All', Icons.all_inclusive),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Navigation', Icons.navigation),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Campaign', Icons.campaign),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Quest Management', Icons.assignment),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Wiki/Lore', Icons.menu_book),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Character', Icons.person),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Bestiary', Icons.pets),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Item', Icons.inventory_2),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Audio', Icons.music_note),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Session', Icons.play_circle),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Utility', Icons.build),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Testing', Icons.bug_report),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String category, IconData icon) {
    final C = context.appColors;
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? C.bg : C.amber),
          const SizedBox(width: 4),
          Text(category),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedCategory = category;
            _selectedScreen = '';
          });
        }
      },
      selectedColor: _mysticalPurple,
      backgroundColor: C.bgPanel.withValues(alpha: 0.3),
      labelStyle: TextStyle(color: isSelected ? C.bg : C.amber),
    );
  }

  Widget _buildGraphArea(BuildContext context) {
    final C = context.appColors;
    final screens = _filteredScreens;
    return CustomPaint(
      painter: _GraphPainter(
        screens: screens,
        showConnections: _showConnections,
        showParameters: _showParameters,
        selectedScreen: _selectedScreen,
        categoryColors: _getCategoryColors(C),
        connectionColors: {
          ConnectionType.navigation: C.green,
          ConnectionType.modal: _warningOrange,
          ConnectionType.deepLink: _mysticalPurple,
          ConnectionType.action: C.accent,
        },
        warningColor: _warningOrange,
        labelColor: C.amber,
        onScreenTap: (screenName) {
          setState(() {
            _selectedScreen = _selectedScreen == screenName ? '' : screenName;
          });
        },
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: C.bg.withValues(alpha: 0.3),
      ),
    );
  }

  Widget _buildScreenDetails(BuildContext context) {
    final C = context.appColors;
    final screen = _screens[_selectedScreen];
    if (screen == null) return const SizedBox();

    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: C.bgPanel.withValues(alpha: 0.9),
        border: const Border(left: BorderSide(color: _mysticalPurple, width: 2)),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              Icon(_getCategoryIcon(screen.category), color: _getCategoryColor(screen.category, C), size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  screen.name,
                  style: TextStyle(color: C.amber, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: C.amber),
                onPressed: () => setState(() => _selectedScreen = ''),
              ),
            ],
          ),
          Divider(color: _mysticalPurple.withValues(alpha: 0.3)),
          const SizedBox(height: 16),
          _buildDetailRow(C, 'Dateiname', screen.fileName),
          const SizedBox(height: 8),
          _buildDetailRow(C, 'Kategorie', screen.category),
          const SizedBox(height: 16),
          if (screen.requiresParameters) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _warningOrange.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _warningOrange.withValues(alpha: 0.5)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: _warningOrange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      screen.parameterInfo ?? 'Benötigt Parameter',
                      style: const TextStyle(color: _warningOrange),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Verbindungen (${screen.connections.length})',
            style: TextStyle(color: C.amber, fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          ...screen.connections.map((conn) => _buildConnectionCard(C, conn)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(AppColorsExtension C, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: TextStyle(color: C.amber.withValues(alpha: 0.7), fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: C.amber)),
        ),
      ],
    );
  }

  Widget _buildConnectionCard(AppColorsExtension C, ScreenConnection connection) {
    final connColor = _getConnectionColor(connection.type, C);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: connColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: connColor.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getConnectionIcon(connection.type), size: 16, color: connColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  connection.targetScreen,
                  style: TextStyle(color: C.amber, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ],
          ),
          if (connection.triggerAction != null) ...[
            const SizedBox(height: 4),
            Text(
              'Trigger: ${connection.triggerAction}',
              style: TextStyle(color: C.amber.withValues(alpha: 0.7), fontSize: 12),
            ),
          ],
          if (connection.description != null) ...[
            const SizedBox(height: 2),
            Text(
              connection.description!,
              style: TextStyle(color: C.amber.withValues(alpha: 0.5), fontSize: 11, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: C.bgPanel.withValues(alpha: 0.3),
        border: Border(top: BorderSide(color: _mysticalPurple.withValues(alpha: 0.3))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Legende', style: TextStyle(color: C.amber, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegendItem(C, 'Navigation', C.green),
              _buildLegendItem(C, 'Deep Link', _mysticalPurple),
              _buildLegendItem(C, 'Modal', _warningOrange),
              _buildLegendItem(C, 'Action', C.accent),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(AppColorsExtension C, String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: C.amber, fontSize: 12)),
      ],
    );
  }

  Widget _buildLoadingIndicator(AppColorsExtension C) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(C.amber)),
          const SizedBox(height: 16),
          Text('Lade Screens...', style: TextStyle(color: C.amber, fontSize: 16)),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category, AppColorsExtension C) {
    return _getCategoryColors(C)[category] ?? C.bgPanel;
  }

  Map<String, Color> _getCategoryColors(AppColorsExtension C) {
    return {
      'Navigation': _mysticalPurple,
      'Campaign': C.amber,
      'Quest Management': C.green,
      'Wiki/Lore': C.accent,
      'Character': _warningOrange,
      'Bestiary': C.red,
      'Item': C.bgPanel,
      'Audio': C.accent,
      'Session': C.green,
      'Utility': _warningOrange,
      'Testing': _mysticalPurple,
    };
  }

  Color _getConnectionColor(ConnectionType type, AppColorsExtension C) {
    return switch (type) {
      ConnectionType.navigation => C.green,
      ConnectionType.modal => _warningOrange,
      ConnectionType.deepLink => _mysticalPurple,
      ConnectionType.action => C.accent,
    };
  }

  IconData _getConnectionIcon(ConnectionType type) {
    return switch (type) {
      ConnectionType.navigation => Icons.arrow_forward,
      ConnectionType.modal => Icons.open_in_new,
      ConnectionType.deepLink => Icons.link,
      ConnectionType.action => Icons.touch_app,
    };
  }

  IconData _getCategoryIcon(String category) {
    return switch (category) {
      'Navigation' => Icons.navigation,
      'Campaign' => Icons.campaign,
      'Quest Management' => Icons.assignment,
      'Wiki/Lore' => Icons.menu_book,
      'Character' => Icons.person,
      'Bestiary' => Icons.pets,
      'Item' => Icons.inventory_2,
      'Audio' => Icons.music_note,
      'Session' => Icons.play_circle,
      'Utility' => Icons.build,
      'Testing' => Icons.bug_report,
      _ => Icons.screen_share,
    };
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _loadScreens();
      case 'listView':
        _showListView();
      case 'info':
        _showInfoDialog();
    }
  }

  void _showListView() {
    final C = context.appColors;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Text('Alle Screens', style: TextStyle(color: C.amber)),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _screens.length,
            itemBuilder: (context, index) {
              final screen = _screens.values.elementAt(index);
              return ListTile(
                leading: Icon(_getCategoryIcon(screen.category), color: _getCategoryColor(screen.category, C)),
                title: Text(screen.name, style: TextStyle(color: C.amber)),
                subtitle: Text(
                  '${screen.fileName} • ${screen.category}',
                  style: TextStyle(color: C.amber.withValues(alpha: 0.7)),
                ),
                trailing: screen.requiresParameters
                    ? const Icon(Icons.warning, color: _warningOrange, size: 20)
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: C.green),
            child: const Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    final C = context.appColors;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: C.bgPanel,
        title: Row(
          children: [
            const Icon(Icons.info, color: _mysticalPurple),
            const SizedBox(width: 8),
            Text('Screen Graph Visualizer', style: TextStyle(color: C.amber)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection(C, 'Was ist das?',
                  'Dieses Tool visualisiert alle Screens der Anwendung und ihre Navigation-Verbindungen als interaktiven Graph.'),
              _buildInfoSection(C, 'Bedienung',
                  '• Klick auf Screen: Details anzeigen\n• Filter: Screens nach Kategorie filtern\n• Listenansicht: Alle Screens auflisten'),
              _buildInfoSection(C, 'Verbindungstypen',
                  '• Grün: Normale Navigation\n• Lila: Deep Link (mit Parametern)\n• Orange: Modal/Dialog\n• Blau: Button/Action'),
              _buildInfoSection(C, 'Screens',
                  '${_screens.length} Screens in ${_getUniqueCategories().length} Kategorien'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: C.green),
            child: const Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(AppColorsExtension C, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: _mysticalPurple, fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(content, style: TextStyle(color: C.amber, fontSize: 12)),
        ],
      ),
    );
  }

  List<String> _getUniqueCategories() {
    return _screens.values.map((s) => s.category).toSet().toList();
  }
}

class _GraphPainter extends CustomPainter {
  final List<ScreenNode> screens;
  final bool showConnections;
  final bool showParameters;
  final String selectedScreen;
  final Map<String, Color> categoryColors;
  final Map<ConnectionType, Color> connectionColors;
  final Color warningColor;
  final Color labelColor;
  final Function(String) onScreenTap;

  _GraphPainter({
    required this.screens,
    required this.showConnections,
    required this.showParameters,
    required this.selectedScreen,
    required this.categoryColors,
    required this.connectionColors,
    required this.warningColor,
    required this.labelColor,
    required this.onScreenTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (screens.isEmpty) return;
    final nodePositions = _calculateNodePositions(size);
    if (showConnections) {
      _drawConnections(canvas, nodePositions);
    }
    _drawNodes(canvas, nodePositions);
  }

  Map<String, Offset> _calculateNodePositions(Size size) {
    final positions = <String, Offset>{};
    final categoryGroups = <String, List<ScreenNode>>{};

    for (var screen in screens) {
      categoryGroups.putIfAbsent(screen.category, () => []).add(screen);
    }

    final categories = categoryGroups.keys.toList();
    const columns = 3;
    final columnWidth = size.width / columns;
    final rows = (categories.length / columns).ceil();
    final rowHeight = size.height / rows;

    for (var i = 0; i < categories.length; i++) {
      final category = categories[i];
      final categoryScreens = categoryGroups[category]!;
      final col = i % columns;
      final row = i ~/ columns;
      final categoryX = col * columnWidth + columnWidth / 2;
      final categoryY = row * rowHeight + rowHeight / 2;

      for (var j = 0; j < categoryScreens.length; j++) {
        final screen = categoryScreens[j];
        final angle = (2 * pi * j) / categoryScreens.length;
        const radius = 40.0;
        positions[screen.name] = Offset(
          categoryX + radius * cos(angle),
          categoryY + radius * sin(angle),
        );
      }
    }

    return positions;
  }

  void _drawConnections(Canvas canvas, Map<String, Offset> positions) {
    for (var screen in screens) {
      final fromPosition = positions[screen.name];
      if (fromPosition == null) continue;
      for (var connection in screen.connections) {
        final toPosition = positions[connection.targetScreen];
        if (toPosition != null) {
          final color = connectionColors[connection.type] ?? Colors.grey;
          final strokeWidth = switch (connection.type) {
            ConnectionType.navigation => 2.5,
            ConnectionType.deepLink => 3.0,
            ConnectionType.modal => 2.0,
            ConnectionType.action => 2.0,
          };
          final paint = Paint()
            ..color = color
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          canvas.drawLine(fromPosition, toPosition, paint);
          _drawArrow(canvas, fromPosition, toPosition, color, strokeWidth);
        }
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color, double strokeWidth) {
    final direction = to - from;
    final length = direction.distance;
    if (length < 20) return;

    final angle = direction.direction;
    const nodeRadius = 32.0;
    final arrowPoint = from + direction * ((length - nodeRadius) / length);
    const arrowLength = 12.0;
    const arrowAngle = 0.4;

    final leftWing = arrowPoint + Offset(cos(angle + pi - arrowAngle), sin(angle + pi - arrowAngle)) * arrowLength;
    final rightWing = arrowPoint + Offset(cos(angle + pi + arrowAngle), sin(angle + pi + arrowAngle)) * arrowLength;

    final path = Path()
      ..moveTo(arrowPoint.dx, arrowPoint.dy)
      ..lineTo(leftWing.dx, leftWing.dy)
      ..lineTo(rightWing.dx, rightWing.dy)
      ..close();

    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
    canvas.drawPath(path, Paint()..color = Colors.black..strokeWidth = 1.0..style = PaintingStyle.stroke);
  }

  void _drawNodes(Canvas canvas, Map<String, Offset> positions) {
    for (var screen in screens) {
      final position = positions[screen.name];
      if (position == null) continue;
      final isSelected = screen.name == selectedScreen;
      final color = categoryColors[screen.category] ?? Colors.grey;
      final radius = isSelected ? 35.0 : 30.0;

      canvas.drawCircle(position, radius, Paint()..color = color.withValues(alpha: 0.3)..style = PaintingStyle.fill);
      canvas.drawCircle(position, radius, Paint()..color = color..strokeWidth = isSelected ? 3.0 : 2.0..style = PaintingStyle.stroke);
      _drawText(canvas, screen.name, position, color, isSelected);

      if (showParameters && screen.requiresParameters) {
        canvas.drawCircle(
          position + Offset(radius * 0.7, -radius * 0.7),
          6,
          Paint()..color = warningColor..strokeWidth = 3.0..style = PaintingStyle.stroke,
        );
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, bool isSelected) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: labelColor,
          fontSize: isSelected ? 11 : 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          shadows: const [Shadow(color: Colors.black, blurRadius: 2, offset: Offset(0, 1))],
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 2,
      ellipsis: '...',
    );
    textPainter.layout();

    final textSize = textPainter.size;
    final textX = position.dx - textSize.width / 2;
    final textY = position.dy - textSize.height / 2;

    final bgRect = Rect.fromLTWH(textX - 2, textY - 2, textSize.width + 4, textSize.height + 4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bgRect, const Radius.circular(4)),
      Paint()..color = Colors.black.withValues(alpha: 0.7)..style = PaintingStyle.fill,
    );
    textPainter.paint(canvas, Offset(textX, textY));
  }

  @override
  bool shouldRepaint(_GraphPainter oldDelegate) {
    return oldDelegate.screens != screens ||
        oldDelegate.showConnections != showConnections ||
        oldDelegate.showParameters != showParameters ||
        oldDelegate.selectedScreen != selectedScreen;
  }
}
