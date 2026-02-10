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
    this.allowRename = true,
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

  /// Whether renaming the layout is allowed.
  final bool allowRename;

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
        allowRename: widget.allowRename,
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
    final named = await _ensureLayoutNamed();
    if (!named) return;
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

  bool _isPlaceholderName(String name) {
    final n = name.trim();
    if (n.isEmpty) return true;
    final lower = n.toLowerCase();
    return lower == 'untitled' || lower == 'unnamed' || n == '未命名';
  }

  Future<bool> _ensureLayoutNamed() async {
    final c = _controller;
    if (c == null) return false;
    if (widget.readOnly || !widget.allowRename) return true;

    final current = c.layout.name;
    if (!_isPlaceholderName(current)) return true;

    final next = await _showNameBubble(
      title: '命名布局',
      initialValue: c.state.name ?? '',
      hintText: '请输入布局名称',
    );
    if (next == null) return false;
    c.replaceState(c.state.copyWith(name: next.trim()), markDirty: true);
    return true;
  }

  Future<void> _renameLayout() async {
    final c = _controller;
    if (c == null) return;
    if (widget.readOnly || !widget.allowRename) return;
    final next = await _showNameBubble(
      title: '重命名布局',
      initialValue: c.layout.name,
      hintText: '请输入布局名称',
    );
    if (next == null) return;
    c.replaceState(c.state.copyWith(name: next.trim()), markDirty: true);
  }

  Future<String?> _showNameBubble({
    required String title,
    required String initialValue,
    required String hintText,
  }) async {
    final textController = TextEditingController(text: initialValue);
    final focusNode = FocusNode();

    String? result;
    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'name',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 160),
      pageBuilder: (context, animation, secondaryAnimation) {
        return SafeArea(
          child: Material(
            type: MaterialType.transparency,
            child: Align(
              alignment: Alignment.topCenter,
              child: MediaQuery.removeViewInsets(
                context: context,
                removeBottom: true,
                child: Padding(
                  padding: const EdgeInsets.only(
                    // top: 20,
                    left: 12,
                    right: 12,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 520),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C1E).withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 18,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            // const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: textController,
                                    focusNode: focusNode,
                                    autofocus: true,
                                    textInputAction: TextInputAction.done,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                    decoration: InputDecoration(
                                      isDense: true,
                                      hintText: hintText,
                                      hintStyle: TextStyle(
                                        color: Colors.white
                                            .withValues(alpha: 0.35),
                                      ),
                                      filled: true,
                                      fillColor:
                                          Colors.white.withValues(alpha: 0.06),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(14),
                                        borderSide: BorderSide.none,
                                      ),
                                    ),
                                    onSubmitted: (v) {
                                      final next = v.trim();
                                      if (next.isEmpty) return;
                                      result = next;
                                      Navigator.of(context).pop();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  icon: const Icon(Icons.close,
                                      color: Colors.white70, size: 18),
                                  tooltip: '取消',
                                ),
                                IconButton(
                                  onPressed: () {
                                    final next = textController.text.trim();
                                    if (next.isEmpty) return;
                                    result = next;
                                    Navigator.of(context).pop();
                                  },
                                  icon: const Icon(Icons.done,
                                      color: Colors.lightBlueAccent, size: 18),
                                  tooltip: '确定',
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1.0).animate(curved),
            child: child,
          ),
        );
      },
    );

    focusNode.dispose();
    textController.dispose();
    return result;
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
                                    showStickClickToggle: c.selectedControl
                                            is VirtualJoystick &&
                                        (c.selectedControl as VirtualJoystick)
                                                .mode ==
                                            'gamepad',
                                    stickClickLabel:
                                        c.selectedControl is VirtualJoystick
                                            ? (((c.selectedControl
                                                            as VirtualJoystick)
                                                        .stickType ==
                                                    'left')
                                                ? 'LS重按'
                                                : 'RS重按')
                                            : '重按',
                                    stickClickEnabled:
                                        c.selectedStickClickEnabled,
                                    onStickClickChanged:
                                        c.setSelectedStickClickEnabled,
                                    showStickLockToggle: c.selectedControl
                                            is VirtualJoystick &&
                                        (c.selectedControl as VirtualJoystick)
                                                .mode ==
                                            'gamepad',
                                    stickLockLabel:
                                        c.selectedControl is VirtualJoystick
                                            ? (((c.selectedControl
                                                            as VirtualJoystick)
                                                        .stickType ==
                                                    'left')
                                                ? 'LS锁定'
                                                : 'RS锁定')
                                            : '锁定',
                                    stickLockEnabled:
                                        c.selectedStickLockEnabled,
                                    onStickLockChanged:
                                        c.setSelectedStickLockEnabled,
                                    showDpad3dToggle:
                                        c.selectedControl is VirtualDpad,
                                    dpad3dEnabled: c.selectedDpad3dEnabled,
                                    onDpad3dChanged: c.setSelectedDpad3dEnabled,
                                    canRemove: c.canDeleteSelected,
                                    canSave: c.isDirty && !widget.readOnly,
                                    canRename:
                                        widget.allowRename && !widget.readOnly,
                                    sizeValue: c.selectedScale,
                                    opacityValue: c.selectedOpacity,
                                    onRename: _renameLayout,
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
                                    onRemove: c.deleteSelected,
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
    required this.onClose,
    required this.onSave,
    required this.onToggleCollapsed,
    required this.onDeselect,
    required this.onOpenKeyboard,
    required this.onOpenMouse,
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
  final VoidCallback onClose;
  final VoidCallback onSave;
  final VoidCallback onToggleCollapsed;
  final VoidCallback onDeselect;
  final VoidCallback onOpenKeyboard;
  final VoidCallback onOpenMouse;
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
      constraints: BoxConstraints(maxWidth: hasSelection ? 400 : 280),
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
                            color:
                                canRemove ? Colors.redAccent : Colors.white24,
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
              Row(
                children: [
                  if (hasSelection && !readOnly && showStickClickToggle)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                      child: _RadioToggle(
                        label: stickClickLabel,
                        value: stickClickEnabled,
                        onChanged: onStickClickChanged,
                      ),
                    ),
                  if (hasSelection && !readOnly && showStickLockToggle)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                      child: _RadioToggle(
                        label: stickLockLabel,
                        value: stickLockEnabled,
                        onChanged: onStickLockChanged,
                      ),
                    ),
                ],
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
            ],
          ),
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
