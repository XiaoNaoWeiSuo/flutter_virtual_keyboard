import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiMode;

import '../../macro/recorded_timeline_event.dart';
import '../../models/virtual_controller_models.dart';
import '../../widgets/macro/virtual_controller_macro_recording_session.dart';
import '../../widgets/shared/input_glyph.dart';
import '../../widgets/system_ui_mode_scope.dart';

part 'suite/macro_suite_editor_bubble.dart';
part 'suite/macro_suite_models.dart';
part 'suite/macro_suite_preview_timeline.dart';
part 'suite/macro_suite_timeline.dart';
part 'suite/macro_suite_tool_panel.dart';

class MacroDraft {
  const MacroDraft({
    required this.label,
    required this.recordingV2,
  });

  final String label;
  final List<Map<String, dynamic>> recordingV2;
}

enum _MacroSuiteView { defaultView, preview }

class MacroSuitePage extends StatefulWidget {
  const MacroSuitePage({
    super.key,
    required this.definition,
    required this.state,
    this.initialLabel = 'Macro',
    this.initialRecordingV2,
    this.immersive = true,
  });

  final VirtualControllerLayout definition;
  final VirtualControllerState state;
  final String initialLabel;
  final List<Map<String, dynamic>>? initialRecordingV2;
  final bool immersive;

  @override
  State<MacroSuitePage> createState() => _MacroSuitePageState();
}

class _MacroSuitePageState extends State<MacroSuitePage> {
  late final TextEditingController _labelController;
  final List<_StepEntry> _steps = [];
  final Map<int, bool> _slotExpandedByAtMs = {};
  late final ScrollController _timelineScrollController;
  late final ScrollController _previewRulerScrollController;
  late final ScrollController _previewTrackHorizontalScrollController;
  late final ScrollController _previewAxisScrollController;
  late final ScrollController _previewTrackScrollController;
  bool _syncingPreviewVertical = false;
  bool _syncingPreviewHorizontal = false;
  List<_TimeSlot> _slots = const [];
  bool _loadingInit = false;
  int _openDownCount = 0;
  _MacroSuiteView _view = _MacroSuiteView.defaultView;
  double _previewZoom = 1.0;
  _SelectedSegment? _selectedSegment;
  final Map<String, List<_AxisWarpOp>> _axisWarpOpsByLaneKey = {};
  int _axisSelectionSpanMs = 1400;
  bool _toolCollapsed = false;

  String? _editingId;
  RecordedTimelineEvent? _draft;
  bool _draftIsNew = false;
  bool _editorDrawerOpen = false;

  @override
  void initState() {
    super.initState();
    _labelController = TextEditingController(text: widget.initialLabel);
    _timelineScrollController = ScrollController();
    _previewRulerScrollController = ScrollController();
    _previewTrackHorizontalScrollController = ScrollController();
    _previewAxisScrollController = ScrollController();
    _previewTrackScrollController = ScrollController();
    _previewRulerScrollController.addListener(() {
      if (_syncingPreviewHorizontal) return;
      if (!_previewTrackHorizontalScrollController.hasClients) return;
      _syncingPreviewHorizontal = true;
      final target = _previewRulerScrollController.offset.clamp(
        _previewTrackHorizontalScrollController.position.minScrollExtent,
        _previewTrackHorizontalScrollController.position.maxScrollExtent,
      );
      _previewTrackHorizontalScrollController.jumpTo(target.toDouble());
      _syncingPreviewHorizontal = false;
    });
    _previewTrackHorizontalScrollController.addListener(() {
      if (_syncingPreviewHorizontal) return;
      if (!_previewRulerScrollController.hasClients) return;
      _syncingPreviewHorizontal = true;
      final target = _previewTrackHorizontalScrollController.offset.clamp(
        _previewRulerScrollController.position.minScrollExtent,
        _previewRulerScrollController.position.maxScrollExtent,
      );
      _previewRulerScrollController.jumpTo(target.toDouble());
      _syncingPreviewHorizontal = false;
    });
    _previewAxisScrollController.addListener(() {
      if (_syncingPreviewVertical) return;
      if (!_previewTrackScrollController.hasClients) return;
      _syncingPreviewVertical = true;
      final target = _previewAxisScrollController.offset.clamp(
        _previewTrackScrollController.position.minScrollExtent,
        _previewTrackScrollController.position.maxScrollExtent,
      );
      _previewTrackScrollController.jumpTo(target.toDouble());
      _syncingPreviewVertical = false;
    });
    _previewTrackScrollController.addListener(() {
      if (_syncingPreviewVertical) return;
      if (!_previewAxisScrollController.hasClients) return;
      _syncingPreviewVertical = true;
      final target = _previewTrackScrollController.offset.clamp(
        _previewAxisScrollController.position.minScrollExtent,
        _previewAxisScrollController.position.maxScrollExtent,
      );
      _previewAxisScrollController.jumpTo(target.toDouble());
      _syncingPreviewVertical = false;
    });
    final init = widget.initialRecordingV2;
    if (init != null && init.isNotEmpty) {
      _loadingInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadInitial(init);
      });
    }
    _rebuildSlots();
  }

  @override
  void dispose() {
    _labelController.dispose();
    _timelineScrollController.dispose();
    _previewRulerScrollController.dispose();
    _previewTrackHorizontalScrollController.dispose();
    _previewAxisScrollController.dispose();
    _previewTrackScrollController.dispose();
    super.dispose();
  }

  void _finish() {
    final label = _labelController.text.trim().isEmpty
        ? widget.initialLabel
        : _labelController.text.trim();
    int mapAxisAtMs(List<_AxisWarpOp> ops, int atMs) {
      final t = atMs.clamp(0, 999999).toInt();
      if (ops.isEmpty) return t;
      final ordered = ops.toList()
        ..sort((a, b) => a.originStartMs.compareTo(b.originStartMs));
      final points = <({int o, int m})>[
        (o: 0, m: 0),
        for (final op in ordered) ...[
          (o: op.originStartMs, m: op.mappedStartMs),
          (o: op.originEndMs, m: op.mappedEndMs),
        ],
      ]..sort((a, b) => a.o.compareTo(b.o));
      for (var i = 0; i < points.length - 1; i++) {
        final a = points[i];
        final b = points[i + 1];
        if (t <= b.o) {
          final denom = (b.o - a.o);
          final ratio = denom == 0 ? 0.0 : (t - a.o) / denom;
          final mapped = a.m + ratio * (b.m - a.m);
          return mapped.round().clamp(0, 999999).toInt();
        }
      }
      final last = points.last;
      final shift = last.m - last.o;
      return (t + shift).clamp(0, 999999).toInt();
    }

    final warped = _steps.map((e) {
      final original = e.event;
      final laneKey = _axisLaneKeyForPreview(original);
      final ops =
          laneKey == null ? const <_AxisWarpOp>[] : (_axisWarpOpsByLaneKey[laneKey] ?? const []);
      final mappedAt = ops.isEmpty ? original.atMs : mapAxisAtMs(ops, original.atMs);
      return RecordedTimelineEvent(
        atMs: mappedAt,
        type: original.type,
        data: {...original.data},
      );
    }).toList(growable: false)
      ..sort((a, b) => a.atMs.compareTo(b.atMs));
    final recordingV2 = warped.map((e) => e.toJson()).toList(growable: false);
    Navigator.of(context)
        .pop(MacroDraft(label: label, recordingV2: recordingV2));
  }

  int _compareSteps(_StepEntry a, _StepEntry b) {
    final atCmp = a.event.atMs.compareTo(b.event.atMs);
    if (atCmp != 0) return atCmp;
    final aDown = a.event.data['isDown'] == true;
    final bDown = b.event.data['isDown'] == true;
    if (aDown != bDown) return aDown ? -1 : 1;
    return a.id.compareTo(b.id);
  }

  void _sortSteps() {
    _steps.sort(_compareSteps);
  }

  void _sanitizeSteps() {
    _sortSteps();
    final idsToRemove = <String>{};
    final open = <String>{};
    for (final step in _steps) {
      final e = step.event;
      final key = _identityForEvent(e);
      if (key == null) continue;
      final isDown = e.data['isDown'] == true;
      if (isDown) {
        if (open.contains(key)) {
          idsToRemove.add(step.id);
        } else {
          open.add(key);
        }
      } else {
        if (!open.contains(key)) {
          idsToRemove.add(step.id);
        } else {
          open.remove(key);
        }
      }
    }
    if (idsToRemove.isEmpty) return;
    _steps.removeWhere((e) => idsToRemove.contains(e.id));
  }

  List<({String downId, String upId, int startMs, int endMs})>
      _segmentsForIdentity(String identity) {
    final ordered = _steps.toList()
      ..sort(_compareSteps);
    final openDown = <String, ({String id, int atMs})>{};
    final segments = <({String downId, String upId, int startMs, int endMs})>[];
    for (final step in ordered) {
      final e = step.event;
      final key = _identityForEvent(e);
      if (key != identity) continue;
      final at = e.atMs.clamp(0, 999999).toInt();
      final isDown = e.data['isDown'] == true;
      if (isDown) {
        openDown[key!] = (id: step.id, atMs: at);
      } else {
        final down = openDown[key!];
        if (down == null) continue;
        segments.add((
          downId: down.id,
          upId: step.id,
          startMs: down.atMs,
          endMs: at,
        ));
        openDown.remove(key);
      }
    }
    segments.sort((a, b) => a.startMs.compareTo(b.startMs));
    return segments;
  }

  @override
  Widget build(BuildContext context) {
    final canFinish = _steps.isNotEmpty;
    final slots = _slots;
    final size = MediaQuery.sizeOf(context);
    final expandedToolWidth = (size.width * 0.26).clamp(200.0, 280.0);
    final toolCollapsedWidth = 64.0 + MediaQuery.paddingOf(context).left;
    final durationMs = slots.isEmpty ? 0 : slots.last.atMs;
    final displayDurationMs = (() {
      final base = durationMs <= 0 ? 2000 : durationMs;
      final extra = (base * 0.25).round().clamp(800, 5000);
      return (base + extra).clamp(0, 999999).toInt();
    })();

    return SystemUiModeScope(
      mode: widget.immersive ? SystemUiMode.immersiveSticky : null,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Positioned.fill(
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 360),
                    curve: Curves.easeOutCubic,
                    width:
                        _toolCollapsed ? toolCollapsedWidth : expandedToolWidth,
                    child: _ToolPanel(
                      collapsed: _toolCollapsed,
                      onToggleCollapsed: () => setState(() {
                        _toolCollapsed = !_toolCollapsed;
                      }),
                      onRecordAppend: () => _startRecording(replace: false),
                      onRecordReplace: () => _startRecording(replace: true),
                      onAddKeyboard: () => _beginAdd('keyboard'),
                      onAddMouse: () => _beginAdd('mouse_button'),
                      onAddGamepad: () => _beginAdd('gamepad_button'),
                      onAddDelay: () => _beginAdd('delay'),
                      onAutoCompleteUps:
                          _openDownCount == 0 ? null : _autoCompleteUps,
                      onClear: _steps.isEmpty
                          ? null
                          : () => setState(() {
                                _steps.clear();
                                if (_editorDrawerOpen) {
                                  Navigator.of(context).maybePop();
                                }
                                _closeDraft();
                                _rebuildSlots();
                              }),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _TopBubble(
                            labelController: _labelController,
                            view: _view,
                            onViewChanged: (v) => setState(() {
                              _view = v;
                              _selectedSegment = null;
                            }),
                            selectedSegment: _selectedSegment,
                            onDeleteSelectedSegment: _selectedSegment == null
                                ? null
                                : () => _deleteSelectedSegment(),
                            onAdjustAxisWindowSpan: _adjustAxisWindowSpan,
                            canFinish: canFinish,
                            onFinish: _finish,
                          ),
                          Row(
                            children: [
                              Text(
                                '信号序列',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '${slots.length} 点 / ${_steps.length} 事件 / ${durationMs}ms'
                                '${_openDownCount == 0 ? '' : ' / 未抬起 $_openDownCount'}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.45),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Expanded(
                            child: ScrollConfiguration(
                              behavior: const _NoScrollbarScrollBehavior(),
                              child: _steps.isEmpty
                                  ? _loadingInit
                                      ? const Center(
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                                strokeWidth: 2),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            '暂无信号：用左侧工具添加，或用录制快速生成',
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.35),
                                            ),
                                          ),
                                        )
                                  : IndexedStack(
                                      index:
                                          _view == _MacroSuiteView.defaultView
                                              ? 0
                                              : 1,
                                      children: [
                                        _TimelineStrip(
                                          slots: slots,
                                          scrollController:
                                              _timelineScrollController,
                                          expandedByAtMs: _slotExpandedByAtMs,
                                          selectedId: _editingId,
                                          onToggleExpanded: (atMs) =>
                                              setState(() {
                                            final prev =
                                                _slotExpandedByAtMs[atMs];
                                            _slotExpandedByAtMs[atMs] =
                                                prev == null ? true : !prev;
                                          }),
                                          onNudgeEntriesAtMs: _nudgeEntriesAtMs,
                                          onTapEntry: _beginEditById,
                                          onDeleteEntry: _deleteById,
                                          onDuplicateEntry: _duplicateById,
                                        ),
                                        _PreviewTimeline(
                                          steps: _steps,
                                          durationMs: durationMs,
                                          displayDurationMs: displayDurationMs,
                                          axisWarpOpsByLaneKey:
                                              _axisWarpOpsByLaneKey,
                                          axisSelectionSpanMs: _axisSelectionSpanMs,
                                          rulerScrollController:
                                              _previewRulerScrollController,
                                          trackHorizontalScrollController:
                                              _previewTrackHorizontalScrollController,
                                          axisScrollController:
                                              _previewAxisScrollController,
                                          trackScrollController:
                                              _previewTrackScrollController,
                                          zoom: _previewZoom,
                                          selected: _selectedSegment,
                                          onSelectedChanged: (s) =>
                                              setState(() => _selectedSegment = s),
                                          onMoveSegment: _moveSegmentEntries,
                                          onResizeDownUp: _resizeDownUp,
                                          onAdjustAxisWarp: _adjustAxisWarp,
                                          onCommitAxisWarp: _commitAxisWarp,
                                          onZoomChanged: (z) => setState(() {
                                            _previewZoom = z.clamp(0.4, 4.0);
                                          }),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording({required bool replace}) async {
    if (_editorDrawerOpen) {
      Navigator.of(context).maybePop();
    }
    final result = await Navigator.of(context).push<List<Map<String, dynamic>>>(
      MaterialPageRoute(
        builder: (context) => VirtualControllerMacroRecordingSession(
          definition: widget.definition,
          state: widget.state,
          onInputEvent: (_) {},
          opacity: 1.0,
          showLabels: true,
          initialMixHardwareInput: true,
          immersive: widget.immersive,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == null) return;
    final events =
        result.map((e) => RecordedTimelineEvent.fromJson(e)).toList();
    setState(() {
      if (replace) _steps.clear();
      _steps.addAll(events.map((e) => _StepEntry(id: _newId(), event: e)));
      _sortSteps();
      _sanitizeSteps();
      _rebuildSlots();
      _closeDraft();
    });
  }

  Future<void> _loadInitial(List<Map<String, dynamic>> init) async {
    List<Map<String, dynamic>> sorted;
    if (init.length >= 120) {
      sorted = await compute(_sortRecordingV2, init);
    } else {
      sorted = init.toList()
        ..sort((a, b) {
          final am = (a['atMs'] as num?)?.toInt() ?? 0;
          final bm = (b['atMs'] as num?)?.toInt() ?? 0;
          return am.compareTo(bm);
        });
    }
    if (!mounted) return;
    setState(() {
      _steps
        ..clear()
        ..addAll(
          sorted
              .map((e) => RecordedTimelineEvent.fromJson(e))
              .map((e) => _StepEntry(id: _newId(), event: e)),
        );
      _sortSteps();
      _loadingInit = false;
      _sanitizeSteps();
      _rebuildSlots();
    });
  }

  static List<Map<String, dynamic>> _sortRecordingV2(
      List<Map<String, dynamic>> init) {
    final copied =
        init.map((e) => Map<String, dynamic>.from(e)).toList(growable: true);
    copied.sort((a, b) {
      final am = (a['atMs'] as num?)?.toInt() ?? 0;
      final bm = (b['atMs'] as num?)?.toInt() ?? 0;
      return am.compareTo(bm);
    });
    return copied;
  }

  void _beginAdd(String type) {
    setState(() {
      _editingId = null;
      _draftIsNew = true;
    });
    _openDraft(_defaultEvent(type, atMs: _defaultNewAtMs()));
  }

  void _beginEditById(String id) {
    final idx = _steps.indexWhere((e) => e.id == id);
    if (idx < 0) return;

    final event = _steps[idx].event;
    final isSignal = event.type != 'delay';
    final isDown = event.data['isDown'] == true;
    String nextEditingId = id;
    if (isSignal && !isDown) {
      final downId = _findPairedDownIdForUpIndex(idx);
      if (downId != null) nextEditingId = downId;
    }

    final downIdx = _steps.indexWhere((e) => e.id == nextEditingId);
    if (downIdx < 0) return;
    setState(() {
      _editingId = nextEditingId;
      _draftIsNew = false;
    });
    _openDraft(_steps[downIdx].event);
  }

  void _deleteById(String id) {
    setState(() {
      final idx = _steps.indexWhere((e) => e.id == id);
      if (idx >= 0) _steps.removeAt(idx);
      if (_editingId == id) _closeDraft();
      _sanitizeSteps();
      _rebuildSlots();
    });
  }

  Future<void> _openDraft(RecordedTimelineEvent event) async {
    if (_editorDrawerOpen) return;
    _draft = RecordedTimelineEvent(
      atMs: event.atMs,
      type: event.type,
      data: {...event.data},
    );
    setState(() {});

    _editorDrawerOpen = true;
    final size = MediaQuery.sizeOf(context);
    final width = (size.width * 0.42).clamp(340.0, 460.0);
    final editingId = _editingId;
    final downIdx =
        editingId == null ? -1 : _steps.indexWhere((e) => e.id == editingId);
    final pairedUpAtMs =
        downIdx < 0 ? null : _findPairedUpAtMsForDownIndex(downIdx);

    final payload = await showGeneralDialog<_EditorSavePayload>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'editor',
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, _, __) {
        return Align(
          alignment: Alignment.centerRight,
          child: SafeArea(
            left: false,
            child: Material(
              color: const Color(0xFF1C1C1E),
              child: SizedBox(
                width: width,
                height: double.infinity,
                child: _EditorDrawer(
                  initial: _draft!,
                  initialPairedUpAtMs: pairedUpAtMs,
                  isNew: _draftIsNew,
                  onCancel: () =>
                      Navigator.of(context, rootNavigator: true).pop(),
                  onSave: (v) =>
                      Navigator.of(context, rootNavigator: true).pop(v),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic));
        final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );

    _editorDrawerOpen = false;
    if (!mounted) return;
    if (payload == null) {
      _closeDraft();
      return;
    }
    _applyDraftPayload(payload);
  }

  void _closeDraft() {
    setState(() {
      _draft = null;
      _editingId = null;
      _draftIsNew = false;
    });
  }

  void _applyDraftPayload(_EditorSavePayload payload) {
    final events = payload.events;
    if (events.isEmpty) return;
    setState(() {
      if (_draftIsNew) {
        for (final e in events) {
          _steps.add(_StepEntry(id: _newId(), event: e));
        }
      } else {
        final id = _editingId;
        if (id != null) {
          final idx = _steps.indexWhere((e) => e.id == id);
          if (idx >= 0) {
            if (payload.removePairedUp) {
              final pairedUpId = _findPairedUpIdForDownIndex(idx);
              if (pairedUpId != null) {
                _steps.removeWhere((e) => e.id == pairedUpId);
              }
            }
            _steps[idx].event = events.first;
            if (events.length > 1) {
              for (int i = 1; i < events.length; i++) {
                _steps.insert(
                  idx + i,
                  _StepEntry(id: _newId(), event: events[i]),
                );
              }
            }
          }
        }
      }
      _sortSteps();
      _sanitizeSteps();
      _rebuildSlots();
      _closeDraft();
    });
  }

  String? _findPairedDownIdForUpIndex(int upIndex) {
    if (upIndex < 0 || upIndex >= _steps.length) return null;
    final up = _steps[upIndex].event;
    final key = _identityForEvent(up);
    if (key == null) return null;
    for (int i = upIndex - 1; i >= 0; i--) {
      final e = _steps[i].event;
      final k = _identityForEvent(e);
      if (k != key) continue;
      if (e.data['isDown'] == true) return _steps[i].id;
    }
    return null;
  }

  int? _findPairedUpAtMsForDownIndex(int downIndex) {
    if (downIndex < 0 || downIndex >= _steps.length) return null;
    final down = _steps[downIndex].event;
    final key = _identityForEvent(down);
    if (key == null) return null;
    for (int i = downIndex + 1; i < _steps.length; i++) {
      final e = _steps[i].event;
      final k = _identityForEvent(e);
      if (k != key) continue;
      if (e.data['isDown'] == false) return e.atMs;
      break;
    }
    return null;
  }

  String? _findPairedUpIdForDownIndex(int downIndex) {
    if (downIndex < 0 || downIndex >= _steps.length) return null;
    final down = _steps[downIndex].event;
    final key = _identityForEvent(down);
    if (key == null) return null;
    for (int i = downIndex + 1; i < _steps.length; i++) {
      final e = _steps[i].event;
      final k = _identityForEvent(e);
      if (k != key) continue;
      if (e.data['isDown'] == false) return _steps[i].id;
      break;
    }
    return null;
  }

  RecordedTimelineEvent _defaultEvent(String type, {required int atMs}) {
    switch (type) {
      case 'keyboard':
        return RecordedTimelineEvent(
          atMs: atMs,
          type: 'keyboard',
          data: {'key': 'A', 'isDown': true},
        );
      case 'mouse_button':
        return RecordedTimelineEvent(
          atMs: atMs,
          type: 'mouse_button',
          data: {'button': 'left', 'isDown': true},
        );
      case 'gamepad_button':
        return RecordedTimelineEvent(
          atMs: atMs,
          type: 'gamepad_button',
          data: {'button': 'a', 'isDown': true},
        );
      case 'delay':
      default:
        return RecordedTimelineEvent(
          atMs: atMs,
          type: 'delay',
          data: const {},
        );
    }
  }

  int _defaultNewAtMs() {
    int maxAt = 0;
    for (final e in _steps) {
      if (e.event.atMs > maxAt) maxAt = e.event.atMs;
    }
    return _steps.isEmpty ? 0 : (maxAt + 100);
  }

  void _rebuildSlots() {
    final slots = <_TimeSlot>[];
    for (final e in _steps) {
      if (slots.isEmpty || slots.last.atMs != e.event.atMs) {
        slots.add(_TimeSlot(atMs: e.event.atMs, entries: [e]));
      } else {
        slots.last.entries.add(e);
      }
    }
    _slots = slots;
    _openDownCount = _collectOpenDowns().length;
  }

  Map<String, RecordedTimelineEvent> _collectOpenDowns() {
    final open = <String, RecordedTimelineEvent>{};
    for (final step in _steps) {
      final e = step.event;
      final key = _identityForEvent(e);
      if (key == null) continue;
      final isDown = e.data['isDown'] == true;
      if (isDown) {
        open[key] = e;
      } else {
        open.remove(key);
      }
    }
    return open;
  }

  String? _identityForEvent(RecordedTimelineEvent e) {
    switch (e.type) {
      case 'keyboard':
        final key = e.data['key']?.toString();
        if (key == null || key.trim().isEmpty) return null;
        final normalized = KeyboardKey(key).normalized().code;
        return 'k|$normalized';
      case 'mouse_button':
        final btn = e.data['button']?.toString();
        if (btn == null || btn.trim().isEmpty) return null;
        return 'm|${normalizeMacroInputToken(btn)}';
      case 'gamepad_button':
        final btn = e.data['button']?.toString();
        if (btn == null || btn.trim().isEmpty) return null;
        final token = normalizeMacroInputToken(btn);
        return 'g|${normalizeGamepadButtonCode(token)}';
      default:
        return null;
    }
  }

  void _deleteSelectedSegment() {
    final selected = _selectedSegment;
    if (selected == null) return;
    final isAxisLike =
        selected.type == 'joystick' || selected.type == 'gamepad_axis';
    if (isAxisLike && selected.entryIds.isEmpty) {
      final laneKey = selected.laneKey;
      final originStart =
          (selected.originStartMs ?? selected.startMs).clamp(0, 999999).toInt();
      final originEnd =
          (selected.originEndMs ?? selected.endMs).clamp(originStart, 999999).toInt();
      setState(() {
        _steps.removeWhere((e) {
          if (_axisLaneKeyForPreview(e.event) != laneKey) return false;
          final t = e.event.atMs;
          return t >= originStart && t <= originEnd;
        });
        final opId = selected.axisWarpId;
        if (opId != null) {
          final ops = List<_AxisWarpOp>.of(_axisWarpOpsByLaneKey[laneKey] ?? const []);
          ops.removeWhere((e) => e.id == opId);
          if (ops.isEmpty) {
            _axisWarpOpsByLaneKey.remove(laneKey);
          } else {
            _axisWarpOpsByLaneKey[laneKey] = ops;
          }
        }
        _selectedSegment = null;
        _sanitizeSteps();
        _rebuildSlots();
      });
      return;
    }
    final idSet = selected.entryIds.toSet();
    setState(() {
      _steps.removeWhere((e) => idSet.contains(e.id));
      _selectedSegment = null;
      _sanitizeSteps();
      _rebuildSlots();
    });
  }

  void _adjustAxisWarp(
    String laneKey, {
    required int deltaStartMs,
    required int deltaEndMs,
  }) {
    if (deltaStartMs == 0 && deltaEndMs == 0) return;
    final selected = _selectedSegment;
    if (selected == null) return;
    final isAxisLike = selected.type == 'joystick' || selected.type == 'gamepad_axis';
    if (!isAxisLike) return;
    if (selected.laneKey != laneKey) return;

    var nextStart = (selected.startMs + deltaStartMs).clamp(0, 999999).toInt();
    var nextEnd = (selected.endMs + deltaEndMs).clamp(0, 999999).toInt();
    if (nextEnd < nextStart) {
      if (deltaStartMs != 0) {
        nextStart = nextEnd;
      } else {
        nextEnd = nextStart;
      }
    }
    final originStart =
        (selected.originStartMs ?? selected.startMs).clamp(0, 999999).toInt();
    final originEnd = (selected.originEndMs ?? selected.endMs)
        .clamp(originStart, 999999)
        .toInt();

    setState(() {
      final opId = selected.axisWarpId ??
          'warp_${laneKey}_${DateTime.now().microsecondsSinceEpoch}';
      final nextOp = _AxisWarpOp(
        id: opId,
        originStartMs: originStart,
        originEndMs: originEnd,
        mappedStartMs: nextStart,
        mappedEndMs: nextEnd,
      );
      _axisWarpOpsByLaneKey[laneKey] = [nextOp];
      _selectedSegment = _SelectedSegment(
        id: selected.id,
        laneKey: selected.laneKey,
        type: selected.type,
        startMs: nextStart,
        endMs: nextEnd,
        entryIds: selected.entryIds,
        originStartMs: originStart,
        originEndMs: originEnd,
        applyAxisWarp: true,
        axisWarpId: opId,
      );
    });
  }

  void _commitAxisWarp(_SelectedSegment selected) {
    if (!selected.applyAxisWarp) return;
    final isAxisLike =
        selected.type == 'joystick' || selected.type == 'gamepad_axis';
    if (!isAxisLike) return;
    if (selected.entryIds.isNotEmpty) return;

    final laneKey = selected.laneKey;
    final originStart =
        (selected.originStartMs ?? selected.startMs).clamp(0, 999999).toInt();
    final originEnd = (selected.originEndMs ?? selected.endMs)
        .clamp(originStart, 999999)
        .toInt();
    final mappedStart = selected.startMs.clamp(0, 999999).toInt();
    final mappedEnd = selected.endMs.clamp(0, 999999).toInt();

    int mapAt(int t) {
      final at = t.clamp(0, 999999).toInt();
      if (at <= originStart) {
        if (originStart == 0) return 0;
        final ratio = at / originStart;
        return (ratio * mappedStart).round().clamp(0, 999999).toInt();
      }
      if (at <= originEnd) {
        final denom = (originEnd - originStart);
        if (denom == 0) return mappedStart;
        final ratio = (at - originStart) / denom;
        final mapped =
            mappedStart + ratio * (mappedEnd - mappedStart);
        return mapped.round().clamp(0, 999999).toInt();
      }
      final shift = mappedEnd - originEnd;
      return (at + shift).clamp(0, 999999).toInt();
    }

    setState(() {
      for (final step in _steps) {
        final key = _axisLaneKeyForPreview(step.event);
        if (key != laneKey) continue;
        step.event = RecordedTimelineEvent(
          atMs: mapAt(step.event.atMs),
          type: step.event.type,
          data: {...step.event.data},
        );
      }
      _axisWarpOpsByLaneKey.remove(laneKey);
      _sortSteps();
      _rebuildSlots();
      _selectedSegment = _SelectedSegment(
        id: selected.id,
        laneKey: selected.laneKey,
        type: selected.type,
        startMs: mappedStart,
        endMs: mappedEnd,
        entryIds: const [],
        applyAxisWarp: false,
      );
    });
  }

  void _adjustAxisWindowSpan(int deltaSpanMs) {
    if (deltaSpanMs == 0) return;
    final selected = _selectedSegment;
    if (selected == null) return;
    final isAxisWindow = (selected.type == 'joystick' ||
            selected.type == 'gamepad_axis') &&
        selected.entryIds.isEmpty;
    if (!isAxisWindow) return;

    int unmapAxisAtMs(List<_AxisWarpOp> ops, int mappedMs) {
      final m = mappedMs.clamp(0, 999999).toInt();
      if (ops.isEmpty) return m;
      final ordered = ops.toList()
        ..sort((a, b) => a.originStartMs.compareTo(b.originStartMs));
      final points = <({int o, int m})>[
        (o: 0, m: 0),
        for (final op in ordered) ...[
          (o: op.originStartMs, m: op.mappedStartMs),
          (o: op.originEndMs, m: op.mappedEndMs),
        ],
      ]..sort((a, b) => a.o.compareTo(b.o));
      for (var i = 0; i < points.length - 1; i++) {
        final a = points[i];
        final b = points[i + 1];
        if (m <= b.m) {
          final denom = (b.m - a.m);
          final ratio = denom == 0 ? 0.0 : (m - a.m) / denom;
          final origin = a.o + ratio * (b.o - a.o);
          return origin.round().clamp(0, 999999).toInt();
        }
      }
      final last = points.last;
      final shift = last.m - last.o;
      return (m - shift).clamp(0, 999999).toInt();
    }

    _axisSelectionSpanMs =
        (_axisSelectionSpanMs + deltaSpanMs).clamp(200, 20000).toInt();

    final currentStart = selected.startMs;
    final currentEnd = selected.endMs;

    final center = ((currentStart + currentEnd) / 2).round();
    // final curSpan = (currentEnd - currentStart).abs().clamp(0, 999999);
    final nextSpan = _axisSelectionSpanMs.clamp(200, 20000).toInt();
    var nextStart = (center - nextSpan ~/ 2).clamp(0, 999999).toInt();
    var nextEnd = (nextStart + nextSpan).clamp(nextStart, 999999).toInt();

    final opsForLane =
        _axisWarpOpsByLaneKey[selected.laneKey] ?? const <_AxisWarpOp>[];
    final nextOriginStart = unmapAxisAtMs(opsForLane, nextStart);
    final nextOriginEnd = unmapAxisAtMs(opsForLane, nextEnd)
        .clamp(nextOriginStart, 999999)
        .toInt();

    setState(() {
      _selectedSegment = _SelectedSegment(
        id: selected.id,
        laneKey: selected.laneKey,
        type: selected.type,
        startMs: nextStart,
        endMs: nextEnd,
        entryIds: selected.entryIds,
        originStartMs: nextOriginStart,
        originEndMs: nextOriginEnd,
        applyAxisWarp: false,
        axisWarpId: selected.axisWarpId,
      );
    });
  }

  void _moveSegmentEntries(List<String> entryIds, int deltaMs) {
    if (entryIds.isEmpty || deltaMs == 0) return;
    final idSet = entryIds.toSet();
    int clampDelta() {
      var minAt = 999999;
      var maxAt = 0;
      var found = false;
      String? identity;
      for (final e in _steps) {
        if (!idSet.contains(e.id)) continue;
        found = true;
        final t = e.event.atMs.clamp(0, 999999).toInt();
        if (t < minAt) minAt = t;
        if (t > maxAt) maxAt = t;
        identity ??= _identityForEvent(e.event);
      }
      if (!found) return 0;
      var minDelta = 0 - minAt;
      var maxDelta = 999999 - maxAt;

      if (identity != null &&
          identity.trim().isNotEmpty &&
          entryIds.length == 2) {
        final segs = _segmentsForIdentity(identity);
        final me = segs
            .where((s) => idSet.contains(s.downId) && idSet.contains(s.upId))
            .toList(growable: false);
        if (me.length == 1) {
          final current = me.single;
          final prev = segs
              .where((s) => s.endMs <= current.startMs && s != current)
              .fold<({String downId, String upId, int startMs, int endMs})?>(
                  null, (best, s) {
            if (best == null) return s;
            return s.endMs > best.endMs ? s : best;
          });
          final next = segs
              .where((s) => s.startMs >= current.endMs && s != current)
              .fold<({String downId, String upId, int startMs, int endMs})?>(
                  null, (best, s) {
            if (best == null) return s;
            return s.startMs < best.startMs ? s : best;
          });

          if (prev != null) {
            minDelta =
                ((prev.endMs + 1) - minAt).clamp(minDelta, 999999).toInt();
          }
          if (next != null) {
            maxDelta =
                ((next.startMs - 1) - maxAt).clamp(-999999, maxDelta).toInt();
          }
        }
      }

      return deltaMs.clamp(minDelta, maxDelta).toInt();
    }

    final applied = clampDelta();
    if (applied == 0) return;
    setState(() {
      for (final e in _steps) {
        if (!idSet.contains(e.id)) continue;
        e.event = RecordedTimelineEvent(
          atMs: (e.event.atMs + applied).clamp(0, 999999).toInt(),
          type: e.event.type,
          data: {...e.event.data},
        );
      }
      final selected = _selectedSegment;
      if (selected != null &&
          selected.entryIds.isNotEmpty &&
          selected.entryIds.every(idSet.contains)) {
        final start = (selected.startMs + applied).clamp(0, 999999).toInt();
        final end = (selected.endMs + applied).clamp(start, 999999).toInt();
        _selectedSegment = _SelectedSegment(
          id: selected.id,
          laneKey: selected.laneKey,
          type: selected.type,
          startMs: start,
          endMs: end,
          entryIds: selected.entryIds,
        );
      }
      _sortSteps();
      _sanitizeSteps();
      _rebuildSlots();
    });
  }

  void _resizeDownUp(
    String downId,
    String upId, {
    required int deltaStartMs,
    required int deltaEndMs,
  }) {
    if (deltaStartMs == 0 && deltaEndMs == 0) return;
    final downIdx = _steps.indexWhere((e) => e.id == downId);
    final upIdx = _steps.indexWhere((e) => e.id == upId);
    if (downIdx < 0 || upIdx < 0) return;

    setState(() {
      final down = _steps[downIdx].event;
      final up = _steps[upIdx].event;
      final identity = _identityForEvent(down);
      final segs =
          identity == null ? const [] : _segmentsForIdentity(identity);
      final current = segs
          .where((s) => s.downId == downId && s.upId == upId)
          .fold<({String downId, String upId, int startMs, int endMs})?>(
              null, (prev, s) => prev ?? s);
      final prevSeg = current == null
          ? null
          : segs
              .where((s) => s.endMs <= current.startMs && s != current)
              .fold<({String downId, String upId, int startMs, int endMs})?>(
                  null, (best, s) {
              if (best == null) return s;
              return s.endMs > best.endMs ? s : best;
            });
      final nextSeg = current == null
          ? null
          : segs
              .where((s) => s.startMs >= current.endMs && s != current)
              .fold<({String downId, String upId, int startMs, int endMs})?>(
                  null, (best, s) {
              if (best == null) return s;
              return s.startMs < best.startMs ? s : best;
            });

      final minDown = prevSeg?.endMs ?? 0;
      final maxUp = nextSeg?.startMs ?? 999999;
      final minDownGap =
          prevSeg == null ? minDown : (minDown + 1).clamp(0, 999999).toInt();
      final maxUpGap =
          nextSeg == null ? maxUp : (maxUp - 1).clamp(0, 999999).toInt();
      if (maxUpGap <= minDownGap) return;

      var nextDown = (down.atMs + deltaStartMs).clamp(0, 999999).toInt();
      var nextUp = (up.atMs + deltaEndMs).clamp(0, 999999).toInt();
      nextDown = nextDown.clamp(minDownGap, 999999).toInt();
      nextUp = nextUp.clamp(0, maxUpGap).toInt();
      if (nextUp <= nextDown) {
        if (deltaStartMs != 0) {
          nextDown = (nextUp - 1).clamp(minDownGap, 999999).toInt();
        } else {
          nextUp = (nextDown + 1).clamp(0, maxUpGap).toInt();
        }
        if (nextUp <= nextDown) return;
      }
      _steps[downIdx].event = RecordedTimelineEvent(
        atMs: nextDown,
        type: down.type,
        data: {...down.data},
      );
      _steps[upIdx].event = RecordedTimelineEvent(
        atMs: nextUp,
        type: up.type,
        data: {...up.data},
      );
      final selected = _selectedSegment;
      if (selected != null &&
          selected.entryIds.length == 2 &&
          selected.entryIds.first == downId &&
          selected.entryIds.last == upId) {
        _selectedSegment = _SelectedSegment(
          id: selected.id,
          laneKey: selected.laneKey,
          type: selected.type,
          startMs: nextDown,
          endMs: nextUp,
          entryIds: selected.entryIds,
        );
      }
      _sortSteps();
      _sanitizeSteps();
      _rebuildSlots();
    });
  }

  String? _axisLaneKeyForPreview(RecordedTimelineEvent e) {
    switch (e.type) {
      case 'gamepad_axis':
        final axisId = normalizeMacroInputToken(e.data['axisId']?.toString() ?? '');
        return 'ga:$axisId';
      case 'joystick':
        return 'j:virtual';
      default:
        return null;
    }
  }

  void _autoCompleteUps() {
    setState(() {
      final open = _collectOpenDowns();
      if (open.isEmpty) return;
      final maxAt = _steps.isEmpty ? 0 : _steps.last.event.atMs;
      int i = 0;
      for (final down in open.values) {
        i++;
        final atMs = (maxAt + 50 * i).clamp(0, 999999).toInt();
        final data = <String, dynamic>{...down.data, 'isDown': false};
        _steps.add(
          _StepEntry(
            id: _newId(),
            event:
                RecordedTimelineEvent(atMs: atMs, type: down.type, data: data),
          ),
        );
      }
      _sortSteps();
      _sanitizeSteps();
      _rebuildSlots();
      if (_editorDrawerOpen) {
        Navigator.of(context).maybePop();
      }
      _closeDraft();
    });
  }

  void _nudgeEntriesAtMs(List<String> entryIds, int deltaMs) {
    if (entryIds.isEmpty || deltaMs == 0) return;
    final idSet = entryIds.toSet();
    int clampDelta() {
      var minAt = 999999;
      var maxAt = 0;
      var found = false;
      for (final e in _steps) {
        if (!idSet.contains(e.id)) continue;
        found = true;
        final t = e.event.atMs.clamp(0, 999999).toInt();
        if (t < minAt) minAt = t;
        if (t > maxAt) maxAt = t;
      }
      if (!found) return 0;
      final minDelta = 0 - minAt;
      final maxDelta = 999999 - maxAt;
      return deltaMs.clamp(minDelta, maxDelta).toInt();
    }

    final applied = clampDelta();
    if (applied == 0) return;
    setState(() {
      int? prevAtMs;
      for (final e in _steps) {
        if (!idSet.contains(e.id)) continue;
        prevAtMs ??= e.event.atMs;
        e.event = RecordedTimelineEvent(
          atMs: (e.event.atMs + applied).clamp(0, 999999).toInt(),
          type: e.event.type,
          data: {...e.event.data},
        );
      }
      _sortSteps();
      _sanitizeSteps();
      final at = prevAtMs;
      if (at != null) {
        final expanded = _slotExpandedByAtMs.remove(at);
        if (expanded != null) {
          final nextAtMs = (at + applied).clamp(0, 999999).toInt();
          _slotExpandedByAtMs[nextAtMs] = expanded;
        }
      }
      _rebuildSlots();
    });
  }

  void _duplicateById(String id) {
    setState(() {
      final idx = _steps.indexWhere((e) => e.id == id);
      if (idx < 0) return;
      final orig = _steps[idx].event;
      final copied = RecordedTimelineEvent(
        atMs: orig.atMs,
        type: orig.type,
        data: {...orig.data},
      );
      _steps.insert(idx + 1, _StepEntry(id: _newId(), event: copied));
      _sortSteps();
      _sanitizeSteps();
      _rebuildSlots();
    });
  }

  static String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_seed++}';
  static int _seed = 0;
}

class _NoScrollbarScrollBehavior extends MaterialScrollBehavior {
  const _NoScrollbarScrollBehavior();

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
