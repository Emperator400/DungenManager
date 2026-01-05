import 'package:flutter/material.dart';

/// Widget für Metadaten-Informationen in Cards
/// 
/// Zeigt Datum, Status, Priorität und andere Metadaten
class CardMetadataWidget extends StatelessWidget {
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? status;
  final String? priority;
  final int? itemCount;
  final Map<String, String>? customMetadata;

  const CardMetadataWidget({
    super.key,
    this.createdAt,
    this.updatedAt,
    this.status,
    this.priority,
    this.itemCount,
    this.customMetadata,
  });

  @override
  Widget build(BuildContext context) {
    final metadataItems = _buildMetadataItems();

    if (metadataItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 4,
        children: metadataItems,
      ),
    );
  }

  List<Widget> _buildMetadataItems() {
    final items = <Widget>[];

    if (createdAt != null) {
      items.add(_buildMetadataItem(
        Icons.calendar_today,
        _formatDate(createdAt!),
        'Erstellt am',
      ));
    }

    if (updatedAt != null) {
      items.add(_buildMetadataItem(
        Icons.update,
        _formatDate(updatedAt!),
        'Zuletzt aktualisiert',
      ));
    }

    if (status != null) {
      items.add(_buildStatusChip(status!));
    }

    if (priority != null) {
      items.add(_buildPriorityChip(priority!));
    }

    if (itemCount != null) {
      items.add(_buildMetadataItem(
        Icons.list,
        '$itemCount Einträge',
        'Anzahl',
      ));
    }

    if (customMetadata != null) {
      customMetadata!.forEach((key, value) {
        items.add(_buildMetadataItem(
          Icons.info_outline,
          value,
          key,
        ));
      });
    }

    return items;
  }

  Widget _buildMetadataItem(IconData icon, String value, String tooltip) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getStatusColor(status).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getStatusColor(status).withOpacity(0.3),
        ),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 11,
          color: _getStatusColor(status),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPriorityChip(String priority) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getPriorityColor(priority).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getPriorityColor(priority).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPriorityIcon(priority),
            size: 10,
            color: _getPriorityColor(priority),
          ),
          const SizedBox(width: 4),
          Text(
            priority,
            style: TextStyle(
              fontSize: 11,
              color: _getPriorityColor(priority),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final lowerStatus = status.toLowerCase();
    if (lowerStatus.contains('aktiv') || lowerStatus.contains('active')) {
      return Colors.green;
    } else if (lowerStatus.contains('pending') || lowerStatus.contains('wartet')) {
      return Colors.orange;
    } else if (lowerStatus.contains('komplett') || lowerStatus.contains('complete')) {
      return Colors.blue;
    } else if (lowerStatus.contains('archiv')) {
      return Colors.grey;
    }
    return Colors.purple;
  }

  Color _getPriorityColor(String priority) {
    final lowerPriority = priority.toLowerCase();
    if (lowerPriority.contains('hoch') || lowerPriority.contains('high')) {
      return Colors.red;
    } else if (lowerPriority.contains('mittel') || lowerPriority.contains('medium')) {
      return Colors.orange;
    } else if (lowerPriority.contains('niedrig') || lowerPriority.contains('low')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  IconData _getPriorityIcon(String priority) {
    final lowerPriority = priority.toLowerCase();
    if (lowerPriority.contains('hoch') || lowerPriority.contains('high')) {
      return Icons.arrow_upward;
    } else if (lowerPriority.contains('niedrig') || lowerPriority.contains('low')) {
      return Icons.arrow_downward;
    }
    return Icons.remove;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return 'Heute';
      }
      return 'Heute';
    } else if (difference.inDays == 1) {
      return 'Gestern';
    } else if (difference.inDays < 7) {
      return 'Vor ${difference.inDays} Tagen';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}
