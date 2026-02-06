import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import '../action/control_action.dart';
import 'virtual_control.dart';

/// Virtual Custom Control.
///
/// A control with arbitrary custom data for specialized use cases.
class VirtualCustomControl extends VirtualControl {
  /// Creates a virtual custom control.
  VirtualCustomControl({
    required super.id,
    required super.label,
    required super.layout,
    required super.trigger,
    super.config,
    super.actions,
    super.style,
    super.feedback,
    this.customData = const {},
  }) : super(type: 'custom');

  /// Creates a [VirtualCustomControl] from a JSON map.
  factory VirtualCustomControl.fromJson(Map<String, dynamic> json) {
    final actionsJson = json['actions'] as List? ?? [];
    return VirtualCustomControl(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
      actions: actionsJson
          .map((a) => ControlAction.fromJson(a as Map<String, dynamic>))
          .toList(),
      customData: Map<String, dynamic>.from(json['customData'] as Map? ?? {}),
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Custom data associated with the control.
  final Map<String, dynamic> customData;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': config,
        'actions': actions.map((a) => a.toJson()).toList(),
        'customData': customData,
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
