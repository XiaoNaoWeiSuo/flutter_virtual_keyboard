/// Flutter Virtual Keyboard
///
/// A pure Flutter implementation of a virtual keyboard/controller system.
/// No external dependencies, no assets required.
library flutter_virtual_keyboard;

export 'src/models/input_event.dart';
export 'src/models/virtual_controller_models.dart';
export 'src/widgets/virtual_controller_overlay.dart';

// Export shared widgets for editor usage
export 'src/widgets/shared/control_container.dart';
export 'src/widgets/shared/control_label.dart';

// Export control widgets
export 'src/widgets/controls/key_widget.dart';
export 'src/widgets/controls/button_widget.dart';
export 'src/widgets/controls/mouse_button_widget.dart';
export 'src/widgets/controls/mouse_wheel_widget.dart';
export 'src/widgets/controls/joystick_widget.dart';
export 'src/widgets/controls/dpad_widget.dart';
export 'src/widgets/controls/scroll_stick_widget.dart';
export 'src/widgets/controls/split_mouse_widget.dart';
export 'src/utils/style_codec.dart';
export 'src/utils/control_geometry.dart';
export 'src/editor/resize_direction.dart';
export 'src/editor/virtual_controller_layout_editor_canvas.dart';
export 'src/editor/editor_palette_tab.dart';
export 'src/editor/editor_control_factory.dart';
export 'src/editor/virtual_controller_layout_editor_palette.dart';
export 'src/editor/virtual_controller_layout_editor_controller.dart';
export 'src/editor/virtual_controller_layout_editor.dart';
