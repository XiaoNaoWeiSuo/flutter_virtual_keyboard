import 'package:flutter/material.dart';
import '../../models/controls/virtual_mouse_wheel.dart';
import '../../models/input_event.dart';
import '../shared/control_container.dart';
import '../shared/control_utils.dart';

/// Widget that renders a virtual mouse wheel.
class VirtualMouseWheelWidget extends StatefulWidget {
  /// Creates a virtual mouse wheel widget.
  const VirtualMouseWheelWidget({
    super.key,
    required this.control,
    required this.onInputEvent,
  });

  /// The mouse wheel control model.
  final VirtualMouseWheel control;

  /// Callback for input events.
  final void Function(InputEvent) onInputEvent;

  @override
  State<VirtualMouseWheelWidget> createState() =>
      _VirtualMouseWheelWidgetState();
}

class _VirtualMouseWheelWidgetState extends State<VirtualMouseWheelWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final icon = widget.control.direction == 'up'
        ? Icons.keyboard_arrow_up
        : Icons.keyboard_arrow_down;

    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        triggerFeedback(widget.control.feedback, true);
        final delta = widget.control.direction == 'up' ? 1 : -1;
        widget.onInputEvent(MouseWheelInputEvent(
            direction: widget.control.direction, delta: delta * 120));
      },
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: ControlContainer(
        isPressed: _isPressed,
        style: widget.control.style,
        defaultShape: BoxShape.rectangle,
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
