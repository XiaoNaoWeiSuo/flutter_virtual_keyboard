import 'package:flutter/material.dart';
import '../../models/binding/binding.dart';
import 'gamepad_symbol.dart';

String normalizeMacroInputToken(String raw) {
  var t = raw.trim().toLowerCase();
  if (t.isEmpty) return '';
  t = t.replaceAll('-', '_').replaceAll(' ', '_');
  while (t.contains('__')) {
    t = t.replaceAll('__', '_');
  }
  for (final prefix in const [
    'pad_',
    'pad',
    'gamepad_',
    'gamepad',
    'button_',
    'button',
    'axis_',
    'axis',
  ]) {
    if (t.startsWith(prefix)) {
      t = t.substring(prefix.length);
      break;
    }
  }
  if (t.startsWith('_')) t = t.substring(1);
  if (t.endsWith('_')) t = t.substring(0, t.length - 1);
  return t.trim();
}

Widget macroInputGlyph({
  required String type,
  required Map<String, dynamic> data,
  double size = 18,
  Color? color,
}) {
  switch (type) {
    case 'keyboard':
      final keyRaw = data['key']?.toString() ?? '';
      final mods = List<String>.from(data['modifiers'] as List? ?? const []);
      final key = KeyboardKey(keyRaw).normalized().code;
      final keyText = _keyboardKeyText(key);
      final modText =
          mods.map(_modifierText).where((e) => e.isNotEmpty).toList();
      if (modText.isEmpty) {
        return _keycap(keyText, size: size, color: color);
      }
      return Wrap(
        spacing: 4,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final m in modText) _keycap(m, size: size, color: color),
          _keycap(keyText, size: size, color: color),
        ],
      );

    case 'mouse_button':
      final btn = normalizeMacroInputToken(data['button']?.toString() ?? '');
      final text = switch (btn) {
        'left' => 'LMB',
        'right' => 'RMB',
        'middle' => 'MMB',
        _ => btn.isEmpty ? 'Mouse' : btn.toUpperCase(),
      };
      return _keycap(text, size: size, color: color);

    case 'gamepad_button':
      final raw = data['button']?.toString() ?? '';
      final token = normalizeMacroInputToken(raw);
      final norm = normalizeGamepadButtonCode(token);
      if (norm.startsWith('dpad_')) {
        final arrow = switch (norm) {
          'dpad_up' => '↑',
          'dpad_down' => '↓',
          'dpad_left' => '←',
          'dpad_right' => '→',
          _ => 'D',
        };
        return _keycap(arrow, size: size, color: color);
      }
      final parsed =
          GamepadButtonId.tryParse(token) ?? GamepadButtonId.tryParse(norm);
      final label = (parsed?.label ?? parsed?.code ?? norm).toString();
      return GamepadSymbol(
        id: 'btn_${parsed?.code ?? norm}',
        label: label,
        size: size,
        color: color,
      );

    case 'gamepad_axis':
      final axisId = normalizeMacroInputToken(data['axisId']?.toString() ?? '');
      final text = switch (axisId) {
        'left' => 'LS',
        'right' => 'RS',
        'lt' || 'left_trigger' => 'LT',
        'rt' || 'right_trigger' => 'RT',
        _ => axisId.isEmpty ? 'AXIS' : axisId.toUpperCase(),
      };
      return _keycap(text, size: size, color: color);

    case 'joystick':
      return _keycap('STICK', size: size, color: color);

    default:
      return _keycap(type.toUpperCase(), size: size, color: color);
  }
}

String macroInputGlyphLabel({
  required String type,
  required Map<String, dynamic> data,
}) {
  switch (type) {
    case 'keyboard':
      final keyRaw = data['key']?.toString() ?? '';
      final mods = List<String>.from(data['modifiers'] as List? ?? const []);
      final key = KeyboardKey(keyRaw).normalized().code;
      final keyText = _keyboardKeyText(key);
      final modText =
          mods.map(_modifierText).where((e) => e.isNotEmpty).toList();
      if (modText.isEmpty) return keyText;
      return '${modText.join(' ')} $keyText';

    case 'mouse_button':
      final btn = normalizeMacroInputToken(data['button']?.toString() ?? '');
      return switch (btn) {
        'left' => 'LMB',
        'right' => 'RMB',
        'middle' => 'MMB',
        _ => btn.isEmpty ? 'Mouse' : btn.toUpperCase(),
      };

    case 'gamepad_button':
      final raw = data['button']?.toString() ?? '';
      final token = normalizeMacroInputToken(raw);
      final norm = normalizeGamepadButtonCode(token);
      if (norm.startsWith('dpad_')) {
        return switch (norm) {
          'dpad_up' => '↑',
          'dpad_down' => '↓',
          'dpad_left' => '←',
          'dpad_right' => '→',
          _ => 'Dpad',
        };
      }
      if (norm == 'triangle') return '△';
      if (norm == 'circle') return '○';
      if (norm == 'square') return '□';
      if (norm == 'cross') return '×';
      final parsed =
          GamepadButtonId.tryParse(token) ?? GamepadButtonId.tryParse(norm);
      return (parsed?.label ?? parsed?.code ?? norm).toString().toUpperCase();

    case 'gamepad_axis':
      final axisId = normalizeMacroInputToken(data['axisId']?.toString() ?? '');
      return switch (axisId) {
        'left' => 'LS',
        'right' => 'RS',
        'lt' || 'left_trigger' => 'LT',
        'rt' || 'right_trigger' => 'RT',
        _ => axisId.isEmpty ? 'AXIS' : axisId.toUpperCase(),
      };

    case 'joystick':
      return 'Stick';

    default:
      return type;
  }
}

String _keyboardKeyText(String code) {
  final t = code.trim();
  if (t.isEmpty) return 'Key';
  return switch (t) {
    'ArrowUp' => '↑',
    'ArrowDown' => '↓',
    'ArrowLeft' => '←',
    'ArrowRight' => '→',
    'Escape' => '⎋',
    'Enter' => '⏎',
    'Backspace' => '⌫',
    'Tab' => '⇥',
    'Space' => '␣',
    _ => t.length == 1 ? t.toUpperCase() : t,
  };
}

String _modifierText(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  return switch (t.toLowerCase()) {
    'ctrl' || 'control' => '⌃',
    'shift' => '⇧',
    'alt' || 'option' => '⌥',
    'meta' || 'cmd' || 'command' => '⌘',
    _ => t.toUpperCase(),
  };
}

Widget _keycap(
  String text, {
  required double size,
  Color? color,
}) {
  final h = (size * 1.15).clamp(16.0, 26.0);
  final minW = (size * 1.25).clamp(18.0, 34.0);
  return Container(
    constraints: BoxConstraints(minWidth: minW, minHeight: h),
    // padding: const EdgeInsets.symmetric(horizontal: 6),
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(999),
      border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
    ),
    child: Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.fade,
      softWrap: false,
      style: TextStyle(
        color: color ?? Colors.white,
        fontSize: (size * 0.50).clamp(7.0, 14.0),
        fontWeight: FontWeight.w900,
        height: 1.0,
        letterSpacing: -0.2,
      ),
    ),
  );
}
