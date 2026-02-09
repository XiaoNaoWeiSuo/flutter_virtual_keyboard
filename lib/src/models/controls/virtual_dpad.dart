import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import '../action/control_action.dart';
import '../binding/binding.dart';
import 'virtual_control.dart';

enum DpadDirection { up, down, left, right }

/// Virtual D-Pad Control.
///
/// Directional pad with Up, Down, Left, Right inputs.
class VirtualDpad extends VirtualControl {
  /// Creates a virtual D-Pad.
  VirtualDpad({
    required super.id,
    required super.label,
    required super.layout,
    required super.trigger,
    super.config,
    super.actions,
    super.style,
    super.feedback,
    Map<DpadDirection, InputBinding>? directions,
    this.enable3D = false,
  })  : directions = directions ??
            const {
              DpadDirection.up: KeyboardBinding(key: KeyboardKey('ArrowUp')),
              DpadDirection.down:
                  KeyboardBinding(key: KeyboardKey('ArrowDown')),
              DpadDirection.left:
                  KeyboardBinding(key: KeyboardKey('ArrowLeft')),
              DpadDirection.right:
                  KeyboardBinding(key: KeyboardKey('ArrowRight')),
            },
        super(type: 'dpad');

  /// Creates a [VirtualDpad] from a JSON map.
  factory VirtualDpad.fromJson(Map<String, dynamic> json) {
    final actionsJson = json['actions'] as List? ?? [];
    final configMap = Map<String, dynamic>.from(json['config'] as Map? ?? {});

    Map<DpadDirection, InputBinding>? directions;
    final bindingsRaw = configMap['bindings'];
    if (bindingsRaw is Map) {
      final map = Map<String, dynamic>.from(bindingsRaw);
      final resolved = <DpadDirection, InputBinding>{};
      for (final entry in map.entries) {
        final dir = tryParseDpadDirection(entry.key);
        if (dir == null) {
          throw FormatException('Unknown dpad direction: ${entry.key}');
        }
        final value = entry.value;
        if (value == null) {
          throw FormatException(
              'Missing binding for dpad direction: ${entry.key}');
        }
        resolved[dir] = InputBinding.fromJson(value);
      }
      if (resolved.isNotEmpty) directions = resolved;
    }

    final legacyDirectionsRaw = configMap['directions'];
    if (directions == null && legacyDirectionsRaw is Map) {
      final legacy = Map<String, dynamic>.from(legacyDirectionsRaw);
      final mode = configMap['mode']?.toString().trim().toLowerCase();
      final resolved = <DpadDirection, InputBinding>{};
      for (final entry in legacy.entries) {
        final dir = tryParseDpadDirection(entry.key);
        if (dir == null) continue;
        final raw = entry.value?.toString() ?? '';
        if (mode == 'gamepad') {
          final parsed = raw.trim().isEmpty
              ? null
              : InputBindingRegistry.tryGetGamepadButton(raw);
          final button = parsed ??
              switch (dir) {
                DpadDirection.up => GamepadButtonId.dpadUp,
                DpadDirection.down => GamepadButtonId.dpadDown,
                DpadDirection.left => GamepadButtonId.dpadLeft,
                DpadDirection.right => GamepadButtonId.dpadRight,
              };
          resolved[dir] = GamepadButtonBinding(button);
        } else {
          resolved[dir] = KeyboardBinding(key: KeyboardKey(raw).normalized());
        }
      }
      if (resolved.isNotEmpty) directions = resolved;
    }

    return VirtualDpad(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: configMap,
      actions: actionsJson
          .map((a) => ControlAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      directions: directions,
      enable3D: configMap['enable3D'] as bool? ?? false,
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  final Map<DpadDirection, InputBinding> directions;

  /// Whether to enable 3D rendering (shader).
  final bool enable3D;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': {
          ...config,
          'bindings': directions.map((k, v) => MapEntry(k.name, v.toJson())),
          'enable3D': enable3D,
        },
        'actions': actions.map((a) => a.toJson()).toList(),
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}

DpadDirection? tryParseDpadDirection(String raw) {
  final lower = raw.trim().toLowerCase();
  return switch (lower) {
    'up' => DpadDirection.up,
    'down' => DpadDirection.down,
    'left' => DpadDirection.left,
    'right' => DpadDirection.right,
    _ => null,
  };
}
