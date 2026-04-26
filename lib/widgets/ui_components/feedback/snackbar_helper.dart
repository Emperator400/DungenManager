import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';
import '../shared/app_icon.dart';

class SnackBarHelper {
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final C = context.appColors;
    _show(context, message, C.green, AppIconName.check, duration);
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final C = context.appColors;
    _show(context, message, C.red, AppIconName.error, duration);
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final C = context.appColors;
    _show(context, message, C.amber, AppIconName.warning, duration);
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    final C = context.appColors;
    _show(context, message, C.accent, AppIconName.info, duration);
  }

  static void showWithAction(
    BuildContext context,
    String message,
    String actionLabel,
    VoidCallback onAction, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    final C = context.appColors;
    final bg = backgroundColor ?? C.accent;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.white),
        ),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
      ),
    );
  }

  static void showDeleteWithUndo(
    BuildContext context,
    String message,
    VoidCallback onUndo, {
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
  }) {
    final C = context.appColors;
    showWithAction(
      context,
      message,
      'Rückgängig',
      onUndo,
      backgroundColor: backgroundColor ?? C.red,
      duration: duration,
    );
  }

  static void clear(BuildContext context) =>
      ScaffoldMessenger.of(context).clearSnackBars();

  static void hideCurrent(BuildContext context) =>
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

  static void _show(
    BuildContext context,
    String message,
    Color bg,
    AppIconName icon,
    Duration duration,
  ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            AppIcon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bg,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
      ),
    );
  }
}
