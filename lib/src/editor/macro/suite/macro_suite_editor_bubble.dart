part of '../macro_suite_page.dart';

const List<String> _keyboardKeyCandidates = [
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
  '0',
  '1',
  '2',
  '3',
  '4',
  '5',
  '6',
  '7',
  '8',
  '9',
  'Space',
  'Enter',
  'Tab',
  'Escape',
  'Backspace',
  'ArrowUp',
  'ArrowDown',
  'ArrowLeft',
  'ArrowRight',
  'F1',
  'F2',
  'F3',
  'F4',
  'F5',
  'F6',
  'F7',
  'F8',
  'F9',
  'F10',
  'F11',
  'F12',
];

class _EditorSavePayload {
  const _EditorSavePayload({
    required this.events,
    this.removePairedUp = false,
  });

  final List<RecordedTimelineEvent> events;
  final bool removePairedUp;
}

enum _SignalTimeMode { range, single }

class _EditorDrawer extends StatefulWidget {
  const _EditorDrawer({
    required this.initial,
    required this.initialPairedUpAtMs,
    required this.isNew,
    required this.onCancel,
    required this.onSave,
  });

  final RecordedTimelineEvent initial;
  final int? initialPairedUpAtMs;
  final bool isNew;
  final VoidCallback onCancel;
  final ValueChanged<_EditorSavePayload> onSave;

  @override
  State<_EditorDrawer> createState() => _EditorDrawerState();
}

class _EditorDrawerState extends State<_EditorDrawer> {
  late _SignalTimeMode _timeMode;

  late int _atMs;
  late int _startMs;
  late int _endMs;

  bool _openEnded = false;
  late bool _isDown;
  late String _keyboardKey;
  late Set<String> _modifiers;
  late String _gamepadButton;
  late String _mouseButton;

  bool _pair = false;
  int _pairDelayMs = 0;

  String get _type => widget.initial.type;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _atMs = init.atMs.clamp(0, 999999);
    _startMs = _atMs;
    final pairedUpAtMs = widget.initialPairedUpAtMs;
    if (_type != 'delay') {
      _timeMode = _SignalTimeMode.range;
      if (widget.isNew) {
        _endMs = _startMs;
        _openEnded = false;
      } else if (pairedUpAtMs != null) {
        _endMs = pairedUpAtMs.clamp(0, 999999);
        _openEnded = false;
      } else {
        _endMs = _startMs;
        _openEnded = !widget.isNew;
      }
    } else {
      _timeMode = _SignalTimeMode.single;
      _endMs = _startMs;
    }
    final data = init.data;
    _isDown = data['isDown'] == false ? false : true;
    _keyboardKey = data['key']?.toString() ?? 'A';
    _modifiers = Set<String>.from(
        List<String>.from(data['modifiers'] as List? ?? const []));
    _gamepadButton = data['button']?.toString() ?? 'a';
    _mouseButton = data['button']?.toString() ?? 'left';
  }

  void _save() {
    final type = _type;
    final atMs = _atMs.clamp(0, 999999).toInt();
    final startMs = _startMs.clamp(0, 999999).toInt();
    final endMs = _endMs.clamp(0, 999999).toInt();

    final data = <String, dynamic>{};
    switch (type) {
      case 'delay':
        break;
      case 'keyboard':
        data['key'] = _keyboardKey.trim().isEmpty ? 'A' : _keyboardKey.trim();
        if (_modifiers.isNotEmpty) {
          data['modifiers'] = _modifiers.toList(growable: false);
        }
        break;
      case 'mouse_button':
        data['button'] = _mouseButton;
        break;
      case 'gamepad_button':
        data['button'] = _gamepadButton.trim().isEmpty ? 'a' : _gamepadButton;
        break;
      default:
        return;
    }

    if (type == 'delay') {
      widget.onSave(
        _EditorSavePayload(
          events: [RecordedTimelineEvent(atMs: atMs, type: type, data: data)],
        ),
      );
      return;
    }

    if (_timeMode == _SignalTimeMode.range) {
      final downData = <String, dynamic>{...data, 'isDown': true};
      final down =
          RecordedTimelineEvent(atMs: startMs, type: type, data: downData);

      if (_openEnded) {
        widget.onSave(
          _EditorSavePayload(
            events: [down],
            removePairedUp: !widget.isNew && widget.initialPairedUpAtMs != null,
          ),
        );
        return;
      }

      final fixedEndMs = endMs < startMs ? startMs : endMs;
      final upData = <String, dynamic>{...data, 'isDown': false};
      final up =
          RecordedTimelineEvent(atMs: fixedEndMs, type: type, data: upData);
      widget.onSave(_EditorSavePayload(events: [down, up]));
      return;
    }

    final downAtMs = atMs;
    final downData = <String, dynamic>{
      ...data,
      'isDown': _pair ? true : _isDown
    };
    final first =
        RecordedTimelineEvent(atMs: downAtMs, type: type, data: downData);
    if (!_pair) {
      widget.onSave(_EditorSavePayload(events: [first]));
      return;
    }

    final upAtMs = (downAtMs + _pairDelayMs).clamp(0, 999999).toInt();
    final upData = <String, dynamic>{...data, 'isDown': false};
    final second =
        RecordedTimelineEvent(atMs: upAtMs, type: type, data: upData);
    widget.onSave(_EditorSavePayload(events: [first, second]));
  }

  List<String> _withCurrentFirst(String current, List<String> base) {
    if (current.trim().isEmpty) return base;
    if (base.contains(current)) return base;
    return [current, ...base];
  }

  Widget _dropdown({
    required String label,
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1C1C1E),
              iconEnabledColor: Colors.white70,
              style: const TextStyle(color: Colors.white),
              items: options
                  .map(
                    (v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    ),
                  )
                  .toList(growable: false),
              onChanged: (v) {
                if (v == null) return;
                onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final type = _type;
    final showSignalMode = type != 'delay';
    final canRange = showSignalMode;
    final endMs = _openEnded ? null : _endMs;
    final durationMs =
        endMs == null ? null : (endMs - _startMs).clamp(0, 999999);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.03),
            border: Border(
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _titleForType(type),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, color: Colors.white70),
                visualDensity: VisualDensity.compact,
                tooltip: '关闭',
              ),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (canRange)
                  SegmentedButton<_SignalTimeMode>(
                    segments: const [
                      ButtonSegment(
                          value: _SignalTimeMode.range, label: Text('区间')),
                      ButtonSegment(
                          value: _SignalTimeMode.single, label: Text('单点')),
                    ],
                    selected: {_timeMode},
                    onSelectionChanged: (v) =>
                        setState(() => _timeMode = v.first),
                    showSelectedIcon: false,
                  ),
                if (canRange) const SizedBox(height: 14),
                if (!showSignalMode || _timeMode == _SignalTimeMode.single) ...[
                  _MsStepper(
                    label: '时间点',
                    value: _atMs,
                    onChanged: (v) => setState(() => _atMs = v),
                  ),
                  const SizedBox(height: 12),
                ],
                if (showSignalMode && _timeMode == _SignalTimeMode.range) ...[
                  _MsStepper(
                    label: '开始 (Down)',
                    value: _startMs,
                    onChanged: (v) => setState(() {
                      _startMs = v;
                      if (!_openEnded && _endMs < _startMs) _endMs = _startMs;
                    }),
                  ),
                  const SizedBox(height: 12),
                  if (!_openEnded) ...[
                    _MsStepper(
                      label: '结束 (Up)',
                      value: _endMs,
                      onChanged: (v) => setState(() {
                        _endMs = v;
                        if (_endMs < _startMs) _startMs = _endMs;
                      }),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Row(
                    children: [
                      FilterChip(
                        label: const Text('开放(无Up)'),
                        selected: _openEnded,
                        showCheckmark: false,
                        onSelected: (v) => setState(() {
                          _openEnded = v;
                          if (!_openEnded && _endMs < _startMs) {
                            _endMs = _startMs;
                          }
                        }),
                      ),
                      const Spacer(),
                      if (durationMs != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.10),
                            ),
                          ),
                          child: Text(
                            '长度 $durationMs ms',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.75),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _openEnded
                        ? '开放区间会保留 Down，不生成 Up；可在工具栏“自动补Up”统一收口。'
                        : '区间会生成一对 Down/Up；它们会在时间轴预览里成为一个可拖拽的时间条。',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 12,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 14),
                ],
                if (showSignalMode && _timeMode == _SignalTimeMode.single) ...[
                  Row(
                    children: [
                      if (!_pair)
                        Expanded(
                          child: SegmentedButton<bool>(
                            segments: const [
                              ButtonSegment(value: true, label: Text('Down')),
                              ButtonSegment(value: false, label: Text('Up')),
                            ],
                            selected: {_isDown},
                            onSelectionChanged: (v) =>
                                setState(() => _isDown = v.first),
                            showSelectedIcon: false,
                          ),
                        ),
                      if (!_pair) const SizedBox(width: 10),
                      FilterChip(
                        label: const Text('Down+Up'),
                        selected: _pair,
                        onSelected: (v) => setState(() {
                          _pair = v;
                          if (_pair) _isDown = true;
                        }),
                        showCheckmark: false,
                      ),
                    ],
                  ),
                  if (_pair) ...[
                    const SizedBox(height: 10),
                    _MsStepper(
                      label: 'Up 延后',
                      value: _pairDelayMs,
                      onChanged: (v) => setState(() => _pairDelayMs = v),
                      min: 0,
                    ),
                    const SizedBox(height: 14),
                  ] else
                    const SizedBox(height: 14),
                ],
                if (type == 'keyboard') ...[
                  _dropdown(
                    label: 'Key',
                    value: _keyboardKey,
                    options: _withCurrentFirst(
                      _keyboardKey,
                      _keyboardKeyCandidates,
                    ),
                    onChanged: (v) => setState(() => _keyboardKey = v),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _ModifierChip(
                        label: 'Ctrl',
                        selected: _modifiers.contains('ctrl'),
                        onChanged: (selected) {
                          final next = Set<String>.from(_modifiers);
                          if (selected) {
                            next.add('ctrl');
                          } else {
                            next.remove('ctrl');
                          }
                          setState(() => _modifiers = next);
                        },
                      ),
                      _ModifierChip(
                        label: 'Shift',
                        selected: _modifiers.contains('shift'),
                        onChanged: (selected) {
                          final next = Set<String>.from(_modifiers);
                          if (selected) {
                            next.add('shift');
                          } else {
                            next.remove('shift');
                          }
                          setState(() => _modifiers = next);
                        },
                      ),
                      _ModifierChip(
                        label: 'Alt',
                        selected: _modifiers.contains('alt'),
                        onChanged: (selected) {
                          final next = Set<String>.from(_modifiers);
                          if (selected) {
                            next.add('alt');
                          } else {
                            next.remove('alt');
                          }
                          setState(() => _modifiers = next);
                        },
                      ),
                      _ModifierChip(
                        label: 'Meta',
                        selected: _modifiers.contains('meta'),
                        onChanged: (selected) {
                          final next = Set<String>.from(_modifiers);
                          if (selected) {
                            next.add('meta');
                          } else {
                            next.remove('meta');
                          }
                          setState(() => _modifiers = next);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                ],
                if (type == 'mouse_button') ...[
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'left', label: Text('Left')),
                      ButtonSegment(value: 'middle', label: Text('Middle')),
                      ButtonSegment(value: 'right', label: Text('Right')),
                    ],
                    selected: {_mouseButton},
                    onSelectionChanged: (v) =>
                        setState(() => _mouseButton = v.first),
                    showSelectedIcon: false,
                  ),
                  const SizedBox(height: 14),
                ],
                if (type == 'gamepad_button') ...[
                  _dropdown(
                    label: 'Button',
                    value: _gamepadButton,
                    options: _withCurrentFirst(
                      _gamepadButton,
                      GamepadButtonId.builtIns.map((e) => e.code).toList(),
                    ),
                    onChanged: (v) => setState(() => _gamepadButton = v),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('保存'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _titleForType(String type) {
    switch (type) {
      case 'keyboard':
        return '键盘信号';
      case 'mouse_button':
        return '鼠标按钮信号';
      case 'gamepad_button':
        return '手柄按钮信号';
      case 'delay':
        return '延时';
      default:
        return type;
    }
  }
}

class _ModifierChip extends StatelessWidget {
  const _ModifierChip({
    required this.label,
    required this.selected,
    required this.onChanged,
  });

  final String label;
  final bool selected;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onChanged,
      showCheckmark: false,
    );
  }
}

class _MsStepper extends StatefulWidget {
  const _MsStepper({
    required this.label,
    required this.value,
    required this.onChanged,
    this.min = 0,
  });

  static const int _max = 999999;

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final int min;

  @override
  State<_MsStepper> createState() => _MsStepperState();
}

class _MsStepperState extends State<_MsStepper> {
  Timer? _holdTimer;

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold(int direction) {
    _holdTimer?.cancel();
    widget.onChanged(
      (widget.value + direction * 1).clamp(widget.min, _MsStepper._max),
    );
    _holdTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      const step = 1;
      widget.onChanged(
        (widget.value + direction * step).clamp(widget.min, _MsStepper._max),
      );
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            GestureDetector(
              onTap: () => widget.onChanged(
                (widget.value - 1).clamp(widget.min, _MsStepper._max),
              ),
              onLongPressStart: (_) => _startHold(-1),
              onLongPressEnd: (_) => _stopHold(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: const Icon(Icons.remove, color: Colors.white70),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Text(
                  '${widget.value}ms',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () => widget.onChanged(
                (widget.value + 1).clamp(widget.min, _MsStepper._max),
              ),
              onLongPressStart: (_) => _startHold(1),
              onLongPressEnd: (_) => _stopHold(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: Colors.white.withValues(alpha: 0.10)),
                ),
                child: const Icon(Icons.add, color: Colors.white70),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
