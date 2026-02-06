/// Feedback configuration for a control.
///
/// Defines the haptic feedback behavior when interacting with a control.
class ControlFeedback {
  /// Creates a feedback configuration.
  const ControlFeedback({
    this.vibration = false,
    this.vibrationType =
        'light', // light, medium, heavy, selection, success, error
  });

  /// Creates a [ControlFeedback] from a JSON map.
  factory ControlFeedback.fromJson(Map<String, dynamic> json) {
    return ControlFeedback(
      vibration: json['vibration'] as bool? ?? false,
      vibrationType: json['vibrationType'] as String? ?? 'light',
    );
  }

  /// Whether vibration is enabled.
  final bool vibration;

  /// The type of vibration feedback.
  ///
  /// Supported values: 'light', 'medium', 'heavy', 'selection', 'success', 'error'.
  final String vibrationType;

  /// Converts the feedback configuration to a JSON map.
  Map<String, dynamic> toJson() => {
        'vibration': vibration,
        'vibrationType': vibrationType,
      };
}
