/// Model representing a hierarchical location entry for Philippine addresses
class PhLocationHierarchy {
  /// Region -> Province -> City/Municipality -> List of Barangays
  static const Map<String, Map<String, Map<String, List<String>>>> data = {
    'South Luzon': {
      'Laguna': {
        'Liliw': [
          'Bagong Anyo (Pob.)',
          'Bayate',
          'Bongkol',
          'Bubukal',
          'Cabuyao',
          'Calumpang',
          'Culoy',
          'Dagatan',
          'Daniw (Danliw)',
          'Dita',
          'Ibabang Palina',
          'Ibabang San Roque',
          'Ibabang Sungi',
          'Ilayang Palina',
          'Ilayang San Roque',
          'Ilayang Sungi',
          'Kanlurang Bukal',
          'Laguan',
          'Luquin',
          'Malinao',
          'Masikap (Pob.)',
          'Maslun (Pob.)',
          'Mojon',
          'Novaliches',
          'Oples',
          'Pag-asa (Pob.)',
          'Palayan',
          'Rizal (Pob.)',
          'San Isidro',
          'Silangang Bukal',
          'Tuy-Baanan',
          'Tuy-Caniwn',
        ],
        'Calamba': [
          'Bagong Kalsada',
          'Bucal',
          'Canlubang',
          'Halang',
          'Makiling',
          'Pansol',
          'Real',
          'Turbina',
        ],
        'Santa Rosa': [
          'Balibago',
          'Caingin',
          'Dila',
          'Dita',
          'Don Jose',
          'Macabling',
          'Tagapo',
        ],
        'Biñan': [
          'Canlalay',
          'De La Paz',
          'Malaban',
          'San Antonio',
          'San Vicente',
        ],
        'Cabuyao': [
          'Banlic',
          'Bigaa',
          'Mamatid',
          'Pulo',
          'Sala',
        ],
        'San Pablo': [
          'Concepcion',
          'Del Remedio',
          'San Francisco',
          'San Gabriel',
          'San Jose',
        ],
        'Nagcarlan': [
          'Bambang',
          'Banago',
          'Malinao',
          'Oples',
          'Poblacion I',
          'Poblacion II',
          'Taytay',
        ],
        'Santa Cruz': [
          'Bubukal',
          'Gatid',
          'Labuin',
          'Pagsawitan',
          'Poblacion',
        ],
        'Los Baños': [
          'Anos',
          'Batong Malake',
          'Bayog',
          'College',
          'Mayondon',
        ],
        'Majayjay': [
          'Bakia',
          'Bangkuro',
          'Ilayang Banga',
          'Poblacion',
          'San Roque',
        ],
        'Magdalena': [
          'Baanan',
          'Bungkol',
          'Ibabang Atingay',
          'Poblacion',
          'Salasad',
        ],
        'Pagsanjan': [
          'Biñan',
          'Maulawin',
          'Poblacion I',
          'Poblacion II',
          'Sampaloc',
        ],
      },
      'Cavite': {
        'Imus': ['Anabu', 'Bucandala', 'Malagasang', 'Poblacion', 'Tanzang Luma'],
        'Bacoor': ['Habay', 'Molino', 'Niog', 'Panapaan', 'Talaba'],
        'Dasmarinas': ['Burol', 'Fatima', 'Langkaan', 'Paliparan', 'Salitran'],
        'Tagaytay': ['Asisan', 'Kaybagal', 'Mendez Crossing', 'Silang Junction'],
      },
      'Batangas': {
        'Batangas City': ['Alangilan', 'Bolbok', 'Kumintang Ibaba', 'Kumintang Ilaya', 'Poblacion'],
        'Lipa City': ['Balintawak', 'Marawoy', 'Mataas na Lupa', 'Sabang', 'Tambubong'],
        'Tanauan City': ['Darasa', 'Natatas', 'Poblacion', 'Trapiche'],
      },
      'Rizal': {
        'Antipolo': ['Cupang', 'Dela Paz', 'Mayamot', 'Mambugan', 'San Roque'],
        'Cainta': ['San Andres', 'San Juan', 'San Roque', 'Santa Rosa'],
        'Taytay': ['Dolores', 'Muzon', 'San Isidro', 'San Juan', 'Santa Ana'],
      },
      'Quezon': {
        'Lucena City': ['Cotta', 'Gulang-Gulang', 'Iyam', 'Mayao Crossing', 'Poblacion'],
        'Tayabas City': ['Alitao', 'Angeles', 'Camposanto', 'San Roque'],
        'Candelaria': ['Malabanban Norte', 'Masin Norte', 'Poblacion', 'Santa Catalina'],
      },
    },
    'Metro Manila': {
      'Metro Manila': {
        'Quezon City': ['Batasan Hills', 'Commonwealth', 'Cubao', 'Diliman', 'Holy Spirit', 'Loyola Heights'],
        'Makati City': ['Bel-Air', 'Pio del Pilar', 'Poblacion', 'San Antonio', 'San Lorenzo', 'Urdaneta'],
        'Taguig City': ['Fort Bonifacio (BGC)', 'Pinagsama', 'Ususan', 'Western Bicutan'],
        'City of Manila': ['Binondo', 'Ermita', 'Intramuros', 'Malate', 'Sampaloc'],
        'Pasig City': ['Kapitolyo', 'Ortigas Center', 'San Antonio', 'Ugong'],
        'Mandaluyong City': ['Highway Hills', 'Plainview', 'Wack-Wack'],
      },
    },
    'North Luzon': {
      'Pampanga': {
        'San Fernando': ['Dolores', 'San Agustin', 'San Jose', 'Sindalan'],
        'Angeles City': ['Balibago', 'Cutcut', 'Malabanias', 'Sto. Rosario'],
      },
      'Bulacan': {
        'Malolos': ['Bulihan', 'Cofradia', 'Guinhawa', 'Mojon', 'San Agustin'],
        'San Jose del Monte': ['Gaya-Gaya', 'Muzon', 'Tungkong Mangga'],
      },
    },
    'Visayas': {
      'Cebu': {
        'Cebu City': ['Banilad', 'Guadalupe', 'Kasambagan', 'Lahug', 'Mabolo'],
        'Mandaue City': ['Bakilid', 'Centro', 'Subangdaku', 'Tipolo'],
      },
      'Iloilo': {
        'Iloilo City': ['City Proper', 'Jaro', 'Mandurriao', 'Molo'],
      },
    },
    'Mindanao': {
      'Davao del Sur': {
        'Davao City': ['Buhangin', 'Matina', 'Poblacion', 'Talomo', 'Toril'],
      },
      'Misamis Oriental': {
        'Cagayan de Oro': ['Carmen', 'Lapasan', 'Macasandig', 'Nazareth'],
      },
    },
  };

  static List<String> get regions => data.keys.toList();

  static List<String> getProvinces(String region) {
    return data[region]?.keys.toList() ?? [];
  }

  static List<String> getCities(String region, String province) {
    return data[region]?[province]?.keys.toList() ?? [];
  }

  static List<String> getBarangays(String region, String province, String city) {
    return data[region]?[province]?[city] ?? [];
  }

  static String getDefaultPostalCode(String city) {
    final c = city.toLowerCase();
    if (c.contains('liliw')) return '4004';
    if (c.contains('calamba')) return '4027';
    if (c.contains('santa rosa')) return '4026';
    if (c.contains('biñan') || c.contains('binan')) return '4024';
    if (c.contains('cabuyao')) return '4025';
    if (c.contains('san pablo')) return '4000';
    if (c.contains('nagcarlan')) return '4002';
    if (c.contains('santa cruz')) return '4009';
    if (c.contains('los baños') || c.contains('los banos')) return '4030';
    if (c.contains('majayjay')) return '4005';
    if (c.contains('magdalena')) return '4007';
    if (c.contains('pagsanjan')) return '4008';
    if (c.contains('imus')) return '4103';
    if (c.contains('bacoor')) return '4102';
    if (c.contains('dasmarinas')) return '4114';
    if (c.contains('tagaytay')) return '4120';
    if (c.contains('batangas')) return '4200';
    if (c.contains('lipa')) return '4217';
    if (c.contains('tanauan')) return '4232';
    if (c.contains('antipolo')) return '1870';
    if (c.contains('cainta')) return '1900';
    if (c.contains('taytay')) return '1920';
    if (c.contains('lucena')) return '4301';
    if (c.contains('quezon city')) return '1100';
    if (c.contains('makati')) return '1200';
    if (c.contains('taguig')) return '1630';
    if (c.contains('manila')) return '1000';
    if (c.contains('pasig')) return '1600';
    if (c.contains('mandaluyong')) return '1550';
    if (c.contains('san fernando')) return '2000';
    if (c.contains('angeles')) return '2009';
    if (c.contains('malolos')) return '3000';
    if (c.contains('cebu')) return '6000';
    if (c.contains('mandaue')) return '6014';
    if (c.contains('iloilo')) return '5000';
    if (c.contains('davao')) return '8000';
    if (c.contains('cagayan de oro')) return '9000';
    return '4004';
  }

  static (double lat, double lng) getCoordinates(String city, String barangay) {
    final b = barangay.toLowerCase();
    final c = city.toLowerCase();

    if (c.contains('liliw')) {
      if (b.contains('tuy-baanan')) return (14.1332, 121.4367);
      if (b.contains('rizal')) return (14.1310, 121.4390);
      if (b.contains('bongkol')) return (14.1360, 121.4330);
      if (b.contains('san roque')) return (14.1345, 121.4350);
      if (b.contains('bagong anyo')) return (14.1340, 121.4360);
      if (b.contains('bayate')) return (14.1400, 121.4320);
      if (b.contains('bubukal')) return (14.1380, 121.4340);
      if (b.contains('calumpang')) return (14.1370, 121.4380);
      if (b.contains('dagatan')) return (14.1420, 121.4300);
      if (b.contains('dita')) return (14.1390, 121.4310);
      return (14.1332, 121.4367);
    }
    if (c.contains('calamba')) return (14.2144, 121.1681);
    if (c.contains('santa rosa')) return (14.3122, 121.1114);
    if (c.contains('biñan') || c.contains('binan')) return (14.3384, 121.0827);
    if (c.contains('cabuyao')) return (14.2786, 121.1244);
    if (c.contains('san pablo')) return (14.0684, 121.3256);
    if (c.contains('nagcarlan')) return (14.1364, 121.4169);
    if (c.contains('santa cruz')) return (14.2806, 121.4172);
    if (c.contains('los baños') || c.contains('los banos')) return (14.1706, 121.2428);
    if (c.contains('pagsanjan')) return (14.2742, 121.4556);
    if (c.contains('quezon city')) return (14.6760, 121.0437);
    if (c.contains('makati')) return (14.5547, 121.0244);
    if (c.contains('taguig')) return (14.5176, 121.0509);
    if (c.contains('manila')) return (14.5995, 120.9842);
    if (c.contains('pasig')) return (14.5764, 121.0851);
    if (c.contains('mandaluyong')) return (14.5794, 121.0359);
    if (c.contains('imus')) return (14.4296, 120.9367);
    if (c.contains('bacoor')) return (14.4624, 120.9645);
    if (c.contains('dasmarinas') || c.contains('dasmariñas')) return (14.3294, 120.9367);
    if (c.contains('antipolo')) return (14.5873, 121.1760);
    if (c.contains('cebu')) return (10.3157, 123.8854);
    if (c.contains('davao')) return (7.1907, 125.4553);
    if (c.contains('iloilo')) return (10.7202, 122.5621);
    if (c.contains('bacolod')) return (10.6766, 122.9509);
    if (c.contains('cagayan de oro')) return (8.4542, 124.6319);
    return (14.1332, 121.4367);
  }
}
