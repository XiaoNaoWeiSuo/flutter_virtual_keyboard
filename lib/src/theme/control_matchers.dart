import '../models/virtual_controller_models.dart';
import '../models/identifiers.dart';

typedef ControlPredicate = bool Function(VirtualControl control);

class ControlMatchers {
  static ControlPredicate idEquals(String id) {
    final needle = id.trim();
    return (c) => c.id.trim() == needle;
  }

  static ControlPredicate idStartsWith(String prefix) {
    final needle = prefix.trim();
    return (c) => c.id.startsWith(needle);
  }

  static ControlPredicate macroButton() => (c) => c is VirtualMacroButton;

  static ControlPredicate joystick({
    JoystickMode? mode,
    GamepadStickId? stick,
  }) {
    return (c) {
      if (c is! VirtualJoystick) return false;
      if (mode != null && c.mode != mode) return false;
      if (stick != null && c.stickType != stick) return false;
      return true;
    };
  }

  static ControlPredicate gamepadButtonId(GamepadButtonId id) {
    final needle = id.code.trim().toLowerCase();
    return (c) {
      if (c is! VirtualButton) return false;
      return c.binding.code.trim().toLowerCase() == needle;
    };
  }

  static ControlPredicate keyboardKey(KeyboardKey key) {
    final needle = key.normalized().code.trim();
    return (c) {
      if (c is! VirtualKey) return false;
      return c.binding.key.code.trim() == needle;
    };
  }
}
