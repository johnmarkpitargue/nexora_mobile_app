import 'package:flutter/material.dart';
import '../../../../core/theme/rider_theme.dart';
import '../../../../core/services/rider_service.dart';

class EarningsSummaryCard extends StatelessWidget {
  final VoidCallback onSeeWallet;

  const EarningsSummaryCard({
    super.key,
    required this.onSeeWallet,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: RiderService.instance,
      builder: (context, _) {
        final profile = RiderService.instance.profile;

        return Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: RiderTheme.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Today's Earnings",
                        style: TextStyle(
                          fontSize: 12,
                          color: RiderTheme.textMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          const Text(
                            '₱',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: RiderTheme.textDark,
                            ),
                          ),
                          Text(
                            profile.todayEarnings.toStringAsFixed(2),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: RiderTheme.textDark,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onSeeWallet,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: RiderTheme.primaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.account_balance_wallet_rounded,
                              size: 16, color: RiderTheme.primary),
                          SizedBox(width: 6),
                          Text(
                            'Wallet',
                            style: TextStyle(
                              color: RiderTheme.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: RiderTheme.cardBorder, height: 1),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _statItem(
                    label: 'Trips Done',
                    value: '${profile.todayDeliveries}',
                    icon: Icons.check_circle_outline_rounded,
                    color: RiderTheme.onlineGreen,
                  ),
                  _dividerVertical(),
                  _statItem(
                    label: 'Rating',
                    value: '${profile.rating} ★',
                    icon: Icons.star_rounded,
                    color: RiderTheme.primary,
                  ),
                  _dividerVertical(),
                  _statItem(
                    label: 'Acceptance',
                    value: '${profile.completionRate}%',
                    icon: Icons.bolt_rounded,
                    color: RiderTheme.primary,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _dividerVertical() {
    return Container(
      width: 1,
      height: 32,
      color: RiderTheme.cardBorder,
    );
  }

  Widget _statItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: RiderTheme.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: RiderTheme.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
