import 'package:flutter/material.dart';

/// A label widget for controls.
class ControlLabel extends StatelessWidget {
  /// Creates a control label.
  const ControlLabel(this.text, {super.key, this.style});

  /// The text to display.
  final String text;

  /// The style of the text.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final effectiveStyle = style ??
        const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
          shadows: [Shadow(color: Colors.black, blurRadius: 2)],
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          text,
          style: effectiveStyle,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.visible,
          softWrap: false,
        ),
      ),
    );
  }
}
