import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/chat_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/core/services/profile_service.dart';
import 'package:nexora_flutter_app/core/services/wishlist_service.dart';
import '../../../app/routes/app_routes.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onToggleDarkMode;
  final bool isDarkMode;

  const ProfilePage({
    super.key,
    this.onToggleDarkMode,
    this.isDarkMode = false,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late bool _darkMode;

  final int _voucherCount = 1;
  final int _pointsCount = 850;

  final List<String> _presetAvatars = const [
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?auto=format&fit=crop&w=200&q=80',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?auto=format&fit=crop&w=200&q=80',
  ];

  ImageProvider _getAvatarImageProvider() {
    final profile = ProfileService.instance;
    if (profile.hasCustomAvatarBytes) {
      return MemoryImage(profile.avatarBytes!);
    }
    return NetworkImage(profile.avatarUrl);
  }

  Future<void> _pickImage(ImageSource source, {StateSetter? setSheetState}) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        ProfileService.instance.updateAvatarBytes(bytes);
        if (setSheetState != null) {
          setSheetState(() {});
        }
        if (mounted) {
          setState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Text('📸 Profile photo uploaded successfully!'),
                ],
              ),
              backgroundColor: Color(0xFF00C1D4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not select image: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showPhotoOptionsModal(BuildContext parentContext, {StateSetter? setSheetState}) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.pop(modalCtx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C1D4).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.upload_file_rounded, color: Color(0xFF00C1D4)),
              ),
              title: const Text('Upload from Files / Device', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Pick photo from your computer or gallery', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(modalCtx);
                _pickImage(ImageSource.gallery, setSheetState: setSheetState);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_outlined, color: Color(0xFF0066FF)),
              ),
              title: const Text('Take Photo with Camera', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Snap a new profile picture now', style: TextStyle(fontSize: 12)),
              onTap: () {
                Navigator.pop(modalCtx);
                _pickImage(ImageSource.camera, setSheetState: setSheetState);
              },
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Or Select from Curated Avatars',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
              ),
            ),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _presetAvatars.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (ctx, index) {
                  final url = _presetAvatars[index];
                  return GestureDetector(
                    onTap: () {
                      ProfileService.instance.updateAvatarUrl(url);
                      if (setSheetState != null) setSheetState(() {});
                      Navigator.pop(modalCtx);
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: ProfileService.instance.avatarUrl == url && !ProfileService.instance.hasCustomAvatarBytes
                              ? const Color(0xFF00C1D4)
                              : const Color(0xFFE2E8F0),
                          width: 2.5,
                        ),
                        image: DecorationImage(
                          image: NetworkImage(url),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _darkMode = widget.isDarkMode;
  }

  void _showEditProfileSheet() {
    final profile = ProfileService.instance;
    final nameCtrl = TextEditingController(text: profile.name);
    final usernameCtrl = TextEditingController(text: profile.username);
    final emailCtrl = TextEditingController(text: profile.email);
    final phoneCtrl = TextEditingController(text: profile.phone);
    final addressCtrl = TextEditingController(text: profile.address);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          return Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Personal Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Avatar Photo Upload Section
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            image: DecorationImage(
                              image: _getAvatarImageProvider(),
                              fit: BoxFit.cover,
                            ),
                            border: Border.all(color: const Color(0xFF00C1D4), width: 2.5),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => _showPhotoOptionsModal(sheetContext, setSheetState: setSheetState),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Color(0xFF00C1D4),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showPhotoOptionsModal(sheetContext, setSheetState: setSheetState),
                      icon: const Icon(Icons.upload_file_rounded, size: 16, color: Color(0xFF00C1D4)),
                      label: const Text(
                        'Upload or Change Photo',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF00C1D4)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Editable Fields with live real-time updates!
                  const Text('Full Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: nameCtrl,
                    onChanged: (val) {
                      ProfileService.instance.updateProfile(name: val);
                    },
                    decoration: _buildInputDecoration(hint: 'Full Name', prefixIcon: Icons.person_outline),
                  ),
                  const SizedBox(height: 12),

                  const Text('Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: usernameCtrl,
                    onChanged: (val) {
                      ProfileService.instance.updateProfile(username: val);
                    },
                    decoration: _buildInputDecoration(hint: '@username', prefixIcon: Icons.alternate_email),
                  ),
                  const SizedBox(height: 12),

                  const Text('Email Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: emailCtrl,
                    onChanged: (val) {
                      ProfileService.instance.updateProfile(email: val);
                    },
                    decoration: _buildInputDecoration(hint: 'Email', prefixIcon: Icons.email_outlined),
                  ),
                  const SizedBox(height: 12),

                  const Text('Mobile Phone', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: phoneCtrl,
                    onChanged: (val) {
                      ProfileService.instance.updateProfile(phone: val);
                    },
                    decoration: _buildInputDecoration(hint: 'Phone', prefixIcon: Icons.phone_outlined),
                  ),
                  const SizedBox(height: 12),

                  const Text('Default Delivery Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: addressCtrl,
                    maxLines: 2,
                    onChanged: (val) {
                      ProfileService.instance.updateProfile(address: val);
                    },
                    decoration: _buildInputDecoration(hint: 'Address', prefixIcon: Icons.location_on_outlined),
                  ),
                  const SizedBox(height: 20),

                  // Save Changes Button
                  Container(
                    width: double.infinity,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        ProfileService.instance.updateProfile(
                          name: nameCtrl.text,
                          username: usernameCtrl.text,
                          email: emailCtrl.text,
                          phone: phoneCtrl.text,
                          address: addressCtrl.text,
                        );
                        Navigator.pop(sheetContext);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Profile updated in real-time!'),
                              ],
                            ),
                            backgroundColor: Color(0xFF00C1D4),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showTopUpDialog() {
    final amountController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.add_card_rounded, color: Color(0xFF0066FF)),
            SizedBox(width: 8),
            Text('Top Up NexoraPay'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter amount to add to your balance:'),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixText: '₱ ',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                hintText: '500.00',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final val = double.tryParse(amountController.text) ?? 500.0;
              final newBal = ProfileService.instance.walletBalance + val;
              ProfileService.instance.updateWalletBalance(newBal);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      'Successfully topped up ₱${val.toStringAsFixed(2)}! New Balance: ₱${newBal.toStringAsFixed(2)}'),
                  backgroundColor: const Color(0xFF0066FF),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0066FF),
              foregroundColor: Colors.white,
            ),
            child: const Text('Confirm Top Up'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        ProfileService.instance,
        OrderService.instance,
        AddressService.instance,
        WishlistService.instance,
        CartService.instance,
        ChatService.instance,
      ]),
      builder: (context, _) {
        return Scaffold(
          backgroundColor: const Color(0xFFF6F8FC),
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
                  // Header Title & Actions Row ("Me", settings, cart, chat)
                  _buildHeaderRow(context),
                  const SizedBox(height: 20),

                  // User Profile Avatar & Verified Info Header
                  _buildUserProfileHeader(),
                  const SizedBox(height: 20),

                  // Key Quick Stats Row (Orders, Wishlist, Wallet, Points)
                  _buildQuickStatsRow(),
                  const SizedBox(height: 20),

                  // NexoraPay Balance Gradient Dark Navy Card
                  _buildNexoraPayCard(context),
                  const SizedBox(height: 24),

                  // My Purchases Section Card
                  _buildMyPurchasesSection(context),
                  const SizedBox(height: 24),

                  // SHOPPING & BENEFITS Group
                  _buildSectionHeader('SHOPPING & BENEFITS'),
                  const SizedBox(height: 10),
                  _buildShoppingBenefitsCard(context),
                  const SizedBox(height: 24),

              // PREFERENCES & SECURITY Group
              _buildSectionHeader('PREFERENCES & SECURITY'),
              const SizedBox(height: 10),
              _buildPreferencesCard(context),
              const SizedBox(height: 24),

              // SUPPORT & LEGAL Group
              _buildSectionHeader('SUPPORT & LEGAL'),
              const SizedBox(height: 10),
              _buildSupportLegalCard(context),
              const SizedBox(height: 24),

              // Log Out Red Button
              _buildLogoutButton(context),
              const SizedBox(height: 16),

              // Footer Info
              _buildFooterInfo(),

              // Clearance for bottom floating navigation dock
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  },
);
}

  Widget _buildHeaderRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Me',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        Row(
          children: [
            // Settings Icon
            IconButton(
              icon: const Icon(Icons.settings_outlined,
                  color: Color(0xFF0F172A), size: 22),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Account Settings...')),
                );
              },
            ),
            // Cart Icon with Real-Time Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.shopping_cart_outlined,
                      color: Color(0xFF0F172A), size: 22),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.cart);
                  },
                ),
                if (CartService.instance.itemCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D2FF),
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${CartService.instance.itemCount}',
                        style: const TextStyle(
                          color: Color(0xFF050B28),
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            // Chat Icon with Real-Time Unread Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded,
                      color: Color(0xFF0F172A), size: 22),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRoutes.chat);
                  },
                ),
                if (ChatService.instance.totalUnreadCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Color(0xFFE11D48),
                        shape: BoxShape.circle,
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '${ChatService.instance.totalUnreadCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.5,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUserProfileHeader() {
    final profile = ProfileService.instance;
    return Row(
      children: [
        // User Photo Avatar
        GestureDetector(
          onTap: _showEditProfileSheet,
          child: Stack(
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  image: DecorationImage(
                    image: _getAvatarImageProvider(),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C1D4),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 14),

        // User Details Column
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      profile.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.verified,
                    size: 18,
                    color: Color(0xFF00D2FF),
                  ),
                ],
              ),
              const SizedBox(height: 1),
              Text(
                profile.username,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),

              // VIP Platinum Badge Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF00D2FF), Color(0xFF0066FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'VIP PLATINUM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Circular Edit Profile Icon Button
        GestureDetector(
          onTap: _showEditProfileSheet,
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Color(0xFFEEECFF),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_outlined,
              size: 18,
              color: Color(0xFF0066FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatsRow() {
    final profile = ProfileService.instance;
    final orderCount = OrderService.instance.activeOrders.length;
    final walletDisplay = profile.walletBalance >= 1000
        ? '₱${(profile.walletBalance / 1000).toStringAsFixed(1)}k'
        : '₱${profile.walletBalance.toStringAsFixed(0)}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem('$orderCount', 'Orders', () {
            Navigator.pushReplacementNamed(context, AppRoutes.orders);
          }),
          _buildStatItem('${WishlistService.instance.itemCount}', 'Wishlist', () {
            Navigator.pushNamed(context, AppRoutes.wishlist);
          }),
          _buildStatItem(walletDisplay, 'Wallet', () {
            _showTopUpDialog();
          }),
          _buildStatItem('$_pointsCount', 'Points', () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Nexora Rewards Points: $_pointsCount pts')),
            );
          }, textColor: const Color(0xFF00D2FF)),
        ],
      ),
    );
  }

  Widget _buildStatItem(String val, String label, VoidCallback onTap,
      {Color? textColor}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Text(
              val,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: textColor ?? const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNexoraPayCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF050B28), Color(0xFF0B1953), Color(0xFF004080)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF050B28).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.account_balance_wallet_outlined,
                      color: Color(0xFF00D2FF), size: 18),
                  SizedBox(width: 8),
                  Text(
                    'NEXORAPAY BALANCE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 3,
                          backgroundColor: Color(0xFF00D2FF),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Active',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₱${ProfileService.instance.walletBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Opening NexoraPay transaction history...')),
                  );
                },
                child: const Row(
                  children: [
                    Text(
                      'History',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded,
                        color: Color(0xFF00D2FF), size: 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          Row(
            children: [
              _buildWalletActionTile('Top Up', Icons.add_circle_outline_rounded,
                  () {
                _showTopUpDialog();
              }),
              const SizedBox(width: 8),
              _buildWalletActionTile('Pay QR', Icons.qr_code_scanner_rounded, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening QR Pay Scanner...')),
                );
              }),
              const SizedBox(width: 8),
              _buildWalletActionTile('Send', Icons.sync_alt_rounded, () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Opening Transfer money...')),
                );
              }),
              const SizedBox(width: 8),
              _buildWalletActionTile(
                'Vouchers',
                Icons.confirmation_number_outlined,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Available Vouchers: $_voucherCount')),
                  );
                },
                badgeCount: _voucherCount,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWalletActionTile(
      String label, IconData icon, VoidCallback onTap,
      {int badgeCount = 0}) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Column(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(icon, color: const Color(0xFF00D2FF), size: 20),
                  if (badgeCount > 0)
                    Positioned(
                      top: -4,
                      right: -6,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00D2FF),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$badgeCount',
                          style: const TextStyle(
                            color: Color(0xFF050B28),
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyPurchasesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Purchases',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: () {
                  Navigator.pushReplacementNamed(context, AppRoutes.orders);
                },
                child: const Row(
                  children: [
                    Text(
                      'View All Orders',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0066FF),
                      ),
                    ),
                    SizedBox(width: 2),
                    Icon(Icons.chevron_right_rounded,
                        size: 16, color: Color(0xFF0066FF)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildPurchaseStatusItem(
                  'To Pay',
                  Icons.credit_card_outlined,
                  OrderService.instance.activeOrders
                      .where((o) => o.statusText.toLowerCase() == 'to pay' || o.statusText.toLowerCase() == 'unpaid')
                      .length, () {
                Navigator.pushReplacementNamed(context, AppRoutes.orders, arguments: {'initialIndex': 1});
              }, isHighlighted: false),
              _buildPurchaseStatusItem(
                  'To Ship',
                  Icons.inventory_2_outlined,
                  OrderService.instance.activeOrders
                      .where((o) => o.statusText.toLowerCase() == 'to ship' || o.statusText.toLowerCase() == 'processing')
                      .length, () {
                Navigator.pushReplacementNamed(context, AppRoutes.orders, arguments: {'initialIndex': 2});
              }, isHighlighted: false),
              _buildPurchaseStatusItem(
                  'To Receive',
                  Icons.local_shipping_outlined,
                  OrderService.instance.activeOrders
                      .where((o) =>
                          o.statusText.toLowerCase() == 'to receive' ||
                          o.statusText.toLowerCase() == 'shipping' ||
                          o.statusText.toLowerCase() == 'shipped' ||
                          o.statusText.toLowerCase() == 'in transit' ||
                          o.statusText.toLowerCase() == 'out for delivery')
                      .length, () {
                Navigator.pushReplacementNamed(context, AppRoutes.orders, arguments: {'initialIndex': 3});
              },
              isHighlighted: OrderService.instance.activeOrders.any((o) =>
                  o.statusText.toLowerCase() == 'to receive' ||
                  o.statusText.toLowerCase() == 'shipping' ||
                  o.statusText.toLowerCase() == 'shipped' ||
                  o.statusText.toLowerCase() == 'in transit' ||
                  o.statusText.toLowerCase() == 'out for delivery')),
              _buildPurchaseStatusItem(
                  'Completed',
                  Icons.rate_review_outlined,
                  OrderService.instance.activeOrders
                      .where((o) => o.statusText.toLowerCase() == 'completed' || o.statusText.toLowerCase() == 'delivered')
                      .length, () {
                Navigator.pushReplacementNamed(context, AppRoutes.orders, arguments: {'initialIndex': 4});
              }, isHighlighted: false),
            ],
          ),

          // Active Parcel Status Banner Box (Only rendered if there are active in-transit orders)
          Builder(
            builder: (context) {
              final inTransitOrders = OrderService.instance.activeOrders.where(
                (o) =>
                    o.statusText.toLowerCase() == 'to receive' ||
                    o.statusText.toLowerCase() == 'shipping' ||
                    o.statusText.toLowerCase() == 'shipped' ||
                    o.statusText.toLowerCase() == 'in transit' ||
                    o.statusText.toLowerCase() == 'out for delivery',
              ).toList();

              if (inTransitOrders.isEmpty) {
                return const SizedBox.shrink();
              }

              final activeOrder = inTransitOrders.first;

              return Container(
                margin: const EdgeInsets.only(top: 16),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEEECFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00D2FF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.sync_rounded,
                          color: Color(0xFF050B28), size: 16),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            activeOrder.etaTime.isNotEmpty
                                ? activeOrder.etaTime
                                : 'Parcel arriving today',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            'Order ${activeOrder.orderId} • ${activeOrder.etaText}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pushNamed(
                          context,
                          AppRoutes.orderTracking,
                          arguments: activeOrder,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00D2FF),
                        foregroundColor: const Color(0xFF050B28),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Track',
                        style:
                            TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseStatusItem(
      String label, IconData icon, int badgeCount, VoidCallback onTap,
      {required bool isHighlighted}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: isHighlighted
                      ? const Color(0xFFE0F7FA)
                      : const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isHighlighted
                      ? const Color(0xFF00B4D8)
                      : const Color(0xFF64748B),
                  size: 20,
                ),
              ),
              if (badgeCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: Color(0xFF00D2FF),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Color(0xFF050B28),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
              color: isHighlighted
                  ? const Color(0xFF0066FF)
                  : const Color(0xFF475569),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 11.5,
        fontWeight: FontWeight.w900,
        color: Color(0xFF64748B),
        letterSpacing: 0.5,
      ),
    );
  }


  Widget _buildShoppingBenefitsCard(BuildContext context) {
    return _buildGroupCard([
      _buildListTile(
        icon: Icons.location_on_outlined,
        title: 'My Addresses',
        subtitle: AddressService.instance.defaultAddress?.fullAddress ?? ProfileService.instance.address,
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.myAddresses);
        },
      ),
      _buildListTile(
        icon: Icons.credit_card_rounded,
        title: 'Payment Methods',
        subtitle: 'GCash •••• 9128, Visa •••• 4012',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening Payment Methods...')),
          );
        },
      ),
      _buildListTile(
        icon: Icons.local_offer_outlined,
        title: 'Nexora Rewards Club',
        subtitle: 'Platinum Tier • 850 pts',
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opening Nexora Rewards Club...')),
          );
        },
      ),
      _buildListTile(
        icon: Icons.favorite_border_rounded,
        title: 'Saved Wishlist',
        subtitle: '${WishlistService.instance.itemCount} items saved',
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.wishlist);
        },
        isLast: true,
      ),
    ]);
  }

  Widget _buildPreferencesCard(BuildContext context) {
    return _buildGroupCard([
      _buildListTile(
        icon: Icons.security_rounded,
        title: 'Security & Biometrics',
        subtitle: 'Face ID enabled',
        onTap: () {},
      ),
      _buildListTile(
        icon: Icons.notifications_none_rounded,
        title: 'Notification Preferences',
        subtitle: 'Push, SMS & Courier Alerts',
        onTap: () {},
      ),
      _buildListTile(
        icon: Icons.language_rounded,
        title: 'Language & Currency',
        subtitle: 'English (PH) • PHP (₱)',
        onTap: () {},
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.nightlight_round,
                  color: Color(0xFF0066FF), size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dark Mode',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Adjust appearance scheme',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _darkMode,
              activeTrackColor: const Color(0xFF0066FF),
              onChanged: (val) {
                setState(() {
                  _darkMode = val;
                });
                if (widget.onToggleDarkMode != null) {
                  widget.onToggleDarkMode!();
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_darkMode
                        ? 'Dark Mode enabled!'
                        : 'Light Mode enabled!'),
                    duration: const Duration(seconds: 1),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    ]);
  }

  Widget _buildSupportLegalCard(BuildContext context) {
    return _buildGroupCard([
      _buildListTile(
        icon: Icons.support_agent_rounded,
        title: 'Help Center & 24/7 Support',
        subtitle: 'Live chat, FAQs, resolution hub',
        onTap: () {
          Navigator.pushReplacementNamed(context, AppRoutes.chat);
        },
      ),
      _buildListTile(
        icon: Icons.assignment_outlined,
        title: 'Terms & Privacy Policy',
        subtitle: 'User rights, privacy standards',
        onTap: () {},
        isLast: true,
      ),
    ]);
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF1F5F9),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: const Color(0xFF0066FF), size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF64748B),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: Colors.grey.shade100,
            indent: 66,
          ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFECDD3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
          ),
        ],
      ),
      child: TextButton.icon(
        onPressed: () {
          Navigator.pushReplacementNamed(context, AppRoutes.login);
        },
        icon: const Icon(Icons.logout_rounded, color: Color(0xFFE11D48), size: 18),
        label: const Text(
          'Log Out',
          style: TextStyle(
            color: Color(0xFFE11D48),
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
      ),
    );
  }

  Widget _buildFooterInfo() {
    return Column(
      children: [
        Center(
          child: Text(
            'Nexora v2.4.1 (Build 890)',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Center(
          child: Text(
            'Encrypted with 256–bit SSL',
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.grey.shade400,
            ),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF64748B), size: 18),
      filled: true,
      fillColor: const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }
}
