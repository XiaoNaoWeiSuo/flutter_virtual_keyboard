part of 'binding.dart';

sealed class InputBinding {
  const InputBinding();

  String get code;

  Map<String, dynamic> toJson();

  static InputBinding fromJson(Object json) {
    if (json is! Map) {
      throw const FormatException('InputBinding json must be a Map');
    }
    final map = Map<String, dynamic>.from(json);
    final type = map['type']?.toString().trim().toLowerCase();
    switch (type) {
      case 'keyboard':
        return KeyboardBinding.fromJson(map);
      case 'gamepad_button':
        return GamepadButtonBinding.fromJson(map);
    }
    throw FormatException('Unknown InputBinding type: $type');
  }

  static InputBinding? tryFromJson(Object? json) {
    if (json == null) return null;
    try {
      return fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

class KeyboardBinding extends InputBinding {
  const KeyboardBinding({
    required this.key,
    this.modifiers = const [],
    this.repeat = false,
  });

  factory KeyboardBinding.fromJson(Map<String, dynamic> json) {
    final keyStr = json['key']?.toString() ?? '';
    final modsRaw = json['modifiers'] as List? ?? const [];
    return KeyboardBinding(
      key: KeyboardKey(keyStr).normalized(),
      modifiers: modsRaw
          .map((e) => KeyboardKey(e?.toString() ?? '').normalized())
          .where((k) => k.code.trim().isNotEmpty)
          .toList(),
      repeat: json['repeat'] as bool? ?? false,
    );
  }

  final KeyboardKey key;
  final List<KeyboardKey> modifiers;
  final bool repeat;

  @override
  String get code => key.code;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'keyboard',
        'key': key.code,
        if (modifiers.isNotEmpty)
          'modifiers': modifiers.map((m) => m.code).toList(),
        if (repeat) 'repeat': true,
      };
}

class GamepadButtonBinding extends InputBinding {
  const GamepadButtonBinding(this.button);

  factory GamepadButtonBinding.fromJson(Map<String, dynamic> json) {
    final raw = json['button']?.toString() ?? '';
    final parsed = InputBindingRegistry.tryGetGamepadButton(raw);
    if (parsed == null) {
      throw FormatException('Unknown gamepad button: ${raw.trim()}');
    }
    return GamepadButtonBinding(parsed);
  }

  final GamepadButtonId button;

  @override
  String get code => button.code;

  @override
  Map<String, dynamic> toJson() => {
        'type': 'gamepad_button',
        'button': button.code,
      };
}
