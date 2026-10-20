import 'package:flutter/material.dart';

class RateProductPage extends StatefulWidget {
  const RateProductPage({super.key});

  @override
  State<RateProductPage> createState() => _RateProductPageState();
}

class _RateProductPageState extends State<RateProductPage> {
  int _productRating = 5;
  int _sellerRating = 5;
  int _deliveryRating = 5;
  int _driverRating = 5;
  bool _reviewAnonymously = false;
  
  final List<String> _courierTags = [
    'Friendly', 'Good hygiene', 'Good communication', 'Reliable',
    'Regular delivery update', 'Helpful', 'Responsive', 'Professional', 'Fast delivery'
  ];
  final Set<String> _selectedCourierTags = {'Good communication'};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rate Product',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildCoinBanner(),
            _buildProductSection(),
            _buildCourierSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCoinBanner() {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF7E6), Color(0xFFEEF2FF)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(
              color: Color(0xFFFFB300),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.currency_bitcoin, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 12),
                children: [
                  TextSpan(text: 'Enjoy up to '),
                  TextSpan(text: '5.3 coins ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE65100))),
                  TextSpan(text: 'for your valued rev...'),
                ],
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Colors.black54),
        ],
      ),
    );
  }

  Widget _buildProductSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                  image: const DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1596462502278-27bfdc403348?auto=format&fit=crop&w=150&q=80'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Mikana 14k White Gold Plated May...',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text('Emika Adjustable', style: TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Text('Rate Product', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (index) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  index < _productRating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFB300),
                  size: 32,
                ),
                onPressed: () {
                  setState(() {
                    _productRating = index + 1;
                  });
                },
              );
            }).map((widget) => Padding(padding: const EdgeInsets.only(right: 8), child: widget)).toList(),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Add 1 photos and video', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7E6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.currency_bitcoin, color: Color(0xFFE65100), size: 12),
                    SizedBox(width: 4),
                    Text('+0.3 Coins', style: TextStyle(color: Color(0xFFE65100), fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE2E8F0), style: BorderStyle.solid),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.camera_alt_outlined, color: Color(0xFF00C1D4), size: 28),
                SizedBox(height: 8),
                Text('Video/Photo/Template', style: TextStyle(color: Colors.black54, fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Text('Write 50 characters', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
              Text('0 characters', style: TextStyle(color: Colors.black38, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Appearance: It's shiny and makes a good\nimpression when worn.", style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5)),
                SizedBox(height: 16),
                Text("Colour: The colour matches what was shown\nonline.", style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.5)),
                SizedBox(height: 24), // Space for user input
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Checkbox(
                value: _reviewAnonymously,
                onChanged: (val) {
                  setState(() {
                    _reviewAnonymously = val ?? false;
                  });
                },
                activeColor: const Color(0xFF00C1D4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              const Text('Review Anonymously', style: TextStyle(color: Colors.black87, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCourierSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingRow('Seller Service', _sellerRating, (val) => setState(() => _sellerRating = val)),
          const SizedBox(height: 16),
          _buildRatingRow('Delivery Speed', _deliveryRating, (val) => setState(() => _deliveryRating = val)),
          const SizedBox(height: 16),
          _buildRatingRow('Driver Service', _driverRating, (val) => setState(() => _driverRating = val)),
          const SizedBox(height: 24),
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage('https://images.unsplash.com/photo-1621876407519-7557dc0f119e?auto=format&fit=crop&w=100&q=80'), // placeholder for courier
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('SPX Express', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                  Text('Standard Local Logistics', style: TextStyle(color: Colors.black54, fontSize: 12)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _courierTags.map((tag) {
              final isSelected = _selectedCourierTags.contains(tag);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedCourierTags.remove(tag);
                    } else {
                      _selectedCourierTags.add(tag);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFF0F4FF) : const Color(0xFFF4F7FB),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF0066FF) : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    tag,
                    style: TextStyle(
                      color: isSelected ? const Color(0xFF0066FF) : Colors.black87,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const TextField(
              decoration: InputDecoration(
                hintText: 'Tell us more about the courier delivery\nexperience...',
                hintStyle: TextStyle(color: Colors.black45, fontSize: 13, height: 1.5),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 3,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Your rider rating and review will be shared to our partner courier and will be used to further improve our services.\nThank you!',
            style: TextStyle(color: Colors.black45, fontSize: 11, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingRow(String label, int rating, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Colors.black87)),
        Row(
          children: List.generate(5, (index) {
            return GestureDetector(
              onTap: () => onChanged(index + 1),
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Icon(
                  index < rating ? Icons.star : Icons.star_border,
                  color: const Color(0xFFFFB300),
                  size: 20,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00C1D4),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('Submit', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
