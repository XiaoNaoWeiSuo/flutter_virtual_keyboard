import 'package:flutter/material.dart';
import '../../models/controls/virtual_control.dart';

/// Default / Fallback Widget.
///
/// Used when a control type is not recognized.
class DefaultControlWidget extends StatelessWidget {
  /// Creates a default control widget.
  const DefaultControlWidget({super.key, required this.control});

  /// The virtual control model.
  final VirtualControl control;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.red),
        color: Colors.red.withAlpha(100),
      ),
      child: Center(
        child: Text(
          control.label.isNotEmpty ? control.label : '?',
          style: const TextStyle(color: Colors.white, fontSize: 10),
        ),
      ),
    );
  }
}
