import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../models/campaign.dart';
import '../../models/session.dart';

/// Zeigt Session-Informationen oben im Screen an
/// Zeigt Kampagne-Name, Session-Laufzeit und Aktiv-Status
class SessionInfoBar extends StatelessWidget {
  final Campaign campaign;
  final Session session;
  final String formattedInGameTime;

  const SessionInfoBar({
    super.key,
    required this.campaign,
    required this.session,
    required this.formattedInGameTime,
  });

  @override
  Widget build(BuildContext context) {
    final C = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: C.bgPanel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: C.amber.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Active Icon
          Container(
            decoration: BoxDecoration(
              color: C.amber,
              shape: BoxShape.circle,
              border: Border.all(
                color: C.bg,
                width: 2,
              ),
            ),
            child: Icon(
              Icons.play_circle_filled,
              color: Colors.black,
              size: 16,
            ),
          ),
          const SizedBox(width: 8),
          // Session Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kampagne: ${campaign.title}',
                  style: TextStyle(
                    fontSize: 12,
                    color: C.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Session-Laufzeit: $formattedInGameTime',
                  style: TextStyle(
                    fontSize: 9,
                    color: C.textMid,
                  ),
                ),
              ],
            ),
          ),
          // Status Badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            decoration: BoxDecoration(
              color: C.bgActive,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: C.amber.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer,
                  color: C.textMid,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Aktiv',
                  style: TextStyle(
                    fontSize: 9,
                    color: C.text,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}