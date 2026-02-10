import 'package:flutter/material.dart';
import '../models/virtual_controller_models.dart';
import '../widgets/controls/button_widget.dart';
import '../widgets/controls/dpad_widget.dart';
import '../widgets/controls/joystick_widget.dart';
import '../widgets/controls/key_widget.dart';
import '../widgets/controls/mouse_button_widget.dart';
import '../widgets/controls/scroll_stick_widget.dart';
import '../widgets/controls/split_mouse_widget.dart';
import 'editor_control_factory.dart';
import 'editor_palette_tab.dart';

class VirtualControllerLayoutEditorPalette extends StatelessWidget {
  const VirtualControllerLayoutEditorPalette({
    super.key,
    required this.tab,
    required this.onAddControl,
    this.previewDecorator,
  });

  final VirtualControllerEditorPaletteTab tab;
  final ValueChanged<VirtualControl> onAddControl;
  final VirtualControllerLayout Function(VirtualControllerLayout layout)?
      previewDecorator;

  @override
  Widget build(BuildContext context) {
    final prototypes = _prototypesFor(tab);
    final previewMap = _decorate(prototypes);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SafeArea(
            top: false,
            bottom: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    (MediaQuery.of(context).size.width - 16).clamp(0, 720),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                        child: _Body(
                          tab: tab,
                          previewMap: previewMap,
                          onAddControl: onAddControl,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, VirtualControl> _decorate(List<VirtualControl> prototypes) {
    final decorator = previewDecorator;
    if (decorator == null) return {for (final c in prototypes) c.id: c};
    final layout = VirtualControllerLayout(
      schemaVersion: 1,
      name: 'palette',
      controls: prototypes,
    );
    final decorated = decorator(layout);
    return {for (final c in decorated.controls) c.id: c};
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.tab,
    required this.previewMap,
    required this.onAddControl,
  });

  final VirtualControllerEditorPaletteTab tab;
  final Map<String, VirtualControl> previewMap;
  final ValueChanged<VirtualControl> onAddControl;

  @override
  Widget build(BuildContext context) {
    return switch (tab) {
      VirtualControllerEditorPaletteTab.keyboard => _KeyboardPalette(
          previewMap: previewMap,
          onAdd: (k) => onAddControl(EditorControlFactory.keyWith(
              key: KeyboardKey(k.key).normalized(),
              label: k.label,
              modifiers: k.modifiers
                  .map((m) => KeyboardKey(m).normalized())
                  .toList())),
        ),
      VirtualControllerEditorPaletteTab.mouseAndJoystick =>
        _MouseJoystickPalette(
          previewMap: previewMap,
          onAdd: onAddControl,
        ),
      VirtualControllerEditorPaletteTab.xbox => _GamepadPalette(
          previewMap: previewMap,
          onAdd: (l) {
            switch (l) {
              case 'Dpad':
                onAddControl(EditorControlFactory.dpad());
              case 'LS':
                onAddControl(EditorControlFactory.gamepadLeftStick());
              case 'RS':
                onAddControl(EditorControlFactory.gamepadRightStick());
              default:
                onAddControl(EditorControlFactory.gamepadButton(l));
            }
          },
          isPs: false,
        ),
      VirtualControllerEditorPaletteTab.ps => _GamepadPalette(
          previewMap: previewMap,
          onAdd: (l) {
            switch (l) {
              case 'Dpad':
                onAddControl(EditorControlFactory.dpad());
              case 'LS':
                onAddControl(EditorControlFactory.gamepadLeftStick());
              case 'RS':
                onAddControl(EditorControlFactory.gamepadRightStick());
              default:
                onAddControl(EditorControlFactory.gamepadButton(l));
            }
          },
          isPs: true,
        ),
    };
  }
}

class _KeyboardPalette extends StatelessWidget {
  const _KeyboardPalette({required this.previewMap, required this.onAdd});
  final Map<String, VirtualControl> previewMap;
  final ValueChanged<_KeySpec> onAdd;

  @override
  Widget build(BuildContext context) {
    final rows = _keyboardRows();
    const spacing = 1.0;
    const rowHeight = 36.0;
    return ListView.separated(
      padding: EdgeInsets.zero,
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: spacing),
      itemBuilder: (context, i) {
        return SizedBox(
          height: rowHeight,
          child: _KeyboardRow(
            keys: rows[i],
            previewMap: previewMap,
            onAdd: onAdd,
            gap: 1,
          ),
        );
      },
    );
  }
}

class _KeyboardRow extends StatelessWidget {
  const _KeyboardRow({
    required this.keys,
    required this.previewMap,
    required this.onAdd,
    required this.gap,
  });

  final List<_KeySpec> keys;
  final Map<String, VirtualControl> previewMap;
  final ValueChanged<_KeySpec> onAdd;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < keys.length; i++) ...[
          Expanded(
            flex: keys[i].flex,
            child: Padding(
              padding: EdgeInsets.only(right: i == keys.length - 1 ? 0 : gap),
              child: _PaletteTile(
                onTap: () => onAdd(keys[i]),
                padding: const EdgeInsets.all(2),
                child:
                    _renderKey(previewMap['kbd_${keys[i].id}'] as VirtualKey?),
              ),
            ),
          ),
        ]
      ],
    );
  }

  Widget _renderKey(VirtualKey? control) {
    if (control == null) {
      return const SizedBox.shrink();
    }
    return VirtualKeyWidget(
      control: control,
      onInputEvent: (_) {},
      showLabel: true,
    );
  }
}

class _MouseJoystickPalette extends StatelessWidget {
  const _MouseJoystickPalette({
    required this.previewMap,
    required this.onAdd,
  });

  final Map<String, VirtualControl> previewMap;
  final ValueChanged<VirtualControl> onAdd;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 4.0;
        final rowHeight = ((constraints.maxHeight - gap) / 2).clamp(52.0, 96.0);
        Widget squareTile({
          required VoidCallback onTap,
          required Widget child,
        }) {
          return SizedBox(
            height: rowHeight,
            width: rowHeight,
            child: _ControlTile(
              onTap: onTap,
              padding: const EdgeInsets.all(4),
              child: child,
            ),
          );
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            squareTile(
              onTap: () => onAdd(EditorControlFactory.joystickWASD()),
              child: VirtualJoystickWidget(
                control: previewMap['joy_wasd'] as VirtualJoystick,
                onInputEvent: (_) {},
              ),
            ),
            squareTile(
              onTap: () => onAdd(EditorControlFactory.joystickArrows()),
              child: VirtualJoystickWidget(
                control: previewMap['joy_arrows'] as VirtualJoystick,
                onInputEvent: (_) {},
              ),
            ),
            squareTile(
              onTap: () => onAdd(EditorControlFactory.splitMouse()),
              child: VirtualSplitMouseWidget(
                control: previewMap['mouse_split'] as VirtualSplitMouse,
                onInputEvent: (_) {},
              ),
            ),
            squareTile(
              onTap: () => onAdd(EditorControlFactory.mouseButton('middle')),
              child: VirtualMouseButtonWidget(
                control: previewMap['mouse_middle'] as VirtualMouseButton,
                onInputEvent: (_) {},
                showLabel: true,
              ),
            ),
            SizedBox(
              width: 70,
              // height: rowHeight,
              child: _ControlTile(
                onTap: () => onAdd(EditorControlFactory.scrollStick()),
                padding: const EdgeInsets.all(4),
                child: VirtualScrollStickWidget(
                  control: previewMap['scroll_stick'] as VirtualScrollStick,
                  onInputEvent: (_) {},
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _GamepadPalette extends StatelessWidget {
  const _GamepadPalette({
    required this.previewMap,
    required this.onAdd,
    required this.isPs,
  });

  final Map<String, VirtualControl> previewMap;
  final ValueChanged<String> onAdd;
  final bool isPs;

  @override
  Widget build(BuildContext context) {
    final row1 = isPs
        ? const ['L1', 'L2', 'L3', 'Share', 'Options', 'R3', 'R1', 'R2']
        : const ['LB', 'LT', 'L3', 'Back', 'Start', 'R3', 'RB', 'RT'];

    final row2 = isPs ? const ['Triangle', 'Circle'] : const ['Y', 'B'];
    final row3 = isPs ? const ['Square', 'Cross'] : const ['X', 'A'];

    final customButtons = InputBindingRegistry.registeredGamepadButtons
        .where((b) => !GamepadButtonId.builtIns.contains(b))
        .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final rowHeight = (constraints.maxHeight - gap).clamp(52.0, 156.0);

        Widget buildRow(List<String> labels) {
          return Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                Expanded(
                  child: _ControlTile(
                    onTap: () => onAdd(labels[i]),
                    padding: const EdgeInsets.all(4),
                    child: VirtualButtonWidget(
                      control: previewMap['pad_${labels[i].toLowerCase()}']
                          as VirtualButton,
                      onInputEvent: (_) {},
                      showLabel: true,
                    ),
                  ),
                ),
                if (i != labels.length - 1) const SizedBox(width: gap),
              ],
            ],
          );
        }

//  SizedBox(height: rowHeight, child: buildRow(row1)),
        final main = Column(
          children: [
            Expanded(child: SizedBox(height: rowHeight, child: buildRow(row1))),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(
                  width: rowHeight,
                  height: rowHeight,
                  child: _ControlTile(
                    onTap: () => onAdd('LS'),
                    padding: const EdgeInsets.all(4),
                    child: VirtualJoystickWidget(
                      control: previewMap['pad_ls'] as VirtualJoystick,
                      onInputEvent: (_) {},
                    ),
                  ),
                ),
                SizedBox(
                  width: rowHeight,
                  height: rowHeight,
                  child: _ControlTile(
                    onTap: () => onAdd('Dpad'),
                    padding: const EdgeInsets.all(4),
                    child: VirtualDpadWidget(
                      control: previewMap['pad_dpad'] as VirtualDpad,
                      onInputEvent: (_) {},
                    ),
                  ),
                ),
                SizedBox(
                  width: rowHeight,
                  height: rowHeight,
                  child: Column(
                    children: [
                      Expanded(
                        child:
                            SizedBox(height: rowHeight, child: buildRow(row2)),
                      ),
                      Expanded(
                        child:
                            SizedBox(height: rowHeight, child: buildRow(row3)),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: rowHeight,
                  height: rowHeight,
                  child: _ControlTile(
                    onTap: () => onAdd('RS'),
                    padding: const EdgeInsets.all(4),
                    child: VirtualJoystickWidget(
                      control: previewMap['pad_rs'] as VirtualJoystick,
                      onInputEvent: (_) {},
                    ),
                  ),
                ),
              ],
            ),
          ],
        );

        if (customButtons.isEmpty) return main;

        return Column(
          children: [
            Expanded(child: main),
            const SizedBox(height: 8),
            SizedBox(
              height: (rowHeight * 0.6).clamp(44.0, 96.0),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                itemCount: customButtons.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final b = customButtons[index];
                  final id = 'pad_${b.code}';
                  final control = previewMap[id] as VirtualButton?;
                  if (control == null) {
                    return const SizedBox.shrink();
                  }
                  return SizedBox(
                    width: (rowHeight * 0.6).clamp(44.0, 96.0),
                    child: _ControlTile(
                      onTap: () => onAdd(b.code),
                      padding: const EdgeInsets.all(4),
                      child: VirtualButtonWidget(
                        control: control,
                        onInputEvent: (_) {},
                        showLabel: true,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(6),
  });
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return _PaletteTile(
      onTap: onTap,
      padding: padding,
      child: IgnorePointer(child: child),
    );
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({
    required this.onTap,
    required this.child,
    this.padding = const EdgeInsets.all(6),
  });
  final VoidCallback onTap;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: padding,
          child: SizedBox.expand(child: child),
        ),
      ),
    );
  }
}

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
