import 'package:flutter/material.dart';
import '../models/virtual_controller_models.dart';
import '../utils/control_geometry.dart';
import '../widgets/shared/control_container.dart';
import '../widgets/shared/control_label.dart';
import '../widgets/controls/button_widget.dart';
import '../widgets/controls/custom_widget.dart';
import '../widgets/controls/dpad_widget.dart';
import '../widgets/controls/joystick_widget.dart';
import '../widgets/controls/key_widget.dart';
import '../widgets/controls/mouse_button_widget.dart';
import '../widgets/controls/mouse_wheel_widget.dart';
import '../widgets/controls/scroll_stick_widget.dart';
import '../widgets/controls/split_mouse_widget.dart';
import 'resize_direction.dart';

class VirtualControllerLayoutEditorCanvas extends StatelessWidget {
  const VirtualControllerLayoutEditorCanvas({
    super.key,
    required this.layout,
    required this.selectedControlId,
    required this.onSelectControl,
    required this.onMoveControlBy,
    required this.onResizeControlBy,
    this.showGrid = true,
    this.hitPadding = 8.0,
    this.handleSize = 18.0,
    this.showSelectionOverlay = true,
    this.showResizeHandles = true,
    this.onBackgroundTap,
    this.controlPreviewBuilder,
  });

  final VirtualControllerLayout layout;
  final String? selectedControlId;
  final ValueChanged<VirtualControl?> onSelectControl;
  final void Function(String controlId, Offset delta, Size canvasSize)
      onMoveControlBy;
  final void Function(String controlId, Offset delta, Size canvasSize,
      ResizeDirection direction) onResizeControlBy;

  final bool showGrid;
  final double hitPadding;
  final double handleSize;
  final bool showSelectionOverlay;
  final bool showResizeHandles;
  final VoidCallback? onBackgroundTap;
  final Widget Function(VirtualControl control)? controlPreviewBuilder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenSize = Size(constraints.maxWidth, constraints.maxHeight);

        return Stack(
          children: [
            if (showGrid) _GridBackground(size: screenSize),
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: () {
                  onSelectControl(null);
                  onBackgroundTap?.call();
                },
              ),
            ),
            for (final control in layout.controls)
              _ControlEditorItem(
                control: control,
                screenSize: screenSize,
                isSelected: control.id == selectedControlId,
                hitPadding: hitPadding,
                handleSize: handleSize,
                showSelectionOverlay: showSelectionOverlay,
                showResizeHandles: showResizeHandles,
                onSelect: () => onSelectControl(control),
                onMoveBy: (d) => onMoveControlBy(control.id, d, screenSize),
                onResizeBy: (d, dir) =>
                    onResizeControlBy(control.id, d, screenSize, dir),
                previewBuilder:
                    controlPreviewBuilder ?? _defaultControlPreviewBuilder,
              ),
          ],
        );
      },
    );
  }
}

class _ControlEditorItem extends StatelessWidget {
  const _ControlEditorItem({
    required this.control,
    required this.screenSize,
    required this.isSelected,
    required this.hitPadding,
    required this.handleSize,
    required this.showSelectionOverlay,
    required this.showResizeHandles,
    required this.onSelect,
    required this.onMoveBy,
    required this.onResizeBy,
    required this.previewBuilder,
  });

  final VirtualControl control;
  final Size screenSize;
  final bool isSelected;
  final double hitPadding;
  final double handleSize;
  final bool showSelectionOverlay;
  final bool showResizeHandles;
  final VoidCallback onSelect;
  final ValueChanged<Offset> onMoveBy;
  final void Function(Offset delta, ResizeDirection direction) onResizeBy;
  final Widget Function(VirtualControl control) previewBuilder;

  @override
  Widget build(BuildContext context) {
    final rect = ControlGeometry.occupiedRect(control, screenSize);

    return Positioned(
      left: rect.left - hitPadding,
      top: rect.top - hitPadding,
      width: rect.width + hitPadding * 2,
      height: rect.height + hitPadding * 2,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onSelect,
        onPanStart: (_) => onSelect(),
        onPanUpdate: (d) => onMoveBy(d.delta),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: hitPadding,
              top: hitPadding,
              width: rect.width,
              height: rect.height,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: _opacityFrom(control),
                    child: IgnorePointer(child: previewBuilder(control)),
                  ),
                  if (showSelectionOverlay)
                    _SelectionOverlay(control: control, isSelected: isSelected),
                ],
              ),
            ),
            if (isSelected && showResizeHandles) ...[
              _ResizeHandle(
                left: hitPadding - handleSize / 2,
                top: hitPadding - handleSize / 2,
                size: handleSize,
                onPanUpdate: (d) =>
                    onResizeBy(d.delta, ResizeDirection.topLeft),
              ),
              _ResizeHandle(
                right: hitPadding - handleSize / 2,
                top: hitPadding - handleSize / 2,
                size: handleSize,
                onPanUpdate: (d) =>
                    onResizeBy(d.delta, ResizeDirection.topRight),
              ),
              _ResizeHandle(
                left: hitPadding - handleSize / 2,
                bottom: hitPadding - handleSize / 2,
                size: handleSize,
                onPanUpdate: (d) =>
                    onResizeBy(d.delta, ResizeDirection.bottomLeft),
              ),
              _ResizeHandle(
                right: hitPadding - handleSize / 2,
                bottom: hitPadding - handleSize / 2,
                size: handleSize,
                onPanUpdate: (d) =>
                    onResizeBy(d.delta, ResizeDirection.bottomRight),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SelectionOverlay extends StatelessWidget {
  const _SelectionOverlay({required this.control, required this.isSelected});

  final VirtualControl control;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    if (!isSelected) return const SizedBox.shrink();

    final (shape, radius) = _selectionShapeFor(control);

    return IgnorePointer(
      child: CustomPaint(
        painter: _DashedSelectionPainter(shape: shape, radius: radius),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _DashedSelectionPainter extends CustomPainter {
  _DashedSelectionPainter({
    required this.shape,
    required this.radius,
  });

  final BoxShape shape;
  final double radius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final rect = Offset.zero & size;
    final insetRect = rect.deflate(1.0);

    final path = Path();
    if (shape == BoxShape.circle) {
      path.addOval(insetRect);
    } else {
      path.addRRect(RRect.fromRectXY(insetRect, radius, radius));
    }

    const dash = 6.0;
    const gap = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dash;
        final segment =
            metric.extractPath(distance, next.clamp(0.0, metric.length));
        canvas.drawPath(segment, paint);
        distance = next + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedSelectionPainter oldDelegate) {
    return oldDelegate.shape != shape || oldDelegate.radius != radius;
  }
}

class _ResizeHandle extends StatelessWidget {
  const _ResizeHandle({
    this.left,
    this.top,
    this.right,
    this.bottom,
    required this.size,
    required this.onPanUpdate,
  });

  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final double size;
  final ValueChanged<DragUpdateDetails> onPanUpdate;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      right: right,
      bottom: bottom,
      width: size,
      height: size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanUpdate: onPanUpdate,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.blueAccent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const SizedBox.expand(),
        ),
      ),
    );
  }
}

(BoxShape shape, double radius) _selectionShapeFor(VirtualControl control) {
  if (control is VirtualKey ||
      control is VirtualKeyCluster ||
      control is VirtualMouseButton ||
      control is VirtualMouseWheel ||
      control is VirtualScrollStick ||
      control is VirtualSplitMouse ||
      control is VirtualMacroButton ||
      control is VirtualCustomControl) {
    return (BoxShape.rectangle, control.style?.borderRadius ?? 8.0);
  }
  if (control is VirtualButton) {
    final shape = control.style?.shape ?? BoxShape.circle;
    if (shape == BoxShape.rectangle) {
      return (BoxShape.rectangle, control.style?.borderRadius ?? 8.0);
    }
    return (BoxShape.circle, 0.0);
  }
  if (control is VirtualJoystick) {
    return (BoxShape.circle, 0.0);
  }
  return (BoxShape.rectangle, 8.0);
}

Widget _defaultControlPreviewBuilder(VirtualControl control) {
  if (control is VirtualKey) {
    return ControlContainer(
      style: control.style,
      defaultShape: BoxShape.rectangle,
      child: ControlLabel(
        control.label.isNotEmpty ? control.label : control.key,
        style: control.style?.labelStyle,
      ),
    );
  }
  if (control is VirtualButton) {
    return VirtualButtonWidget(
      control: control,
      onInputEvent: (_) {},
      showLabel: true,
    );
  }
  if (control is VirtualMouseButton) {
    return VirtualMouseButtonWidget(
      control: control,
      onInputEvent: (_) {},
      showLabel: true,
    );
  }
  if (control is VirtualJoystick) {
    return VirtualJoystickWidget(
      control: control,
      onInputEvent: (_) {},
    );
  }
  if (control is VirtualDpad) {
    return VirtualDpadWidget(
      control: control,
      onInputEvent: (_) {},
    );
  }
  if (control is VirtualMouseWheel) {
    return VirtualMouseWheelWidget(
      control: control,
      onInputEvent: (_) {},
    );
  }
  if (control is VirtualScrollStick) {
    return VirtualScrollStickWidget(
      control: control,
      onInputEvent: (_) {},
    );
  }
  if (control is VirtualSplitMouse) {
    return VirtualSplitMouseWidget(
      control: control,
      onInputEvent: (_) {},
    );
  }
  if (control is VirtualKeyCluster) {
    return ControlContainer(
      style: control.style,
      defaultShape: BoxShape.rectangle,
      child: const SizedBox.expand(),
    );
  }
  if (control is VirtualCustomControl) {
    return VirtualCustomWidget(
      control: control,
      onInputEvent: (_) {},
      showLabel: true,
    );
  }
  return ControlContainer(
    style: control.style,
    defaultShape: BoxShape.rectangle,
    child: Center(
      child: ControlLabel(
        control.label.isNotEmpty ? control.label : '?',
        style: control.style?.labelStyle,
      ),
    ),
  );
}

double _opacityFrom(VirtualControl control) {
  final v = control.config['opacity'];
  if (v is num) return v.toDouble().clamp(0.0, 1.0);
  return 1.0;
}

class _GridBackground extends StatelessWidget {
  const _GridBackground({required this.size});
  final Size size;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF1E1E1E),
      child: CustomPaint(
        size: size,
        painter: _GridPainter(),
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1;

    const step = 20.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
