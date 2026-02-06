import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import 'virtual_control.dart';

/// Virtual Mouse Wheel Control.
///
/// Simulates mouse wheel scrolling.
class VirtualMouseWheel extends VirtualControl {
  /// Creates a virtual mouse wheel.
  VirtualMouseWheel({
    required super.id,
    required super.label,
    required super.layout,
    required super.trigger,
    super.config,
    super.style,
    super.feedback,
    required this.direction,
    this.step = 3,
  }) : super(type: 'mouse_wheel');

  /// Creates a [VirtualMouseWheel] from a JSON map.
  factory VirtualMouseWheel.fromJson(Map<String, dynamic> json) {
    final config = Map<String, dynamic>.from(json['config'] as Map? ?? {});
    return VirtualMouseWheel(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: config,
      direction: config['direction'] as String? ?? 'up',
      step: config['step'] as int? ?? 3,
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  /// The scroll direction (up, down).
  final String direction;

  /// The number of lines/steps to scroll.
  final int step;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': {
          ...config,
          'direction': direction,
          'step': step,
        },
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
