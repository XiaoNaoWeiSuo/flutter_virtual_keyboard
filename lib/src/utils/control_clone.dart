import '../models/virtual_controller_models.dart';

VirtualControl cloneControlWithOverrides(
  VirtualControl control, {
  ControlLayout? layout,
  ControlStyle? style,
  String? label,
  Map<String, dynamic>? config,
}) {
  final nextLayout = layout ?? control.layout;
  final nextLabel = label ?? control.label;
  final nextConfig = config ?? control.config;

  if (control is VirtualButton) {
    return VirtualButton(
      id: control.id,
      label: nextLabel,
      layout: nextLayout,
      trigger: control.trigger,
      binding: control.binding,
      config: nextConfig,
      actions: control.actions,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualJoystick) {
    return VirtualJoystick(
      id: control.id,
      label: nextLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      actions: control.actions,
      deadzone: control.deadzone,
      mode: control.mode,
      stickType: control.stickType,
      keys: control.keys,
      axes: control.axes,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualKey) {
    return VirtualKey(
      id: control.id,
      label: nextLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      binding: control.binding,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualKeyCluster) {
    return VirtualKeyCluster(
      id: control.id,
      label: nextLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      grid: control.grid,
      keySize: control.keySize,
      spacing: control.spacing,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualMouseButton) {
    return VirtualMouseButton(
      id: control.id,
      label: nextLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      button: control.button,
      clickType: control.clickType,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualMouseWheel) {
    return VirtualMouseWheel(
      id: control.id,
      label: nextLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      direction: control.direction,
      step: control.step,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualMacroButton) {
    return VirtualMacroButton(
      id: control.id,
      label: nextLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      sequence: control.sequence,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualCustomControl) {
    return VirtualCustomControl(
      id: control.id,
      label: nextLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      actions: control.actions,
      customData: control.customData,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualSplitMouse) {
    return VirtualSplitMouse(
      id: control.id,
      label: nextLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualScrollStick) {
    return VirtualScrollStick(
      id: control.id,
      label: nextLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      sensitivity: control.sensitivity,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  if (control is VirtualDpad) {
    return VirtualDpad(
      id: control.id,
      label: nextLabel,
      layout: nextLayout,
      trigger: control.trigger,
      config: nextConfig,
      actions: control.actions,
      directions: control.directions,
      enable3D: control.enable3D,
      style: style ?? control.style,
      feedback: control.feedback,
    );
  }
  return control;
}
