import 'package:flutter/material.dart';

/// Normalized layout (0.0 - 1.0) for positioning virtual controls.
class ControlLayout {
  /// Creates a layout configuration.
  const ControlLayout({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Creates a [ControlLayout] from a JSON map.
  factory ControlLayout.fromJson(Map<String, dynamic> json) {
    return ControlLayout(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
    );
  }

  /// The normalized X position (0.0 - 1.0).
  final double x;

  /// The normalized Y position (0.0 - 1.0).
  final double y;

  /// The normalized width (0.0 - 1.0).
  final double width;

  /// The normalized height (0.0 - 1.0).
  final double height;

  /// Converts the layout to a JSON map.
  Map<String, dynamic> toJson() => {
        'x': double.parse(x.toStringAsFixed(6)),
        'y': double.parse(y.toStringAsFixed(6)),
        'width': double.parse(width.toStringAsFixed(6)),
        'height': double.parse(height.toStringAsFixed(6)),
      };

  /// Convert normalized layout to actual screen rect.
  Rect toRect(Size screenSize) => Rect.fromLTWH(
        x * screenSize.width,
        y * screenSize.height,
        width * screenSize.width,
        height * screenSize.height,
      );
}
