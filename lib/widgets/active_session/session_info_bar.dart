import 'package:flutter/material.dart';
import '../../theme/dnd_theme.dart';
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: DnDTheme.sm, vertical: 4),
      decoration: BoxDecoration(
        gradient: DnDTheme.getMysticalGradient(
          startColor: DnDTheme.stoneGrey,
          endColor: DnDTheme.slateGrey,
        ),
        borderRadius: BorderRadius.circular(DnDTheme.radiusMedium),
        border: Border.all(
          color: DnDTheme.ancientGold.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          // Active Icon
          Container(
            decoration: BoxDecoration(
              color: DnDTheme.ancientGold,
              shape: BoxShape.circle,
              border: Border.all(
                color: DnDTheme.stoneGrey,
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.play_circle_filled,
              color: DnDTheme.dungeonBlack,
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
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                Text(
                  'Session-Laufzeit: $formattedInGameTime',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white70,
                    fontSize: 9,
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
              gradient: DnDTheme.getMysticalGradient(
                startColor: DnDTheme.arcaneBlue,
                endColor: DnDTheme.mysticalPurple,
              ),
              borderRadius: BorderRadius.circular(DnDTheme.radiusSmall),
              border: Border.all(
                color: DnDTheme.ancientGold.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.timer,
                  color: Colors.white,
                  size: 12,
                ),
                const SizedBox(width: DnDTheme.xs),
                Text(
                  'Aktiv',
                  style: DnDTheme.bodyText2.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 9,
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