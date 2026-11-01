import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/services/cart_service.dart';
import '../../../core/services/order_service.dart';

class ReviewMediaItem {
  final Uint8List? bytes;
  final String? url;
  final String name;

  const ReviewMediaItem({
    this.bytes,
    this.url,
    required this.name,
  });
}

class RateProductPage extends StatefulWidget {
  final OrderItemModel? orderItem;
  final CartItemModel? cartItem;

  const RateProductPage({
    super.key,
    this.orderItem,
    this.cartItem,
  });

  @override
  State<RateProductPage> createState() => _RateProductPageState();
}

class _RateProductPageState extends State<RateProductPage> {
  int _productRating = 5;
  int _sellerRating = 5;
  int _deliveryRating = 5;
  int _driverRating = 5;
  bool _reviewAnonymously = false;

  final TextEditingController _reviewController = TextEditingController();
  final TextEditingController _courierCommentController = TextEditingController();

  // Attached user photos/media
  final List<ReviewMediaItem> _uploadedPhotos = [];
  bool _isPickingMedia = false;

  final List<String> _courierTags = [
    'Friendly',
    'Good hygiene',
    'Good communication',
    'Reliable',
    'Regular delivery update',
    'Helpful',
    'Responsive',
    'Professional',
    'Fast delivery',
  ];
  final Set<String> _selectedCourierTags = {'Good communication'};

  final List<String> _reviewQuickChips = [
    'Great Quality',
    'True to Description',
    'Well Packaged',
    'Fast Delivery',
    'Value for Money',
    'Highly Recommended',
  ];

  String _productTitle = 'Nexora StreamMic D20 Professional Condenser Microphone';
  String _productVariant = 'Tight Cardioid Solo';
  String _productImage =
      'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?auto=format&fit=crop&w=150&q=80';

  OrderItemModel? _resolvedOrder;
  String _courierName = 'Pedro Jose Garcia';
  String _orderId = '#NX-8942-ORD';
  bool _initializedArgs = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initializedArgs) {
      _initializedArgs = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      OrderItemModel? orderArg = widget.orderItem;
      if (orderArg == null && args is OrderItemModel) {
        orderArg = args;
      }
      if (orderArg == null) {
        if (OrderService.instance.pastOrders.isNotEmpty) {
          orderArg = OrderService.instance.pastOrders.first;
        } else if (OrderService.instance.activeOrders.isNotEmpty) {
          orderArg = OrderService.instance.activeOrders.first;
        }
      }
      if (orderArg != null) {
        _resolvedOrder = orderArg;
        _orderId = orderArg.orderId;
        if (orderArg.courierName.isNotEmpty) {
          _courierName = orderArg.courierName;
        }
        if (orderArg.isRated) {
          if (orderArg.buyerDriverRating != null) {
            _driverRating = orderArg.buyerDriverRating!;
          }
          if (orderArg.buyerDeliveryRating != null) {
            _deliveryRating = orderArg.buyerDeliveryRating!;
          }
          if (orderArg.buyerCourierComment != null &&
              orderArg.buyerCourierComment!.isNotEmpty) {
            _courierCommentController.text = orderArg.buyerCourierComment!;
          }
          if (orderArg.buyerCourierTags != null &&
              orderArg.buyerCourierTags!.isNotEmpty) {
            _selectedCourierTags
              ..clear()
              ..addAll(orderArg.buyerCourierTags!);
          }
        }
      }

      if (widget.cartItem != null) {
        _productTitle = widget.cartItem!.title;
        _productVariant = widget.cartItem!.variant;
        _productImage = widget.cartItem!.imageUrl;
      } else if (orderArg != null && orderArg.items.isNotEmpty) {
        final first = orderArg.items.first;
        _productTitle = first.title;
        _productVariant = first.variant;
        _productImage = first.imageUrl;
      } else if (args is CartItemModel) {
        _productTitle = args.title;
        _productVariant = args.variant;
        _productImage = args.imageUrl;
      } else if (args is Map<String, dynamic>) {
        if (args['title'] != null) _productTitle = args['title'] as String;
        if (args['variant'] != null) _productVariant = args['variant'] as String;
        if (args['imageUrl'] != null) _productImage = args['imageUrl'] as String;
        if (args['orderId'] != null) _orderId = args['orderId'] as String;
        if (args['courierName'] != null) _courierName = args['courierName'] as String;
      }
    }
  }

  @override
  void dispose() {
    _reviewController.dispose();
    _courierCommentController.dispose();
    super.dispose();
  }

  void _addQuickChip(String chip) {
    setState(() {
      final text = _reviewController.text.trim();
      if (text.isEmpty) {
        _reviewController.text = chip;
      } else {
        _reviewController.text = '$text. $chip';
      }
      _reviewController.selection = TextSelection.fromPosition(
        TextPosition(offset: _reviewController.text.length),
      );
    });
  }

  void _showMediaPickerSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Material(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Add Photos & Video',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 4),
            const Text(
              'Upload up to 5 clear photos or a short clip of the item.',
              style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 18),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0066FF)),
              ),
              title: const Text('Take Photo / Video', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Capture item condition now', style: TextStyle(fontSize: 12, color: Colors.black54)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromCamera();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.photo_library_rounded, color: Color(0xFF3B82F6)),
              ),
              title: const Text('Choose from Gallery', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              subtitle: const Text('Select from device photos', style: TextStyle(fontSize: 12, color: Colors.black54)),
              onTap: () {
                Navigator.pop(ctx);
                _pickFromGallery();
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    ),
  );
}

  Future<void> _pickFromCamera() async {
    if (_uploadedPhotos.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 media attachments allowed.')),
        );
      }
      return;
    }

    try {
      setState(() => _isPickingMedia = true);
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (picked == null) {
        // User cancelled camera capture: do NOT add any image!
        return;
      }

      final bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _uploadedPhotos.add(
          ReviewMediaItem(
            bytes: bytes,
            name: picked.name,
          ),
        );
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✓ Photo captured successfully!'),
          backgroundColor: Color(0xFF10B981),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to capture photo: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingMedia = false);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_uploadedPhotos.length >= 5) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Maximum 5 media attachments allowed.')),
        );
      }
      return;
    }

    final availableSlots = 5 - _uploadedPhotos.length;

    try {
      setState(() => _isPickingMedia = true);
      final picker = ImagePicker();
      List<XFile> pickedList = [];

      try {
        pickedList = await picker.pickMultiImage(
          limit: availableSlots,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
      } catch (_) {
        final single = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        if (single != null) {
          pickedList = [single];
        }
      }

      if (pickedList.isEmpty) {
        // User cancelled gallery selection: do NOT add any image!
        return;
      }

      final toAdd = <ReviewMediaItem>[];
      for (final picked in pickedList.take(availableSlots)) {
        final bytes = await picked.readAsBytes();
        toAdd.add(
          ReviewMediaItem(
            bytes: bytes,
            name: picked.name,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _uploadedPhotos.addAll(toAdd);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ ${toAdd.length} photo(s) selected!'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Unable to pick photos: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingMedia = false);
      }
    }
  }

  Future<void> _handleSubmit() async {
    if (_productRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a star rating for the product.')),
      );
      return;
    }

    final newRiderRating = await OrderService.instance.submitRiderRating(
      orderId: _orderId,
      driverRating: _driverRating,
      deliveryRating: _deliveryRating,
      productRating: _productRating,
      sellerRating: _sellerRating,
      courierComment: _courierCommentController.text.trim(),
      courierTags: _selectedCourierTags.toList(),
      productReview: _reviewController.text.trim(),
      courierName: _courierName,
    );

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 28),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Review Submitted Successfully!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Thank you for sharing your feedback. Your product review and rider rating help keep our marketplace safe and reliable.',
              style: TextStyle(fontSize: 13.5, color: Color(0xFF475569), height: 1.45),
            ),
            if (_uploadedPhotos.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                '✓ ${_uploadedPhotos.length} photo(s) attached.',
                style: const TextStyle(fontSize: 12, color: Color(0xFF0066FF), fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context, newRiderRating); // Return to Orders / Order Details
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            ),
            child: const Text('Done', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Rate Product',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black87),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reviews follow Nexora Community & Authenticity Guidelines.')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProductSection(),
            _buildCourierSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildProductSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Summary Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _productImage,
                  width: 52,
                  height: 52,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 52,
                    height: 52,
                    color: const Color(0xFFF1F5F9),
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _productVariant,
                      style: const TextStyle(color: Colors.black54, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),

          // Star Rating
          const Text('Rate Product Quality', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: List.generate(5, (index) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  index < _productRating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFB300),
                  size: 36,
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

          // Photos & Video Section (File Upload)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Add Photos & Video',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
              ),
              Text(
                '${_uploadedPhotos.length}/5 uploaded',
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Media Upload Grid / Box
          if (_uploadedPhotos.isEmpty)
            InkWell(
              onTap: _isPickingMedia ? null : _showMediaPickerSheet,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                width: double.infinity,
                height: 96,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isPickingMedia)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0066FF)),
                      )
                    else
                      const Icon(Icons.add_a_photo_outlined, color: Color(0xFF0066FF), size: 28),
                    const SizedBox(height: 8),
                    Text(
                      _isPickingMedia ? 'Opening media picker...' : 'Tap to upload photos or video',
                      style: const TextStyle(color: Color(0xFF475569), fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ..._uploadedPhotos.map((photo) {
                  return Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: photo.bytes != null
                            ? Image.memory(
                                photo.bytes!,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : (photo.url != null && photo.url!.startsWith('http'))
                                ? Image.network(
                                    photo.url!,
                                    width: 80,
                                    height: 80,
                                    fit: BoxFit.cover,
                                  )
                                : Container(
                                    width: 80,
                                    height: 80,
                                    color: const Color(0xFFF1F5F9),
                                    child: const Icon(Icons.image, color: Colors.grey),
                                  ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _uploadedPhotos.remove(photo);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close, size: 14, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  );
                }),
                if (_uploadedPhotos.length < 5)
                  InkWell(
                    onTap: _isPickingMedia ? null : _showMediaPickerSheet,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (_isPickingMedia)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0066FF)),
                            )
                          else
                            const Icon(Icons.add, color: Color(0xFF0066FF), size: 24),
                          const SizedBox(height: 4),
                          const Text('Add', style: TextStyle(fontSize: 11, color: Color(0xFF0066FF), fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 20),

          // Write Review Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Write Your Review',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87),
              ),
              AnimatedBuilder(
                animation: _reviewController,
                builder: (context, _) {
                  final len = _reviewController.text.length;
                  return Text(
                    '$len characters',
                    style: TextStyle(
                      color: len >= 20 ? const Color(0xFF059669) : Colors.black45,
                      fontSize: 12,
                      fontWeight: len >= 20 ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Interactive Review Input TextField
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _reviewController,
              maxLines: 5,
              minLines: 3,
              style: const TextStyle(fontSize: 13.5, color: Color(0xFF0F172A), height: 1.45),
              decoration: const InputDecoration(
                hintText:
                    'Share your honest feedback on the product! Mention the quality, packaging, material, and how it matched your expectations.',
                hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 12.5, height: 1.4),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Quick Review Suggestion Chips
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: _reviewQuickChips.map((chip) {
              return ActionChip(
                label: Text(
                  '+ $chip',
                  style: const TextStyle(fontSize: 11, color: Color(0xFF00838F), fontWeight: FontWeight.w600),
                ),
                backgroundColor: const Color(0xFFE0F7FA),
                side: BorderSide.none,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                onPressed: () => _addQuickChip(chip),
              );
            }).toList(),
          ),

          const SizedBox(height: 14),

          // Review Anonymously Checkbox
          Row(
            children: [
              Checkbox(
                value: _reviewAnonymously,
                onChanged: (val) {
                  setState(() {
                    _reviewAnonymously = val ?? false;
                  });
                },
                activeColor: const Color(0xFF0066FF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              const Text('Review Anonymously', style: TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w500)),
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
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRatingRow('Seller Service', _sellerRating, (val) => setState(() => _sellerRating = val)),
          const SizedBox(height: 16),
          _buildRatingRow('Delivery Speed', _deliveryRating, (val) => setState(() => _deliveryRating = val)),
          const SizedBox(height: 16),
          _buildRatingRow('Driver Service', _driverRating, (val) => setState(() => _driverRating = val)),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: NetworkImage(
                      _resolvedOrder?.courierAvatarUrl.isNotEmpty == true
                          ? _resolvedOrder!.courierAvatarUrl
                          : 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=150&q=80',
                    ),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nexora Express • SPX', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.black87)),
                    Text('Assigned Rider: $_courierName', style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 15),
                    const SizedBox(width: 4),
                    Text(
                      OrderService.instance
                          .getLiveCourierRating(
                            _courierName,
                            fallback: _resolvedOrder?.courierRating ?? 4.96,
                          )
                          .toStringAsFixed(2),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                        color: Color(0xFF92400E),
                      ),
                    ),
                  ],
                ),
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
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: TextField(
              controller: _courierCommentController,
              decoration: const InputDecoration(
                hintText: 'Tell us more about the courier delivery experience...',
                hintStyle: TextStyle(color: Colors.black45, fontSize: 12.5, height: 1.4),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              maxLines: 3,
            ),
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
                padding: const EdgeInsets.only(left: 6),
                child: Icon(
                  index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: const Color(0xFFFFB300),
                  size: 26,
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
        child: SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _handleSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Text('Submit Review', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
