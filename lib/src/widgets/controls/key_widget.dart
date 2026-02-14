import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/controls/virtual_key.dart';
import '../../models/input_event.dart';
import '../shared/control_container.dart';
import '../shared/control_label.dart';
import '../shared/control_utils.dart';

/// Widget that renders a virtual key.
class VirtualKeyWidget extends StatefulWidget {
  /// Creates a virtual key widget.
  const VirtualKeyWidget({
    super.key,
    required this.control,
    required this.onInputEvent,
    required this.showLabel,
  });

  /// The key control model.
  final VirtualKey control;

  /// Callback for input events.
  final void Function(InputEvent) onInputEvent;

  /// Whether to show the label.
  final bool showLabel;

  @override
  State<VirtualKeyWidget> createState() => _VirtualKeyWidgetState();
}

class _VirtualKeyWidgetState extends State<VirtualKeyWidget> {
  bool _isPressed = false;
  Timer? _repeatTimer;

  @override
  void dispose() {
    _repeatTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      child: Transform.scale(
        scale: _isPressed ? 0.95 : 1.0,
        child: ControlContainer(
          isPressed: _isPressed,
          style: widget.control.style,
          defaultShape: BoxShape.rectangle,
          child: widget.showLabel
              ? ControlLabel(
                  widget.control.label.isEmpty
                      ? widget.control.binding.key.code
                      : widget.control.label,
                  style: widget.control.style?.labelStyle,
                )
              : null,
        ),
      ),
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() => _isPressed = true);
    triggerFeedback(widget.control.feedback, true);
    widget.onInputEvent(KeyboardInputEvent.down(
      widget.control.binding.key,
      widget.control.binding.modifiers,
    ));

    if (widget.control.binding.repeat) {
      _repeatTimer = Timer.periodic(
        const Duration(milliseconds: 50),
        (_) => widget.onInputEvent(KeyboardInputEvent.down(
          widget.control.binding.key,
          widget.control.binding.modifiers,
        )),
      );
    }
  }

  void _onPointerUp(PointerUpEvent event) => _release();
  void _onPointerCancel(PointerCancelEvent event) => _release();

  void _release() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    setState(() => _isPressed = false);
    triggerFeedback(widget.control.feedback, false);
    widget.onInputEvent(KeyboardInputEvent.up(
      widget.control.binding.key,
      widget.control.binding.modifiers,
    ));
  }
}
