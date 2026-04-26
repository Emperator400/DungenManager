import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    required this.title,
    super.key,
    this.message,
    this.action,
    this.icon,
    this.iconColor,
  });

  final String title;
  final String? message;
  final Widget? action;
  final IconData? icon;
  final Color? iconColor;

  factory ErrorStateWidget.withRetry({
    required String title,
    required VoidCallback onRetry,
    String? message,
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) =>
      ErrorStateWidget(
        key: key,
        title: title,
        message: message,
        icon: icon ?? Icons.error_outline,
        iconColor: iconColor,
        action: ElevatedButton.icon(
          onPressed: onRetry,
          icon: const Icon(Icons.refresh),
          label: const Text('Erneut versuchen'),
        ),
      );

  factory ErrorStateWidget.minimal({
    required String title,
    String? message,
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) =>
      ErrorStateWidget(
        key: key,
        title: title,
        message: message,
        icon: icon ?? Icons.error_outline,
        iconColor: iconColor,
      );

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final effectiveColor = iconColor ?? C.red;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon ?? Icons.error_outline, size: 64, color: effectiveColor),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: effectiveColor),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: TextStyle(fontSize: 14, color: C.textMid),
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
