// lib/widgets/ui_components/shared/status_badge.dart
//
// StatusBadge nach UI_vorschrift:
//   done / erledigt  → grün
//   open / offen     → amber
//   aktiv            → accent blau
//   failed / failed  → rot

import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';

enum AppStatus { done, open, aktiv, failed }

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.status, {super.key, this.small = false});

  final AppStatus status;
  final bool small;

  static AppStatus fromString(String s) {
    switch (s.toLowerCase()) {
      case 'done':
      case 'erledigt':
      case 'abgeschlossen':
        return AppStatus.done;
      case 'aktiv':
      case 'active':
      case 'laufend':
        return AppStatus.aktiv;
      case 'failed':
      case 'fehlgeschlagen':
      case 'abandoned':
      case 'abgebrochen':
        return AppStatus.failed;
      default:
        return AppStatus.open;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final (Color fg, Color bg, String label) = switch (status) {
      AppStatus.done   => (c.green,  c.greenSoft,  'Erledigt'),
      AppStatus.open   => (c.amber,  c.amberSoft,  'Offen'),
      AppStatus.aktiv  => (c.accent, c.accentSoft, 'Aktiv'),
      AppStatus.failed => (c.red,    c.redSoft,    'Fehlgeschlagen'),
    };

    final fs = small ? 10.0 : 11.0;
    final px = small ? 6.0  : 8.0;
    final py = small ? 2.0  : 3.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: px, vertical: py),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: fs,
              fontWeight: FontWeight.w500,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
