import 'style/control_layout.dart';
import 'style/control_style.dart';
import 'binding/binding.dart';
import 'identifiers.dart';
import 'controls/virtual_control.dart';
import 'controls/virtual_joystick.dart';
import 'controls/virtual_button.dart';

// Export all models for convenience
export 'style/control_style.dart';
export 'style/control_feedback.dart';
export 'style/control_layout.dart';
export 'binding/binding.dart';
export 'action/control_action.dart';
export 'controls/virtual_control.dart';
export 'controls/virtual_joystick.dart';
export 'controls/virtual_button.dart';
export 'controls/virtual_dpad.dart';
export 'controls/virtual_key.dart';
export 'controls/virtual_key_cluster.dart';
export 'controls/virtual_mouse_button.dart';
export 'controls/virtual_mouse_wheel.dart';
export 'controls/virtual_macro_button.dart';
export 'controls/virtual_custom_control.dart';
export 'controls/virtual_split_mouse.dart';
export 'controls/virtual_scroll_stick.dart';
export 'controller_state.dart';

/// Root Layout Model.
///
/// Represents the complete layout of a virtual controller.
class VirtualControllerLayout {
  /// Creates a virtual controller layout.
  const VirtualControllerLayout({
    required this.schemaVersion,
    required this.name,
    required this.controls,
  });

  VirtualControllerLayout copyWith({
    int? schemaVersion,
    String? name,
    List<VirtualControl>? controls,
  }) {
    return VirtualControllerLayout(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      name: name ?? this.name,
      controls: controls ?? this.controls,
    );
  }

  VirtualControllerLayout mapControls(
    VirtualControl Function(VirtualControl control) transform,
  ) {
    return copyWith(controls: controls.map(transform).toList());
  }

  VirtualControllerLayout withButtonStyle({
    required bool Function(VirtualButton button) where,
    required ControlStyle style,
  }) {
    return mapControls((c) {
      if (c is VirtualButton && where(c)) {
        return c.copyWith(style: style);
      }
      return c;
    });
  }

  VirtualControllerLayout withButtonLayout({
    required bool Function(VirtualButton button) where,
    required ControlLayout layout,
  }) {
    return mapControls((c) {
      if (c is VirtualButton && where(c)) {
        return c.copyWith(layout: layout);
      }
      return c;
    });
  }

  VirtualControllerLayout withButtonLayoutByGamepadButtonId({
    required GamepadButtonId button,
    required ControlLayout layout,
  }) {
    return withButtonLayout(
      where: (b) => b.gamepadButtonOrNull == button,
      layout: layout,
    );
  }

  VirtualControllerLayout withButtonStyleByGamepadButtonId({
    required GamepadButtonId button,
    required ControlStyle style,
  }) {
    return withButtonStyle(
      where: (b) => b.gamepadButtonOrNull == button,
      style: style,
    );
  }

  /// Create a standard Xbox controller layout.
  factory VirtualControllerLayout.xbox() {
    return VirtualControllerLayout(
      schemaVersion: 1,
      name: 'Xbox Controller',
      controls: [
        // Left Stick
        VirtualJoystick(
          id: 'ls',
          label: 'LS',
          layout: const ControlLayout(x: 0.1, y: 0.2, width: 0.2, height: 0.2),
          trigger: TriggerType.hold,
          mode: JoystickMode.gamepad,
          stickType: GamepadStickId.left,
        ),
        // Right Stick
        VirtualJoystick(
          id: 'rs',
          label: 'RS',
          layout: const ControlLayout(x: 0.7, y: 0.5, width: 0.2, height: 0.2),
          trigger: TriggerType.hold,
          mode: JoystickMode.gamepad,
          stickType: GamepadStickId.right,
        ),
        // A, B, X, Y
        VirtualButton(
          id: 'a',
          label: 'A',
          layout:
              const ControlLayout(x: 0.8, y: 0.7, width: 0.08, height: 0.08),
          trigger: TriggerType.tap,
          binding: const GamepadButtonBinding(GamepadButtonId.a),
        ),
        VirtualButton(
          id: 'b',
          label: 'B',
          layout:
              const ControlLayout(x: 0.9, y: 0.6, width: 0.08, height: 0.08),
          trigger: TriggerType.tap,
          binding: const GamepadButtonBinding(GamepadButtonId.b),
        ),
        VirtualButton(
          id: 'x',
          label: 'X',
          layout:
              const ControlLayout(x: 0.7, y: 0.6, width: 0.08, height: 0.08),
          trigger: TriggerType.tap,
          binding: const GamepadButtonBinding(GamepadButtonId.x),
        ),
        VirtualButton(
          id: 'y',
          label: 'Y',
          layout:
              const ControlLayout(x: 0.8, y: 0.5, width: 0.08, height: 0.08),
          trigger: TriggerType.tap,
          binding: const GamepadButtonBinding(GamepadButtonId.y),
        ),
      ],
    );
  }

  /// The schema version of the layout format.
  final int schemaVersion;

  /// The name of the layout.
  final String name;

  /// The list of controls in the layout.
  final List<VirtualControl> controls;
}
