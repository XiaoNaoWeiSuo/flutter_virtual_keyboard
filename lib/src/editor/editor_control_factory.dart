import 'package:flutter/material.dart';
import '../models/virtual_controller_models.dart';

class EditorControlFactory {
  static const ControlStyle _wasdStickStyle = ControlStyle(
    shape: BoxShape.circle,
    borderColor: Color(0xFF4DA3FF),
    pressedBorderColor: Color(0xFF9BD0FF),
    borderWidth: 2.0,
    color: Color(0x263A3A3C),
    pressedColor: Color(0x334A4A4C),
    pressedOpacity: 1.0,
  );

  static const ControlStyle _arrowsStickStyle = ControlStyle(
    shape: BoxShape.circle,
    borderColor: Color(0xFF66D19E),
    pressedBorderColor: Color(0xFFB1F2D1),
    borderWidth: 2.0,
    color: Color(0x263A3A3C),
    pressedColor: Color(0x334A4A4C),
    pressedOpacity: 1.0,
  );

  static const ControlStyle _gamepadLeftStickStyle = ControlStyle(
    shape: BoxShape.circle,
    borderColor: Color(0xFFFFCC00),
    pressedBorderColor: Color(0xFFFFE27A),
    borderWidth: 2.0,
    color: Color(0x263A3A3C),
    pressedColor: Color(0x334A4A4C),
    pressedOpacity: 1.0,
  );

  static const ControlStyle _gamepadRightStickStyle = ControlStyle(
    shape: BoxShape.circle,
    borderColor: Color(0xFFFF7A45),
    pressedBorderColor: Color(0xFFFFB394),
    borderWidth: 2.0,
    color: Color(0x263A3A3C),
    pressedColor: Color(0x334A4A4C),
    pressedOpacity: 1.0,
  );
  static VirtualKey key(String label, {ControlLayout? layout}) {
    final (key, normalizedLabel, modifiers) = _normalizeKey(label);
    return keyWith(
      key: key,
      label: normalizedLabel,
      modifiers: modifiers,
      layout: layout,
    );
  }

  static VirtualKey keyWith({
    required KeyboardKey key,
    required String label,
    List<KeyboardKey> modifiers = const [],
    ControlLayout? layout,
  }) {
    return VirtualKey(
      id: 'key_${DateTime.now().microsecondsSinceEpoch}',
      label: label,
      layout: layout ?? _keyboardInitialLayoutFor(label),
      trigger: TriggerType.tap,
      config: const {},
      binding: KeyboardBinding(key: key, modifiers: modifiers),
    );
  }

  static VirtualMouseButton mouseButton(String button,
      {ControlLayout? layout}) {
    return VirtualMouseButton(
      id: 'mouse_${button}_${DateTime.now().microsecondsSinceEpoch}',
      label: button,
      layout: layout ??
          const ControlLayout(x: 0.75, y: 0.65, width: 0.1, height: 0.15),
      trigger: button == 'right' ? TriggerType.hold : TriggerType.tap,
      button: button,
      config: {},
    );
  }

  static VirtualSplitMouse splitMouse({ControlLayout? layout}) {
    return VirtualSplitMouse(
      id: 'split_mouse_${DateTime.now().microsecondsSinceEpoch}',
      label: '',
      layout: layout ??
          const ControlLayout(x: 0.7, y: 0.65, width: 0.22, height: 0.20),
      trigger: TriggerType.hold,
      config: {},
    );
  }

  static VirtualMouseWheel mouseWheel(String direction,
      {ControlLayout? layout}) {
    return VirtualMouseWheel(
      id: 'wheel_${direction}_${DateTime.now().microsecondsSinceEpoch}',
      label: direction == 'up' ? '滑轮上' : '滑轮下',
      layout: layout ??
          const ControlLayout(x: 0.8, y: 0.5, width: 0.1, height: 0.15),
      trigger: TriggerType.tap,
      direction: direction,
      config: {'inputType': 'mouse_wheel'},
    );
  }

  static VirtualJoystick joystickWASD({ControlLayout? layout}) {
    return VirtualJoystick(
      id: 'joystick_wasd_${DateTime.now().microsecondsSinceEpoch}',
      label: '',
      layout: layout ??
          const ControlLayout(x: 0.1, y: 0.6, width: 0.18, height: 0.28),
      trigger: TriggerType.hold,
      keys: const [
        KeyboardKey('W'),
        KeyboardKey('A'),
        KeyboardKey('S'),
        KeyboardKey('D'),
      ],
      style: _wasdStickStyle,
      feedback: const ControlFeedback(vibration: true, vibrationType: 'medium'),
      config: const {
        'overlayLabels': ['W', 'A', 'S', 'D'],
        'overlayStyle': 'quadrant',
      },
    );
  }

  static VirtualJoystick joystickArrows({ControlLayout? layout}) {
    return VirtualJoystick(
      id: 'joystick_arrows_${DateTime.now().microsecondsSinceEpoch}',
      label: '',
      layout: layout ??
          const ControlLayout(x: 0.1, y: 0.6, width: 0.18, height: 0.28),
      trigger: TriggerType.hold,
      keys: const [
        KeyboardKey('ArrowUp'),
        KeyboardKey('ArrowLeft'),
        KeyboardKey('ArrowDown'),
        KeyboardKey('ArrowRight'),
      ],
      style: _arrowsStickStyle,
      feedback: const ControlFeedback(vibration: true, vibrationType: 'medium'),
      config: const {
        'overlayLabels': ['↑', '←', '↓', '→'],
        'overlayStyle': 'quadrant',
      },
    );
  }

  static VirtualJoystick gamepadLeftStick({ControlLayout? layout}) {
    return VirtualJoystick(
      id: 'joystick_gamepad_left_${DateTime.now().microsecondsSinceEpoch}',
      label: 'LS',
      layout: layout ??
          const ControlLayout(x: 0.1, y: 0.6, width: 0.18, height: 0.28),
      trigger: TriggerType.hold,
      mode: 'gamepad',
      stickType: 'left',
      style: _gamepadLeftStickStyle,
      feedback: const ControlFeedback(vibration: true, vibrationType: 'medium'),
      config: const {
        'centerLabel': 'L',
        'overlayStyle': 'center',
      },
    );
  }

  static VirtualJoystick gamepadRightStick({ControlLayout? layout}) {
    return VirtualJoystick(
      id: 'joystick_gamepad_right_${DateTime.now().microsecondsSinceEpoch}',
      label: 'RS',
      layout: layout ??
          const ControlLayout(x: 0.1, y: 0.6, width: 0.18, height: 0.28),
      trigger: TriggerType.hold,
      mode: 'gamepad',
      stickType: 'right',
      style: _gamepadRightStickStyle,
      feedback: const ControlFeedback(vibration: true, vibrationType: 'medium'),
      config: const {
        'centerLabel': 'R',
        'overlayStyle': 'center',
      },
    );
  }

  static VirtualScrollStick scrollStick({ControlLayout? layout}) {
    return VirtualScrollStick(
      id: 'scroll_stick_${DateTime.now().microsecondsSinceEpoch}',
      label: '',
      layout: layout ??
          const ControlLayout(x: 0.82, y: 0.50, width: 0.12, height: 0.30),
      trigger: TriggerType.hold,
      feedback:
          const ControlFeedback(vibration: true, vibrationType: 'selection'),
      config: const {},
    );
  }

  static VirtualDpad dpad({ControlLayout? layout}) {
    return VirtualDpad(
      id: 'dpad_${DateTime.now().microsecondsSinceEpoch}',
      label: '',
      layout: layout ??
          const ControlLayout(x: 0.12, y: 0.6, width: 0.20, height: 0.20),
      trigger: TriggerType.hold,
      enable3D: true,
      directions: const {
        DpadDirection.up: GamepadButtonBinding(GamepadButtonId.dpadUp),
        DpadDirection.down: GamepadButtonBinding(GamepadButtonId.dpadDown),
        DpadDirection.left: GamepadButtonBinding(GamepadButtonId.dpadLeft),
        DpadDirection.right: GamepadButtonBinding(GamepadButtonId.dpadRight),
      },
      config: {},
    );
  }

  static VirtualButton gamepadButton(String label, {ControlLayout? layout}) {
    final parsed = GamepadButtonId.parse(label);
    return VirtualButton(
      id: 'btn_${parsed.code}_${DateTime.now().microsecondsSinceEpoch}',
      label: label,
      layout: layout ??
          const ControlLayout(x: 0.75, y: 0.55, width: 0.12, height: 0.12),
      trigger: TriggerType.hold,
      binding: GamepadButtonBinding(parsed),
      actions: const [],
      config: const {},
    );
  }

  static ControlLayout _keyboardInitialLayoutFor(String label) {
    const base = Size(0.06, 0.09);
    final flex = switch (label) {
      'Backspace' => 2,
      'Tab' => 2,
      'CapsLock' => 2,
      'Enter' => 2,
      'Shift' => 2,
      'Space' => 6,
      _ => 1,
    };
    return ControlLayout(
      x: 0.1,
      y: 0.8,
      width: base.width * flex,
      height: base.height,
    );
  }

  static (KeyboardKey key, String label, List<KeyboardKey> modifiers)
      _normalizeKey(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return (const KeyboardKey(''), '', const []);
    }

    KeyboardKey? normalizeMod(String s) {
      final lower = s.toLowerCase();
      return switch (lower) {
        'shift' => const KeyboardKey('Shift'),
        'ctrl' || 'control' => const KeyboardKey('Ctrl'),
        'alt' => const KeyboardKey('Alt'),
        'meta' || 'cmd' || 'win' => const KeyboardKey('Meta'),
        _ => null,
      };
    }

    if (trimmed.contains('+')) {
      final parts = trimmed
          .split('+')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.length >= 2) {
        final mods = <KeyboardKey>[];
        for (final m in parts.take(parts.length - 1)) {
          final normalized = normalizeMod(m);
          if (normalized != null) mods.add(normalized);
        }
        final last = parts.last;
        final (key, label, _) = _normalizeKey(last);
        return (key, trimmed, mods);
      }
    }

    if (trimmed == '~') {
      return (const KeyboardKey('`'), '~', const [KeyboardKey('Shift')]);
    }

    return switch (trimmed) {
      'Caps' => (const KeyboardKey('CapsLock'), 'CapsLock', const []),
      'Win' => (const KeyboardKey('Meta'), 'Win', const []),
      '↑' => (const KeyboardKey('ArrowUp'), '↑', const []),
      '↓' => (const KeyboardKey('ArrowDown'), '↓', const []),
      '←' => (const KeyboardKey('ArrowLeft'), '←', const []),
      '→' => (const KeyboardKey('ArrowRight'), '→', const []),
      _ => (KeyboardKey(trimmed).normalized(), trimmed, const []),
    };
  }
}
