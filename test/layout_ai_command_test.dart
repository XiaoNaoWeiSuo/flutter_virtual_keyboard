import 'package:flutter_test/flutter_test.dart';
import 'package:virtual_gamepad_pro/src/editor/ai/layout_ai_command.dart';
import 'package:virtual_gamepad_pro/src/editor/virtual_controller_layout_editor_controller.dart';
import 'package:virtual_gamepad_pro/src/models/virtual_controller_models.dart';

void main() {
  group('LayoutAICommand Tests', () {
    test('JSON serialization/deserialization', () {
      final json = {
        'action': 'add',
        'type': 'button',
        'id': 'btn_1',
        'label': 'Test',
        'x': 0.1,
        'y': 0.2,
        'width': 0.3,
        'height': 0.4,
      };

      final cmd = LayoutAICommand.fromJson(json);
      expect(cmd.action, LayoutAIAction.add);
      expect(cmd.type, 'button');
      expect(cmd.id, 'btn_1');
      expect(cmd.label, 'Test');
      expect(cmd.x, 0.1);

      final out = cmd.toJson();
      expect(out['action'], 'add');
      expect(out['id'], 'btn_1');
    });

    test('Execute add command', () {
      final controller = VirtualControllerLayoutEditorController(
        definition: const VirtualControllerLayout(schemaVersion: 1, name: 'test', controls: []),
        state: const VirtualControllerState(schemaVersion: 1, name: 'test', controls: []),
        allowAddRemove: true,
      );

      controller.executeAICommands([
        const LayoutAICommand(
          action: LayoutAIAction.add,
          type: 'button',
          id: 'btn_test',
          label: 'Test',
          x: 0.5,
          y: 0.5,
        ),
      ]);

      expect(controller.layout.controls.length, 1);
      final btn = controller.layout.controls.first;
      expect(btn.id, 'btn_test');
      expect(btn.label, 'Test');
      expect(btn.layout.x, 0.5);
    });

    test('Execute move command', () {
      final controller = VirtualControllerLayoutEditorController(
        definition: const VirtualControllerLayout(schemaVersion: 1, name: 'test', controls: []),
        state: const VirtualControllerState(schemaVersion: 1, name: 'test', controls: []),
        allowAddRemove: true,
        allowMove: true,
      );

      // Add first
      controller.executeAICommands([
        const LayoutAICommand(
          action: LayoutAIAction.add,
          type: 'button',
          id: 'btn_test',
        ),
      ]);

      // Move
      controller.executeAICommands([
        const LayoutAICommand(
          action: LayoutAIAction.move,
          id: 'btn_test',
          x: 0.1,
          y: 0.1,
        ),
      ]);

      final btn = controller.layout.controls.first;
      expect(btn.layout.x, 0.1);
      expect(btn.layout.y, 0.1);
    });

     test('Execute resize command', () {
      final controller = VirtualControllerLayoutEditorController(
        definition: const VirtualControllerLayout(schemaVersion: 1, name: 'test', controls: []),
        state: const VirtualControllerState(schemaVersion: 1, name: 'test', controls: []),
        allowAddRemove: true,
        allowResize: true,
      );

      // Add first
      controller.executeAICommands([
        const LayoutAICommand(
          action: LayoutAIAction.add,
          type: 'button',
          id: 'btn_test',
          width: 0.2,
          height: 0.2,
        ),
      ]);

      // Resize
      controller.executeAICommands([
        const LayoutAICommand(
          action: LayoutAIAction.resize,
          id: 'btn_test',
          width: 0.3,
          height: 0.3,
        ),
      ]);

      final btn = controller.layout.controls.first;
      expect(btn.layout.width, 0.3);
      expect(btn.layout.height, 0.3);
    });

    test('Execute rename command', () {
      final controller = VirtualControllerLayoutEditorController(
        definition: const VirtualControllerLayout(schemaVersion: 1, name: 'test', controls: []),
        state: const VirtualControllerState(schemaVersion: 1, name: 'test', controls: []),
        allowAddRemove: true,
        allowRename: true,
      );

      // Add first
      controller.executeAICommands([
        const LayoutAICommand(
          action: LayoutAIAction.add,
          type: 'button',
          id: 'btn_test',
          label: 'Old Name',
        ),
      ]);

      // Rename
      controller.executeAICommands([
        const LayoutAICommand(
          action: LayoutAIAction.rename,
          id: 'btn_test',
          label: 'New Name',
        ),
      ]);

      final btn = controller.layout.controls.first;
      expect(btn.label, 'New Name');
    });
  });
}
