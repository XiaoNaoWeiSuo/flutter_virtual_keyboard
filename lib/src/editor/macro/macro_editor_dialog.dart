import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/action/control_action.dart';

part 'dialog/macro_editor_key_capture.dart';
part 'dialog/macro_editor_step_tile.dart';
part 'dialog/macro_editor_widgets.dart';

class MacroEditorDialog extends StatefulWidget {
  const MacroEditorDialog({
    super.key,
    required this.initialSequence,
  });

  final List<MacroSequenceItem> initialSequence;

  @override
  State<MacroEditorDialog> createState() => _MacroEditorDialogState();
}

class _MacroEditorDialogState extends State<MacroEditorDialog> {
  late List<MacroSequenceItem> _sequence;
  bool _isRecording = false;
  DateTime? _lastRecordedAt;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _sequence = List.from(widget.initialSequence);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _scrollController.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (!_isRecording) return false;

    final keyCode = _toKeyCode(event.logicalKey);
    if (keyCode == null) return false;

    final now = DateTime.now();
    final last = _lastRecordedAt;
    final delayMs = (last == null) ? 0 : now.difference(last).inMilliseconds;
    _lastRecordedAt = now;

    final modifiers = _currentModifierCodes(excluding: event.logicalKey);

    if (event is KeyDownEvent) {
      _addStep(MacroSequenceItem(
        type: 'key_down',
        key: keyCode,
        modifiers: modifiers,
        delay: delayMs.clamp(0, 999999),
      ));
    } else if (event is KeyUpEvent) {
      _addStep(MacroSequenceItem(
        type: 'key_up',
        key: keyCode,
        modifiers: modifiers,
        delay: delayMs.clamp(0, 999999),
      ));
    }
    return true;
  }

  void _addStep(MacroSequenceItem item) {
    setState(() {
      _sequence.add(item);
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _updateStep(int index, MacroSequenceItem item) {
    setState(() {
      _sequence[index] = item;
    });
  }

  void _removeStep(int index) {
    setState(() {
      _sequence.removeAt(index);
    });
  }

  void _reorderStep(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final item = _sequence.removeAt(oldIndex);
      _sequence.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Column(
          children: [
            // _buildHeader(),
            Expanded(
              child: _sequence.isEmpty
                  ? _buildEmptyState()
                  : ReorderableListView.builder(
                      scrollController: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: _sequence.length,
                      itemBuilder: (context, index) {
                        final item = _sequence[index];
                        return _MacroStepTile(
                          key: ValueKey('${index}_${item.hashCode}'),
                          item: item,
                          onDelete: () => _removeStep(index),
                          onUpdate: (newItem) => _updateStep(index, newItem),
                        );
                      },
                      onReorder: _reorderStep,
                    ),
            ),
            _buildToolbar(),
          ],
        ),
      ),
    );
  }


  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.movie_creation_outlined,
              size: 64, color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(height: 16),
          Text(
            '暂无指令',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
          const SizedBox(height: 8),
          Text(
            '点击录制或手动添加指令',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      child: Row(
        children: [
          _RecordButton(
            isRecording: _isRecording,
            onToggle: () {
              setState(() {
                _isRecording = !_isRecording;
                _lastRecordedAt = _isRecording ? DateTime.now() : null;
              });
            },
          ),
          const SizedBox(width: 12),
          PopupMenuButton<String>(
            icon: const Icon(Icons.add, color: Colors.lightBlueAccent),
            tooltip: '添加指令',
            color: const Color(0xFF2C2C2E),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'key_down', child: Text('按下按键', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'key_up', child: Text('抬起按键', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'delay', child: Text('延时', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'mouse_down', child: Text('鼠标按下', style: TextStyle(color: Colors.white))),
              const PopupMenuItem(value: 'mouse_up', child: Text('鼠标抬起', style: TextStyle(color: Colors.white))),
            ],
            onSelected: (value) {
              if (value == 'delay') {
                _addStep(const MacroSequenceItem(type: 'delay', delay: 100));
              } else if (value.startsWith('mouse')) {
                _addStep(MacroSequenceItem(type: value, button: 'left'));
              } else {
                _addStep(MacroSequenceItem(type: value, key: 'A'));
              }
            },
          ),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消', style: TextStyle(color: Colors.white60)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(_sequence),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlueAccent,
              foregroundColor: Colors.black,
            ),
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }
}
