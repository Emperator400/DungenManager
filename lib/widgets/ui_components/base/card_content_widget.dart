import 'package:flutter/material.dart';

/// Flexibler Content-Container für Cards
/// 
/// Unterstützt Beschreibung, Tags und zusätzliche Inhalte
class CardContentWidget extends StatelessWidget {
  final String description;
  final int descriptionMaxLines;
  final List<String>? tags;
  final List<Widget>? additionalContent;
  final VoidCallback? onTagTap;

  const CardContentWidget({
    super.key,
    required this.description,
    this.descriptionMaxLines = 3,
    this.tags,
    this.additionalContent,
    this.onTagTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Beschreibung
        Text(
          description,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            height: 1.4,
          ),
          maxLines: descriptionMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
        
        // Zusätzlicher Inhalt
        if (additionalContent != null && additionalContent!.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...additionalContent!,
        ],
        
        // Tags
        if (tags != null && tags!.isNotEmpty) ...[
          const SizedBox(height: 8),
          _buildTags(context),
        ],
      ],
    );
  }

  Widget _buildTags(BuildContext context) {
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tags!.take(4).map((tag) => _buildTagChip(context, tag)).toList(),
    );
  }

  Widget _buildTagChip(BuildContext context, String tag) {
    return GestureDetector(
      onTap: onTagTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).primaryColor.withOpacity(0.3),
          ),
        ),
        child: Text(
          tag,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
