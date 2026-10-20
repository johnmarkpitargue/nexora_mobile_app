import 'package:flutter/material.dart';
import 'profile_service.dart';

class AddressModel {
  final String id;
  final String fullName;
  final String phone;
  final String regionCity;
  final String postalCode;
  final String streetBuilding;
  final String label; // 'Home' or 'Work'
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.regionCity,
    required this.postalCode,
    required this.streetBuilding,
    required this.label,
    this.isDefault = false,
  });

  String get fullAddress {
    final parts = [streetBuilding, regionCity, postalCode].where((s) => s.trim().isNotEmpty).toList();
    return parts.join(', ');
  }

  AddressModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? regionCity,
    String? postalCode,
    String? streetBuilding,
    String? label,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      regionCity: regionCity ?? this.regionCity,
      postalCode: postalCode ?? this.postalCode,
      streetBuilding: streetBuilding ?? this.streetBuilding,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class AddressService extends ChangeNotifier {
  static final AddressService instance = AddressService._internal();

  AddressService._internal() {
    _syncDefaultWithProfile();
  }

  final List<AddressModel> _addresses = [
    AddressModel(
      id: 'addr_1',
      fullName: 'John Mark Pitargue',
      phone: '(+63) 975 963 2035',
      streetBuilding: '192 Tuy-Baanan',
      regionCity: 'Liliw, Laguna, South Luzon',
      postalCode: '4004',
      label: 'Home',
      isDefault: true,
    ),
    AddressModel(
      id: 'addr_2',
      fullName: 'Ma. Sofia Ballescas',
      phone: '(+63) 949 692 3307',
      streetBuilding: '355 Sta Catalina, Holy Spirit',
      regionCity: 'Quezon City, Metro Manila',
      postalCode: '1127',
      label: 'Work',
      isDefault: false,
    ),
  ];

  List<AddressModel> get addresses => List.unmodifiable(_addresses);

  AddressModel? get defaultAddress {
    try {
      return _addresses.firstWhere((a) => a.isDefault);
    } catch (_) {
      return _addresses.isNotEmpty ? _addresses.first : null;
    }
  }

  void setDefaultAddress(String id) {
    for (int i = 0; i < _addresses.length; i++) {
      final a = _addresses[i];
      _addresses[i] = a.copyWith(isDefault: a.id == id);
    }
    _syncDefaultWithProfile();
    notifyListeners();
  }

  void addAddress(AddressModel newAddress) {
    if (newAddress.isDefault || _addresses.isEmpty) {
      for (int i = 0; i < _addresses.length; i++) {
        _addresses[i] = _addresses[i].copyWith(isDefault: false);
      }
      _addresses.insert(0, newAddress.copyWith(isDefault: true));
    } else {
      _addresses.add(newAddress);
    }
    _syncDefaultWithProfile();
    notifyListeners();
  }

  void updateAddress(AddressModel updatedAddress) {
    final index = _addresses.indexWhere((a) => a.id == updatedAddress.id);
    if (index != -1) {
      if (updatedAddress.isDefault) {
        for (int i = 0; i < _addresses.length; i++) {
          if (i != index) {
            _addresses[i] = _addresses[i].copyWith(isDefault: false);
          }
        }
      }
      _addresses[index] = updatedAddress;
      _syncDefaultWithProfile();
      notifyListeners();
    }
  }

  void deleteAddress(String id) {
    final wasDefault = _addresses.firstWhere((a) => a.id == id, orElse: () => _addresses.first).isDefault;
    _addresses.removeWhere((a) => a.id == id);
    if (wasDefault && _addresses.isNotEmpty) {
      _addresses[0] = _addresses[0].copyWith(isDefault: true);
    }
    _syncDefaultWithProfile();
    notifyListeners();
  }

  void _syncDefaultWithProfile() {
    final def = defaultAddress;
    if (def != null) {
      ProfileService.instance.updateProfile(
        name: def.fullName,
        phone: def.phone,
        address: def.fullAddress,
      );
    }
  }
}
