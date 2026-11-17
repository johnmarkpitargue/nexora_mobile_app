import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'wishlist_service.dart';

class ProfileService extends ChangeNotifier {
  static final ProfileService instance = ProfileService._internal();
  ProfileService._internal();

  String _name = '';
  String _username = '';
  String _email = '';
  String _phone = '';
  String _address = '';
  String _avatarUrl = '';
  Uint8List? _avatarBytes;
  double _walletBalance = 0.0;
  final int _voucherCount = 0;

  // Getters
  String get name => _name;
  String get username => _username;
  String get email => _email;
  String get phone => _phone;
  String get address => _address;
  String get avatarUrl => _avatarUrl;
  Uint8List? get avatarBytes => _avatarBytes;
  double get walletBalance => _walletBalance;
  int get voucherCount => _voucherCount;
  int get wishlistCount => WishlistService.instance.itemCount;

  bool get hasCustomAvatarBytes => _avatarBytes != null && _avatarBytes!.isNotEmpty;

  void updateProfile({
    String? name,
    String? username,
    String? email,
    String? phone,
    String? address,
    String? avatarUrl,
    Uint8List? avatarBytes,
  }) {
    if (name != null) _name = name.trim();
    if (username != null) _username = username.trim();
    if (email != null) _email = email.trim();
    if (phone != null) _phone = phone.trim();
    if (address != null) _address = address.trim();
    if (avatarUrl != null) {
      _avatarUrl = avatarUrl;
      _avatarBytes = null;
    }
    if (avatarBytes != null) {
      _avatarBytes = avatarBytes;
    }
    notifyListeners();
  }

  void updateAvatarBytes(Uint8List bytes) {
    _avatarBytes = bytes;
    notifyListeners();
  }

  void updateAvatarUrl(String url) {
    _avatarUrl = url;
    _avatarBytes = null;
    notifyListeners();
  }

  void updateWalletBalance(double newBalance) {
    _walletBalance = newBalance;
    notifyListeners();
  }
}
