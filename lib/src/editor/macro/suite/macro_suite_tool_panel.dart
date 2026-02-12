part of '../macro_suite_page.dart';

class _TopBubble extends StatelessWidget {
  const _TopBubble({
    required this.labelController,
    required this.view,
    required this.onViewChanged,
    required this.selectedSegment,
    required this.onDeleteSelectedSegment,
    required this.onAdjustAxisWindowSpan,
    required this.canFinish,
    required this.onFinish,
  });

  final TextEditingController labelController;
  final _MacroSuiteView view;
  final ValueChanged<_MacroSuiteView> onViewChanged;
  final _SelectedSegment? selectedSegment;
  final VoidCallback? onDeleteSelectedSegment;
  final ValueChanged<int> onAdjustAxisWindowSpan;
  final bool canFinish;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) {
    final selected = selectedSegment;
    final isPreview = view == _MacroSuiteView.preview;
    final isAxisWindow = isPreview &&
        selected != null &&
        (selected.type == 'joystick' || selected.type == 'gamepad_axis') &&
        selected.entryIds.isEmpty;

    String fmt(int ms) {
      if (ms < 1000) return '${ms}ms';
      final s = ms / 1000.0;
      final str = s.toStringAsFixed(s >= 10 ? 0 : 1);
      return '${str}s';
    }

    final axisSpanMs =
        isAxisWindow ? (selected.endMs - selected.startMs).abs() : 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        SizedBox(
          width: 160,
          child: TextField(
            controller: labelController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: '按键名称',
              labelText: '宏名称',
              hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.35)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.06),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        _ViewTabs(value: view, onChanged: onViewChanged),
        if (isAxisWindow)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '宽度 ${fmt(axisSpanMs)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: () => onAdjustAxisWindowSpan(-100),
                  icon: const Icon(Icons.remove, color: Colors.white70, size: 14),
                  visualDensity: VisualDensity.compact,
                  tooltip: '缩小选区',
                ),
                IconButton(
                  onPressed: () => onAdjustAxisWindowSpan(100),
                  icon: const Icon(Icons.add, color: Colors.white70, size: 14),
                  visualDensity: VisualDensity.compact,
                  tooltip: '扩大选区',
                ),
              ],
            ),
          ),
        if (isPreview && selected != null) ...[
          IconButton(
            onPressed: onDeleteSelectedSegment,
            icon: const Icon(Icons.delete_outline, color: Colors.white70),
            visualDensity: VisualDensity.compact,
            tooltip: '删除时间条',
          ),
        ],
        FilledButton(
          onPressed: canFinish ? onFinish : null,
          child: const Text('添加到布局'),
        ),
      ],
    );
  }
}

class _ViewTabs extends StatelessWidget {
  const _ViewTabs({required this.value, required this.onChanged});

  final _MacroSuiteView value;
  final ValueChanged<_MacroSuiteView> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget tab(String label, _MacroSuiteView v) {
      final selected = value == v;
      return InkWell(
        onTap: () => onChanged(v),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.20)
                  : Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected
                  ? Colors.white.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.55),
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        tab('元数据', _MacroSuiteView.defaultView),
        const SizedBox(width: 8),
        tab('时间轨道', _MacroSuiteView.preview),
      ],
    );
  }
}

class _ToolPanel extends StatelessWidget {
  const _ToolPanel({
    required this.collapsed,
    required this.onToggleCollapsed,
    required this.onRecordAppend,
    required this.onRecordReplace,
    required this.onAddKeyboard,
    required this.onAddMouse,
    required this.onAddGamepad,
    required this.onAddDelay,
    required this.onAutoCompleteUps,
    required this.onClear,
  });

  final bool collapsed;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onRecordAppend;
  final VoidCallback onRecordReplace;
  final VoidCallback onAddKeyboard;
  final VoidCallback onAddMouse;
  final VoidCallback onAddGamepad;
  final VoidCallback onAddDelay;
  final VoidCallback? onAutoCompleteUps;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final toggleIcon = collapsed ? Icons.chevron_right : Icons.chevron_left;
    final toggleTooltip = collapsed ? '展开' : '折叠';
    return Container(
      color: const Color(0xFF0B0B0C),
      padding:
          EdgeInsets.only(left: MediaQuery.paddingOf(context).left, top: 10),
      child: Column(
        children: [
          if (collapsed)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
                IconButton(
                  onPressed: onToggleCollapsed,
                  tooltip: toggleTooltip,
                  icon: Icon(toggleIcon, color: Colors.white70),
                ),
              ],
            )
          else
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
                Text(
                  '宏编辑器',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: onToggleCollapsed,
                  tooltip: toggleTooltip,
                  icon: Icon(toggleIcon, color: Colors.white70),
                ),
              ],
            ),
          Expanded(
            child: ListView(
              shrinkWrap: true,
              padding: EdgeInsets.fromLTRB(collapsed ? 8 : 12, 12, 12, 12),
              children: collapsed
                  ? [
                      const SizedBox(height: 4),
                      _ToolIconTile(
                        icon: Icons.fiber_manual_record,
                        tooltip: '录制追加',
                        onTap: onRecordAppend,
                        iconColor: const Color(0xFFE74C3C),
                      ),
                      _ToolIconTile(
                        icon: Icons.refresh,
                        tooltip: '录制覆盖',
                        onTap: onRecordReplace,
                      ),
                      const SizedBox(height: 10),
                      _ToolIconTile(
                        icon: Icons.keyboard,
                        tooltip: '键盘',
                        onTap: onAddKeyboard,
                      ),
                      _ToolIconTile(
                        icon: Icons.mouse,
                        tooltip: '鼠标按钮',
                        onTap: onAddMouse,
                      ),
                      _ToolIconTile(
                        icon: Icons.sports_esports,
                        tooltip: '手柄按钮',
                        onTap: onAddGamepad,
                      ),
                      _ToolIconTile(
                        icon: Icons.timer_outlined,
                        tooltip: '延时',
                        onTap: onAddDelay,
                      ),
                      const SizedBox(height: 10),
                      _ToolIconTile(
                        icon: Icons.auto_fix_high,
                        tooltip: '补全 Up',
                        onTap: onAutoCompleteUps,
                      ),
                      _ToolIconTile(
                        icon: Icons.delete_outline,
                        tooltip: '清空序列',
                        onTap: onClear,
                      ),
                    ]
                  : [
                      const SizedBox(height: 12),
                      Text(
                        '录制工具',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                        onPressed: onRecordAppend,
                        icon: const Icon(Icons.fiber_manual_record),
                        label: const Text('录制追加'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: onRecordReplace,
                        icon: const Icon(Icons.refresh),
                        label: const Text('录制覆盖'),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        '手动添加',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ToolTile(
                        icon: Icons.keyboard,
                        title: '键盘',
                        onTap: onAddKeyboard,
                      ),
                      _ToolTile(
                        icon: Icons.mouse,
                        title: '鼠标按钮',
                        onTap: onAddMouse,
                      ),
                      _ToolTile(
                        icon: Icons.sports_esports,
                        title: '手柄按钮',
                        onTap: onAddGamepad,
                      ),
                      _ToolTile(
                        icon: Icons.timer_outlined,
                        title: '延时',
                        onTap: onAddDelay,
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: onAutoCompleteUps,
                        icon: const Icon(Icons.auto_fix_high),
                        label: const Text('补全 Up'),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: onClear,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('清空序列'),
                      ),
                    ],
            ),
          )
        ],
      ),
    );
  }
}

class _ToolTile extends StatelessWidget {
  const _ToolTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: Colors.white70, size: 18),
              Text(title, style: const TextStyle(color: Colors.white,fontSize: 14)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToolIconTile extends StatelessWidget {
  const _ToolIconTile({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.iconColor,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final resolvedIconColor = enabled
        ? (iconColor ?? Colors.white70)
        : Colors.white.withValues(alpha: 0.25);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Container(
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color:
                  enabled ? const Color(0xFF1C1C1E) : const Color(0xFF141416),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(icon, color: resolvedIconColor, size: 20),
          ),
        ),
      ),
    );
  }
}
