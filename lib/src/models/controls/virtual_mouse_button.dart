import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import 'virtual_control.dart';

/// Virtual Mouse Button Control.
///
/// Simulates mouse clicks (left, right, middle).
class VirtualMouseButton extends VirtualControl {
  /// Creates a virtual mouse button.
  VirtualMouseButton({
    required super.id,
    required super.label,
    required super.layout,
    required super.trigger,
    super.config,
    super.style,
    super.feedback,
    required this.button,
    this.clickType = 'single', // single, double, hold
  }) : super(type: 'mouse_button');

  /// Creates a [VirtualMouseButton] from a JSON map.
  factory VirtualMouseButton.fromJson(Map<String, dynamic> json) {
    final config = Map<String, dynamic>.from(json['config'] as Map? ?? {});
    return VirtualMouseButton(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: config,
      button: config['button'] as String? ?? 'left',
      clickType: config['clickType'] as String? ?? 'single',
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  /// The mouse button (left, right, middle).
  final String button;

  /// The click type (single, double, hold).
  final String clickType;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': {
          ...config,
          'button': button,
          'clickType': clickType,
        },
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
