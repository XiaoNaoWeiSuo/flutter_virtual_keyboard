part of '../macro_editor_dialog.dart';

List<String> _currentModifierCodes({LogicalKeyboardKey? excluding}) {
  final pressed = HardwareKeyboard.instance.logicalKeysPressed;
  bool has(LogicalKeyboardKey k) => pressed.contains(k) && excluding != k;

  final codes = <String>[];

  final ctrl =
      has(LogicalKeyboardKey.controlLeft) || has(LogicalKeyboardKey.controlRight);
  final shift =
      has(LogicalKeyboardKey.shiftLeft) || has(LogicalKeyboardKey.shiftRight);
  final alt = has(LogicalKeyboardKey.altLeft) || has(LogicalKeyboardKey.altRight);
  final meta = has(LogicalKeyboardKey.metaLeft) || has(LogicalKeyboardKey.metaRight);

  if (ctrl) codes.add('Ctrl');
  if (shift) codes.add('Shift');
  if (alt) codes.add('Alt');
  if (meta) codes.add('Meta');
  return codes;
}

String? _toKeyCode(LogicalKeyboardKey key) {
  if (key == LogicalKeyboardKey.escape) return 'Esc';
  if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
    return 'Enter';
  }
  if (key == LogicalKeyboardKey.backspace) return 'Backspace';
  if (key == LogicalKeyboardKey.tab) return 'Tab';
  if (key == LogicalKeyboardKey.space) return 'Space';

  if (key == LogicalKeyboardKey.arrowUp) return 'ArrowUp';
  if (key == LogicalKeyboardKey.arrowDown) return 'ArrowDown';
  if (key == LogicalKeyboardKey.arrowLeft) return 'ArrowLeft';
  if (key == LogicalKeyboardKey.arrowRight) return 'ArrowRight';

  if (key == LogicalKeyboardKey.shiftLeft || key == LogicalKeyboardKey.shiftRight) {
    return 'Shift';
  }
  if (key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight) {
    return 'Ctrl';
  }
  if (key == LogicalKeyboardKey.altLeft || key == LogicalKeyboardKey.altRight) {
    return 'Alt';
  }
  if (key == LogicalKeyboardKey.metaLeft || key == LogicalKeyboardKey.metaRight) {
    return 'Meta';
  }

  final label = key.keyLabel;
  final trimmed = label.trim();
  if (trimmed.isNotEmpty) {
    if (trimmed.length == 1) return trimmed.toUpperCase();
    return trimmed;
  }

  final name = key.debugName?.trim();
  if (name == null || name.isEmpty) return null;
  return name;
}

