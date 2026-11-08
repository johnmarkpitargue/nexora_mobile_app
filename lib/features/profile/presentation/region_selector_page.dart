import 'package:flutter/material.dart';
import '../../../core/services/ph_location_service.dart';
import '../../../core/services/psgc_location_service.dart';

class RegionSelectionResult {
  final String region;
  final String regionCode;
  final String province;
  final String provinceCode;
  final String city;
  final String municipalityCode;
  final String barangay;
  final String barangayCode;
  final String postalCode;
  final double latitude;
  final double longitude;

  const RegionSelectionResult({
    required this.region,
    this.regionCode = '',
    required this.province,
    this.provinceCode = '',
    required this.city,
    this.municipalityCode = '',
    required this.barangay,
    this.barangayCode = '',
    required this.postalCode,
    required this.latitude,
    required this.longitude,
  });
}

class RegionSelectorPage extends StatefulWidget {
  final String? initialRegion;
  final String? initialProvince;
  final String? initialCity;
  final String? initialBarangay;

  const RegionSelectorPage({
    super.key,
    this.initialRegion,
    this.initialProvince,
    this.initialCity,
    this.initialBarangay,
  });

  @override
  State<RegionSelectorPage> createState() => _RegionSelectorPageState();
}

class _RegionSelectorPageState extends State<RegionSelectorPage> {
  static const Color primaryBlue = Color(0xFF0066FF);

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String? _selectedRegion;
  String? _selectedRegionCode;
  String? _selectedProvince;
  String? _selectedProvinceCode;
  String? _selectedCity;
  String? _selectedCityCode;
  String? _selectedBarangay;
  String? _selectedBarangayCode;

  @override
  void initState() {
    super.initState();
    _selectedRegion = widget.initialRegion;
    _selectedProvince = widget.initialProvince;
    _selectedCity = widget.initialCity;
    _selectedBarangay = widget.initialBarangay;
    if (_selectedRegion != null) {
      _selectedRegionCode = PsgcLocationService.resolveRegionCode(_selectedRegion!, _selectedProvince);
    }
    if (_selectedProvince != null) {
      _selectedProvinceCode = PsgcLocationService.resolveProvinceCode(_selectedProvince!);
    }
    if (_selectedCity != null) {
      _selectedCityCode = PsgcLocationService.resolveCityCode(_selectedCity!, _selectedProvinceCode);
    }
    if (_selectedBarangay != null && _selectedCityCode != null) {
      _selectedBarangayCode = PsgcLocationService.resolveBarangayCode(_selectedBarangay!, _selectedCityCode!);
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _resetAll() {
    setState(() {
      _selectedRegion = null;
      _selectedRegionCode = null;
      _selectedProvince = null;
      _selectedProvinceCode = null;
      _selectedCity = null;
      _selectedCityCode = null;
      _selectedBarangay = null;
      _selectedBarangayCode = null;
      _searchController.clear();
      _searchQuery = '';
    });
  }

  int get _currentStep {
    if (_selectedRegion == null) return 0; // Select region
    if (_selectedProvince == null) return 1; // Select province
    if (_selectedCity == null) return 2; // Select city
    return 3; // Select barangay
  }

  String get _currentStepTitle {
    switch (_currentStep) {
      case 0:
        return 'Region';
      case 1:
        return 'Province';
      case 2:
        return 'City / Municipality';
      case 3:
      default:
        return 'Barangay';
    }
  }

  List<String> get _currentItems {
    switch (_currentStep) {
      case 0:
        return PhLocationHierarchy.regions;
      case 1:
        return PhLocationHierarchy.getProvinces(_selectedRegion!);
      case 2:
        return PhLocationHierarchy.getCities(_selectedRegion!, _selectedProvince!);
      case 3:
      default:
        final list = PhLocationHierarchy.getBarangays(
          _selectedRegion!,
          _selectedProvince!,
          _selectedCity!,
        );
        return List<String>.from(list)..sort();
    }
  }

  Map<String, List<String>> _groupAlphabetically(List<String> items) {
    final Map<String, List<String>> grouped = {};
    for (final item in items) {
      final firstLetter = item.trim().isEmpty ? '#' : item.trim()[0].toUpperCase();
      grouped.putIfAbsent(firstLetter, () => []).add(item);
    }
    return grouped;
  }

  void _onItemSelected(String item) {
    setState(() {
      switch (_currentStep) {
        case 0:
          _selectedRegion = item;
          _selectedRegionCode = PsgcLocationService.resolveRegionCode(item);
          _selectedProvince = null;
          _selectedProvinceCode = null;
          _selectedCity = null;
          _selectedCityCode = null;
          _selectedBarangay = null;
          _selectedBarangayCode = null;
          break;
        case 1:
          _selectedProvince = item;
          _selectedProvinceCode = PsgcLocationService.resolveProvinceCode(item);
          _selectedCity = null;
          _selectedCityCode = null;
          _selectedBarangay = null;
          _selectedBarangayCode = null;
          break;
        case 2:
          _selectedCity = item;
          _selectedCityCode = PsgcLocationService.resolveCityCode(item, _selectedProvinceCode);
          _selectedBarangay = null;
          _selectedBarangayCode = null;
          break;
        case 3:
          _selectedBarangay = item;
          _selectedBarangayCode = PsgcLocationService.resolveBarangayCode(item, _selectedCityCode ?? '043426000');
          _finishSelection();
          break;
      }
    });
  }

  void _finishSelection() {
    if (_selectedRegion == null ||
        _selectedProvince == null ||
        _selectedCity == null ||
        _selectedBarangay == null) {
      return;
    }
    final postal = PhLocationHierarchy.getDefaultPostalCode(_selectedCity!);
    final coords = PhLocationHierarchy.getCoordinates(_selectedCity!, _selectedBarangay!);

    final regCode = _selectedRegionCode ??
        PsgcLocationService.resolveRegionCode(_selectedRegion!, _selectedProvince);
    final provCode = _selectedProvinceCode ??
        PsgcLocationService.resolveProvinceCode(_selectedProvince!);
    final cityCode = _selectedCityCode ??
        PsgcLocationService.resolveCityCode(_selectedCity!, provCode);
    final brgyCode = _selectedBarangayCode ??
        PsgcLocationService.resolveBarangayCode(_selectedBarangay!, cityCode);

    final result = RegionSelectionResult(
      region: _selectedRegion!,
      regionCode: regCode,
      province: _selectedProvince!,
      provinceCode: provCode,
      city: _selectedCity!,
      municipalityCode: cityCode,
      barangay: _selectedBarangay!,
      barangayCode: brgyCode,
      postalCode: postal,
      latitude: coords.$1,
      longitude: coords.$2,
    );
    Navigator.pop(context, result);
  }

  List<RegionSelectionResult> _getGlobalSearchResults(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final results = <RegionSelectionResult>[];
    for (final region in PhLocationHierarchy.regions) {
      for (final province in PhLocationHierarchy.getProvinces(region)) {
        for (final city in PhLocationHierarchy.getCities(region, province)) {
          final postal = PhLocationHierarchy.getDefaultPostalCode(city);
          final barangays = PhLocationHierarchy.getBarangays(region, province, city);

          for (final b in barangays) {
            if (b.toLowerCase().contains(q) ||
                city.toLowerCase().contains(q) ||
                province.toLowerCase().contains(q) ||
                postal.contains(q)) {
              final coords = PhLocationHierarchy.getCoordinates(city, b);
              final regCode = PsgcLocationService.resolveRegionCode(region, province);
              final provCode = PsgcLocationService.resolveProvinceCode(province);
              final cityCode = PsgcLocationService.resolveCityCode(city, provCode);
              final brgyCode = PsgcLocationService.resolveBarangayCode(b, cityCode);

              results.add(RegionSelectionResult(
                region: region,
                regionCode: regCode,
                province: province,
                provinceCode: provCode,
                city: city,
                municipalityCode: cityCode,
                barangay: b,
                barangayCode: brgyCode,
                postalCode: postal,
                latitude: coords.$1,
                longitude: coords.$2,
              ));
              if (results.length >= 30) return results;
            }
          }
        }
      }
    }
    return results;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F172A), size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        titleSpacing: 0,
        title: Container(
          height: 38,
          margin: const EdgeInsets.only(right: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F5F5),
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              const Icon(Icons.search, size: 18, color: Color(0xFF999999)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) {
                    setState(() => _searchQuery = val);
                  },
                  style: const TextStyle(fontSize: 13, color: Color(0xFF222222)),
                  decoration: const InputDecoration(
                    hintText: 'Search City, District or Postal Code',
                    hintStyle: TextStyle(fontSize: 13, color: Color(0xFF999999)),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Icon(Icons.clear, size: 16, color: Color(0xFF999999)),
                ),
            ],
          ),
        ),
      ),
      body: _searchQuery.trim().isNotEmpty
          ? _buildSearchResults()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStepperHeader(),
                const Divider(height: 1, color: Color(0xFFF0F0F0)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
                  child: Text(
                    _currentStepTitle,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                Expanded(child: _buildItemsList()),
              ],
            ),
    );
  }

  Widget _buildSearchResults() {
    final results = _getGlobalSearchResults(_searchQuery);

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No locations found for "$_searchQuery"',
              style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFF0F0F0)),
      itemBuilder: (context, index) {
        final item = results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          title: Text(
            item.barangay,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF222222)),
          ),
          subtitle: Text(
            '${item.city}, ${item.province} • Postal: ${item.postalCode}',
            style: const TextStyle(fontSize: 12, color: Color(0xFF666666)),
          ),
          trailing: const Icon(Icons.chevron_right, size: 16, color: Color(0xFFCCCCCC)),
          onTap: () => Navigator.pop(context, item),
        );
      },
    );
  }

  Widget _buildStepperHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Region Selected',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF999999),
                ),
              ),
              GestureDetector(
                onTap: _resetAll,
                child: const Text(
                  'Reset',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Stepper chain matching Image 2
          if (_selectedRegion != null)
            _buildStepRow(
              title: _selectedRegion!,
              isCurrent: _selectedProvince == null,
              onTap: () {
                setState(() {
                  _selectedProvince = null;
                  _selectedCity = null;
                  _selectedBarangay = null;
                });
              },
            ),

          if (_selectedProvince != null)
            _buildStepRow(
              title: _selectedProvince!,
              isCurrent: _selectedCity == null,
              onTap: () {
                setState(() {
                  _selectedCity = null;
                  _selectedBarangay = null;
                });
              },
            ),

          if (_selectedCity != null)
            _buildStepRow(
              title: _selectedCity!,
              isCurrent: _selectedBarangay == null,
              onTap: () {
                setState(() {
                  _selectedBarangay = null;
                });
              },
            ),

          if (_selectedBarangay != null)
            _buildStepRow(
              title: _selectedBarangay!,
              isCurrent: true,
              isLastActive: true,
              onTap: () {},
            ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String title,
    required bool isCurrent,
    bool isLastActive = false,
    required VoidCallback onTap,
  }) {
    if (isLastActive) {
      return Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.radio_button_checked,
                  color: primaryBlue,
                  size: 18,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFCBD5E1),
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 1.5,
                  height: 24,
                  color: const Color(0xFFE2E8F0),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Padding(
            padding: const EdgeInsets.only(top: 0),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                color: isCurrent ? primaryBlue : const Color(0xFF222222),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsList() {
    final items = _currentItems;
    final grouped = _groupAlphabetically(items);
    final sortedKeys = grouped.keys.toList()..sort();

    return ListView.builder(
      itemCount: sortedKeys.length,
      itemBuilder: (context, sectionIndex) {
        final letter = sortedKeys[sectionIndex];
        final sectionItems = grouped[letter]!;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Alphabet Column (e.g. B, C, D) matching Image 2
            SizedBox(
              width: 44,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  letter,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF999999),
                  ),
                ),
              ),
            ),

            // Items in Section
            Expanded(
              child: Column(
                children: List.generate(sectionItems.length, (idx) {
                  final name = sectionItems[idx];
                  final isLast = idx == sectionItems.length - 1;
                  final isSelected = name == _selectedBarangay;

                  return InkWell(
                    onTap: () => _onItemSelected(name),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      decoration: BoxDecoration(
                        border: isLast && sectionIndex == sortedKeys.length - 1
                            ? null
                            : const Border(
                                bottom: BorderSide(color: Color(0xFFF0F0F0), width: 0.8),
                              ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? primaryBlue : const Color(0xFF222222),
                              ),
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check, size: 18, color: primaryBlue),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        );
      },
    );
  }
}
