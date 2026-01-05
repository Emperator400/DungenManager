import 'package:flutter/material.dart';
import '../../../theme/dnd_theme.dart';

/// Helper-Klasse für konsistente SnackBar-Nachrichten
/// 
/// Bietet statische Methoden für verschiedene SnackBar-Typen
/// mit automatischer Anzeige und Konfiguration.
class SnackBarHelper {
  /// Zeigt eine Standard-Erfolgsmeldung
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: DnDTheme.emeraldGreen,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: DnDTheme.emeraldGreen.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        elevation: 8,
      ),
    );
  }

  /// Zeigt eine Fehlermeldung
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: DnDTheme.deepRed,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: DnDTheme.deepRed.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        elevation: 8,
      ),
    );
  }

  /// Zeigt eine Warnung
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.warning, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: DnDTheme.warningOrange,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: DnDTheme.warningOrange.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        elevation: 8,
      ),
    );
  }

  /// Zeigt eine Info-Nachricht
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info, color: Colors.white),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: DnDTheme.arcaneBlue,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: DnDTheme.arcaneBlue.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        elevation: 8,
      ),
    );
  }

  /// Zeigt eine SnackBar mit benutzerdefinierter Aktion
  static void showWithAction(
    BuildContext context,
    String message,
    String actionLabel,
    VoidCallback onAction, {
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 4),
  }) {
    final bgColor = backgroundColor ?? DnDTheme.mysticalPurple;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: bgColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: bgColor.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        elevation: 8,
        action: SnackBarAction(
          label: actionLabel,
          textColor: Colors.white,
          onPressed: onAction,
        ),
      ),
    );
  }

  /// Zeigt eine Lösch-Bestätigung mit Undo-Option
  static void showDeleteWithUndo(
    BuildContext context,
    String message,
    VoidCallback onUndo, {
    Duration duration = const Duration(seconds: 4),
    Color? backgroundColor,
  }) {
    showWithAction(
      context,
      message,
      'Rückgängig',
      onUndo,
      backgroundColor: backgroundColor ?? DnDTheme.deepRed,
      duration: duration,
    );
  }

  /// Entfernt alle aktuellen SnackBars
  static void clear(BuildContext context) {
    ScaffoldMessenger.of(context).clearSnackBars();
  }

  /// Entfernt die oberste SnackBar
  static void hideCurrent(BuildContext context) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
  }
}
