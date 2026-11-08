import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../network/api_client.dart';

class PsgcLocationItem {
  final String code;
  final String name;
  final String? regionCode;
  final String? regionName;
  final String? provinceCode;
  final String? provinceName;
  final String? cityCode;
  final String? cityName;

  const PsgcLocationItem({
    required this.code,
    required this.name,
    this.regionCode,
    this.regionName,
    this.provinceCode,
    this.provinceName,
    this.cityCode,
    this.cityName,
  });

  factory PsgcLocationItem.fromJson(Map<String, dynamic> json) => PsgcLocationItem(
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        regionCode: json['region_code']?.toString(),
        regionName: json['region_name']?.toString(),
        provinceCode: json['province_code']?.toString(),
        provinceName: json['province_name']?.toString(),
        cityCode: json['city_code']?.toString(),
        cityName: json['city_name']?.toString(),
      );
}

class PsgcLocationService {
  static final PsgcLocationService instance = PsgcLocationService._internal();
  PsgcLocationService._internal();

  List<PsgcLocationItem>? _cachedProvinces;
  final Map<String, List<PsgcLocationItem>> _cachedCities = {};
  final Map<String, List<PsgcLocationItem>> _cachedBarangays = {};

  /// Preload / get provinces from Laravel backend (or cached)
  Future<List<PsgcLocationItem>> getProvinces() async {
    if (_cachedProvinces != null && _cachedProvinces!.isNotEmpty) {
      return _cachedProvinces!;
    }

    try {
      final res = await ApiClient.instance.get(ApiConstants.provinces);
      final raw = res['data'];
      final List list = raw is List ? raw : (raw is Map && raw['data'] is List ? raw['data'] : []);
      if (list.isNotEmpty) {
        _cachedProvinces = list
            .whereType<Map<String, dynamic>>()
            .map(PsgcLocationItem.fromJson)
            .toList();
        return _cachedProvinces!;
      }
    } catch (e) {
      debugPrint('PsgcLocationService.getProvinces remote error: $e');
    }

    // Fallback: build from local PhLocationHierarchy
    _cachedProvinces = [
      const PsgcLocationItem(
        code: '043400000',
        name: 'Laguna',
        regionCode: '040000000',
        regionName: 'Region IV-A (CALABARZON)',
      ),
      const PsgcLocationItem(
        code: '042100000',
        name: 'Cavite',
        regionCode: '040000000',
        regionName: 'Region IV-A (CALABARZON)',
      ),
      const PsgcLocationItem(
        code: '133900000',
        name: 'Metro Manila',
        regionCode: '130000000',
        regionName: 'National Capital Region (NCR)',
      ),
    ];
    return _cachedProvinces!;
  }

  /// Get cities/municipalities for a province
  Future<List<PsgcLocationItem>> getCities(String provinceCode) async {
    if (_cachedCities.containsKey(provinceCode) && _cachedCities[provinceCode]!.isNotEmpty) {
      return _cachedCities[provinceCode]!;
    }

    try {
      final res = await ApiClient.instance.get(ApiConstants.cities(provinceCode));
      final raw = res['data'];
      final List list = raw is List ? raw : (raw is Map && raw['data'] is List ? raw['data'] : []);
      if (list.isNotEmpty) {
        final cities = list
            .whereType<Map<String, dynamic>>()
            .map(PsgcLocationItem.fromJson)
            .toList();
        _cachedCities[provinceCode] = cities;
        return cities;
      }
    } catch (e) {
      debugPrint('PsgcLocationService.getCities remote error: $e');
    }

    // Fallback: local cities for Laguna / Cavite / Metro Manila
    final fallbackList = <PsgcLocationItem>[];
    if (provinceCode == '043400000') {
      fallbackList.addAll([
        const PsgcLocationItem(code: '043410000', name: 'Liliw', provinceCode: '043400000', provinceName: 'Laguna'),
        const PsgcLocationItem(code: '043426000', name: 'Santa Cruz', provinceCode: '043400000', provinceName: 'Laguna'),
        const PsgcLocationItem(code: '043404000', name: 'City of Calamba', provinceCode: '043400000', provinceName: 'Laguna'),
        const PsgcLocationItem(code: '043411000', name: 'Los Baños', provinceCode: '043400000', provinceName: 'Laguna'),
        const PsgcLocationItem(code: '043403000', name: 'City of Biñan', provinceCode: '043400000', provinceName: 'Laguna'),
        const PsgcLocationItem(code: '043419000', name: 'Pagsanjan', provinceCode: '043400000', provinceName: 'Laguna'),
        const PsgcLocationItem(code: '043412000', name: 'Luisiana', provinceCode: '043400000', provinceName: 'Laguna'),
      ]);
    } else if (provinceCode == '042100000') {
      fallbackList.addAll([
        const PsgcLocationItem(code: '042109000', name: 'City of Imus', provinceCode: '042100000', provinceName: 'Cavite'),
        const PsgcLocationItem(code: '042103000', name: 'City of Bacoor', provinceCode: '042100000', provinceName: 'Cavite'),
        const PsgcLocationItem(code: '042106000', name: 'City of Dasmariñas', provinceCode: '042100000', provinceName: 'Cavite'),
      ]);
    } else {
      fallbackList.addAll([
        const PsgcLocationItem(code: '133901000', name: 'City of Manila', provinceCode: '133900000', provinceName: 'Metro Manila'),
        const PsgcLocationItem(code: '133902000', name: 'Quezon City', provinceCode: '133900000', provinceName: 'Metro Manila'),
        const PsgcLocationItem(code: '133903000', name: 'Makati City', provinceCode: '133900000', provinceName: 'Metro Manila'),
      ]);
    }
    _cachedCities[provinceCode] = fallbackList;
    return fallbackList;
  }

  /// Get barangays for a city/municipality
  Future<List<PsgcLocationItem>> getBarangays(String cityCode) async {
    if (_cachedBarangays.containsKey(cityCode) && _cachedBarangays[cityCode]!.isNotEmpty) {
      return _cachedBarangays[cityCode]!;
    }

    try {
      final res = await ApiClient.instance.get(ApiConstants.barangays(cityCode));
      final raw = res['data'];
      final List list = raw is List ? raw : (raw is Map && raw['data'] is List ? raw['data'] : []);
      if (list.isNotEmpty) {
        final brgys = list
            .whereType<Map<String, dynamic>>()
            .map(PsgcLocationItem.fromJson)
            .toList();
        _cachedBarangays[cityCode] = brgys;
        return brgys;
      }
    } catch (e) {
      debugPrint('PsgcLocationService.getBarangays remote error: $e');
    }

    // Fallback: local barangays
    final fallbackList = <PsgcLocationItem>[
      PsgcLocationItem(code: '${cityCode}001', name: 'Poblacion', cityCode: cityCode),
      PsgcLocationItem(code: '${cityCode}002', name: 'San Roque', cityCode: cityCode),
      PsgcLocationItem(code: '${cityCode}003', name: 'Bubukal', cityCode: cityCode),
    ];
    _cachedBarangays[cityCode] = fallbackList;
    return fallbackList;
  }

  void clearCache() {
    _cachedProvinces = null;
    _cachedCities.clear();
    _cachedBarangays.clear();
  }

  static String resolveProvinceCode(String provinceName) {
    final p = provinceName.toLowerCase().trim();
    if (p.contains('laguna')) return '043400000';
    if (p.contains('cavite')) return '042100000';
    if (p.contains('metro manila') || p.contains('ncr')) return '133900000';
    if (p.contains('rizal')) return '045800000';
    if (p.contains('batangas')) return '041000000';
    if (p.contains('quezon')) return '045600000';
    if (p.contains('cebu')) return '072200000';
    if (p.contains('davao')) return '112400000';
    if (p.contains('iloilo')) return '063000000';
    if (p.contains('pampanga')) return '035400000';
    return '043400000';
  }

  static String resolveRegionCode(String regionName, [String? provinceName]) {
    final r = regionName.toLowerCase().trim();
    if (r.contains('ncr') ||
        r.contains('national capital') ||
        (provinceName != null && provinceName.toLowerCase().contains('metro manila'))) {
      return '130000000';
    }
    if (r.contains('calabarzon') || r.contains('iv-a') || r.contains('south luzon')) {
      return '040000000';
    }
    if (r.contains('vii') || r.contains('central visayas')) return '070000000';
    if (r.contains('xi') || r.contains('davao')) return '110000000';
    if (r.contains('vi') || r.contains('western visayas')) return '060000000';
    if (r.contains('iii') || r.contains('central luzon')) return '030000000';
    return '040000000';
  }

  static String resolveCityCode(String cityName, [String? provinceCode]) {
    final c = cityName.toLowerCase().trim();
    if (c.contains('santa cruz')) return '043426000';
    if (c.contains('luisiana')) return '043412000';
    if (c.contains('liliw')) return '043410000';
    if (c.contains('calamba')) return '043404000';
    if (c.contains('los baños') || c.contains('los banos')) return '043411000';
    if (c.contains('biñan') || c.contains('binan')) return '043403000';
    if (c.contains('pagsanjan')) return '043419000';
    if (c.contains('cavinti')) return '043407000';
    if (c.contains('lumban')) return '043413000';
    if (c.contains('cabuyao')) return '043405000';
    if (c.contains('santa rosa')) return '043428000';
    if (c.contains('san pablo')) return '043424000';
    if (c.contains('nagcarlan')) return '043416000';
    if (c.contains('bacoor')) return '042103000';
    if (c.contains('dasmariñas') || c.contains('dasmarinas')) return '042106000';
    if (c.contains('imus')) return '042109000';
    if (c.contains('tagaytay')) return '042119000';
    if (c.contains('general trias')) return '042108000';
    if (c.contains('manila')) return '133901000';
    if (c.contains('quezon')) return '133902000';
    if (c.contains('makati')) return '133903000';
    return (provinceCode != null && provinceCode.length >= 4)
        ? '${provinceCode.substring(0, 4)}99000'
        : '043426000';
  }

  static String resolveBarangayCode(String barangayName, String cityCode) {
    final b = barangayName.toLowerCase().trim();
    if (cityCode == '043426000') {
      if (b.contains('poblacion i') && !b.contains('ii')) return '043426001';
      if (b.contains('poblacion ii') && !b.contains('iii')) return '043426002';
      if (b.contains('poblacion iii')) return '043426003';
      if (b.contains('poblacion iv')) return '043426004';
      if (b.contains('poblacion v')) return '043426005';
      if (b.contains('bubukal')) return '043426006';
      if (b.contains('gatid')) return '043426007';
      if (b.contains('labuin')) return '043426008';
      if (b.contains('pagsawitan')) return '043426009';
      return '043426001';
    }
    if (cityCode == '043412000') {
      if (b.contains('de la paz')) return '043412001';
      return '043412001';
    }
    if (cityCode == '043410000') {
      if (b.contains('tuy-baanan')) return '043410037';
      return '043410001';
    }
    return cityCode.length >= 6 ? '${cityCode.substring(0, 6)}001' : '043426001';
  }
}
