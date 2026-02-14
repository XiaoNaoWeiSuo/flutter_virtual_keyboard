# Virtual Gamepad Pro

[![pub package](https://img.shields.io/pub/v/virtual_gamepad_pro.svg)](https://pub.dev/packages/virtual_gamepad_pro)
[![license](https://img.shields.io/github/license/XiaoNaoWeiSuo/flutter_virtual_keyboard)](https://github.com/XiaoNaoWeiSuo/flutter_virtual_keyboard/blob/main/LICENSE)

Live demo (runs this repo's `example/`): [plugin.qianpc.cn/gamepad](https://plugin.qianpc.cn/gamepad/)

A pure-Flutter virtual controller suite (Joystick / D-Pad / Buttons / Mouse / Keyboard / Macros) with a runtime layout editor.

This package cleanly separates:
- **Definition**: bindings, styles, semantics (owned by your app code)
- **State**: editable runtime data like position/size/opacity/config (portable JSON)

So you can:
- Share and persist only the minimal JSON state (no callbacks, no business logic, no platform objects)
- Keep bindings and visual rules strongly typed (no implicit `String + Map` conventions)
- Control performance (less dynamic inference, fewer runtime maps)

Coordinate system: every control uses normalized percentage coordinates (0.0–1.0) for both position and size, so layouts are resolution-independent.

---

## Highlights
- Overlay renderer: render `definition + state` with predictable performance
- Runtime layout editor: drag / resize / opacity; saves a minimal `VirtualControllerState` JSON
- Strongly-typed input: `InputBinding` for keyboard & gamepad; supports registering custom buttons
- Theme layer: `VirtualControlTheme` can override style/label/config (and other visual props) at render-time without mutating original data
- Macro suite: record, edit, and serialize an `InputEvent` sequence to power macro buttons

---

## Screenshots

| Layout Editor | Macro Editor |
|---|---|
| <img src="resource/layout_editor.jpg" width="420" alt="Layout editor" /> | <img src="resource/macro_editor_demo.gif" width="420" alt="Macro editor demo" /> |

| Macro Recorder (dock) | Keyboard Control |
|---|---|
| <img src="resource/macro_recorder.jpg" width="420" alt="Macro recorder" /> | <img src="resource/keyboard.png" width="420" alt="Keyboard control" /> |

Gamepad Buttons

<img src="resource/gamepad_buttons.png" width="860" alt="Gamepad buttons" />

Editor Signals (examples)

| Button Edit Signal | Joystick Edit Signal |
|---|---|
| <img src="resource/edit_button_signal.jpg" width="420" alt="Button edit signal" /> | <img src="resource/edit_joystick_signal.jpg" width="420" alt="Joystick edit signal" /> |

---

## Install

```yaml
dependencies:
  virtual_gamepad_pro: ^0.3.0
```

---

## Quick Start (Render Overlay: definition + state)

Recommended data model:
- `VirtualControllerLayout`: control definition (binding/style/default layout, owned by code)
- `VirtualControllerState`: user-editable state (layout/opacity/config only, JSON-friendly)

```dart
import 'package:flutter/material.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

class GamePage extends StatelessWidget {
  const GamePage({super.key});

  @override
  Widget build(BuildContext context) {
    final definition = VirtualControllerLayout(
      schemaVersion: 1,
      name: 'Default',
      controls: [
        VirtualJoystick(
          id: 'ls',
          label: 'LS',
          layout: const ControlLayout(x: 0.1, y: 0.6, width: 0.2, height: 0.2),
          trigger: TriggerType.hold,
          mode: JoystickMode.gamepad,
          stickType: GamepadStickId.left,
        ),
        VirtualButton(
          id: 'btn_a',
          label: 'A',
          layout: const ControlLayout(x: 0.8, y: 0.7, width: 0.1, height: 0.1),
          trigger: TriggerType.tap,
          binding: const GamepadButtonBinding(GamepadButtonId.a),
        ),
      ],
    );

    final state = const VirtualControllerState(schemaVersion: 1, controls: []);

    return Scaffold(
      body: Stack(
        children: [
          const Center(child: Text('Game Content')),
          VirtualControllerOverlay(
            definition: definition,
            state: state,
            onInputEvent: (event) {
              if (event is GamepadAxisInputEvent) {
                debugPrint('Axis ${event.axisId}: ${event.x}, ${event.y}');
              } else if (event is GamepadButtonInputEvent) {
                debugPrint('Button ${event.button}: ${event.isDown}');
              } else if (event is KeyboardInputEvent) {
                debugPrint('Key ${event.key}: ${event.isDown}');
              }
            },
          ),
        ],
      ),
    );
  }
}
```

---

## Example App (for pub.dev)

This repository includes a complete example app (layout management + runtime editor + macro entry points):
- Directory: `example/`
- Entry: `example/lib/main.dart`

---

## Theming (Recommended): `VirtualControlTheme`

Themes are meant to decorate at render-time, not to rewrite your source data.
You can treat a theme as a pure function: `VirtualControl -> VirtualControl`.

Notes:
- The overlay resolves **position/size** from `state.layout` (or `definition.layout`) and uses it for geometry. Do not rely on themes to move/resize controls; change `state` (or definition defaults) instead.
- Themes run **after** `state.config` has been merged into each control's `config`, so you can override config-driven visuals inside `decorate(...)`.
- Do not change `control.id` inside themes (state lookup and editor selection are ID-based).
- `VirtualKeyCluster` is decorated once as a cluster, then expanded into keys; expanded keys are decorated again.

```dart
final theme = RuleBasedVirtualControlTheme(
  base: const DefaultVirtualControlTheme(),
  post: [
    ControlRule(
      when: ControlMatchers.gamepadButtonId(GamepadButtonId.a),
      transform: (c) => (c as VirtualButton).copyWith(
        style: const ControlStyle(color: Colors.green),
      ),
    ),
  ],
);

VirtualControllerOverlay(
  definition: definition,
  state: state,
  theme: theme,
  onInputEvent: onInputEvent,
);
```

---

## Add Custom Gamepad Buttons: `InputBindingRegistry`

Register a strongly-typed custom button (e.g. Turbo / Screenshot / OEM keys) before building your layout/editor palette:

```dart
void main() {
  InputBindingRegistry.registerGamepadButton(code: 'turbo', label: 'Turbo');
  InputBindingRegistry.registerGamepadButton(code: 'screenshot', label: 'Shot');
  runApp(const MyApp());
}
```

Notes:
- Button `code` is normalized and de-duplicated internally (so the same logical code maps to one typed ID).
- When recovering controls from state-only IDs like `btn_<code>_...`, the renderer may auto-register unknown codes.

---

## Layout Serialization Guide

### Goals & constraints
- **Shareable & persistable**: serialized data must not contain callbacks, platform objects, or business semantics
- **Cross-device reuse**: coordinates are normalized (0.0–1.0), avoiding resolution coupling
- **Evolvable**: `schemaVersion` supports structure evolution

### Two-layer model: Definition vs State
- **Definition**: `VirtualControllerLayout` (control types, bindings, styles, default layout)
- **State**: `VirtualControllerState` (user-editable layout/opacity/config)

Core rule: **Definition is controlled by code; State is the minimal data you persist/share.**

### Minimal State JSON (recommended)

```json
{
  "schemaVersion": 1,
  "name": "My Layout",
  "controls": [
    {
      "id": "btn_a",
      "layout": { "x": 0.78, "y": 0.63, "width": 0.12, "height": 0.12 },
      "opacity": 0.7
    }
  ]
}
```

### Render-time merge behavior (important)
- For every control in `definition`, the renderer:
  - Picks `layout = state.layout ?? definition.layout` and `opacity = state.opacity ?? 1.0`
  - Merges `state.config` into `control.config` (state overrides definition)
  - Applies extra macro fields: `config['label']` (non-empty) overrides label; `config['sequence']` (legacy) overrides `VirtualMacroButton.sequence`
  - Applies `theme.decorate(...)` on the merged control
- If `state` contains control IDs that do not exist in `definition`, the renderer may attempt best-effort completion by ID prefix (useful for migration/replay).
- While loading JSON, any state entry with `config.deleted == true` is ignored.

### Dynamic control IDs (best-effort recovery)
When a `VirtualControlState.id` is not found in `definition`, the overlay may create a control by ID prefix (so that a shared `state` can still render something usable). Common prefixes include:
- `macro_`
- `btn_`
- `mouse_`, `wheel_`, `split_mouse_`, `scroll_stick_`
- `dpad_`
- `joystick_wasd_`, `joystick_arrows_`, `joystick_gamepad_left_`, `joystick_gamepad_right_`
- `key_`

This enables sharing only `state` while still restoring a usable layout, with definition-level style/binding owned by your app.

---

## API Notes

### `VirtualControllerOverlay`
Renderer entry point (`definition + state`).

| Property | Type | Description |
|----------|------|-------------|
| `definition` | `VirtualControllerLayout` | Control definitions (bindings/styles/default layout). |
| `state` | `VirtualControllerState` | Editable runtime state (layout/opacity/config), JSON-friendly. |
| `theme` | `VirtualControlTheme` | Optional render-time decorator (styling/labels/config overrides). |
| `onInputEvent` | `Function(InputEvent)` | Input event callback. |
| `opacity` | `double` | Global overlay opacity (0.0–1.0). |
| `showLabels` | `bool` | Whether to show text labels on controls. |
| `immersive` | `bool` | Hide system UI (status/navigation) with immersive mode. |

### `VirtualControllerLayoutEditor`
Runtime layout editor: edits only `state` (position/size/opacity); does not mutate bindings/styles/actions.

| Property | Type | Description |
|----------|------|-------------|
| `layoutId` | `String` | Unique ID for the layout being edited. |
| `loadDefinition` | `Future<VirtualControllerLayout> Function(id)` | Load definition (owned by code). |
| `loadState` | `Future<VirtualControllerState> Function(id)` | Load state (JSON). |
| `saveState` | `Future<void> Function(id, state)` | Persist state (JSON). |
| `previewDecorator` | `Function` | Optional hook to decorate preview (e.g. apply theme). |
| `onClose` | `VoidCallback?` | Called when the user taps the close button. |
| `readOnly` | `bool` | Read-only mode (viewing only). |
| `allowAddRemove` | `bool` | Whether adding/removing controls is allowed. |
| `allowResize` | `bool` | Whether resizing controls is allowed. |
| `allowMove` | `bool` | Whether moving controls is allowed. |
| `allowRename` | `bool` | Whether renaming the layout is allowed. |
| `enabledPaletteTabs` | `Set<VirtualControllerEditorPaletteTab>` | Which palette tabs are shown. |
| `initialPaletteTab` | `VirtualControllerEditorPaletteTab` | Initially selected palette tab. |
| `immersive` | `bool` | Immersive mode. |

### Macro recording & editing
For normal runtime rendering you only need `VirtualControllerOverlay`. Macro workflows are opt-in tooling:

- `MacroSuitePage`: macro editor (main editor + recording importer). Typically writes macro data into a macro button state `config`:
  - `config['recordingV2']`: timeline JSON
  - `config['label']`: optional display label override
- `VirtualControllerMacroRecordingSession`: records input events (optionally mixing hardware keyboard/mouse) and returns a `recordingV2` timeline JSON list (each item includes `atMs`) for editing or storage.

#### `recordingV2` timeline format (stored in `VirtualControlState.config['recordingV2']`)

Each item is a JSON object:
- `atMs` (int): timestamp from the start of playback (milliseconds)
- `type` (string): event kind
- `data` (object): payload (depends on `type`)

Supported `type` values and required `data` keys:
- `keyboard`: `key` (string), `isDown` (bool), optional `modifiers` (string[])
- `mouse_button`: `button` (string), `isDown` (bool)
- `mouse_wheel`: `direction` (string), `delta` (int)
- `mouse_wheel_vector`: `dx` (double), `dy` (double)
- `gamepad_button`: `button` (string), `isDown` (bool)
- `gamepad_axis`: `axisId` (string, `left`/`right`), `x` (double), `y` (double)
- `joystick`: `dx` (double), `dy` (double), `activeKeys` (string[])
- `custom`: `id` (string), optional `data` (object)

### Type Reference (Complete)

#### Input events (`InputEvent`)
All events delivered via `onInputEvent` are one of:
- `KeyboardInputEvent`: `key: KeyboardKey`, `isDown: bool`, `modifiers: List<KeyboardKey>`
- `MouseButtonInputEvent`: `button: MouseButtonId`, `isDown: bool`
- `MouseWheelInputEvent`: `direction: MouseWheelDirection`, `delta: int`
- `MouseWheelVectorInputEvent`: `dx: double`, `dy: double`
- `JoystickInputEvent`: `dx: double`, `dy: double`, `activeKeys: List<KeyboardKey>`
- `GamepadButtonInputEvent`: `button: GamepadButtonId`, `isDown: bool`
- `GamepadAxisInputEvent`: `axisId: GamepadStickId`, `x: double`, `y: double`
- `CustomInputEvent`: `id: String`, `data: Map<String, dynamic>`
- `MacroInputEvent`: `sequence: List<TimedInputEvent>` (in-memory only; not stored as a single timeline item)

#### Identifiers / enums (`identifiers.dart`)
- `MouseButtonId`: `left`, `right`, `middle`
- `MouseWheelDirection`: `up`, `down`
- `JoystickMode`: `keyboard`, `gamepad`
- `GamepadStickId`: `left`, `right`
- `GamepadAxisId`: `left_x`, `left_y`, `right_x`, `right_y`

#### Bindings (`InputBinding`)
Serialized binding types:
- `keyboard`: `KeyboardBinding(key: KeyboardKey, modifiers: List<KeyboardKey>)`
- `gamepad_button`: `GamepadButtonBinding(GamepadButtonId)`

#### Triggers (`TriggerType`)
JSON string values:
- `tap`
- `hold`
- `double_tap`

#### Controls (`VirtualControl`)
Controls that can exist in a `VirtualControllerLayout.controls` list:
- `VirtualJoystick`
- `VirtualDpad`
- `VirtualButton`
- `VirtualKey`
- `VirtualKeyCluster`
- `VirtualMouseButton`
- `VirtualMouseWheel`
- `VirtualSplitMouse`
- `VirtualScrollStick`
- `VirtualMacroButton`
- `VirtualCustomControl`

#### Gamepad button IDs (`GamepadButtonId`)
Built-in `code` values:
- `a`, `b`, `x`, `y`
- `lb`, `rb`, `lt`, `rt`
- `l1`, `l2`, `r1`, `r2`
- `back`, `start`, `view`, `menu`, `options`, `share`
- `dpad_up`, `dpad_down`, `dpad_left`, `dpad_right`
- `l3`, `r3`
- `triangle`, `circle`, `square`, `cross`

### `ControlStyle`
Visual appearance of a control.

| Property | Type | Description |
|----------|------|-------------|
| `shape` | `BoxShape` | `circle` or `rectangle`. |
| `color` | `Color?` | Background color. |
| `borderColor` | `Color?` | Border color. |
| `lockedColor` | `Color?` | Color for "locked" state (e.g. joystick lock). |
| `backgroundImagePath` | `String?` | Asset path or URL for background image. |
| `shadows` | `List<BoxShadow>` | Shadow list for neon/glow effects. |
| `imageFit` | `BoxFit` | How the image should be inscribed. |

### `VirtualJoystick`
A virtual thumbstick.

| Property | Type | Description |
|----------|------|-------------|
| `deadzone` | `double` | Minimum input value to register (0.0–1.0). Default: 0.1. |
| `mode` | `JoystickMode` | Keyboard (WASD-like) or gamepad stick mode. |
| `stickType` | `GamepadStickId` | `left` or `right` (used by `GamepadAxisInputEvent.axisId`). |
| `keys` | `List<KeyboardKey>` | Up/Left/Down/Right keys for keyboard mode. |
| `axes` | `List<GamepadAxisId>` | Axis identifiers (mainly for modeling/compat). |

### `VirtualButton`
A standard push button.

| Property | Type | Description |
|----------|------|-------------|
| `trigger` | `TriggerType` | `tap` (press/release), `hold` (continuous), `doubleTap`. |
| `label` | `String` | Text displayed on the button. |
| `binding` | `InputBinding` | Strong-typed binding for emitted input. |

#### Ultra strong typed helper

```dart
final GamepadButtonId id = button.gamepadButton; // throws if not gamepad
final GamepadButtonId? maybe = button.gamepadButtonOrNull;
```

---

## Layout Editor Integration

To use the editor, implement the persistence layer (load/save).

```dart
// Example using SharedPreferences
Future<void> saveState(String id, VirtualControllerState state) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = jsonEncode(state.toJson());
  await prefs.setString('layout_state_$id', jsonStr);
}

Future<VirtualControllerState> loadState(String id) async {
  final prefs = await SharedPreferences.getInstance();
  final jsonStr = prefs.getString('layout_state_$id');
  if (jsonStr == null) {
    return const VirtualControllerState(schemaVersion: 1, controls: []);
  }
  return VirtualControllerState.fromJson(jsonDecode(jsonStr));
}

Future<VirtualControllerLayout> loadDefinition(String id) async {
  return VirtualControllerLayout.xbox();
}

// In your Widget:
VirtualControllerLayoutEditor(
  layoutId: 'user_custom_1',
  loadDefinition: loadDefinition,
  loadState: loadState,
  saveState: saveState,
)
```

Notes:
- The editor palette automatically lists registered custom buttons.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Built in Production

<img src="resource/favicon.png" width="48" height="48" alt="Product icon" />

This package was extracted from a real production need: a highly customizable, editable, serializable (shareable) virtual controller + macro system with predictable performance. If you're building game streaming, remote control, cloud apps, or tool-like products, it should help you ship interaction faster.

- Company: Hangzhou iLingJing Technology Co., Ltd.
- Product: [QianPC](https://www.qianpc.com)
- Author: [liliin.icu](https://liliin.icu)
