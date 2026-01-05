import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Wiederverwendbarer Bestätigungsdialog
/// 
/// Bietet eine konsistente Benutzeroberfläche für Bestätigungsdialoge
/// mit optionalen Icons und verschiedenen Stilen.
class ConfirmationDialog {
  /// Zeigt einen einfachen Bestätigungsdialog
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'Bestätigen',
    String? cancelText,
    bool isDangerous = false,
    IconData? icon,
    Color? iconColor,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: iconColor),
              const SizedBox(width: 12),
            ],
            Expanded(child: Text(title)),
          ],
        ),
        content: message != null ? Text(message) : null,
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: isDangerous ? DnDTheme.errorRed : null,
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  /// Bestätigungsdialog für Lösch-Operationen
  static Future<bool?> showDelete({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'Löschen',
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: 'Abbrechen',
      isDangerous: true,
      icon: Icons.warning,
      iconColor: DnDTheme.errorRed,
    );
  }

  /// Bestätigungsdialog für Speicher-Operationen
  static Future<bool?> showSave({
    required BuildContext context,
    String title = 'Änderungen speichern?',
    String? message = 'Möchtest du die Änderungen speichern?',
    String confirmText = 'Speichern',
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: 'Verwerfen',
      isDangerous: false,
      icon: Icons.save,
      iconColor: DnDTheme.ancientGold,
    );
  }

  /// Bestätigungsdialog für Warnungen
  static Future<bool?> showWarning({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'Fortfahren',
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: 'Abbrechen',
      isDangerous: false,
      icon: Icons.warning,
      iconColor: Colors.orange,
    );
  }

  /// Bestätigungsdialog für Informations-Dialoge
  static Future<bool?> showInfo({
    required BuildContext context,
    required String title,
    String? message,
    String confirmText = 'OK',
    bool showCancel = false,
  }) {
    return show(
      context: context,
      title: title,
      message: message,
      confirmText: confirmText,
      cancelText: showCancel ? 'Abbrechen' : null,
      isDangerous: false,
      icon: Icons.info,
      iconColor: DnDTheme.infoBlue,
    );
  }
}
