import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import '../../models/controls/virtual_scroll_stick.dart';
import '../../models/input_event.dart';
import '../shared/control_utils.dart';
import '../../models/style/control_style.dart';

/// Widget that renders a virtual scroll stick (vertical slider).
///
/// Modified to support "Displacement Control" (touchpad style)
/// without a visible thumb, as requested.
class VirtualScrollStickWidget extends StatefulWidget {
  /// Creates a virtual scroll stick widget.
  const VirtualScrollStickWidget({
    super.key,
    required this.control,
    required this.onInputEvent,
  });

  /// The scroll stick control model.
  final VirtualScrollStick control;

  /// Callback for input events.
  final void Function(InputEvent) onInputEvent;

  @override
  State<VirtualScrollStickWidget> createState() =>
      _VirtualScrollStickWidgetState();
}

class _VirtualScrollStickWidgetState extends State<VirtualScrollStickWidget> {
  bool _isDragging = false;
  double _pendingDx = 0.0;
  double _pendingDy = 0.0;
  static const _emitInterval = Duration(milliseconds: 16);
  static const _epsilon = 0.00001;
  Timer? _emitTimer;

  double get _unitPerPixel {
    final v = widget.control.config['wheelUnitPerPixel'];
    if (v is num) return v.toDouble();
    return 3.0 / 20.0;
  }

  double get _maxAbsDeltaPerTick {
    final v = widget.control.config['maxAbsDeltaPerTick'];
    if (v is num) return v.toDouble();
    return 12.0;
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDragging = true;
    });
    triggerFeedback(widget.control.feedback, true);
    _pendingDx = 0.0;
    _pendingDy = 0.0;
    _emitTimer?.cancel();
    _emitTimer = null;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    _pendingDx += details.delta.dx;
    _pendingDy += details.delta.dy;
    _emitTimer ??= Timer(_emitInterval, _flushWheel);
  }

  void _onPanEnd(DragEndDetails details) {
    setState(() {
      _isDragging = false;
    });
    _flushWheel();
    triggerFeedback(widget.control.feedback, false);
    _pendingDx = 0.0;
    _pendingDy = 0.0;
    _emitTimer?.cancel();
    _emitTimer = null;
  }

  void _flushWheel() {
    _emitTimer?.cancel();
    _emitTimer = null;

    final sensitivity =
        widget.control.sensitivity > 0 ? widget.control.sensitivity : 1.0;
    final rawDx = _pendingDx * _unitPerPixel * sensitivity;
    final rawDy = _pendingDy * _unitPerPixel * sensitivity;
    final maxAbs = _maxAbsDeltaPerTick;
    final dx = rawDx.clamp(-maxAbs, maxAbs).toDouble();
    final dy = rawDy.clamp(-maxAbs, maxAbs).toDouble();
    _pendingDx = 0.0;
    _pendingDy = 0.0;

    if (dx.abs() < _epsilon && dy.abs() < _epsilon) return;

    widget.onInputEvent(MouseWheelVectorInputEvent(dx: dx, dy: dy));
  }

  @override
  Widget build(BuildContext context) {
    final style = widget.control.style ?? const ControlStyle();
    final backgroundImage =
        style.backgroundImage ?? getImageProvider(style.backgroundImagePath);
    final pressedImage = style.pressedBackgroundImage ??
        getImageProvider(style.pressedBackgroundImagePath);
    final currentImage =
        _isDragging ? (pressedImage ?? backgroundImage) : backgroundImage;

    final defaultColor = backgroundImage != null
        ? Colors.transparent
        : Colors.grey.withValues(alpha: 0.3);
    final defaultPressedColor = backgroundImage != null
        ? Colors.transparent
        : Colors.blue.withValues(alpha: 0.2);
    final color = style.color ?? defaultColor;
    final pressedColor = style.pressedColor ?? defaultPressedColor;
    final activeColor = _isDragging ? pressedColor : color;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        final radius = width / 2;
        final iconSize = math.min(width * 0.55, height / 4.5);

        return GestureDetector(
          onPanStart: _onPanStart,
          onPanUpdate: _onPanUpdate,
          onPanEnd: _onPanEnd,
          onPanCancel: () => _onPanEnd(DragEndDetails()),
          child: Container(
            width: width,
            height: height,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: activeColor,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: style.borderColor ?? Colors.white30,
                width: style.borderWidth,
              ),
              image: currentImage != null
                  ? DecorationImage(
                      image: currentImage,
                      fit: style.imageFit,
                      filterQuality: FilterQuality.high,
                      isAntiAlias: true,
                    )
                  : null,
              boxShadow: style.shadows,
            ),
            child: Center(
              // Add a subtle icon or visual cue that this is a scroll area
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Icon(Icons.keyboard_arrow_up,
                      color: Colors.white12, size: iconSize),
                  Icon(Icons.unfold_more,
                      color: Colors.white24, size: iconSize),
                  Icon(Icons.keyboard_arrow_down,
                      color: Colors.white12, size: iconSize),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
