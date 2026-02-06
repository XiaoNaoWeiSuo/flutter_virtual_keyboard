import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import '../action/control_action.dart';
import 'virtual_control.dart';

/// Virtual Macro Button Control.
///
/// Executes a sequence of actions when triggered.
class VirtualMacroButton extends VirtualControl {
  /// Creates a virtual macro button.
  VirtualMacroButton({
    required super.id,
    required super.label,
    required super.layout,
    required super.trigger,
    super.config,
    super.style,
    super.feedback,
    required this.sequence,
  }) : super(type: 'macro_button');

  /// Creates a [VirtualMacroButton] from a JSON map.
  factory VirtualMacroButton.fromJson(Map<String, dynamic> json) {
    final config = Map<String, dynamic>.from(json['config'] as Map? ?? {});
    final sequenceJson = config['sequence'] as List? ?? [];

    return VirtualMacroButton(
      id: json['id'] as String,
      label: json['label'] as String? ?? '',
      layout: ControlLayout.fromJson(json['layout'] as Map<String, dynamic>),
      trigger: parseTriggerType(json['trigger'] as String?),
      config: config,
      sequence: sequenceJson
          .map((s) => MacroSequenceItem.fromJson(s as Map<String, dynamic>))
          .toList(),
      style: json['style'] != null
          ? ControlStyle.fromJson(json['style'] as Map<String, dynamic>)
          : null,
      feedback: json['feedback'] != null
          ? ControlFeedback.fromJson(json['feedback'] as Map<String, dynamic>)
          : null,
    );
  }

  /// The sequence of actions to execute.
  final List<MacroSequenceItem> sequence;

  @override
  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'label': label,
        'layout': layout.toJson(),
        'trigger': triggerTypeToString(trigger),
        'config': {
          ...config,
          'sequence': sequence.map((s) => s.toJson()).toList(),
        },
        if (style != null) 'style': style!.toJson(),
        if (feedback != null) 'feedback': feedback!.toJson(),
      };
}
