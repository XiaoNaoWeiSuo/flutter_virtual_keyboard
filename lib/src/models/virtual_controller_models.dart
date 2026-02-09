import 'style/control_layout.dart';
import 'style/control_style.dart';
import 'binding/binding.dart';
import 'controls/virtual_control.dart';
import 'controls/virtual_joystick.dart';
import 'controls/virtual_button.dart';
import 'controls/virtual_dpad.dart';
import 'controls/virtual_key.dart';
import 'controls/virtual_key_cluster.dart';
import 'controls/virtual_mouse_button.dart';
import 'controls/virtual_mouse_wheel.dart';
import 'controls/virtual_macro_button.dart';
import 'controls/virtual_custom_control.dart';
import 'controls/virtual_split_mouse.dart';
import 'controls/virtual_scroll_stick.dart';

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

/// Factory for creating [VirtualControl] instances.
class VirtualControlFactory {
  /// Creates a [VirtualControl] from a JSON map based on the 'type' field.
  static VirtualControl fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    switch (type) {
      case 'joystick':
        return VirtualJoystick.fromJson(json);
      case 'button':
        return VirtualButton.fromJson(json);
      case 'dpad':
        return VirtualDpad.fromJson(json);
      case 'key':
        return VirtualKey.fromJson(json);
      case 'key_cluster':
        return VirtualKeyCluster.fromJson(json);
      case 'mouse_button':
        return VirtualMouseButton.fromJson(json);
      case 'mouse_wheel':
        return VirtualMouseWheel.fromJson(json);
      case 'macro_button':
        return VirtualMacroButton.fromJson(json);
      case 'custom':
        return VirtualCustomControl.fromJson(json);
      case 'split_mouse':
        return VirtualSplitMouse.fromJson(json);
      case 'scroll_stick':
        return VirtualScrollStick.fromJson(json);
      default:
        throw ArgumentError('Unknown control type: $type');
    }
  }
}

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

  VirtualControllerLayout withButtonLayoutByPadKeyOrId({
    required String padKeyOrId,
    required ControlLayout layout,
  }) {
    final needle = padKeyOrId.trim().toLowerCase();
    return withButtonLayout(
      where: (b) {
        final id = b.id.trim().toLowerCase();
        final legacyPadKey =
            b.config['padKey']?.toString().trim().toLowerCase();
        final code = b.binding.code.trim().toLowerCase();
        return id == needle ||
            id.endsWith('_$needle') ||
            legacyPadKey == needle ||
            code == needle;
      },
      layout: layout,
    );
  }

  VirtualControllerLayout withButtonStyleByPadKeyOrId({
    required String padKeyOrId,
    required ControlStyle style,
  }) {
    final needle = padKeyOrId.trim().toLowerCase();
    return withButtonStyle(
      where: (b) {
        final id = b.id.trim().toLowerCase();
        final legacyPadKey =
            b.config['padKey']?.toString().trim().toLowerCase();
        final code = b.binding.code.trim().toLowerCase();
        return id == needle ||
            id.endsWith('_$needle') ||
            legacyPadKey == needle ||
            code == needle;
      },
      style: style,
    );
  }

  /// Creates a [VirtualControllerLayout] from a JSON map.
  factory VirtualControllerLayout.fromJson(Map<String, dynamic> json) {
    final controlsJson = json['controls'] as List? ?? [];
    return VirtualControllerLayout(
      schemaVersion: json['schemaVersion'] as int? ?? 1,
      name: json['name'] as String? ?? 'Untitled',
      controls: controlsJson
          .map((c) => VirtualControlFactory.fromJson(c as Map<String, dynamic>))
          .toList(),
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
          mode: 'gamepad',
          stickType: 'left',
        ),
        // Right Stick
        VirtualJoystick(
          id: 'rs',
          label: 'RS',
          layout: const ControlLayout(x: 0.7, y: 0.5, width: 0.2, height: 0.2),
          trigger: TriggerType.hold,
          mode: 'gamepad',
          stickType: 'right',
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

  /// Converts the layout to a JSON map.
  Map<String, dynamic> toJson() => {
        'schemaVersion': schemaVersion,
        'name': name,
        'controls': controls.map((c) => c.toJson()).toList(),
      };
}
