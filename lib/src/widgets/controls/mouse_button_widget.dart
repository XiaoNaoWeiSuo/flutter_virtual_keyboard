import 'package:flutter/material.dart';
import '../../models/controls/virtual_mouse_button.dart';
import '../../models/input_event.dart';
import '../shared/control_container.dart';
import '../shared/control_label.dart';
import '../shared/control_utils.dart';

/// Widget that renders a virtual mouse button.
class VirtualMouseButtonWidget extends StatefulWidget {
  /// Creates a virtual mouse button widget.
  const VirtualMouseButtonWidget({
    super.key,
    required this.control,
    required this.onInputEvent,
    required this.showLabel,
  });

  /// The mouse button control model.
  final VirtualMouseButton control;

  /// Callback for input events.
  final void Function(InputEvent) onInputEvent;

  /// Whether to show the label.
  final bool showLabel;

  @override
  State<VirtualMouseButtonWidget> createState() =>
      _VirtualMouseButtonWidgetState();
}

class _VirtualMouseButtonWidgetState extends State<VirtualMouseButtonWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        triggerFeedback(widget.control.feedback, true);
        widget.onInputEvent(MouseButtonInputEvent.down(widget.control.button));
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        triggerFeedback(widget.control.feedback, false);
        widget.onInputEvent(MouseButtonInputEvent.up(widget.control.button));
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        triggerFeedback(widget.control.feedback, false);
        widget.onInputEvent(MouseButtonInputEvent.up(widget.control.button));
      },
      child: Transform.scale(
        scale: _isPressed ? 0.95 : 1.0,
        child: ControlContainer(
          isPressed: _isPressed,
          style: widget.control.style,
          defaultShape: BoxShape.rectangle,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.control.button == 'left'
                      ? Icons.mouse_outlined
                      : Icons.mouse,
                  color: Colors.white,
                  size: 20,
                ),
                if (widget.showLabel)
                  ControlLabel(widget.control.label,
                      style: widget.control.style?.labelStyle),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
