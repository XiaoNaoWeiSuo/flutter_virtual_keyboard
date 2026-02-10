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
  bool _isStickClickDown = false;
  bool _showStickClickHint = false;
  Offset _stickClickHintOffset = Offset.zero;
  bool _isLocked = false;
  Timer? _lockTimer;
  double _currentAngle = 0.0;
  double _currentMagnitude = 0.0; // 0.0 to 1.0 (clamped)

  double _lastAxisX = 0.0;
  double _lastAxisY = 0.0;
  int _lastAxisSentUs = 0;

  @override
  void dispose() {
    _lockTimer?.cancel();
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
    final clickColor = style?.pressedBorderColor ?? Colors.orangeAccent;

    final backgroundImage =
        style?.backgroundImage ?? getImageProvider(style?.backgroundImagePath);
    final pressedImage = style?.pressedBackgroundImage ??
        getImageProvider(style?.pressedBackgroundImagePath);
    final stickClickEnabled =
        widget.control.config['stickClickEnabled'] == true;

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: backgroundColor,
          border: Border.all(
              color: _isLocked
                  ? lockedColor
                  : (_isStickClickDown ? clickColor : borderColor),
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
                    : (_isStickClickDown
                        ? clickColor
                        : borderColor.withAlpha(255))),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipOval(
                child: _JoystickOverlay(
                  control: widget.control,
                  color: style?.labelStyle?.color ?? Colors.white70,
                ),
              ),
              if (stickClickEnabled &&
                  _showStickClickHint &&
                  !_isLocked &&
                  !_isStickClickDown)
                Transform.translate(
                  offset: _stickClickHintOffset,
                  child: IgnorePointer(
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 1,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'S',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ),
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
                      ? Icon(Icons.lock, color: lockedColor, size: 14)
                      : _isStickClickDown
                          ? Icon(Icons.sports_esports,
                              color: clickColor, size: 14)
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
      if (_isStickClickDown) {
        _emitStickClick(false);
      }
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

    // If locked, maintain state and do NOT reset or release buttons
    if (_isLocked) {
      return;
    }

    triggerFeedback(widget.control.feedback, false);

    if (_isStickClickDown) {
      _emitStickClick(false);
    }

    _currentMagnitude = 0.0;
    _showStickClickHint = false;

    final useGamepad = widget.control.mode == 'gamepad';

    if (useGamepad) {
      // Use explicit stickType
      final stickId = widget.control.stickType;
      _emitAxis(stickId: stickId, x: 0.0, y: 0.0);
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
    final stickClickEnabled =
        widget.control.config['stickClickEnabled'] == true;
    final stickLockEnabled =
        widget.control.config['stickLockEnabled'] == true;

    final size = context.size;
    if (size == null) return;

    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2 - 12;
    // Threshold for Lock (Level 3)
    final lockThreshold = maxRadius * 2.0;

    final stickClickHintDistance = (maxRadius * 0.22).clamp(12.0, 20.0);
    const stickClickHintHitRadius = 14.0;
    final stickClickCancelRadius = maxRadius * 0.88;

    var delta = localPosition - center;
    final distance = delta.distance;

    // Calculate Angle for Arc
    final angle = math.atan2(delta.dy, delta.dx);
    _currentAngle = angle;
    _currentMagnitude = (distance / maxRadius).clamp(0.0, 1.0);

    // Haptic Logic & State Machine (Lock)
    if (useGamepad && stickLockEnabled) {
      if (distance >= lockThreshold) {
        if (!_isLocked && _lockTimer == null) {
          _lockTimer = Timer(const Duration(seconds: 1), () {
            if (!mounted) return;
            setState(() => _isLocked = true);
            if (stickClickEnabled && !_isStickClickDown) {
              _emitStickClick(true);
            }
            triggerFeedback(widget.control.feedback, true, type: 'success');
          });
        }
      } else {
        if (_lockTimer != null) {
          _lockTimer?.cancel();
          _lockTimer = null;
        }

        if (_isLocked && distance < maxRadius) {
          setState(() => _isLocked = false);
          if (_isStickClickDown) {
            _emitStickClick(false);
          }
          triggerFeedback(widget.control.feedback, true, type: 'light');
        }
      }
    } else {
      if (_lockTimer != null) {
        _lockTimer?.cancel();
        _lockTimer = null;
      }
      if (_isLocked) {
        setState(() => _isLocked = false);
      }
    }

    if (useGamepad && !_isLocked && stickClickEnabled) {
      if (distance >= maxRadius) {
        final unit = distance == 0 ? Offset.zero : delta / distance;
        final hintOffset = unit * (maxRadius + stickClickHintDistance);
        final hintCenter = center + hintOffset;
        final overHint =
            (localPosition - hintCenter).distance <= stickClickHintHitRadius;
        final showHint = !_isStickClickDown;

        if (_showStickClickHint != showHint ||
            (showHint && _stickClickHintOffset != hintOffset)) {
          setState(() {
            _showStickClickHint = showHint;
            _stickClickHintOffset = hintOffset;
          });
        }

        if (!_isStickClickDown && overHint) {
          triggerFeedback(widget.control.feedback, true, type: 'heavy');
          _emitStickClick(true);
        }
      } else {
        if (_showStickClickHint) {
          setState(() {
            _showStickClickHint = false;
          });
        }
      }

      if (_isStickClickDown && distance <= stickClickCancelRadius) {
        _emitStickClick(false);
      }
    } else {
      if (_showStickClickHint) {
        setState(() {
          _showStickClickHint = false;
        });
      }
      if (_isStickClickDown) {
        _emitStickClick(false);
      }
    }

    // Clamp stick visual
    if (distance > maxRadius) {
      delta = delta / distance * maxRadius;
    }

    final nextStickPosition = delta;
    if ((_stickPosition - nextStickPosition).distanceSquared > 0.25) {
      setState(() => _stickPosition = nextStickPosition);
    }

    final dx = delta.dx / maxRadius;
    final dy = delta.dy / maxRadius;

    if (useGamepad) {
      // Use explicit stickType
      final stickId = widget.control.stickType;
      _emitAxis(stickId: stickId, x: dx, y: dy);
      return;
    }

    final newActiveKeys = <String>{};
    final deadzone = widget.control.deadzone;
    final keys = widget.control.keys;

    if (dy < -deadzone && keys.isNotEmpty) newActiveKeys.add(keys[0].code);
    if (dx < -deadzone && keys.length > 1) newActiveKeys.add(keys[1].code);
    if (dy > deadzone && keys.length > 2) newActiveKeys.add(keys[2].code);
    if (dx > deadzone && keys.length > 3) newActiveKeys.add(keys[3].code);

    for (final key in _activeKeys.difference(newActiveKeys)) {
      widget.onInputEvent(KeyboardInputEvent.up(key));
    }
    for (final key in newActiveKeys.difference(_activeKeys)) {
      widget.onInputEvent(KeyboardInputEvent.down(key));
    }
    _activeKeys = newActiveKeys;
  }

  void _emitAxis({
    required String stickId,
    required double x,
    required double y,
  }) {
    final nowUs = DateTime.now().microsecondsSinceEpoch;
    const minIntervalUs = 8000;
    const epsilon = 0.002;

    final dx = (x - _lastAxisX).abs();
    final dy = (y - _lastAxisY).abs();
    final changed = dx > epsilon || dy > epsilon;
    final due = (nowUs - _lastAxisSentUs) >= minIntervalUs;

    if (!changed && !due) return;

    _lastAxisX = x;
    _lastAxisY = y;
    _lastAxisSentUs = nowUs;
    widget.onInputEvent(GamepadAxisInputEvent(axisId: stickId, x: x, y: y));
  }

  void _emitStickClick(bool down) {
    if (widget.control.mode != 'gamepad') return;
    if (_isStickClickDown == down) return;
    setState(() {
      _isStickClickDown = down;
      if (down) {
        _showStickClickHint = false;
      }
    });
    final stickId = widget.control.stickType;
    final buttonId = stickId == 'right' ? 'r3' : 'l3';
    widget.onInputEvent(
        down ? GamepadButtonInputEvent.down(buttonId) : GamepadButtonInputEvent.up(buttonId));
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

    if (overlayStyle == 'center' && centerLabel.trim().isNotEmpty) {
      return IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final fontSize =
                (constraints.biggest.shortestSide * 0.18).clamp(10.0, 14.0);
            final textStyle = TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.0,
            );
            return Center(child: Text(centerLabel, style: textStyle));
          },
        ),
      );
    }

    if (overlayStyle == 'quadrant' && list.length >= 4) {
      return IgnorePointer(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final shortest = constraints.biggest.shortestSide;
            final pad = (shortest * 0.10).clamp(6.0, 10.0);
            final fontSize = (shortest * 0.16).clamp(10.0, 13.0);
            final textStyle = TextStyle(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              height: 1.0,
            );
            return Padding(
              padding: EdgeInsets.all(pad),
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
            );
          },
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
