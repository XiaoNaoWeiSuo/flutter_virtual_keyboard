import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import '../binding/binding.dart';
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
    required this.binding,
  }) : super(type: 'key');

  /// Creates a [VirtualKey] from a JSON map.
  factory VirtualKey.fromJson(Map<String, dynamic> json) {
    final config = Map<String, dynamic>.from(json['config'] as Map? ?? {});
    final bindingJson = json['binding'] ?? config['binding'];
    final fromNew =
        bindingJson != null ? InputBinding.fromJson(bindingJson) : null;
    final binding = fromNew is KeyboardBinding ? fromNew : null;
    if (fromNew != null && binding == null) {
      throw const FormatException('VirtualKey binding must be keyboard');
    }
    return VirtualKey(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: config,
      binding: binding ??
          KeyboardBinding(
            key: KeyboardKey(config['key'] as String? ?? '').normalized(),
            modifiers: (config['modifiers'] as List? ?? const [])
                .map((e) => KeyboardKey(e?.toString() ?? '').normalized())
                .where((k) => k.code.trim().isNotEmpty && k.code != 'null')
                .toList(),
            repeat: config['repeat'] as bool? ?? false,
          ),
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  final KeyboardBinding binding;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': {
          ...config,
          'binding': binding.toJson(),
        },
        'binding': binding.toJson(),
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
