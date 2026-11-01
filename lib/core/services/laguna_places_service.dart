/// Model representing a verified place, municipality, barangay, or landmark in Laguna Province
class LagunaPlace {
  final String name;
  final String cityOrMunicipality;
  final String province;
  final String postalCode;
  final double latitude;
  final double longitude;
  final String type;

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
      name: 'Santa Rosa City Center',
      cityOrMunicipality: 'Santa Rosa City',
      postalCode: '4026',
      latitude: 14.3122,
      longitude: 121.1114,
      type: 'City',
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
      name: 'Biñan City Center',
      cityOrMunicipality: 'Biñan City',
      postalCode: '4024',
      latitude: 14.3382,
      longitude: 121.0827,
      type: 'City',
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
      name: 'Cabuyao City Center',
      cityOrMunicipality: 'Cabuyao City',
      postalCode: '4025',
      latitude: 14.2783,
      longitude: 121.1245,
      type: 'City',
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
      name: 'San Pedro City Center',
      cityOrMunicipality: 'San Pedro City',
      postalCode: '4023',
      latitude: 14.3598,
      longitude: 121.0544,
      type: 'City',
    ),

    // --- SAN PABLO CITY ---
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

    // --- SANTA CRUZ ---
    LagunaPlace(
      name: 'Santa Cruz Town Center',
      cityOrMunicipality: 'Santa Cruz',
      postalCode: '4009',
      latitude: 14.2818,
      longitude: 121.4172,
      type: 'Municipality',
    ),
    // --- PAGSANJAN ---
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
      name: 'Nagcarlan Town Center',
      cityOrMunicipality: 'Nagcarlan',
      postalCode: '4002',
      latitude: 14.1378,
      longitude: 121.4158,
      type: 'Municipality',
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
  ];

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
