import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    required this.title,
    super.key,
    this.message,
    this.action,
    this.icon,
    this.iconColor,
    this.showAction = true,
  });

  final String title;
  final String? message;
  final Widget? action;
  final IconData? icon;
  final Color? iconColor;
  final bool showAction;

  factory EmptyStateWidget.withAction({
    required String title,
    String? message,
    Widget? action,
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) =>
      EmptyStateWidget(
        key: key,
        title: title,
        message: message,
        icon: icon ?? Icons.folder_open,
        iconColor: iconColor,
        action: action,
      );

  factory EmptyStateWidget.minimal({
    required String title,
    String? message,
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) =>
      EmptyStateWidget(
        key: key,
        title: title,
        message: message,
        icon: icon ?? Icons.folder_open,
        iconColor: iconColor,
        showAction: false,
      );

  factory EmptyStateWidget.withCreate({
    required String title,
    required VoidCallback onCreate,
    String? message,
    String buttonText = 'Erstellen',
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) =>
      EmptyStateWidget(
        key: key,
        title: title,
        message: message,
        icon: icon ?? Icons.folder_open,
        iconColor: iconColor,
        action: ElevatedButton.icon(
          onPressed: onCreate,
          icon: const Icon(Icons.add),
          label: Text(buttonText),
        ),
      );

  factory EmptyStateWidget.withClearFilters({
    required String title,
    required VoidCallback onClearFilters,
    String? message,
    IconData? icon,
    Color? iconColor,
    Key? key,
  }) =>
      EmptyStateWidget(
        key: key,
        title: title,
        message: message,
        icon: icon ?? Icons.search_off,
        iconColor: iconColor,
        action: ElevatedButton.icon(
          onPressed: onClearFilters,
          icon: const Icon(Icons.clear_all),
          label: const Text('Filter zurücksetzen'),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    final effectiveColor = iconColor ?? C.textSoft;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: math.max(0, constraints.maxHeight - 48)),
          child: IntrinsicHeight(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon ?? Icons.folder_open, size: 64, color: effectiveColor),
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
                    style: TextStyle(fontSize: 14, color: C.textSoft),
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
        ),
      ),
    );
  }
}
