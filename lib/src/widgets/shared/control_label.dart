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
    return Text(
      text,
      style: style ??
          const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
            shadows: [Shadow(color: Colors.black, blurRadius: 2)],
          ),
      textAlign: TextAlign.center,
    );
  }
}
