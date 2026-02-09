part of 'binding.dart';

String normalizeGamepadButtonCode(String raw) {
  final lower = raw.trim().toLowerCase();
  return switch (lower) {
    '△' => 'triangle',
    '○' => 'circle',
    '□' => 'square',
    '×' => 'cross',
    _ => lower,
  };
}

final class GamepadButtonId {
  const GamepadButtonId._(this.code, {this.label});

  final String code;
  final String? label;

  static const a = GamepadButtonId._('a', label: 'A');
  static const b = GamepadButtonId._('b', label: 'B');
  static const x = GamepadButtonId._('x', label: 'X');
  static const y = GamepadButtonId._('y', label: 'Y');

  static const lb = GamepadButtonId._('lb', label: 'LB');
  static const rb = GamepadButtonId._('rb', label: 'RB');
  static const lt = GamepadButtonId._('lt', label: 'LT');
  static const rt = GamepadButtonId._('rt', label: 'RT');

  static const l1 = GamepadButtonId._('l1', label: 'L1');
  static const r1 = GamepadButtonId._('r1', label: 'R1');
  static const l2 = GamepadButtonId._('l2', label: 'L2');
  static const r2 = GamepadButtonId._('r2', label: 'R2');

  static const back = GamepadButtonId._('back', label: 'Back');
  static const start = GamepadButtonId._('start', label: 'Start');
  static const view = GamepadButtonId._('view', label: 'View');
  static const menu = GamepadButtonId._('menu', label: 'Menu');
  static const options = GamepadButtonId._('options', label: 'Options');
  static const share = GamepadButtonId._('share', label: 'Share');

  static const dpadUp = GamepadButtonId._('dpad_up', label: 'DpadUp');
  static const dpadDown = GamepadButtonId._('dpad_down', label: 'DpadDown');
  static const dpadLeft = GamepadButtonId._('dpad_left', label: 'DpadLeft');
  static const dpadRight = GamepadButtonId._('dpad_right', label: 'DpadRight');

  static const l3 = GamepadButtonId._('l3', label: 'L3');
  static const r3 = GamepadButtonId._('r3', label: 'R3');

  static const triangle = GamepadButtonId._('triangle', label: 'Triangle');
  static const circle = GamepadButtonId._('circle', label: 'Circle');
  static const square = GamepadButtonId._('square', label: 'Square');
  static const cross = GamepadButtonId._('cross', label: 'Cross');

  static const List<GamepadButtonId> builtIns = [
    a,
    b,
    x,
    y,
    lb,
    rb,
    lt,
    rt,
    l1,
    r1,
    l2,
    r2,
    back,
    start,
    view,
    menu,
    options,
    share,
    dpadUp,
    dpadDown,
    dpadLeft,
    dpadRight,
    l3,
    r3,
    triangle,
    circle,
    square,
    cross,
  ];

  static GamepadButtonId? tryParse(String raw) =>
      InputBindingRegistry.tryGetGamepadButton(raw);

  static GamepadButtonId parse(String raw) {
    final parsed = tryParse(raw);
    if (parsed == null) {
      throw FormatException('Unknown gamepad button: ${raw.trim()}');
    }
    return parsed;
  }

  static GamepadButtonId _custom(String code, {String? label}) {
    final normalized = normalizeGamepadButtonCode(code);
    return GamepadButtonId._(normalized, label: label);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is GamepadButtonId && other.code == code;

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => code;
}
