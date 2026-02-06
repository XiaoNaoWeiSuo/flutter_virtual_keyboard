import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Renders a gamepad symbol (Xbox letters or PlayStation shapes).
class GamepadSymbol extends StatelessWidget {
  /// Creates a gamepad symbol.
  const GamepadSymbol({
    super.key,
    required this.id,
    required this.label,
    this.size = 24.0,
    this.color,
  });

  final String id;
  final String label;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Normalize input
    final normId = id.toLowerCase();
    final normLabel = label.toLowerCase();

    // Xbox Logic
    if (normLabel == 'a' || normId.endsWith('_a')) {
      return _buildText('A', const Color(0xFF4CAF50)); // Green
    }
    if (normLabel == 'b' || normId.endsWith('_b')) {
      return _buildText('B', const Color(0xFFF44336)); // Red
    }
    if (normLabel == 'y' || normId.endsWith('_y')) {
      return _buildText('Y', const Color(0xFFFFC107)); // Amber
    }
    // X is ambiguous (Xbox X or PS Cross).
    // If ID explicitly says 'cross', treat as PS Cross.
    // If ID says 'x', treat as Xbox X.
    if (normId.contains('cross')) {
      return _buildShape(_ShapeType.cross, const Color(0xFF2196F3)); // Blue
    }
    if (normLabel == 'x' || normId.endsWith('_x')) {
      return _buildText('X', const Color(0xFF2196F3)); // Blue
    }

    // Xbox Shoulder Buttons
    if (normLabel == 'lb' || normId.endsWith('_lb')) {
      return _buildText('LB', Colors.white, scale: 0.45);
    }
    if (normLabel == 'rb' || normId.endsWith('_rb')) {
      return _buildText('RB', Colors.white, scale: 0.45);
    }
    if (normLabel == 'lt' || normId.endsWith('_lt')) {
      return _buildText('LT', Colors.white, scale: 0.45);
    }
    if (normLabel == 'rt' || normId.endsWith('_rt')) {
      return _buildText('RT', Colors.white, scale: 0.45);
    }

    // PlayStation Logic
    if (normId.contains('triangle') || normLabel == 'triangle') {
      return _buildShape(_ShapeType.triangle, const Color(0xFF4CAF50)); // Green
    }
    if (normId.contains('circle') || normLabel == 'circle') {
      return _buildShape(_ShapeType.circle, const Color(0xFFF44336)); // Red
    }
    if (normId.contains('square') || normLabel == 'square') {
      return _buildShape(_ShapeType.square, const Color(0xFFE91E63)); // Pink
    }

    // PlayStation Shoulder Buttons
    if (normLabel == 'l1' || normId.endsWith('_l1')) {
      return _buildText('L1', Colors.white, scale: 0.45);
    }
    if (normLabel == 'r1' || normId.endsWith('_r1')) {
      return _buildText('R1', Colors.white, scale: 0.45);
    }
    if (normLabel == 'l2' || normId.endsWith('_l2')) {
      return _buildText('L2', Colors.white, scale: 0.45);
    }
    if (normLabel == 'r2' || normId.endsWith('_r2')) {
      return _buildText('R2', Colors.white, scale: 0.45);
    }

    // System Buttons
    if (normLabel == 'menu' ||
        normId.endsWith('_menu') ||
        normLabel == 'options') {
      return _buildIcon(Icons.menu, Colors.white);
    }
    if (normLabel == 'view' || normId.endsWith('_view')) {
      return _buildIcon(Icons.filter_none, Colors.white,
          sizeScale: 0.5); // 2 overlapping squares
    }
    if (normLabel == 'share' || normId.endsWith('_share')) {
      return _buildIcon(Icons.share, Colors.white, sizeScale: 0.5);
    }
    if (normLabel == 'home' ||
        normId.endsWith('_home') ||
        normLabel == 'guide' ||
        normLabel == 'ps') {
      // Generic Home Icon
      return _buildIcon(Icons.radio_button_checked, Colors.white);
    }

    // Stick Buttons
    if (normLabel == 'l3' ||
        normId.endsWith('_l3') ||
        normLabel == 'ls' ||
        normId.endsWith('_ls')) {
      return _buildText('LS', Colors.white, scale: 0.45);
    }
    if (normLabel == 'r3' ||
        normId.endsWith('_r3') ||
        normLabel == 'rs' ||
        normId.endsWith('_rs')) {
      return _buildText('RS', Colors.white, scale: 0.45);
    }

    // Fallback: Just Text
    return Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color ?? Colors.white,
          fontSize: size * 0.5,
          fontWeight: FontWeight.bold,
          shadows: const [Shadow(color: Colors.black45, blurRadius: 2)],
        ),
      ),
    );
  }

  Widget _buildText(String text, Color defaultColor, {double scale = 0.6}) {
    return Center(
      child: Text(
        text,
        style: TextStyle(
          color: color ?? defaultColor,
          fontSize: size * scale, // Adjusted to fit within the button
          fontWeight: FontWeight.w900,
          fontFamily: 'Roboto', // Ensure standard look
          height: 1.0, // Tighter line height
          shadows: [
            Shadow(
              color: defaultColor.withValues(alpha: 0.5),
              blurRadius: size * 0.3,
            ),
            Shadow(
              color: Colors.black26,
              offset: Offset(size * 0.04, size * 0.04),
              blurRadius: size * 0.08,
            )
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(IconData icon, Color defaultColor,
      {double sizeScale = 0.6}) {
    return Center(
      child: Icon(
        icon,
        size: size * sizeScale,
        color: color ?? defaultColor,
        shadows: [
          Shadow(
            color: defaultColor.withValues(alpha: 0.5),
            blurRadius: size * 0.3,
          ),
          Shadow(
            color: Colors.black26,
            offset: Offset(size * 0.04, size * 0.04),
            blurRadius: size * 0.08,
          )
        ],
      ),
    );
  }

  Widget _buildShape(_ShapeType type, Color defaultColor) {
    return CustomPaint(
      size: Size(size, size),
      painter: _GamepadShapePainter(
        type: type,
        color: color ?? defaultColor,
      ),
    );
  }
}

enum _ShapeType { triangle, square, circle, cross }

class _GamepadShapePainter extends CustomPainter {
  final _ShapeType type;
  final Color color;

  _GamepadShapePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1 // Thinner stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Add glow
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08;

    final center = Offset(size.width / 2, size.height / 2);
    // Reduced radius further to 0.22
    final radius = size.width * 0.22;

    Path path = Path();

    switch (type) {
      case _ShapeType.circle:
        path.addOval(Rect.fromCircle(center: center, radius: radius));
        break;
      case _ShapeType.square:
        final rect = Rect.fromCenter(
            center: center, width: radius * 1.8, height: radius * 1.8);
        path.addRRect(
            RRect.fromRectAndRadius(rect, Radius.circular(size.width * 0.05)));
        break;
      case _ShapeType.triangle:
        // Equilateral triangle
        final r = radius * 1.1;
        path.moveTo(center.dx, center.dy - r);
        // Bottom right
        path.lineTo(center.dx + r * math.cos(math.pi / 6),
            center.dy + r * math.sin(math.pi / 6));
        // Bottom left
        path.lineTo(center.dx - r * math.cos(math.pi / 6),
            center.dy + r * math.sin(math.pi / 6));
        path.close();
        break;
      case _ShapeType.cross:
        final r = radius * 0.8;
        path.moveTo(center.dx - r, center.dy - r);
        path.lineTo(center.dx + r, center.dy + r);
        path.moveTo(center.dx + r, center.dy - r);
        path.lineTo(center.dx - r, center.dy + r);
        break;
    }

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _GamepadShapePainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.color != color;
  }
}
