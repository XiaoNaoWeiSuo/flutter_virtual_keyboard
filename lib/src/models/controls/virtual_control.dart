import '../style/control_layout.dart';
import '../style/control_style.dart';
import '../style/control_feedback.dart';
import '../action/control_action.dart';

/// Trigger types for control interaction.
enum TriggerType {
  /// Trigger on tap.
  tap,

  /// Trigger on hold.
  hold,

  /// Trigger on double tap.
  doubleTap,
}

/// Helper to parse trigger type from string.
TriggerType parseTriggerType(String? value) {
  switch (value) {
    case 'hold':
      return TriggerType.hold;
    case 'double_tap':
      return TriggerType.doubleTap;
    case 'tap':
    default:
      return TriggerType.tap;
  }
}

/// Helper to convert trigger type to string.
String triggerTypeToString(TriggerType trigger) {
  switch (trigger) {
    case TriggerType.hold:
      return 'hold';
    case TriggerType.doubleTap:
      return 'double_tap';
    case TriggerType.tap:
      return 'tap';
  }
}

/// Abstract base class for all virtual controls.
abstract class VirtualControl {
  /// Creates a base virtual control.
  const VirtualControl({
    required this.id,
    required this.type,
    required this.label,
    required this.layout,
    required this.trigger,
    this.config = const {},
    this.actions = const [],
    this.style,
    this.feedback,
  });

  /// Unique identifier for the control.
  final String id;

  /// The type of control (e.g., 'button', 'joystick').
  final String type;

  /// Display label for the control.
  final String label;

  /// Layout configuration (position and size).
  final ControlLayout layout;

  /// Interaction trigger type.
  final TriggerType trigger;

  /// Additional configuration parameters.
  final Map<String, dynamic> config;

  /// List of actions associated with the control.
  final List<ControlAction> actions;

  /// Visual style configuration.
  final ControlStyle? style;

  /// Haptic feedback configuration.
  final ControlFeedback? feedback;

  /// Converts the control to a JSON map.
  Map<String, dynamic> toJson();
}
