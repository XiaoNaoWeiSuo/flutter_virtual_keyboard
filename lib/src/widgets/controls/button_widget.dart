import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/controls/virtual_button.dart';
import '../../models/input_event.dart';
import '../shared/control_container.dart';
import '../shared/control_label.dart';
import '../shared/gamepad_symbol.dart';
import '../shared/control_utils.dart';

/// Widget that renders a virtual button (gamepad style).
class VirtualButtonWidget extends StatefulWidget {
  /// Creates a virtual button widget.
  const VirtualButtonWidget({
    super.key,
    required this.control,
    required this.onInputEvent,
    required this.showLabel,
  });

  /// The button control model.
  final VirtualButton control;

  /// Callback for input events.
  final void Function(InputEvent) onInputEvent;

  /// Whether to show the label.
  final bool showLabel;

  @override
  State<VirtualButtonWidget> createState() => _VirtualButtonWidgetState();
}

class _VirtualButtonWidgetState extends State<VirtualButtonWidget> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final button = widget.control.binding.code;
    final style = widget.control.style;
    final useSymbol = style?.useGamepadSymbol ?? true;
    final text = style?.labelText ?? (useSymbol ? '' : widget.control.label);
    final hasText = text.trim().isNotEmpty;
    final hasCustomIcon = style?.labelIcon != null;
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        triggerFeedback(widget.control.feedback, true);
        widget.onInputEvent(GamepadButtonInputEvent.down(button));
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        triggerFeedback(widget.control.feedback, false);
        widget.onInputEvent(GamepadButtonInputEvent.up(button));
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        triggerFeedback(widget.control.feedback, false);
        widget.onInputEvent(GamepadButtonInputEvent.up(button));
      },
      child: Transform.scale(
        scale: _isPressed ? 0.95 : 1.0,
        child: ControlContainer(
          isPressed: _isPressed,
          style: widget.control.style,
          defaultShape: BoxShape.circle,
          child: widget.showLabel
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final size =
                        math.min(constraints.maxWidth, constraints.maxHeight);
                    final iconSize = size * (style?.labelIconScale ?? 0.6);
                    final iconColor = style?.labelIconColor;

                    Widget? iconWidget;
                    if (hasCustomIcon) {
                      iconWidget = Icon(
                        style!.labelIcon,
                        size: iconSize,
                        color: iconColor ?? style.labelStyle?.color,
                      );
                    } else if (useSymbol) {
                      iconWidget = GamepadSymbol(
                        id: widget.control.id,
                        label: widget.control.label,
                        size: iconSize,
                        color: iconColor ?? style?.labelStyle?.color,
                      );
                    }

                    return ControlLabel(
                      hasText ? text : '',
                      style: style?.labelStyle,
                      iconWidget: iconWidget,
                      iconColor: iconColor,
                      iconScale: style?.labelIconScale ?? 0.6,
                    );
                  },
                )
              : null,
        ),
      ),
    );
  }
}
