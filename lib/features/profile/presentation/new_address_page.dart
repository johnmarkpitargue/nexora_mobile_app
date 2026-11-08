import 'dart:math' as math;
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../app/theme/nexora_theme.dart';
import '../../../core/services/address_service.dart';
import '../../../core/services/buyer_account_service.dart';
import '../../../core/services/laguna_places_service.dart';
import '../../../core/services/ph_location_service.dart';
import '../../../core/services/psgc_location_service.dart';
import 'region_selector_page.dart';

class NewAddressPage extends StatefulWidget {
  final AddressModel? editAddress;

  const NewAddressPage({
    super.key,
    this.editAddress,
  });

  @override
  State<NewAddressPage> createState() => _NewAddressPageState();
}

class _NewAddressPageState extends State<NewAddressPage> {
  static const Color primaryBlue = NexoraTheme.primary; // Color(0xFF0066FF)
  static const Color textDark = Color(0xFF0F172A);
  static const Color labelGray = Color(0xFF64748B);

  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _postalController;
  late final TextEditingController _streetController;
  late final TextEditingController _houseNumberController;

  String? _selectedRegion;
  String? _selectedRegionCode;
  String? _selectedProvince;
  String? _selectedProvinceCode;
  String? _selectedCity;
  String? _selectedMunicipalityCode;
  String? _selectedBarangay;
  String? _selectedBarangayCode;

  bool _isDefault = false;
  String _selectedLabel = 'Home'; // 'Work' or 'Home'
  String? _validationError;

  double? _latitude;
  double? _longitude;
  String? _pinpointPlaceName;

  @override
  void initState() {
    super.initState();
    final item = widget.editAddress;
    _nameController = TextEditingController(text: item?.fullName ?? '');
    _phoneController = TextEditingController(text: item?.phone ?? '');
    _postalController = TextEditingController(text: item?.postalCode ?? '');
    _streetController = TextEditingController(text: item?.streetBuilding ?? '');
    _houseNumberController = TextEditingController(text: item?.houseNumber ?? '');

    if (item != null) {
      _selectedRegion = item.region.isNotEmpty ? item.region : null;
      _selectedRegionCode = item.regionCode.isNotEmpty ? item.regionCode : null;
      _selectedProvince = item.province.isNotEmpty ? item.province : null;
      _selectedProvinceCode = item.provinceCode.isNotEmpty ? item.provinceCode : null;
      _selectedCity = item.city.isNotEmpty ? item.city : null;
      _selectedMunicipalityCode = item.municipalityCode.isNotEmpty ? item.municipalityCode : null;
      _selectedBarangay = item.barangay.isNotEmpty ? item.barangay : null;
      _selectedBarangayCode = item.barangayCode.isNotEmpty ? item.barangayCode : null;
      _latitude = item.latitude;
      _longitude = item.longitude;
      _pinpointPlaceName = '${item.barangay}, ${item.city}, ${item.province}';
      _isDefault = item.isDefault;
      _selectedLabel = item.label;
    } else {
      // Clean blank state for adding a NEW address
      _selectedRegion = null;
      _selectedRegionCode = null;
      _selectedProvince = null;
      _selectedProvinceCode = null;
      _selectedCity = null;
      _selectedMunicipalityCode = null;
      _selectedBarangay = null;
      _selectedBarangayCode = null;
      _latitude = null;
      _longitude = null;
      _pinpointPlaceName = null;
      _isDefault = AddressService.instance.addresses.isEmpty;
      _selectedLabel = 'Home';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _postalController.dispose();
    _streetController.dispose();
    _houseNumberController.dispose();
    super.dispose();
  }

  bool get _hasSelectedLocation =>
      _selectedRegion != null && _selectedCity != null && _selectedBarangay != null;

  /// Opens the Stepped Region Selector (matching Image 2)
  Future<void> _openRegionSelector() async {
    final result = await Navigator.push<RegionSelectionResult>(
      context,
      MaterialPageRoute(
        builder: (context) => RegionSelectorPage(
          initialRegion: _selectedRegion,
          initialProvince: _selectedProvince,
          initialCity: _selectedCity,
          initialBarangay: _selectedBarangay,
        ),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedRegion = result.region;
        _selectedRegionCode = result.regionCode;
        _selectedProvince = result.province;
        _selectedProvinceCode = result.provinceCode;
        _selectedCity = result.city;
        _selectedMunicipalityCode = result.municipalityCode;
        _selectedBarangay = result.barangay;
        _selectedBarangayCode = result.barangayCode;
        _postalController.text = result.postalCode;
        _latitude = result.latitude;
        _longitude = result.longitude;
        _pinpointPlaceName = '${result.barangay}, ${result.city}, ${result.province}';
        _validationError = null;
      });
    }
  }

  /// Interactive Delivery Map Pinpoint Modal
  void _openInteractiveMapPinpointModal() {
    double tempLat = _latitude ?? 0.0;
    double tempLng = _longitude ?? 0.0;

    if (tempLat == 0.0 || tempLng == 0.0) {
      if (_selectedCity != null && _selectedCity!.isNotEmpty) {
        final coords = PhLocationHierarchy.getCoordinates(_selectedCity!, _selectedBarangay ?? '');
        tempLat = coords.$1;
        tempLng = coords.$2;
      } else {
        final resolved = LagunaPlacesService.instance.resolveCoordinates('${_selectedCity ?? ''} ${_selectedProvince ?? ''}');
        tempLat = resolved.latitude;
        tempLng = resolved.longitude;
      }
    }

    int tempZoom = 15;
    final areaParts = [
      if (_selectedBarangay != null && _selectedBarangay!.isNotEmpty) _selectedBarangay!,
      if (_selectedCity != null && _selectedCity!.isNotEmpty) _selectedCity!,
      if (_selectedProvince != null && _selectedProvince!.isNotEmpty) _selectedProvince!,
    ];
    String tempPlaceName = _pinpointPlaceName ??
        (areaParts.isNotEmpty ? areaParts.join(', ') : 'Delivery Location Pin');
    if (tempPlaceName == 'Delivery Location Pin') {
      final nearest = LagunaPlacesService.instance.getNearestPlace(tempLat, tempLng);
      tempPlaceName = '${nearest.name}, ${nearest.cityOrMunicipality}';
    }

    final searchController = TextEditingController();
    List<LagunaPlace> searchSuggestions = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalCtx) => StatefulBuilder(
        builder: (modalCtx, setModalState) {
          final int z = tempZoom;
          final double globalTileX = (tempLng + 180.0) / 360.0 * (1 << z);
          final double latRad = tempLat * math.pi / 180.0;
          final double globalTileY = (1.0 -
                  (math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) /
                      math.pi)) /
              2.0 *
              (1 << z);

          final int centerTileX = globalTileX.floor();
          final int centerTileY = globalTileY.floor();
          final double fracX = globalTileX - centerTileX;
          final double fracY = globalTileY - centerTileY;

          return Container(
            height: MediaQuery.of(context).size.height * 0.90,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                // Modal Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: primaryBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.pin_drop_rounded,
                            color: primaryBlue, size: 20),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pinpoint Delivery Location',
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: textDark),
                            ),
                            Text(
                              'Move map to place pin at your exact doorstep or gate',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Color(0xFF64748B)),
                        onPressed: () => Navigator.pop(modalCtx),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Search Bar for Landmarks / Streets
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.search_rounded,
                            size: 18, color: Color(0xFF64748B)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: searchController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              hintText: 'Search place, landmark, or street...',
                              hintStyle: TextStyle(
                                  fontSize: 12.5, color: Color(0xFF94A3B8)),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 10),
                            ),
                            onChanged: (val) async {
                              if (val.trim().isEmpty) {
                                setModalState(() {
                                  searchSuggestions = [];
                                });
                              } else {
                                final res = await LagunaPlacesService.instance
                                    .searchPlaces(val);
                                setModalState(() {
                                  searchSuggestions = res;
                                });
                              }
                            },
                          ),
                        ),
                        if (searchController.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              searchController.clear();
                              setModalState(() => searchSuggestions = []);
                            },
                            child: const Icon(Icons.clear_rounded,
                                size: 16, color: Color(0xFF94A3B8)),
                          ),
                      ],
                    ),
                  ),
                ),

                if (searchSuggestions.isNotEmpty)
                  Container(
                    constraints: const BoxConstraints(maxHeight: 180),
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: searchSuggestions.length.clamp(0, 5),
                      separatorBuilder: (ctx, index) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (ctx, idx) {
                        final p = searchSuggestions[idx];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.location_on_outlined,
                              size: 18, color: primaryBlue),
                          title: Text(p.name,
                              style: const TextStyle(
                                  fontSize: 12.5, fontWeight: FontWeight.bold)),
                          subtitle: Text(
                              '${p.cityOrMunicipality}, ${p.province} • ${p.postalCode}',
                              style: const TextStyle(fontSize: 10.5)),
                          onTap: () {
                            setModalState(() {
                              tempLat = p.latitude;
                              tempLng = p.longitude;
                              tempPlaceName = '${p.name}, ${p.cityOrMunicipality}';
                              searchSuggestions = [];
                              searchController.text = p.name;
                            });
                          },
                        );
                      },
                    ),
                  ),

                const SizedBox(height: 8),

                // Interactive Map Viewport with Center Pin & Drag Controls
                Expanded(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRect(
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final mapWidth = constraints.maxWidth;
                            final mapHeight = constraints.maxHeight;
                            final originX =
                                (mapWidth / 2) - (fracX * 256.0);
                            final originY =
                                (mapHeight / 2) - (fracY * 256.0);

                            final tiles = <Widget>[];
                            for (int dx = -2; dx <= 2; dx++) {
                              for (int dy = -2; dy <= 2; dy++) {
                                final left = originX + (dx * 256.0);
                                final top = originY + (dy * 256.0);

                                if (left + 256 < 0 ||
                                    left > mapWidth ||
                                    top + 256 < 0 ||
                                    top > mapHeight) {
                                  continue;
                                }

                                final tx = centerTileX + dx;
                                final ty = centerTileY + dy;
                                final googleTileUrl =
                                    'https://mt1.google.com/vt/lyrs=m&x=$tx&y=$ty&z=$z';
                                final osmTileUrl =
                                    'https://tile.openstreetmap.org/$z/$tx/$ty.png';

                                tiles.add(
                                  Positioned(
                                    left: left,
                                    top: top,
                                    width: 256,
                                    height: 256,
                                    child: Image.network(
                                      googleTileUrl,
                                      fit: BoxFit.cover,
                                      gaplessPlayback: true,
                                      errorBuilder: (context, error, stackTrace) =>
                                          Image.network(
                                        osmTileUrl,
                                        headers: kIsWeb
                                            ? null
                                            : const {
                                                'User-Agent':
                                                    'NexoraBuyerApp/1.0 (com.example.nexora_flutter_app)',
                                              },
                                        fit: BoxFit.cover,
                                        gaplessPlayback: true,
                                        errorBuilder: (ctx, err, st) =>
                                            CustomPaint(
                                          size: const Size(256, 256),
                                          painter: _DynamicMapCanvasPainter(
                                            lat: tempLat,
                                            lng: tempLng,
                                            label: _selectedBarangay ?? '',
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }
                            }

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onPanUpdate: (details) {
                                setModalState(() {
                                  final moveDx = details.delta.dx;
                                  final moveDy = details.delta.dy;
                                  final metersPerPixel =
                                      156543.03392 *
                                          math.cos(tempLat * math.pi / 180.0) /
                                          math.pow(2, z);
                                  final double deltaLng =
                                      -(moveDx * metersPerPixel) /
                                          (111320.0 *
                                              math.cos(tempLat * math.pi / 180.0));
                                  final double deltaLat =
                                      (moveDy * metersPerPixel) / 110540.0;

                                  tempLat = (tempLat + deltaLat).clamp(-85.0, 85.0);
                                  tempLng = (tempLng + deltaLng).clamp(-180.0, 180.0);
                                });
                              },
                              onPanEnd: (_) {
                                setModalState(() {
                                  final nearest = LagunaPlacesService.instance.getNearestPlace(tempLat, tempLng);
                                  tempPlaceName = '${nearest.name}, ${nearest.cityOrMunicipality}';
                                });
                              },
                              child: Container(
                                color: const Color(0xFFDCF0D8),
                                child: Stack(
                                  children: [
                                    Positioned.fill(
                                      child: CustomPaint(
                                        painter: _DynamicMapCanvasPainter(
                                          lat: tempLat,
                                          lng: tempLng,
                                          label: _selectedBarangay ?? '',
                                        ),
                                      ),
                                    ),
                                    ...tiles,
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),

                      // Fixed Center Target Pin
                      IgnorePointer(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: textDark,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.doorbell_rounded,
                                      color: primaryBlue, size: 12),
                                  SizedBox(width: 4),
                                  Text(
                                    'Delivery Doorstep Pin',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Icon(
                              Icons.location_on_rounded,
                              size: 44,
                              color: Color(0xFFEA4335),
                            ),
                            Container(
                              width: 10,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),

                      // Map Zoom +/- and Locate Controls
                      Positioned(
                        bottom: 16,
                        right: 16,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FloatingActionButton.small(
                              heroTag: 'map_locate',
                              backgroundColor: Colors.white,
                              foregroundColor: primaryBlue,
                              elevation: 3,
                              onPressed: () async {
                                final loc = await LagunaPlacesService.instance.getCurrentDeviceLocation();
                                if (loc != null) {
                                  setModalState(() {
                                    tempLat = loc.latitude;
                                    tempLng = loc.longitude;
                                    tempPlaceName = loc.name;
                                  });
                                } else if (_selectedCity != null && _selectedCity!.isNotEmpty) {
                                  final coords = PhLocationHierarchy.getCoordinates(_selectedCity!, _selectedBarangay ?? '');
                                  setModalState(() {
                                    tempLat = coords.$1;
                                    tempLng = coords.$2;
                                    tempPlaceName = '${_selectedBarangay ?? ''}, ${_selectedCity!}';
                                  });
                                } else {
                                  setModalState(() {
                                    tempLat = 14.1332;
                                    tempLng = 121.4367;
                                    tempPlaceName = 'Tuy-Baanan, Liliw, Laguna';
                                  });
                                }
                              },
                              child: const Icon(Icons.my_location_rounded, size: 20),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.add, size: 18),
                                    onPressed: () {
                                      if (tempZoom < 18) {
                                        setModalState(() => tempZoom++);
                                      }
                                    },
                                    constraints: const BoxConstraints(
                                        minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                  ),
                                  const Divider(height: 1),
                                  IconButton(
                                    icon: const Icon(Icons.remove, size: 18),
                                    onPressed: () {
                                      if (tempZoom > 12) {
                                        setModalState(() => tempZoom--);
                                      }
                                    },
                                    constraints: const BoxConstraints(
                                        minWidth: 36, minHeight: 36),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Google attribution watermark
                      Positioned(
                        bottom: 8,
                        left: 10,
                        child: IgnorePointer(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.7),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'Google',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF5F6368),
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Bottom Confirmation Card
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              size: 16, color: Color(0xFF10B981)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              tempPlaceName,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: textDark,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Coordinates: ${tempLat.toStringAsFixed(4)}° N, ${tempLng.toStringAsFixed(4)}° E',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _latitude = tempLat;
                              _longitude = tempLng;
                              _pinpointPlaceName = tempPlaceName;
                            });
                            Navigator.pop(modalCtx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                    '✓ Delivery pinpoint confirmed at $tempPlaceName!'),
                                backgroundColor: primaryBlue,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            'Confirm Pinpoint Location',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() => _validationError = null);
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final postal = _postalController.text.trim();
    final street = _streetController.text.trim();

    if (name.isEmpty) {
      setState(() => _validationError = 'Please enter your full name');
      return;
    }

    final normalizedPhone = BuyerValidationRules.normalizePhone(phone);
    if (!BuyerValidationRules.phoneRegex.hasMatch(normalizedPhone)) {
      setState(() => _validationError = 'Invalid mobile number format. Must be 11 digits starting with 09');
      return;
    }

    if (_selectedRegion == null || _selectedCity == null || _selectedBarangay == null) {
      setState(() => _validationError = 'Please select Region, Province, City, and Barangay');
      return;
    }

    if (postal.isEmpty) {
      setState(() => _validationError = 'Please enter your postal code');
      return;
    }
    if (street.isEmpty) {
      setState(() => _validationError = 'Please enter street name, building, and house number');
      return;
    }

    final regionCity = '$_selectedRegion, ${_selectedProvince ?? ''}, $_selectedCity, $_selectedBarangay';

    double lat;
    double lng;
    if (_latitude != null && _longitude != null) {
      lat = _latitude!;
      lng = _longitude!;
    } else if (_selectedCity != null && _selectedCity!.isNotEmpty) {
      final coords = PhLocationHierarchy.getCoordinates(_selectedCity!, _selectedBarangay ?? '');
      lat = coords.$1;
      lng = coords.$2;
    } else {
      final resolved = LagunaPlacesService.instance.resolveCoordinates(regionCity);
      lat = resolved.latitude;
      lng = resolved.longitude;
    }

    if (widget.editAddress == null && !AddressService.instance.canAddAddress) {
      setState(() => _validationError =
          'Maximum 10 addresses reached. Please edit or delete an existing address.');
      return;
    }

    final regCode = _selectedRegionCode ??
        PsgcLocationService.resolveRegionCode(_selectedRegion!, _selectedProvince);
    final provCode = _selectedProvinceCode ??
        PsgcLocationService.resolveProvinceCode(_selectedProvince ?? '');
    final cityCode = _selectedMunicipalityCode ??
        PsgcLocationService.resolveCityCode(_selectedCity!, provCode);
    final brgyCode = _selectedBarangayCode ??
        PsgcLocationService.resolveBarangayCode(_selectedBarangay!, cityCode);
    final houseNum = _houseNumberController.text.trim();

    if (widget.editAddress != null) {
      final updated = widget.editAddress!.copyWith(
        fullName: name,
        phone: phone,
        region: _selectedRegion!,
        regionCode: regCode,
        province: _selectedProvince ?? '',
        provinceCode: provCode,
        city: _selectedCity!,
        municipalityCode: cityCode,
        barangay: _selectedBarangay!,
        barangayCode: brgyCode,
        regionCity: regionCity,
        postalCode: postal,
        streetBuilding: street,
        houseNumber: houseNum,
        label: _selectedLabel,
        isDefault: _isDefault,
        latitude: lat,
        longitude: lng,
      );
      final res = await AddressService.instance.updateAddressRemote(updated);
      if (!res.success) {
        setState(() => _validationError = res.message);
        return;
      }

      _showToast('Address updated successfully');
    } else {
      final newAddr = AddressModel(
        id: 'addr_${DateTime.now().millisecondsSinceEpoch}',
        fullName: name,
        phone: phone,
        region: _selectedRegion!,
        regionCode: regCode,
        province: _selectedProvince ?? '',
        provinceCode: provCode,
        city: _selectedCity!,
        municipalityCode: cityCode,
        barangay: _selectedBarangay!,
        barangayCode: brgyCode,
        regionCity: regionCity,
        postalCode: postal,
        streetBuilding: street,
        houseNumber: houseNum,
        label: _selectedLabel,
        isDefault: _isDefault,
        latitude: lat,
        longitude: lng,
      );

      final res = await AddressService.instance.addAddressRemote(newAddr);
      if (!res.success) {
        setState(() => _validationError = res.message);
        return;
      }

      _showToast('New address saved successfully');
    }

    if (!mounted) return;
    Navigator.pop(context);
  }

  void _showDeleteConfirmDialog() {
    if (widget.editAddress == null) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Address', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        content: const Text(
          'Are you sure you want to delete this delivery address?',
          style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _handleDelete();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete() async {
    if (widget.editAddress == null) return;

    final res = await AddressService.instance.deleteAddressRemote(widget.editAddress!.id);
    if (!res.success) {
      if (!mounted) return;
      setState(() => _validationError = res.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res.message),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (!mounted) return;
    _showToast('Address deleted successfully');
    Navigator.pop(context);
  }

  void _showToast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: primaryBlue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editAddress != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: textDark, size: 22),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Address' : 'New Address',
          style: const TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, color: Color(0xFFF1F5F9)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 30),
        child: Column(
          children: [
            // Top Clean Nexora Info Banner
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFDBEAFE), width: 1),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: primaryBlue, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Please ensure your address details and delivery pin are accurate for fast and reliable courier delivery.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF1E3A8A),
                        height: 1.35,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (_validationError != null)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.redAccent.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),

            // Card 1: Address Card with Embedded Map at the bottom
            Container(
              margin: const EdgeInsets.fromLTRB(16, 6, 16, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Address Details',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Full Name
                        const Text('Full Name', style: TextStyle(fontSize: 12, color: labelGray, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        TextField(
                          controller: _nameController,
                          onChanged: (_) => setState(() {}),
                          textCapitalization: TextCapitalization.words,
                          style: const TextStyle(fontSize: 14.5, color: textDark, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: 'Enter receiver full name',
                            hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFFCBD5E1)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                        const Divider(height: 18, color: Color(0xFFF1F5F9)),

                        // Phone Number
                        const Text('Phone Number', style: TextStyle(fontSize: 12, color: labelGray, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        TextField(
                          controller: _phoneController,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.phone,
                          style: const TextStyle(fontSize: 14.5, color: textDark, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: '09XXXXXXXXX or (+63) 9XXXXXXXXX',
                            hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFFCBD5E1)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                        const Divider(height: 18, color: Color(0xFFF1F5F9)),

                        // Region, Province, City, Barangay (Multi-line with >)
                        InkWell(
                          onTap: _openRegionSelector,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Region, Province, City, Barangay',
                                        style: TextStyle(fontSize: 12, color: labelGray, fontWeight: FontWeight.w600),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _hasSelectedLocation
                                            ? '${_selectedRegion!}\n${_selectedProvince ?? ''}\n${_selectedCity!}\n${_selectedBarangay!}'
                                            : 'Select Region, Province, City, Barangay',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          color: _hasSelectedLocation ? textDark : const Color(0xFF94A3B8),
                                          fontWeight: _hasSelectedLocation ? FontWeight.w600 : FontWeight.normal,
                                          height: _hasSelectedLocation ? 1.35 : 1.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right, size: 20, color: labelGray),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 18, color: Color(0xFFF1F5F9)),

                        // Postal Code
                        const Text('Postal Code', style: TextStyle(fontSize: 12, color: labelGray, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        TextField(
                          controller: _postalController,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          buildCounter: (ctx, {required currentLength, required isFocused, maxLength}) => null,
                          style: const TextStyle(fontSize: 14.5, color: textDark, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: 'e.g. 4004',
                            hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFFCBD5E1)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                        const Divider(height: 18, color: Color(0xFFF1F5F9)),

                        // Street Name, Building, House No.
                        const Text('Street Name, Building, House No.', style: TextStyle(fontSize: 12, color: labelGray, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        TextField(
                          controller: _streetController,
                          onChanged: (_) => setState(() {}),
                          keyboardType: TextInputType.streetAddress,
                          style: const TextStyle(fontSize: 14.5, color: textDark, fontWeight: FontWeight.w600),
                          decoration: const InputDecoration(
                            hintText: 'House / Unit / Building / Street Number',
                            hintStyle: TextStyle(fontSize: 13.5, color: Color(0xFFCBD5E1)),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                    ),
                  ),

                  // EMBEDDED MAP PREVIEW (Live Centered on Pin or Invitation Card)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    child: _buildEmbeddedMapPreview(),
                  ),
                ],
              ),
            ),

            // Card 2: Settings & Tag
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                      const Expanded(
                        child: Text(
                          'Set as Default Delivery Address',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                      ),
                      CupertinoSwitch(
                        value: _isDefault,
                        activeTrackColor: primaryBlue,
                        inactiveTrackColor: const Color(0xFFE2E8F0),
                        onChanged: (val) => setState(() => _isDefault = val),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      const Text(
                        'Label As:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                      const Spacer(),
                      _buildLabelButton('Work'),
                      const SizedBox(width: 10),
                      _buildLabelButton('Home'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),

      // Bottom Action Buttons with Clean Elevation & No Clipping
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: isEditing
              ? Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _showDeleteConfirmDialog,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE11D48), width: 1.2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            backgroundColor: Colors.white,
                          ),
                          child: const Text(
                            'Delete Address',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFE11D48),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Submit',
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  /// Builds the embedded map preview inside the Address Card, actively centered on pinned coordinates
  Widget _buildEmbeddedMapPreview() {
    // If no coordinates yet (e.g. adding a new address), display an inviting pinpoint trigger card
    if (_latitude == null || _longitude == null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: const BoxDecoration(
          color: Color(0xFFF8FAFC),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.pin_drop_rounded, color: primaryBlue, size: 18),
                SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Delivery Pinpoint on Map',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.bold,
                      color: textDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            InkWell(
              onTap: _openInteractiveMapPinpointModal,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: primaryBlue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_location_alt_rounded, size: 15, color: primaryBlue),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Set / Adjust Delivery Pin on Map',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: primaryBlue,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    final lat = _latitude!;
    final lng = _longitude!;
    const int z = 16;

    final double globalTileX = (lng + 180.0) / 360.0 * (1 << z);
    final double latRad = lat * math.pi / 180.0;
    final double globalTileY = (1.0 -
            (math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) /
                math.pi)) /
        2.0 *
        (1 << z);

    final int centerTileX = globalTileX.floor();
    final int centerTileY = globalTileY.floor();
    final double fracX = globalTileX - centerTileX;
    final double fracY = globalTileY - centerTileY;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar & Action Button stacked cleanly for all viewport widths
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.pin_drop_rounded, color: primaryBlue, size: 18),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Delivery Pinpoint on Map',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.my_location_rounded, size: 13, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'Coordinates: ${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _openInteractiveMapPinpointModal,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: primaryBlue.withValues(alpha: 0.25)),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.edit_location_alt_rounded, size: 14, color: primaryBlue),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'Set / Adjust Delivery Pin on Map',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: primaryBlue,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Live Map Viewport
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _openInteractiveMapPinpointModal,
            onPanUpdate: (details) {
              setState(() {
                final moveDx = details.delta.dx;
                final moveDy = details.delta.dy;
                final metersPerPixel =
                    156543.03392 * math.cos(lat * math.pi / 180.0) / math.pow(2, z);
                final double deltaLng = -(moveDx * metersPerPixel) /
                    (111320.0 * math.cos(lat * math.pi / 180.0));
                final double deltaLat = (moveDy * metersPerPixel) / 110540.0;

                _latitude = (lat + deltaLat).clamp(-85.0, 85.0);
                _longitude = (lng + deltaLng).clamp(-180.0, 180.0);
              });
            },
            onPanEnd: (_) {
              setState(() {
                final nearest = LagunaPlacesService.instance.getNearestPlace(_latitude!, _longitude!);
                _pinpointPlaceName = '${nearest.name}, ${nearest.cityOrMunicipality}';
              });
            },
            child: Container(
              height: 140,
              width: double.infinity,
              color: const Color(0xFFDCF0D8),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Live map tiles canvas
                  ClipRect(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final mapWidth = constraints.maxWidth;
                        final mapHeight = constraints.maxHeight;
                        final originX = (mapWidth / 2) - (fracX * 256.0);
                        final originY = (mapHeight / 2) - (fracY * 256.0);

                        final tiles = <Widget>[];
                        for (int dx = -2; dx <= 2; dx++) {
                          for (int dy = -1; dy <= 1; dy++) {
                            final left = originX + (dx * 256.0);
                            final top = originY + (dy * 256.0);

                            if (left + 256 < 0 ||
                                left > mapWidth ||
                                top + 256 < 0 ||
                                top > mapHeight) {
                              continue;
                            }

                            final tx = centerTileX + dx;
                            final ty = centerTileY + dy;
                            final googleTileUrl =
                                'https://mt1.google.com/vt/lyrs=m&x=$tx&y=$ty&z=$z';
                            final osmTileUrl =
                                'https://tile.openstreetmap.org/$z/$tx/$ty.png';

                            tiles.add(
                              Positioned(
                                left: left,
                                top: top,
                                width: 256,
                                height: 256,
                                child: Image.network(
                                  googleTileUrl,
                                  fit: BoxFit.cover,
                                  gaplessPlayback: true,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Image.network(
                                    osmTileUrl,
                                    fit: BoxFit.cover,
                                    gaplessPlayback: true,
                                    errorBuilder: (ctx, err, st) => CustomPaint(
                                      size: const Size(256, 256),
                                      painter: _DynamicMapCanvasPainter(
                                        lat: lat,
                                        lng: lng,
                                        label: _selectedBarangay ?? '',
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }
                        }

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _DynamicMapCanvasPainter(
                                  lat: lat,
                                  lng: lng,
                                  label: _selectedBarangay ?? '',
                                ),
                              ),
                            ),
                            ...tiles,
                          ],
                        );
                      },
                    ),
                  ),

                  // Google Wordmark Attribution at bottom left
                  Positioned(
                    bottom: 8,
                    left: 10,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.75),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Text(
                          'Google',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5F6368),
                            letterSpacing: -0.4,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Center Red Location Pin (Centered needle tip on coordinates)
                  IgnorePointer(
                    child: Center(
                      child: Transform.translate(
                        offset: const Offset(0, -14),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              size: 38,
                              color: Color(0xFFEA4335),
                            ),
                            Container(
                              width: 8,
                              height: 3,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.28),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the 'Work' or 'Home' label button with selected checkmark (Nexora Blue)
  Widget _buildLabelButton(String label) {
    final isSelected = _selectedLabel == label;

    if (isSelected) {
      return GestureDetector(
        onTap: () => setState(() => _selectedLabel = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: primaryBlue, width: 1.3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 14, color: primaryBlue),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedLabel = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

/// Dynamic custom painter rendering road & terrain view shifted by coordinates
class _DynamicMapCanvasPainter extends CustomPainter {
  final double lat;
  final double lng;
  final String label;

  _DynamicMapCanvasPainter({
    required this.lat,
    required this.lng,
    required this.label,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Terrain Background (Soft Google Maps light green)
    final bgPaint = Paint()..color = const Color(0xFFDCF0D8);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Coordinate-based offset so roads visibly move when coordinates change
    final double normLng = (lng * 10000.0);
    final double normLat = (lat * 10000.0);
    final double offsetX = (normLng % 160.0) - 80.0;
    final double offsetY = (normLat % 100.0) - 50.0;

    // 2. Secondary field/parcel variations
    final parcelPaint = Paint()..color = const Color(0xFFE8F6E4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          (size.width * 0.40) + offsetX,
          10 + offsetY,
          size.width * 0.55,
          size.height * 0.75,
        ),
        const Radius.circular(6),
      ),
      parcelPaint,
    );

    // 3. Small building footprints along the roads
    final buildingPaint = Paint()..color = const Color(0xFFF1F5F9);
    final bOffsets = [
      Offset(size.width * 0.38 + offsetX, size.height * 0.42 + offsetY),
      Offset(size.width * 0.42 + offsetX, size.height * 0.40 + offsetY),
      Offset(size.width * 0.46 + offsetX, size.height * 0.45 + offsetY),
      Offset(size.width * 0.52 + offsetX, size.height * 0.48 + offsetY),
      Offset(size.width * 0.55 + offsetX, size.height * 0.43 + offsetY),
      Offset(size.width * 0.48 + offsetX, size.height * 0.54 + offsetY),
      Offset(size.width * 0.44 + offsetX, size.height * 0.58 + offsetY),
    ];
    for (final off in bOffsets) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: off, width: 14, height: 12),
          const Radius.circular(2),
        ),
        buildingPaint,
      );
    }

    // 4. Main Road (White with light gray border)
    final roadBorderPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round;

    final roadFillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(size.width * 0.15 + offsetX, -10 + offsetY);
    path.lineTo(size.width * 0.32 + offsetX, size.height * 0.38 + offsetY);
    path.quadraticBezierTo(
      size.width * 0.38 + offsetX,
      size.height * 0.55 + offsetY,
      size.width * 0.62 + offsetX,
      size.height * 0.65 + offsetY,
    );
    path.lineTo(size.width * 0.85 + offsetX, size.height + 10 + offsetY);

    canvas.drawPath(path, roadBorderPaint);
    canvas.drawPath(path, roadFillPaint);

    // Connecting residential street
    final alleyBorder = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final alleyFill = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9
      ..strokeCap = StrokeCap.round;

    final alleyPath = Path();
    alleyPath.moveTo(size.width * 0.32 + offsetX, size.height * 0.38 + offsetY);
    alleyPath.lineTo(size.width * 0.55 + offsetX, size.height * 0.30 + offsetY);
    canvas.drawPath(alleyPath, alleyBorder);
    canvas.drawPath(alleyPath, alleyFill);

    // 5. Road Name Label
    canvas.save();
    canvas.translate(size.width * 0.22 + offsetX, size.height * 0.18 + offsetY);
    canvas.rotate(0.9);
    final textPainter = TextPainter(
      text: TextSpan(
        text: label.isNotEmpty ? '$label Rd' : 'a Rd',
        style: const TextStyle(
          color: Color(0xFF64748B),
          fontSize: 9.5,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DynamicMapCanvasPainter oldDelegate) =>
      oldDelegate.lat != lat ||
      oldDelegate.lng != lng ||
      oldDelegate.label != label;
}
