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
  int _playToken = 0;

  @override
  void dispose() {
    _playToken++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _isPressed = true);
        triggerFeedback(widget.control.feedback, true);
        _executeMacro();
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
                  widget.control.label.isEmpty ? 'Macro' : widget.control.label,
                  style: widget.control.style?.labelStyle,
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _executeMacro() async {
    final token = ++_playToken;

    final recordedV2 = widget.control.config['recordingV2'];
    if (recordedV2 is List) {
      final v2 = recordedV2
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList(growable: false);
      await _playTimelineFromJson(v2, token: token);
      return;
    }
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

    int prevAt = 0;
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
