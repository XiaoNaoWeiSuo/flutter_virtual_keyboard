import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/virtual_controller_models.dart';

/// Geometry helpers for virtual controls.
///
/// Some controls (e.g. joystick/d-pad/split mouse) occupy a square area even if
/// the provided layout is not perfectly square. This utility provides a
/// consistent way to compute the occupied area and a safe inner area for hit
/// testing/handles.
class ControlGeometry {
  /// Returns the actual on-screen rectangle occupied by [control] given its
  /// normalized [layout] and the current [screenSize].
  ///
  /// This may differ from [ControlLayout.toRect] for controls that enforce
  /// square geometry or minimum aspect ratios.
  static Rect occupiedRect(
    VirtualControl control,
    ControlLayout layout,
    Size screenSize,
  ) {
    var rect = layout.toRect(screenSize);

    if (_shouldBeSquare(control)) {
      final size = math.min(rect.width, rect.height);
      rect = Rect.fromCenter(center: rect.center, width: size, height: size);
    }

    if (control is VirtualScrollStick) {
      rect = _ensureMinHeightToWidthRatio(rect, minRatio: 2.5);
    }

    return rect;
  }

  /// Returns the normalized layout that corresponds to [occupiedRect].
  static ControlLayout occupiedLayout(
    VirtualControl control,
    ControlLayout layout,
    Size screenSize,
  ) {
    final rect = occupiedRect(control, layout, screenSize);
    final w = screenSize.width == 0 ? 1 : screenSize.width;
    final h = screenSize.height == 0 ? 1 : screenSize.height;
    return ControlLayout(
      x: rect.left / w,
      y: rect.top / h,
      width: rect.width / w,
      height: rect.height / h,
    );
  }

  /// Returns a "safe" inner rect within [occupiedRect] for selection handles,
  /// hit-testing padding, and visual affordances.
  static Rect safeRect(
    VirtualControl control,
    ControlLayout layout,
    Size screenSize, {
    double borderPadding = 2.0,
  }) {
    final r = occupiedRect(control, layout, screenSize);
    final inset = _safeInsetFor(control, r.size) + borderPadding;
    return Rect.fromLTWH(
      r.left + inset,
      r.top + inset,
      math.max(0.0, r.width - inset * 2),
      math.max(0.0, r.height - inset * 2),
    );
  }

  /// Returns the safe padding inset for a control of a given [size].
  ///
  /// This is equivalent to the inset used by [safeRect].
  static EdgeInsets safePadding(VirtualControl control, Size size,
      {double borderPadding = 2.0}) {
    final inset = _safeInsetFor(control, size) + borderPadding;
    return EdgeInsets.all(inset);
  }

  static bool _shouldBeSquare(VirtualControl control) {
    if (control is VirtualJoystick) return true;
    if (control is VirtualDpad) return true;
    if (control is VirtualSplitMouse) return true;
    if (control is VirtualScrollStick) return false;
    if (control is VirtualButton) {
      final shape = control.style?.shape ?? BoxShape.circle;
      return shape != BoxShape.rectangle;
    }
    final shape = control.style?.shape;
    if (shape != null && shape != BoxShape.rectangle) return true;
    return false;
  }

  static double _safeInsetFor(VirtualControl control, Size size) {
    final minSide = math.min(size.width, size.height);
    if (control is VirtualButton) {
      final shape = control.style?.shape ?? BoxShape.circle;
      if (shape != BoxShape.rectangle) return minSide * 0.18;
    }
    if (control is VirtualJoystick ||
        control is VirtualDpad ||
        control is VirtualSplitMouse) {
      return minSide * 0.12;
    }
    if (control is VirtualScrollStick) {
      return minSide * 0.10;
    }
    final style = control.style;
    if (style != null && style.shape != BoxShape.rectangle) {
      return minSide * 0.16;
    }
    return minSide * 0.08;
  }

  static Rect _ensureMinHeightToWidthRatio(Rect rect,
      {required double minRatio}) {
    if (rect.height >= rect.width * minRatio) return rect;
    final newWidth = rect.height / minRatio;
    return Rect.fromCenter(
        center: rect.center, width: newWidth, height: rect.height);
  }
}
