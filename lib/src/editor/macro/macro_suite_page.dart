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
  bool _toolCollapsed = false;

  String? _editingId;
  RecordedTimelineEvent? _draft;
  bool _draftIsNew = false;

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
    final ordered = _steps.toList()
      ..sort((a, b) => a.event.atMs.compareTo(b.event.atMs));
    final recordingV2 =
        ordered.map((e) => e.event.toJson()).toList(growable: false);
    Navigator.of(context)
        .pop(MacroDraft(label: label, recordingV2: recordingV2));
  }

  @override
  Widget build(BuildContext context) {
    final canFinish = _steps.isNotEmpty;
    final slots = _slots;
    final size = MediaQuery.sizeOf(context);
    final expandedToolWidth = (size.width * 0.26).clamp(200.0, 280.0);
    final toolCollapsedWidth = 64.0 + MediaQuery.paddingOf(context).left;
    final durationMs = slots.isEmpty ? 0 : slots.last.atMs;

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
                    width: _toolCollapsed ? toolCollapsedWidth : expandedToolWidth,
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
                            }),
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
                                          onNudgeEntriesAtMs:
                                              _nudgeEntriesAtMs,
                                          onTapEntry: _beginEditById,
                                          onDeleteEntry: _deleteById,
                                          onDuplicateEntry: _duplicateById,
                                        ),
                                        _PreviewTimeline(
                                          steps: _steps,
                                          durationMs: durationMs,
                                          rulerScrollController:
                                              _previewRulerScrollController,
                                          trackHorizontalScrollController:
                                              _previewTrackHorizontalScrollController,
                                          axisScrollController:
                                              _previewAxisScrollController,
                                          trackScrollController:
                                              _previewTrackScrollController,
                                          onTapEntry: _beginEditById,
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
            if (_draft != null)
              Positioned(
                top: 0,
                right: 0,
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: _EditorBubble(
                    initial: _draft!,
                    onCancel: _closeDraft,
                    onSave: _applyDraftEvents,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _startRecording({required bool replace}) async {
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
      _steps.sort((a, b) => a.event.atMs.compareTo(b.event.atMs));
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
      _steps.sort((a, b) => a.event.atMs.compareTo(b.event.atMs));
      _loadingInit = false;
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
    _editingId = null;
    _draftIsNew = true;
    _openDraft(_defaultEvent(type, atMs: _defaultNewAtMs()));
  }

  void _beginEditById(String id) {
    final idx = _steps.indexWhere((e) => e.id == id);
    if (idx < 0) return;
    _editingId = id;
    _draftIsNew = false;
    _openDraft(_steps[idx].event);
  }

  void _deleteById(String id) {
    setState(() {
      final idx = _steps.indexWhere((e) => e.id == id);
      if (idx >= 0) _steps.removeAt(idx);
      if (_editingId == id) _closeDraft();
      _rebuildSlots();
    });
  }

  void _openDraft(RecordedTimelineEvent event) {
    _draft = RecordedTimelineEvent(
      atMs: event.atMs,
      type: event.type,
      data: {...event.data},
    );
    setState(() {});
  }

  void _closeDraft() {
    setState(() {
      _draft = null;
      _editingId = null;
      _draftIsNew = false;
    });
  }

  void _applyDraftEvents(List<RecordedTimelineEvent> events) {
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
      _steps.sort((a, b) => a.event.atMs.compareTo(b.event.atMs));
      _rebuildSlots();
      _closeDraft();
    });
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
        final mods = List<String>.from(e.data['modifiers'] as List? ?? const [])
          ..sort();
        return 'k|$key|${mods.join('+')}';
      case 'mouse_button':
        final btn = e.data['button']?.toString();
        if (btn == null || btn.trim().isEmpty) return null;
        return 'm|$btn';
      case 'gamepad_button':
        final btn = e.data['button']?.toString();
        if (btn == null || btn.trim().isEmpty) return null;
        return 'g|$btn';
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
            event: RecordedTimelineEvent(atMs: atMs, type: down.type, data: data),
          ),
        );
      }
      _steps.sort((a, b) => a.event.atMs.compareTo(b.event.atMs));
      _rebuildSlots();
      _closeDraft();
    });
  }

  void _nudgeEntriesAtMs(List<String> entryIds, int deltaMs) {
    if (entryIds.isEmpty || deltaMs == 0) return;
    final idSet = entryIds.toSet();
    setState(() {
      int? prevAtMs;
      for (final e in _steps) {
        if (!idSet.contains(e.id)) continue;
        prevAtMs ??= e.event.atMs;
        e.event = RecordedTimelineEvent(
          atMs: (e.event.atMs + deltaMs).clamp(0, 999999).toInt(),
          type: e.event.type,
          data: {...e.event.data},
        );
      }
      _steps.sort((a, b) => a.event.atMs.compareTo(b.event.atMs));
      final at = prevAtMs;
      if (at != null) {
        final expanded = _slotExpandedByAtMs.remove(at);
        if (expanded != null) {
          final nextAtMs = (at + deltaMs).clamp(0, 999999).toInt();
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
      _steps.sort((a, b) => a.event.atMs.compareTo(b.event.atMs));
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
