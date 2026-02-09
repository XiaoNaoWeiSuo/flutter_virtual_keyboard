import 'package:flutter/material.dart';

/// A label widget for controls.
class ControlLabel extends StatelessWidget {
  /// Creates a control label.
  const ControlLabel(
    this.text, {
    super.key,
    this.style,
    this.icon,
    this.iconWidget,
    this.iconColor,
    this.iconScale = 0.6,
  });

  /// The text to display.
  final String text;

  /// The style of the text.
  final TextStyle? style;

  final IconData? icon;
  final Widget? iconWidget;
  final Color? iconColor;
  final double iconScale;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        );

    final hasText = text.trim().isNotEmpty;
    final hasIcon = iconWidget != null || icon != null;

    return LayoutBuilder(
      builder: (context, constraints) {
        final baseSize = constraints.biggest.shortestSide;
        final iconSize = baseSize.isFinite ? baseSize * iconScale : 20.0;

        final resolvedIcon = iconWidget ??
            (icon != null
                ? Icon(
                    icon,
                    size: iconSize,
                    color: iconColor ?? effectiveStyle.color ?? Colors.white,
                  )
                : null);

        final Widget content;
        if (hasIcon && hasText) {
          content = Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              resolvedIcon!,
              const SizedBox(height: 2),
              Text(
                text,
                style: effectiveStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.visible,
                softWrap: false,
              ),
            ],
          );
        } else if (hasIcon) {
          content = resolvedIcon!;
        } else {
          content = Text(
            text,
            style: effectiveStyle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.visible,
            softWrap: false,
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: content,
          ),
        );
      },
    );
  }
}
