import 'package:flutter/material.dart';

/// Official Google 'G' Logo rendered with exact official vector geometry and brand colors.
///
/// Colors:
/// - Blue:   #4285F4
/// - Green:  #34A853
/// - Yellow: #FBBC05
/// - Red:    #EA4335
///
/// Conforms precisely to Google Brand Guidelines and SVG coordinates (viewBox 0 0 48 48).
class GoogleLogoIcon extends StatelessWidget {
  final double size;

  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        size: Size(size, size),
        painter: const _OfficialGoogleLogoPainter(),
      ),
    );
  }
}

class _OfficialGoogleLogoPainter extends CustomPainter {
  const _OfficialGoogleLogoPainter();

  // Official Google brand color definitions
  static const Color googleBlue = Color(0xFF4285F4);
  static const Color googleGreen = Color(0xFF34A853);
  static const Color googleYellow = Color(0xFFFBBC05);
  static const Color googleRed = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    // Coordinate space is based on the canonical 48x48 Google 'G' vector specification
    final double scale = size.width / 48.0;

    canvas.save();
    canvas.scale(scale, scale);

    // 1. Blue Segment (#4285F4): Right arc and central horizontal crossbar
    final Paint bluePaint = Paint()
      ..color = googleBlue
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path bluePath = Path()
      ..moveTo(46.98, 24.55)
      ..cubicTo(46.98, 22.98, 46.83, 21.46, 46.60, 20.00)
      ..lineTo(24.00, 20.00)
      ..lineTo(24.00, 29.02)
      ..lineTo(36.94, 29.02)
      ..cubicTo(36.36, 31.98, 34.68, 34.50, 32.16, 36.20)
      ..lineTo(39.89, 42.20)
      ..cubicTo(44.40, 38.02, 46.98, 31.84, 46.98, 24.55)
      ..close();
    canvas.drawPath(bluePath, bluePaint);

    // 2. Green Segment (#34A853): Bottom curved arc
    final Paint greenPaint = Paint()
      ..color = googleGreen
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path greenPath = Path()
      ..moveTo(24.00, 48.00)
      ..cubicTo(30.48, 48.00, 35.93, 45.87, 39.89, 42.19)
      ..lineTo(32.16, 36.19)
      ..cubicTo(30.01, 37.64, 27.24, 38.49, 24.00, 38.49)
      ..cubicTo(17.74, 38.49, 12.43, 34.27, 10.53, 28.58)
      ..lineTo(2.55, 34.77)
      ..cubicTo(6.51, 42.62, 14.62, 48.00, 24.00, 48.00)
      ..close();
    canvas.drawPath(greenPath, greenPaint);

    // 3. Yellow Segment (#FBBC05): Left curved arc
    final Paint yellowPaint = Paint()
      ..color = googleYellow
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path yellowPath = Path()
      ..moveTo(10.53, 28.59)
      ..cubicTo(10.05, 27.14, 9.77, 25.60, 9.77, 24.00)
      ..cubicTo(9.77, 22.40, 10.05, 20.86, 10.53, 19.41)
      ..lineTo(2.55, 13.22)
      ..cubicTo(0.92, 16.46, 0.00, 20.12, 0.00, 24.00)
      ..cubicTo(0.00, 27.88, 0.92, 31.54, 2.56, 34.78)
      ..lineTo(10.53, 28.59)
      ..close();
    canvas.drawPath(yellowPath, yellowPaint);

    // 4. Red Segment (#EA4335): Top curved arc
    final Paint redPaint = Paint()
      ..color = googleRed
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final Path redPath = Path()
      ..moveTo(24.00, 9.50)
      ..cubicTo(27.54, 9.50, 30.71, 10.72, 33.21, 13.10)
      ..lineTo(40.06, 6.25)
      ..cubicTo(35.90, 2.38, 30.47, 0.00, 24.00, 0.00)
      ..cubicTo(14.62, 0.00, 6.51, 5.38, 2.56, 13.22)
      ..lineTo(10.54, 19.41)
      ..cubicTo(12.43, 13.72, 17.74, 9.50, 24.00, 9.50)
      ..close();
    canvas.drawPath(redPath, redPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
