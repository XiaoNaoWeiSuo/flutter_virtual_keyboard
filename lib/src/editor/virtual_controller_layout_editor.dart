import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiMode;
import '../models/virtual_controller_models.dart';
import 'editor_palette_tab.dart';
import 'macro/macro_suite_page.dart';
import 'virtual_controller_layout_editor_canvas.dart';
import 'virtual_controller_layout_editor_controller.dart';
import 'virtual_controller_layout_editor_palette.dart';
import '../widgets/system_ui_mode_scope.dart';

part 'layout_editor/virtual_controller_layout_editor_dock.dart';

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
    this.immersive = true,
    this.enabledPaletteTabs = const {
      VirtualControllerEditorPaletteTab.keyboard,
      VirtualControllerEditorPaletteTab.mouseAndJoystick,
      VirtualControllerEditorPaletteTab.macro,
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

  final bool immersive;

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

  Future<void> _editMacro() async {
    final c = _controller;
    if (c == null) return;
    final selected = c.selectedControl;
    if (selected is! VirtualMacroButton) return;

    final initialRecordingV2 = selected.config['recordingV2'];
    final initV2 = initialRecordingV2 is List
        ? initialRecordingV2
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : null;

    final result = await Navigator.of(context).push<MacroDraft>(
      MaterialPageRoute(
        builder: (context) => MacroSuitePage(
          definition: c.definition,
          state: c.state,
          initialLabel: selected.label.isEmpty ? 'Macro' : selected.label,
          initialRecordingV2: initV2,
          immersive: widget.immersive,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result != null) {
      c.setSelectedMacroRecordingV2(
        recordingV2: result.recordingV2,
        label: result.label,
      );
    }
  }

  Future<void> _openMacroSuite() async {
    final c = _controller;
    if (c == null) return;
    if (widget.readOnly || !widget.allowAddRemove) return;

    final result = await Navigator.of(context).push<MacroDraft>(
      MaterialPageRoute(
        builder: (context) => MacroSuitePage(
          definition: c.definition,
          state: c.state,
          initialLabel: '连招',
          immersive: widget.immersive,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == null) return;

    final id = 'macro_${DateTime.now().microsecondsSinceEpoch}';
    final control = VirtualMacroButton(
      id: id,
      label: result.label,
      layout: const ControlLayout(x: 0.7, y: 0.45, width: 0.22, height: 0.10),
      trigger: TriggerType.tap,
      config: {
        'label': result.label,
        'recordingV2': result.recordingV2,
      },
      sequence: const [],
    );
    c.addControl(control);
    c.setSelectedMacroRecordingV2(
      recordingV2: result.recordingV2,
      label: result.label,
    );
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

    return SystemUiModeScope(
      mode: widget.immersive ? SystemUiMode.immersiveSticky : null,
      child: Scaffold(
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
                          if (_dockCollapsed && c.selectedControl != null) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted) return;
                              if (!_dockCollapsed) return;
                              if (c.selectedControl == null) return;
                              setState(() => _dockCollapsed = false);
                            });
                          }
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
                                child: Padding(
                                  padding: const EdgeInsets.all(25),
                                  child: _DockPanel(
                                    title: c.layout.name,
                                    readOnly: widget.readOnly,
                                    allowAddRemove: widget.allowAddRemove,
                                    allowResize: widget.allowResize,
                                    enabledTabs: widget.enabledPaletteTabs,
                                    hasSelection: c.selectedControl != null,
                                    isMacro:
                                        c.selectedControl is VirtualMacroButton,
                                    showStickClickToggle:
                                        c.selectedControl is VirtualJoystick,
                                    stickClickLabel: c.selectedControl
                                            is VirtualJoystick
                                        ? (((((c.selectedControl
                                                                as VirtualJoystick)
                                                            .config['stickType']
                                                        as String?) ??
                                                    (c.selectedControl
                                                            as VirtualJoystick)
                                                        .stickType) ==
                                                'left')
                                            ? 'LS摇杆重按'
                                            : 'RS摇杆重按')
                                        : '按键',
                                    stickClickEnabled:
                                        c.selectedStickClickEnabled,
                                    onStickClickChanged:
                                        c.setSelectedStickClickEnabled,
                                    showStickLockToggle:
                                        c.selectedControl is VirtualJoystick,
                                    stickLockLabel:'摇杆锁定',
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
                                    onEditMacro: _editMacro,
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
                                    onOpenMacro: _openMacroSuite,
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
                            ],
                          );
                        },
                      ),
      ),
    );
  }
}
