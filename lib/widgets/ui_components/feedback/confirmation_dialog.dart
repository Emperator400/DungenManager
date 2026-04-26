import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class ConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'Bestätigen',
    String? cancelText,
    bool isDangerous = false,
  }) {
    final C = context.appColors;
    return showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: C.bgPanel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: C.border),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDangerous ? C.red : C.text,
                ),
              ),
              if (message != null) ...[
                const SizedBox(height: 10),
                Text(
                  message,
                  style: TextStyle(fontSize: 13, color: C.textMid),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (cancelText != null) ...[
                    OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: C.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                        ),
                      ),
                      child: Text(
                        cancelText,
                        style: TextStyle(color: C.textMid, fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  FilledButton(
                    onPressed: () => Navigator.of(ctx).pop(true),
                    style: FilledButton.styleFrom(
                      backgroundColor: isDangerous ? C.red : C.accent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: Text(confirmText, style: const TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<bool?> showDelete({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'Löschen',
  }) =>
      show(
        context: context,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: 'Abbrechen',
        isDangerous: true,
      );

  static Future<bool?> showSave({
    required BuildContext context,
    String title = 'Änderungen speichern?',
    String? message = 'Möchtest du die Änderungen speichern?',
    String confirmText = 'Speichern',
  }) =>
      show(
        context: context,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: 'Verwerfen',
      );

  static Future<bool?> showWarning({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'Fortfahren',
  }) =>
      show(
        context: context,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: 'Abbrechen',
      );

  static Future<bool?> showInfo({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'OK',
    bool showCancel = false,
  }) =>
      show(
        context: context,
        title: title,
        message: message,
        confirmText: confirmText,
        cancelText: showCancel ? 'Abbrechen' : null,
      );
}
