import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../models/controls/virtual_button.dart';
import '../../models/input_event.dart';
import '../shared/control_container.dart';
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

  String _resolveGamepadButton() {
    final fromConfig = widget.control.config['padKey'] ??
        widget.control.config['button'] ??
        widget.control.config['gamepadButton'];

    String pickNonEmpty(List<String?> candidates) {
      for (final c in candidates) {
        final v = c?.trim();
        if (v != null && v.isNotEmpty) return v;
      }
      return '';
    }

    final candidate = pickNonEmpty([
      fromConfig?.toString(),
      widget.control.label,
    ]);

    if (candidate.isNotEmpty) {
      return _normalizeGamepadButton(candidate);
    }

    final id = widget.control.id;
    final parts = id.split(RegExp(r'[_\-]'));
    final last = parts.isNotEmpty ? parts.last : id;
    return _normalizeGamepadButton(last);
  }

  String _normalizeGamepadButton(String raw) {
    final lower = raw.trim().toLowerCase();
    return switch (lower) {
      '△' => 'triangle',
      '○' => 'circle',
      '□' => 'square',
      '×' => 'cross',
      _ => lower,
    };
  }

  @override
  Widget build(BuildContext context) {
    final button = _resolveGamepadButton();
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
                    // Use the smallest dimension to ensure the symbol fits
                    final size =
                        math.min(constraints.maxWidth, constraints.maxHeight);
                    return GamepadSymbol(
                      id: widget.control.id,
                      label: widget.control.label,
                      size: size,
                      color: widget.control.style?.labelStyle?.color,
                    );
                  },
                )
              : null,
        ),
      ),
    );
  }
}
