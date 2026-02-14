import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../models/controls/virtual_dpad.dart';
import '../../models/binding/binding.dart';
import '../../models/input_event.dart';
import '../../models/style/control_style.dart';
import '../shared/control_utils.dart';

/// Widget that renders a virtual D-Pad with a unified cross style.
class VirtualDpadWidget extends StatefulWidget {
  /// Creates a virtual D-Pad widget.
  const VirtualDpadWidget({
    super.key,
    required this.control,
    required this.onInputEvent,
  });

  /// The D-Pad control model.
  final VirtualDpad control;

  /// Callback for input events.
  final void Function(InputEvent) onInputEvent;

  @override
  State<VirtualDpadWidget> createState() => _VirtualDpadWidgetState();
}

class _VirtualDpadWidgetState extends State<VirtualDpadWidget> {
  // Track currently pressed directions
  final Set<DpadDirection> _pressedDirections = {};

  ui.FragmentProgram? _program;

  @override
  void initState() {
    super.initState();
    _loadShader();
  }

  Future<void> _loadShader() async {
    try {
      // When running in an app (like example/), package assets need the package prefix.
      const assetKey = 'packages/virtual_gamepad_pro/lib/shaders/d_pad.frag';
      final program = await ui.FragmentProgram.fromAsset(assetKey);
      if (mounted) {
        setState(() {
          _program = program;
        });
      }
    } catch (e) {
      debugPrint('Shader load failed: $e');
      // Fallback: try without package prefix (for local dev scenarios if needed)
      try {
        final program =
            await ui.FragmentProgram.fromAsset('lib/shaders/d_pad.frag');
        if (mounted) {
          setState(() {
            _program = program;
          });
        }
      } catch (e2) {
        debugPrint('Shader fallback load failed: $e2');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.control.style;
    final backgroundImage =
        style?.backgroundImage ?? getImageProvider(style?.backgroundImagePath);

    // Calculate press direction vector for shader
    Offset pressDir = Offset.zero;
    if (_pressedDirections.isNotEmpty) {
      double dx = 0;
      double dy = 0;
      if (_pressedDirections.contains(DpadDirection.up)) dy -= 1;
      if (_pressedDirections.contains(DpadDirection.down)) dy += 1;
      if (_pressedDirections.contains(DpadDirection.left)) dx -= 1;
      if (_pressedDirections.contains(DpadDirection.right)) dx += 1;

      if (dx != 0 || dy != 0) {
        final dist = math.sqrt(dx * dx + dy * dy);
        pressDir = Offset(dx / dist, dy / dist);
      }
    }

    return Listener(
      onPointerDown: (e) => _processInput(e.localPosition),
      onPointerMove: (e) => _processInput(e.localPosition),
      onPointerUp: (_) => _reset(),
      onPointerCancel: (_) => _reset(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (backgroundImage != null)
            DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: backgroundImage,
                  fit: style?.imageFit ?? BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                ),
              ),
            ),
          CustomPaint(
            painter: _DpadPainter(
              style: style,
              pressedDirections: _pressedDirections,
              program: _program,
              pressDir: pressDir,
              enable3D: widget.control.enable3D,
            ),
            size: Size.infinite,
          ),
        ],
      ),
    );
  }

  void _reset() {
    if (_pressedDirections.isNotEmpty) {
      _updateEvents({});
    }
  }

  void _processInput(Offset localPosition) {
    final size = context.size;
    if (size == null) return;

    final center = Offset(size.width / 2, size.height / 2);
    final delta = localPosition - center;
    final distance = delta.distance;
    final maxRadius = size.width / 2;

    // Deadzone (center) - 15%
    if (distance < maxRadius * 0.15) {
      if (_pressedDirections.isNotEmpty) {
        _updateEvents({});
      }
      return;
    }

    // Determine direction based on angle and position
    // We map sectors to directions.
    // 33% width for the arms.
    // Actually, simple angle check is often enough for 8-way.
    // Let's use specific zones for the "Cross" shape feel.

    final newDirections = <DpadDirection>{};

    // Check against the cross geometry
    // Horizontal band: y within center 1/3
    // Vertical band: x within center 1/3

    // Refined Logic:
    // If inside the central cross area, trigger based on position relative to center.
    // If diagonal (corners), trigger both?

    // Simple Sector Logic (Classic 8-way D-pad)
    // Up: -112.5 to -67.5 (for 4-way) or wider for 8-way.
    // Let's strictly allow diagonals if the touch is clearly in the quadrant.

    // Angle: 0 is Right, pi/2 is Down, -pi/2 is Up, pi is Left.
    final angle = delta.direction; // -pi to pi
    final angleDeg = angle * 180 / math.pi;

    // Up: -135 to -45
    // Right: -45 to 45
    // Down: 45 to 135
    // Left: 135 to 180 OR -180 to -135

    // However, to simulate "Cross" feel, we might want to prioritize axes.
    // But standard gamepad D-pads allow rolling.

    if (angleDeg >= -150 && angleDeg <= -30) {
      newDirections.add(DpadDirection.up);
    }
    if (angleDeg >= -60 && angleDeg <= 60) {
      newDirections.add(DpadDirection.right);
    }
    if (angleDeg >= 30 && angleDeg <= 150) {
      newDirections.add(DpadDirection.down);
    }
    if (angleDeg >= 120 || angleDeg <= -120) {
      newDirections.add(DpadDirection.left);
    }

    // Filter impossible combinations (Up+Down, Left+Right) - Physics prevents this
    if (newDirections.contains(DpadDirection.up) &&
        newDirections.contains(DpadDirection.down)) {
      // Prefer the one with stronger magnitude? Or just clear both?
      // Usually impossible on physical, but here possible. Remove both or keep last?
      // Let's just keep vertical component based on y sign
      if (delta.dy < 0) {
        newDirections.remove(DpadDirection.down);
      } else {
        newDirections.remove(DpadDirection.up);
      }
    }
    if (newDirections.contains(DpadDirection.left) &&
        newDirections.contains(DpadDirection.right)) {
      if (delta.dx < 0) {
        newDirections.remove(DpadDirection.right);
      } else {
        newDirections.remove(DpadDirection.left);
      }
    }

    _updateEvents(newDirections);
  }

  void _updateEvents(Set<DpadDirection> newDirections) {
    // Diff calculation
    final added = newDirections.difference(_pressedDirections);
    final removed = _pressedDirections.difference(newDirections);

    if (added.isEmpty && removed.isEmpty) return;

    setState(() {
      _pressedDirections.clear();
      _pressedDirections.addAll(newDirections);
    });

    // Trigger Haptics
    if (added.isNotEmpty) {
      triggerFeedback(widget.control.feedback, true, type: 'selection');
    }

    // Send Events
    for (final dir in removed) {
      _sendEvent(dir, false);
    }
    for (final dir in added) {
      _sendEvent(dir, true);
    }
  }

  void _sendEvent(DpadDirection direction, bool isDown) {
    final binding = widget.control.directions[direction];
    if (binding == null) return;
    if (binding is KeyboardBinding) {
      final key = binding.key.normalized();
      if (key.code.trim().isEmpty) return;
      widget.onInputEvent(isDown
          ? KeyboardInputEvent.down(key)
          : KeyboardInputEvent.up(key));
      return;
    }
    if (binding is GamepadButtonBinding) {
      widget.onInputEvent(
        GamepadButtonInputEvent(button: binding.button, isDown: isDown),
      );
      return;
    }
    final raw = binding.code.trim();
    if (raw.isEmpty) return;
    final parsed = GamepadButtonId.parse(raw);
    widget.onInputEvent(GamepadButtonInputEvent(button: parsed, isDown: isDown));
  }
}

class _DpadPainter extends CustomPainter {
  final ControlStyle? style;
  final Set<DpadDirection> pressedDirections;
  final ui.FragmentProgram? program;
  final Offset pressDir;
  final bool enable3D;

  _DpadPainter({
    this.style,
    required this.pressedDirections,
    this.program,
    this.pressDir = Offset.zero,
    this.enable3D = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (program != null && enable3D) {
      _paintShader(canvas, size);
      // Shader already includes 3D arrows/indentations
    } else {
      _paintFallback(canvas, size);
    }
  }

  void _paintShader(Canvas canvas, Size size) {
    final shader = program!.fragmentShader();
    shader.setFloat(0, size.width);
    shader.setFloat(1, size.height);
    shader.setFloat(2, pressDir.dx);
    shader.setFloat(3, pressDir.dy);
    // u_press: 1.0 if any direction is pressed, else 0.0
    shader.setFloat(4, pressedDirections.isNotEmpty ? 1.0 : 0.0);

    final paint = Paint()..shader = shader;
    canvas.drawRect(Offset.zero & size, paint);
  }

  void _paintFallback(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final w = size.width;
    final h = size.height;

    // Colors
    final baseColor = style?.color ?? Colors.grey.shade800;
    final pressedColor = style?.pressedColor ?? Colors.blueAccent;
    final borderColor = style?.borderColor ?? Colors.black26;
    final borderWidth = style?.borderWidth ?? 1.0;

    // Geometry: Union of two rounded rects
    final armThickness = w * 0.34;
    const radius = 6.0;

    final verticalRect =
        Rect.fromCenter(center: center, width: armThickness, height: h);
    final horizontalRect =
        Rect.fromCenter(center: center, width: w, height: armThickness);

    final pathV = Path()
      ..addRRect(
          RRect.fromRectAndRadius(verticalRect, const Radius.circular(radius)));
    final pathH = Path()
      ..addRRect(RRect.fromRectAndRadius(
          horizontalRect, const Radius.circular(radius)));

    final fullCrossPath = Path.combine(PathOperation.union, pathV, pathH);

    // Split into 4 buttons using X-shaped gap
    final gap = w * 0.02; // Gap size
    final big = w * 2.0; // Large distance for mask

    // Helper to create directional button path
    Path createButtonPath(double angle, Offset shiftDir) {
      // Create a wedge mask for the direction
      // The wedge starts from center displaced by gap, and widens out.
      // We use a large triangle rotated to the correct angle.

      final mask = Path();
      // Shift center to create gap.
      // We move the tip of the wedge away from center.
      final tip = center + shiftDir * gap;

      // Add rounded corner at the tip (center of cross)
      // Instead of sharp moveTo(tip), we use a small arc or quadratic bezier
      // But since we are doing intersection, maybe just drawing a rounded triangle is easier?
      // Let's manually draw a rounded V shape for the mask.

      // Actually, the sharp corners come from the intersection of the Rounded Rects (fullCrossPath)
      // and our straight-line wedge mask.
      // The outer corners are already rounded by fullCrossPath.
      // The INNER corner (at the center) is what needs smoothing.
      // Our wedge tip is at 'tip'.

      // Let's make the mask slightly rounded at the tip.
      final tipRadius = w * 0.015;

      // Calculate points for rounded tip
      // We need normal vectors to the wedge sides.
      // Wedge sides are at +45 and -45 degrees relative to 'angle'.

      // Let's use a simpler approach:
      // Draw the wedge with a rounded cap at the tip.

      mask.moveTo(tip.dx, tip.dy);
      // We will fix the sharpness by using a small circle at center?
      // No, the user wants "smooth cut edges", likely meaning the inner corners of the buttons.

      // Let's refine the mask geometry.

      // Right-pointing wedge template
      // Tip at (0,0).
      // P1 (big, -big), P2 (big, big).
      // We want to round the tip.
      // Start at (tipRadius, -tipRadius) -> Arc to (tipRadius, tipRadius)?
      // Or just move the tip back a bit and add a radius?

      // Let's draw the wedge relative to (0,0) then rotate & translate.
      final wedgePath = Path();

      // We want a wedge opening to the Right (0 deg)
      // Top edge: y = -x (for 45 deg) ? No, P1 is (big, -big) -> y = -x. Angle -45.
      // Bottom edge: P2 is (big, big) -> y = x. Angle +45.

      // Rounded tip:
      // We want the tip to be rounded with radius `tipRadius`.
      // The circle is tangent to y=-x and y=x.
      // Center of such circle is at (d, 0).
      // Distance to line y=x is |d|/sqrt(2) = r. -> d = r * sqrt(2).
      final d = tipRadius * math.sqrt(2);

      wedgePath.moveTo(big, -big);
      // Line to tangent point on top edge
      // Tangent point: Center (d, 0) + Radius vector rotated -45 deg + 90 deg = +45 deg?
      // Normal to y=-x (slope -1) is slope 1.
      // Wait, simpler:
      // Top edge y = -x. Normal is (-1, -1) normalized? (-0.707, -0.707).
      // Circle center (d, 0).
      // Point on circle: (d, 0) + r * (cos(-135), sin(-135)) ?
      // Tangent point T1: x = d - r/sqrt(2), y = -r/sqrt(2).
      // Since d = r*sqrt(2), x = r*sqrt(2) - r/sqrt(2) = r/sqrt(2).
      // y = -r/sqrt(2).
      // So T1 is (r/sqrt(2), -r/sqrt(2)).
      // T2 is (r/sqrt(2), r/sqrt(2)).

      // Let's draw:
      wedgePath.lineTo(
          d + tipRadius * math.cos(-math.pi * 3 / 4),
          tipRadius *
              math.sin(-math.pi * 3 / 4)); // Close enough approximation?
      // Actually, let's use arcToPoint.
      // Start point on top line: (d + r*cos(-135), r*sin(-135))? No.

      // Let's just use a small quadratic bezier for the tip.
      // Start: (gap + tipRadius, -tipRadius)
      // Control: (gap, 0)
      // End: (gap + tipRadius, tipRadius)
      // This is easier.

      wedgePath.reset();
      wedgePath.moveTo(big, -big);
      wedgePath.lineTo(tipRadius * 2, -tipRadius * 2); // Line to near tip
      wedgePath.quadraticBezierTo(
          0, 0, tipRadius * 2, tipRadius * 2); // Round tip
      wedgePath.lineTo(big, big);
      wedgePath.close();

      // Transform the wedge
      final matrix = Matrix4.identity()
        ..setTranslationRaw(tip.dx, tip.dy, 0)
        ..rotateZ(angle);

      final transformedWedge = wedgePath.transform(matrix.storage);

      return Path.combine(
          PathOperation.intersect, fullCrossPath, transformedWedge);
    }

    void drawButton(DpadDirection dir, double angle) {
      // Shift vector: same direction as angle
      final shift = Offset(math.cos(angle), math.sin(angle));
      var path = createButtonPath(angle, shift);

      final isPressed = pressedDirections.contains(dir);

      // Animation: Scale if pressed
      if (isPressed) {
        final bounds = path.getBounds();
        final btnCenter = bounds.center;
        final matrix = Matrix4.identity()
          ..translateByDouble(btnCenter.dx, btnCenter.dy, 0, 1)
          ..scaleByDouble(0.92, 0.92, 1.0, 1)
          ..translateByDouble(-btnCenter.dx, -btnCenter.dy, 0, 1);
        path = path.transform(matrix.storage);
      }

      // Draw Shadow
      if (style?.shadows != null && !isPressed) {
        for (final shadow in style!.shadows) {
          canvas.drawShadow(path, shadow.color, shadow.blurRadius, true);
        }
      }

      // Draw Gradient Fill
      // Gradient from Tip (center) to End (outer)
      // We can use a RadialGradient centered at 'center' or LinearGradient along 'angle'.
      // Linear is better for directional buttons.
      // Start point: near center (tip). End point: outer edge.
      // We can approximate start/end based on angle and size.
      final gradStart = center + shift * (gap * 2);
      final gradEnd = center + shift * (w * 0.5);

      final fillPaint = Paint()
        ..shader = ui.Gradient.linear(
          gradStart,
          gradEnd,
          [
            isPressed
                ? pressedColor
                : baseColor.withValues(
                    alpha: 0.6), // Near center (transparent/lighter)
            isPressed
                ? pressedColor.withValues(alpha: 0.8)
                : baseColor, // Outer edge (solid)
          ],
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(path, fillPaint);

      // Draw Border
      if (borderWidth > 0) {
        final borderPaint = Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = borderWidth;
        canvas.drawPath(path, borderPaint);
      }

      // Draw Hollow Triangle Icon
      final iconDist = w * 0.35;
      final iconCenter = center + shift * iconDist;
      final iconSize = w * 0.05; // Half size

      final iconPath = Path();
      // Triangle pointing in 'angle' direction
      // Tip at angle. Base perpendicular.
      // We want hollow, so we stroke it.

      final tTip = iconCenter + shift * iconSize; // Tip of arrow
      // Base center
      final tBase = iconCenter - shift * iconSize;
      // Perpendicular vector
      final perp = Offset(-shift.dy, shift.dx);
      final tLeft = tBase + perp * iconSize;
      final tRight = tBase - perp * iconSize;

      iconPath.moveTo(tTip.dx, tTip.dy);
      iconPath.lineTo(tLeft.dx, tLeft.dy);
      iconPath.lineTo(tRight.dx, tRight.dy);
      iconPath.close();

      final iconPaint = Paint()
        ..color = Colors.white.withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeJoin = StrokeJoin.round;

      canvas.drawPath(iconPath, iconPaint);
    }

    drawButton(DpadDirection.up, -math.pi / 2);
    drawButton(DpadDirection.down, math.pi / 2);
    drawButton(DpadDirection.left, math.pi);
    drawButton(DpadDirection.right, 0);
  }

  @override
  bool shouldRepaint(covariant _DpadPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.pressedDirections.length != pressedDirections.length ||
        !_setsEqual(oldDelegate.pressedDirections, pressedDirections) ||
        oldDelegate.program != program ||
        oldDelegate.pressDir != pressDir ||
        oldDelegate.enable3D != enable3D;
  }

  bool _setsEqual(Set<DpadDirection> a, Set<DpadDirection> b) {
    if (a.length != b.length) return false;
    return a.containsAll(b);
  }
}
