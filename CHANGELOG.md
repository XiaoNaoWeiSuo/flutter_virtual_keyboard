## 0.3.1
- **Feat**: Update documentation for `VirtualControllerOverlay` and `VirtualControllerTheme`.

## 0.3.0
- **Feat**: Introduced `VirtualControlTheme` + rule-based theming (`RuleBasedVirtualControlTheme`, `ControlMatchers`) and applied it in `VirtualControllerOverlay`.
- **Feat**: Added `identifiers.dart` (typed enums + robust `parse/tryParse`) for mouse buttons, wheel direction, joystick mode, stick/axis identifiers.
- **Feat**: Added layout utilities (`layoutWithAspectRatio`, `layoutSquare`), state-to-definition helper (`buildDefinitionFromState`), and control cloning helper (`cloneControlWithOverrides`) for editor/runtime composition.
- **Change**: Improved `KeyboardKey.normalized()` (aliases like esc/cmd/ctrl + arrow symbols).
- **Change**: Expanded dynamic control creation from state IDs (mouse/wheel/dpad/split mouse/scroll stick/key) for better state portability.
- **Change**: Macro suite timeline/preview UI refactor and tooling improvements.

## 0.2.4
- **Change**: Narrowed default Macro Button size (width 0.06, height 0.10) for better ergonomics.
- **Fix**: Unified all macro button creation paths (palette, factory, editor macro add) to use the narrowed default width.
- **Docs**: Updated README to reflect default macro button sizing and customization notes.

## 0.2.3
- **Feat**: Add macro recording suite UI (`MacroSuitePage`) and timeline preview widgets.
- **Feat**: Add macro recording runtime helpers and widgets (recording session + macro button widget).
- **Change**: Refactor layout editor internals (palette/layout editor split) and update exports.

## 0.2.2
- **Fix**: Resolved `IconData` tree-shaking issue in `style_json_codec.dart` to support optimized web builds (`--tree-shake-icons`).
- **Optimization**: Improved web compilation compatibility by avoiding non-constant `IconData` invocations.

## 0.2.1
- **Fix**: Correctly merge and propagate `config` in `VirtualJoystick` and `VirtualDpad` editors.
- **Change**: `VirtualDpad` defaults to `enable3D: false` for cleaner flat design.
- **Change**: `VirtualJoystick` defaults `stickClickEnabled` and `stickLockEnabled` to `false`.
- **Example**: Major UI overhaul with Apple-style design, hover effects, and improved layout management (rename/duplicate/import/export).

## 0.2.0
- **Breaking**: Introduced strong-typed `InputBinding` model for keyboard/gamepad input.
- **Breaking**: `VirtualButton` now requires `binding` (replaces `config.padKey`-based resolution).
- **Breaking**: `VirtualKey` now uses `binding: KeyboardBinding(...)` (replaces `key/modifiers/repeat` fields).
- **Breaking**: `VirtualDpad` directions now map to typed bindings (replaces `mode` + string maps).
- **Feat**: Added extensible `InputBindingRegistry` and `GamepadButtonId` to support custom strong-typed buttons with editor + JSON ecosystem.
- **Perf**: Reduced runtime string parsing in widgets by resolving input codes in models.

## 0.1.2
- **Fix**: Improved D-Pad label rendering with dynamic font sizing and clamping to prevent layout issues.
- **Fix**: Added `FittedBox` to `ControlLabel` to prevent text overflow.
- **Feat**: Added support for `start` and `back` button labels/IDs (maps to menu/view icons).

## 0.1.1
- **Docs**: Comprehensive documentation overhaul (README.md) with Nanny-level guides.
- **Feat**: Added `lockedColor` to `ControlStyle` for customizable joystick lock feedback.
- **Refactor**: Improved code comments and library exports.
- **Fix**: Updated package name to `virtual_gamepad_pro`.

## 0.1.0
- Initial release of **Virtual Gamepad Pro**.
- Includes:
  - Virtual Joystick, D-Pad, Buttons, Mouse Controls.
  - Runtime Layout Editor.
  - JSON Serialization/Deserialization.
  - Overlay Widget for easy integration.
