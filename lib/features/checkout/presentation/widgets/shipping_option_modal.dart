import 'package:flutter/material.dart';
import 'package:nexora_flutter_app/app/theme/nexora_theme.dart';

class ShippingOptionResult {
  final String methodType; // 'door_to_door'
  final String optionName; // 'Standard Local', 'Priority Next-Day'
  final String estimatedDate; // '8 - 9 Oct', '7 - 8 Oct'
  final double shippingFee; // 0.0 or 45.0
  final String? pickupLocation;

  const ShippingOptionResult({
    required this.methodType,
    required this.optionName,
    required this.estimatedDate,
    required this.shippingFee,
    this.pickupLocation,
  });
}

class ShippingOptionModal extends StatefulWidget {
  final ShippingOptionResult initialSelection;

  const ShippingOptionModal({super.key, required this.initialSelection});

  @override
  State<ShippingOptionModal> createState() => _ShippingOptionModalState();
}

class _ShippingOptionModalState extends State<ShippingOptionModal> {
  late String _selectedDoorOption; // 'standard' or 'priority'

  @override
  void initState() {
    super.initState();
    _selectedDoorOption =
        widget.initialSelection.optionName.contains('Priority')
            ? 'priority'
            : 'standard';
  }

  ShippingOptionResult _getCurrentResult() {
    if (_selectedDoorOption == 'priority') {
      return const ShippingOptionResult(
        methodType: 'door_to_door',
        optionName: 'Priority Next-Day',
        estimatedDate: '7 - 8 Oct',
        shippingFee: 45.0,
      );
    } else {
      return const ShippingOptionResult(
        methodType: 'door_to_door',
        optionName: 'Standard Local',
        estimatedDate: '8 - 9 Oct',
        shippingFee: 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentResult = _getCurrentResult();
    final isFree = currentResult.shippingFee == 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
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
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Delivery Options Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery Option',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        '2 Options Available',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Standard Delivery Option
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDoorOption = 'standard';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedDoorOption == 'standard'
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedDoorOption == 'standard'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
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
                              color: _selectedDoorOption == 'standard'
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              border: _selectedDoorOption == 'standard'
                                  ? null
                                  : Border.all(
                                      color: theme.colorScheme.outlineVariant,
                                      width: 1.5,
                                    ),
                            ),
                            child: _selectedDoorOption == 'standard'
                                ? const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Standard Delivery',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Fastest Free',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Delivered by Nexora Express Logistics',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Est. 8 - 9 Oct',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'FREE',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: NexoraTheme.priceColor(context),
                                ),
                              ),
                              Text(
                                '₱34',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Priority Next-Day Option
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedDoorOption = 'priority';
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: _selectedDoorOption == 'priority'
                            ? theme.colorScheme.primary.withValues(alpha: 0.08)
                            : theme.colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _selectedDoorOption == 'priority'
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
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
                              color: _selectedDoorOption == 'priority'
                                  ? theme.colorScheme.primary
                                  : Colors.transparent,
                              border: _selectedDoorOption == 'priority'
                                  ? null
                                  : Border.all(
                                      color: theme.colorScheme.outlineVariant,
                                      width: 1.5,
                                    ),
                            ),
                            child: _selectedDoorOption == 'priority'
                                ? const Icon(
                                    Icons.check,
                                    size: 12,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Priority Next-Day',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        'Top Speed',
                                        style: TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: FontWeight.bold,
                                          color: theme.colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Dispatched within 2 hours',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.bolt,
                                      size: 13,
                                      color: theme.colorScheme.primary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Est. 7 - 8 Oct (Next Day!)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: theme.colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '₱45',
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  color: NexoraTheme.priceColor(context),
                                ),
                              ),
                              Text(
                                '₱75',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurfaceVariant,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // Bottom Confirmation Dock Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
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
                        'Total Shipping',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            isFree
                                ? 'FREE'
                                : '₱${currentResult.shippingFee.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: NexoraTheme.priceColor(context),
                            ),
                          ),
                          if (isFree) ...[
                            const SizedBox(width: 4),
                            Text(
                              '₱34',
                              style: TextStyle(
                                fontSize: 10,
                                color: theme.colorScheme.onSurfaceVariant,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 44,
                    width: 180,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, currentResult);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
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
