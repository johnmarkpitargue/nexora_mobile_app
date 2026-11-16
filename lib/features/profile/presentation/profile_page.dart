import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:nexora_flutter_app/core/services/address_service.dart';
import 'package:nexora_flutter_app/core/services/cart_service.dart';
import 'package:nexora_flutter_app/core/services/chat_service.dart';
import 'package:nexora_flutter_app/core/services/order_service.dart';
import 'package:nexora_flutter_app/core/services/profile_service.dart';
import 'package:nexora_flutter_app/core/services/wishlist_service.dart';
import 'package:nexora_flutter_app/core/services/buyer_account_service.dart';
import 'package:nexora_flutter_app/core/services/payment_method_service.dart';
import 'package:nexora_flutter_app/core/services/shop_service.dart';
import 'package:nexora_flutter_app/core/services/supabase_auth_service.dart';

import '../../../app/routes/app_routes.dart';
import '../../../app/theme/nexora_theme.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/guest_auth_guard.dart';
import '../../../core/widgets/report_issue_sheet.dart';
import 'account_security_modal.dart';
import 'widgets/profile_components.dart';

const bool _useLegacyProfile = bool.fromEnvironment('NEXORA_LEGACY_PROFILE');

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

  ImageProvider? _getAvatarImageProvider() {
    final profile = ProfileService.instance;
    if (profile.hasCustomAvatarBytes) {
      return MemoryImage(profile.avatarBytes!);
    }
    if (profile.avatarUrl.isNotEmpty) {
      return NetworkImage(profile.avatarUrl);
    }
    return null;
  }

  Future<void> _pickImage(
    ImageSource source, {
    StateSetter? setSheetState,
  }) async {
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
        final sizeMb = bytes.lengthInBytes / (1024 * 1024);
        final name = picked.name;

        final session = BuyerAccountService.instance.currentBuyerSession;
        final res = BuyerAccountService.instance.editProfile(
          firstName:
              session?.firstName ??
              ProfileService.instance.name.split(' ').first,
          lastName:
              session?.lastName ??
              (ProfileService.instance.name.split(' ').length > 1
                  ? ProfileService.instance.name.split(' ').sublist(1).join(' ')
                  : 'Cruz'),
          photoName: name,
          photoSizeMb: sizeMb,
          photoBytes: bytes,
        );

        if (!res.success) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(res.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          return;
        }

        if (ApiClient.instance.hasToken) {
          final remoteRes = await BuyerAccountService.instance
              .updateProfileRemote(
                firstName:
                    session?.firstName ??
                    ProfileService.instance.name.split(' ').first,
                lastName:
                    session?.lastName ??
                    (ProfileService.instance.name.split(' ').length > 1
                        ? ProfileService.instance.name
                              .split(' ')
                              .sublist(1)
                              .join(' ')
                        : 'User'),
                avatarBytes: bytes,
                avatarFilename: name,
              );
          if (!remoteRes.success && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(remoteRes.message),
                backgroundColor: Colors.redAccent,
              ),
            );
            return;
          }
        }

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
              backgroundColor: Color(0xFF0066FF),
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

  void _showPhotoOptionsModal(
    BuildContext parentContext, {
    StateSetter? setSheetState,
  }) {
    final theme = Theme.of(parentContext);
    final isDark = theme.brightness == Brightness.dark;
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          border: isDark ? Border.all(color: const Color(0xFF1E293B)) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Change Profile Photo',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close_rounded,
                    color: isDark
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF64748B),
                  ),
                  onPressed: () => Navigator.pop(modalCtx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF0066FF).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.upload_file_rounded,
                  color: Color(0xFF0066FF),
                ),
              ),
              title: Text(
                'Upload from Files / Device',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                'Pick photo from your computer or gallery',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
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
                child: const Icon(
                  Icons.camera_alt_outlined,
                  color: Color(0xFF0066FF),
                ),
              ),
              title: Text(
                'Take Photo with Camera',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              subtitle: Text(
                'Snap a new profile picture now',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF64748B),
                ),
              ),
              onTap: () {
                Navigator.pop(modalCtx);
                _pickImage(ImageSource.camera, setSheetState: setSheetState);
              },
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
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = ProfileService.instance;
    final session = BuyerAccountService.instance.currentBuyerSession;
    final firstName = session?.firstName ?? profile.name.split(' ').first;
    final lastName =
        session?.lastName ??
        (profile.name.split(' ').length > 1
            ? profile.name.split(' ').sublist(1).join(' ')
            : 'Cruz');
    final firstNameCtrl = TextEditingController(text: firstName);
    final lastNameCtrl = TextEditingController(text: lastName);
    String initialUsername = profile.username;
    if (initialUsername.isEmpty || initialUsername == '@alexrivera') {
      final emailPrefix = (session?.email ?? profile.email)
          .split('@')
          .first
          .trim();
      initialUsername = emailPrefix.isNotEmpty ? '@$emailPrefix' : '@username';
    }
    final usernameCtrl = TextEditingController(text: initialUsername);

    String initialPhone = session?.mobileNumber ?? profile.phone;
    if (initialPhone == '09000000000' || initialPhone == '+63 917 123 4567') {
      initialPhone = '';
    }
    final phoneCtrl = TextEditingController(text: initialPhone);
    final addressCtrl = TextEditingController(text: profile.address);
    String? sheetError;

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
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              border: isDark
                  ? Border.all(color: const Color(0xFF1E293B))
                  : null,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Edit Personal Information',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Avatar Photo Upload Section
                  Center(
                    child: Stack(
                      children: [
                        Builder(
                          builder: (context) {
                            final avatarProvider = _getAvatarImageProvider();
                            return Container(
                              width: 88,
                              height: 88,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDark
                                    ? const Color(0xFF1E293B)
                                    : const Color(0xFFF1F5F9),
                                image: avatarProvider != null
                                    ? DecorationImage(
                                        image: avatarProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                border: Border.all(
                                  color: const Color(0xFF0066FF),
                                  width: 2.5,
                                ),
                              ),
                              child: avatarProvider == null
                                  ? Icon(
                                      Icons.person_rounded,
                                      size: 44,
                                      color: isDark
                                          ? const Color(0xFF94A3B8)
                                          : const Color(0xFF64748B),
                                    )
                                  : null,
                            );
                          },
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: GestureDetector(
                            onTap: () => _showPhotoOptionsModal(
                              sheetContext,
                              setSheetState: setSheetState,
                            ),
                            child: Container(
                              width: 30,
                              height: 30,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0066FF),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _showPhotoOptionsModal(
                        sheetContext,
                        setSheetState: setSheetState,
                      ),
                      icon: const Icon(
                        Icons.upload_file_rounded,
                        size: 16,
                        color: Color(0xFF0066FF),
                      ),
                      label: const Text(
                        'Upload or Change Photo (Max 5MB)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0066FF),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (sheetError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEBEB),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent.shade100),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.redAccent,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              sheetError!,
                              style: const TextStyle(
                                color: Colors.redAccent,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // Editable First & Last Name (BUY-ACCT-001)
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'First Name *',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: firstNameCtrl,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _buildInputDecoration(
                                hint: 'First Name',
                                prefixIcon: Icons.person_outline,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Last Name *',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            TextField(
                              controller: lastNameCtrl,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: _buildInputDecoration(
                                hint: 'Last Name',
                                prefixIcon: Icons.badge_outlined,
                                isDark: isDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Username',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: usernameCtrl,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _buildInputDecoration(
                      hint: '@username',
                      prefixIcon: Icons.alternate_email,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Email Address (Security Protected)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Email Address (Verified)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF0F172A),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(sheetContext);
                          showAccountSecurityModal(context);
                        },
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(50, 24),
                        ),
                        child: const Text(
                          'Change via OTP',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0066FF),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                      border: isDark
                          ? Border.all(color: const Color(0xFF334155))
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 18,
                          color: isDark
                              ? const Color(0xFF94A3B8)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            BuyerAccountService
                                    .instance
                                    .currentBuyerSession
                                    ?.email ??
                                profile.email,
                            style: TextStyle(
                              fontSize: 13.5,
                              color: isDark
                                  ? const Color(0xFFE2E8F0)
                                  : const Color(0xFF334155),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.verified,
                          size: 16,
                          color: Color(0xFF00D2FF),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mobile Phone
                  Text(
                    'Mobile Phone',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _buildInputDecoration(
                      hint: '09XXXXXXXXX',
                      prefixIcon: Icons.phone_outlined,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    'Delivery Address Note',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: addressCtrl,
                    maxLines: 2,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: _buildInputDecoration(
                      hint: 'Address Note',
                      prefixIcon: Icons.location_on_outlined,
                      isDark: isDark,
                    ),
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
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final sheetNavigator = Navigator.of(sheetContext);
                        setSheetState(() => sheetError = null);

                        final cleanPhone = phoneCtrl.text.trim();
                        if (cleanPhone.isNotEmpty &&
                            !BuyerValidationRules.phoneRegex.hasMatch(
                              BuyerValidationRules.normalizePhone(cleanPhone),
                            )) {
                          setSheetState(
                            () => sheetError = 'Please enter a valid 11-digit Philippine mobile number starting with 09',
                          );
                          return;
                        }

                        final valRes = BuyerAccountService.instance.editProfile(
                          firstName: firstNameCtrl.text,
                          lastName: lastNameCtrl.text,
                        );

                        if (!valRes.success) {
                          setSheetState(() => sheetError = valRes.message);
                          return;
                        }

                        if (ApiClient.instance.hasToken) {
                          final remoteRes = await BuyerAccountService.instance
                              .updateProfileRemote(
                                firstName: firstNameCtrl.text.trim(),
                                lastName: lastNameCtrl.text.trim(),
                                phone: cleanPhone,
                              );
                          if (!remoteRes.success) {
                            setSheetState(() => sheetError = remoteRes.message);
                            return;
                          }
                        }

                        BuyerAccountService
                                .instance
                                .currentBuyerSession
                                ?.mobileNumber =
                            cleanPhone;

                        final rawUsername = usernameCtrl.text.trim();
                        final cleanUsername = rawUsername.isNotEmpty
                            ? (rawUsername.startsWith('@')
                                  ? rawUsername
                                  : '@$rawUsername')
                            : '@${(session?.email ?? profile.email).split('@').first}';

                        ProfileService.instance.updateProfile(
                          name:
                              '${firstNameCtrl.text.trim()} ${lastNameCtrl.text.trim()}',
                          username: cleanUsername,
                          phone: cleanPhone,
                          address: addressCtrl.text,
                        );
                        if (!mounted) return;
                        setState(() {});
                        sheetNavigator.pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text('Profile updated successfully!'),
                              ],
                            ),
                            backgroundColor: Color(0xFF0066FF),
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

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        BuyerAccountService.instance,
        ProfileService.instance,
        OrderService.instance,
        AddressService.instance,
        WishlistService.instance,
        CartService.instance,
        ChatService.instance,
        ShopService.instance,
        PaymentMethodService.instance,
      ]),
      builder: (context, _) {
        if (!_useLegacyProfile) {
          return _buildRefinedProfile(context);
        }

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

                  // User Profile Avatar & Info Header
                  _buildUserProfileHeader(),
                  const SizedBox(height: 20),

                  // Key Quick Stats Row (Orders, Wishlist, Vouchers)
                  _buildQuickStatsRow(),
                  const SizedBox(height: 20),

                  // My Purchases Section Card
                  _buildMyPurchasesSection(context),
                  const SizedBox(height: 24),

                  // SHOPPING & BENEFITS Group
                  _buildSectionHeader('SHOPPING & BENEFITS'),
                  const SizedBox(height: 10),
                  _buildShoppingBenefitsCard(context),
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
                  const SizedBox(height: 110),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRefinedProfile(BuildContext context) {
    final theme = Theme.of(context);
    final buyer = BuyerAccountService.instance.currentBuyerSession;
    final profile = ProfileService.instance;
    final loggedIn = BuyerAccountService.instance.isLoggedIn;
    final payment = PaymentMethodService.instance.defaultMethod;
    final addressCount = AddressService.instance.addresses.length;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 820),
            child: ListView(
              key: const ValueKey('profile-dashboard-scroll'),
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                NexoraSpacing.md,
                NexoraSpacing.md,
                NexoraSpacing.md,
                112,
              ),
              children: [
                ProfileIdentityCard(
                  key: const ValueKey('profile-identity-card'),
                  name: loggedIn
                      ? (buyer?.fullName ?? profile.name)
                      : 'Welcome to Nexora',
                  subtitle: loggedIn ? (buyer?.email ?? profile.email) : 'Sign in to sync orders, saved items, and account preferences.',
                  avatarImage: loggedIn ? _getAvatarImageProvider() : null,
                  isGuest: !loggedIn,
                  onAvatarTap: loggedIn ? _showEditProfileSheet : null,
                  actionLabel: loggedIn ? 'Edit profile' : 'Sign in',
                  onAction: loggedIn
                      ? _showEditProfileSheet
                      : () => Navigator.pushNamed(context, AppRoutes.login),
                ),
                const SizedBox(height: NexoraSpacing.md),
                ProfileMetricsPanel(
                  items: [
                    ProfileMetricData(
                      value: '${OrderService.instance.totalOrderCount}',
                      label: 'Orders',
                      onTap: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.orders,
                      ),
                    ),
                    ProfileMetricData(
                      value: '${WishlistService.instance.itemCount}',
                      label: 'Wishlist',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.wishlist),
                    ),
                    ProfileMetricData(
                      value: '${ShopService.instance.followedShopCount}',
                      label: 'Following',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.followedStores,
                      ),
                    ),
                    ProfileMetricData(
                      value: '$addressCount',
                      label: 'Addresses',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.myAddresses),
                    ),
                  ],
                ),
                const SizedBox(height: NexoraSpacing.xl),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Purchases',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    TextButton(
                      key: const ValueKey('profile-view-all-orders'),
                      onPressed: () => Navigator.pushReplacementNamed(
                        context,
                        AppRoutes.orders,
                      ),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: NexoraSpacing.xs),
                ProfileShortcutGrid(
                  items: [
                    ProfileShortcutData(
                      icon: Icons.inventory_2_outlined,
                      label: 'To Ship',
                      onTap: () => _openOrderFilter(context, 1),
                    ),
                    ProfileShortcutData(
                      icon: Icons.local_shipping_outlined,
                      label: 'To Receive',
                      onTap: () => _openOrderFilter(context, 2),
                    ),
                    ProfileShortcutData(
                      icon: Icons.rate_review_outlined,
                      label: 'Completed',
                      onTap: () => _openOrderFilter(context, 3),
                    ),
                    ProfileShortcutData(
                      icon: Icons.assignment_return_outlined,
                      label: 'Return/Refund',
                      onTap: () => _openOrderFilter(context, 4),
                    ),
                  ],
                ),
                const SizedBox(height: NexoraSpacing.xl),
                ProfileSettingGroup(
                  title: 'Account',
                  children: [
                    ProfileSettingTile(
                      icon: NexoraTheme.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      title: 'Appearance',
                      subtitle: NexoraTheme.isDarkMode
                          ? 'Dark Mode (Active)'
                          : 'Light Mode (Active)',
                      trailingWidget: Switch.adaptive(
                        value: NexoraTheme.isDarkMode,
                        activeTrackColor: const Color(0xFF0075FF),
                        onChanged: (val) {
                          NexoraTheme.toggleTheme();
                        },
                      ),
                      onTap: () {
                        NexoraTheme.toggleTheme();
                      },
                    ),
                    ProfileSettingTile(
                      icon: Icons.shield_outlined,
                      title: 'Account and security',
                      subtitle:
                          'Profile details, password, and sign-in security',
                      onTap: () => showAccountSecurityModal(context),
                    ),
                    ProfileSettingTile(
                      icon: Icons.location_on_outlined,
                      title: 'My addresses',
                      subtitle: 'Delivery recipients and saved locations',
                      trailing: '$addressCount saved',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.myAddresses),
                    ),
                    ProfileSettingTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Payment methods',
                      subtitle: 'Choose how you pay at checkout',
                      trailing: payment.name,
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.paymentMethods,
                      ),
                    ),
                    ProfileSettingTile(
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Orders, messages, offers, and phone alerts',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.notificationPreferences,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NexoraSpacing.xl),
                ProfileSettingGroup(
                  title: 'Shopping',
                  children: [
                    ProfileSettingTile(
                      icon: Icons.favorite_border_rounded,
                      title: 'Saved wishlist',
                      subtitle: 'Products you want to revisit',
                      trailing: '${WishlistService.instance.itemCount} items',
                      onTap: () =>
                          Navigator.pushNamed(context, AppRoutes.wishlist),
                    ),
                    ProfileSettingTile(
                      icon: Icons.storefront_outlined,
                      title: 'Followed stores',
                      subtitle: 'Shops and brands you follow',
                      trailing: '${ShopService.instance.followedShopCount}',
                      onTap: () => Navigator.pushNamed(
                        context,
                        AppRoutes.followedStores,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: NexoraSpacing.xl),
                ProfileSettingGroup(
                  title: 'Support',
                  children: [
                    ProfileSettingTile(
                      icon: Icons.support_agent_rounded,
                      title: 'Help center and support',
                      subtitle: 'Ask a question or open a support ticket',
                      onTap: () => Navigator.pushNamed(context, AppRoutes.chat),
                    ),
                    ProfileSettingTile(
                      icon: Icons.shield_outlined,
                      title: 'Safety & Reports',
                      subtitle: 'Report an issue or track submitted reports',
                      onTap: () => _showSafetyAndReportsMenu(context),
                    ),
                  ],
                ),
                const SizedBox(height: NexoraSpacing.xl),
                if (loggedIn)
                  OutlinedButton.icon(
                    key: const ValueKey('profile-logout-action'),
                    onPressed: () => _showLogoutConfirmationDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NexoraTheme.error,
                      side: const BorderSide(color: NexoraTheme.error),
                    ),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out'),
                  )
                else
                  FilledButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, AppRoutes.login),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Sign in or create account'),
                  ),
                const SizedBox(height: NexoraSpacing.lg),
                Text(
                  'Nexora v2.4.1 (Build 890)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openOrderFilter(BuildContext context, int initialIndex) {
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.orders,
      arguments: {'initialIndex': initialIndex},
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
              icon: const Icon(
                Icons.settings_outlined,
                color: Color(0xFF0F172A),
                size: 22,
              ),
              tooltip: 'Settings & Preferences',
              onPressed: () {
                _showSettingsModal(context);
              },
            ),
            // Cart Icon with Real-Time Badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.shopping_cart_outlined,
                    color: Color(0xFF0F172A),
                    size: 22,
                  ),
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
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
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
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: Color(0xFF0F172A),
                    size: 22,
                  ),
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
                      constraints: const BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
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
    final isLoggedIn = BuyerAccountService.instance.isLoggedIn;
    final profile = ProfileService.instance;
    final session = BuyerAccountService.instance.currentBuyerSession;

    if (!isLoggedIn) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
          children: [
            // Guest Avatar Placeholder
            Container(
              width: 58,
              height: 58,
              decoration: const BoxDecoration(
                color: Color(0xFFEFF6FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_outline_rounded,
                size: 32,
                color: Color(0xFF0066FF),
              ),
            ),
            const SizedBox(width: 14),

            // Guest User Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Guest User',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Sign in to sync orders & perks',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Direct Sign In Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.login);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066FF),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'Sign In',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      );
    }

    final displayName = session?.fullName ?? profile.name;
    final displayUsername = session != null
        ? '@${session.email.split('@').first}'
        : profile.username;

    return Row(
      children: [
        // User Photo Avatar
        GestureDetector(
          onTap: _showEditProfileSheet,
          child: Stack(
            children: [
              Builder(
                builder: (context) {
                  final avatarProvider = _getAvatarImageProvider();
                  return Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _darkMode
                          ? const Color(0xFF1E293B)
                          : const Color(0xFFF1F5F9),
                      image: avatarProvider != null
                          ? DecorationImage(
                              image: avatarProvider,
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: avatarProvider == null
                        ? Icon(
                            Icons.person_rounded,
                            size: 34,
                            color: _darkMode
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF64748B),
                          )
                        : null,
                  );
                },
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066FF),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 11,
                  ),
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
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF0F172A),
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                displayUsername,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w500,
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
    final isLoggedIn = BuyerAccountService.instance.isLoggedIn;
    final profile = ProfileService.instance;
    final orderCount = OrderService.instance.activeOrders.length;
    final followCount = ShopService.instance.followedShopCount;
    final voucherDisplay =
        '${profile.voucherCount > 0 ? profile.voucherCount : 5}';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
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
          _buildStatItem(isLoggedIn ? '$orderCount' : '-', 'Orders', () {
            if (!isLoggedIn) {
              GuestAuthGuard.requireLogin(
                context,
                title: 'Sign In to View Orders',
                message: 'Sign in to track orders, shipping status, and view past receipts.',
              );
              return;
            }
            Navigator.pushReplacementNamed(context, AppRoutes.orders);
          }),
          _buildStatItem(isLoggedIn ? '$followCount' : '-', 'Following', () {
            if (!isLoggedIn) {
              GuestAuthGuard.requireLogin(
                context,
                title: 'Followed Stores',
                message: 'Sign in to see and manage the stores you follow on Nexora.',
              );
              return;
            }
            Navigator.pushNamed(context, AppRoutes.followedStores);
          }),
          _buildStatItem(
            '${WishlistService.instance.itemCount}',
            'Wishlist',
            () {
              Navigator.pushNamed(context, AppRoutes.wishlist);
            },
          ),
          _buildStatItem(isLoggedIn ? voucherDisplay : '-', 'Vouchers', () {
            if (!isLoggedIn) {
              GuestAuthGuard.requireLogin(
                context,
                title: 'Member Vouchers',
                message: 'Sign in or create an account to claim discount vouchers and free shipping.',
              );
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  '$voucherDisplay Discount & Free Shipping Vouchers Available',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String val,
    String label,
    VoidCallback onTap, {
    Color? textColor,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  val,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: textColor ?? const Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyPurchasesSection(BuildContext context) {
    final isLoggedIn = BuyerAccountService.instance.isLoggedIn;

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
                  if (!isLoggedIn) {
                    GuestAuthGuard.requireLogin(
                      context,
                      title: 'My Purchases',
                      message: 'Sign in to review and track all your active purchases and completed orders.',
                    );
                    return;
                  }
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
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: Color(0xFF0066FF),
                    ),
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
                isLoggedIn
                    ? OrderService.instance.activeOrders
                          .where(
                            (o) =>
                                o.statusText.toLowerCase() == 'to pay' ||
                                o.statusText.toLowerCase() == 'unpaid',
                          )
                          .length
                    : 0,
                () {
                  if (!isLoggedIn) {
                    GuestAuthGuard.requireLogin(context, title: 'My Purchases');
                    return;
                  }
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.orders,
                    arguments: {'initialIndex': 1},
                  );
                },
                isHighlighted: false,
              ),
              _buildPurchaseStatusItem(
                'To Ship',
                Icons.inventory_2_outlined,
                isLoggedIn
                    ? OrderService.instance.activeOrders
                          .where(
                            (o) =>
                                o.statusText.toLowerCase() == 'to ship' ||
                                o.statusText.toLowerCase() == 'processing',
                          )
                          .length
                    : 0,
                () {
                  if (!isLoggedIn) {
                    GuestAuthGuard.requireLogin(context, title: 'My Purchases');
                    return;
                  }
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.orders,
                    arguments: {'initialIndex': 1},
                  );
                },
                isHighlighted: false,
              ),
              _buildPurchaseStatusItem(
                'To Receive',
                Icons.local_shipping_outlined,
                isLoggedIn
                    ? OrderService.instance.activeOrders
                          .where(
                            (o) =>
                                o.statusText.toLowerCase() == 'to receive' ||
                                o.statusText.toLowerCase() == 'shipping' ||
                                o.statusText.toLowerCase() == 'shipped' ||
                                o.statusText.toLowerCase() == 'in transit' ||
                                o.statusText.toLowerCase() ==
                                    'out for delivery',
                          )
                          .length
                    : 0,
                () {
                  if (!isLoggedIn) {
                    GuestAuthGuard.requireLogin(context, title: 'My Purchases');
                    return;
                  }
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.orders,
                    arguments: {'initialIndex': 2},
                  );
                },
                isHighlighted:
                    isLoggedIn &&
                    OrderService.instance.activeOrders.any(
                      (o) =>
                          o.statusText.toLowerCase() == 'to receive' ||
                          o.statusText.toLowerCase() == 'shipping' ||
                          o.statusText.toLowerCase() == 'shipped' ||
                          o.statusText.toLowerCase() == 'in transit' ||
                          o.statusText.toLowerCase() == 'out for delivery',
                    ),
              ),
              _buildPurchaseStatusItem(
                'Completed',
                Icons.rate_review_outlined,
                isLoggedIn
                    ? OrderService.instance.pastOrders
                          .where(
                            (o) =>
                                o.rawStatus == 'delivered' ||
                                o.rawStatus == 'completed',
                          )
                          .length
                    : 0,
                () {
                  if (!isLoggedIn) {
                    GuestAuthGuard.requireLogin(context, title: 'My Purchases');
                    return;
                  }
                  Navigator.pushReplacementNamed(
                    context,
                    AppRoutes.orders,
                    arguments: {'initialIndex': 3},
                  );
                },
                isHighlighted: false,
              ),
            ],
          ),

          // Active Parcel Status Banner Box (Only rendered if user is logged in AND there are active in-transit orders)
          if (isLoggedIn)
            Builder(
              builder: (context) {
                final inTransitOrders = OrderService.instance.activeOrders
                    .where(
                      (o) =>
                          o.statusText.toLowerCase() == 'to receive' ||
                          o.statusText.toLowerCase() == 'shipping' ||
                          o.statusText.toLowerCase() == 'shipped' ||
                          o.statusText.toLowerCase() == 'in transit' ||
                          o.statusText.toLowerCase() == 'out for delivery',
                    )
                    .toList();

                if (inTransitOrders.isEmpty) {
                  return const SizedBox.shrink();
                }

                final activeOrder = inTransitOrders.first;

                return Container(
                  margin: const EdgeInsets.only(top: 16),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
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
                        child: const Icon(
                          Icons.sync_rounded,
                          color: Color(0xFF050B28),
                          size: 16,
                        ),
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
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          'Track',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
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
    String label,
    IconData icon,
    int badgeCount,
    VoidCallback onTap, {
    required bool isHighlighted,
  }) {
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                color: isHighlighted
                    ? const Color(0xFF0066FF)
                    : const Color(0xFF475569),
              ),
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
    final isLoggedIn = BuyerAccountService.instance.isLoggedIn;

    return _buildGroupCard([
      _buildListTile(
        icon: Icons.location_on_outlined,
        title: 'My Addresses',
        subtitle: isLoggedIn
            ? (AddressService.instance.defaultAddress?.fullAddress ??
                  (ProfileService.instance.address.isNotEmpty
                      ? ProfileService.instance.address
                      : 'No delivery address set'))
            : 'Sign in to view saved addresses',
        onTap: () {
          if (!isLoggedIn) {
            GuestAuthGuard.requireLogin(
              context,
              title: 'Saved Addresses',
              message: 'Sign in or create an account to view and manage delivery addresses.',
            );
            return;
          }
          Navigator.pushNamed(context, AppRoutes.myAddresses);
        },
      ),
      AnimatedBuilder(
        animation: PaymentMethodService.instance,
        builder: (context, _) {
          if (!isLoggedIn) {
            return _buildListTile(
              icon: Icons.credit_card_rounded,
              title: 'Payment Methods',
              subtitle: 'Sign in to link GCash & payment cards',
              onTap: () {
                GuestAuthGuard.requireLogin(
                  context,
                  title: 'Payment Methods',
                  message: 'Sign in or create an account to manage GCash and payment options.',
                );
              },
            );
          }
          final gcash = PaymentMethodService.instance.gcashMethod;
          final defaultMethod = PaymentMethodService.instance.defaultMethod;
          String subtitle = 'Manage GCash & Cards';
          if (gcash != null && gcash.isLinked) {
            subtitle =
                'GCash (${gcash.formattedDisplay}) • ${defaultMethod.type == PaymentType.gcash ? "Default" : "Linked"}';
          }
          return _buildListTile(
            icon: Icons.credit_card_rounded,
            title: 'Payment Methods',
            subtitle: subtitle,
            onTap: () {
              Navigator.pushNamed(context, AppRoutes.paymentMethods);
            },
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

  void _showSettingsModal(BuildContext parentContext) {
    showModalBottomSheet(
      context: parentContext,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            final isLoggedIn = BuyerAccountService.instance.isLoggedIn;
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
              decoration: const BoxDecoration(
                color: Color(0xFFF6F8FC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Settings & Preferences',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Manage account security, alerts & appearance',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close_rounded,
                            color: Color(0xFF64748B),
                          ),
                          onPressed: () => Navigator.pop(sheetContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildSectionHeader('PREFERENCES & SECURITY'),
                    const SizedBox(height: 10),
                    _buildGroupCard([
                      _buildListTile(
                        icon: Icons.security_rounded,
                        title: 'Account Security',
                        subtitle: isLoggedIn
                            ? 'Password, Email & Phone via OTP'
                            : 'Sign in to protect and secure your account',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          if (!isLoggedIn) {
                            GuestAuthGuard.requireLogin(
                              parentContext,
                              title: 'Account Security',
                              message: 'Sign in or register to configure passwords, two-factor auth, and profile security.',
                            );
                            return;
                          }
                          showAccountSecurityModal(parentContext);
                        },
                      ),
                      _buildListTile(
                        icon: Icons.notifications_none_rounded,
                        title: 'Notification Preferences',
                        subtitle: 'Push, Phone Alerts & Courier Tracking',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Navigator.pushNamed(
                            parentContext,
                            AppRoutes.notificationPreferences,
                          );
                        },
                      ),
                      _buildListTile(
                        icon: Icons.language_rounded,
                        title: 'Language & Currency',
                        subtitle: 'English (PH) • PHP (₱)',
                        onTap: () {
                          ScaffoldMessenger.of(parentContext).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Language & Currency: English (PH) • PHP (₱)',
                              ),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Color(0xFFF1F5F9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.nightlight_round,
                                color: Color(0xFF0066FF),
                                size: 18,
                              ),
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
                                setSheetState(() {});
                                if (widget.onToggleDarkMode != null) {
                                  widget.onToggleDarkMode!();
                                }
                                ScaffoldMessenger.of(parentContext)
                                    .showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          _darkMode
                                              ? 'Dark Mode enabled!'
                                              : 'Light Mode enabled!',
                                        ),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                              },
                            ),
                          ],
                        ),
                      ),
                    ]),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        icon: Icons.shield_outlined,
        title: 'Safety & Reports',
        subtitle: 'Report an issue or view my safety reports',
        onTap: () => _showSafetyAndReportsMenu(context),
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

  void _showSafetyAndReportsMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Safety & Reports',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: const Icon(Icons.flag_outlined, color: Color(0xFFE11D48)),
                title: const Text('Report an Issue'),
                subtitle: const Text('Report a seller, product, scam, or abuse'),
                onTap: () {
                  Navigator.pop(ctx);
                  showSafetyReportSheet(
                    context,
                    defaultCategory: 'other_violation',
                    defaultTitle: '',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.shield_outlined, color: Color(0xFF0066FF)),
                title: const Text('My Safety Reports'),
                subtitle: const Text('Track investigation status and appeals'),
                onTap: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MySafetyReportsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
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
    final isLoggedIn = BuyerAccountService.instance.isLoggedIn;

    if (!isLoggedIn) {
      return Container(
        width: double.infinity,
        height: 50,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(
            colors: [Color(0xFF0066FF), Color(0xFF0052CC)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0066FF).withValues(alpha: 0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.login);
          },
          icon: const Icon(Icons.login_rounded, color: Colors.white, size: 18),
          label: const Text(
            'Sign In or Create Account',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFFECDD3)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 8),
        ],
      ),
      child: TextButton.icon(
        onPressed: () => _showLogoutConfirmationDialog(context),
        icon: const Icon(
          Icons.logout_rounded,
          color: Color(0xFFE11D48),
          size: 18,
        ),
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

  void _showLogoutConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFFE4E6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.logout_rounded,
                color: Color(0xFFE11D48),
                size: 28,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Log Out of Nexora?',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Are you sure you want to log out? You will need to sign in again to access your orders and cart.',
              style: TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogCtx);
                    // Clear session from Laravel API token, BuyerAccount, Supabase, and cache
                    await BuyerAccountService.instance.logoutRemote();
                    try {
                      await SupabaseAuthService.instance.signOut();
                    } catch (_) {}
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Color(0xFF0F172A),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Log Out',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
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
            style: TextStyle(fontSize: 10.5, color: Colors.grey.shade400),
          ),
        ),
      ],
    );
  }

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData prefixIcon,
    bool isDark = false,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
        fontSize: 13.5,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        size: 18,
      ),
      filled: true,
      fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.transparent,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: isDark ? const Color(0xFF334155) : Colors.transparent,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF0066FF), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    );
  }
}
