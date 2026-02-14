part of '../virtual_controller_layout_editor_palette.dart';

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
          onAdd: (k) => onAddControl(
            EditorControlFactory.keyWith(
              key: KeyboardKey(k.key).normalized(),
              label: k.label,
              modifiers:
                  k.modifiers.map((m) => KeyboardKey(m).normalized()).toList(),
            ),
          ),
        ),
      VirtualControllerEditorPaletteTab.mouseAndJoystick =>
        _MouseJoystickPalette(
          previewMap: previewMap,
          onAdd: onAddControl,
        ),
      VirtualControllerEditorPaletteTab.macro => _MacroPalette(
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

class _MacroPalette extends StatelessWidget {
  const _MacroPalette({
    required this.previewMap,
    required this.onAdd,
  });

  final Map<String, VirtualControl> previewMap;
  final ValueChanged<VirtualControl> onAdd;

  @override
  Widget build(BuildContext context) {
    final control = previewMap['macro'] as VirtualMacroButton?;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 64,
            child: _ControlTile(
              onTap: () => onAdd(EditorControlFactory.macroButton()),
              child: control == null
                  ? const SizedBox.shrink()
                  : VirtualMacroButtonWidget(
                      control: control,
                      onInputEvent: (_) {},
                      showLabel: true,
                    ),
            ),
          ),
        ],
      ),
    );
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
                child: _renderKey(
                  previewMap['kbd_${keys[i].id}'] as VirtualKey?,
                ),
              ),
            ),
          ),
        ],
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
              onTap: () =>
                  onAdd(EditorControlFactory.mouseButton(MouseButtonId.middle)),
              child: VirtualMouseButtonWidget(
                control: previewMap['mouse_middle'] as VirtualMouseButton,
                onInputEvent: (_) {},
                showLabel: true,
              ),
            ),
            SizedBox(
              width: 70,
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
