import 'package:flutter/material.dart';
import '../models/virtual_controller_models.dart';
import 'editor_palette_tab.dart';
import 'virtual_controller_layout_editor_canvas.dart';
import 'virtual_controller_layout_editor_controller.dart';
import 'virtual_controller_layout_editor_palette.dart';

/// A full-screen editor widget for creating and modifying virtual controller layouts.
///
/// This widget provides a complete UI for:
/// * Visualizing the layout on a canvas.
/// * Adding controls from a palette.
/// * Moving and resizing controls via touch/drag.
/// * Editing control properties (via double-tap).
/// * Renaming the layout.
/// * Saving and loading layouts via provided callbacks.
///
/// The editor is storage-agnostic. You must provide [load] and [save] callbacks
/// to handle the persistence of [VirtualControllerLayout] objects (e.g., to SharedPreferences,
/// local file system, or a remote server).
class VirtualControllerLayoutEditor extends StatefulWidget {
  /// Creates an editor instance.
  ///
  /// [layoutId] is the unique identifier for the layout to be edited.
  /// The editor loads a **definition** (code-driven) and a **state** (user-edited).
  const VirtualControllerLayoutEditor({
    super.key,
    required this.layoutId,
    required this.loadDefinition,
    required this.loadState,
    required this.saveState,
    this.previewDecorator,
    this.onClose,
    this.readOnly = false,
    this.allowAddRemove = false,
    this.allowResize = true,
    this.allowMove = true,
    this.enabledPaletteTabs = const {
      VirtualControllerEditorPaletteTab.keyboard,
      VirtualControllerEditorPaletteTab.mouseAndJoystick,
      VirtualControllerEditorPaletteTab.xbox,
      VirtualControllerEditorPaletteTab.ps,
    },
    this.initialPaletteTab = VirtualControllerEditorPaletteTab.keyboard,
  });

  /// The ID of the layout to edit. Passed to [load] and [save].
  final String layoutId;

  /// Callback to load the definition (control types, bindings, styles...).
  final Future<VirtualControllerLayout> Function(String layoutId)
      loadDefinition;

  /// Callback to load the editable state (position/size/opacity).
  final Future<VirtualControllerState> Function(String layoutId) loadState;

  /// Callback to save the editable state (position/size/opacity).
  final Future<void> Function(String layoutId, VirtualControllerState state)
      saveState;

  /// Optional decorator to modify the layout before previewing in the palette.
  /// Useful for applying global themes to palette items.
  final VirtualControllerLayout Function(VirtualControllerLayout layout)?
      previewDecorator;

  /// Called when the user taps the close button.
  final VoidCallback? onClose;

  /// If true, the editor is in read-only mode (viewing only).
  final bool readOnly;

  /// Whether adding/removing controls is allowed.
  final bool allowAddRemove;

  /// Whether resizing controls is allowed.
  final bool allowResize;

  /// Whether moving controls is allowed.
  final bool allowMove;

  /// The set of tabs to show in the control palette.
  final Set<VirtualControllerEditorPaletteTab> enabledPaletteTabs;

  /// The initially selected tab in the palette.
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

  Size _lastCanvasSize = Size.zero;
  bool _dockCollapsed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final definition = await widget.loadDefinition(widget.layoutId);
      final state = await widget.loadState(widget.layoutId);
      _controller?.dispose();
      final c = VirtualControllerLayoutEditorController(
        definition: definition,
        state: state,
        readOnly: widget.readOnly,
        allowAddRemove: widget.allowAddRemove,
        allowResize: widget.allowResize,
        allowMove: widget.allowMove,
      );
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
      await widget.saveState(widget.layoutId, c.state);
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
        maxHeight: MediaQuery.of(context).size.height * 0.65,
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
                                    onReset: _confirmReset,
                                    onSizeChanged: (v) =>
                                        c.setSelectedScale(v, _lastCanvasSize),
                                    onOpacityChanged: c.setSelectedOpacity,
                                    collapsed: _dockCollapsed,
                                  ),
                                ),
                              ),
                            ),
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
    required this.enabledTabs,
    required this.hasSelection,
    required this.canSave,
    required this.sizeValue,
    required this.opacityValue,
    required this.onClose,
    required this.onSave,
    required this.onToggleCollapsed,
    required this.onDeselect,
    required this.onOpenKeyboard,
    required this.onOpenMouse,
    required this.onOpenXbox,
    required this.onOpenPs,
    required this.onReset,
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
  final bool canSave;
  final double sizeValue;
  final double opacityValue;

  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onDeselect;
  final VoidCallback onOpenKeyboard;
  final VoidCallback onOpenMouse;
  final VoidCallback onOpenXbox;
  final VoidCallback onOpenPs;
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
      constraints: BoxConstraints(maxWidth: hasSelection ? 380 : 280),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E).withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 5, 5),
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
                  IconButton(
                    onPressed: canSave ? onSave : null,
                    icon: Icon(Icons.save,
                        color: canSave ? Colors.white : Colors.white24,
                        size: 18),
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
