import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class LayoutToolbar extends StatelessWidget {
  const LayoutToolbar({
    super.key,
    required this.isEditing,
    required this.onToggleEdit,
    required this.selectedPreset,
    required this.presets,
    required this.onPresetChanged,
    required this.width,
    required this.height,
    required this.onWidthChanged,
    required this.onHeightChanged,
    required this.onToggleSidebar,
    required this.isSidebarOpen,
  });

  final bool isEditing;
  final VoidCallback onToggleEdit;
  final String selectedPreset;
  final List<String> presets;
  final ValueChanged<String?> onPresetChanged;
  final double width;
  final double height;
  final ValueChanged<double> onWidthChanged;
  final ValueChanged<double> onHeightChanged;

  final VoidCallback onToggleSidebar;
  final bool isSidebarOpen;

  @override
  Widget build(BuildContext context) {
    final borderColor = Colors.grey.withValues(alpha: 0.2);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onToggleSidebar,
            icon: Icon(
              isSidebarOpen ? Icons.menu_open : Icons.menu,
              color: Colors.black87,
              size: 20,
            ),
            tooltip: isSidebarOpen ? '收起侧边栏' : '展开侧边栏',
            style: IconButton.styleFrom(
              visualDensity: VisualDensity.compact,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _PresetSelector(
                    selectedPreset: selectedPreset,
                    presets: presets,
                    onPresetChanged: onPresetChanged,
                  ),
                  const SizedBox(width: 24),
                  Container(
                    height: 20,
                    width: 1,
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 24),
                  _DimensionInput(
                    label: '宽',
                    value: width,
                    onChanged: onWidthChanged,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      '×',
                      style: TextStyle(
                        color: Colors.grey.withValues(alpha: 0.4),
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                  _DimensionInput(
                    label: '高',
                    value: height,
                    onChanged: onHeightChanged,
                  ),
                  const SizedBox(width: 24),
                  Container(
                    height: 20,
                    width: 1,
                    color: Colors.grey.withValues(alpha: 0.15),
                  ),
                  const SizedBox(width: 24),
                  CupertinoSlidingSegmentedControl<bool>(
                    groupValue: isEditing,
                    children: const {
                      false: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('预览', style: TextStyle(fontSize: 13)),
                      ),
                      true: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('编辑', style: TextStyle(fontSize: 13)),
                      ),
                    },
                    onValueChanged: (v) {
                      if (v != null) onToggleEdit();
                    },
                    thumbColor: Colors.white,
                    backgroundColor: const Color(0xFFF2F2F7),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PresetSelector extends StatelessWidget {
  const _PresetSelector({
    required this.selectedPreset,
    required this.presets,
    required this.onPresetChanged,
  });

  final String selectedPreset;
  final List<String> presets;
  final ValueChanged<String?> onPresetChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedPreset,
          icon: const Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 16,
            color: Colors.black54,
          ),
          style: const TextStyle(
            fontSize: 13,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          isDense: true,
          menuMaxHeight: 400,
          borderRadius: BorderRadius.circular(12),
          items: presets
              .map(
                (e) => DropdownMenuItem(
                  value: e,
                  child: Text(e),
                ),
              )
              .toList(),
          onChanged: onPresetChanged,
        ),
      ),
    );
  }
}

class _DimensionInput extends StatefulWidget {
  const _DimensionInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_DimensionInput> createState() => _DimensionInputState();
}

class _DimensionInputState extends State<_DimensionInput> {
  late TextEditingController _ctrl;
  final FocusNode _focusNode = FocusNode();
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toStringAsFixed(0));
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
      if (!_focusNode.hasFocus) {
        final d = double.tryParse(_ctrl.text);
        if (d != null) {
          widget.onChanged(d);
        } else {
          _ctrl.text = widget.value.toStringAsFixed(0);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant _DimensionInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value && !_focusNode.hasFocus) {
      _ctrl.text = widget.value.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: TextStyle(
            color: Colors.grey.withValues(alpha: 0.6),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 56,
          height: 32,
          decoration: BoxDecoration(
            color: _isFocused ? Colors.white : const Color(0xFFF2F2F7),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: _isFocused ? Colors.blue : Colors.transparent,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: TextField(
            controller: _ctrl,
            focusNode: _focusNode,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onSubmitted: (v) {
              final d = double.tryParse(v);
              if (d != null) widget.onChanged(d);
            },
          ),
        ),
      ],
    );
  }
}
