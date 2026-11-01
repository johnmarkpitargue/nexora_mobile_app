import 'package:flutter/material.dart';

class RouteProgressWidget extends StatelessWidget {
  final int currentStageIndex; // 0: To Store, 1: At Store, 2: Pickup, 3: Transit, 4: Delivered
  final ValueChanged<int>? onStepTapped;

  const RouteProgressWidget({
    super.key,
    required this.currentStageIndex,
    this.onStepTapped,
  });

  String _getPillText() {
    switch (currentStageIndex) {
      case 0:
        return 'HEADED TO STORE';
      case 1:
        return 'AT STORE';
      case 2:
        return 'PICKUP VERIFIED';
      case 3:
        return 'IN TRANSIT';
      case 4:
      default:
        return 'COMPLETED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final stages = [
      {'title': 'To Store', 'icon': Icons.two_wheeler_rounded},
      {'title': 'At Store', 'icon': Icons.storefront_rounded},
      {'title': 'Pickup', 'icon': Icons.archive_outlined},
      {'title': 'Transit', 'icon': Icons.local_shipping_outlined},
      {'title': 'Delivered', 'icon': Icons.verified_outlined},
    ];

    final isCompleted = currentStageIndex >= 4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  currentStageIndex == 1 ? 'ACTIVE PIPELINE' : 'DELIVERY PROGRESS',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.8,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFBAE6FD),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCompleted)
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00C4FF),
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(right: 4),
                        child: Icon(Icons.check, size: 12, color: Color(0xFF0284C7)),
                      ),
                    Text(
                      _getPillText(),
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0284C7),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (currentStageIndex == 1) ...[
            const SizedBox(height: 2),
            const Text(
              '5-Stage Store Fulfillment',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
          const SizedBox(height: 14),

          // 5-node stepper with connecting line
          LayoutBuilder(
            builder: (context, constraints) {
              final double totalWidth = constraints.maxWidth;
              const double circleSize = 34.0;
              final double stepWidth = totalWidth / stages.length;

              return Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // Background track connecting line
                  Positioned(
                    top: circleSize / 2 - 1.5,
                    left: stepWidth / 2,
                    right: stepWidth / 2,
                    child: Container(
                      height: 3,
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),

                  // Active progress connecting line (green for completed portion)
                  if (currentStageIndex > 0)
                    Positioned(
                      top: circleSize / 2 - 1.5,
                      left: stepWidth / 2,
                      width: stepWidth * currentStageIndex.clamp(0, stages.length - 1),
                      child: Container(
                        height: 3,
                        color: const Color(0xFF10B981),
                      ),
                    ),

                  // Stepper nodes
                  Row(
                    children: List.generate(stages.length, (index) {
                      final isPast = currentStageIndex > index;
                      final isCurrent = currentStageIndex == index;
                      final isStepDone = currentStageIndex >= index;

                      return Expanded(
                        child: GestureDetector(
                          onTap: (onStepTapped != null && index <= currentStageIndex)
                              ? () => onStepTapped?.call(index)
                              : null,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                width: circleSize,
                                height: circleSize,
                                decoration: BoxDecoration(
                                  color: isPast
                                      ? const Color(0xFF10B981)
                                      : (isCurrent
                                          ? const Color(0xFF00C4FF)
                                          : const Color(0xFFF1F5F9)),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isPast
                                        ? const Color(0xFF059669)
                                        : (isCurrent
                                            ? const Color(0xFF00C4FF)
                                            : const Color(0xFFCBD5E1)),
                                    width: 1.5,
                                  ),
                                  boxShadow: isCurrent
                                      ? [
                                          BoxShadow(
                                            color: const Color(0xFF00C4FF)
                                                .withValues(alpha: 0.35),
                                            blurRadius: 8,
                                            offset: const Offset(0, 3),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Center(
                                  child: Icon(
                                    isPast
                                        ? Icons.check_rounded
                                        : stages[index]['icon'] as IconData,
                                    size: isPast ? 18 : 17,
                                    color: isStepDone
                                        ? Colors.white
                                        : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                stages[index]['title'] as String,
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: isStepDone
                                      ? FontWeight.w900
                                      : FontWeight.w600,
                                  color: isPast
                                      ? const Color(0xFF047857)
                                      : (isCurrent
                                          ? const Color(0xFF0284C7)
                                          : const Color(0xFF64748B)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
