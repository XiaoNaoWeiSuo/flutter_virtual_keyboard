part of '../virtual_controller_layout_editor.dart';

class _DockPanel extends StatelessWidget {
  const _DockPanel({
    required this.title,
    required this.readOnly,
    required this.allowAddRemove,
    required this.allowResize,
    required this.enabledTabs,
    required this.hasSelection,
    required this.isMacro,
    required this.showStickClickToggle,
    required this.stickClickLabel,
    required this.stickClickEnabled,
    required this.onStickClickChanged,
    required this.showStickLockToggle,
    required this.stickLockLabel,
    required this.stickLockEnabled,
    required this.onStickLockChanged,
    required this.showDpad3dToggle,
    required this.dpad3dEnabled,
    required this.onDpad3dChanged,
    required this.canRemove,
    required this.canSave,
    required this.canRename,
    required this.sizeValue,
    required this.opacityValue,
    required this.onRename,
    required this.onEditMacro,
    required this.onClose,
    required this.onSave,
    required this.onToggleCollapsed,
    required this.onDeselect,
    required this.onOpenKeyboard,
    required this.onOpenMouse,
    required this.onOpenMacro,
    required this.onOpenXbox,
    required this.onOpenPs,
    required this.onReset,
    required this.onRemove,
    required this.onSizeChanged,
    required this.onOpacityChanged,
    required this.collapsed,
  });

  final String title;
  final bool readOnly;
  final bool allowAddRemove;
  final bool allowResize;
  final Set<VirtualControllerEditorPaletteTab> enabledTabs;
  final bool hasSelection;
  final bool isMacro;
  final bool showStickClickToggle;
  final String stickClickLabel;
  final bool stickClickEnabled;
  final ValueChanged<bool> onStickClickChanged;
  final bool showStickLockToggle;
  final String stickLockLabel;
  final bool stickLockEnabled;
  final ValueChanged<bool> onStickLockChanged;
  final bool showDpad3dToggle;
  final bool dpad3dEnabled;
  final ValueChanged<bool> onDpad3dChanged;
  final bool canRemove;
  final bool canSave;
  final bool canRename;
  final double sizeValue;
  final double opacityValue;

  final VoidCallback onRename;
  final VoidCallback onEditMacro;
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onDeselect;
  final VoidCallback onOpenKeyboard;
  final VoidCallback onOpenMouse;
  final VoidCallback onOpenMacro;
  final VoidCallback onOpenXbox;
  final VoidCallback onOpenPs;
  final VoidCallback onReset;
  final VoidCallback onRemove;
  final ValueChanged<double> onSizeChanged;
  final ValueChanged<double> onOpacityChanged;
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    if (collapsed) {
      return _DockPill(
        onClose: onClose,
        onExpand: onToggleCollapsed,
        dirty: canSave,
      );
    }
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: hasSelection ? 350 : 335),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  tooltip: '关闭',
                ),
                IconButton(
                  onPressed: onToggleCollapsed,
                  icon: const Icon(Icons.chevron_left,
                      color: Colors.white70, size: 18),
                  tooltip: '折叠',
                ),
                Expanded(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                    child: GestureDetector(
                      onTap: canRename ? onRename : null,
                      child: Text(
                        title,
                        style: TextStyle(
                          color: canRename
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.60),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: canSave ? onSave : null,
                  icon: Icon(Icons.save,
                      color: canSave ? Colors.white : Colors.white24, size: 18),
                  tooltip: '保存',
                ),
                if (hasSelection) ...[
                  IconButton(
                    onPressed: onDeselect,
                    icon: const Icon(Icons.done_outline,
                        color: Colors.lightBlueAccent, size: 18),
                    tooltip: '完成',
                  ),
                  IconButton(
                    onPressed: onReset,
                    icon: const Icon(Icons.restore,
                        color: Colors.amberAccent, size: 18),
                    tooltip: '重置',
                  ),
                  if (allowAddRemove && !readOnly)
                    IconButton(
                      onPressed: () {
                        if (canRemove) {
                          onRemove();
                          return;
                        }
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('默认控件不可删除')),
                        );
                      },
                      icon: Icon(Icons.delete_outline,
                          color: canRemove ? Colors.redAccent : Colors.white24,
                          size: 18),
                      tooltip: canRemove ? '删除' : '默认控件不可删除',
                    ),
                ],
              ],
            ),
            if (hasSelection && !readOnly && allowResize) ...[
              _SmallSlider(
                label: '大小',
                value: sizeValue.clamp(0.5, 3.0),
                min: 0.5,
                max: 3.0,
                onChanged: onSizeChanged,
              ),
              _SmallSlider(
                label: '透明',
                value: opacityValue.clamp(0.05, 1.0),
                min: 0.05,
                max: 1.0,
                onChanged: onOpacityChanged,
              ),
            ] else if (!readOnly && allowAddRemove) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(5, 0, 5, 5),
                child: Row(
                  children: [
                    if (enabledTabs
                        .contains(VirtualControllerEditorPaletteTab.keyboard))
                      _DockAction(
                        icon: Icons.keyboard,
                        label: '键盘',
                        onTap: onOpenKeyboard,
                      ),
                    if (enabledTabs.contains(
                        VirtualControllerEditorPaletteTab.mouseAndJoystick))
                      _DockAction(
                        icon: Icons.mouse,
                        label: '鼠标',
                        onTap: onOpenMouse,
                      ),
                    if (enabledTabs
                        .contains(VirtualControllerEditorPaletteTab.macro))
                      _DockAction(
                        icon: Icons.movie_creation_outlined,
                        label: '宏',
                        onTap: onOpenMacro,
                      ),
                    if (enabledTabs
                        .contains(VirtualControllerEditorPaletteTab.xbox))
                      _DockAction(
                        icon: Icons.sports_esports,
                        label: 'Xbox',
                        onTap: onOpenXbox,
                      ),
                    if (enabledTabs
                        .contains(VirtualControllerEditorPaletteTab.ps))
                      _DockAction(
                        icon: Icons.gamepad,
                        label: 'PS',
                        onTap: onOpenPs,
                      ),
                  ],
                ),
              ),
            ],
            if (hasSelection &&
                !readOnly &&
                (showStickClickToggle || showStickLockToggle))
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Row(
                  children: [
                    if (showStickClickToggle)
                      Expanded(
                        child: _RadioToggle(
                          label: stickClickLabel,
                          value: stickClickEnabled,
                          onChanged: onStickClickChanged,
                        ),
                      ),
                    if (showStickClickToggle && showStickLockToggle)
                      const SizedBox(width: 12),
                    if (showStickLockToggle)
                      Expanded(
                        child: _RadioToggle(
                          label: stickLockLabel,
                          value: stickLockEnabled,
                          onChanged: onStickLockChanged,
                        ),
                      ),
                  ],
                ),
              ),
            if (hasSelection && !readOnly && showDpad3dToggle)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: _RadioToggle(
                  label: '3D模式',
                  value: dpad3dEnabled,
                  onChanged: onDpad3dChanged,
                ),
              ),
            if (hasSelection && !readOnly && isMacro)
              TextButton(
                  onPressed: onEditMacro,
                  child: const Row(
                    
                    children: [
                      Icon(Icons.movie_creation, size: 16, color: Colors.white),
                      SizedBox(width: 4),
                      Text('编辑宏序列',
                          style: TextStyle(fontSize: 12, color: Colors.white)),
                    ],
                  ))
          ],
        ),
      ),
    );
  }
}

class _RadioToggle extends StatelessWidget {
  const _RadioToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    const activeColor = Colors.lightBlueAccent;
    final inactiveColor = Colors.white.withValues(alpha: 0.65);
    final selected = value;

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 16,
              color: selected ? activeColor : inactiveColor,
            ),
          ),
        ),
      ],
    );
  }
}

class _DockPill extends StatelessWidget {
  const _DockPill({
    required this.onClose,
    required this.onExpand,
    required this.dirty,
  });

  final VoidCallback onClose;
  final VoidCallback onExpand;
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: onClose,
                  icon: const Icon(Icons.close, color: Colors.white, size: 18),
                  tooltip: '关闭',
                ),
                if (dirty)
                  Positioned(
                    right: 5,
                    top: 10,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              onPressed: onExpand,
              icon: const Icon(Icons.chevron_right,
                  color: Colors.white, size: 18),
              tooltip: '展开',
            ),
          ],
        ),
      ),
    );
  }
}

class _DockAction extends StatelessWidget {
  const _DockAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              Text(label,
                  style: const TextStyle(color: Colors.white, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallSlider extends StatelessWidget {
  const _SmallSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.only(bottom: 0, left: 18, right: 18),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ),
          Expanded(
            child: Slider(
              value: value,
              min: min,
              max: max,
              activeColor: Colors.white70,
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 36,
            child: Text(
              value.toStringAsFixed(1),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
