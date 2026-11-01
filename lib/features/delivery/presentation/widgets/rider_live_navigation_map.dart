import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/services/rider_location_service.dart';

/// Modern Real-Time Live Navigation Map for Nexora Rider App.
///
/// Features:
/// 1. Up-to-date crisp CartoDB Voyager & OpenStreetMap tiles (replaces outdated legacy map).
/// 2. Real instantaneous hardware GPS speedometer (km/h) with stationary clamping.
/// 3. Vehicle heading arrow & pulse beacon rotating with real-time compass heading.
/// 4. Dynamic connecting route line to customer drop-off pin.
/// 5. Camera recentering, multi-level zoom (13-18), and Street/Dark/Satellite styles.
/// 6. Turn-by-Turn launch trigger for Google Maps app navigation.
class RiderLiveNavigationMap extends StatefulWidget {
  final double destinationLat;
  final double destinationLng;
  final String destinationAddress;
  final String customerName;
  final String orderId;

  const RiderLiveNavigationMap({
    super.key,
    required this.destinationLat,
    required this.destinationLng,
    required this.destinationAddress,
    required this.customerName,
    required this.orderId,
  });

  @override
  State<RiderLiveNavigationMap> createState() => _RiderLiveNavigationMapState();
}

class _RiderLiveNavigationMapState extends State<RiderLiveNavigationMap>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  int _tileZoom = 15;
  bool _customZoomSet = false;
  Offset _panOffset = Offset.zero;
  int _mapStyleIndex = 0; // 0: Modern Street (Voyager), 1: Dark Matter, 2: Satellite

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _getTileUrl(int z, int x, int y) {
    switch (_mapStyleIndex) {
      case 1:
        // Esri High-Contrast World Street Map (zero watermark, no auth required)
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Street_Map/MapServer/tile/$z/$y/$x';
      case 2:
        // Esri High-Resolution World Imagery (satellite)
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/$z/$y/$x';
      case 0:
      default:
        // OpenStreetMap Standard Tiles (open, reliable, zero API key required, zero watermark)
        return 'https://tile.openstreetmap.org/$z/$x/$y.png';
    }
  }

  Future<void> _launchTurnByTurnNavigation() async {
    final lat = widget.destinationLat;
    final lng = widget.destinationLng;
    final label = Uri.encodeComponent(widget.destinationAddress);

    try {
      Uri? navUri;
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        // Android Google Maps turn-by-turn navigation intent
        final googleNavIntent = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
        if (await canLaunchUrl(googleNavIntent)) {
          navUri = googleNavIntent;
        }
      } else if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
        final googleMapsIos = Uri.parse('comgooglemaps://?daddr=$lat,$lng&directionsmode=driving');
        final appleMapsIos = Uri.parse('maps://?daddr=$lat,$lng&dirflg=d');
        if (await canLaunchUrl(googleMapsIos)) {
          navUri = googleMapsIos;
        } else if (await canLaunchUrl(appleMapsIos)) {
          navUri = appleMapsIos;
        }
      }

      navUri ??= Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');

      final launched = await launchUrl(navUri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallback = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng($label)');
        await launchUrl(fallback, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open external navigation: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locationService = RiderLocationService.instance;

    return ListenableBuilder(
      listenable: locationService,
      builder: (context, _) {
        final riderLat = locationService.currentLat;
        final riderLng = locationService.currentLng;
        final speedKmh = locationService.currentSpeedKmh;
        final heading = locationService.currentHeading;
        final accuracy = locationService.currentAccuracyMeters;

        final distKm = RiderLocationService.calculateDistanceKm(
          riderLat,
          riderLng,
          widget.destinationLat,
          widget.destinationLng,
        );

        final etaMins = (distKm / (speedKmh > 10 ? speedKmh : 24.0) * 60.0).round().clamp(1, 60);

        if (!_customZoomSet) {
          if (distKm > 40) {
            _tileZoom = 10;
          } else if (distKm > 20) {
            _tileZoom = 11;
          } else if (distKm > 8) {
            _tileZoom = 12;
          } else if (distKm > 3) {
            _tileZoom = 13;
          } else if (distKm > 1.2) {
            _tileZoom = 14;
          } else {
            _tileZoom = 15;
          }
        }

        final isDark = _mapStyleIndex == 1 || _mapStyleIndex == 2;
        final int z = _tileZoom;
        final double centerLat = (riderLat + widget.destinationLat) / 2.0;
        final double centerLng = (riderLng + widget.destinationLng) / 2.0;

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFCBD5E1),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Real-Time Speed & Telemetry HUD Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                color: const Color(0xFF0A192F),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Live Speedometer Chip
                    Expanded(
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00C4FF).withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF00C4FF).withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.speed_rounded, size: 16, color: Color(0xFF00C4FF)),
                                const SizedBox(width: 6),
                                Text(
                                  '${speedKmh.round()}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Text(
                                  'KM/H',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF38BDF8),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF10B981),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Expanded(
                                      child: Text(
                                        speedKmh > 1.5 ? 'CRUISING' : 'STATIONARY',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w900,
                                          color: speedKmh > 1.5
                                              ? const Color(0xFF34D399)
                                              : const Color(0xFFFBBF24),
                                          letterSpacing: 0.6,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'GNSS (±${accuracy.round()}m)',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    color: Color(0xFF94A3B8),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Map Style Switcher (Street / Dark / Sat)
                    InkWell(
                      onTap: () {
                        setState(() {
                          _mapStyleIndex = (_mapStyleIndex + 1) % 3;
                        });
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _mapStyleIndex == 0
                                  ? Icons.map_rounded
                                  : (_mapStyleIndex == 1
                                      ? Icons.nightlight_round
                                      : Icons.satellite_alt_rounded),
                              size: 13,
                              color: const Color(0xFF38BDF8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _mapStyleIndex == 0
                                  ? 'Street'
                                  : (_mapStyleIndex == 1 ? 'Night' : 'Satellite'),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Buyer Pinpoint Destination Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.location_on_rounded, size: 20, color: Color(0xFFEF4444)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  widget.customerName,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w900,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'BUYER PINPOINT',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF059669),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.destinationAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '${widget.destinationLat.toStringAsFixed(5)}° N, ${widget.destinationLng.toStringAsFixed(5)}° E',
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 3. Interactive Map Viewport with Real Slippy Tiles & Overlay
              SizedBox(
                height: 280,
                child: ClipRect(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final mapWidth = constraints.maxWidth;
                      final mapHeight = constraints.maxHeight;

                      // Mercator projection
                      final double globalTileX = (centerLng + 180.0) / 360.0 * (1 << z);
                      final double latRad = centerLat * math.pi / 180.0;
                      final double globalTileY = (1.0 -
                              (math.log(math.tan(latRad) + (1.0 / math.cos(latRad))) / math.pi)) /
                          2.0 *
                          (1 << z);

                      final int centerTileX = globalTileX.floor();
                      final int centerTileY = globalTileY.floor();

                      final double fracX = globalTileX - centerTileX;
                      final double fracY = globalTileY - centerTileY;

                      final double originPixelX =
                          (mapWidth / 2) - (fracX * 256.0) + _panOffset.dx;
                      final double originPixelY =
                          (mapHeight / 2) - (fracY * 256.0) + _panOffset.dy;

                      final tileWidgets = <Widget>[];
                      for (int dx = -2; dx <= 2; dx++) {
                        for (int dy = -2; dy <= 2; dy++) {
                          final double tileLeft = originPixelX + (dx * 256.0);
                          final double tileTop = originPixelY + (dy * 256.0);

                          if (tileLeft + 256 < 0 ||
                              tileLeft > mapWidth ||
                              tileTop + 256 < 0 ||
                              tileTop > mapHeight) {
                            continue;
                          }

                          final int tileX = centerTileX + dx;
                          final int tileY = centerTileY + dy;
                          final tileUrl = _getTileUrl(z, tileX, tileY);

                          tileWidgets.add(
                            Positioned(
                              left: tileLeft,
                              top: tileTop,
                              width: 256,
                              height: 256,
                              child: Image.network(
                                tileUrl,
                                headers: kIsWeb
                                    ? null
                                    : const {
                                        'User-Agent':
                                            'NexoraRiderApp/1.0 (com.nexora.nexora_rider_app)',
                                      },
                                fit: BoxFit.cover,
                                gaplessPlayback: true,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: isDark
                                      ? const Color(0xFF0F172A)
                                      : const Color(0xFFF1F5F9),
                                  child: Center(
                                    child: Icon(
                                      Icons.map_outlined,
                                      size: 20,
                                      color: isDark ? Colors.white12 : Colors.black12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }
                      }

                      return GestureDetector(
                        onPanUpdate: (details) {
                          setState(() {
                            _panOffset += details.delta;
                          });
                        },
                        child: Stack(
                          children: [
                            // Base color
                            Container(
                              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            ),

                            // Map tiles
                            ...tileWidgets,

                            // Custom painter for route & pins
                            Positioned.fill(
                              child: AnimatedBuilder(
                                animation: _animController,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: _RiderMapPainter(
                                      progress: _animController.value,
                                      z: z,
                                      globalTileX: globalTileX,
                                      globalTileY: globalTileY,
                                      panOffset: _panOffset,
                                      riderLat: riderLat,
                                      riderLng: riderLng,
                                      riderHeading: heading,
                                      riderSpeed: speedKmh,
                                      destLat: widget.destinationLat,
                                      destLng: widget.destinationLng,
                                      customerName: widget.customerName,
                                      isDark: isDark,
                                    ),
                                  );
                                },
                              ),
                            ),

                            // Floating Distance & ETA badge top-left
                            Positioned(
                              top: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: (isDark ? const Color(0xFF0F172A) : Colors.white)
                                      .withValues(alpha: 0.95),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isDark
                                        ? const Color(0xFF334155)
                                        : const Color(0xFFCBD5E1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.near_me_rounded,
                                        size: 13, color: Color(0xFF0066FF)),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${distKm.toStringAsFixed(1)} km away • ~$etaMins min ETA',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // Floating Map Controls (Zoom In, Zoom Out, Buyer Pinpoint, Recenter on Bike)
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  _buildMapButton(
                                    icon: Icons.add_rounded,
                                    tooltip: 'Zoom In',
                                    onTap: () {
                                      if (_tileZoom < 18) {
                                        setState(() {
                                          _tileZoom++;
                                          _customZoomSet = true;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  _buildMapButton(
                                    icon: Icons.remove_rounded,
                                    tooltip: 'Zoom Out',
                                    onTap: () {
                                      if (_tileZoom > 10) {
                                        setState(() {
                                          _tileZoom--;
                                          _customZoomSet = true;
                                        });
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  _buildMapButton(
                                    icon: Icons.place_rounded,
                                    tooltip: 'Recenter on Buyer Pinpoint',
                                    color: const Color(0xFFEF4444),
                                    onTap: () {
                                      final destTileX = (widget.destinationLng + 180.0) / 360.0 * (1 << z);
                                      final destLatRad = widget.destinationLat * math.pi / 180.0;
                                      final destTileY = (1.0 - (math.log(math.tan(destLatRad) + (1.0 / math.cos(destLatRad))) / math.pi)) / 2.0 * (1 << z);
                                      final deltaX = (destTileX - globalTileX) * 256.0;
                                      final deltaY = (destTileY - globalTileY) * 256.0;
                                      setState(() {
                                        _panOffset = Offset(-deltaX, -deltaY);
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 6),
                                  _buildMapButton(
                                    icon: Icons.my_location_rounded,
                                    tooltip: 'Recenter on Bike',
                                    color: const Color(0xFF0066FF),
                                    onTap: () {
                                      setState(() {
                                        _panOffset = Offset.zero;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              // 3. Bottom Action Bar: Turn-by-Turn Navigation Launch Button
              Container(
                padding: const EdgeInsets.all(12),
                color: const Color(0xFF0B192C),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _launchTurnByTurnNavigation,
                        icon: const Icon(Icons.navigation_rounded, size: 16),
                        label: const Text(
                          'Open Live Turn-by-Turn in Google Maps',
                          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0066FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
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
    );
  }

  Widget _buildMapButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    Color? color,
  }) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      elevation: 3,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          child: Icon(icon, size: 18, color: color ?? const Color(0xFF0F172A)),
        ),
      ),
    );
  }
}

/// Custom painter for rendering vehicle pin with heading, route glow, and destination pin
class _RiderMapPainter extends CustomPainter {
  final double progress;
  final int z;
  final double globalTileX;
  final double globalTileY;
  final Offset panOffset;
  final double riderLat;
  final double riderLng;
  final double riderHeading;
  final double riderSpeed;
  final double destLat;
  final double destLng;
  final String customerName;
  final bool isDark;

  _RiderMapPainter({
    required this.progress,
    required this.z,
    required this.globalTileX,
    required this.globalTileY,
    required this.panOffset,
    required this.riderLat,
    required this.riderLng,
    required this.riderHeading,
    required this.riderSpeed,
    required this.destLat,
    required this.destLng,
    required this.customerName,
    required this.isDark,
  });

  Offset _toScreen(Size size, double lat, double lng) {
    final double gx = (lng + 180.0) / 360.0 * (1 << z);
    final double r = lat * math.pi / 180.0;
    final double gy =
        (1.0 - (math.log(math.tan(r) + (1.0 / math.cos(r))) / math.pi)) / 2.0 * (1 << z);

    final double px = (size.width / 2) + ((gx - globalTileX) * 256.0) + panOffset.dx;
    final double py = (size.height / 2) + ((gy - globalTileY) * 256.0) + panOffset.dy;
    return Offset(px, py);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final riderPos = _toScreen(size, riderLat, riderLng);
    final destPos = _toScreen(size, destLat, destLng);

    // 1. Draw Connecting Route Line
    final routePath = Path();
    routePath.moveTo(riderPos.dx, riderPos.dy);
    final midX = (riderPos.dx + destPos.dx) / 2 + 12;
    final midY = (riderPos.dy + destPos.dy) / 2 - 12;
    routePath.quadraticBezierTo(midX, midY, destPos.dx, destPos.dy);

    // Outer Route Glow
    final glowPaint = Paint()
      ..color = const Color(0xFF0066FF).withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 9;
    canvas.drawPath(routePath, glowPaint);

    // Core Route
    final coreRoutePaint = Paint()
      ..color = const Color(0xFF00C4FF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawPath(routePath, coreRoutePaint);

    // Moving neon pulses along route
    for (double p = 0.0; p < 1.0; p += 0.25) {
      final t = (progress + p) % 1.0;
      final px = math.pow(1 - t, 2) * riderPos.dx +
          2 * (1 - t) * t * midX +
          math.pow(t, 2) * destPos.dx;
      final py = math.pow(1 - t, 2) * riderPos.dy +
          2 * (1 - t) * t * midY +
          math.pow(t, 2) * destPos.dy;

      final pulsePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(px, py), 3.0, pulsePaint);
    }

    // 2. Draw Destination Pin
    _drawDestinationPin(canvas, destPos);

    // 3. Draw Rider Marker with Heading & Pulse
    _drawRiderMarker(canvas, riderPos);
  }

  void _drawDestinationPin(Canvas canvas, Offset pos) {
    // Ground Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pos.dx, pos.dy + 2), width: 18, height: 8),
      shadowPaint,
    );

    // Pin base
    final pinPaint = Paint()..color = const Color(0xFFEF4444);
    canvas.drawCircle(pos, 11, pinPaint);

    // Inner White Ring
    final whiteRing = Paint()..color = Colors.white;
    canvas.drawCircle(pos, 5, whiteRing);

    // Pin Center Dot
    final redDot = Paint()..color = const Color(0xFFDC2626);
    canvas.drawCircle(pos, 2.5, redDot);

    // Pinpoint Callout Pill
    final label = customerName.isNotEmpty ? customerName : 'Buyer Pinpoint';
    final textPainter = TextPainter(
      text: TextSpan(
        text: '📍 $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final pillWidth = textPainter.width + 14;
    const pillHeight = 20.0;
    final pillRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(pos.dx, pos.dy - 22),
        width: pillWidth,
        height: pillHeight,
      ),
      const Radius.circular(6),
    );

    final bgPaint = Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.92);
    canvas.drawRRect(pillRect, bgPaint);

    final borderPill = Paint()
      ..color = const Color(0xFFEF4444)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(pillRect, borderPill);

    textPainter.paint(
      canvas,
      Offset(pos.dx - (textPainter.width / 2), pos.dy - 22 - (textPainter.height / 2)),
    );
  }

  void _drawRiderMarker(Canvas canvas, Offset pos) {
    // Pulse animation ring
    final pulseRadius = 14.0 + (progress * 14.0);
    final pulseAlpha = (1.0 - progress).clamp(0.0, 1.0) * 0.45;
    final pulsePaint = Paint()
      ..color = const Color(0xFF00C4FF).withValues(alpha: pulseAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(pos, pulseRadius, pulsePaint);

    // Accuracy Circle
    final accPaint = Paint()
      ..color = const Color(0xFF0066FF).withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 22, accPaint);

    // Main Rider Badge
    final badgePaint = Paint()
      ..color = const Color(0xFF0066FF)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(pos, 15, badgePaint);

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(pos, 15, borderPaint);

    // Vehicle Heading Pointer Arrow
    final rad = (riderHeading - 90) * math.pi / 180.0;
    final tipX = pos.dx + math.cos(rad) * 19;
    final tipY = pos.dy + math.sin(rad) * 19;
    final leftX = pos.dx + math.cos(rad + 2.5) * 11;
    final leftY = pos.dy + math.sin(rad + 2.5) * 11;
    final rightX = pos.dx + math.cos(rad - 2.5) * 11;
    final rightY = pos.dy + math.sin(rad - 2.5) * 11;

    final arrowPath = Path()
      ..moveTo(tipX, tipY)
      ..lineTo(leftX, leftY)
      ..lineTo(pos.dx, pos.dy)
      ..lineTo(rightX, rightY)
      ..close();

    final arrowPaint = Paint()
      ..color = const Color(0xFF00C4FF)
      ..style = PaintingStyle.fill;
    canvas.drawPath(arrowPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant _RiderMapPainter oldDelegate) => true;
}
