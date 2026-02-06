import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/style/control_feedback.dart';

/// Triggers haptic feedback based on the control configuration.
Future<void> triggerFeedback(ControlFeedback? feedback, bool isPressed,
    {String? type}) async {
  final effective = feedback ?? const ControlFeedback(vibration: true);
  if (!effective.vibration) return;

  if (isPressed) {
    final vibrationType = type ?? effective.vibrationType;
    switch (vibrationType) {
      case 'light':
        await HapticFeedback.lightImpact();
        break;
      case 'medium':
        await HapticFeedback.mediumImpact();
        break;
      case 'heavy':
        await HapticFeedback.heavyImpact();
        break;
      case 'selection':
        await HapticFeedback.selectionClick();
        break;
      case 'success':
        await HapticFeedback.mediumImpact();
        break;
      case 'error':
        await HapticFeedback.heavyImpact();
        break;
      default:
        await HapticFeedback.lightImpact();
    }
  }
}

/// Gets an [ImageProvider] from a path string.
///
/// Supports http/https URLs and asset paths.
ImageProvider? getImageProvider(String? path) {
  if (path == null || path.trim().isEmpty) return null;
  final cleanPath = path.trim();

  if (cleanPath.startsWith('http')) {
    return NetworkImage(cleanPath);
  } else if (cleanPath.startsWith('assets/')) {
    return AssetImage(cleanPath);
  } else {
    // Fallback to AssetImage for local paths if not http
    return AssetImage(cleanPath);
  }
}
