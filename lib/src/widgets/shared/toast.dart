import 'dart:async';

import 'package:flutter/material.dart';

OverlayEntry? _toastEntry;
Timer? _toastTimer;

void showToast(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 2),
}) {
  final text = message.trim();
  if (text.isEmpty) return;

  _toastTimer?.cancel();
  _toastTimer = null;

  _toastEntry?.remove();
  _toastEntry = null;

  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) return;

  final theme = Theme.of(context);

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (overlayContext) {
      return Theme(
        data: theme,
        child: _ToastOverlay(
          message: text,
          duration: duration,
          onDismissed: () {
            if (_toastEntry == entry) {
              _toastEntry?.remove();
              _toastEntry = null;
            }
          },
        ),
      );
    },
  );

  _toastEntry = entry;
  overlay.insert(entry);
}

class _ToastOverlay extends StatefulWidget {
  const _ToastOverlay({
    required this.message,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_ToastOverlay> createState() => _ToastOverlayState();
}

class _ToastOverlayState extends State<_ToastOverlay> {
  static const _fadeDuration = Duration(milliseconds: 180);

  Timer? _fadeTimer;
  Timer? _dismissTimer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();

    final fadeAt = widget.duration - _fadeDuration;
    if (fadeAt > Duration.zero) {
      _fadeTimer = Timer(fadeAt, () {
        if (!mounted) return;
        setState(() => _visible = false);
      });
    } else {
      _visible = false;
    }

    _dismissTimer = Timer(widget.duration, () {
      widget.onDismissed();
    });
  }

  @override
  void dispose() {
    _fadeTimer?.cancel();
    _dismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = (theme.textTheme.bodyMedium ?? const TextStyle())
        .copyWith(color: Colors.white);

    return IgnorePointer(
      ignoring: true,
      child: SafeArea(
        child: Align(
          alignment: const Alignment(0, -0.5),
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: _fadeDuration,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.62),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text(
                      widget.message,
                      style: textStyle,
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
