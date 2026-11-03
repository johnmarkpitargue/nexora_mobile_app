import 'package:flutter/material.dart';
import 'buyer_account_service.dart';
import 'profile_service.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

class AddressModel {
  final String id;
  final String fullName;
  final String phone;
  final String region;
  final String province;
  final String city;
  final String barangay;
  final String regionCity;
  final String postalCode;
  final String streetBuilding;
  final String label; // 'Home' or 'Work'
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  AddressModel({
    required this.id,
    required this.fullName,
    required this.phone,
    this.region = '',
    this.province = '',
    this.city = '',
    this.barangay = '',
    required this.regionCity,
    required this.postalCode,
    required this.streetBuilding,
    required this.label,
    this.isDefault = false,
    this.latitude,
    this.longitude,
  });

  String get streetAddress => streetBuilding;

  String get fullAddress {
    final locationParts = [
      streetBuilding,
      barangay,
      city,
      regionCity.isNotEmpty && !regionCity.contains(city) ? regionCity : '',
      postalCode,
    ].where((s) => s.trim().isNotEmpty).toSet().toList();
    return locationParts.join(', ');
  }

  AddressModel copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? region,
    String? province,
    String? city,
    String? barangay,
    String? regionCity,
    String? postalCode,
    String? streetBuilding,
    String? label,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return AddressModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      region: region ?? this.region,
      province: province ?? this.province,
      city: city ?? this.city,
      barangay: barangay ?? this.barangay,
      regionCity: regionCity ?? this.regionCity,
      postalCode: postalCode ?? this.postalCode,
      streetBuilding: streetBuilding ?? this.streetBuilding,
      label: label ?? this.label,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toApiJson() => {
    'label': label.isNotEmpty ? label : 'Home',
    'recipient_name': fullName,
    'phone': phone,
    'street': streetBuilding.isNotEmpty ? streetBuilding : fullAddress,
    'barangay': barangay.isNotEmpty ? barangay : 'Central',
    'city': city.isNotEmpty ? city : 'Makati',
    'province': province,
    'region': region,
    'postal_code': postalCode.isNotEmpty ? postalCode : '1200',
    'is_default': isDefault,
    if (latitude != null) 'latitude': latitude,
    if (longitude != null) 'longitude': longitude,
  };

  factory AddressModel.fromApiJson(Map<String, dynamic> json) {
    return AddressModel(
      id: json['id'].toString(),
      fullName: json['recipient_name'] as String? ?? json['fullName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      region: json['region'] as String? ?? '',
      province: json['province'] as String? ?? '',
      city: json['city'] as String? ?? '',
      barangay: json['barangay'] as String? ?? '',
      regionCity: [json['region'], json['province'], json['city'], json['barangay']]
          .where((s) => s != null && (s as String).isNotEmpty)
          .join(', '),
      postalCode: json['postal_code'] as String? ?? json['postalCode'] as String? ?? '',
      streetBuilding: json['street'] as String? ?? json['streetBuilding'] as String? ?? '',
      label: json['label'] as String? ?? 'Home',
      isDefault: json['is_default'] == true || json['is_default'] == 1 || json['isDefault'] == true,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
    );
  }
}

class AddressService extends ChangeNotifier {
  static final AddressService instance = AddressService._internal();

  AddressService._internal() {
    BuyerAccountService.instance.addListener(_onBuyerChanged);
    _syncDefaultWithProfile();
  }

  void _onBuyerChanged() {
    _syncDefaultWithProfile();
    loadAddressesFromApi();
    notifyListeners();
  }

  static const int maxAddresses = 10;

  // Cascading Philippine Geographical Data (BUY-ADDR-001, BUY-ADDR-002, BUY-ADDR-003)
  static const Map<String, Map<String, List<String>>> locationHierarchy = {
    'National Capital Region (NCR)': {
      'Makati City': ['Bel-Air', 'Poblacion', 'San Lorenzo', 'Pio del Pilar', 'San Antonio'],
      'Quezon City': ['Holy Spirit', 'Batasan Hills', 'Diliman', 'Commonwealth', 'Cubao'],
      'Taguig City (BGC)': ['Fort Bonifacio', 'Western Bicutan', 'Ususan', 'Pinagsama'],
      'City of Manila': ['Malate', 'Ermita', 'Intramuros', 'Sampaloc', 'Binondo'],
      'Pasig City': ['San Antonio', 'Kapitolyo', 'Ortigas Center', 'Ugong'],
      'Mandaluyong City': ['Highway Hills', 'Wack-Wack', 'Plainview', 'Barangka'],
    },
    'Region IV-A (CALABARZON)': {
      'Liliw, Laguna': ['Tuy-Baanan', 'Rizal', 'Bongkol', 'San Roque', 'Ilayang Sungi', 'Poblacion'],
      'Calamba City, Laguna': ['Real', 'Halang', 'Bucal', 'Canlubang', 'Pansol', 'Turbina'],
      'Santa Rosa, Laguna': ['Balibago', 'Don Jose', 'Tagapo', 'Macabling', 'Dita'],
      'Biñan City, Laguna': ['San Antonio', 'Canlalay', 'San Vicente', 'Malaban'],
      'Cabuyao City, Laguna': ['Sala', 'Banlic', 'Pulo', 'Mamatid'],
      'San Pedro City, Laguna': ['Poblacion', 'San Vicente', 'Pacita Complex', 'Landayan'],
      'San Pablo City, Laguna': ['Poblacion', 'San Jose', 'Concepcion', 'Del Remedio'],
      'Los Baños, Laguna': ['Batong Malake', 'College', 'Mayondon', 'Bayog'],
      'Santa Cruz, Laguna': ['Poblacion', 'Pagsawitan', 'Bubukal', 'Gatid'],
      'Pagsanjan, Laguna': ['Poblacion I', 'Poblacion II', 'Sampaloc', 'Maulawin'],
      'Nagcarlan, Laguna': ['Poblacion I', 'Poblacion II', 'Taytay', 'Oples'],
      'Antipolo, Rizal': ['San Roque', 'Dela Paz', 'Mayamot', 'Cupang'],
      'Imus, Cavite': ['Bucandala', 'Malagasang', 'Poblacion', 'Anabu'],
    },
    'Region VII (Central Visayas)': {
      'Cebu City': ['Lahug', 'Mabolo', 'Banilad', 'Guadalupe', 'Kasambagan'],
      'Mandaue City': ['Subangdaku', 'Tipolo', 'Bakilid', 'Centro'],
      'Lapu-Lapu City': ['Mactan', 'Maribago', 'Pusok', 'Basak'],
    },
    'Region XI (Davao Region)': {
      'Davao City': ['Poblacion', 'Buhangin', 'Talomo', 'Matina', 'Toril'],
    },
    'Region VI (Western Visayas)': {
      'Bacolod City': ['Mandalagan', 'Villamonte', 'Bata', 'Singcang'],
      'Iloilo City': ['Mandurriao', 'Jaro', 'Molo', 'City Proper'],
    },
    'Region III (Central Luzon)': {
      'San Fernando, Pampanga': ['Dolores', 'San Jose', 'Sindalan', 'San Agustin'],
    },
    'Region X (Northern Mindanao)': {
      'Cagayan de Oro': ['Carmen', 'Macasandig', 'Nazareth', 'Lapasan'],
    },
  };

  static List<String> get regions => locationHierarchy.keys.toList();

  static List<String> getCities(String region) {
    return locationHierarchy[region]?.keys.toList() ?? [];
  }

  static List<String> getBarangays(String region, String city) {
    return locationHierarchy[region]?[city] ?? [];
  }

  static String getDefaultPostalCode(String city) {
    if (city.contains('Liliw')) return '4004';
    if (city.contains('Calamba')) return '4027';
    if (city.contains('Santa Rosa')) return '4026';
    if (city.contains('Biñan')) return '4024';
    if (city.contains('Cabuyao')) return '4025';
    if (city.contains('San Pedro')) return '4023';
    if (city.contains('San Pablo')) return '4000';
    if (city.contains('Los Baños')) return '4030';
    if (city.contains('Santa Cruz')) return '4009';
    if (city.contains('Pagsanjan')) return '4008';
    if (city.contains('Nagcarlan')) return '4002';
    if (city.contains('Quezon City')) return '1127';
    if (city.contains('Makati')) return '1209';
    if (city.contains('Taguig') || city.contains('BGC')) return '1634';
    if (city.contains('Manila')) return '1000';
    if (city.contains('Pasig')) return '1605';
    if (city.contains('Mandaluyong')) return '1550';
    if (city.contains('Cebu')) return '6000';
    if (city.contains('Mandaue')) return '6014';
    if (city.contains('Lapu-Lapu')) return '6015';
    if (city.contains('Davao')) return '8000';
    if (city.contains('Bacolod')) return '6100';
    if (city.contains('Iloilo')) return '5000';
    if (city.contains('Antipolo')) return '1870';
    if (city.contains('Imus')) return '4103';
    if (city.contains('San Fernando')) return '2000';
    if (city.contains('Cagayan de Oro')) return '9000';
    return '1000';
  }

  final Map<String, List<AddressModel>> _userAddresses = {};

  String get _currentUserKey {
    final b = BuyerAccountService.instance.currentBuyer ??
        BuyerAccountService.instance.currentUnverifiedBuyer;
    return (b != null && b.email.isNotEmpty)
        ? b.email.toLowerCase().trim()
        : 'guest';
  }

  List<AddressModel> get _currentAddresses {
    return _userAddresses.putIfAbsent(
      _currentUserKey,
      () => _createInitialAddressesForUser(_currentUserKey),
    );
  }

  List<AddressModel> _createInitialAddressesForUser(String key) {
    return [];
  }

  List<AddressModel> get addresses => List.unmodifiable(_currentAddresses);
  bool get canAddAddress => _currentAddresses.length < maxAddresses;

  AddressModel? get defaultAddress {
    final list = _currentAddresses;
    try {
      return list.firstWhere((a) => a.isDefault);
    } catch (_) {
      return list.isNotEmpty ? list.first : null;
    }
  }

  void setDefaultAddress(String id) {
    final list = _currentAddresses;
    for (int i = 0; i < list.length; i++) {
      final a = list[i];
      list[i] = a.copyWith(isDefault: a.id == id);
    }
    _syncDefaultWithProfile();
    notifyListeners();
  }

  BuyerOpResult addAddress(AddressModel newAddress) {
    final list = _currentAddresses;
    // 10-address limit enforcement (BUY-ADDR-005)
    if (list.length >= maxAddresses) {
      return BuyerOpResult.fail('Address limit reached. You can only save up to 10 addresses.');
    }

    if (newAddress.isDefault || list.isEmpty) {
      for (int i = 0; i < list.length; i++) {
        list[i] = list[i].copyWith(isDefault: false);
      }
      list.insert(0, newAddress.copyWith(isDefault: true));
    } else {
      list.add(newAddress);
    }
    _syncDefaultWithProfile();
    notifyListeners();
    return BuyerOpResult.ok(message: 'Address saved successfully');
  }

  BuyerOpResult updateAddress(AddressModel updatedAddress) {
    final list = _currentAddresses;
    final index = list.indexWhere((a) => a.id == updatedAddress.id);
    if (index != -1) {
      if (updatedAddress.isDefault) {
        for (int i = 0; i < list.length; i++) {
          if (i != index) {
            list[i] = list[i].copyWith(isDefault: false);
          }
        }
      }
      list[index] = updatedAddress;
      _syncDefaultWithProfile();
      notifyListeners();
      return BuyerOpResult.ok(message: 'Address updated successfully');
    }
    return BuyerOpResult.fail('Address not found.');
  }

  BuyerOpResult deleteAddress(String id) {
    final list = _currentAddresses;
    final index = list.indexWhere((a) => a.id == id);
    if (index == -1) {
      return BuyerOpResult.fail('Address not found.');
    }

    final target = list[index];
    // Cannot delete default address without setting another default first (BUY-ADDR-006, BUY-ADDR-007)
    if (target.isDefault && list.length > 1) {
      return BuyerOpResult.fail(
        'Cannot delete default delivery address. Please set another address as default first.',
      );
    }

    list.removeAt(index);
    if (list.isNotEmpty && !list.any((a) => a.isDefault)) {
      list[0] = list[0].copyWith(isDefault: true);
    }
    _syncDefaultWithProfile();
    notifyListeners();
    return BuyerOpResult.ok(message: 'Address deleted successfully.');
  }

  /// Fetch buyer addresses from backend API
  Future<void> loadAddressesFromApi() async {
    if (!ApiClient.instance.hasToken) return;
    try {
      final res = await ApiClient.instance.get(ApiConstants.buyerAddresses);
      if (res['data'] is List) {
        final list = (res['data'] as List)
            .map((x) => AddressModel.fromApiJson(x as Map<String, dynamic>))
            .toList();
        _userAddresses[_currentUserKey] = list;
        _syncDefaultWithProfile();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('loadAddressesFromApi error: $e');
    }
  }

  /// Add address via backend API
  Future<BuyerOpResult> addAddressRemote(AddressModel newAddress) async {
    if (ApiClient.instance.hasToken) {
      try {
        final res = await ApiClient.instance.post(
          ApiConstants.buyerAddresses,
          body: newAddress.toApiJson(),
        );
        await loadAddressesFromApi();
        return BuyerOpResult.ok(message: res['message'] as String? ?? 'Address saved successfully');
      } on ApiException catch (e) {
        return BuyerOpResult.fail(e.message);
      } catch (e) {
        return BuyerOpResult.fail(e.toString());
      }
    }
    return addAddress(newAddress);
  }

  /// Update address via backend API
  Future<BuyerOpResult> updateAddressRemote(AddressModel updatedAddress) async {
    if (ApiClient.instance.hasToken) {
      try {
        final res = await ApiClient.instance.put(
          ApiConstants.buyerAddressDetail(updatedAddress.id),
          body: updatedAddress.toApiJson(),
        );
        await loadAddressesFromApi();
        return BuyerOpResult.ok(message: res['message'] as String? ?? 'Address updated successfully');
      } on ApiException catch (e) {
        return BuyerOpResult.fail(e.message);
      } catch (e) {
        return BuyerOpResult.fail(e.toString());
      }
    }
    return updateAddress(updatedAddress);
  }

  /// Delete address via backend API
  Future<BuyerOpResult> deleteAddressRemote(String id) async {
    if (ApiClient.instance.hasToken) {
      try {
        final res = await ApiClient.instance.delete(ApiConstants.buyerAddressDetail(id));
        await loadAddressesFromApi();
        return BuyerOpResult.ok(message: res['message'] as String? ?? 'Address deleted successfully');
      } on ApiException catch (e) {
        return BuyerOpResult.fail(e.message);
      } catch (e) {
        return BuyerOpResult.fail(e.toString());
      }
    }
    return deleteAddress(id);
  }

  /// Set default address via backend API
  Future<void> setDefaultAddressRemote(String id) async {
    if (ApiClient.instance.hasToken) {
      try {
        await ApiClient.instance.patch(ApiConstants.buyerAddressDefault(id));
        await loadAddressesFromApi();
        return;
      } catch (e) {
        debugPrint('setDefaultAddressRemote error: $e');
      }
    }
    setDefaultAddress(id);
  }

  void _syncDefaultWithProfile() {
    final def = defaultAddress;
    if (def != null) {
      ProfileService.instance.updateProfile(
        name: def.fullName,
        phone: def.phone,
        address: def.fullAddress,
      );
    } else {
      final buyer = BuyerAccountService.instance.currentBuyer;
      ProfileService.instance.updateProfile(
        name: buyer?.fullName,
        phone: buyer?.mobileNumber,
        address: '',
      );
    }
  }

  /// Reset address state for clean tests
  void resetState() {
    _userAddresses.clear();
    _userAddresses[_currentUserKey] = [];
    _syncDefaultWithProfile();
    notifyListeners();
  }

  void resetToDefaults() => resetState();

  AddressModel? getDefaultAddress() => defaultAddress;

  Map<String, String> getMockGpsLocation() {
    return {
      'region': 'NCR',
      'city': 'Makati City',
      'barangay': 'Poblacion',
      'postalCode': '1210',
      'streetAddress': '6789 Ayala Ave, Tower 1',
    };
  }

  List<String> getCitiesForRegion(String regionQuery) {
    for (final reg in locationHierarchy.keys) {
      if (reg.toLowerCase().contains(regionQuery.toLowerCase())) {
        return locationHierarchy[reg]?.keys.toList() ?? [];
      }
    }
    return [];
  }

  List<String> getBarangaysForCity(String cityQuery) {
    for (final reg in locationHierarchy.values) {
      for (final entry in reg.entries) {
        if (entry.key.toLowerCase().contains(cityQuery.toLowerCase())) {
          return entry.value;
        }
      }
    }
    return [];
  }

  String lookupPostalCode(String city) {
    if (city.toLowerCase().contains('makati')) return '1200';
    if (city.toLowerCase().contains('quezon')) return '1100';
    if (city.toLowerCase().contains('cebu')) return '6000';
    if (city.toLowerCase().contains('davao')) return '8000';
    return getDefaultPostalCode(city);
  }
}
