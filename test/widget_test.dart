import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

void main() {
  testWidgets('VirtualControllerOverlay builds correctly',
      (WidgetTester tester) async {
    // Define a simple layout with one button
    final layout = VirtualControllerLayout(
      schemaVersion: 1,
      name: 'Test Layout',
      controls: [
        VirtualButton(
          id: 'btn_a',
          label: 'A',
          layout: const ControlLayout(x: 0.8, y: 0.8, width: 0.1, height: 0.1),
          trigger: TriggerType.tap,
          binding: const GamepadButtonBinding(GamepadButtonId.a),
        ),
      ],
    );

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VirtualControllerOverlay(
            definition: layout,
            state: const VirtualControllerState(schemaVersion: 1, controls: []),
            onInputEvent: (event) {},
          ),
        ),
      ),
    );

    // Verify the button is present
    expect(find.text('A'), findsOneWidget);
    expect(find.byType(VirtualControllerOverlay), findsOneWidget);
  });

  testWidgets('WASD joystick edge presses Shift sprint',
      (WidgetTester tester) async {
    final events = <InputEvent>[];

    final control = VirtualJoystick(
      id: 'joystick_wasd_test',
      label: '',
      layout: const ControlLayout(x: 0.5, y: 0.5, width: 0.4, height: 0.4),
      trigger: TriggerType.hold,
      keys: const [
        KeyboardKey('W'),
        KeyboardKey('A'),
        KeyboardKey('S'),
        KeyboardKey('D'),
      ],
      config: const {},
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: VirtualJoystickWidget(
                control: control,
                onInputEvent: events.add,
              ),
            ),
          ),
        ),
      ),
    );

    final finder = find.byType(VirtualJoystickWidget);
    final center = tester.getCenter(finder);

    final gesture = await tester.startGesture(center);
    await tester.pump();

    await gesture.moveTo(center + const Offset(90, 0));
    await tester.pump();

    final keyboardEvents = events.whereType<KeyboardInputEvent>().toList();
    expect(
      keyboardEvents.any((e) => e.isDown && e.key.code == 'D'),
      isTrue,
    );
    expect(
      keyboardEvents.any((e) => e.isDown && e.key.code == 'ShiftLeft'),
      isTrue,
    );
    expect(
      keyboardEvents.any((e) => !e.isDown && e.key.code == 'ShiftLeft'),
      isFalse,
    );

    await tester.pump(const Duration(milliseconds: 200));
    expect(
      events
          .whereType<KeyboardInputEvent>()
          .any((e) => !e.isDown && e.key.code == 'ShiftLeft'),
      isFalse,
    );

    await gesture.moveTo(center + const Offset(40, 0));
    await tester.pump();

    expect(
      events
          .whereType<KeyboardInputEvent>()
          .any((e) => !e.isDown && e.key.code == 'ShiftLeft'),
      isTrue,
    );

    await gesture.up();
    await tester.pump();

    expect(
      events
          .whereType<KeyboardInputEvent>()
          .any((e) => !e.isDown && e.key.code == 'D'),
      isTrue,
    );
  });
}
