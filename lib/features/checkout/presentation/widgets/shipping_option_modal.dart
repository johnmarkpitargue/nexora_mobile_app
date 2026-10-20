import 'package:flutter/material.dart';

class ShippingOptionResult {
  final String methodType; // 'door_to_door' or 'self_pickup'
  final String optionName; // 'Standard Local', 'Priority Next-Day', 'Self Pick-Up (Liliw Hub)'
  final String estimatedDate; // '8 - 9 Oct', '7 - 8 Oct'
  final double shippingFee; // 0.0 or 45.0
  final String? pickupLocation; // Name of pickup location if applicable

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

  const ShippingOptionModal({
    super.key,
    required this.initialSelection,
  });

  @override
  State<ShippingOptionModal> createState() => _ShippingOptionModalState();
}

class _ShippingOptionModalState extends State<ShippingOptionModal> {
  late String _selectedType; // 'door_to_door' or 'self_pickup'
  late String _selectedDoorOption; // 'standard' or 'priority'
  late int _selectedPickupIndex; // 0, 1, 2

  final List<Map<String, dynamic>> _pickupLocations = [
    {
      'name': 'Liliw Central Pick-Up Hub',
      'tag': 'Nearest',
      'distance': '0.8 km away • Open 8AM - 8PM',
      'address': '192 Poblacion St, Liliw, Laguna',
      'date': '7 - 8 Oct',
      'fee': 0.0,
    },
    {
      'name': 'San Pablo Express Hub',
      'tag': '24/7 Open',
      'distance': '4.2 km away • Open 24 Hours',
      'address': 'Regidor St, San Pablo City, Laguna',
      'date': '7 - 8 Oct',
      'fee': 0.0,
    },
    {
      'name': 'Sta. Cruz Logistics Station',
      'tag': '',
      'distance': '8.5 km away • Open 8AM - 6PM',
      'address': 'Pagsanjan Road, Sta. Cruz, Laguna',
      'date': '8 - 9 Oct',
      'fee': 0.0,
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialSelection.methodType;
    _selectedDoorOption = widget.initialSelection.optionName.contains('Priority')
        ? 'priority'
        : 'standard';
    _selectedPickupIndex = 0;
  }

  ShippingOptionResult _getCurrentResult() {
    if (_selectedType == 'door_to_door') {
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
    } else {
      final loc = _pickupLocations[_selectedPickupIndex];
      return ShippingOptionResult(
        methodType: 'self_pickup',
        optionName: 'Self Pick-Up (${loc['name']})',
        estimatedDate: loc['date'] as String,
        shippingFee: loc['fee'] as double,
        pickupLocation: loc['name'] as String,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentResult = _getCurrentResult();
    final isFree = currentResult.shippingFee == 0.0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A)),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Shipping Option',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
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
                  // 1. Top Delivery Type Tabs (Door-to-Door vs Self Pick-Up)
                  Row(
                    children: [
                      // Door-to-Door Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = 'door_to_door';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedType == 'door_to_door'
                                  ? const Color(0xFFE0F7FA)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedType == 'door_to_door'
                                    ? const Color(0xFF00D2FF)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00B4D8)
                                            .withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.local_shipping_outlined,
                                        color: Color(0xFF00B4D8),
                                        size: 18,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF00B4D8)
                                            .withValues(alpha: 0.15),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'FREE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF00B4D8),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Door-to-Door',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Delivered to address',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Self Pick-Up Tab
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedType = 'self_pickup';
                            });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _selectedType == 'self_pickup'
                                  ? const Color(0xFFE0F7FA)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _selectedType == 'self_pickup'
                                    ? const Color(0xFF00D2FF)
                                    : Colors.transparent,
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Icon(
                                        Icons.storefront_outlined,
                                        color: Color(0xFF64748B),
                                        size: 18,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEF2FF),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        'FREE',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Self Pick-Up',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Nearby pick-up points',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 2. Guaranteed On-Time Delivery Banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'NEXORA SUPPORTED LOGISTICS',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF00838F),
                                letterSpacing: 0.5,
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Guaranteed ',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF334155),
                                  ),
                                ),
                                Icon(Icons.info_outline,
                                    size: 13, color: Color(0xFF64748B)),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 30,
                                height: 30,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE0F7FA),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.speed_rounded,
                                  color: Color(0xFF00B4D8),
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Guaranteed On-Time Delivery',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 12,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      'Get up to ₱40 voucher if your package arrives later than estimated date.',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Color(0xFF475569),
                                        height: 1.25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // 3. Dynamic Section Body (Door-to-Door options VS Self Pick-Up points)
                  if (_selectedType == 'door_to_door') ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Shipping Tier',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '2 Options Available',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

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
                              ? const Color(0xFFE0F7FA).withValues(alpha: 0.5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedDoorOption == 'standard'
                                ? const Color(0xFF00D2FF)
                                : Colors.transparent,
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
                                    ? const Color(0xFF00D2FF)
                                    : Colors.transparent,
                                border: _selectedDoorOption == 'standard'
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFCBD5E1),
                                        width: 1.5),
                              ),
                              child: _selectedDoorOption == 'standard'
                                  ? const Icon(Icons.check,
                                      size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Standard Delivery',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFC7D2FE),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Fastest Free',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF3730A3),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Delivered by Nexora Express Logistics',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Row(
                                    children: [
                                      Icon(Icons.access_time,
                                          size: 13, color: Color(0xFF00838F)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Est. 8 - 9 Oct',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF00838F),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'FREE',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Color(0xFF00838F),
                                  ),
                                ),
                                Text(
                                  '₱34',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
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
                              ? const Color(0xFFE0F7FA).withValues(alpha: 0.5)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedDoorOption == 'priority'
                                ? const Color(0xFF00D2FF)
                                : Colors.transparent,
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
                                    ? const Color(0xFF00D2FF)
                                    : Colors.transparent,
                                border: _selectedDoorOption == 'priority'
                                    ? null
                                    : Border.all(
                                        color: const Color(0xFFCBD5E1),
                                        width: 1.5),
                              ),
                              child: _selectedDoorOption == 'priority'
                                  ? const Icon(Icons.check,
                                      size: 12, color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Priority Next-Day',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: Color(0xFF0F172A),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0F2FE),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Top Speed',
                                          style: TextStyle(
                                            fontSize: 8.5,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF0284C7),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Dispatched within 2 hours',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF64748B),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Row(
                                    children: [
                                      Icon(Icons.bolt,
                                          size: 13, color: Color(0xFF0066FF)),
                                      SizedBox(width: 4),
                                      Text(
                                        'Est. 7 - 8 Oct (Next Day!)',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF0066FF),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₱45',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14,
                                    color: Color(0xFF0F172A),
                                  ),
                                ),
                                Text(
                                  '₱75',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF94A3B8),
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Nearby Pick-Up Locations',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          '${_pickupLocations.length} Points Available',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // List of Pick-Up Locations
                    ...List.generate(_pickupLocations.length, (index) {
                      final loc = _pickupLocations[index];
                      final isSelected = _selectedPickupIndex == index;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedPickupIndex = index;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFE0F7FA).withValues(alpha: 0.5)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF00D2FF)
                                    : Colors.transparent,
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
                                    color: isSelected
                                        ? const Color(0xFF00D2FF)
                                        : Colors.transparent,
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: const Color(0xFFCBD5E1),
                                            width: 1.5),
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check,
                                          size: 12, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              loc['name'] as String,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w800,
                                                fontSize: 13,
                                                color: Color(0xFF0F172A),
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          if ((loc['tag'] as String).isNotEmpty) ...[
                                            const SizedBox(width: 4),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 6,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFE0F2FE),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                loc['tag'] as String,
                                                style: const TextStyle(
                                                  fontSize: 8.5,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF0284C7),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        loc['distance'] as String,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF00B4D8),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        loc['address'] as String,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(
                                              Icons.storefront_outlined,
                                              size: 13,
                                              color: Color(0xFF00838F)),
                                          const SizedBox(width: 4),
                                          Text(
                                            'Est. ${loc['date']}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF00838F),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'FREE',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        color: Color(0xFF00838F),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),

          // Bottom Confirmation Dock Bar matching screenshot
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
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
                      const Text(
                        'Total Shipping',
                        style: TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            isFree ? 'FREE' : '₱${currentResult.shippingFee.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF00838F),
                            ),
                          ),
                          if (isFree) ...[
                            const SizedBox(width: 4),
                            const Text(
                              '₱34',
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(0xFF94A3B8),
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
                        backgroundColor: const Color(0xFF0096C7),
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
