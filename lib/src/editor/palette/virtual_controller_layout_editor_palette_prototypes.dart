part of '../virtual_controller_layout_editor_palette.dart';

List<VirtualControl> _prototypesFor(VirtualControllerEditorPaletteTab tab) {
  const dummy = ControlLayout(x: 0, y: 0, width: 0.1, height: 0.1);
  switch (tab) {
    case VirtualControllerEditorPaletteTab.keyboard:
      return [
        for (final row in _keyboardRows())
          for (final k in row)
            VirtualKey(
              id: 'kbd_${k.id}',
              label: k.label,
              layout: dummy,
              trigger: TriggerType.tap,
              config: const {},
              binding: KeyboardBinding(
                key: KeyboardKey(k.key).normalized(),
                modifiers: k.modifiers
                    .map((m) => KeyboardKey(m).normalized())
                    .toList(),
              ),
            ),
      ];
    case VirtualControllerEditorPaletteTab.mouseAndJoystick:
      return [
        VirtualMouseButton(
          id: 'mouse_middle',
          label: 'M',
          layout: dummy,
          trigger: TriggerType.tap,
          button: 'middle',
          config: const {},
        ),
        VirtualSplitMouse(
          id: 'mouse_split',
          label: '',
          layout: dummy,
          trigger: TriggerType.hold,
          config: const {},
        ),
        VirtualScrollStick(
          id: 'scroll_stick',
          label: '',
          layout: dummy,
          trigger: TriggerType.hold,
          config: const {},
        ),
        VirtualJoystick(
          id: 'joy_wasd',
          label: '',
          layout: dummy,
          trigger: TriggerType.hold,
          keys: const [
            KeyboardKey('W'),
            KeyboardKey('A'),
            KeyboardKey('S'),
            KeyboardKey('D'),
          ],
          style: const ControlStyle(
            shape: BoxShape.circle,
            borderColor: Color(0xFF4DA3FF),
            pressedBorderColor: Color(0xFF9BD0FF),
            borderWidth: 2.0,
            color: Color(0x263A3A3C),
            pressedColor: Color(0x334A4A4C),
            pressedOpacity: 1.0,
          ),
          feedback:
              const ControlFeedback(vibration: true, vibrationType: 'medium'),
          config: const {
            'overlayLabels': ['W', 'A', 'S', 'D'],
            'overlayStyle': 'quadrant',
          },
        ),
        VirtualJoystick(
          id: 'joy_arrows',
          label: '',
          layout: dummy,
          trigger: TriggerType.hold,
          keys: const [
            KeyboardKey('ArrowUp'),
            KeyboardKey('ArrowLeft'),
            KeyboardKey('ArrowDown'),
            KeyboardKey('ArrowRight'),
          ],
          style: const ControlStyle(
            shape: BoxShape.circle,
            borderColor: Color(0xFF66D19E),
            pressedBorderColor: Color(0xFFB1F2D1),
            borderWidth: 2.0,
            color: Color(0x263A3A3C),
            pressedColor: Color(0x334A4A4C),
            pressedOpacity: 1.0,
          ),
          feedback:
              const ControlFeedback(vibration: true, vibrationType: 'medium'),
          config: const {
            'overlayLabels': ['↑', '←', '↓', '→'],
            'overlayStyle': 'quadrant',
          },
        ),
        VirtualDpad(
          id: 'dpad',
          label: '',
          layout: dummy,
          trigger: TriggerType.hold,
          enable3D: false,
          directions: const {
            DpadDirection.up: GamepadButtonBinding(GamepadButtonId.dpadUp),
            DpadDirection.down: GamepadButtonBinding(GamepadButtonId.dpadDown),
            DpadDirection.left: GamepadButtonBinding(GamepadButtonId.dpadLeft),
            DpadDirection.right:
                GamepadButtonBinding(GamepadButtonId.dpadRight),
          },
          config: const {},
        ),
      ];
    case VirtualControllerEditorPaletteTab.macro:
      return [
        VirtualMacroButton(
          id: 'macro',
          label: 'Macro',
          layout: dummy,
          trigger: TriggerType.tap,
          config: const {},
          sequence: const [],
        ),
      ];
    case VirtualControllerEditorPaletteTab.xbox:
    case VirtualControllerEditorPaletteTab.ps:
      final isPs = tab == VirtualControllerEditorPaletteTab.ps;
      final face = isPs
          ? const ['Triangle', 'Circle', 'Square', 'Cross']
          : const ['A', 'B', 'X', 'Y'];
      final shoulders = isPs
          ? const ['L1', 'R1', 'L2', 'R2']
          : const ['LB', 'RB', 'LT', 'RT'];
      final sys = isPs
          ? const ['Options', 'Share', 'L3', 'R3']
          : const ['Start', 'Back', 'L3', 'R3'];
      final customButtons = InputBindingRegistry.registeredGamepadButtons
          .where((b) => !GamepadButtonId.builtIns.contains(b))
          .toList();
      return [
        for (final k in [...face, ...shoulders, ...sys])
          VirtualButton(
            id: 'pad_${k.toLowerCase()}',
            label: k,
            layout: dummy,
            trigger: TriggerType.hold,
            binding: GamepadButtonBinding(GamepadButtonId.parse(k)),
            config: const {},
          ),
        for (final b in customButtons)
          VirtualButton(
            id: 'pad_${b.code}',
            label: b.label ?? b.code,
            layout: dummy,
            trigger: TriggerType.hold,
            binding: GamepadButtonBinding(b),
            config: const {},
          ),
        VirtualDpad(
          id: 'pad_dpad',
          label: '',
          layout: dummy,
          trigger: TriggerType.hold,
          enable3D: true,
          directions: const {
            DpadDirection.up: GamepadButtonBinding(GamepadButtonId.dpadUp),
            DpadDirection.down: GamepadButtonBinding(GamepadButtonId.dpadDown),
            DpadDirection.left: GamepadButtonBinding(GamepadButtonId.dpadLeft),
            DpadDirection.right:
                GamepadButtonBinding(GamepadButtonId.dpadRight),
          },
          config: const {},
        ),
        VirtualJoystick(
          id: 'pad_ls',
          label: 'LS',
          layout: dummy,
          trigger: TriggerType.hold,
          mode: 'gamepad',
          stickType: 'left',
          style: const ControlStyle(
            shape: BoxShape.circle,
            borderColor: Color(0xFFFFCC00),
            pressedBorderColor: Color(0xFFFFE27A),
            borderWidth: 2.0,
            color: Color(0x263A3A3C),
            pressedColor: Color(0x334A4A4C),
            pressedOpacity: 1.0,
          ),
          feedback:
              const ControlFeedback(vibration: true, vibrationType: 'medium'),
          config: const {
            'centerLabel': 'L',
            'overlayStyle': 'center',
          },
        ),
        VirtualJoystick(
          id: 'pad_rs',
          label: 'RS',
          layout: dummy,
          trigger: TriggerType.hold,
          mode: 'gamepad',
          stickType: 'right',
          style: const ControlStyle(
            shape: BoxShape.circle,
            borderColor: Color(0xFFFF7A45),
            pressedBorderColor: Color(0xFFFFB394),
            borderWidth: 2.0,
            color: Color(0x263A3A3C),
            pressedColor: Color(0x334A4A4C),
            pressedOpacity: 1.0,
          ),
          feedback:
              const ControlFeedback(vibration: true, vibrationType: 'medium'),
          config: const {
            'centerLabel': 'R',
            'overlayStyle': 'center',
          },
        ),
      ];
  }
}

class _KeySpec {
  const _KeySpec(
    this.id,
    this.label,
    this.flex, {
    String? key,
    this.modifiers = const [],
  }) : key = key ?? label;
  final String id;
  final String label;
  final int flex;
  final String key;
  final List<String> modifiers;
}

List<List<_KeySpec>> _keyboardRows() {
  return const [
    [
      _KeySpec('f1', 'F1', 1),
      _KeySpec('f2', 'F2', 1),
      _KeySpec('f3', 'F3', 1),
      _KeySpec('f4', 'F4', 1),
      _KeySpec('f5', 'F5', 1),
      _KeySpec('f6', 'F6', 1),
      _KeySpec('f7', 'F7', 1),
      _KeySpec('f8', 'F8', 1),
      _KeySpec('f9', 'F9', 1),
      _KeySpec('f10', 'F10', 1),
      _KeySpec('f11', 'F11', 1),
      _KeySpec('f12', 'F12', 1),
    ],
    [
      _KeySpec('esc', 'Esc', 1),
      _KeySpec('tilde', '~', 1, key: '`', modifiers: ['Shift']),
      _KeySpec('1', '1', 1),
      _KeySpec('2', '2', 1),
      _KeySpec('3', '3', 1),
      _KeySpec('4', '4', 1),
      _KeySpec('5', '5', 1),
      _KeySpec('6', '6', 1),
      _KeySpec('7', '7', 1),
      _KeySpec('8', '8', 1),
      _KeySpec('9', '9', 1),
      _KeySpec('0', '0', 1),
      _KeySpec('minus', '-', 1),
      _KeySpec('equal', '=', 1),
      _KeySpec('backspace', 'Backspace', 2),
    ],
    [
      _KeySpec('tab', 'Tab', 2),
      _KeySpec('q', 'Q', 1),
      _KeySpec('w', 'W', 1),
      _KeySpec('e', 'E', 1),
      _KeySpec('r', 'R', 1),
      _KeySpec('t', 'T', 1),
      _KeySpec('y', 'Y', 1),
      _KeySpec('u', 'U', 1),
      _KeySpec('i', 'I', 1),
      _KeySpec('o', 'O', 1),
      _KeySpec('p', 'P', 1),
      _KeySpec('lbracket', '[', 1),
      _KeySpec('rbracket', ']', 1),
      _KeySpec('slash', '\\', 2),
    ],
    [
      _KeySpec('caps', 'CapsLock', 2),
      _KeySpec('a', 'A', 1),
      _KeySpec('s', 'S', 1),
      _KeySpec('d', 'D', 1),
      _KeySpec('f', 'F', 1),
      _KeySpec('g', 'G', 1),
      _KeySpec('h', 'H', 1),
      _KeySpec('j', 'J', 1),
      _KeySpec('k', 'K', 1),
      _KeySpec('l', 'L', 1),
      _KeySpec('semicolon', ';', 1),
      _KeySpec('quote', '\'', 1),
      _KeySpec('enter', 'Enter', 2),
    ],
    [
      _KeySpec('shift_l', 'Shift', 3),
      _KeySpec('z', 'Z', 1),
      _KeySpec('x', 'X', 1),
      _KeySpec('c', 'C', 1),
      _KeySpec('v', 'V', 1),
      _KeySpec('b', 'B', 1),
      _KeySpec('n', 'N', 1),
      _KeySpec('m', 'M', 1),
      _KeySpec('comma', ',', 1),
      _KeySpec('dot', '.', 1),
      _KeySpec('slash2', '/', 1),
      _KeySpec('shift_r', 'Shift', 3),
    ],
    [
      _KeySpec('ctrl', 'Ctrl', 2),
      _KeySpec('alt', 'Alt', 2),
      _KeySpec('win', 'Win', 2, key: 'Meta'),
      _KeySpec('space', 'Space', 8),
      _KeySpec('left', '←', 1, key: 'ArrowLeft'),
      _KeySpec('down', '↓', 1, key: 'ArrowDown'),
      _KeySpec('up', '↑', 1, key: 'ArrowUp'),
      _KeySpec('right', '→', 1, key: 'ArrowRight'),
    ],
    [
      _KeySpec('insert', 'Insert', 2),
      _KeySpec('delete', 'Delete', 2),
      _KeySpec('home', 'Home', 2),
      _KeySpec('end', 'End', 2),
      _KeySpec('pageup', 'PageUp', 2),
      _KeySpec('pagedown', 'PageDown', 2),
    ],
    [
      _KeySpec('vol_down', 'Vol-', 2, key: 'VolumeDown'),
      _KeySpec('vol_up', 'Vol+', 2, key: 'VolumeUp'),
      _KeySpec('mute', 'Mute', 2, key: 'AudioMute'),
      _KeySpec('prev', 'Prev', 2, key: 'AudioPrev'),
      _KeySpec('play', 'Play', 2, key: 'AudioPlay'),
      _KeySpec('next', 'Next', 2, key: 'AudioNext'),
    ],
  ];
}

