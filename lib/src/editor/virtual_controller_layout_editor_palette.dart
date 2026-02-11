import 'package:flutter/material.dart';
import '../models/virtual_controller_models.dart';
import '../widgets/controls/button_widget.dart';
import '../widgets/controls/dpad_widget.dart';
import '../widgets/controls/joystick_widget.dart';
import '../widgets/controls/key_widget.dart';
import '../widgets/controls/macro_button_widget.dart';
import '../widgets/controls/mouse_button_widget.dart';
import '../widgets/controls/scroll_stick_widget.dart';
import '../widgets/controls/split_mouse_widget.dart';
import 'editor_control_factory.dart';
import 'editor_palette_tab.dart';

part 'palette/virtual_controller_layout_editor_palette_body.dart';
part 'palette/virtual_controller_layout_editor_palette_prototypes.dart';
part 'palette/virtual_controller_layout_editor_palette_tiles.dart';

class VirtualControllerLayoutEditorPalette extends StatelessWidget {
  const VirtualControllerLayoutEditorPalette({
    super.key,
    required this.tab,
    required this.onAddControl,
    this.previewDecorator,
  });

  final VirtualControllerEditorPaletteTab tab;
  final ValueChanged<VirtualControl> onAddControl;
  final VirtualControllerLayout Function(VirtualControllerLayout layout)?
      previewDecorator;

  @override
  Widget build(BuildContext context) {
    final prototypes = _prototypesFor(tab);
    final previewMap = _decorate(prototypes);

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SafeArea(
            top: false,
            bottom: false,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth:
                    (MediaQuery.of(context).size.width - 16).clamp(0, 720),
              ),
              child: Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1C1C1E),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(8, 2, 8, 8),
                        child: _Body(
                          tab: tab,
                          previewMap: previewMap,
                          onAddControl: onAddControl,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Map<String, VirtualControl> _decorate(List<VirtualControl> prototypes) {
    final decorator = previewDecorator;
    if (decorator == null) return {for (final c in prototypes) c.id: c};
    final layout = VirtualControllerLayout(
      schemaVersion: 1,
      name: 'palette',
      controls: prototypes,
    );
    final decorated = decorator(layout);
    return {for (final c in decorated.controls) c.id: c};
  }
}
