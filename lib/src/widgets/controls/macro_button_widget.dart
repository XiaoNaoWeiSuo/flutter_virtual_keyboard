import 'dart:async';
import 'package:flutter/material.dart';
import '../../macro/recorded_timeline_event.dart';
import '../../models/controls/virtual_macro_button.dart';
import '../../models/input_event.dart';
import '../shared/control_container.dart';
import '../shared/control_label.dart';
import '../shared/control_utils.dart';

class VirtualMacroButtonWidget extends StatefulWidget {
  const VirtualMacroButtonWidget({
    super.key,
    required this.control,
    required this.onInputEvent,
    required this.showLabel,
  });

  final VirtualMacroButton control;
  final void Function(InputEvent) onInputEvent;
  final bool showLabel;

  @override
  State<VirtualMacroButtonWidget> createState() =>
      _VirtualMacroButtonWidgetState();
}

class _VirtualMacroButtonWidgetState extends State<VirtualMacroButtonWidget> {
  bool _isPressed = false;
  bool _isLocked = false;
  bool _didLongPress = false;
  int _playToken = 0;

  @override
  void dispose() {
    _playToken++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.control.label.isEmpty ? 'Macro' : widget.control.label;
    return GestureDetector(
      onTapDown: (_) {
        setState(() {
          _isPressed = true;
          _didLongPress = false;
        });
        triggerFeedback(widget.control.feedback, true);
      },
      onTap: () {
        if (_didLongPress) return;
        if (_isLocked) {
          _stopLockedLoop();
          return;
        }
        _playOnce();
      },
      onLongPressStart: (_) {
        _didLongPress = true;
        if (_isLocked) return;
        _startLockedLoop();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        triggerFeedback(widget.control.feedback, false);
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        triggerFeedback(widget.control.feedback, false);
      },
      child: Transform.scale(
        scale: _isPressed ? 0.95 : 1.0,
        child: ControlContainer(
          isPressed: _isPressed,
          style: widget.control.style,
          defaultShape: BoxShape.rectangle,
          child: widget.showLabel
              ? ControlLabel(
                  label,
                  style: widget.control.style?.labelStyle,
                  icon: _isLocked ? Icons.lock : null,
                )
              : null,
        ),
      ),
    );
  }

  List<Map<String, dynamic>>? _recordingV2() {
    final recordedV2 = widget.control.config['recordingV2'];
    if (recordedV2 is List) {
      return recordedV2
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
    }
    return null;
  }

  void _stopLockedLoop() {
    if (!_isLocked) return;
    setState(() => _isLocked = false);
    _playToken++;
    triggerFeedback(widget.control.feedback, true, type: 'selection');
  }

  void _startLockedLoop() {
    final v2 = _recordingV2();
    if (v2 == null || v2.isEmpty) return;

    setState(() => _isLocked = true);
    triggerFeedback(widget.control.feedback, true, type: 'selection');

    final token = ++_playToken;
    _loopPlay(v2, token: token);
  }

  Future<void> _loopPlay(List<Map<String, dynamic>> v2,
      {required int token}) async {
    while (mounted && token == _playToken && _isLocked) {
      await _playTimelineFromJson(v2, token: token);
      if (!mounted) return;
      if (token != _playToken) return;
      if (!_isLocked) return;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }
  }

  void _playOnce() {
    final v2 = _recordingV2();
    if (v2 == null || v2.isEmpty) return;
    final token = ++_playToken;
    _playTimelineFromJson(v2, token: token);
  }

  Future<void> _playTimelineFromJson(
    List<Map<String, dynamic>> json, {
    required int token,
  }) async {
    final groups = <int, List<RecordedTimelineEvent>>{};
    for (final raw in json) {
      final e = RecordedTimelineEvent.fromJson(raw);
      groups.putIfAbsent(e.atMs, () => <RecordedTimelineEvent>[]).add(e);
    }
    final times = groups.keys.toList()..sort();
    if (times.isEmpty) return;

    final baseAt = times.first;
    int prevAt = baseAt;
    for (final atMs in times) {
      if (!mounted) return;
      if (token != _playToken) return;

      final waitMs = (atMs - prevAt).clamp(0, 999999);
      prevAt = atMs;
      if (waitMs > 0) {
        await Future.delayed(Duration(milliseconds: waitMs));
      } else {
        await Future<void>.delayed(Duration.zero);
      }

      if (!mounted) return;
      if (token != _playToken) return;

      final list = groups[atMs] ?? const <RecordedTimelineEvent>[];
      for (var i = 0; i < list.length; i++) {
        final ev = list[i].toInputEvent();
        if (ev != null) widget.onInputEvent(ev);
        if (i % 20 == 19) await Future<void>.delayed(Duration.zero);
        if (!mounted) return;
        if (token != _playToken) return;
      }
    }
  }
}
