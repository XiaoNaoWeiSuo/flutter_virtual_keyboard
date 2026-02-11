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

class _EditorBubble extends StatefulWidget {
  const _EditorBubble({
    required this.initial,
    required this.onCancel,
    required this.onSave,
  });

  final RecordedTimelineEvent initial;
  final VoidCallback onCancel;
  final ValueChanged<List<RecordedTimelineEvent>> onSave;

  @override
  State<_EditorBubble> createState() => _EditorBubbleState();
}

class _EditorBubbleState extends State<_EditorBubble> {
  Timer? _holdTimer;
  int _holdTicks = 0;

  late int _atMs;
  late bool _isDown;
  late String _keyboardKey;
  late Set<String> _modifiers;
  late String _gamepadButton;
  late String _mouseButton;

  bool _pair = false;
  int _pairDelayMs = 50;

  String get _type => widget.initial.type;

  @override
  void initState() {
    super.initState();
    final init = widget.initial;
    _atMs = init.atMs.clamp(0, 999999);
    final data = init.data;
    _isDown = data['isDown'] == false ? false : true;
    _keyboardKey = data['key']?.toString() ?? 'A';
    _modifiers = Set<String>.from(
        List<String>.from(data['modifiers'] as List? ?? const []));
    _gamepadButton = data['button']?.toString() ?? 'a';
    _mouseButton = data['button']?.toString() ?? 'left';
  }

  @override
  void dispose() {
    _holdTimer?.cancel();
    super.dispose();
  }

  void _startHold(int direction) {
    _holdTimer?.cancel();
    _holdTicks = 0;
    setState(() {
      _atMs = (_atMs + direction * 10).clamp(0, 999999).toInt();
    });
    _holdTimer = Timer.periodic(const Duration(milliseconds: 80), (_) {
      _holdTicks++;
      final step = _holdTicks < 10
          ? 10
          : _holdTicks < 25
              ? 50
              : _holdTicks < 50
                  ? 100
                  : 200;
      setState(() {
        _atMs = (_atMs + direction * step).clamp(0, 999999).toInt();
      });
    });
  }

  void _stopHold() {
    _holdTimer?.cancel();
    _holdTimer = null;
  }

  void _save() {
    final type = _type;
    final atMs = _atMs.clamp(0, 999999).toInt();

    final data = <String, dynamic>{};
    switch (type) {
      case 'delay':
        break;
      case 'keyboard':
        data['key'] = _keyboardKey.trim().isEmpty ? 'A' : _keyboardKey.trim();
        data['isDown'] = _pair ? true : _isDown;
        if (_modifiers.isNotEmpty) {
          data['modifiers'] = _modifiers.toList(growable: false);
        }
        break;
      case 'mouse_button':
        data['button'] = _mouseButton;
        data['isDown'] = _pair ? true : _isDown;
        break;
      case 'gamepad_button':
        data['button'] = _gamepadButton.trim().isEmpty ? 'a' : _gamepadButton;
        data['isDown'] = _pair ? true : _isDown;
        break;
      default:
        return;
    }

    final first = RecordedTimelineEvent(atMs: atMs, type: type, data: data);
    if (!_pair || type == 'delay') {
      widget.onSave([first]);
      return;
    }

    final upAtMs = (atMs + _pairDelayMs).clamp(0, 999999).toInt();
    final upData = <String, dynamic>{...data, 'isDown': false};
    final second =
        RecordedTimelineEvent(atMs: upAtMs, type: type, data: upData);
    widget.onSave([first, second]);
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _titleForType(_type),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  GestureDetector(
                    onTap: () =>
                        setState(() => _atMs = (_atMs - 10).clamp(0, 999999)),
                    onLongPressStart: (_) => _startHold(-1),
                    onLongPressEnd: (_) => _stopHold(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10)),
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
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08)),
                      ),
                      child: Text(
                        '${_atMs}ms',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _atMs = (_atMs + 10).clamp(0, 999999)),
                    onLongPressStart: (_) => _startHold(1),
                    onLongPressEnd: (_) => _stopHold(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10)),
                      ),
                      child: const Icon(Icons.add, color: Colors.white70),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_type != 'delay') ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween
                  ,
                  children: [
                    if (!_pair)
                      SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(value: true, label: Text('Down')),
                          ButtonSegment(value: false, label: Text('Up')),
                        ],
                        selected: {_isDown},
                        onSelectionChanged: (v) =>
                            setState(() => _isDown = v.first),
                        showSelectedIcon: false,
                      ),
                    FilterChip(
                      label: const Text('Down+Up'),
                      selected: _pair,
                      onSelected: (v) => setState(() {
                        _pair = v;
                        if (_pair) _isDown = true;
                      }),
                      showCheckmark: false,
                    ),
                    if (_pair)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: () => setState(() {
                              _pairDelayMs =
                                  (_pairDelayMs - 10).clamp(0, 999999).toInt();
                            }),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: const Icon(Icons.remove,
                                  color: Colors.white70, size: 18),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            height: 34,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                            ),
                            child: Text(
                              '${_pairDelayMs}ms',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() {
                              _pairDelayMs =
                                  (_pairDelayMs + 10).clamp(0, 999999).toInt();
                            }),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.10),
                                ),
                              ),
                              child: const Icon(Icons.add,
                                  color: Colors.white70, size: 18),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
              if (_type == 'keyboard') ...[
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
                const SizedBox(height: 10),
              ],
              if (_type == 'mouse_button') ...[
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
                const SizedBox(height: 10),
              ],
              if (_type == 'gamepad_button') ...[
                _dropdown(
                  label: 'Button',
                  value: _gamepadButton,
                  options: _withCurrentFirst(
                    _gamepadButton,
                    GamepadButtonId.builtIns.map((e) => e.code).toList(),
                  ),
                  onChanged: (v) => setState(() => _gamepadButton = v),
                ),
                const SizedBox(height: 10),
              ],
              Row(
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
            ],
          ),
        ),
      ),
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
