import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../models/style/control_layout.dart';
import '../models/virtual_controller_models.dart';
import '../utils/control_geometry.dart';
import 'resize_direction.dart';

class VirtualControllerLayoutEditorController extends ChangeNotifier {
  VirtualControllerLayoutEditorController({
    required VirtualControllerLayout layout,
    this.readOnly = false,
    this.allowAddRemove = true,
    this.allowResize = true,
    this.allowMove = true,
    this.allowRename = true,
  }) : _layout = layout;

  VirtualControllerLayout _layout;
  VirtualControl? _selected;
  ControlLayout? _selectedBaseLayout;
  double _selectedScale = 1.0;
  bool _isDirty = false;

  final bool readOnly;
  final bool allowAddRemove;
  final bool allowResize;
  final bool allowMove;
  final bool allowRename;

  VirtualControllerLayout get layout => _layout;
  VirtualControl? get selectedControl => _selected;
  double get selectedScale => _selectedScale;
  double get selectedOpacity {
    final v = _selected?.config['opacity'];
    if (v is num) return v.toDouble().clamp(0.0, 1.0);
    return 1.0;
  }

  bool get isDirty => _isDirty;

  void replaceLayout(VirtualControllerLayout layout, {bool markDirty = false}) {
    _layout = layout;
    _isDirty = markDirty;
    if (_selected != null) {
      final next = layout.controls
          .where((c) => c.id == _selected!.id)
          .cast<VirtualControl?>()
          .firstOrNull;
      _selected = next;
      _selectedBaseLayout = next?.layout;
    }
    notifyListeners();
  }

  void renameLayout(String name) {
    if (readOnly || !allowRename) return;
    _layout = VirtualControllerLayout(
      schemaVersion: _layout.schemaVersion,
      name: name,
      controls: _layout.controls,
    );
    _isDirty = true;
    notifyListeners();
  }

  void selectControl(VirtualControl? control) {
    _selected = control;
    _selectedScale = 1.0;
    _selectedBaseLayout = control?.layout;
    notifyListeners();
  }

  void addControl(VirtualControl control) {
    if (readOnly || !allowAddRemove) return;
    final nextControls = List<VirtualControl>.from(_layout.controls)
      ..add(control);
    _layout = VirtualControllerLayout(
      schemaVersion: _layout.schemaVersion,
      name: _layout.name,
      controls: nextControls,
    );
    _isDirty = true;
    selectControl(control);
  }

  void deleteSelected() {
    if (readOnly || !allowAddRemove) return;
    final selected = _selected;
    if (selected == null) return;
    final nextControls =
        _layout.controls.where((c) => c.id != selected.id).toList();
    _layout = VirtualControllerLayout(
      schemaVersion: _layout.schemaVersion,
      name: _layout.name,
      controls: nextControls,
    );
    _isDirty = true;
    selectControl(null);
  }

  void updateControl(VirtualControl updated) {
    final idx = _layout.controls.indexWhere((c) => c.id == updated.id);
    if (idx == -1) return;
    final nextControls = List<VirtualControl>.from(_layout.controls);
    nextControls[idx] = updated;
    _layout = VirtualControllerLayout(
      schemaVersion: _layout.schemaVersion,
      name: _layout.name,
      controls: nextControls,
    );
    _isDirty = true;
    if (_selected?.id == updated.id) {
      _selected = updated;
    }
    notifyListeners();
  }

  void moveControlBy(String controlId, Offset delta, Size canvasSize) {
    if (readOnly || !allowMove) return;
    _mutateControl(controlId, (control) {
      final dx = delta.dx / canvasSize.width;
      final dy = delta.dy / canvasSize.height;
      final l = control.layout;
      final tentative = ControlLayout(
        x: (l.x + dx).clamp(0.0, 1.0 - l.width),
        y: (l.y + dy).clamp(0.0, 1.0 - l.height),
        width: l.width,
        height: l.height,
      );
      final constrained = _constrainLayout(control, tentative, canvasSize);
      return _cloneWithLayout(control, constrained);
    });
  }

  void resizeControlBy(
    String controlId,
    Offset delta,
    Size canvasSize,
    ResizeDirection direction,
  ) {
    if (readOnly || !allowResize) return;
    _mutateControl(controlId, (control) {
      final dx = delta.dx / canvasSize.width;
      final dy = delta.dy / canvasSize.height;
      const minSize = 0.02;

      final l = control.layout;
      double newX = l.x;
      double newY = l.y;
      double newWidth = l.width;
      double newHeight = l.height;

      switch (direction) {
        case ResizeDirection.topLeft:
          final actualDx = dx.clamp(-newX, newWidth - minSize);
          final actualDy = dy.clamp(-newY, newHeight - minSize);
          newX += actualDx;
          newWidth -= actualDx;
          newY += actualDy;
          newHeight -= actualDy;
          break;
        case ResizeDirection.topRight:
          final actualDx =
              dx.clamp(minSize - newWidth, 1.0 - (newX + newWidth));
          final actualDy = dy.clamp(-newY, newHeight - minSize);
          newWidth += actualDx;
          newY += actualDy;
          newHeight -= actualDy;
          break;
        case ResizeDirection.bottomLeft:
          final actualDx = dx.clamp(-newX, newWidth - minSize);
          final actualDy =
              dy.clamp(minSize - newHeight, 1.0 - (newY + newHeight));
          newX += actualDx;
          newWidth -= actualDx;
          newHeight += actualDy;
          break;
        case ResizeDirection.bottomRight:
          final actualDx =
              dx.clamp(minSize - newWidth, 1.0 - (newX + newWidth));
          final actualDy =
              dy.clamp(minSize - newHeight, 1.0 - (newY + newHeight));
          newWidth += actualDx;
          newHeight += actualDy;
          break;
      }

      final tentative = ControlLayout(
        x: newX,
        y: newY,
        width: newWidth,
        height: newHeight,
      );
      final constrained = _constrainLayout(control, tentative, canvasSize);
      return _cloneWithLayout(control, constrained);
    });
  }

  void setSelectedScale(double scale, Size canvasSize) {
    if (readOnly || !allowResize) return;
    final selected = _selected;
    final base = _selectedBaseLayout;
    if (selected == null || base == null) return;

    final current = selected.layout;
    final centerX = current.x + current.width / 2;
    final centerY = current.y + current.height / 2;

    const minSize = 0.02;
    var newWidth = (base.width * scale).clamp(minSize, 1.0);
    var newHeight = (base.height * scale).clamp(minSize, 1.0);

    var newX = (centerX - newWidth / 2).clamp(0.0, 1.0 - newWidth);
    var newY = (centerY - newHeight / 2).clamp(0.0, 1.0 - newHeight);

    final tentative = ControlLayout(
      x: newX,
      y: newY,
      width: newWidth,
      height: newHeight,
    );

    final constrained = _constrainLayout(selected, tentative, canvasSize);
    final updated = _cloneWithLayout(selected, constrained);
    updateControl(updated);
    _selectedScale = scale;
    notifyListeners();
  }

  void setSelectedOpacity(double opacity) {
    if (readOnly) return;
    final selected = _selected;
    if (selected == null) return;
    final nextOpacity = opacity.clamp(0.05, 1.0);
    final nextConfig = Map<String, dynamic>.from(selected.config);
    nextConfig['opacity'] = nextOpacity;
    final updated = _cloneWithOverrides(selected, config: nextConfig);
    updateControl(updated);
    notifyListeners();
  }

  void markSaved() {
    _isDirty = false;
    notifyListeners();
  }

  void _mutateControl(
    String controlId,
    VirtualControl Function(VirtualControl control) transformer,
  ) {
    final idx = _layout.controls.indexWhere((c) => c.id == controlId);
    if (idx == -1) return;
    final current = _layout.controls[idx];
    final updated = transformer(current);
    updateControl(updated);
  }

  ControlLayout _constrainLayout(
    VirtualControl control,
    ControlLayout layout,
    Size canvasSize,
  ) {
    final temp = _cloneWithLayout(control, layout);
    final occupied = ControlGeometry.occupiedLayout(temp, canvasSize);
    final x = occupied.x.clamp(0.0, 1.0 - occupied.width);
    final y = occupied.y.clamp(0.0, 1.0 - occupied.height);
    return ControlLayout(
      x: x,
      y: y,
      width: occupied.width.clamp(0.02, 1.0),
      height: occupied.height.clamp(0.02, 1.0),
    );
  }

  VirtualControl _cloneWithLayout(
      VirtualControl control, ControlLayout layout) {
    return _cloneWithOverrides(control, layout: layout);
  }

  VirtualControl _cloneWithOverrides(
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
        key: control.key,
        modifiers: control.modifiers,
        repeat: control.repeat,
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
    if (control is VirtualDpad) {
      return VirtualDpad(
        id: control.id,
        label: nextLabel,
        layout: nextLayout,
        trigger: control.trigger,
        config: nextConfig,
        actions: control.actions,
        directions: control.directions,
        mode: control.mode,
        enable3D: control.enable3D,
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
    return control;
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
