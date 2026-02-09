import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import '../action/control_action.dart';
import '../binding/binding.dart';
import 'virtual_control.dart';

/// Virtual Button Control.
///
/// Generic button that can map to keyboard keys or gamepad buttons.
class VirtualButton extends VirtualControl {
  /// Creates a virtual button.
  VirtualButton({
    required super.id,
    required super.label,
    required super.layout,
    required super.trigger,
    required this.binding,
    super.config,
    super.actions,
    super.style,
    super.feedback,
  }) : super(type: 'button');

  VirtualButton copyWith({
    String? id,
    String? label,
    ControlLayout? layout,
    TriggerType? trigger,
    InputBinding? binding,
    Map<String, dynamic>? config,
    List<ControlAction>? actions,
    ControlStyle? style,
    ControlFeedback? feedback,
  }) {
    return VirtualButton(
      id: id ?? this.id,
      label: label ?? this.label,
      layout: layout ?? this.layout,
      trigger: trigger ?? this.trigger,
      binding: binding ?? this.binding,
      config: config ?? this.config,
      actions: actions ?? this.actions,
      style: style ?? this.style,
      feedback: feedback ?? this.feedback,
    );
  }

  /// Creates a [VirtualButton] from a JSON map.
  factory VirtualButton.fromJson(Map<String, dynamic> json) {
    final actionsJson = json['actions'] as List? ?? [];
    final config = Map<String, dynamic>.from(json['config'] as Map? ?? {});

    final bindingJson = json['binding'];
    final binding = bindingJson != null
        ? InputBinding.fromJson(bindingJson)
        : _legacyBinding(config);
    return VirtualButton(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      binding: binding,
      config: config,
      actions: actionsJson
          .map((a) => ControlAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  static InputBinding _legacyBinding(Map<String, dynamic> config) {
    final fromConfig =
        config['padKey'] ?? config['button'] ?? config['gamepadButton'];

    final raw = fromConfig?.toString().trim() ?? '';
    if (raw.isEmpty) {
      throw const FormatException(
          'Legacy VirtualButton must provide config.padKey (or button/gamepadButton)');
    }
    return GamepadButtonBinding(GamepadButtonId.parse(raw));
  }

  final InputBinding binding;

  GamepadButtonId? get gamepadButtonOrNull {
    final b = binding;
    return b is GamepadButtonBinding ? b.button : null;
  }

  GamepadButtonId get gamepadButton {
    final v = gamepadButtonOrNull;
    if (v == null) {
      throw StateError('VirtualButton($id) is not a gamepad button');
    }
    return v;
  }

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': config,
        'actions': actions.map((a) => a.toJson()).toList(),
        'binding': binding.toJson(),
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
