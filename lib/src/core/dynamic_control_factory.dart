import '../models/virtual_controller_models.dart';

VirtualControl? dynamicControlFromId(
  String id,
  ControlLayout layout, {
  required bool runtimeDefaults,
}) {
  if (id.startsWith('macro_')) {
    return VirtualMacroButton(
      id: id,
      label: 'Macro',
      layout: layout,
      trigger: TriggerType.tap,
      config: const {},
      sequence: const [],
    );
  }
  if (id.startsWith('btn_')) {
    final parts = id.split('_');
    if (parts.length >= 2) {
      final code = parts[1];
      final btn = InputBindingRegistry.tryGetGamepadButton(code) ??
          InputBindingRegistry.registerGamepadButton(code: code);
      return VirtualButton(
        id: id,
        label: btn.label ?? btn.code,
        layout: layout,
        trigger: TriggerType.hold,
        binding: GamepadButtonBinding(btn),
      );
    }
  }
  if (id.startsWith('mouse_')) {
    final parts = id.split('_');
    if (parts.length >= 2) {
      final button = parts[1];
      return VirtualMouseButton(
        id: id,
        label: button == 'middle' ? 'M' : button,
        layout: layout,
        trigger: button == 'right' ? TriggerType.hold : TriggerType.tap,
        button: button,
        config: const {},
      );
    }
  }
  if (id.startsWith('wheel_')) {
    final parts = id.split('_');
    if (parts.length >= 2) {
      final direction = parts[1];
      return VirtualMouseWheel(
        id: id,
        label: direction == 'up' ? '滑轮上' : '滑轮下',
        layout: layout,
        trigger: TriggerType.tap,
        direction: direction,
        config: const {'inputType': 'mouse_wheel'},
      );
    }
  }
  if (id.startsWith('split_mouse_')) {
    return VirtualSplitMouse(
      id: id,
      label: '',
      layout: layout,
      trigger: TriggerType.hold,
      config: const {},
    );
  }
  if (id.startsWith('scroll_stick_')) {
    return VirtualScrollStick(
      id: id,
      label: '',
      layout: layout,
      trigger: TriggerType.hold,
      config: const {},
    );
  }
  if (id.startsWith('dpad_')) {
    return VirtualDpad(
      id: id,
      label: '',
      layout: layout,
      trigger: TriggerType.hold,
      enable3D: false,
      directions: const {
        DpadDirection.up: GamepadButtonBinding(GamepadButtonId.dpadUp),
        DpadDirection.down: GamepadButtonBinding(GamepadButtonId.dpadDown),
        DpadDirection.left: GamepadButtonBinding(GamepadButtonId.dpadLeft),
        DpadDirection.right: GamepadButtonBinding(GamepadButtonId.dpadRight),
      },
      config: const {},
    );
  }
  if (id.startsWith('joystick_wasd_')) {
    return VirtualJoystick(
      id: id,
      label: '',
      layout: layout,
      trigger: TriggerType.hold,
      keys: const [
        KeyboardKey('W'),
        KeyboardKey('A'),
        KeyboardKey('S'),
        KeyboardKey('D'),
      ],
      config: const {
        'overlayLabels': ['W', 'A', 'S', 'D'],
        'overlayStyle': 'quadrant',
      },
    );
  }
  if (id.startsWith('joystick_arrows_')) {
    return VirtualJoystick(
      id: id,
      label: '',
      layout: layout,
      trigger: TriggerType.hold,
      keys: const [
        KeyboardKey('ArrowUp'),
        KeyboardKey('ArrowLeft'),
        KeyboardKey('ArrowDown'),
        KeyboardKey('ArrowRight'),
      ],
      config: const {
        'overlayLabels': ['↑', '←', '↓', '→'],
        'overlayStyle': 'quadrant',
      },
    );
  }
  if (id.startsWith('joystick_gamepad_left_')) {
    final config = runtimeDefaults
        ? const {
            'centerLabel': 'L',
            'overlayStyle': 'center',
            'stickClickEnabled': false,
            'stickLockEnabled': false,
          }
        : const {
            'centerLabel': 'L',
            'overlayStyle': 'center',
          };
    return VirtualJoystick(
      id: id,
      label: 'LS',
      layout: layout,
      trigger: TriggerType.hold,
      mode: 'gamepad',
      stickType: 'left',
      config: config,
    );
  }
  if (id.startsWith('joystick_gamepad_right_')) {
    final config = runtimeDefaults
        ? const {
            'centerLabel': 'R',
            'overlayStyle': 'center',
            'stickClickEnabled': false,
            'stickLockEnabled': false,
          }
        : const {
            'centerLabel': 'R',
            'overlayStyle': 'center',
          };
    return VirtualJoystick(
      id: id,
      label: 'RS',
      layout: layout,
      trigger: TriggerType.hold,
      mode: 'gamepad',
      stickType: 'right',
      config: config,
    );
  }
  if (id.startsWith('key_')) {
    final parts = id.split('_');
    if (parts.length >= 4) {
      final keyCode = Uri.decodeComponent(parts[1]);
      final modsRaw = parts[2];
      final modifiers = modsRaw == 'none'
          ? const <KeyboardKey>[]
          : Uri.decodeComponent(modsRaw)
              .split('+')
              .where((e) => e.trim().isNotEmpty)
              .map((e) => KeyboardKey(e).normalized())
              .toList(growable: false);
      final key = KeyboardKey(keyCode).normalized();
      return VirtualKey(
        id: id,
        label: key.code,
        layout: layout,
        trigger: TriggerType.tap,
        binding: KeyboardBinding(key: key, modifiers: modifiers),
        config: const {},
      );
    }
  }
  return null;
}

