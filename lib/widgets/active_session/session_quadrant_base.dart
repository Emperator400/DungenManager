import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';

/// Basis-Widget für alle Quadranten im Active Session Screen
/// Bietet einheitliches Design mit Header, Gradient und Rahmen
class SessionQuadrantBase extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget content;

  const SessionQuadrantBase({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.slateGrey,
          endColor: DnDTheme.stoneGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(),
          // Content
          Expanded(
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: color.withValues(alpha: 0.8),
          endColor: color.withValues(alpha: 0.4),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(DnDTheme.radiusMedium),
          topRight: Radius.circular(DnDTheme.radiusMedium),
        ),
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 10,
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              title,
              style: DnDTheme.bodyText2.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 9,
              ),
            ),
          ),
        ],
      ),
    );
  }
}