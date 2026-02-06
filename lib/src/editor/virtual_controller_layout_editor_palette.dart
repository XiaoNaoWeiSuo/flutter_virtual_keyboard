import 'package:flutter/material.dart';
import '../models/style/control_layout.dart';
import '../models/virtual_controller_models.dart';
import '../widgets/controls/button_widget.dart';
import '../widgets/controls/dpad_widget.dart';
import '../widgets/controls/joystick_widget.dart';
import '../widgets/controls/key_widget.dart';
import '../widgets/controls/mouse_button_widget.dart';
import '../widgets/controls/mouse_wheel_widget.dart';
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
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: SafeArea(
            top: false,
            bottom: false,
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
                      padding: const EdgeInsets.fromLTRB(10, 2, 10, 8),
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
          onAdd: (k) => onAddControl(EditorControlFactory.key(k)),
        ),
      VirtualControllerEditorPaletteTab.mouseAndJoystick =>
        _MouseJoystickPalette(
          previewMap: previewMap,
          onAdd: onAddControl,
        ),
      VirtualControllerEditorPaletteTab.xbox => _GamepadPalette(
          previewMap: previewMap,
          onAdd: (l) => onAddControl(EditorControlFactory.gamepadButton(l)),
          isPs: false,
        ),
      VirtualControllerEditorPaletteTab.ps => _GamepadPalette(
          previewMap: previewMap,
          onAdd: (l) => onAddControl(EditorControlFactory.gamepadButton(l)),
          isPs: true,
        ),
    };
  }
}

class _KeyboardPalette extends StatelessWidget {
  const _KeyboardPalette({required this.previewMap, required this.onAdd});
  final Map<String, VirtualControl> previewMap;
  final ValueChanged<String> onAdd;

  @override
  Widget build(BuildContext context) {
    final rows = _keyboardRows();
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 2.0;
        final rowCount = rows.length;
        final rowHeight =
            (constraints.maxHeight - spacing * (rowCount - 1)) / rowCount;

        return Column(
          children: [
            for (var i = 0; i < rows.length; i++) ...[
              SizedBox(
                height: rowHeight > 44.0 ? 44.0 : rowHeight,
                child: _KeyboardRow(
                  keys: rows[i],
                  previewMap: previewMap,
                  onAdd: onAdd,
                  gap: 2,
                ),
              ),
              if (i != rows.length - 1) const SizedBox(height: spacing),
            ],
          ],
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
  final ValueChanged<String> onAdd;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      child: Row(
        children: [
          for (var i = 0; i < keys.length; i++) ...[
            Expanded(
              flex: keys[i].flex,
              child: Padding(
                padding: EdgeInsets.only(right: i == keys.length - 1 ? 0 : gap),
                child: _PaletteTile(
                  onTap: () => onAdd(keys[i].label),
                  child: _renderKey(
                      previewMap['kbd_${keys[i].id}'] as VirtualKey?),
                ),
              ),
            ),
          ]
        ],
      ),
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
        const gap = 6.0;
        final rowHeight = ((constraints.maxHeight - gap) / 2).clamp(52.0, 96.0);

        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  SizedBox(
                    height: rowHeight,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: _ControlTile(
                            onTap: () =>
                                onAdd(EditorControlFactory.splitMouse()),
                            child: VirtualSplitMouseWidget(
                              control: previewMap['mouse_split']
                                  as VirtualSplitMouse,
                              onInputEvent: (_) {},
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        Expanded(
                          child: _ControlTile(
                            onTap: () => onAdd(
                                EditorControlFactory.mouseButton('middle')),
                            child: VirtualMouseButtonWidget(
                              control: previewMap['mouse_middle']
                                  as VirtualMouseButton,
                              onInputEvent: (_) {},
                              showLabel: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        Expanded(
                          child: _ControlTile(
                            onTap: () async {
                              final text =
                                  await _showCustomSignalSheet(context);
                              if (text == null) return;
                              final created =
                                  EditorControlFactory.customSignal(text);
                              if (created == null ||
                                  created is VirtualJoystick) {
                                if (!context.mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('无效输入')),
                                );
                                return;
                              }
                              onAdd(created);
                            },
                            child: _customPreview(),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: gap),
                  SizedBox(
                    height: rowHeight,
                    child: Row(
                      children: [
                        Expanded(
                          child: _ControlTile(
                            onTap: () =>
                                onAdd(EditorControlFactory.joystickWASD()),
                            child: VirtualJoystickWidget(
                              control:
                                  previewMap['joy_wasd'] as VirtualJoystick,
                              onInputEvent: (_) {},
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        Expanded(
                          child: _ControlTile(
                            onTap: () =>
                                onAdd(EditorControlFactory.joystickArrows()),
                            child: VirtualJoystickWidget(
                              control:
                                  previewMap['joy_arrows'] as VirtualJoystick,
                              onInputEvent: (_) {},
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        Expanded(
                          child: _ControlTile(
                            onTap: () =>
                                onAdd(EditorControlFactory.gamepadLeftStick()),
                            child: VirtualJoystickWidget(
                              control: previewMap['joy_ls'] as VirtualJoystick,
                              onInputEvent: (_) {},
                            ),
                          ),
                        ),
                        const SizedBox(width: gap),
                        Expanded(
                          child: _ControlTile(
                            onTap: () =>
                                onAdd(EditorControlFactory.gamepadRightStick()),
                            child: VirtualJoystickWidget(
                              control: previewMap['joy_rs'] as VirtualJoystick,
                              onInputEvent: (_) {},
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: 110,
              child: _ControlTile(
                onTap: () => onAdd(EditorControlFactory.scrollStick()),
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

  Widget _customPreview() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, size: 16, color: Colors.white70),
          SizedBox(width: 6),
          Text('自定义', style: TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Future<String?> _showCustomSignalSheet(BuildContext context) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimatedPadding(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: Material(
              color: const Color(0xFF1C1C1E),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        autofocus: true,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText:
                              '例如：Space / key:Enter / mouse:middle / gamepad:A',
                          hintStyle: const TextStyle(color: Colors.white38),
                          filled: true,
                          fillColor: Colors.white10,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (v) => Navigator.of(context).pop(v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.of(context).pop(controller.text),
                      child: const Text('添加'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
    focusNode.dispose();
    controller.dispose();
    final v = result?.trim();
    if (v == null || v.isEmpty) return null;
    return v;
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
        ? const ['Triangle', 'Circle', 'Square', 'Cross', 'L1']
        : const ['Y', 'B', 'X', 'A', 'LB'];
    final row2 = isPs
        ? const ['R1', 'L2', 'R2', 'Share', 'Options']
        : const ['RB', 'LT', 'RT', 'Back', 'Start'];

    return LayoutBuilder(
      builder: (context, constraints) {
        const gap = 6.0;
        final rowHeight = ((constraints.maxHeight - gap) / 2).clamp(52.0, 96.0);

        Widget buildRow(List<String> labels) {
          return Row(
            children: [
              for (var i = 0; i < labels.length; i++) ...[
                Expanded(
                  child: _ControlTile(
                    onTap: () => onAdd(labels[i]),
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

        return Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  SizedBox(height: rowHeight, child: buildRow(row1)),
                  const SizedBox(height: gap),
                  SizedBox(height: rowHeight, child: buildRow(row2)),
                ],
              ),
            ),
            const SizedBox(width: gap),
            SizedBox(
              width: 110,
              child: _ControlTile(
                onTap: () => onAdd('Dpad'),
                child: VirtualDpadWidget(
                  control: previewMap['pad_dpad'] as VirtualDpad,
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

class _SectionRow extends StatelessWidget {
  const _SectionRow({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(
          height: 56,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: children.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) =>
                SizedBox(width: 74, child: children[i]),
          ),
        ),
      ],
    );
  }
}

class _ControlTile extends StatelessWidget {
  const _ControlTile({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return _PaletteTile(onTap: onTap, child: IgnorePointer(child: child));
  }
}

class _PaletteTile extends StatelessWidget {
  const _PaletteTile({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Center(child: child),
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
              key: _normalizeKeyValue(k.label),
            ),
      ];
    case VirtualControllerEditorPaletteTab.mouseAndJoystick:
      return [
        VirtualMouseButton(
          id: 'mouse_middle',
          label: 'middle',
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
          keys: const ['W', 'A', 'S', 'D'],
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
          keys: const ['↑', '←', '↓', '→'],
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
        VirtualJoystick(
          id: 'joy_ls',
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
          id: 'joy_rs',
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
        VirtualDpad(
          id: 'dpad',
          label: '',
          layout: dummy,
          trigger: TriggerType.hold,
          mode: 'gamepad',
          enable3D: true,
          directions: const {
            'up': 'dpad_up',
            'down': 'dpad_down',
            'left': 'dpad_left',
            'right': 'dpad_right',
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
      final sys = isPs ? const ['Options', 'Share'] : const ['Start', 'Back'];
      return [
        for (final k in [...face, ...shoulders, ...sys])
          VirtualButton(
            id: 'pad_${k.toLowerCase()}',
            label: k,
            layout: dummy,
            trigger: TriggerType.hold,
            config: {'padKey': k.toLowerCase()},
          ),
        VirtualDpad(
          id: 'pad_dpad',
          label: '',
          layout: dummy,
          trigger: TriggerType.hold,
          mode: 'gamepad',
          enable3D: true,
          directions: const {
            'up': 'dpad_up',
            'down': 'dpad_down',
            'left': 'dpad_left',
            'right': 'dpad_right',
          },
          config: const {},
        ),
      ];
  }
}

String _normalizeKeyValue(String label) {
  return switch (label) {
    '↑' => 'ArrowUp',
    '↓' => 'ArrowDown',
    '←' => 'ArrowLeft',
    '→' => 'ArrowRight',
    'Win' => 'Meta',
    _ => label,
  };
}

class _KeySpec {
  const _KeySpec(this.id, this.label, this.flex);
  final String id;
  final String label;
  final int flex;
}

List<List<_KeySpec>> _keyboardRows() {
  return const [
    [
      _KeySpec('esc', 'Esc', 1),
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
      _KeySpec('win', 'Win', 2),
      _KeySpec('space', 'Space', 8),
      _KeySpec('left', '←', 1),
      _KeySpec('down', '↓', 1),
      _KeySpec('up', '↑', 1),
      _KeySpec('right', '→', 1),
    ],
  ];
}
