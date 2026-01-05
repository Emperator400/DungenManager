import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Wiederverwendbarer Error State Widget
/// 
/// Zeigt einen konsistenten Fehlerzustand mit optionalen Aktionen.
class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String? message;
  final Widget? action;
  final IconData? icon;
  final Color? iconColor;

  const ErrorStateWidget({
    super.key,
    required this.title,
    this.message,
    this.action,
    this.icon,
    this.iconColor,
  });

  /// Standard Error mit "Erneut versuchen" Button
  factory ErrorStateWidget.withRetry({
    required String title,
    String? message,
    required VoidCallback onRetry,
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) {
    return ErrorStateWidget(
      key: key,
      title: title,
      message: message,
      icon: icon ?? Icons.error_outline,
      iconColor: iconColor ?? DnDTheme.errorRed,
      action: ElevatedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Erneut versuchen'),
      ),
    );
  }

  /// Minimaler Error ohne Aktion
  factory ErrorStateWidget.minimal({
    required String title,
    String? message,
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) {
    return ErrorStateWidget(
      key: key,
      title: title,
      message: message,
      icon: icon ?? Icons.error_outline,
      iconColor: iconColor ?? DnDTheme.errorRed,
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
              icon ?? Icons.error_outline,
              size: 64,
              color: iconColor ?? DnDTheme.errorRed,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: iconColor ?? DnDTheme.errorRed,
              ),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
