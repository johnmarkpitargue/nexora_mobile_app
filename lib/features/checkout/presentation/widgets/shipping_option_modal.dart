import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';

class ShippingOptionResult {
  final String methodType; // 'door_to_door'
  final String optionName; // 'Standard Local'
  final String estimatedDate; // 'Calculated by parcel weight'
  final double shippingFee;
  final String? pickupLocation;

  const ShippingOptionResult({
    required this.methodType,
    required this.optionName,
    required this.estimatedDate,
    required this.shippingFee,
    this.pickupLocation,
  });
}

class ShippingOptionModal extends StatelessWidget {
  final ShippingOptionResult initialSelection;

  const ShippingOptionModal({super.key, required this.initialSelection});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final hasKnownFee = initialSelection.shippingFee > 0;
    final feeLabel = hasKnownFee
        ? '₱${initialSelection.shippingFee.toStringAsFixed(0)}'
        : (initialSelection.estimatedDate.isNotEmpty
            ? initialSelection.estimatedDate
            : 'Weight-based rate');

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.56,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: cs.onSurface),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 14),
                Text(
                  'Shipping Option',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery Option',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: cs.onSurface,
                        ),
                      ),
                      Text(
                        'Standard Courier',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.primary,
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cs.primary,
                          ),
                          child: const Icon(
                            Icons.check,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                initialSelection.optionName.isNotEmpty
                                    ? initialSelection.optionName
                                    : 'Standard Door-to-Door',
                                style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Dispatched via Nexora hub-to-hub and rider network. Fee is calculated from billed parcel weight per store.',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: cs.onSurfaceVariant,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(
                                    Icons.local_shipping_outlined,
                                    size: 14,
                                    color: cs.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      feeLabel,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: cs.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (hasKnownFee) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₱${initialSelection.shippingFee.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: NexoraTheme.priceColor(context),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              border: Border(top: BorderSide(color: cs.outlineVariant)),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Shipping Fee',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        hasKnownFee
                            ? '₱${initialSelection.shippingFee.toStringAsFixed(0)}'
                            : 'Weight-based',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: NexoraTheme.priceColor(context),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 44,
                    width: 160,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, initialSelection),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CONFIRM',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
