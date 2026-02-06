import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import '../action/control_action.dart';
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
    super.config,
    super.actions,
    super.style,
    super.feedback,
  }) : super(type: 'button');

  /// Creates a [VirtualButton] from a JSON map.
  factory VirtualButton.fromJson(Map<String, dynamic> json) {
    final actionsJson = json['actions'] as List? ?? [];
    return VirtualButton(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
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

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': config,
        'actions': actions.map((a) => a.toJson()).toList(),
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
