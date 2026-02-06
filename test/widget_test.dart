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
        ),
      ],
    );

    // Build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: VirtualControllerOverlay(
            layout: layout,
            onInputEvent: (event) {},
          ),
        ),
      ),
    );

    // Verify the button is present
    expect(find.text('A'), findsOneWidget);
    expect(find.byType(VirtualControllerOverlay), findsOneWidget);
  });
}
