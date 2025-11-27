import 'package:flutter/material.dart';
import '../../models/scene.dart';
import '../../models/sound_scene.dart';
import '../../models/session.dart';

/// Enhanced Scene Flow Widget mit modernem Design
class EnhancedSceneFlowWidget extends StatefulWidget {
  final Session session;
  final List<Scene> scenes;
  final List<SoundScene> soundScenes;
  final Function(Scene) onSceneSelected;
  final Function(Scene) onSceneEdit;
  final Function(Scene) onSceneDelete;
  final Function() onSceneAdd;

  const EnhancedSceneFlowWidget({
    super.key,
    required this.session,
    required this.scenes,
    required this.soundScenes,
    required this.onSceneSelected,
    required this.onSceneEdit,
    required this.onSceneDelete,
    required this.onSceneAdd,
  });

  @override
  State<EnhancedSceneFlowWidget> createState() => _EnhancedSceneFlowWidgetState();
}

class _EnhancedSceneFlowWidgetState extends State<EnhancedSceneFlowWidget>
    with TickerProviderStateMixin {
  late AnimationController _flowAnimationController;
  late Animation<double> _flowAnimation;
  String _searchQuery = '';
  SceneType? _selectedTypeFilter;
  bool _showCompletedOnly = false;

  @override
  void initState() {
    super.initState();
    _flowAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _flowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _flowAnimationController,
      curve: Curves.easeInOut,
    ));
    _flowAnimationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _flowAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildSearchAndFilters(context),
        Expanded(
          child: _buildSceneFlow(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.timeline,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scene Flow',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  widget.session.title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.layers,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${widget.scenes.length} Szenen',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: widget.onSceneAdd,
            mini: true,
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.background,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Szenen durchsuchen...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
            ),
          ),
          const SizedBox(height: 12),
          
          // Filter Chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                label: const Text('Alle'),
                selected: _selectedTypeFilter == null,
                onSelected: (_) => setState(() => _selectedTypeFilter = null),
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
              ),
              ...SceneType.values.map((type) {
                final color = _getSceneTypeColor(type);
                return FilterChip(
                  label: Text(type.toString().split('.').last),
                  selected: _selectedTypeFilter == type,
                  onSelected: (selected) => setState(() {
                    _selectedTypeFilter = selected ? type : null;
                  }),
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  selectedColor: color.withOpacity(0.2),
                  checkmarkColor: color,
                );
              }).toList(),
              FilterChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, size: 16),
                    const SizedBox(width: 4),
                    const Text('Abgeschlossen'),
                  ],
                ),
                selected: _showCompletedOnly,
                onSelected: (_) => setState(() => _showCompletedOnly = !_showCompletedOnly),
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedColor: Colors.green.withOpacity(0.2),
                checkmarkColor: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSceneFlow(BuildContext context) {
    final filteredScenes = _getFilteredScenes();
    
    if (filteredScenes.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredScenes.length,
      itemBuilder: (context, index) {
        final scene = filteredScenes[index];
        final soundScene = widget.soundScenes
            .where((ss) => ss.sceneId == scene.id)
            .firstOrNull;
        
        return Column(
          children: [
            if (index > 0) _buildConnectionLine(context, index, scene.isCompleted),
            _buildSceneCard(context, scene, soundScene, index),
          ],
        );
      },
    );
  }

  Widget _buildConnectionLine(BuildContext context, int index, bool isCompleted) {
    return AnimatedBuilder(
      animation: _flowAnimation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          height: 20,
          child: CustomPaint(
            painter: ConnectionLinePainter(
              progress: _flowAnimation.value,
              isCompleted: isCompleted,
              color: isCompleted 
                  ? Colors.green 
                  : Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSceneCard(BuildContext context, Scene scene, SoundScene? soundScene, int index) {
    final sceneTypeColor = _getSceneTypeColor(scene.sceneType);
    final hasSound = soundScene != null;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Card(
        elevation: scene.isCompleted ? 2 : 6,
        color: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: sceneTypeColor.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: () => widget.onSceneSelected(scene),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: scene.isCompleted
                  ? LinearGradient(
                      colors: [
                        Colors.green.withOpacity(0.1),
                        Colors.green.withOpacity(0.05),
                      ],
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with index and type
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: sceneTypeColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              scene.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: scene.isCompleted 
                                    ? Colors.green 
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              scene.sceneType.toString().split('.').last,
                              style: TextStyle(
                                fontSize: 12,
                                color: sceneTypeColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (scene.isCompleted)
                        Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      if (hasSound)
                        Icon(
                          Icons.music_note,
                          color: Colors.amber,
                          size: 20,
                        ),
                      PopupMenuButton<String>(
                        onSelected: (value) {
                          switch (value) {
                            case 'edit':
                              widget.onSceneEdit(scene);
                              break;
                            case 'delete':
                              _showDeleteConfirmation(context, scene);
                              break;
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, size: 16),
                                SizedBox(width: 8),
                                Text('Bearbeiten'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete, size: 16, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Löschen', style: TextStyle(color: Colors.red)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  if (scene.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      scene.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  
                  // Duration and additional info
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (scene.estimatedDuration != null) ...[
                        Icon(
                          Icons.schedule,
                          size: 16,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(scene.estimatedDuration!),
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                          ),
                        ),
                        const SizedBox(width: 16),
                      ],
                      if (scene.complexity != null) ...[
                        Icon(
                          Icons.signal_cellular_alt,
                          size: 16,
                          color: _getComplexityColor(scene.complexity!),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatComplexity(scene.complexity!),
                          style: TextStyle(
                            fontSize: 12,
                            color: _getComplexityColor(scene.complexity!),
                          ),
                        ),
                      ],
                      const Spacer(),
                      TextButton(
                        onPressed: () => widget.onSceneSelected(scene),
                        style: TextButton.styleFrom(
                          foregroundColor: sceneTypeColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        child: const Text('Starten'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.timeline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Keine Szenen gefunden',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedTypeFilter != null
                ? 'Versuche es mit anderen Filtern'
                : 'Erstelle deine erste Szene',
            style: TextStyle(
              fontSize: 14,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: widget.onSceneAdd,
            icon: const Icon(Icons.add),
            label: const Text('Szene hinzufügen'),
          ),
        ],
      ),
    );
  }

  List<Scene> _getFilteredScenes() {
    return widget.scenes.where((scene) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = scene.name.toLowerCase().contains(query);
        final descriptionMatch = scene.description.toLowerCase().contains(query);
        if (!nameMatch && !descriptionMatch) return false;
      }

      // Type filter
      if (_selectedTypeFilter != null && scene.sceneType != _selectedTypeFilter) {
        return false;
      }

      // Completed filter
      if (_showCompletedOnly && !scene.isCompleted) {
        return false;
      }

      return true;
    }).toList();
  }

  Color _getSceneTypeColor(SceneType type) {
    switch (type) {
      case SceneType.Introduction:
        return Colors.blue;
      case SceneType.Exploration:
        return Colors.green;
      case SceneType.Combat:
        return Colors.red;
      case SceneType.Social:
        return Colors.purple;
      case SceneType.Puzzle:
        return Colors.orange;
      case SceneType.Climax:
        return Colors.amber;
      case SceneType.Resolution:
        return Colors.teal;
    }
  }

  Color _getComplexityColor(Complexity complexity) {
    switch (complexity) {
      case Complexity.Easy:
        return Colors.green;
      case Complexity.Medium:
        return Colors.orange;
      case Complexity.Hard:
        return Colors.red;
      case Complexity.Legendary:
        return Colors.purple;
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}min';
    }
    return '${minutes}min';
  }

  String _formatComplexity(Complexity complexity) {
    switch (complexity) {
      case Complexity.Easy:
        return 'Einfach';
      case Complexity.Medium:
        return 'Mittel';
      case Complexity.Hard:
        return 'Schwer';
      case Complexity.Legendary:
        return 'Legendär';
    }
  }

  void _showDeleteConfirmation(BuildContext context, Scene scene) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Szene löschen'),
        content: Text(
          'Möchtest du die Szene "${scene.name}" wirklich löschen? Diese Aktion kann nicht rückgängig gemacht werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onSceneDelete(scene);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
  }
}

/// Custom Painter for animated connection lines
class ConnectionLinePainter extends CustomPainter {
  final double progress;
  final bool isCompleted;
  final Color color;

  ConnectionLinePainter({
    required this.progress,
    required this.isCompleted,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(isCompleted ? 1.0 : 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final path = Path();
    final startY = size.height / 2;
    final endY = size.height / 2;

    // Create a dotted line with animation
    path.moveTo(0, startY);
    
    if (isCompleted) {
      // Solid line for completed scenes
      path.lineTo(size.width, endY);
      canvas.drawPath(path, paint);
    } else {
      // Animated dotted line for active scenes
      const dashWidth = 8.0;
      const dashSpace = 4.0;
      final totalDashLength = dashWidth + dashSpace;
      
      double currentPosition = 0;
      while (currentPosition < size.width) {
        final dashEnd = (currentPosition + dashWidth).clamp(0.0, size.width);
        
        // Only draw dashes that should be visible based on progress
        final dashProgress = (currentPosition / size.width);
        if (dashProgress <= progress) {
          canvas.drawLine(
            Offset(currentPosition, startY),
            Offset(dashEnd, endY),
            paint,
          );
        }
        
        currentPosition += totalDashLength;
      }
    }

    // Draw arrow at the end
    if (progress > 0.8) {
      final arrowPaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.fill;

      final arrowPath = Path();
      arrowPath.moveTo(size.width - 8, startY - 4);
      arrowPath.lineTo(size.width, startY);
      arrowPath.lineTo(size.width - 8, startY + 4);
      arrowPath.close();

      canvas.drawPath(arrowPath, arrowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true; // Always repaint for animation
  }
}
