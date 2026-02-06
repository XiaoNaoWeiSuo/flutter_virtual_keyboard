import 'package:flutter/material.dart';
import '../../models/style/control_style.dart';
import 'control_utils.dart';

/// A container that renders a control with the specified style.
///
/// Handles shape, color, border, background image, shadows, and opacity
/// based on the current state (pressed/normal).
class ControlContainer extends StatelessWidget {
  /// Creates a control container.
  const ControlContainer({
    super.key,
    this.child,
    this.isPressed = false,
    this.style,
    this.defaultShape = BoxShape.circle,
    this.defaultColor,
  });

  /// The child widget to render inside the container.
  final Widget? child;

  /// Whether the control is currently pressed.
  final bool isPressed;

  /// The style configuration for the control.
  final ControlStyle? style;

  /// The default shape if not specified in style.
  final BoxShape defaultShape;

  /// The default color if not specified in style.
  final Color? defaultColor;

  @override
  Widget build(BuildContext context) {
    // Resolve properties from style or defaults
    final shape = style?.shape ?? defaultShape;
    final opacity =
        isPressed ? (style?.pressedOpacity ?? 0.8) : (style?.opacity ?? 1.0);

    final baseColor =
        isPressed ? (style?.pressedColor ?? style?.color) : style?.color;
    final color = baseColor ??
        defaultColor ??
        (isPressed ? Colors.white54 : Colors.grey.shade900.withAlpha(200));

    final borderColor = isPressed
        ? (style?.pressedBorderColor ?? style?.borderColor)
        : style?.borderColor;
    final effectiveBorderColor =
        borderColor ?? (isPressed ? Colors.white : Colors.white54);

    final borderWidth = style?.borderWidth ?? 2.0;

    final backgroundImage =
        style?.backgroundImage ?? getImageProvider(style?.backgroundImagePath);

    final pressedImage = style?.pressedBackgroundImage ??
        getImageProvider(style?.pressedBackgroundImagePath);

    final currentImage =
        isPressed ? (pressedImage ?? backgroundImage) : backgroundImage;

    final shadows = isPressed
        ? (style?.pressedShadows.isNotEmpty == true
            ? style!.pressedShadows
            : style?.shadows)
        : style?.shadows;

    return Opacity(
      opacity: opacity,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: color,
          shape: shape,
          borderRadius: shape == BoxShape.rectangle
              ? BorderRadius.circular(style?.borderRadius ?? 8.0)
              : null,
          border: Border.all(
            color: effectiveBorderColor,
            width: borderWidth,
          ),
          image: currentImage != null
              ? DecorationImage(
                  image: currentImage,
                  fit: style?.imageFit ?? BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                )
              : null,
          boxShadow: shadows,
        ),
        child: Center(child: child),
      ),
    );
  }
}
