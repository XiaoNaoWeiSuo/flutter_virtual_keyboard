import 'package:flutter/material.dart';
import '../models/virtual_controller_models.dart';
import 'editor_palette_tab.dart';
import 'virtual_controller_layout_editor_canvas.dart';
import 'virtual_controller_layout_editor_controller.dart';
import 'virtual_controller_layout_editor_palette.dart';

class VirtualControllerLayoutEditor extends StatefulWidget {
  const VirtualControllerLayoutEditor({
    super.key,
    required this.layoutId,
    required this.load,
    required this.save,
    this.previewDecorator,
    this.onClose,
    this.readOnly = false,
    this.allowAddRemove = true,
    this.allowResize = true,
    this.allowMove = true,
    this.allowRename = true,
    this.enabledPaletteTabs = const {
      VirtualControllerEditorPaletteTab.keyboard,
      VirtualControllerEditorPaletteTab.mouseAndJoystick,
      VirtualControllerEditorPaletteTab.xbox,
      VirtualControllerEditorPaletteTab.ps,
    },
    this.initialPaletteTab = VirtualControllerEditorPaletteTab.keyboard,
  });

  final String layoutId;
  final Future<VirtualControllerLayout> Function(String layoutId) load;
  final Future<void> Function(String layoutId, VirtualControllerLayout layout)
      save;
  final VirtualControllerLayout Function(VirtualControllerLayout layout)?
      previewDecorator;
  final VoidCallback? onClose;

  final bool readOnly;
  final bool allowAddRemove;
  final bool allowResize;
  final bool allowMove;
  final bool allowRename;
  final Set<VirtualControllerEditorPaletteTab> enabledPaletteTabs;
  final VirtualControllerEditorPaletteTab initialPaletteTab;

  @override
  State<VirtualControllerLayoutEditor> createState() =>
      _VirtualControllerLayoutEditorState();
}

class _VirtualControllerLayoutEditorState
    extends State<VirtualControllerLayoutEditor> {
  VirtualControllerLayoutEditorController? _controller;
  bool _loading = true;
  String? _error;

  final _nameController = TextEditingController();
  final _renameFocusNode = FocusNode();
  Size _lastCanvasSize = Size.zero;
  bool _renaming = false;
  bool _dockCollapsed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _nameController.dispose();
    _renameFocusNode.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final layout = await widget.load(widget.layoutId);
      _controller?.dispose();
      final c = VirtualControllerLayoutEditorController(
        layout: layout,
        readOnly: widget.readOnly,
        allowAddRemove: widget.allowAddRemove,
        allowResize: widget.allowResize,
        allowMove: widget.allowMove,
        allowRename: widget.allowRename,
      );
      _nameController.text = layout.name;
      setState(() {
        _controller = c;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final c = _controller;
    if (c == null) return;
    try {
      await widget.save(widget.layoutId, c.layout);
      c.markSaved();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('已保存')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('保存失败: $e')),
      );
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重置更改'),
        content: const Text('放弃未保存的更改并重新加载？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('重置'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _load();
    }
  }

  Future<void> _openPaletteFor(VirtualControllerEditorPaletteTab tab) async {
    final c = _controller;
    if (c == null) return;
    if (widget.readOnly || !widget.allowAddRemove) return;
    if (!widget.enabledPaletteTabs.contains(tab)) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.55,
      ),
      builder: (context) {
        return VirtualControllerLayoutEditorPalette(
          tab: tab,
          previewDecorator: widget.previewDecorator,
          onAddControl: (control) {
            c.addControl(control);
            Navigator.of(context).pop();
          },
        );
      },
    );
  }

  void _beginRename() {
    final c = _controller;
    if (c == null) return;
    if (widget.readOnly || !widget.allowRename) return;
    _nameController.text = c.layout.name;
    setState(() => _renaming = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      FocusScope.of(context).requestFocus(_renameFocusNode);
    });
  }

  void _cancelRename() {
    if (!_renaming) return;
    FocusScope.of(context).unfocus();
    setState(() => _renaming = false);
  }

  void _commitRename() {
    final c = _controller;
    if (c == null) return;
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      c.renameLayout(name);
    }
    _cancelRename();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.white70),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _load,
                          child: const Text('重试'),
                        ),
                      ],
                    ),
                  ),
                )
              : c == null
                  ? const SizedBox.shrink()
                  : AnimatedBuilder(
                      animation: c,
                      builder: (context, _) {
                        final raw = c.layout;
                        final decorated =
                            widget.previewDecorator?.call(raw) ?? raw;

                        return Stack(
                          children: [
                            Positioned.fill(
                              child: LayoutBuilder(
                                builder: (context, constraints) {
                                  _lastCanvasSize = Size(
                                    constraints.maxWidth,
                                    constraints.maxHeight,
                                  );
                                  return VirtualControllerLayoutEditorCanvas(
                                    layout: decorated,
                                    selectedControlId: c.selectedControl?.id,
                                    onSelectControl: c.selectControl,
                                    onMoveControlBy: c.moveControlBy,
                                    onResizeControlBy: c.resizeControlBy,
                                    showGrid: true,
                                    showResizeHandles: false,
                                    showSelectionOverlay: true,
                                    onBackgroundTap: () {},
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: 0,
                              left: 0,
                              child: SafeArea(
                                bottom: false,
                                child: Padding(
                                  padding: const EdgeInsets.all(10),
                                  child: _DockPanel(
                                    title: c.layout.name,
                                    readOnly: widget.readOnly,
                                    allowAddRemove: widget.allowAddRemove,
                                    allowResize: widget.allowResize,
                                    allowRename: widget.allowRename,
                                    enabledTabs: widget.enabledPaletteTabs,
                                    hasSelection: c.selectedControl != null,
                                    canSave: c.isDirty && !widget.readOnly,
                                    sizeValue: c.selectedScale,
                                    opacityValue: c.selectedOpacity,
                                    onClose: () {
                                      widget.onClose?.call();
                                      Navigator.of(context).maybePop();
                                    },
                                    onSave: _save,
                                    onToggleCollapsed: () => setState(
                                      () => _dockCollapsed = !_dockCollapsed,
                                    ),
                                    onBeginRename: _beginRename,
                                    onDeselect: () => c.selectControl(null),
                                    onOpenKeyboard: () => _openPaletteFor(
                                        VirtualControllerEditorPaletteTab
                                            .keyboard),
                                    onOpenMouse: () => _openPaletteFor(
                                        VirtualControllerEditorPaletteTab
                                            .mouseAndJoystick),
                                    onOpenXbox: () => _openPaletteFor(
                                        VirtualControllerEditorPaletteTab.xbox),
                                    onOpenPs: () => _openPaletteFor(
                                        VirtualControllerEditorPaletteTab.ps),
                                    onDelete: c.deleteSelected,
                                    onReset: _confirmReset,
                                    onSizeChanged: (v) =>
                                        c.setSelectedScale(v, _lastCanvasSize),
                                    onOpacityChanged: c.setSelectedOpacity,
                                    collapsed: _dockCollapsed,
                                  ),
                                ),
                              ),
                            ),
                            if (_renaming) ...[
                              Positioned.fill(
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTap: _cancelRename,
                                  child: const SizedBox.expand(),
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: AnimatedPadding(
                                  duration: const Duration(milliseconds: 160),
                                  curve: Curves.easeOut,
                                  padding: EdgeInsets.only(
                                    bottom: MediaQuery.of(context)
                                        .viewInsets
                                        .bottom,
                                  ),
                                  child: SafeArea(
                                    top: false,
                                    child: _RenameBar(
                                      controller: _nameController,
                                      focusNode: _renameFocusNode,
                                      onCancel: _cancelRename,
                                      onSubmit: _commitRename,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
    );
  }
}

class _DockPanel extends StatelessWidget {
  const _DockPanel({
    required this.title,
    required this.readOnly,
    required this.allowAddRemove,
    required this.allowResize,
    required this.allowRename,
    required this.enabledTabs,
    required this.hasSelection,
    required this.canSave,
    required this.sizeValue,
    required this.opacityValue,
    required this.onClose,
    required this.onSave,
    required this.onToggleCollapsed,
    required this.onBeginRename,
    required this.onDeselect,
    required this.onOpenKeyboard,
    required this.onOpenMouse,
    required this.onOpenXbox,
    required this.onOpenPs,
    required this.onDelete,
    required this.onReset,
    required this.onSizeChanged,
    required this.onOpacityChanged,
    required this.collapsed,
  });

  final String title;
  final bool readOnly;
  final bool allowAddRemove;
  final bool allowResize;
  final bool allowRename;
  final Set<VirtualControllerEditorPaletteTab> enabledTabs;
  final bool hasSelection;
  final bool canSave;
  final double sizeValue;
  final double opacityValue;

  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onBeginRename;
  final VoidCallback onDeselect;
  final VoidCallback onOpenKeyboard;
  final VoidCallback onOpenMouse;
  final VoidCallback onOpenXbox;
  final VoidCallback onOpenPs;
  final VoidCallback onDelete;
  final VoidCallback onReset;
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
      constraints: const BoxConstraints(maxWidth: 340),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: onClose,
                    icon:
                        const Icon(Icons.close, color: Colors.white, size: 18),
                    tooltip: '关闭',
                  ),
                  IconButton(
                    onPressed: onToggleCollapsed,
                    icon: const Icon(Icons.chevron_left,
                        color: Colors.white70, size: 18),
                    tooltip: '折叠',
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: (!readOnly && allowRename) ? onBeginRename : null,
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ),
                  if (hasSelection)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        '大${sizeValue.toStringAsFixed(1)}  透${opacityValue.toStringAsFixed(1)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: canSave ? onSave : null,
                    icon: Icon(Icons.save,
                        color: canSave ? Colors.white : Colors.white24,
                        size: 18),
                    tooltip: '保存',
                  ),
                ],
              ),
              if (hasSelection) ...[
                if (!readOnly && allowResize) ...[
                  const SizedBox(height: 4),
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
                ],
                const SizedBox(height: 2),
                Row(
                  children: [
                    IconButton(
                      onPressed: onDeselect,
                      icon: const Icon(Icons.check_circle_outline,
                          color: Colors.white70, size: 18),
                      tooltip: '完成',
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: !readOnly ? onDelete : null,
                      icon: Icon(Icons.delete,
                          color: !readOnly ? Colors.redAccent : Colors.white24,
                          size: 18),
                      tooltip: '删除',
                    ),
                    IconButton(
                      onPressed: onReset,
                      icon: const Icon(Icons.restore,
                          color: Colors.white70, size: 18),
                      tooltip: '重置',
                    ),
                  ],
                ),
              ] else if (!readOnly && allowAddRemove) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
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
              ],
            ],
          ),
        ),
      ),
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
                    right: 2,
                    top: 2,
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
    return SizedBox(
      height: 30,
      width: 240,
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

class _RenameBar extends StatelessWidget {
  const _RenameBar({
    required this.controller,
    required this.focusNode,
    required this.onCancel,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onCancel;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1C1C1E).withValues(alpha: 0.96),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: '方案名称',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => onSubmit(),
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onCancel,
              child: const Text('取消'),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
              onPressed: onSubmit,
              child: const Text('确定'),
            ),
          ],
        ),
      ),
    );
  }
}
