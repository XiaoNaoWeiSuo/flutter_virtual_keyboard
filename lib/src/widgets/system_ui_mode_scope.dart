import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SystemUiModeScope extends StatefulWidget {
  const SystemUiModeScope({
    super.key,
    required this.child,
    this.mode,
    this.overlays,
  });

  final Widget child;
  final SystemUiMode? mode;
  final List<SystemUiOverlay>? overlays;

  @override
  State<SystemUiModeScope> createState() => _SystemUiModeScopeState();
}

class _SystemUiModeScopeState extends State<SystemUiModeScope> {
  final Object _token = Object();

  @override
  void initState() {
    super.initState();
    _SystemUiModeStack.push(
      _token,
      mode: widget.mode,
      overlays: widget.overlays,
    );
  }

  @override
  void didUpdateWidget(SystemUiModeScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.mode != widget.mode ||
        oldWidget.overlays != widget.overlays) {
      _SystemUiModeStack.update(
        _token,
        mode: widget.mode,
        overlays: widget.overlays,
      );
    }
  }

  @override
  void dispose() {
    _SystemUiModeStack.pop(_token);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _SystemUiModeEntry {
  _SystemUiModeEntry({
    required this.token,
    required this.mode,
    required this.overlays,
  });

  final Object token;
  final SystemUiMode? mode;
  final List<SystemUiOverlay>? overlays;
}

class _SystemUiModeStack {
  static final List<_SystemUiModeEntry> _stack = <_SystemUiModeEntry>[];

  static void push(
    Object token, {
    required SystemUiMode? mode,
    required List<SystemUiOverlay>? overlays,
  }) {
    _stack
        .add(_SystemUiModeEntry(token: token, mode: mode, overlays: overlays));
    _applyTop();
  }

  static void update(
    Object token, {
    required SystemUiMode? mode,
    required List<SystemUiOverlay>? overlays,
  }) {
    final index = _stack.indexWhere((e) => e.token == token);
    if (index < 0) return;
    _stack[index] =
        _SystemUiModeEntry(token: token, mode: mode, overlays: overlays);
    _applyTop();
  }

  static void pop(Object token) {
    _stack.removeWhere((e) => e.token == token);
    _applyTop();
  }

  static void _applyTop() {
    final top = _stack.isNotEmpty ? _stack.last : null;
    final mode = top?.mode;
    if (mode == null) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      return;
    }
    final overlays = top?.overlays;
    if (mode == SystemUiMode.manual && overlays != null) {
      SystemChrome.setEnabledSystemUIMode(mode, overlays: overlays);
      return;
    }
    SystemChrome.setEnabledSystemUIMode(mode);
  }
}
