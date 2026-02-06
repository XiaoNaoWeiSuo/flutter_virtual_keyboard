import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/controls/virtual_split_mouse.dart';
import '../../models/input_event.dart';
import '../shared/control_utils.dart';
import '../../models/style/control_style.dart';

class VirtualSplitMouseWidget extends StatefulWidget {
  const VirtualSplitMouseWidget({
    super.key,
    required this.control,
    required this.onInputEvent,
  });

  final VirtualSplitMouse control;
  final void Function(InputEvent) onInputEvent;

  @override
  State<VirtualSplitMouseWidget> createState() =>
      _VirtualSplitMouseWidgetState();
}

class _VirtualSplitMouseWidgetState extends State<VirtualSplitMouseWidget> {
  bool _isLeftPressed = false;
  bool _isRightPressed = false;

  void _updateState(Offset localPosition, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Determine side based on localPosition relative to center
    final isLeft = localPosition.dx < center.dx;

    if (isLeft) {
      if (!_isLeftPressed) {
        setState(() => _isLeftPressed = true);
        _sendEvent('left', true);
      }
      if (_isRightPressed) {
        setState(() => _isRightPressed = false);
        _sendEvent('right', false);
      }
    } else {
      if (!_isRightPressed) {
        setState(() => _isRightPressed = true);
        _sendEvent('right', true);
      }
      if (_isLeftPressed) {
        setState(() => _isLeftPressed = false);
        _sendEvent('left', false);
      }
    }
  }

  void _handleUp() {
    if (_isLeftPressed) {
      setState(() => _isLeftPressed = false);
      _sendEvent('left', false);
    }
    if (_isRightPressed) {
      setState(() => _isRightPressed = false);
      _sendEvent('right', false);
    }
  }

  void _sendEvent(String button, bool isDown) {
    triggerFeedback(widget.control.feedback, isDown);
    widget.onInputEvent(MouseButtonInputEvent(button: button, isDown: isDown));
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final size = Size(constraints.maxWidth, constraints.maxHeight);
      return GestureDetector(
        onPanStart: (details) => _updateState(details.localPosition, size),
        onPanUpdate: (details) => _updateState(details.localPosition, size),
        onPanEnd: (_) => _handleUp(),
        onPanCancel: _handleUp,
        onTapDown: (details) => _updateState(details.localPosition, size),
        onTapUp: (_) => _handleUp(),
        onTapCancel: _handleUp,
        child: CustomPaint(
          painter: _SplitMousePainter(
            isLeftPressed: _isLeftPressed,
            isRightPressed: _isRightPressed,
            style: widget.control.style,
          ),
          size: size,
        ),
      );
    });
  }
}

class _SplitMousePainter extends CustomPainter {
  _SplitMousePainter({
    required this.isLeftPressed,
    required this.isRightPressed,
    this.style,
  });

  final bool isLeftPressed;
  final bool isRightPressed;
  final ControlStyle? style;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;

    final paint = Paint()..style = PaintingStyle.fill;

    // Colors
    final baseColor = style?.color ?? Colors.black54;
    final pressedColor = style?.pressedColor ?? Colors.blueAccent;
    final borderColor = style?.borderColor ?? Colors.black26;
    final borderWidth = style?.borderWidth ?? 2.0;

    // Draw Left Half
    paint.color = isLeftPressed ? pressedColor : baseColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi / 2, // Start at bottom (90 deg)
      math.pi, // Sweep 180 deg
      true, // Use center
      paint,
    );

    // Draw Right Half
    paint.color = isRightPressed ? pressedColor : baseColor;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // Start at top (-90 deg)
      math.pi, // Sweep 180 deg
      true,
      paint,
    );

    // Draw Separator Line (Vertical) and Border
    if (borderWidth > 0) {
      final linePaint = Paint()
        ..color = borderColor
        ..strokeWidth = borderWidth
        ..style = PaintingStyle.stroke;

      // Draw Circle Border
      canvas.drawCircle(center, radius, linePaint);

      // Draw Vertical Split
      canvas.drawLine(
        Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius),
        linePaint,
      );
    }

    // Draw Labels
    _drawLabel(canvas, center, radius, true);
    _drawLabel(canvas, center, radius, false);
  }

  void _drawLabel(Canvas canvas, Offset center, double radius, bool isLeft) {
    final offsetX = isLeft ? -radius * 0.5 : radius * 0.5;
    final pos = center + Offset(offsetX, 0);

    final textSpan = TextSpan(
      text: isLeft ? 'L' : 'R',
      style: TextStyle(
        color: Colors.white,
        fontSize: radius * 0.5,
        fontWeight: FontWeight.w900,
        shadows: [
          const Shadow(
            blurRadius: 2.0,
            color: Colors.black45,
            offset: Offset(1.0, 1.0),
          ),
        ],
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
        canvas, pos - Offset(textPainter.width / 2, textPainter.height / 2));
  }

  @override
  bool shouldRepaint(covariant _SplitMousePainter oldDelegate) {
    return oldDelegate.isLeftPressed != isLeftPressed ||
        oldDelegate.isRightPressed != isRightPressed ||
        oldDelegate.style != style;
  }
}
