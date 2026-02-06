import 'package:flutter/material.dart';
import '../../models/controls/virtual_custom_control.dart';
import '../../models/input_event.dart';
import '../shared/control_container.dart';
import '../shared/control_label.dart';
import '../shared/control_utils.dart';

/// Widget that renders a virtual custom control.
class VirtualCustomWidget extends StatefulWidget {
  /// Creates a virtual custom control widget.
  const VirtualCustomWidget({
    super.key,
    required this.control,
    required this.onInputEvent,
    required this.showLabel,
  });

  /// The custom control model.
  final VirtualCustomControl control;

  /// Callback for input events.
  final void Function(InputEvent) onInputEvent;

  /// Whether to show the label.
  final bool showLabel;

  @override
  State<VirtualCustomWidget> createState() => _VirtualCustomWidgetState();
}

class _VirtualCustomWidgetState extends State<VirtualCustomWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        triggerFeedback(widget.control.feedback, true);
        widget.onInputEvent(CustomInputEvent(
          id: widget.control.id,
          data: {...widget.control.customData, 'event': 'down'},
        ));
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        triggerFeedback(widget.control.feedback, false);
        widget.onInputEvent(CustomInputEvent(
          id: widget.control.id,
          data: {...widget.control.customData, 'event': 'up'},
        ));
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        triggerFeedback(widget.control.feedback, false);
        widget.onInputEvent(CustomInputEvent(
          id: widget.control.id,
          data: {...widget.control.customData, 'event': 'cancel'},
        ));
      },
      child: Transform.scale(
        scale: _isPressed ? 0.95 : 1.0,
        child: ControlContainer(
          isPressed: _isPressed,
          style: widget.control.style,
          defaultShape: BoxShape.rectangle, // Default to rectangle for custom
          defaultColor: Colors.blue.withAlpha(150), // Distinct color
          child: widget.showLabel
              ? ControlLabel(widget.control.label,
                  style: widget.control.style?.labelStyle)
              : const Icon(Icons.touch_app, color: Colors.white),
        ),
      ),
    );
  }
}
