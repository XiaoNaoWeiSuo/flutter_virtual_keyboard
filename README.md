# Virtual Gamepad Pro

Advanced virtual controller suite for Flutter: keyboard keys, gamepad buttons, joysticks, D-Pad, mouse buttons, wheel, and a built-in **layout editor suite**. Designed for remote desktop / cloud gaming / streaming scenarios.

This package is pure Flutter (no native dependencies) and ships with a structured event system you can forward to your own input pipeline (WebRTC, sockets, etc.).

## Features

- **Controls**: Key, Key Cluster, Joystick, D-Pad, Button, Mouse Button, Mouse Wheel, Split Mouse, Scroll Stick.
- **Responsive Layout**: Percent-based `ControlLayout(x,y,width,height)` works across aspect ratios.
- **Editor Suite**: `VirtualControllerLayoutEditor` + palette to create and edit layouts at runtime.
- **Customization**: `ControlStyle` supports shapes, borders, shadows, colors, images, label styles.
- **Per-Control Opacity**: Store a per-control opacity override in `control.config['opacity']`.
- **Haptics**: `ControlFeedback` + sensible defaults (can be disabled per control).
- **Utilities**: `ControlGeometry` for consistent “occupied size” vs “safe size” math.

## Installation

```yaml
dependencies:
  virtual_gamepad_pro: ^0.1.0
```

## Quick Start (Overlay)

Render controls with `VirtualControllerOverlay` and forward `InputEvent` to your own handler:

```dart
import 'package:flutter/material.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

class MyControllerPage extends StatelessWidget {
  const MyControllerPage({super.key});

  @override
  Widget build(BuildContext context) {
    final layout = VirtualControllerLayout(
      schemaVersion: 1,
      name: 'My Layout',
      controls: [
        VirtualJoystick(
          id: 'ls',
          label: 'L',
          layout: const ControlLayout(x: 0.08, y: 0.62, width: 0.18, height: 0.28),
          trigger: TriggerType.hold,
          mode: 'gamepad',
          stickType: 'left',
        ),
        VirtualButton(
          id: 'a',
          label: 'A',
          layout: const ControlLayout(x: 0.82, y: 0.70, width: 0.10, height: 0.10),
          trigger: TriggerType.tap,
        ),
      ],
    );

    return Scaffold(
      body: Stack(
        children: [
          const Placeholder(),
          VirtualControllerOverlay(
            layout: layout,
            opacity: 1.0,
            showLabels: true,
            onInputEvent: (event) {
              switch (event) {
                case KeyboardInputEvent e:
                  // send to your keyboard layer
                  break;
                case MouseWheelVectorInputEvent e:
                  // smooth scroll (dx, dy)
                  break;
                case MouseWheelInputEvent e:
                  // legacy discrete wheel (direction, delta)
                  break;
                default:
                  break;
              }
            },
          ),
        ],
      ),
    );
  }
}
```

## Layout Editor Suite

The package provides a full-screen editor that works well in landscape. The editor is **storage-agnostic**: you provide `load` and `save`.

```dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

class LayoutEditorPage extends StatelessWidget {
  const LayoutEditorPage({super.key, required this.layoutId});
  final String layoutId;

  Future<VirtualControllerLayout> _load(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('layout_$id');
    if (raw == null) {
      return const VirtualControllerLayout(schemaVersion: 1, name: 'New Layout', controls: []);
    }
    return VirtualControllerLayout.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> _save(String id, VirtualControllerLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('layout_$id', jsonEncode(layout.toJson()));
  }

  @override
  Widget build(BuildContext context) {
    return VirtualControllerLayoutEditor(
      layoutId: layoutId,
      load: _load,
      save: _save,
      previewDecorator: (layout) {
        // Inject your own per-control styles (optional)
        return layout;
      },
    );
  }
}
```

## Core Widgets

### VirtualControllerOverlay

| Parameter | Type | Notes |
| --- | --- | --- |
| `layout` | `VirtualControllerLayout` | Layout containing controls |
| `onInputEvent` | `void Function(InputEvent)` | Input callback |
| `opacity` | `double` | Global opacity multiplier (default `0.5`) |
| `showLabels` | `bool` | Show labels (default `true`) |

### VirtualControllerLayoutEditor

| Parameter | Type | Notes |
| --- | --- | --- |
| `layoutId` | `String` | Your layout key |
| `load` | `Future<VirtualControllerLayout> Function(String)` | Load from your storage |
| `save` | `Future<void> Function(String, VirtualControllerLayout)` | Save to your storage |
| `previewDecorator` | `VirtualControllerLayout Function(VirtualControllerLayout)?` | Inject project styles (optional) |
| `enabledPaletteTabs` | `Set<VirtualControllerEditorPaletteTab>` | Which groups can be added |
| `allowAddRemove/allowResize/allowMove/allowRename/readOnly` | `bool` | Feature toggles |

## Controls (Models)

All controls extend `VirtualControl` and share:

- `id`, `label`, `layout`, `trigger`, `config`, `style`, `feedback`

Available controls:

- `VirtualKey`, `VirtualKeyCluster`
- `VirtualJoystick`
- `VirtualDpad`
- `VirtualButton`
- `VirtualMouseButton`, `VirtualMouseWheel`
- `VirtualSplitMouse`
- `VirtualScrollStick`
- `VirtualMacroButton`
- `VirtualCustomControl`

## Events

All user interactions are emitted as `InputEvent` subclasses:

- `KeyboardInputEvent` (key up/down, optional modifiers)
- `MouseButtonInputEvent`
- `MouseWheelInputEvent` (legacy discrete wheel)
- `MouseWheelVectorInputEvent` (smooth wheel vector dx/dy)
- `JoystickInputEvent`
- `GamepadButtonInputEvent`, `GamepadAxisInputEvent`
- `MacroInputEvent`
- `CustomInputEvent`

## Haptics (ControlFeedback)

Controls can provide `feedback: ControlFeedback(...)`. If a control has no feedback configured, the package uses a default light haptic (you can disable by setting `ControlFeedback(vibration: false)` explicitly).

Supported `vibrationType`:

- `light`, `medium`, `heavy`, `selection`, `success`, `error`

## Scroll Stick (Vector Scroll)

`VirtualScrollStick` now emits **smooth vector wheel events**:

- Emits `MouseWheelVectorInputEvent(dx, dy)` at ~60Hz while dragging
- Uses `sensitivity` plus optional `config`:
  - `wheelUnitPerPixel` (`double`, default `3/20`) converts drag pixels → wheel units
  - `maxAbsDeltaPerTick` (`double`, default `12`) caps per-frame deltas

## Per-Control Opacity

You can store a per-control opacity multiplier in the control config:

```dart
VirtualButton(
  id: 'a',
  label: 'A',
  layout: const ControlLayout(x: 0.8, y: 0.7, width: 0.1, height: 0.1),
  trigger: TriggerType.tap,
  config: const {'opacity': 0.6},
)
```

The final opacity is: `overlay.opacity * control.config['opacity']`.

## Utilities

### ControlGeometry

`ControlGeometry` provides consistent math for editor and overlay:

- `occupiedRect(control, screenSize)`
- `occupiedLayout(control, screenSize)`
- `safeRect(control, screenSize)`
- `safePadding(control, size)`

Useful for ensuring circular controls stay square and special controls (like scroll stick) keep a minimum aspect ratio.

### Style Codec

- `controlStyleFromJson(...)`
- `controlStyleToJson(...)`

Layouts can be serialized to/from JSON, allowing dynamic configuration from a server.

```json
{
  "schemaVersion": 1,
  "name": "Game Config",
  "controls": [
    {
      "type": "joystick",
      "id": "ls",
      "label": "Move",
      "layout": {"x": 0.1, "y": 0.5, "width": 0.25, "height": 0.25},
      "trigger": "hold",
      "config": {
        "mode": "gamepad",
        "stickType": "left",
        "deadzone": 0.1
      },
      "style": {
        "color": "0xFF000000",
        "shape": "circle"
      }
    }
  ]
}
```
