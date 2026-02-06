/// Action definition within a control.
class ControlAction {
  /// Creates a control action.
  const ControlAction({
    required this.id,
    required this.inputType,
    required this.config,
  });

  /// Creates a [ControlAction] from a JSON map.
  factory ControlAction.fromJson(Map<String, dynamic> json) {
    return ControlAction(
      id: json['id'] as String? ?? '',
      inputType: json['inputType'] as String? ?? 'keyboard',
      config: Map<String, dynamic>.from(json['config'] as Map? ?? {}),
    );
  }

  /// The action identifier.
  final String id;

  /// The input type (e.g., 'keyboard', 'gamepad').
  final String inputType;

  /// Configuration for the action.
  final Map<String, dynamic> config;

  /// Converts the action to a JSON map.
  Map<String, dynamic> toJson() => {
        'id': id,
        'inputType': inputType,
        'config': config,
      };
}

/// Single step in a macro sequence.
class MacroSequenceItem {
  /// Creates a macro sequence item.
  const MacroSequenceItem({
    required this.type,
    this.key,
    this.button,
    this.modifiers = const [],
    this.delay = 0,
  });

  /// Creates a [MacroSequenceItem] from a JSON map.
  factory MacroSequenceItem.fromJson(Map<String, dynamic> json) {
    return MacroSequenceItem(
      type: json['type'] as String,
      key: json['key'] as String?,
      button: json['button'] as String?,
      modifiers: List<String>.from(json['modifiers'] as List? ?? []),
      delay: json['delay'] as int? ?? 0,
    );
  }

  /// The type of action (key_down, key_up, mouse_down, mouse_up).
  final String type;

  /// The key code (for keyboard actions).
  final String? key;

  /// The button code (for mouse/gamepad actions).
  final String? button;

  /// List of modifier keys.
  final List<String> modifiers;

  /// Delay in milliseconds before executing this step.
  final int delay;

  /// Converts the sequence item to a JSON map.
  Map<String, dynamic> toJson() => {
        'type': type,
        if (key != null) 'key': key,
        if (button != null) 'button': button,
        if (modifiers.isNotEmpty) 'modifiers': modifiers,
        if (delay > 0) 'delay': delay,
      };
}
