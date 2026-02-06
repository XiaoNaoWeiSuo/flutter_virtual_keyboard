import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import '../action/control_action.dart';
import 'virtual_control.dart';

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
    Map<String, String>? directions,
    this.mode = 'keyboard', // keyboard, gamepad
    this.enable3D = false,
  })  : directions = directions ??
            {
              'up': 'ArrowUp',
              'down': 'ArrowDown',
              'left': 'ArrowLeft',
              'right': 'ArrowRight',
            },
        super(type: 'dpad');

  /// Creates a [VirtualDpad] from a JSON map.
  factory VirtualDpad.fromJson(Map<String, dynamic> json) {
    final actionsJson = json['actions'] as List? ?? [];
    final configMap = Map<String, dynamic>.from(json['config'] as Map? ?? {});

    // Parse directions from config
    Map<String, String>? directionsMap;
    if (configMap.containsKey('directions')) {
      directionsMap = Map<String, String>.from(configMap['directions'] as Map);
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
      directions: directionsMap,
      mode: configMap['mode'] as String? ?? 'keyboard',
      enable3D: configMap['enable3D'] as bool? ?? false,
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Mapping of directions (up, down, left, right) to key/button codes.
  final Map<String, String> directions;

  /// Input mode: 'keyboard' or 'gamepad'.
  final String mode;

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
          'directions': directions,
          'mode': mode,
          'enable3D': enable3D,
        },
        'actions': actions.map((a) => a.toJson()).toList(),
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
