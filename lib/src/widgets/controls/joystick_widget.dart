import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/controls/virtual_joystick.dart';
import '../../models/input_event.dart';
import '../shared/control_utils.dart';

/// Widget that renders a virtual joystick.
class VirtualJoystickWidget extends StatefulWidget {
  /// Creates a virtual joystick widget.
  const VirtualJoystickWidget({
    super.key,
    required this.control,
    required this.onInputEvent,
  });

  /// The joystick control model.
  final VirtualJoystick control;

  /// Callback for input events.
  final void Function(InputEvent) onInputEvent;

  @override
  State<VirtualJoystickWidget> createState() => _VirtualJoystickWidgetState();
}

class _VirtualJoystickWidgetState extends State<VirtualJoystickWidget> {
  Offset _stickPosition = Offset.zero;
  Set<String> _activeKeys = {};

  // Interaction State
  bool _wasAtEdge = false;
  bool _wasOverPushed = false;
  bool _isLocked = false;
  Timer? _lockTimer;
  Timer? _overPushTimer;
  double _currentAngle = 0.0;
  double _currentMagnitude = 0.0; // 0.0 to 1.0 (clamped)

  @override
  void dispose() {
    _lockTimer?.cancel();
    _overPushTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.control.style;
    final backgroundColor = style?.color ?? Colors.black45;
    final borderColor = style?.borderColor ?? Colors.white30;
    final borderWidth = style?.borderWidth ?? 2.0;
    final stickColor = style?.pressedColor ?? Colors.white.withAlpha(200);
    final lockedColor = style?.lockedColor ?? Colors.cyanAccent;

    final backgroundImage =
        style?.backgroundImage ?? getImageProvider(style?.backgroundImagePath);
    final pressedImage = style?.pressedBackgroundImage ??
        getImageProvider(style?.pressedBackgroundImagePath);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(
              color: _isLocked ? lockedColor : borderColor,
              width: borderWidth),
          image: backgroundImage != null
              ? DecorationImage(
                  image: backgroundImage,
                  fit: style?.imageFit ?? BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                )
              : null,
          boxShadow: style?.shadows,
        ),
        child: CustomPaint(
          painter: _JoystickArcPainter(
            angle: _currentAngle,
            magnitude: _currentMagnitude,
            color: _isLocked
                ? lockedColor
                : (_lockTimer != null
                    ? Colors.yellowAccent
                    : borderColor.withAlpha(255)),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              _JoystickOverlay(
                control: widget.control,
                color: style?.labelStyle?.color ?? Colors.white70,
              ),
              // Stick
              Transform.translate(
                offset: _stickPosition,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: stickColor,
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                    image: pressedImage != null
                        ? DecorationImage(
                            image: pressedImage,
                            fit: style?.imageFit ?? BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            isAntiAlias: true,
                          )
                        : null,
                  ),
                  child: _isLocked
                      ? Icon(Icons.lock,
                          color: lockedColor, size: 14)
                      : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    if (_isLocked) {
      // Unlock on touch
      setState(() {
        _isLocked = false;
      });
      triggerFeedback(widget.control.feedback, true, type: 'light');
    }
    triggerFeedback(widget.control.feedback, true);
    _updateStick(details.localPosition);
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _updateStick(details.localPosition);
  }

  void _onPanEnd(DragEndDetails details) {
    _lockTimer?.cancel();
    _lockTimer = null;
    _overPushTimer?.cancel();
    _overPushTimer = null;

    // If locked, maintain state and do NOT reset or release buttons
    if (_isLocked) {
      return;
    }

    triggerFeedback(widget.control.feedback, false);

    // Release any over-push buttons
    if (_wasOverPushed) {
      final stickId = widget.control.stickType;
      final buttonId = stickId == 'right' ? 'R3' : 'L3';
      widget.onInputEvent(GamepadButtonInputEvent.up(buttonId));
      _wasOverPushed = false;
    }

    _wasAtEdge = false;
    _currentMagnitude = 0.0;

    final useGamepad = widget.control.mode == 'gamepad';

    if (useGamepad) {
      // Use explicit stickType
      final stickId = widget.control.stickType;
      widget
          .onInputEvent(GamepadAxisInputEvent(axisId: stickId, x: 0.0, y: 0.0));
    } else {
      for (final key in _activeKeys) {
        widget.onInputEvent(KeyboardInputEvent.up(key));
      }
      _activeKeys.clear();
    }

    setState(() => _stickPosition = Offset.zero);
  }

  void _updateStick(Offset localPosition) {
    final useGamepad = widget.control.mode == 'gamepad';

    final size = context.size;
    if (size == null) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 12;
    // Threshold for over-push (heavy vibration + click).
    // Now triggers at Edge (1.0 radius) with 0.5s Delay
    final overPushThreshold = maxRadius;
    // Threshold for Lock (Level 3)
    final lockThreshold = maxRadius * 2.0;

    var delta = localPosition - center;
    final distance = delta.distance;

    // Calculate Angle for Arc
    final angle = math.atan2(delta.dy, delta.dx);
    _currentAngle = angle;
    _currentMagnitude = (distance / maxRadius).clamp(0.0, 1.0);

    // Haptic Logic & State Machine
    if (distance >= lockThreshold) {
      if (!_isLocked && _lockTimer == null) {
        // Start timer for lock
        _lockTimer = Timer(const Duration(seconds: 1), () {
          if (mounted) {
            setState(() => _isLocked = true);
            triggerFeedback(widget.control.feedback, true, type: 'success');
          }
        });
      }
    } else {
      // Cancel timer if user moves back before lock triggers
      if (_lockTimer != null) {
        _lockTimer?.cancel();
        _lockTimer = null;
      }

      if (_isLocked && distance < maxRadius) {
        // Unlock if dragged back close to center without releasing
        setState(() => _isLocked = false);
        triggerFeedback(widget.control.feedback, true, type: 'light');
      }
    }

    if (distance >= maxRadius) {
      if (!_wasAtEdge) {
        triggerFeedback(widget.control.feedback, true, type: 'medium');
        _wasAtEdge = true;
      }
    } else {
      _wasAtEdge = false;
    }

    // Over-push / Level 2 Logic with Delay
    if (distance >= overPushThreshold) {
      if (!_wasOverPushed && _overPushTimer == null) {
        // Start 0.5s timer for over-push
        _overPushTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted && !_wasOverPushed) {
            triggerFeedback(widget.control.feedback, true, type: 'heavy');
            if (useGamepad) {
              final stickId = widget.control.stickType;
              final buttonId = stickId == 'right' ? 'R3' : 'L3';
              widget.onInputEvent(GamepadButtonInputEvent.down(buttonId));
            }
            _wasOverPushed = true;
          }
        });
      }
    } else {
      // Cancel over-push timer if user moves back
      _overPushTimer?.cancel();
      _overPushTimer = null;

      if (_wasOverPushed) {
        // Released from over-push region
        if (useGamepad) {
          final stickId = widget.control.stickType;
          final buttonId = stickId == 'right' ? 'R3' : 'L3';
          widget.onInputEvent(GamepadButtonInputEvent.up(buttonId));
        }
        _wasOverPushed = false;
      }
    }

    // Clamp stick visual
    if (distance > maxRadius) {
      delta = delta / distance * maxRadius;
    }

    setState(() => _stickPosition = delta);

    final dx = delta.dx / maxRadius;
    final dy = delta.dy / maxRadius;

    if (useGamepad) {
      // Use explicit stickType
      final stickId = widget.control.stickType;
      widget.onInputEvent(GamepadAxisInputEvent(axisId: stickId, x: dx, y: dy));
      return;
    }

    final newActiveKeys = <String>{};
    final deadzone = widget.control.deadzone;
    final keys = widget.control.keys;

    if (dy < -deadzone && keys.isNotEmpty) newActiveKeys.add(keys[0]);
    if (dx < -deadzone && keys.length > 1) newActiveKeys.add(keys[1]);
    if (dy > deadzone && keys.length > 2) newActiveKeys.add(keys[2]);
    if (dx > deadzone && keys.length > 3) newActiveKeys.add(keys[3]);

    for (final key in _activeKeys.difference(newActiveKeys)) {
      widget.onInputEvent(KeyboardInputEvent.up(key));
    }
    for (final key in newActiveKeys.difference(_activeKeys)) {
      widget.onInputEvent(KeyboardInputEvent.down(key));
    }
    _activeKeys = newActiveKeys;
  }
}

class _JoystickOverlay extends StatelessWidget {
  const _JoystickOverlay({required this.control, required this.color});

  final VirtualJoystick control;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final overlayStyle = control.config['overlayStyle']?.toString();
    final centerLabel =
        control.config['centerLabel']?.toString().trim().isNotEmpty == true
            ? control.config['centerLabel']!.toString()
            : control.label;
    final labels = control.config['overlayLabels'];
    final list = labels is List
        ? labels.map((e) => e?.toString() ?? '').toList()
        : const <String>[];

    final textStyle = TextStyle(
      color: color,
      fontSize: 12,
      fontWeight: FontWeight.w700,
      height: 1.0,
    );

    if (overlayStyle == 'center' && centerLabel.trim().isNotEmpty) {
      return IgnorePointer(
        child: Center(child: Text(centerLabel, style: textStyle)),
      );
    }

    if (overlayStyle == 'quadrant' && list.length >= 4) {
      return IgnorePointer(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Text(list[0], style: textStyle),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(list[1], style: textStyle),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: Text(list[2], style: textStyle),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Text(list[3], style: textStyle),
              ),
            ],
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

class _JoystickArcPainter extends CustomPainter {
  final double angle;
  final double magnitude;
  final Color color;

  _JoystickArcPainter({
    required this.angle,
    required this.magnitude,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (magnitude < 0.1) return;

    final center = Offset(size.width / 2, size.height / 2);
    // Draw arc outside the border
    // Base radius is width/2. Border width is typically 2.0.
    // We want some padding.
    final radius = size.width / 2 + 10.0;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    // Max sweep 60 degrees = pi / 3
    const maxSweep = math.pi / 3;
    final currentSweep = maxSweep * magnitude;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      angle - currentSweep / 2,
      currentSweep,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_JoystickArcPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.magnitude != magnitude ||
        oldDelegate.color != color;
  }
}
