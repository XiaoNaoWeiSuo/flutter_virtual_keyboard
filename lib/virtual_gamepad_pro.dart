/// Flutter Virtual Keyboard
///
/// A pure Flutter implementation of a virtual keyboard/controller system.
/// No external dependencies, no assets required.
library virtual_gamepad_pro;

export 'src/models/input_event.dart';
export 'src/models/identifiers.dart';
export 'src/models/virtual_controller_models.dart';
export 'src/macro/recorded_timeline_event.dart';
export 'src/widgets/virtual_controller_overlay.dart';
export 'src/widgets/system_ui_mode_scope.dart';
export 'src/widgets/macro/virtual_controller_macro_recording_session.dart';

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
export 'src/utils/layout_state_protocol.dart';
export 'src/utils/control_clone.dart';
export 'src/utils/layout_transform.dart';
export 'src/theme/virtual_control_theme.dart';
export 'src/theme/control_matchers.dart';
export 'src/theme/rule_based_theme.dart';
export 'src/editor/resize_direction.dart';
export 'src/editor/virtual_controller_layout_editor_canvas.dart';
export 'src/editor/editor_palette_tab.dart';
export 'src/editor/editor_control_factory.dart';
export 'src/editor/virtual_controller_layout_editor_palette.dart';
export 'src/editor/virtual_controller_layout_editor_controller.dart';
export 'src/editor/virtual_controller_layout_editor.dart';
export 'src/editor/macro/macro_suite_page.dart';
