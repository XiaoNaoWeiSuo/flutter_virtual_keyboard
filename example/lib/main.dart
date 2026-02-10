import 'dart:convert';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

import 'platform/file_io.dart';
import 'platform/kv_store.dart';

void main() {
  // InputBindingRegistry.registerGamepadButton(code: 'turbo', label: 'Turbo');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '布局编辑器',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.black,
          brightness: Brightness.light,
          surface: Colors.white,
          onSurface: Colors.black87,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F7), // Apple-like light gray
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          scrolledUnderElevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          ),
          color: Colors.white,
        ),
        dividerTheme: DividerThemeData(
          color: Colors.grey.withValues(alpha: 0.1),
          thickness: 1,
        ),
      ),
      home: const LayoutManagerPage(),
    );
  }
}

class LayoutManagerPage extends StatefulWidget {
  const LayoutManagerPage({super.key});

  @override
  State<LayoutManagerPage> createState() => _LayoutManagerPageState();
}

class _LayoutManagerPageState extends State<LayoutManagerPage> {
  final _repo = _LayoutRepo(createStore());

  bool _loading = true;
  String? _selectedId;
  VirtualControllerState _state = const VirtualControllerState(
    schemaVersion: 1,
    controls: [],
  );
  List<String> _ids = const [];
  Map<String, String> _names = {};

  // Canvas State
  bool _isEditing = false;
  double _canvasWidth = 812;
  double _canvasHeight = 375;
  String _selectedPreset = 'iPhone X/11/12/13 (L)';

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

  final VirtualControllerLayout _definition = VirtualControllerLayout.xbox()
      .withButtonStyle(
        where: (b) => b.gamepadButtonOrNull == GamepadButtonId.a,
        style: const ControlStyle(
          shape: BoxShape.rectangle,
          borderRadius: 999,
          borderWidth: 2,
          borderColor: Color(0x88FFFFFF),
          color: Color(0x66000000),
          labelText: 'A',
          labelIcon: Icons.touch_app,
          labelIconColor: Color(0xFFFFCC00),
          labelIconScale: 0.62,
        ),
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
    final state = await _repo.loadState(selected);
    
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
      _state = state;
      _names = names;
      _loading = false;
    });
  }

  Future<void> _select(String id) async {
    final nextState = await _repo.loadState(id);
    await _repo.setSelectedId(id);
    if (!mounted) return;
    setState(() {
      _selectedId = id;
      _state = nextState;
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
          SizedBox(
            width: 280,
            child: _Sidebar(
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
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Toolbar
                _Toolbar(
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
                              color: Colors.white,
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
                                      painter: _GridPaperPainter(
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
                                      saveState: (id, state) async {
                                        await _repo.saveState(id, state);
                                        if (mounted) {
                                          setState(() {
                                            _state = state;
                                            final newNames =
                                                Map<String, String>.from(
                                                    _names);
                                            newNames[id] = state.name ?? id;
                                            _names = newNames;
                                          });
                                        }
                                      },
                                      onClose: _toggleEdit,
                                      allowMove: true,
                                      allowResize: true,
                                      allowAddRemove: true,
                                      readOnly: false,
                                      allowRename: true,
                                    )
                                  else
                                    VirtualControllerOverlay(
                                      definition: _definition,
                                      state: _state,
                                      onInputEvent: (e) {},
                                      opacity: 1.0,
                                      showLabels: true,
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

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedId,
    required this.ids,
    required this.names,
    required this.onSelect,
    required this.onNew,
    required this.onDuplicate,
    required this.onDelete,
    required this.onExport,
    required this.onImport,
  });

  final String selectedId;
  final List<String> ids;
  final Map<String, String> names;
  final ValueChanged<String> onSelect;
  final VoidCallback onNew;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;
  final VoidCallback onExport;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: const Text(
              'Virtual Gamepad',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              itemCount: ids.length,
              itemBuilder: (context, index) {
                final id = ids[index];
                final name = names[id] ?? id;
                final isSelected = id == selectedId;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: ListTile(
                    title: Text(
                      name,
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected ? Colors.black : Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    selected: isSelected,
                    selectedTileColor: const Color(0xFFF5F5F7),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    onTap: () => onSelect(id),
                    dense: true,
                    visualDensity: VisualDensity.compact,
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _SidebarButton(
                  icon: CupertinoIcons.add,
                  label: '新建布局',
                  onTap: onNew,
                  textColor: Colors.blue,
                ),
                _SidebarButton(
                  icon: CupertinoIcons.arrow_up_doc,
                  label: '导入 JSON',
                  onTap: onImport,
                ),
                // More actions menu
                MenuAnchor(
                  style: MenuStyle(
                    backgroundColor: const WidgetStatePropertyAll(Colors.white),
                    surfaceTintColor: const WidgetStatePropertyAll(Colors.white),
                    padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 8)),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    elevation: const WidgetStatePropertyAll(6),
                    shadowColor: WidgetStatePropertyAll(Colors.black.withValues(alpha: 0.2)),
                  ),
                  builder: (context, controller, child) {
                    return _SidebarButton(
                      icon: CupertinoIcons.ellipsis_circle,
                      label: '更多操作',
                      onTap: () {
                        if (controller.isOpen) {
                          controller.close();
                        } else {
                          controller.open();
                        }
                      },
                    );
                  },
                  menuChildren: [
                    _MenuItem(
                      onPressed: onDuplicate,
                      icon: CupertinoIcons.doc_on_doc,
                      label: '复制当前布局',
                    ),
                    _MenuItem(
                      onPressed: onExport,
                      icon: CupertinoIcons.arrow_down_doc,
                      label: '导出 JSON',
                    ),
                    _MenuItem(
                      onPressed: ids.length <= 1 ? null : onDelete,
                      icon: CupertinoIcons.trash,
                      label: '删除',
                      isDestructive: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarButton extends StatefulWidget {
  const _SidebarButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.textColor = Colors.black87,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color textColor;

  @override
  State<_SidebarButton> createState() => _SidebarButtonState();
}

class _SidebarButtonState extends State<_SidebarButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          decoration: BoxDecoration(
            color: _isHovered ? const Color(0xFFF5F5F7) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(widget.icon, size: 20, color: widget.textColor == Colors.blue ? Colors.blue : Colors.black54),
              const SizedBox(width: 12),
              Text(
                widget.label,
                style: TextStyle(
                  color: widget.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.isDestructive = false,
  });

  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    return MenuItemButton(
      onPressed: onPressed,
      style: ButtonStyle(
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return const Color(0xFFF5F5F7);
          }
          return null;
        }),
        padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
        minimumSize: const WidgetStatePropertyAll(Size(200, 40)),
      ),
      leadingIcon: Icon(
        icon,
        size: 18,
        color: onPressed == null
            ? Colors.grey
            : (isDestructive ? Colors.red : Colors.black87),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: onPressed == null
              ? Colors.grey
              : (isDestructive ? Colors.red : Colors.black87),
          fontSize: 14,
        ),
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.isEditing,
    required this.onToggleEdit,
    required this.selectedPreset,
    required this.presets,
    required this.onPresetChanged,
    required this.width,
    required this.height,
    required this.onWidthChanged,
    required this.onHeightChanged,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
          left: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 200,
            child: InputDecorator(
            
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                // labelText: '画布预设',
                floatingLabelBehavior: FloatingLabelBehavior.always,
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedPreset,
                  isExpanded: true,
                  items: presets
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: onPresetChanged,
                ),
              ),
            ),
          ),
          const VerticalDivider(indent: 12, endIndent: 12, width: 32),
          _SizeInput(
            label: 'W',
            value: width,
            onChanged: onWidthChanged,
          ),
          const SizedBox(width: 16),
          _SizeInput(
            label: 'H',
            value: height,
            onChanged: onHeightChanged,
          ),
          const Spacer(),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(
                value: false,
                label: Text('预览',style: TextStyle(fontSize: 12),),
                // icon: Icon(Icons.visibility_outlined),
              ),
              ButtonSegment(
                value: true,
                label: Text('编辑',style: TextStyle(fontSize: 12),),
                // icon: Icon(Icons.edit_outlined),
              ),
            ],
            selected: {isEditing},
            onSelectionChanged: (_) => onToggleEdit(),
            showSelectedIcon: false,
          ),
        ],
      ),
    );
  }
}

class _SizeInput extends StatefulWidget {
  const _SizeInput({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  State<_SizeInput> createState() => _SizeInputState();
}

class _SizeInputState extends State<_SizeInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value.toStringAsFixed(0));
  }

  @override
  void didUpdateWidget(covariant _SizeInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value &&
        double.tryParse(_ctrl.text) != widget.value) {
      _ctrl.text = widget.value.toStringAsFixed(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 80,
      child: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          isDense: true,
        ),
        onSubmitted: (v) {
          final d = double.tryParse(v);
          if (d != null) widget.onChanged(d);
        },
      ),
    );
  }
}

class _GridPaperPainter extends CustomPainter {
  const _GridPaperPainter({required this.color, required this.interval});

  final Color color;
  final double interval;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (double x = 0; x <= size.width; x += interval) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }

    for (double y = 0; y <= size.height; y += interval) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GridPaperPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.interval != interval;
  }
}

class _LayoutRepo {
  _LayoutRepo(this._store);

  final KeyValueStore _store;

  static const _kIds = 'vkp_layout_ids';
  static const _kSelected = 'vkp_selected_id';
  static const _kPrefix = 'vkp_state_';

  Future<void> init() async {
    final ids = await listIds();
    if (ids.isNotEmpty) return;
    final id = 'default';
    await _store.setString(_kIds, jsonEncode([id]));
    await saveState(
      id,
      const VirtualControllerState(schemaVersion: 1, controls: []),
    );
    await setSelectedId(id);
  }

  Future<List<String>> listIds() async {
    final raw = _store.getString(_kIds);
    if (raw == null || raw.trim().isEmpty) return const [];
    final v = jsonDecode(raw);
    if (v is! List) return const [];
    return v.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }

  Future<String?> getSelectedId() async {
    final v = _store.getString(_kSelected);
    final s = v?.trim();
    return (s == null || s.isEmpty) ? null : s;
  }

  Future<void> setSelectedId(String id) => _store.setString(_kSelected, id);

  String _stateKey(String id) => '$_kPrefix$id';

  Future<VirtualControllerState> loadState(String layoutId) async {
    final raw = _store.getString(_stateKey(layoutId));
    if (raw == null || raw.trim().isEmpty) {
      return const VirtualControllerState(schemaVersion: 1, controls: []);
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      return const VirtualControllerState(schemaVersion: 1, controls: []);
    }
    return VirtualControllerState.fromJson(Map<String, dynamic>.from(decoded));
  }

  Future<void> saveState(String layoutId, VirtualControllerState state) async {
    await _store.setString(_stateKey(layoutId), jsonEncode(state.toJson()));
  }

  Future<void> delete(String layoutId) async {
    final ids = (await listIds()).where((e) => e != layoutId).toList();
    await _store.setString(_kIds, jsonEncode(ids));
    await _store.remove(_stateKey(layoutId));
  }

  Future<String> create({String? baseId}) async {
    final ids = await listIds();
    final id = _uniqueId(
      'layout_${DateTime.now().millisecondsSinceEpoch}',
      ids,
    );
    final state = baseId == null
        ? const VirtualControllerState(schemaVersion: 1, controls: [])
        : await loadState(baseId);
    await _store.setString(_kIds, jsonEncode([...ids, id]));
    await saveState(id, state);
    await setSelectedId(id);
    return id;
  }

  Future<String> importAs(
    String preferredId,
    VirtualControllerState state,
  ) async {
    final ids = await listIds();
    final base = preferredId.trim().isEmpty ? 'imported' : preferredId.trim();
    final id = _uniqueId(base, ids);
    await _store.setString(_kIds, jsonEncode([...ids, id]));
    await saveState(id, state);
    await setSelectedId(id);
    return id;
  }

  String _uniqueId(
    String base,
    List<String> existing, {
    bool allowSame = false,
  }) {
    final normalized = base.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    if (normalized.isEmpty) return _uniqueId('layout', existing);
    if (allowSame && !existing.contains(normalized)) return normalized;
    if (!existing.contains(normalized)) return normalized;
    var i = 2;
    while (true) {
      final c = '${normalized}_$i';
      if (!existing.contains(c)) return c;
      i++;
    }
  }
}