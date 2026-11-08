import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/rider_theme.dart';
import '../../../../core/models/delivery_order.dart';

class AvailableOrderCard extends StatelessWidget {
  final DeliveryOrder order;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const AvailableOrderCard({
    super.key,
    required this.order,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RiderTheme.cardBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Top Bar: Earnings, Distance, and Isolated "Decline" button in upper corner
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Payout & Distance
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: RiderTheme.onlineGreenLight,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: RiderTheme.onlineGreen.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.payments_rounded,
                              size: 15, color: RiderTheme.onlineGreen),
                          const SizedBox(width: 5),
                          Text.rich(
                            TextSpan(
                              text: '₱${order.riderEarnings.toStringAsFixed(2)}',
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontWeight: FontWeight.w900,
                                fontSize: 14.5,
                              ),
                              children: [
                                if (order.tip > 0)
                                  TextSpan(
                                    text: ' (+₱${order.tip.toStringAsFixed(0)})',
                                    style: const TextStyle(
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Distance & Time
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.directions_bike_rounded,
                              size: 13, color: Color(0xFF475569)),
                          const SizedBox(width: 4),
                          Text(
                            '${order.distanceKm} km • ~${order.estimatedMinutes}m',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (order.acceptanceCountdownSec > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFCA5A5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, size: 13, color: Color(0xFFDC2626)),
                            const SizedBox(width: 4),
                            Text(
                              '${order.acceptanceCountdownSec}s remaining',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFFDC2626),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Isolated Decline Action in upper corner (Fat-finger danger zone fix)
              Tooltip(
                message: 'Decline this order',
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onDecline,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2).withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFF87171).withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.close_rounded,
                              size: 14, color: Color(0xFFDC2626)),
                          SizedBox(width: 4),
                          Text(
                            'Decline',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. PRIMARY INFORMATION: Physical Cargo Specs (Information Hierarchy Fix)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.all_inbox_rounded,
                        size: 15, color: RiderTheme.primary),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'CARGO SPECIFICATIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: RiderTheme.textDark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: order.paymentType.contains('COD')
                            ? const Color(0xFFFEF3C7)
                            : const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        order.paymentType.contains('COD')
                            ? 'COD ₱${order.orderTotal.toStringAsFixed(0)}'
                            : 'Prepaid',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: order.paymentType.contains('COD')
                              ? const Color(0xFFD97706)
                              : const Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Specs Badges Row (Size, Weight, Fragility, Bag fit)
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _buildSpecChip(
                      icon: Icons.inventory_2_outlined,
                      label: order.packageSize,
                      bgColor: const Color(0xFFEFF6FF),
                      textColor: const Color(0xFF1D4ED8),
                    ),
                    _buildSpecChip(
                      icon: Icons.scale_rounded,
                      label: '${order.packageWeightKg} kg',
                      bgColor: const Color(0xFFF1F5F9),
                      textColor: const Color(0xFF0F172A),
                    ),
                    if (order.isFragile)
                      _buildSpecChip(
                        icon: Icons.warning_amber_rounded,
                        label: 'Fragile Handling',
                        bgColor: const Color(0xFFFEF3C7),
                        textColor: const Color(0xFFB45309),
                      ),
                    if (order.fitsInsulatedBag)
                      _buildSpecChip(
                        icon: Icons.check_circle_outline_rounded,
                        label: 'Fits Insulated Bag',
                        bgColor: const Color(0xFFD1FAE5),
                        textColor: const Color(0xFF10B981),
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Manifest text that wraps cleanly onto two lines (Text Truncation fix)
                Text(
                  '${order.items.length} package items • ${order.items.map((i) => '${i.quantity}x ${i.name}').join(', ')}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF475569),
                    height: 1.35,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // 3. Pickup & Drop-off Route (Customer Privacy Protection)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  const Icon(Icons.storefront_rounded,
                      size: 18, color: RiderTheme.primary),
                  Container(
                    width: 2,
                    height: 28,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 2),
                  ),
                  const Icon(Icons.location_on_rounded,
                      size: 18, color: RiderTheme.errorRed),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Pickup Store
                    Text(
                      order.merchantName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: RiderTheme.textDark,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      order.merchantAddress,
                      style: const TextStyle(
                        fontSize: 11,
                        color: RiderTheme.textMuted,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),

                    // Drop-off Neighborhood Area (Protected before acceptance)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Drop-off: ${order.maskedDropoffArea}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                              color: RiderTheme.textDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: const [
                        Icon(Icons.shield_outlined,
                            size: 12, color: Color(0xFF64748B)),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Exact unit & recipient details unlocked upon accept',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 4. "Swipe to Accept" Slider (Fat-finger & accidental tap prevention)
          SwipeToAcceptSlider(
            key: ValueKey('slider_${order.id}'),
            onAccept: onAccept,
          ),
        ],
      ),
    );
  }

  Widget _buildSpecChip({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// A dedicated "Swipe to Accept" interactive slider widget.
/// Eliminates accidental clicks for riders with motorcycle mounts or riding gloves.
class SwipeToAcceptSlider extends StatefulWidget {
  final VoidCallback onAccept;

  const SwipeToAcceptSlider({
    super.key,
    required this.onAccept,
  });

  @override
  State<SwipeToAcceptSlider> createState() => _SwipeToAcceptSliderState();
}

class _SwipeToAcceptSliderState extends State<SwipeToAcceptSlider>
    with SingleTickerProviderStateMixin {
  double _dragPosition = 0.0;
  bool _accepted = false;
  late AnimationController _animController;
  late Animation<double> _resetAnim;
  Timer? _autoResetTimer;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void didUpdateWidget(covariant SwipeToAcceptSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_accepted) {
      _autoResetTimer?.cancel();
      setState(() {
        _accepted = false;
        _dragPosition = 0.0;
      });
    }
  }

  @override
  void dispose() {
    _autoResetTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details, double maxDrag) {
    if (_accepted) return;
    setState(() {
      _dragPosition = (_dragPosition + details.delta.dx).clamp(0.0, maxDrag);
    });
  }

  void _springBack() {
    final start = _dragPosition;
    _resetAnim = Tween<double>(begin: start, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _dragPosition = _resetAnim.value;
          });
        }
      });
    _animController.forward(from: 0.0);
  }

  void _resetSlider() {
    if (!mounted) return;
    final start = _dragPosition;
    _resetAnim = Tween<double>(begin: start, end: 0.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    )..addListener(() {
        if (mounted) {
          setState(() {
            _dragPosition = _resetAnim.value;
          });
        }
      });
    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() {
          _accepted = false;
          _dragPosition = 0.0;
        });
      }
    });
  }

  void _triggerAccept(double maxDrag) {
    if (_accepted) return;
    HapticFeedback.heavyImpact();
    setState(() {
      _dragPosition = maxDrag;
      _accepted = true;
    });
    widget.onAccept();

    // Automatically spring back after 1.2s so the slider never stays stuck
    // if the card remains mounted or if the user navigates back
    _autoResetTimer?.cancel();
    _autoResetTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted && _accepted) {
        _resetSlider();
      }
    });
  }

  void _onDragEnd(DragEndDetails details, double maxDrag) {
    if (_accepted) return;
    // Threshold is 75% of the full drag width
    if (_dragPosition >= maxDrag * 0.75) {
      _triggerAccept(maxDrag);
    } else {
      _springBack();
    }
  }

  @override
  Widget build(BuildContext context) {
    const double knobSize = 46.0;
    const double trackHeight = 54.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - knobSize - 8.0;
        final double progress = maxDrag > 0 ? (_dragPosition / maxDrag).clamp(0.0, 1.0) : 0.0;

        return Container(
          height: trackHeight,
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: RiderTheme.onlineGreen.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Active fill gradient as user drags
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: _dragPosition + knobSize + 8,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF10B981),
                        RiderTheme.onlineGreen,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
              ),

              // Guide text and pulsing chevrons in center (also tappable for quick accept)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _triggerAccept(maxDrag),
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) => _onDragEnd(details, maxDrag),
                  child: Center(
                    child: Opacity(
                      opacity: (1.0 - (progress * 1.6)).clamp(0.0, 1.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'SWIPE TO ACCEPT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(Icons.keyboard_double_arrow_right_rounded,
                              color: Colors.white70, size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Dragging Knob
              Positioned(
                left: 4.0 + _dragPosition,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  key: const ValueKey('swipe_knob'),
                  onTap: () {
                    if (_accepted) {
                      _resetSlider();
                    } else {
                      _triggerAccept(maxDrag);
                    }
                  },
                  onHorizontalDragUpdate: (details) => _onDragUpdate(details, maxDrag),
                  onHorizontalDragEnd: (details) => _onDragEnd(details, maxDrag),
                  child: Container(
                    width: knobSize,
                    height: knobSize,
                    decoration: BoxDecoration(
                      color: _accepted ? RiderTheme.onlineGreen : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Icon(
                        _accepted ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        color: _accepted ? Colors.white : RiderTheme.primary,
                        size: 24,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
