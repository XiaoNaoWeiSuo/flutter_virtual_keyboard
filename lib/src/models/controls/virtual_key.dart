import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import 'virtual_control.dart';

/// Virtual Key Control.
///
/// Represents a single keyboard key.
class VirtualKey extends VirtualControl {
  /// Creates a virtual key.
  VirtualKey({
    required super.id,
    required super.label,
    required super.layout,
    required super.trigger,
    super.config,
    super.style,
    super.feedback,
    required this.key,
    this.modifiers = const [],
    this.repeat = false,
  }) : super(type: 'key');

  /// Creates a [VirtualKey] from a JSON map.
  factory VirtualKey.fromJson(Map<String, dynamic> json) {
    final config = Map<String, dynamic>.from(json['config'] as Map? ?? {});
    return VirtualKey(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: config,
      key: config['key'] as String? ?? '',
      modifiers: List<String>.from(config['modifiers'] as List? ?? []),
      repeat: config['repeat'] as bool? ?? false,
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  /// The key code.
  final String key;

  /// List of modifier keys (e.g., Shift, Ctrl).
  final List<String> modifiers;

  /// Whether the key should repeat when held down.
  final bool repeat;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': {
          ...config,
          'key': key,
          'modifiers': modifiers,
          'repeat': repeat,
        },
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
