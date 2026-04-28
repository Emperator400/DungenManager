import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class SessionQuadrantBase extends StatelessWidget {
  const SessionQuadrantBase({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildHeader(),
          Flexible(child: content),
        ],
      ),
    );
  }

  Widget _buildHeader() => Container(
    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.85),
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(12),
        topRight: Radius.circular(12),
      ),
    ),
    child: Row(
      children: [
        Container(
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.9), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 10),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 9),
          ),
        ),
      ],
    ),
  );
}