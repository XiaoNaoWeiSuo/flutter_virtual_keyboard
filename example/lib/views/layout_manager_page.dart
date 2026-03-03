import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

import '../platform/file_io.dart';
import '../platform/kv_store.dart';
import '../repo/layout_repository.dart';
import '../theme/example_virtual_control_theme.dart';
import 'widgets/grid_paper.dart';
import 'widgets/sidebar.dart';
import 'widgets/toolbar.dart';

class LayoutManagerPage extends StatefulWidget {
  const LayoutManagerPage({super.key});

  @override
  State<LayoutManagerPage> createState() => _LayoutManagerPageState();
}

class _LayoutManagerPageState extends State<LayoutManagerPage> {
  final _repo = LayoutRepo(createStore());

  bool _loading = true;
  String? _selectedId;
  List<String> _ids = const [];
  Map<String, String> _names = {};

  // Canvas State
  bool _isEditing = false;
  double _canvasWidth = 812;
  double _canvasHeight = 375;
  String _selectedPreset = 'iPhone X/11/12/13 (L)';
  int _stateRevision = 0;
  bool _isSidebarOpen = true;

  static const _presets = <String, Size>{
    'iPhone 8 (L)': Size(667, 375),
    'iPhone 8 Plus (L)': Size(736, 414),
    'iPhone X/11/12/13 (L)': Size(812, 375),
    'iPhone 14/15 Pro Max (L)': Size(932, 430),
    'iPad (L)': Size(1024, 768),
    'iPad Pro 12.9 (L)': Size(1366, 1024),
    'Android 1080p (L)': Size(1920, 1080),
    'Android 720p (L)': Size(1280, 720),
    'Custom': Size.zero,
  };

  late final VirtualControlTheme _theme = buildExampleVirtualControlTheme();

  final VirtualControllerLayout _definition = VirtualControllerLayout(
    schemaVersion: 1,
    name: 'unnamed',
    controls: [],
  );

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _repo.init();
    final ids = await _repo.listIds();
    final selected = await _repo.getSelectedId() ?? ids.first;

    // Load all names
    final names = <String, String>{};
    for (final id in ids) {
      final s = await _repo.loadState(id);
      names[id] = s.name ?? id;
    }

    if (!mounted) return;
    setState(() {
      _ids = ids;
      _selectedId = selected;
      _names = names;
      _loading = false;
    });
  }

  Future<void> _select(String id) async {
    await _repo.loadState(id);
    await _repo.setSelectedId(id);
    if (!mounted) return;
    setState(() {
      _selectedId = id;
    });
  }

  Future<void> _createNew({bool duplicate = false}) async {
    final id = await _repo.create(baseId: duplicate ? _selectedId : null);
    final ids = await _repo.listIds();
    final state = await _repo.loadState(id);

    await _select(id);
    if (!mounted) return;
    setState(() {
      _ids = ids;
      final newNames = Map<String, String>.from(_names);
      newNames[id] = state.name ?? id;
      _names = newNames;
    });
  }

  Future<void> _deleteCurrent() async {
    final id = _selectedId;
    if (id == null) return;
    if (_ids.length <= 1) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除布局'),
        content: Text('确定删除 "${_names[id] ?? id}" 吗？此操作只影响本地存储。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('删除'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await _repo.delete(id);
    final ids = await _repo.listIds();
    final next = ids.first;
    await _select(next);
    if (!mounted) return;
    setState(() {
      _ids = ids;
      final newNames = Map<String, String>.from(_names);
      newNames.remove(id);
      _names = newNames;
    });
  }

  void _toggleEdit() {
    setState(() => _isEditing = !_isEditing);
  }

  Future<void> _exportCurrent() async {
    final id = _selectedId;
    if (id == null) return;
    final state = await _repo.loadState(id);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(state.toJson());
    final name = state.name ?? id;
    try {
      await downloadTextFile('$name.state.json', jsonStr);
    } catch (_) {
      await _showExportDialog(filename: '$name.state.json', content: jsonStr);
    }
  }

  Future<void> _importNew() async {
    String? filename;
    String? content;
    try {
      final picked = await pickTextFile();
      if (picked == null) return;
      filename = picked.name;
      content = picked.content;
    } catch (_) {
      final pasted = await _showImportDialog();
      if (pasted == null) return;
      filename = 'imported.state.json';
      content = pasted;
    }

    final dynamic decoded = jsonDecode(content);
    if (decoded is! Map) return;
    final state = VirtualControllerState.fromJson(
      Map<String, dynamic>.from(decoded),
    );
    final name = filename.replaceAll(RegExp(r'\.state\.json$'), '');
    final id = await _repo.importAs(name, state);
    final ids = await _repo.listIds();
    await _select(id);
    if (!mounted) return;
    setState(() {
      _ids = ids;
      final newNames = Map<String, String>.from(_names);
      newNames[id] = state.name ?? id;
      _names = newNames;
    });
  }

  Future<void> _showExportDialog({
    required String filename,
    required String content,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('导出：$filename'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(child: SelectableText(content)),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: content));
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('复制并关闭'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }

  Future<String?> _showImportDialog() async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入布局 State JSON'),
        content: SizedBox(
          width: 520,
          child: TextField(
            controller: controller,
            autofocus: true,
            minLines: 8,
            maxLines: 16,
            decoration: const InputDecoration(
              hintText: '粘贴 VirtualControllerState 的 JSON',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('导入'),
          ),
        ],
      ),
    );
  }

  void _updateCanvasSize(String preset) {
    setState(() {
      _selectedPreset = preset;
      final size = _presets[preset];
      if (size != null && size != Size.zero) {
        _canvasWidth = size.width;
        _canvasHeight = size.height;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final selected = _selectedId ?? _ids.first;

    return Scaffold(
      body: Row(
        children: [
          // Left Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOutCubic,
            width: _isSidebarOpen ? 280 : 0,
            child: OverflowBox(
              minWidth: 280,
              maxWidth: 280,
              alignment: Alignment.topLeft,
              child: LayoutSidebar(
                selectedId: selected,
                ids: _ids,
                names: _names,
                onSelect: _select,
                onNew: () => _createNew(duplicate: false),
                onDuplicate: () => _createNew(duplicate: true),
                onDelete: _deleteCurrent,
                onExport: _exportCurrent,
                onImport: _importNew,
              ),
            ),
          ),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Toolbar
                LayoutToolbar(
                  isEditing: _isEditing,
                  onToggleEdit: _toggleEdit,
                  selectedPreset: _selectedPreset,
                  presets: _presets.keys.toList(),
                  onPresetChanged: (v) {
                    if (v != null) _updateCanvasSize(v);
                  },
                  width: _canvasWidth,
                  height: _canvasHeight,
                  onWidthChanged: (v) => setState(() {
                    _canvasWidth = v;
                    _selectedPreset = 'Custom';
                  }),
                  onHeightChanged: (v) => setState(() {
                    _canvasHeight = v;
                    _selectedPreset = 'Custom';
                  }),
                  isSidebarOpen: _isSidebarOpen,
                  onToggleSidebar: () =>
                      setState(() => _isSidebarOpen = !_isSidebarOpen),
                ),
                // Canvas Area
                Expanded(
                  child: Container(
                    color: const Color(0xFFE5E5EA), // Light gray background
                    child: Center(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          padding: const EdgeInsets.all(40),
                          child: Container(
                            width: _canvasWidth,
                            height: _canvasHeight,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: CustomPaint(
                                      painter: GridPaperPainter(
                                        color: const Color(0xFFF0F0F2),
                                        interval: 20,
                                      ),
                                    ),
                                  ),
                                  if (_isEditing)
                                    VirtualControllerLayoutEditor(
                                      key: ValueKey('editor_$selected'),
                                      layoutId: selected,
                                      loadDefinition: (_) async => _definition,
                                      loadState: _repo.loadState,
                                      previewDecoratorTabs: const {
                                        VirtualControllerEditorPaletteTab
                                            .mouseAndJoystick,
                                        VirtualControllerEditorPaletteTab.macro,
                                        VirtualControllerEditorPaletteTab.xbox,
                                        VirtualControllerEditorPaletteTab.ps
                                      },
                                      saveState: (id, state) async {
                                        await _repo.saveState(id, state);
                                        if (mounted) {
                                          setState(() {
                                            _stateRevision++;
                                            final newNames =
                                                Map<String, String>.from(
                                              _names,
                                            );
                                            newNames[id] = state.name ?? id;
                                            _names = newNames;
                                          });
                                        }
                                      },
                                      previewDecorator: (layout) =>
                                          layout.mapControls(_theme.decorate),
                                      // Pass the theme to the editor for deep styling in previews
                                      theme: _theme,
                                      onClose: _toggleEdit,
                                      allowMove: true,
                                      allowResize: true,
                                      allowAddRemove: true,
                                      readOnly: false,
                                      allowRename: true,
                                      immersive: true,
                                    )
                                  else
                                    FutureBuilder<VirtualControllerState>(
                                      key: ValueKey(
                                        'overlay_${selected}_$_stateRevision',
                                      ),
                                      future: _repo.loadState(selected),
                                      builder: (context, snapshot) {
                                        final state = snapshot.data;
                                        if (state == null) {
                                          return const Center(
                                            child: SizedBox(
                                              width: 22,
                                              height: 22,
                                              child:
                                                  CircularProgressIndicator(),
                                            ),
                                          );
                                        }
                                        final definition =
                                            buildDefinitionFromState(
                                          state,
                                          runtimeDefaults: true,
                                          fallbackName: _definition.name,
                                        );
                                        return VirtualControllerOverlay(
                                          definition: definition,
                                          state: state,
                                          theme: _theme,
                                          onInputEvent: (_) {},
                                          opacity: 1.0,
                                          showLabels: true,
                                          immersive: true,
                                        );
                                      },
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
              ],
            ),
          ),
        ],
      ),
    );
  }
}
