import 'package:flutter/material.dart';

/// Wiederverwendbarer Empty State Widget
/// 
/// Zeigt einen konsistenten Leerer-Zustand mit optionalen Aktionen.
class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? action;
  final IconData? icon;
  final Color? iconColor;
  final bool showAction;

  const EmptyStateWidget({
    super.key,
    required this.title,
    this.message,
    this.action,
    this.icon,
    this.iconColor,
    this.showAction = true,
  });

  /// Empty State mit Standard-Icon und optionaler Aktion
  factory EmptyStateWidget.withAction({
    required String title,
    String? message,
    Widget? action,
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) {
    return EmptyStateWidget(
      key: key,
      title: title,
      message: message,
      icon: icon ?? Icons.folder_open,
      iconColor: iconColor ?? Colors.grey[600],
      action: action,
    );
  }

  /// Minimaler Empty State ohne Aktion
  factory EmptyStateWidget.minimal({
    required String title,
    String? message,
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) {
    return EmptyStateWidget(
      key: key,
      title: title,
      message: message,
      icon: icon ?? Icons.folder_open,
      iconColor: iconColor ?? Colors.grey[600],
      showAction: false,
    );
  }

  /// Empty State mit "Erstellen" Button
  factory EmptyStateWidget.withCreate({
    required String title,
    String? message,
    required VoidCallback onCreate,
    String buttonText = 'Erstellen',
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) {
    return EmptyStateWidget(
      key: key,
      title: title,
      message: message,
      icon: icon ?? Icons.folder_open,
      iconColor: iconColor ?? Colors.grey[600],
      action: ElevatedButton.icon(
        onPressed: onCreate,
        icon: const Icon(Icons.add),
        label: Text(buttonText),
      ),
    );
  }

  /// Empty State mit "Filter zurücksetzen" Button
  factory EmptyStateWidget.withClearFilters({
    required String title,
    String? message,
    required VoidCallback onClearFilters,
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) {
    return EmptyStateWidget(
      key: key,
      title: title,
      message: message,
      icon: icon ?? Icons.search_off,
      iconColor: iconColor ?? Colors.grey[600],
      action: ElevatedButton.icon(
        onPressed: onClearFilters,
        icon: const Icon(Icons.clear_all),
        label: const Text('Filter zurücksetzen'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon ?? Icons.folder_open,
              size: 64,
              color: iconColor ?? Colors.grey[600],
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor ?? Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (showAction && action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
