import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

void main() {
  testWidgets('Macro button trims leading empty time',
      (WidgetTester tester) async {
    final events = <InputEvent>[];

    final layout = VirtualControllerLayout(
      schemaVersion: 1,
      name: 'Test Layout',
      controls: [
        VirtualMacroButton(
          id: 'macro_1',
          label: 'Macro',
          layout: const ControlLayout(x: 0.1, y: 0.1, width: 0.3, height: 0.2),
          trigger: TriggerType.tap,
          config: const {
            'recordingV2': [
              {
                'atMs': 500,
                'type': 'mouse_button',
                'data': {'button': 'left', 'isDown': true},
              },
              {
                'atMs': 500,
                'type': 'mouse_button',
                'data': {'button': 'left', 'isDown': false},
              },
            ],
          },
          sequence: const [],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 240,
            child: VirtualControllerOverlay(
              definition: layout,
              state:
                  const VirtualControllerState(schemaVersion: 1, controls: []),
              onInputEvent: events.add,
              opacity: 1,
              showLabels: true,
              immersive: false,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Macro'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1));

    expect(events.length, equals(2));
  });

  testWidgets('Macro button long press locks loop and tap cancels',
      (WidgetTester tester) async {
    final events = <InputEvent>[];

    final layout = VirtualControllerLayout(
      schemaVersion: 1,
      name: 'Test Layout',
      controls: [
        VirtualMacroButton(
          id: 'macro_1',
          label: 'Macro',
          layout: const ControlLayout(x: 0.1, y: 0.1, width: 0.3, height: 0.2),
          trigger: TriggerType.tap,
          config: const {
            'recordingV2': [
              {
                'atMs': 0,
                'type': 'mouse_button',
                'data': {'button': 'left', 'isDown': true},
              },
              {
                'atMs': 0,
                'type': 'mouse_button',
                'data': {'button': 'left', 'isDown': false},
              },
            ],
          },
          sequence: const [],
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 240,
            child: VirtualControllerOverlay(
              definition: layout,
              state:
                  const VirtualControllerState(schemaVersion: 1, controls: []),
              onInputEvent: events.add,
              opacity: 1,
              showLabels: true,
              immersive: false,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Macro'), findsOneWidget);
    expect(find.byIcon(Icons.lock), findsNothing);

    await tester.longPress(find.text('Macro'));
    await tester.pump();

    expect(find.byIcon(Icons.lock), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 220));
    final countWhileLocked = events.length;
    expect(countWhileLocked, greaterThanOrEqualTo(4));

    await tester.tap(find.text('Macro'));
    await tester.pump();
    expect(find.byIcon(Icons.lock), findsNothing);

    await tester.pump(const Duration(milliseconds: 400));
    expect(events.length, equals(countWhileLocked));
  });
}
