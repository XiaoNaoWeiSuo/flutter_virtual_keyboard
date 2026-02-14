import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import '../action/control_action.dart';
import '../binding/binding.dart';
import '../identifiers.dart';
import 'virtual_control.dart';

/// Virtual Joystick Control.
///
/// Simulates a joystick or thumbstick, mapping to keyboard keys (WASD) or gamepad axes.
class VirtualJoystick extends VirtualControl {
  /// Creates a virtual joystick.
  VirtualJoystick({
    required super.id,
    required super.label,
    required super.layout,
    required super.trigger,
    super.config,
    super.actions,
    super.style,
    super.feedback,
    this.deadzone = 0.1,
    this.mode = JoystickMode.keyboard,
    this.stickType = GamepadStickId.left,
    this.keys = const [
      KeyboardKey('W'),
      KeyboardKey('A'),
      KeyboardKey('S'),
      KeyboardKey('D'),
    ], // Up, Left, Down, Right
    this.axes = const [GamepadAxisId.leftX, GamepadAxisId.leftY],
  }) : super(type: 'joystick');

  /// Creates a [VirtualJoystick] from a JSON map.
  factory VirtualJoystick.fromJson(Map<String, dynamic> json) {
    final config = Map<String, dynamic>.from(json['config'] as Map? ?? {});
    final actionsJson = json['actions'] as List? ?? [];
    final actions = actionsJson
        .map((a) => ControlAction.fromJson(a as Map<String, dynamic>))
        .toList();

    // Extract keys from actions if present
    List<String> keys = ['W', 'A', 'S', 'D'];
    if (config['keys'] != null) {
      keys = List<String>.from(config['keys'] as List);
    } else if (actions.isNotEmpty && actions.first.config['keys'] != null) {
      // Legacy support
      keys = List<String>.from(actions.first.config['keys'] as List);
    }

    final normalizedKeys =
        keys.map((k) => KeyboardKey(k).normalized()).toList(growable: false);

    return VirtualJoystick(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: config,
      actions: actions,
      deadzone: (config['deadzone'] as num?)?.toDouble() ?? 0.1,
      mode: config['mode'] is String
          ? (JoystickMode.tryParse(config['mode'] as String) ??
              JoystickMode.keyboard)
          : JoystickMode.keyboard,
      stickType: config['stickType'] is String
          ? (GamepadStickId.tryParse(config['stickType'] as String) ??
              GamepadStickId.left)
          : GamepadStickId.left,
      keys: normalizedKeys,
      axes: (config['axes'] as List? ?? const ['left_x', 'left_y'])
          .map((e) => e?.toString() ?? '')
          .map((raw) => GamepadAxisId.tryParse(raw))
          .whereType<GamepadAxisId>()
          .toList(growable: false),
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Deadzone threshold (0.0 - 1.0).
  final double deadzone;

  final JoystickMode mode;

  final GamepadStickId stickType;

  /// Keys mapped to Up, Left, Down, Right (Keyboard mode).
  final List<KeyboardKey> keys;

  final List<GamepadAxisId> axes;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': {
          ...config,
          'deadzone': deadzone,
          'mode': mode.code,
          'stickType': stickType.code,
          'keys': keys.map((k) => k.code).toList(),
          'axes': axes.map((a) => a.code).toList(),
        },
        'actions': actions.map((a) => a.toJson()).toList(),
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
