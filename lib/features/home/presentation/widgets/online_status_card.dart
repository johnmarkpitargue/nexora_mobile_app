import 'package:flutter/material.dart';
import '../../../../core/theme/rider_theme.dart';
import '../../../../core/services/rider_service.dart';

class OnlineStatusCard extends StatelessWidget {
  const OnlineStatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: RiderService.instance,
      builder: (context, _) {
        final profile = RiderService.instance.profile;
        final isOnline = profile.isOnline;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isOnline
                  ? [RiderTheme.darkNavy, const Color(0xFF13224F)]
                  : [const Color(0xFF1E293B), const Color(0xFF0F172A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: isOnline
                    ? RiderTheme.primary.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isOnline
                          ? RiderTheme.onlineGreen.withValues(alpha: 0.15)
                          : Colors.grey.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isOnline
                              ? RiderTheme.onlineGreen
                              : RiderTheme.textMuted,
                          shape: BoxShape.circle,
                          boxShadow: isOnline
                              ? [
                                  BoxShadow(
                                    color: RiderTheme.onlineGreen.withValues(alpha: 0.8),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              isOnline ? 'ON DUTY' : 'OFFLINE',
                              style: TextStyle(
                                color: isOnline
                                    ? RiderTheme.onlineGreen
                                    : RiderTheme.textLight,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 1.1,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '${profile.onlineHoursToday} hrs today',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isOnline
                              ? 'Searching orders in ${profile.assignedHub.split('#').first.trim()}...'
                              : 'Go online to start receiving delivery requests',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isOnline,
                    activeThumbColor: RiderTheme.onlineGreen,
                    activeTrackColor: RiderTheme.onlineGreen.withValues(alpha: 0.35),
                    inactiveThumbColor: Colors.white70,
                    inactiveTrackColor: Colors.white24,
                    onChanged: (val) {
                      RiderService.instance.toggleOnlineStatus();
                    },
                  ),
                ],
              ),
              if (isOnline) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.two_wheeler_rounded,
                              size: 16, color: RiderTheme.secondary),
                          const SizedBox(width: 6),
                          Text(
                            profile.vehicleModel,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: RiderTheme.secondary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          profile.plateNumber,
                          style: const TextStyle(
                            color: RiderTheme.secondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
