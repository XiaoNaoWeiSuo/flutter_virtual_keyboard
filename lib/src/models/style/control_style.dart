import 'package:flutter/material.dart';

part '../../utils/style_json_codec.dart';

/// Style configuration for a control.
///
/// Defines the visual appearance of a control, including shape, color,
/// border, background image, opacity, and shadows.
class ControlStyle {
  /// Creates a style configuration.
  const ControlStyle({
    this.shape = BoxShape.circle,
    this.borderRadius = 8.0,
    this.color,
    this.pressedColor,
    this.borderColor,
    this.pressedBorderColor,
    this.lockedColor,
    this.borderWidth = 2.0,
    this.backgroundImage,
    this.pressedBackgroundImage,
    this.backgroundImagePath,
    this.pressedBackgroundImagePath,
    this.opacity = 1.0,
    this.pressedOpacity = 0.8,
    this.labelStyle,
    this.shadows = const [],
    this.pressedShadows = const [],
    this.imageFit = BoxFit.cover,
  });

  /// Creates a [ControlStyle] from a JSON map.
  factory ControlStyle.fromJson(Map<String, dynamic> json) {
    return ControlStyleJsonCodec.fromJson(json);
  }

  /// The shape of the control (circle or rectangle).
  final BoxShape shape;

  /// The border radius (only applies if shape is rectangle).
  final double borderRadius;

  /// The background color in normal state.
  final Color? color;

  /// The background color in pressed state.
  final Color? pressedColor;

  /// The border color in normal state.
  final Color? borderColor;

  /// The border color in pressed state.
  final Color? pressedBorderColor;

  /// The color overlay when the control is in a locked state (e.g. joystick lock).
  final Color? lockedColor;

  /// The width of the border.
  final double borderWidth;

  /// The background image provider in normal state (optional, overrides backgroundImagePath).
  final ImageProvider? backgroundImage;

  /// The background image provider in pressed state (optional, overrides pressedBackgroundImagePath).
  final ImageProvider? pressedBackgroundImage;

  /// The path/URL to the background image in normal state.
  final String? backgroundImagePath;

  /// The path/URL to the background image in pressed state.
  final String? pressedBackgroundImagePath;

  /// The opacity in normal state (0.0 - 1.0).
  final double opacity;

  /// The opacity in pressed state (0.0 - 1.0).
  final double pressedOpacity;

  /// The text style for the control label.
  final TextStyle? labelStyle;

  /// The shadows in normal state.
  final List<BoxShadow> shadows;

  /// The shadows in pressed state.
  final List<BoxShadow> pressedShadows;

  /// How the background image should be inscribed into the control.
  final BoxFit imageFit;

  /// Converts the style configuration to a JSON map.
  Map<String, dynamic> toJson() => ControlStyleJsonCodec.toJson(this);
}
