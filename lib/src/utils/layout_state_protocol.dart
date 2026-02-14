import '../core/dynamic_control_factory.dart';
import '../models/virtual_controller_models.dart';

VirtualControllerLayout buildDefinitionFromState(
  VirtualControllerState state, {
  bool runtimeDefaults = true,
  String? fallbackName,
}) {
  final controls = <VirtualControl>[];
  for (final s in state.controls) {
    final c =
        dynamicControlFromId(s.id, s.layout, runtimeDefaults: runtimeDefaults);
    if (c != null) controls.add(c);
  }
  return VirtualControllerLayout(
    schemaVersion: state.schemaVersion,
    name: (state.name?.trim().isNotEmpty ?? false)
        ? state.name!.trim()
        : (fallbackName ?? 'Untitled'),
    controls: controls,
  );
}
