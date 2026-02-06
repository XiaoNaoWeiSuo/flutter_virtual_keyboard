import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import 'virtual_control.dart';

/// Virtual Split Mouse Button Control.
///
/// A circular button split vertically into two halves.
/// Left half triggers left mouse button, right half triggers right mouse button.
class VirtualSplitMouse extends VirtualControl {
  /// Creates a virtual split mouse control.
  VirtualSplitMouse({
    required super.id,
    required super.label,
    required super.layout,
    required super.trigger,
    super.config,
    super.style,
    super.feedback,
  }) : super(type: 'split_mouse');

  /// Creates a [VirtualSplitMouse] from a JSON map.
  factory VirtualSplitMouse.fromJson(Map<String, dynamic> json) {
    return VirtualSplitMouse(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
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
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
