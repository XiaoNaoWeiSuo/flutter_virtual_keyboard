part of 'binding.dart';

class InputBindingRegistry {
  static final Map<String, GamepadButtonId> _gamepadButtonsByCode = {
    for (final b in GamepadButtonId.builtIns)
      normalizeGamepadButtonCode(b.code): b,
  };

  static bool isKnownGamepadButton(String code) {
    final normalized = normalizeGamepadButtonCode(code);
    return _gamepadButtonsByCode.containsKey(normalized);
  }

  static GamepadButtonId? tryGetGamepadButton(String code) {
    final normalized = normalizeGamepadButtonCode(code);
    return _gamepadButtonsByCode[normalized];
  }

  static GamepadButtonId registerGamepadButton({
    required String code,
    String? label,
  }) {
    final normalized = normalizeGamepadButtonCode(code);
    final existing = _gamepadButtonsByCode[normalized];
    if (existing != null) return existing;
    final created = GamepadButtonId._custom(normalized, label: label);
    _gamepadButtonsByCode[normalized] = created;
    return created;
  }

  static List<GamepadButtonId> get registeredGamepadButtons =>
      _gamepadButtonsByCode.values.toSet().toList()
        ..sort((a, b) => a.code.compareTo(b.code));
}
