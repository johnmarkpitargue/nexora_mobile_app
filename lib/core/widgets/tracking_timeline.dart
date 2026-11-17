import 'package:flutter/material.dart';
import '../../app/theme/nexora_theme.dart';

/// Vertical parcel tracking timeline backed strictly by Laravel's real
/// `tracking_summary` milestones & sanitized buyer-safe exception messages.
class TrackingTimeline extends StatelessWidget {
  final Map<String, dynamic> trackingSummary;

  const TrackingTimeline({
    super.key,
    required this.trackingSummary,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasException = trackingSummary['has_active_exception'] == true;
    final exceptionBadge = trackingSummary['exception_badge']?.toString();
    final exceptionMessage = trackingSummary['exception_message']?.toString();
    final rawMilestones = trackingSummary['milestones'] as List<dynamic>? ?? [];
    final milestones = rawMilestones.whereType<Map>().toList().reversed.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (hasException && (exceptionBadge != null || exceptionMessage != null))
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: NexoraTheme.warning.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(NexoraRadius.card),
              border: Border.all(
                color: NexoraTheme.warning.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: NexoraTheme.warning,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (exceptionBadge != null && exceptionBadge.isNotEmpty)
                        Text(
                          exceptionBadge,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: scheme.onSurface,
                          ),
                        ),
                      if (exceptionMessage != null && exceptionMessage.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          exceptionMessage,
                          style: TextStyle(
                            fontSize: 12,
                            color: scheme.onSurfaceVariant,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (milestones.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Tracking updates will appear as your parcel moves through Nexora hubs.',
              style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
            ),
          )
        else
          ...List.generate(milestones.length, (idx) {
            final item = milestones[idx];
            final isLatest = idx == 0;
            final isLast = idx == milestones.length - 1;
            final label = item['label']?.toString() ?? 'Status Update';
            final detail = item['detail']?.toString();
            final hub = item['hub']?.toString();
            final timestamp = _formatTimestamp(item['timestamp']?.toString());
            final dotColor = isLatest ? NexoraTheme.accent : scheme.outline;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: isLatest ? 14 : 10,
                          height: isLatest ? 14 : 10,
                          margin: const EdgeInsets.only(top: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: dotColor,
                            border: isLatest
                                ? Border.all(
                                    color: NexoraTheme.primaryContainer,
                                    width: 3,
                                  )
                                : null,
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              color: scheme.outlineVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight:
                                  isLatest ? FontWeight.w800 : FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (hub != null && hub.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              hub,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: NexoraTheme.accent,
                              ),
                            ),
                          ],
                          if (detail != null && detail.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              detail,
                              style: TextStyle(
                                fontSize: 12,
                                color: scheme.onSurfaceVariant,
                                height: 1.35,
                              ),
                            ),
                          ],
                          if (timestamp.isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              timestamp,
                              style: TextStyle(
                                fontSize: 11,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  String _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    final dt = DateTime.tryParse(raw)?.toLocal();
    if (dt == null) return raw;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year} • $hour12:$min $ampm';
  }
}
