import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/dnd_theme.dart';
import '../models/screen_node.dart';
import '../services/screen_graph_service.dart';

/// Screen für die interaktive Visualisierung aller Screens und ihrer Navigation-Verbindungen
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
    return Scaffold(
      backgroundColor: DnDTheme.dungeonBlack,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildFilterBar(context),
          Expanded(
            child: _screens.isEmpty
                ? _buildLoadingIndicator()
                : Row(
                    children: [
                      Expanded(
                        child: _buildGraphArea(),
                      ),
                      if (_selectedScreen.isNotEmpty) _buildScreenDetails(),
                    ],
                  ),
          ),
          _buildLegend(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Screen Navigation Graph',
            style: TextStyle(
              color: DnDTheme.ancientGold,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            '${_screens.length} Screens mit Navigation-Verbindungen',
            style: TextStyle(
              color: DnDTheme.ancientGold.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
      backgroundColor: DnDTheme.mysticalPurple,
      elevation: 4,
      actions: [
        IconButton(
          icon: Icon(
            _showConnections ? Icons.link : Icons.link_off,
            color: DnDTheme.ancientGold,
          ),
          onPressed: () {
            setState(() {
              _showConnections = !_showConnections;
            });
          },
          tooltip: 'Verbindungen anzeigen/ausblenden',
        ),
        IconButton(
          icon: Icon(
            _showParameters ? Icons.visibility : Icons.visibility_off,
            color: DnDTheme.ancientGold,
          ),
          onPressed: () {
            setState(() {
              _showParameters = !_showParameters;
            });
          },
          tooltip: 'Parameter anzeigen/ausblenden',
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: DnDTheme.ancientGold),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'refresh',
              child: Row(
                children: [
                  Icon(Icons.refresh, color: DnDTheme.emeraldGreen),
                  SizedBox(width: 8),
                  Text('Aktualisieren'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'listView',
              child: Row(
                children: [
                  Icon(Icons.list, color: DnDTheme.emeraldGreen),
                  SizedBox(width: 8),
                  Text('Listenansicht'),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'info',
              child: Row(
                children: [
                  Icon(Icons.info, color: DnDTheme.emeraldGreen),
                  SizedBox(width: 8),
                  Text('Info'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: DnDTheme.mysticalPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildFilterChip('All', Icons.all_inclusive),
            SizedBox(width: DnDTheme.sm),
            _buildFilterChip('Navigation', Icons.navigation),
            SizedBox(width: DnDTheme.sm),
            _buildFilterChip('Campaign', Icons.campaign),
            SizedBox(width: DnDTheme.sm),
            _buildFilterChip('Quest Management', Icons.assignment),
            SizedBox(width: DnDTheme.sm),
            _buildFilterChip('Wiki/Lore', Icons.menu_book),
            SizedBox(width: DnDTheme.sm),
            _buildFilterChip('Character', Icons.person),
            SizedBox(width: DnDTheme.sm),
            _buildFilterChip('Bestiary', Icons.pets),
            SizedBox(width: DnDTheme.sm),
            _buildFilterChip('Item', Icons.inventory_2),
            SizedBox(width: DnDTheme.sm),
            _buildFilterChip('Audio', Icons.music_note),
            SizedBox(width: DnDTheme.sm),
            _buildFilterChip('Session', Icons.play_circle),
            SizedBox(width: DnDTheme.sm),
            _buildFilterChip('Utility', Icons.build),
            SizedBox(width: DnDTheme.sm),
            _buildFilterChip('Testing', Icons.bug_report),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String category, IconData icon) {
    final isSelected = _selectedCategory == category;
    return FilterChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: isSelected ? DnDTheme.dungeonBlack : DnDTheme.ancientGold),
          SizedBox(width: 4),
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
      selectedColor: DnDTheme.mysticalPurple,
      backgroundColor: DnDTheme.stoneGrey.withOpacity(0.3),
      labelStyle: TextStyle(
        color: isSelected ? DnDTheme.dungeonBlack : DnDTheme.ancientGold,
      ),
    );
  }

  Widget _buildGraphArea() {
    final screens = _filteredScreens;
    
    return CustomPaint(
      painter: _GraphPainter(
        screens: screens,
        showConnections: _showConnections,
        showParameters: _showParameters,
        selectedScreen: _selectedScreen,
        categoryColors: _getCategoryColors(),
        connectionColors: {
          ConnectionType.navigation: DnDTheme.emeraldGreen,
          ConnectionType.modal: DnDTheme.warningOrange,
          ConnectionType.deepLink: DnDTheme.mysticalPurple,
          ConnectionType.action: DnDTheme.infoBlue,
        },
        onScreenTap: (screenName) {
          setState(() {
            _selectedScreen = _selectedScreen == screenName ? '' : screenName;
          });
        },
      ),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: DnDTheme.dungeonBlack.withOpacity(0.3),
      ),
    );
  }

  Widget _buildScreenDetails() {
    final screen = _screens[_selectedScreen];
    if (screen == null) return const SizedBox();

    return Container(
      width: 350,
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey.withOpacity(0.9),
        border: Border(
          left: BorderSide(
            color: DnDTheme.mysticalPurple,
            width: 2,
          ),
        ),
      ),
      child: ListView(
        padding: EdgeInsets.all(DnDTheme.md),
        children: [
          Row(
            children: [
              Icon(
                _getCategoryIcon(screen.category),
                color: _getCategoryColor(screen.category),
                size: 24,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  screen.name,
                  style: TextStyle(
                    color: DnDTheme.ancientGold,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: DnDTheme.ancientGold),
                onPressed: () => setState(() => _selectedScreen = ''),
              ),
            ],
          ),
          Divider(color: DnDTheme.mysticalPurple.withOpacity(0.3)),
          SizedBox(height: DnDTheme.md),
          _buildDetailRow('Dateiname', screen.fileName),
          SizedBox(height: DnDTheme.sm),
          _buildDetailRow('Kategorie', screen.category),
          SizedBox(height: DnDTheme.md),
          if (screen.requiresParameters) ...[
            Container(
              padding: EdgeInsets.all(DnDTheme.sm),
              decoration: BoxDecoration(
                color: DnDTheme.warningOrange.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: DnDTheme.warningOrange.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: DnDTheme.warningOrange, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      screen.parameterInfo ?? 'Benötigt Parameter',
                      style: TextStyle(color: DnDTheme.warningOrange),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: DnDTheme.md),
          ],
          Text(
            'Verbindungen (${screen.connections.length})',
            style: TextStyle(
              color: DnDTheme.ancientGold,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: DnDTheme.sm),
          ...screen.connections.map((conn) => _buildConnectionCard(conn)),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label + ':',
            style: TextStyle(
              color: DnDTheme.ancientGold.withOpacity(0.7),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(color: DnDTheme.ancientGold),
          ),
        ),
      ],
    );
  }

  Widget _buildConnectionCard(ScreenConnection connection) {
    return Container(
      margin: EdgeInsets.only(bottom: DnDTheme.sm),
      padding: EdgeInsets.all(DnDTheme.sm),
      decoration: BoxDecoration(
        color: _getConnectionColor(connection.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _getConnectionColor(connection.type).withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(_getConnectionIcon(connection.type), size: 16, color: _getConnectionColor(connection.type)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  connection.targetScreen,
                  style: TextStyle(
                    color: DnDTheme.ancientGold,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          if (connection.triggerAction != null) ...[
            SizedBox(height: 4),
            Text(
              'Trigger: ${connection.triggerAction}',
              style: TextStyle(
                color: DnDTheme.ancientGold.withOpacity(0.7),
                fontSize: 12,
              ),
            ),
          ],
          if (connection.description != null) ...[
            SizedBox(height: 2),
            Text(
              connection.description!,
              style: TextStyle(
                color: DnDTheme.ancientGold.withOpacity(0.5),
                fontSize: 11,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegend() {
    return Container(
      padding: EdgeInsets.all(DnDTheme.md),
      decoration: BoxDecoration(
        color: DnDTheme.stoneGrey.withOpacity(0.3),
        border: Border(
          top: BorderSide(
            color: DnDTheme.mysticalPurple.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Legende',
            style: TextStyle(
              color: DnDTheme.ancientGold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: DnDTheme.sm),
          Wrap(
            spacing: DnDTheme.md,
            runSpacing: DnDTheme.sm,
            children: [
              _buildLegendItem('Navigation', DnDTheme.emeraldGreen),
              _buildLegendItem('Deep Link', DnDTheme.mysticalPurple),
              _buildLegendItem('Modal', DnDTheme.warningOrange),
              _buildLegendItem('Action', DnDTheme.infoBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 20,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: DnDTheme.ancientGold,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(DnDTheme.ancientGold),
          ),
          SizedBox(height: DnDTheme.md),
          Text(
            'Lade Screens...',
            style: TextStyle(
              color: DnDTheme.ancientGold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    final colors = _getCategoryColors();
    return colors[category] ?? DnDTheme.stoneGrey;
  }

  Map<String, Color> _getCategoryColors() {
    return {
      'Navigation': DnDTheme.mysticalPurple,
      'Campaign': DnDTheme.ancientGold,
      'Quest Management': DnDTheme.emeraldGreen,
      'Wiki/Lore': DnDTheme.infoBlue,
      'Character': DnDTheme.warningOrange,
      'Bestiary': DnDTheme.deepRed,
      'Item': DnDTheme.stoneGrey,
      'Audio': DnDTheme.infoBlue,
      'Session': DnDTheme.emeraldGreen,
      'Utility': DnDTheme.warningOrange,
      'Testing': DnDTheme.mysticalPurple,
    };
  }

  Color _getConnectionColor(ConnectionType type) {
    switch (type) {
      case ConnectionType.navigation:
        return DnDTheme.emeraldGreen;
      case ConnectionType.modal:
        return DnDTheme.warningOrange;
      case ConnectionType.deepLink:
        return DnDTheme.mysticalPurple;
      case ConnectionType.action:
        return DnDTheme.infoBlue;
    }
  }

  IconData _getConnectionIcon(ConnectionType type) {
    switch (type) {
      case ConnectionType.navigation:
        return Icons.arrow_forward;
      case ConnectionType.modal:
        return Icons.open_in_new;
      case ConnectionType.deepLink:
        return Icons.link;
      case ConnectionType.action:
        return Icons.touch_app;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Navigation':
        return Icons.navigation;
      case 'Campaign':
        return Icons.campaign;
      case 'Quest Management':
        return Icons.assignment;
      case 'Wiki/Lore':
        return Icons.menu_book;
      case 'Character':
        return Icons.person;
      case 'Bestiary':
        return Icons.pets;
      case 'Item':
        return Icons.inventory_2;
      case 'Audio':
        return Icons.music_note;
      case 'Session':
        return Icons.play_circle;
      case 'Utility':
        return Icons.build;
      case 'Testing':
        return Icons.bug_report;
      default:
        return Icons.screen_share;
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'refresh':
        _loadScreens();
        break;
      case 'listView':
        _showListView();
        break;
      case 'info':
        _showInfoDialog();
        break;
    }
  }

  void _showListView() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Text(
          'Alle Screens',
          style: TextStyle(color: DnDTheme.ancientGold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _screens.length,
            itemBuilder: (context, index) {
              final screen = _screens.values.elementAt(index);
              return ListTile(
                leading: Icon(
                  _getCategoryIcon(screen.category),
                  color: _getCategoryColor(screen.category),
                ),
                title: Text(
                  screen.name,
                  style: TextStyle(color: DnDTheme.ancientGold),
                ),
                subtitle: Text(
                  '${screen.fileName} • ${screen.category}',
                  style: TextStyle(color: DnDTheme.ancientGold.withOpacity(0.7)),
                ),
                trailing: screen.requiresParameters
                    ? Icon(Icons.warning, color: DnDTheme.warningOrange, size: 20)
                    : null,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: DnDTheme.emeraldGreen),
            child: Text('Schließen'),
          ),
        ],
      ),
    );
  }

  void _showInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DnDTheme.stoneGrey,
        title: Row(
          children: [
            Icon(Icons.info, color: DnDTheme.mysticalPurple),
            SizedBox(width: 8),
            Text(
              'Screen Graph Visualizer',
              style: TextStyle(color: DnDTheme.ancientGold),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection(
                'Was ist das?',
                'Dieses Tool visualisiert alle Screens der Anwendung und ihre Navigation-Verbindungen als interaktiven Graph.',
              ),
              _buildInfoSection(
                'Bedienung',
                '• Klick auf Screen: Details anzeigen\n• Filter: Screens nach Kategorie filtern\n• Listenansicht: Alle Screens auflisten',
              ),
              _buildInfoSection(
                'Verbindungstypen',
                '• Grün: Normale Navigation\n• Lila: Deep Link (mit Parametern)\n• Orange: Modal/Dialog\n• Blau: Button/Action',
              ),
              _buildInfoSection(
                'Screens',
                '${_screens.length} Screens in ${_getUniqueCategories().length} Kategorien',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(foregroundColor: DnDTheme.emeraldGreen),
            child: Text('Verstanden'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: EdgeInsets.only(bottom: DnDTheme.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: DnDTheme.mysticalPurple,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          SizedBox(height: 4),
          Text(
            content,
            style: TextStyle(
              color: DnDTheme.ancientGold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getUniqueCategories() {
    return _screens.values.map((s) => s.category).toSet().toList();
  }
}

/// Custom Painter für die Graph-Visualisierung
class _GraphPainter extends CustomPainter {
  final List<ScreenNode> screens;
  final bool showConnections;
  final bool showParameters;
  final String selectedScreen;
  final Map<String, Color> categoryColors;
  final Map<ConnectionType, Color> connectionColors;
  final Function(String) onScreenTap;

  _GraphPainter({
    required this.screens,
    required this.showConnections,
    required this.showParameters,
    required this.selectedScreen,
    required this.categoryColors,
    required this.connectionColors,
    required this.onScreenTap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (screens.isEmpty) return;

    final nodePositions = _calculateNodePositions(size);
    
    // Verbindungen zeichnen
    if (showConnections) {
      _drawConnections(canvas, nodePositions);
    }
    
    // Knoten zeichnen
    _drawNodes(canvas, nodePositions);
  }

  Map<String, Offset> _calculateNodePositions(Size size) {
    final positions = <String, Offset>{};
    final categoryGroups = <String, List<ScreenNode>>{};
    
    // Screens nach Kategorie gruppieren
    for (var screen in screens) {
      categoryGroups.putIfAbsent(screen.category, () => []).add(screen);
    }
    
    final categories = categoryGroups.keys.toList();
    final columns = 3;
    final columnWidth = size.width / columns;
    final rows = ((categories.length / columns).ceil());
    final rowHeight = size.height / rows;
    
    // Positionen berechnen
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
        final radius = 40.0;
        
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
        // Nur exakte Übereinstimmung akzeptieren
        final toPosition = positions[connection.targetScreen];
        
        // Nur zeichnen wenn Ziel-Screen existiert
        if (toPosition != null) {
          // Verbindungstyp bestimmen
          final connectionType = connection.type;
          final color = connectionColors[connectionType] ?? Colors.grey;
          
          // Linienstärke je nach Verbindungstyp
          final strokeWidth = switch (connectionType) {
            ConnectionType.navigation => 2.5,
            ConnectionType.deepLink => 3.0,
            ConnectionType.modal => 2.0,
            ConnectionType.action => 2.0,
          };
          
          // Linie zeichnen
          final paint = Paint()
            ..color = color
            ..strokeWidth = strokeWidth
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round;
          
          canvas.drawLine(fromPosition, toPosition, paint);
          
          // Pfeilspitze zeichnen
          _drawArrow(canvas, fromPosition, toPosition, color, strokeWidth);
        }
      }
    }
  }

  void _drawArrow(Canvas canvas, Offset from, Offset to, Color color, double strokeWidth) {
    final direction = (to - from);
    final length = direction.distance;
    if (length < 20) return;
    
    final angle = direction.direction;
    final nodeRadius = 32.0; // Etwas größer als die Knoten
    
    // Pfeil am Rand des Zielknotens starten lassen
    final arrowPoint = from + direction * ((length - nodeRadius) / length);
    final arrowLength = 12.0;
    final arrowAngle = 0.4; // Schärferer Winkel
    
    // Linke Flügel
    final leftWing = arrowPoint + Offset(
      cos(angle + pi - arrowAngle),
      sin(angle + pi - arrowAngle),
    ) * arrowLength;
    
    // Rechte Flügel
    final rightWing = arrowPoint + Offset(
      cos(angle + pi + arrowAngle),
      sin(angle + pi + arrowAngle),
    ) * arrowLength;
    
    // Pfeil zeichnen
    final path = Path()
      ..moveTo(arrowPoint.dx, arrowPoint.dy)
      ..lineTo(leftWing.dx, leftWing.dy)
      ..lineTo(rightWing.dx, rightWing.dy)
      ..close();
    
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, paint);
    
    // Schwarzen Rand um Pfeil für bessere Sichtbarkeit
    final borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawPath(path, borderPaint);
  }

  void _drawNodes(Canvas canvas, Map<String, Offset> positions) {
    for (var screen in screens) {
      final position = positions[screen.name];
      if (position == null) continue;
      
      final isSelected = screen.name == selectedScreen;
      final color = categoryColors[screen.category] ?? Colors.grey;
      final radius = isSelected ? 35.0 : 30.0;
      
      // Kreis zeichnen
      final paint = Paint()
        ..color = color.withOpacity(0.3)
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(position, radius, paint);
      
      // Rahmen zeichnen
      final borderPaint = Paint()
        ..color = color
        ..strokeWidth = isSelected ? 3.0 : 2.0
        ..style = PaintingStyle.stroke;
      
      canvas.drawCircle(position, radius, borderPaint);
      
      // Screen-Name zeichnen
      _drawText(canvas, screen.name, position, color, isSelected);
      
      // Parameter-Indikator
      if (showParameters && screen.requiresParameters) {
        final paramPaint = Paint()
          ..color = DnDTheme.warningOrange
          ..strokeWidth = 3.0
          ..style = PaintingStyle.stroke;
        
        canvas.drawCircle(position + Offset(radius * 0.7, -radius * 0.7), 6, paramPaint);
      }
    }
  }

  void _drawText(Canvas canvas, String text, Offset position, Color color, bool isSelected) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: DnDTheme.ancientGold,
          fontSize: isSelected ? 11 : 10,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          shadows: [
            Shadow(
              color: Colors.black,
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
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

    // Hintergrund für Text
    final bgPaint = Paint()
      ..color = Colors.black.withOpacity(0.7)
      ..style = PaintingStyle.fill;
    
    final bgRect = Rect.fromLTWH(
      textX - 2,
      textY - 2,
      textSize.width + 4,
      textSize.height + 4,
    );
    
    final rRect = RRect.fromRectAndRadius(bgRect, Radius.circular(4));
    canvas.drawRRect(rRect, bgPaint);
    
    // Text zeichnen
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
