part of 'binding.dart';

class KeyboardKey {
  const KeyboardKey(this.code);

  final String code;

  KeyboardKey normalized() {
    final t = code.trim();
    if (t.isEmpty) return this;

    if (t.length == 1) {
      final c = t.codeUnitAt(0);
      final isLetter = (c >= 65 && c <= 90) || (c >= 97 && c <= 122);
      if (isLetter) return KeyboardKey(t.toUpperCase());
      return this;
    }

    final lower = t.toLowerCase();
    final normalized = switch (lower) {
      'esc' || 'escape' => 'Escape',
      'enter' || 'return' => 'Enter',
      'space' => 'Space',
      'tab' => 'Tab',
      'backspace' || 'back' => 'Backspace',
      'ctrl' || 'control' => 'ControlLeft',
      'shift' => 'ShiftLeft',
      'alt' => 'AltLeft',
      'meta' || 'cmd' || 'win' => 'MetaLeft',
      'up' => 'ArrowUp',
      'down' => 'ArrowDown',
      'left' => 'ArrowLeft',
      'right' => 'ArrowRight',
      _ => switch (t) {
          '↑' => 'ArrowUp',
          '↓' => 'ArrowDown',
          '←' => 'ArrowLeft',
          '→' => 'ArrowRight',
          _ => t,
        },
    };

    return KeyboardKey(normalized);
  }

  @override
  String toString() => code;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is KeyboardKey && other.code == code;

  @override
  int get hashCode => code.hashCode;
}

final class KeyboardKeys {
  const KeyboardKeys._();

  static const space = KeyboardKey('Space');
  static const tab = KeyboardKey('Tab');
  static const enter = KeyboardKey('Enter');
  static const escape = KeyboardKey('Escape');
  static const backspace = KeyboardKey('Backspace');

  static const shiftLeft = KeyboardKey('ShiftLeft');
  static const shiftRight = KeyboardKey('ShiftRight');
  static const controlLeft = KeyboardKey('ControlLeft');
  static const controlRight = KeyboardKey('ControlRight');
  static const altLeft = KeyboardKey('AltLeft');
  static const altRight = KeyboardKey('AltRight');
  static const metaLeft = KeyboardKey('MetaLeft');
  static const metaRight = KeyboardKey('MetaRight');

  static const arrowUp = KeyboardKey('ArrowUp');
  static const arrowDown = KeyboardKey('ArrowDown');
  static const arrowLeft = KeyboardKey('ArrowLeft');
  static const arrowRight = KeyboardKey('ArrowRight');
}
