import 'package:flutter/material.dart';

/// Google "G" logo widget using CustomPainter
/// This creates the official Google logo with correct colors
class GoogleLogo extends StatelessWidget {
  final double size;

  const GoogleLogo({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double s = size.width;

    // Google logo colors
    const blue = Color(0xFF4285F4);
    const red = Color(0xFFEA4335);
    const yellow = Color(0xFFFBBC05);
    const green = Color(0xFF34A853);

    final paint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    // Scale factor
    final scale = s / 24;

    // Draw the Google "G" logo
    // Blue arc (right side)
    paint.color = blue;
    final bluePath = Path()
      ..moveTo(12 * scale, 9.5 * scale)
      ..lineTo(23 * scale, 9.5 * scale)
      ..cubicTo(23.3 * scale, 10.3 * scale, 23.5 * scale, 11.1 * scale, 23.5 * scale, 12 * scale)
      ..cubicTo(23.5 * scale, 18.6 * scale, 18.6 * scale, 24 * scale, 12 * scale, 24 * scale)
      ..cubicTo(5.4 * scale, 24 * scale, 0, 18.6 * scale, 0, 12 * scale)
      ..cubicTo(0, 5.4 * scale, 5.4 * scale, 0, 12 * scale, 0)
      ..cubicTo(15.1 * scale, 0, 17.9 * scale, 1.2 * scale, 20.1 * scale, 3.2 * scale)
      ..lineTo(17 * scale, 6.3 * scale)
      ..cubicTo(15.5 * scale, 4.9 * scale, 13.9 * scale, 4 * scale, 12 * scale, 4 * scale)
      ..cubicTo(7.6 * scale, 4 * scale, 4 * scale, 7.6 * scale, 4 * scale, 12 * scale)
      ..cubicTo(4 * scale, 16.4 * scale, 7.6 * scale, 20 * scale, 12 * scale, 20 * scale)
      ..cubicTo(16.1 * scale, 20 * scale, 19 * scale, 17.5 * scale, 19.8 * scale, 14 * scale)
      ..lineTo(12 * scale, 14 * scale)
      ..lineTo(12 * scale, 9.5 * scale)
      ..close();
    canvas.drawPath(bluePath, paint);

    // Green arc (bottom right)
    paint.color = green;
    final greenPath = Path()
      ..moveTo(12 * scale, 24 * scale)
      ..cubicTo(15.2 * scale, 24 * scale, 18 * scale, 22.8 * scale, 20 * scale, 20.8 * scale)
      ..lineTo(16.8 * scale, 17.8 * scale)
      ..cubicTo(15.5 * scale, 19 * scale, 13.9 * scale, 20 * scale, 12 * scale, 20 * scale)
      ..cubicTo(9.1 * scale, 20 * scale, 6.6 * scale, 17.9 * scale, 5.5 * scale, 15 * scale)
      ..lineTo(1.8 * scale, 18 * scale)
      ..cubicTo(4 * scale, 21.7 * scale, 7.7 * scale, 24 * scale, 12 * scale, 24 * scale)
      ..close();
    canvas.drawPath(greenPath, paint);

    // Yellow arc (bottom left)
    paint.color = yellow;
    final yellowPath = Path()
      ..moveTo(5.5 * scale, 15 * scale)
      ..cubicTo(5.2 * scale, 14.1 * scale, 5 * scale, 13.1 * scale, 5 * scale, 12 * scale)
      ..cubicTo(5 * scale, 10.9 * scale, 5.2 * scale, 9.9 * scale, 5.5 * scale, 9 * scale)
      ..lineTo(1.8 * scale, 6 * scale)
      ..cubicTo(0.7 * scale, 7.9 * scale, 0, 10 * scale, 0, 12 * scale)
      ..cubicTo(0, 14 * scale, 0.7 * scale, 16.1 * scale, 1.8 * scale, 18 * scale)
      ..lineTo(5.5 * scale, 15 * scale)
      ..close();
    canvas.drawPath(yellowPath, paint);

    // Red arc (top left)
    paint.color = red;
    final redPath = Path()
      ..moveTo(12 * scale, 4 * scale)
      ..cubicTo(13.9 * scale, 4 * scale, 15.6 * scale, 4.7 * scale, 17 * scale, 6.3 * scale)
      ..lineTo(20.1 * scale, 3.2 * scale)
      ..cubicTo(17.9 * scale, 1.2 * scale, 15.1 * scale, 0, 12 * scale, 0)
      ..cubicTo(7.7 * scale, 0, 4 * scale, 2.3 * scale, 1.8 * scale, 6 * scale)
      ..lineTo(5.5 * scale, 9 * scale)
      ..cubicTo(6.6 * scale, 6.1 * scale, 9.1 * scale, 4 * scale, 12 * scale, 4 * scale)
      ..close();
    canvas.drawPath(redPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
