import '../models/input_event.dart';
import '../models/binding/binding.dart';
import '../models/identifiers.dart';

class RecordedInputEvent {
  const RecordedInputEvent({
    required this.type,
    required this.delayMs,
    required this.data,
  });

  factory RecordedInputEvent.fromJson(Map<String, dynamic> json) {
    return RecordedInputEvent(
      type: json['type'] as String,
      delayMs: (json['delayMs'] as num?)?.toInt() ?? 0,
      data: json['data'] is Map
          ? Map<String, dynamic>.from(json['data'] as Map)
          : const {},
    );
  }

  final String type;
  final int delayMs;
  final Map<String, dynamic> data;

  Map<String, dynamic> toJson() => {
        'type': type,
        if (delayMs > 0) 'delayMs': delayMs,
        if (data.isNotEmpty) 'data': data,
      };

  static RecordedInputEvent? tryFromInputEvent(
    InputEvent event, {
    required int delayMs,
  }) {
    if (event is KeyboardInputEvent) {
      return RecordedInputEvent(
        type: 'keyboard',
        delayMs: delayMs,
        data: {
          'key': event.key.code,
          'isDown': event.isDown,
          if (event.modifiers.isNotEmpty)
            'modifiers': event.modifiers.map((m) => m.code).toList(),
        },
      );
    }

    if (event is MouseButtonInputEvent) {
      return RecordedInputEvent(
        type: 'mouse_button',
        delayMs: delayMs,
        data: {
          'button': event.button.code,
          'isDown': event.isDown,
        },
      );
    }

    if (event is MouseWheelInputEvent) {
      return RecordedInputEvent(
        type: 'mouse_wheel',
        delayMs: delayMs,
        data: {
          'direction': event.direction.code,
          'delta': event.delta,
        },
      );
    }

    if (event is MouseWheelVectorInputEvent) {
      return RecordedInputEvent(
        type: 'mouse_wheel_vector',
        delayMs: delayMs,
        data: {
          'dx': event.dx,
          'dy': event.dy,
        },
      );
    }

    if (event is GamepadButtonInputEvent) {
      return RecordedInputEvent(
        type: 'gamepad_button',
        delayMs: delayMs,
        data: {
          'button': event.button.code,
          'isDown': event.isDown,
        },
      );
    }

    if (event is GamepadAxisInputEvent) {
      return RecordedInputEvent(
        type: 'gamepad_axis',
        delayMs: delayMs,
        data: {
          'axisId': event.axisId.code,
          'x': event.x,
          'y': event.y,
        },
      );
    }

    if (event is JoystickInputEvent) {
      return RecordedInputEvent(
        type: 'joystick',
        delayMs: delayMs,
        data: {
          'dx': event.dx,
          'dy': event.dy,
          'activeKeys': event.activeKeys.map((k) => k.code).toList(),
        },
      );
    }

    if (event is CustomInputEvent) {
      return RecordedInputEvent(
        type: 'custom',
        delayMs: delayMs,
        data: {
          'id': event.id,
          if (event.data.isNotEmpty) 'data': event.data,
        },
      );
    }

    if (event is MacroInputEvent) {
      return null;
    }

    return null;
  }

  InputEvent? toInputEvent() {
    switch (type) {
      case 'keyboard':
        final key = data['key'] as String?;
        final isDown = data['isDown'] as bool?;
        if (key == null || isDown == null) return null;
        final modifiersRaw =
            List<String>.from(data['modifiers'] as List? ?? const []);
        final modifiers = modifiersRaw
            .map((e) => KeyboardKey(e).normalized())
            .where((k) => k.code.trim().isNotEmpty && k.code != 'null')
            .toList(growable: false);
        return KeyboardInputEvent(
          key: KeyboardKey(key).normalized(),
          isDown: isDown,
          modifiers: modifiers,
        );

      case 'mouse_button':
        final button = data['button'] as String?;
        final isDown = data['isDown'] as bool?;
        if (button == null || isDown == null) return null;
        final parsed = MouseButtonId.tryParse(button);
        if (parsed == null) return null;
        return MouseButtonInputEvent(button: parsed, isDown: isDown);

      case 'mouse_wheel':
        final direction = data['direction'] as String?;
        final delta = (data['delta'] as num?)?.toInt();
        if (direction == null || delta == null) return null;
        final parsed = MouseWheelDirection.tryParse(direction);
        if (parsed == null) return null;
        return MouseWheelInputEvent(direction: parsed, delta: delta);

      case 'mouse_wheel_vector':
        final dx = (data['dx'] as num?)?.toDouble();
        final dy = (data['dy'] as num?)?.toDouble();
        if (dx == null || dy == null) return null;
        return MouseWheelVectorInputEvent(dx: dx, dy: dy);

      case 'gamepad_button':
        final button = data['button'] as String?;
        final isDown = data['isDown'] as bool?;
        if (button == null || isDown == null) return null;
        return GamepadButtonInputEvent(
          button: GamepadButtonId.parse(button),
          isDown: isDown,
        );

      case 'gamepad_axis':
        final axisId = data['axisId'] as String?;
        final x = (data['x'] as num?)?.toDouble();
        final y = (data['y'] as num?)?.toDouble();
        if (axisId == null || x == null || y == null) return null;
        return GamepadAxisInputEvent(
          axisId: GamepadStickId.parse(axisId),
          x: x,
          y: y,
        );

      case 'joystick':
        final dx = (data['dx'] as num?)?.toDouble();
        final dy = (data['dy'] as num?)?.toDouble();
        if (dx == null || dy == null) return null;
        final rawKeys =
            List<String>.from(data['activeKeys'] as List? ?? const []);
        final activeKeys = rawKeys
            .map((e) => KeyboardKey(e).normalized())
            .where((k) => k.code.trim().isNotEmpty && k.code != 'null')
            .toList(growable: false);
        return JoystickInputEvent(dx: dx, dy: dy, activeKeys: activeKeys);

      case 'custom':
        final id = data['id'] as String?;
        if (id == null) return null;
        final payload = data['data'] is Map
            ? Map<String, dynamic>.from(data['data'] as Map)
            : const <String, dynamic>{};
        return CustomInputEvent(id: id, data: payload);

      default:
        return null;
    }
  }
}
