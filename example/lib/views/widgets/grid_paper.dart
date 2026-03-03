import 'package:flutter/material.dart';

class GridPaperPainter extends CustomPainter {
  const GridPaperPainter({required this.color, required this.interval});

  final Color color;
  final double interval;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = 0; x <= size.width; x += interval) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += interval) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridPaperPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.interval != interval;
  }
}
