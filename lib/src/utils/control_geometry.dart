import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/style/control_layout.dart';
import '../models/style/control_style.dart';
import '../models/virtual_controller_models.dart';

class ControlGeometry {
  static Rect occupiedRect(VirtualControl control, Size screenSize) {
    var rect = control.layout.toRect(screenSize);

    if (_shouldBeSquare(control)) {
      final size = math.min(rect.width, rect.height);
      rect = Rect.fromCenter(center: rect.center, width: size, height: size);
    }

    if (control is VirtualScrollStick) {
      rect = _ensureMinHeightToWidthRatio(rect, minRatio: 2.5);
    }

    return rect;
  }

  static ControlLayout occupiedLayout(VirtualControl control, Size screenSize) {
    final rect = occupiedRect(control, screenSize);
    final w = screenSize.width == 0 ? 1 : screenSize.width;
    final h = screenSize.height == 0 ? 1 : screenSize.height;
    return ControlLayout(
      x: rect.left / w,
      y: rect.top / h,
      width: rect.width / w,
      height: rect.height / h,
    );
  }

  static Rect safeRect(VirtualControl control, Size screenSize,
      {double borderPadding = 2.0}) {
    final r = occupiedRect(control, screenSize);
    final inset = _safeInsetFor(control, r.size) + borderPadding;
    return Rect.fromLTWH(
      r.left + inset,
      r.top + inset,
      math.max(0.0, r.width - inset * 2),
      math.max(0.0, r.height - inset * 2),
    );
  }

  static EdgeInsets safePadding(VirtualControl control, Size size,
      {double borderPadding = 2.0}) {
    final inset = _safeInsetFor(control, size) + borderPadding;
    return EdgeInsets.all(inset);
  }

  static bool _shouldBeSquare(VirtualControl control) {
    if (control is VirtualJoystick) return true;
    if (control is VirtualDpad) return true;
    if (control is VirtualSplitMouse) return true;
    if (control is VirtualButton) {
      final shape = control.style?.shape ?? BoxShape.circle;
      return shape != BoxShape.rectangle;
    }
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
