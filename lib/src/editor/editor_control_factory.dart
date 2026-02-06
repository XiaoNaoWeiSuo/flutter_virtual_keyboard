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
    final (key, normalizedLabel) = _normalizeKey(label);
    return VirtualKey(
      id: 'key_${DateTime.now().microsecondsSinceEpoch}',
      label: normalizedLabel,
      layout: layout ?? _keyboardInitialLayoutFor(normalizedLabel),
      trigger: TriggerType.tap,
      config: {},
      key: key,
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
      keys: const ['W', 'A', 'S', 'D'],
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
      keys: const ['↑', '←', '↓', '→'],
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

  static VirtualControl? customSignal(String raw, {ControlLayout? layout}) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final lower = trimmed.toLowerCase();

    if (lower.startsWith('key:')) {
      final v = trimmed.substring(4).trim();
      if (v.isEmpty) return null;
      return key(v, layout: layout);
    }

    if (lower.startsWith('mouse:')) {
      final v = trimmed.substring(6).trim().toLowerCase();
      if (v != 'left' && v != 'right' && v != 'middle') return null;
      return mouseButton(v, layout: layout);
    }

    if (lower.startsWith('wheel:')) {
      final v = trimmed.substring(6).trim().toLowerCase();
      if (v != 'up' && v != 'down') return null;
      return mouseWheel(v, layout: layout);
    }

    if (lower.startsWith('gamepad:') || lower.startsWith('pad:')) {
      final v = trimmed.contains(':')
          ? trimmed.substring(trimmed.indexOf(':') + 1).trim()
          : '';
      if (v.isEmpty) return null;
      return gamepadButton(v, layout: layout);
    }

    return key(trimmed, layout: layout);
  }

  static VirtualDpad dpad({ControlLayout? layout}) {
    return VirtualDpad(
      id: 'dpad_${DateTime.now().microsecondsSinceEpoch}',
      label: '',
      layout: layout ??
          const ControlLayout(x: 0.12, y: 0.6, width: 0.20, height: 0.20),
      trigger: TriggerType.hold,
      mode: 'gamepad',
      enable3D: true,
      directions: const {
        'up': 'dpad_up',
        'down': 'dpad_down',
        'left': 'dpad_left',
        'right': 'dpad_right',
      },
      config: {},
    );
  }

  static VirtualButton gamepadButton(String label, {ControlLayout? layout}) {
    final padKey = label.toLowerCase();
    return VirtualButton(
      id: 'btn_${padKey}_${DateTime.now().microsecondsSinceEpoch}',
      label: label,
      layout: layout ??
          const ControlLayout(x: 0.75, y: 0.55, width: 0.12, height: 0.12),
      trigger: TriggerType.hold,
      actions: const [],
      config: {'padKey': padKey},
    );
  }

  static ControlLayout _keyboardInitialLayoutFor(String label) {
    const base = Size(0.05, 0.08);
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

  static (String key, String label) _normalizeKey(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return ('', '');
    return switch (trimmed) {
      'Caps' => ('CapsLock', 'CapsLock'),
      'Win' => ('Meta', 'Win'),
      '↑' => ('ArrowUp', '↑'),
      '↓' => ('ArrowDown', '↓'),
      '←' => ('ArrowLeft', '←'),
      '→' => ('ArrowRight', '→'),
      _ => (trimmed, trimmed),
    };
  }
}
