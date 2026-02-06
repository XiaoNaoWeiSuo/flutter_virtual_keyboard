import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import 'virtual_control.dart';

/// Virtual Scroll Stick Control.
///
/// A vertical slider/joystick that simulates mouse wheel scrolling.
/// Sliding up scrolls up, sliding down scrolls down.
class VirtualScrollStick extends VirtualControl {
  /// Creates a virtual scroll stick.
  VirtualScrollStick({
    required super.id,
    required super.label,
    required super.layout,
    required super.trigger,
    super.config,
    super.style,
    super.feedback,
    this.sensitivity = 1.0,
  }) : super(type: 'scroll_stick');

  /// Creates a [VirtualScrollStick] from a JSON map.
  factory VirtualScrollStick.fromJson(Map<String, dynamic> json) {
    final config = Map<String, dynamic>.from(json['config'] as Map? ?? {});
    return VirtualScrollStick(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: config,
      sensitivity: (config['sensitivity'] as num?)?.toDouble() ?? 1.0,
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  /// Scroll sensitivity multiplier.
  final double sensitivity;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': {
          ...config,
          'sensitivity': sensitivity,
        },
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
