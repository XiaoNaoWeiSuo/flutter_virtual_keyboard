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
    this.axisId,
    this.dx,
    this.dy,
    this.delta,
    this.direction,
    this.activeKeys = const [],
    this.customId,
    this.customData = const {},
    this.modifiers = const [],
    this.delay = 0,
  });

  /// Creates a [MacroSequenceItem] from a JSON map.
  factory MacroSequenceItem.fromJson(Map<String, dynamic> json) {
    return MacroSequenceItem(
      type: json['type'] as String,
      key: json['key'] as String?,
      button: json['button'] as String?,
      axisId: json['axisId'] as String?,
      dx: (json['dx'] as num?)?.toDouble(),
      dy: (json['dy'] as num?)?.toDouble(),
      delta: json['delta'] as int?,
      direction: json['direction'] as String?,
      activeKeys: List<String>.from(json['activeKeys'] as List? ?? const []),
      customId: json['customId'] as String?,
      customData: json['customData'] is Map
          ? Map<String, dynamic>.from(json['customData'] as Map)
          : const {},
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

  /// The axis identifier (for gamepad axis actions).
  final String? axisId;

  /// The x component (for stick/axis actions).
  final double? dx;

  /// The y component (for stick/axis actions).
  final double? dy;

  /// Wheel delta (for mouse wheel actions).
  final int? delta;

  /// Wheel direction (up/down) or other direction identifiers.
  final String? direction;

  /// Active keys (for joystick-to-keys mapping).
  final List<String> activeKeys;

  /// Custom event id.
  final String? customId;

  /// Custom event payload.
  final Map<String, dynamic> customData;

  /// List of modifier keys.
  final List<String> modifiers;

  /// Delay in milliseconds before executing this step.
  final int delay;

  /// Converts the sequence item to a JSON map.
  Map<String, dynamic> toJson() => {
        'type': type,
        if (key != null) 'key': key,
        if (button != null) 'button': button,
        if (axisId != null) 'axisId': axisId,
        if (dx != null) 'dx': dx,
        if (dy != null) 'dy': dy,
        if (delta != null) 'delta': delta,
        if (direction != null) 'direction': direction,
        if (activeKeys.isNotEmpty) 'activeKeys': activeKeys,
        if (customId != null) 'customId': customId,
        if (customData.isNotEmpty) 'customData': customData,
        if (modifiers.isNotEmpty) 'modifiers': modifiers,
        if (delay > 0) 'delay': delay,
      };
}
