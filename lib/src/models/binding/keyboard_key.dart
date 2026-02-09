part of 'binding.dart';

class KeyboardKey {
  const KeyboardKey(this.code);

  final String code;

  KeyboardKey normalized() {
    final t = code.trim();
    if (t.isEmpty) return this;

    final normalized = switch (t) {
      '↑' => 'ArrowUp',
      '↓' => 'ArrowDown',
      '←' => 'ArrowLeft',
      '→' => 'ArrowRight',
      _ => switch (t.toLowerCase()) {
          'up' => 'ArrowUp',
          'down' => 'ArrowDown',
          'left' => 'ArrowLeft',
          'right' => 'ArrowRight',
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
