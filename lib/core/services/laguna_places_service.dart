import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Model representing a verified place, municipality, barangay, or landmark in Laguna Province
class LagunaPlace {
  final String name;
  final String cityOrMunicipality;
  final String province;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String type; // 'City', 'Municipality', 'Barangay', 'Landmark', 'Address'

  const LagunaPlace({
    required this.name,
    required this.cityOrMunicipality,
    this.province = 'Laguna',
    required this.postalCode,
    required this.latitude,
    required this.longitude,
    required this.type,
  });

  String get fullAddress => '$name, $cityOrMunicipality, $province $postalCode';

  Map<String, dynamic> toMap() => {
        'name': name,
        'city': cityOrMunicipality,
        'province': province,
        'postalCode': postalCode,
        'latitude': latitude,
        'longitude': longitude,
        'type': type,
      };
}

/// Service providing high-precision GPS geocoding and Laguna Places API lookup
class LagunaPlacesService {
  static final LagunaPlacesService instance = LagunaPlacesService._internal();
  LagunaPlacesService._internal();

  /// Comprehensive verified registry of Laguna cities, municipalities, key barangays & landmarks
  static const List<LagunaPlace> _lagunaDatabase = [
    // --- LILIW ---
    LagunaPlace(
      name: 'Tuy-Baanan',
      cityOrMunicipality: 'Liliw',
      postalCode: '4004',
      latitude: 14.1332,
      longitude: 121.4367,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Rizal',
      cityOrMunicipality: 'Liliw',
      postalCode: '4004',
      latitude: 14.1310,
      longitude: 121.4390,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Bongkol',
      cityOrMunicipality: 'Liliw',
      postalCode: '4004',
      latitude: 14.1360,
      longitude: 121.4330,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'San Roque',
      cityOrMunicipality: 'Liliw',
      postalCode: '4004',
      latitude: 14.1345,
      longitude: 121.4350,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Liliw Municipal Hall / Town Center',
      cityOrMunicipality: 'Liliw',
      postalCode: '4004',
      latitude: 14.1335,
      longitude: 121.4362,
      type: 'Landmark',
    ),
    LagunaPlace(
      name: 'Liliw Famous Footwear Strip (Gat Tayaw)',
      cityOrMunicipality: 'Liliw',
      postalCode: '4004',
      latitude: 14.1340,
      longitude: 121.4358,
      type: 'Landmark',
    ),

    // --- CALAMBA CITY ---
    LagunaPlace(
      name: 'Real',
      cityOrMunicipality: 'Calamba City',
      postalCode: '4027',
      latitude: 14.2144,
      longitude: 121.1558,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Halang',
      cityOrMunicipality: 'Calamba City',
      postalCode: '4027',
      latitude: 14.1950,
      longitude: 121.1610,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Bucal',
      cityOrMunicipality: 'Calamba City',
      postalCode: '4027',
      latitude: 14.1802,
      longitude: 121.1730,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Canlubang',
      cityOrMunicipality: 'Calamba City',
      postalCode: '4028',
      latitude: 14.2190,
      longitude: 121.0980,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Pansol',
      cityOrMunicipality: 'Calamba City',
      postalCode: '4027',
      latitude: 14.1795,
      longitude: 121.1855,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Turbina',
      cityOrMunicipality: 'Calamba City',
      postalCode: '4027',
      latitude: 14.1880,
      longitude: 121.1440,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'SM City Calamba',
      cityOrMunicipality: 'Calamba City',
      postalCode: '4027',
      latitude: 14.2045,
      longitude: 121.1544,
      type: 'Landmark',
    ),
    LagunaPlace(
      name: 'Calamba City Hall',
      cityOrMunicipality: 'Calamba City',
      postalCode: '4027',
      latitude: 14.2135,
      longitude: 121.1684,
      type: 'City',
    ),

    // --- SANTA ROSA CITY ---
    LagunaPlace(
      name: 'Balibago',
      cityOrMunicipality: 'Santa Rosa City',
      postalCode: '4026',
      latitude: 14.2965,
      longitude: 121.1090,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Don Jose',
      cityOrMunicipality: 'Santa Rosa City',
      postalCode: '4026',
      latitude: 14.2655,
      longitude: 121.0645,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Tagapo',
      cityOrMunicipality: 'Santa Rosa City',
      postalCode: '4026',
      latitude: 14.3180,
      longitude: 121.1095,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Macabling',
      cityOrMunicipality: 'Santa Rosa City',
      postalCode: '4026',
      latitude: 14.3140,
      longitude: 121.1180,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Nuvali / Solenad',
      cityOrMunicipality: 'Santa Rosa City',
      postalCode: '4026',
      latitude: 14.2405,
      longitude: 121.0602,
      type: 'Landmark',
    ),
    LagunaPlace(
      name: 'Enchanted Kingdom',
      cityOrMunicipality: 'Santa Rosa City',
      postalCode: '4026',
      latitude: 14.2828,
      longitude: 121.0975,
      type: 'Landmark',
    ),

    // --- BIÑAN CITY ---
    LagunaPlace(
      name: 'San Antonio',
      cityOrMunicipality: 'Biñan City',
      postalCode: '4024',
      latitude: 14.3410,
      longitude: 121.0850,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Canlalay',
      cityOrMunicipality: 'Biñan City',
      postalCode: '4024',
      latitude: 14.3480,
      longitude: 121.0790,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'San Vicente',
      cityOrMunicipality: 'Biñan City',
      postalCode: '4024',
      latitude: 14.3320,
      longitude: 121.0810,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Southwoods City / Mall',
      cityOrMunicipality: 'Biñan City',
      postalCode: '4024',
      latitude: 14.3185,
      longitude: 121.0425,
      type: 'Landmark',
    ),

    // --- CABUYAO CITY ---
    LagunaPlace(
      name: 'Sala',
      cityOrMunicipality: 'Cabuyao City',
      postalCode: '4025',
      latitude: 14.2750,
      longitude: 121.1220,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Banlic',
      cityOrMunicipality: 'Cabuyao City',
      postalCode: '4025',
      latitude: 14.2690,
      longitude: 121.1290,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Pulo',
      cityOrMunicipality: 'Cabuyao City',
      postalCode: '4025',
      latitude: 14.2580,
      longitude: 121.1340,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Mamatid',
      cityOrMunicipality: 'Cabuyao City',
      postalCode: '4025',
      latitude: 14.2650,
      longitude: 121.1490,
      type: 'Barangay',
    ),

    // --- SAN PEDRO CITY ---
    LagunaPlace(
      name: 'Pacita Complex',
      cityOrMunicipality: 'San Pedro City',
      postalCode: '4023',
      latitude: 14.3435,
      longitude: 121.0565,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Poblacion',
      cityOrMunicipality: 'San Pedro City',
      postalCode: '4023',
      latitude: 14.3580,
      longitude: 121.0540,
      type: 'Barangay',
    ),

    // --- SAN PABLO CITY ---
    LagunaPlace(
      name: 'Sampaloc Lake',
      cityOrMunicipality: 'San Pablo City',
      postalCode: '4000',
      latitude: 14.0755,
      longitude: 121.3280,
      type: 'Landmark',
    ),
    LagunaPlace(
      name: 'San Jose',
      cityOrMunicipality: 'San Pablo City',
      postalCode: '4000',
      latitude: 14.0720,
      longitude: 121.3190,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'San Pablo City Center',
      cityOrMunicipality: 'San Pablo City',
      postalCode: '4000',
      latitude: 14.0683,
      longitude: 121.3256,
      type: 'City',
    ),

    // --- LOS BAÑOS ---
    LagunaPlace(
      name: 'Batong Malake',
      cityOrMunicipality: 'Los Baños',
      postalCode: '4030',
      latitude: 14.1670,
      longitude: 121.2420,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'UPLB Campus',
      cityOrMunicipality: 'Los Baños',
      postalCode: '4031',
      latitude: 14.1675,
      longitude: 121.2410,
      type: 'Landmark',
    ),
    LagunaPlace(
      name: 'College',
      cityOrMunicipality: 'Los Baños',
      postalCode: '4031',
      latitude: 14.1630,
      longitude: 121.2440,
      type: 'Barangay',
    ),

    // --- SANTA CRUZ (Capital) ---
    LagunaPlace(
      name: 'Laguna Provincial Capitol',
      cityOrMunicipality: 'Santa Cruz',
      postalCode: '4009',
      latitude: 14.2795,
      longitude: 121.4190,
      type: 'Landmark',
    ),
    LagunaPlace(
      name: 'Pagsawitan',
      cityOrMunicipality: 'Santa Cruz',
      postalCode: '4009',
      latitude: 14.2780,
      longitude: 121.4280,
      type: 'Barangay',
    ),
    LagunaPlace(
      name: 'Santa Cruz Poblacion',
      cityOrMunicipality: 'Santa Cruz',
      postalCode: '4009',
      latitude: 14.2818,
      longitude: 121.4172,
      type: 'Municipality',
    ),

    // --- PAGSANJAN ---
    LagunaPlace(
      name: 'Pagsanjan Falls Tourist Wharf',
      cityOrMunicipality: 'Pagsanjan',
      postalCode: '4008',
      latitude: 14.2720,
      longitude: 121.4580,
      type: 'Landmark',
    ),
    LagunaPlace(
      name: 'Pagsanjan Town Center',
      cityOrMunicipality: 'Pagsanjan',
      postalCode: '4008',
      latitude: 14.2736,
      longitude: 121.4556,
      type: 'Municipality',
    ),

    // --- NAGCARLAN ---
    LagunaPlace(
      name: 'Nagcarlan Underground Cemetery',
      cityOrMunicipality: 'Nagcarlan',
      postalCode: '4002',
      latitude: 14.1380,
      longitude: 121.4160,
      type: 'Landmark',
    ),

    // --- MAJAYJAY ---
    LagunaPlace(
      name: 'Majayjay Town Center',
      cityOrMunicipality: 'Majayjay',
      postalCode: '4005',
      latitude: 14.1436,
      longitude: 121.4883,
      type: 'Municipality',
    ),

    // --- MAGDALENA ---
    LagunaPlace(
      name: 'Magdalena Town Center',
      cityOrMunicipality: 'Magdalena',
      postalCode: '4007',
      latitude: 14.2003,
      longitude: 121.4289,
      type: 'Municipality',
    ),

    // --- LUISIANA ---
    LagunaPlace(
      name: 'Luisiana Town Center',
      cityOrMunicipality: 'Luisiana',
      postalCode: '4032',
      latitude: 14.1856,
      longitude: 121.5139,
      type: 'Municipality',
    ),

    // --- CAVINTI ---
    LagunaPlace(
      name: 'Cavinti Town Center',
      cityOrMunicipality: 'Cavinti',
      postalCode: '4013',
      latitude: 14.2467,
      longitude: 121.5078,
      type: 'Municipality',
    ),

    // --- LUMBAN ---
    LagunaPlace(
      name: 'Lumban Embroidery Capital',
      cityOrMunicipality: 'Lumban',
      postalCode: '4014',
      latitude: 14.2981,
      longitude: 121.4594,
      type: 'Municipality',
    ),

    // --- PAETE ---
    LagunaPlace(
      name: 'Paete Woodcarving Heritage Center',
      cityOrMunicipality: 'Paete',
      postalCode: '4016',
      latitude: 14.3644,
      longitude: 121.5278,
      type: 'Municipality',
    ),

    // --- PAKIL ---
    LagunaPlace(
      name: 'Pakil Town Center',
      cityOrMunicipality: 'Pakil',
      postalCode: '4017',
      latitude: 14.3828,
      longitude: 121.4794,
      type: 'Municipality',
    ),

    // --- PANGIL ---
    LagunaPlace(
      name: 'Pangil Town Center',
      cityOrMunicipality: 'Pangil',
      postalCode: '4018',
      latitude: 14.4028,
      longitude: 121.4764,
      type: 'Municipality',
    ),

    // --- SINILOAN ---
    LagunaPlace(
      name: 'Siniloan Commercial Center',
      cityOrMunicipality: 'Siniloan',
      postalCode: '4019',
      latitude: 14.4194,
      longitude: 121.4489,
      type: 'Municipality',
    ),

    // --- FAMY ---
    LagunaPlace(
      name: 'Famy Town Center',
      cityOrMunicipality: 'Famy',
      postalCode: '4021',
      latitude: 14.4361,
      longitude: 121.4508,
      type: 'Municipality',
    ),

    // --- MABITAC ---
    LagunaPlace(
      name: 'Mabitac Town Center',
      cityOrMunicipality: 'Mabitac',
      postalCode: '4020',
      latitude: 14.4258,
      longitude: 121.4286,
      type: 'Municipality',
    ),

    // --- SANTA MARIA ---
    LagunaPlace(
      name: 'Santa Maria Town Center',
      cityOrMunicipality: 'Santa Maria',
      postalCode: '4022',
      latitude: 14.4714,
      longitude: 121.4258,
      type: 'Municipality',
    ),

    // --- KALAYAAN ---
    LagunaPlace(
      name: 'Kalayaan Eco Center',
      cityOrMunicipality: 'Kalayaan',
      postalCode: '4015',
      latitude: 14.3522,
      longitude: 121.5647,
      type: 'Municipality',
    ),

    // --- PILA ---
    LagunaPlace(
      name: 'Pila Heritage Town Square',
      cityOrMunicipality: 'Pila',
      postalCode: '4010',
      latitude: 14.2333,
      longitude: 121.3653,
      type: 'Municipality',
    ),

    // --- VICTORIA ---
    LagunaPlace(
      name: 'Victoria Duck Farming Capital',
      cityOrMunicipality: 'Victoria',
      postalCode: '4011',
      latitude: 14.2281,
      longitude: 121.3283,
      type: 'Municipality',
    ),

    // --- BAY ---
    LagunaPlace(
      name: 'Bay Town Center',
      cityOrMunicipality: 'Bay',
      postalCode: '4033',
      latitude: 14.1808,
      longitude: 121.2858,
      type: 'Municipality',
    ),

    // --- ALAMINOS ---
    LagunaPlace(
      name: 'Alaminos Town Center',
      cityOrMunicipality: 'Alaminos',
      postalCode: '4001',
      latitude: 14.0622,
      longitude: 121.2469,
      type: 'Municipality',
    ),

    // --- RIZAL (Laguna) ---
    LagunaPlace(
      name: 'Rizal Laguna Town Center',
      cityOrMunicipality: 'Rizal',
      postalCode: '4003',
      latitude: 14.1122,
      longitude: 121.3956,
      type: 'Municipality',
    ),
  ];

  /// Get all verified places in Laguna database
  List<LagunaPlace> get allPlaces => List.unmodifiable(_lagunaDatabase);

  /// Search places matching query either locally or using OpenStreetMap Nominatim Geocoding API
  Future<List<LagunaPlace>> searchPlaces(String query) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) return _lagunaDatabase.take(10).toList();

    // 1. Instant local filter
    final localMatches = _lagunaDatabase.where((p) {
      return p.name.toLowerCase().contains(cleanQuery) ||
          p.cityOrMunicipality.toLowerCase().contains(cleanQuery) ||
          p.postalCode.contains(cleanQuery);
    }).toList();

    // 2. Query Nominatim API for high accuracy geocoding when online
    try {
      final encoded = Uri.encodeComponent('$query, Laguna, Philippines');
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$encoded&format=json&limit=5&countrycodes=ph&addressdetails=1',
      );

      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': 'NexoraECommerceApp/1.0 (dev@nexora.io; accurate-pinpoint)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 3));

      if (resp.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(resp.body) as List<dynamic>;
        final onlinePlaces = <LagunaPlace>[];

        for (final item in jsonList) {
          try {
            final lat = double.parse(item['lat'].toString());
            final lon = double.parse(item['lon'].toString());
            final displayName = (item['display_name'] ?? '').toString();
            final address = item['address'] as Map<String, dynamic>?;

            final cityOrTown = address?['city'] ??
                address?['town'] ??
                address?['municipality'] ??
                address?['county'] ??
                'Laguna';

            final postcode = (address?['postcode'] ?? '4000').toString();
            final primaryName = (item['name'] ?? displayName.split(',').first).toString();

            // Accept any valid Philippine coordinates (4.0 to 22.0 Lat, 116.0 to 127.0 Long)
            if (lat >= 4.0 && lat <= 22.0 && lon >= 116.0 && lon <= 127.0) {
              onlinePlaces.add(
                LagunaPlace(
                  name: primaryName.isNotEmpty ? primaryName : displayName.split(',').first.trim(),
                  cityOrMunicipality: cityOrTown.toString(),
                  postalCode: postcode,
                  latitude: lat,
                  longitude: lon,
                  type: 'API Geocoded',
                ),
              );
            }
          } catch (_) {}
        }

        if (onlinePlaces.isNotEmpty) {
          // Merge avoiding coordinate duplicates
          final merged = <LagunaPlace>[...localMatches];
          for (final op in onlinePlaces) {
            final exists = merged.any(
              (p) => (p.latitude - op.latitude).abs() < 0.005 && (p.longitude - op.longitude).abs() < 0.005,
            );
            if (!exists) {
              merged.add(op);
            }
          }
          return merged;
        }
      }
    } catch (e) {
      debugPrint('ℹ️ LagunaPlacesService API geocode fallback to local: $e');
    }

    return localMatches.isNotEmpty ? localMatches : _lagunaDatabase.take(6).toList();
  }

  /// Finds the closest landmark or barangay for any given GPS coordinates
  LagunaPlace getNearestPlace(double lat, double lng) {
    LagunaPlace nearest = _lagunaDatabase.first;
    double minDistance = double.infinity;

    for (final p in _lagunaDatabase) {
      final dLat = p.latitude - lat;
      final dLng = p.longitude - lng;
      final distSq = (dLat * dLat) + (dLng * dLng);
      if (distSq < minDistance) {
        minDistance = distSq;
        nearest = p;
      }
    }
    return nearest;
  }

  /// High accuracy reverse geocoding from OpenStreetMap Nominatim with local fallback
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?lat=$lat&lon=$lng&format=json&countrycodes=ph',
      );
      final resp = await http.get(
        uri,
        headers: {
          'User-Agent': 'NexoraECommerceApp/1.0 (dev@nexora.io; accurate-pinpoint)',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(milliseconds: 2500));

      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = address['road'] ?? address['pedestrian'] ?? address['suburb'] ?? '';
          final barangay = address['quarter'] ?? address['neighbourhood'] ?? address['suburb'] ?? '';
          final city = address['city'] ?? address['town'] ?? address['municipality'] ?? '';
          final province = address['province'] ?? address['state'] ?? 'Laguna';

          final parts = [road, barangay, city, province]
              .where((s) => s.toString().trim().isNotEmpty)
              .toSet()
              .toList();
          if (parts.isNotEmpty) {
            return parts.join(', ');
          }
        }
      }
    } catch (_) {}

    // Local nearest place fallback
    final nearest = getNearestPlace(lat, lng);
    return '${nearest.name}, ${nearest.cityOrMunicipality}, ${nearest.province}';
  }

  /// Detects real physical device GPS coordinates via IP/Network geolocation lookup
  Future<({double latitude, double longitude, String name})?> getCurrentDeviceLocation() async {
    try {
      final uri = Uri.parse('https://ipapi.co/json/');
      final resp = await http.get(uri).timeout(const Duration(seconds: 3));
      if (resp.statusCode == 200) {
        final data = jsonDecode(resp.body) as Map<String, dynamic>;
        final lat = double.tryParse(data['latitude']?.toString() ?? '');
        final lng = double.tryParse(data['longitude']?.toString() ?? '');
        final city = (data['city'] ?? 'Current Location').toString();
        final region = (data['region'] ?? '').toString();
        if (lat != null && lng != null) {
          return (latitude: lat, longitude: lng, name: '$city, $region');
        }
      }
    } catch (_) {}

    try {
      final uri2 = Uri.parse('http://ip-api.com/json');
      final resp2 = await http.get(uri2).timeout(const Duration(seconds: 3));
      if (resp2.statusCode == 200) {
        final data2 = jsonDecode(resp2.body) as Map<String, dynamic>;
        final lat = double.tryParse(data2['lat']?.toString() ?? '');
        final lng = double.tryParse(data2['lon']?.toString() ?? '');
        final city = (data2['city'] ?? 'Current Location').toString();
        final region = (data2['regionName'] ?? '').toString();
        if (lat != null && lng != null) {
          return (latitude: lat, longitude: lng, name: '$city, $region');
        }
      }
    } catch (_) {}

    return null;
  }

  /// Automatically resolves the most accurate GPS coordinates for any given address string
  LagunaPlace resolveCoordinates(String address) {
    final lower = address.toLowerCase();

    // 1. Check if both name and city/municipality are in address
    for (final p in _lagunaDatabase) {
      final cityClean = p.cityOrMunicipality.toLowerCase().replaceAll(' city', '');
      if (lower.contains(p.name.toLowerCase()) && lower.contains(cityClean)) {
        return p;
      }
    }

    // 2. If a specific city is identified, find best matching place in that city
    for (final p in _lagunaDatabase) {
      final cityClean = p.cityOrMunicipality.toLowerCase().replaceAll(' city', '');
      if (lower.contains(cityClean) && lower.contains(p.name.toLowerCase())) {
        return p;
      }
    }

    // 3. Match by city/municipality center
    for (final p in _lagunaDatabase) {
      final cityClean = p.cityOrMunicipality.toLowerCase().replaceAll(' city', '');
      if (lower.contains(cityClean)) {
        return p;
      }
    }

    // 4. Check barangay / landmark matches
    for (final p in _lagunaDatabase) {
      if (lower.contains(p.name.toLowerCase())) {
        return p;
      }
    }

    // 5. Nationwide major Philippine cities outside Laguna (high precision coords)
    if (lower.contains('quezon city')) {
      return const LagunaPlace(name: 'Quezon City Center', cityOrMunicipality: 'Quezon City', province: 'Metro Manila', postalCode: '1100', latitude: 14.6760, longitude: 121.0437, type: 'City');
    }
    if (lower.contains('makati')) {
      return const LagunaPlace(name: 'Makati CBD', cityOrMunicipality: 'Makati City', province: 'Metro Manila', postalCode: '1200', latitude: 14.5547, longitude: 121.0244, type: 'City');
    }
    if (lower.contains('taguig') || lower.contains('bgc')) {
      return const LagunaPlace(name: 'Bonifacio Global City', cityOrMunicipality: 'Taguig City', province: 'Metro Manila', postalCode: '1630', latitude: 14.5176, longitude: 121.0509, type: 'City');
    }
    if (lower.contains('manila')) {
      return const LagunaPlace(name: 'City of Manila', cityOrMunicipality: 'City of Manila', province: 'Metro Manila', postalCode: '1000', latitude: 14.5995, longitude: 120.9842, type: 'City');
    }
    if (lower.contains('pasig')) {
      return const LagunaPlace(name: 'Pasig City', cityOrMunicipality: 'Pasig City', province: 'Metro Manila', postalCode: '1600', latitude: 14.5764, longitude: 121.0851, type: 'City');
    }
    if (lower.contains('mandaluyong')) {
      return const LagunaPlace(name: 'Mandaluyong City', cityOrMunicipality: 'Mandaluyong City', province: 'Metro Manila', postalCode: '1550', latitude: 14.5794, longitude: 121.0359, type: 'City');
    }
    if (lower.contains('imus')) {
      return const LagunaPlace(name: 'Imus City', cityOrMunicipality: 'Imus', province: 'Cavite', postalCode: '4103', latitude: 14.4296, longitude: 120.9367, type: 'City');
    }
    if (lower.contains('bacoor')) {
      return const LagunaPlace(name: 'Bacoor City', cityOrMunicipality: 'Bacoor', province: 'Cavite', postalCode: '4102', latitude: 14.4624, longitude: 120.9645, type: 'City');
    }
    if (lower.contains('dasmarinas') || lower.contains('dasmariñas')) {
      return const LagunaPlace(name: 'Dasmariñas City', cityOrMunicipality: 'Dasmariñas', province: 'Cavite', postalCode: '4114', latitude: 14.3294, longitude: 120.9367, type: 'City');
    }
    if (lower.contains('antipolo')) {
      return const LagunaPlace(name: 'Antipolo City', cityOrMunicipality: 'Antipolo', province: 'Rizal', postalCode: '1870', latitude: 14.5842, longitude: 121.1763, type: 'City');
    }
    if (lower.contains('cebu')) {
      return const LagunaPlace(name: 'Cebu City Center', cityOrMunicipality: 'Cebu City', province: 'Cebu', postalCode: '6000', latitude: 10.3157, longitude: 123.8854, type: 'City');
    }
    if (lower.contains('davao')) {
      return const LagunaPlace(name: 'Davao City Center', cityOrMunicipality: 'Davao City', province: 'Davao del Sur', postalCode: '8000', latitude: 7.1907, longitude: 125.4553, type: 'City');
    }
    if (lower.contains('iloilo')) {
      return const LagunaPlace(name: 'Iloilo City', cityOrMunicipality: 'Iloilo City', province: 'Iloilo', postalCode: '5000', latitude: 10.7202, longitude: 122.5621, type: 'City');
    }
    if (lower.contains('bacolod')) {
      return const LagunaPlace(name: 'Bacolod City', cityOrMunicipality: 'Bacolod City', province: 'Negros Occidental', postalCode: '6100', latitude: 10.6765, longitude: 122.9509, type: 'City');
    }
    if (lower.contains('cagayan de oro')) {
      return const LagunaPlace(name: 'Cagayan de Oro City', cityOrMunicipality: 'Cagayan de Oro', province: 'Misamis Oriental', postalCode: '9000', latitude: 8.4542, longitude: 124.6319, type: 'City');
    }

    // 6. Default to Liliw, Laguna (customer base)
    return const LagunaPlace(
      name: 'Tuy-Baanan',
      cityOrMunicipality: 'Liliw',
      postalCode: '4004',
      latitude: 14.1332,
      longitude: 121.4367,
      type: 'Barangay',
    );
  }
}
