String _norm(String raw) => raw.trim().toLowerCase();

enum MouseButtonId {
  left('left'),
  right('right'),
  middle('middle');

  const MouseButtonId(this.code);
  final String code;

  static MouseButtonId parse(String raw) {
    final v = _norm(raw);
    return switch (v) {
      'left' => MouseButtonId.left,
      'right' => MouseButtonId.right,
      'middle' || 'mid' => MouseButtonId.middle,
      _ => throw FormatException('Unknown mouse button: ${raw.trim()}'),
    };
  }

  static MouseButtonId? tryParse(String raw) {
    try {
      return parse(raw);
    } catch (_) {
      return null;
    }
  }
}

enum MouseWheelDirection {
  up('up'),
  down('down');

  const MouseWheelDirection(this.code);
  final String code;

  static MouseWheelDirection parse(String raw) {
    final v = _norm(raw);
    return switch (v) {
      'up' => MouseWheelDirection.up,
      'down' => MouseWheelDirection.down,
      _ => throw FormatException('Unknown wheel direction: ${raw.trim()}'),
    };
  }

  static MouseWheelDirection? tryParse(String raw) {
    try {
      return parse(raw);
    } catch (_) {
      return null;
    }
  }
}

enum JoystickMode {
  keyboard('keyboard'),
  gamepad('gamepad');

  const JoystickMode(this.code);
  final String code;

  static JoystickMode parse(String raw) {
    final v = _norm(raw);
    return switch (v) {
      'keyboard' => JoystickMode.keyboard,
      'gamepad' => JoystickMode.gamepad,
      _ => throw FormatException('Unknown joystick mode: ${raw.trim()}'),
    };
  }

  static JoystickMode? tryParse(String raw) {
    try {
      return parse(raw);
    } catch (_) {
      return null;
    }
  }
}

enum GamepadStickId {
  left('left'),
  right('right');

  const GamepadStickId(this.code);
  final String code;

  static GamepadStickId parse(String raw) {
    final v = _norm(raw);
    return switch (v) {
      'left' => GamepadStickId.left,
      'right' => GamepadStickId.right,
      _ => throw FormatException('Unknown stick id: ${raw.trim()}'),
    };
  }

  static GamepadStickId? tryParse(String raw) {
    try {
      return parse(raw);
    } catch (_) {
      return null;
    }
  }
}

enum GamepadAxisId {
  leftX('left_x'),
  leftY('left_y'),
  rightX('right_x'),
  rightY('right_y');

  const GamepadAxisId(this.code);
  final String code;

  static GamepadAxisId parse(String raw) {
    final v = _norm(raw);
    return switch (v) {
      'left_x' => GamepadAxisId.leftX,
      'left_y' => GamepadAxisId.leftY,
      'right_x' => GamepadAxisId.rightX,
      'right_y' => GamepadAxisId.rightY,
      _ => throw FormatException('Unknown axis id: ${raw.trim()}'),
    };
  }

  static GamepadAxisId? tryParse(String raw) {
    try {
      return parse(raw);
    } catch (_) {
      return null;
    }
  }
}

