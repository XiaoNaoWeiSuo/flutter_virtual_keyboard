import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

import 'platform/file_io.dart';
import 'platform/kv_store.dart';

void main() {
  InputBindingRegistry.registerGamepadButton(code: 'turbo', label: 'Turbo');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Virtual Gamepad Pro (Web Demo)',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorSchemeSeed: const Color(0xFF6AA9FF),
        useMaterial3: true,
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
    if (!mounted) return;
    setState(() {
      _ids = ids;
      _selectedId = selected;
      _state = state;
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
    await _select(id);
    if (!mounted) return;
    setState(() => _ids = ids);
  }

  Future<void> _renameCurrent() async {
    final id = _selectedId;
    if (id == null) return;
    final controller = TextEditingController(text: id);
    final next = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('重命名布局'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: '输入新 ID（用于保存与分享）'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text.trim()),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    final nextId = (next ?? '').trim();
    if (nextId.isEmpty || nextId == id) return;
    final renamed = await _repo.rename(id, nextId);
    final ids = await _repo.listIds();
    await _select(renamed);
    if (!mounted) return;
    setState(() => _ids = ids);
  }

  Future<void> _deleteCurrent() async {
    final id = _selectedId;
    if (id == null) return;
    if (_ids.length <= 1) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除布局'),
        content: Text('确定删除 "$id" 吗？此操作只影响本地存储。'),
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
    setState(() => _ids = ids);
  }

  Future<void> _editCurrent() async {
    final id = _selectedId;
    if (id == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VirtualControllerLayoutEditor(
          layoutId: id,
          loadDefinition: (_) async => _definition,
          loadState: _repo.loadState,
          saveState: _repo.saveState,
          onClose: () => Navigator.of(context).maybePop(),
          allowMove: true,
          allowResize: true,
          allowAddRemove: true,
          readOnly: false,
        ),
      ),
    );
    final state = await _repo.loadState(id);
    if (!mounted) return;
    setState(() => _state = state);
  }

  Future<void> _exportCurrent() async {
    final id = _selectedId;
    if (id == null) return;
    final state = await _repo.loadState(id);
    final jsonStr = const JsonEncoder.withIndent('  ').convert(state.toJson());
    try {
      await downloadTextFile('$id.state.json', jsonStr);
    } catch (_) {
      await _showExportDialog(filename: '$id.state.json', content: jsonStr);
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
    setState(() => _ids = ids);
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final selected = _selectedId ?? _ids.first;
    final definition = _definition;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Virtual Gamepad Pro — Web Demo'),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected,
                  items: [
                    for (final id in _ids)
                      DropdownMenuItem(value: id, child: Text(id)),
                  ],
                  onChanged: (v) => v == null ? null : _select(v),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: '编辑',
            onPressed: _editCurrent,
            icon: const Icon(Icons.edit),
          ),
          IconButton(
            tooltip: '导出 JSON',
            onPressed: _exportCurrent,
            icon: const Icon(Icons.download),
          ),
          IconButton(
            tooltip: '导入 JSON',
            onPressed: _importNew,
            icon: const Icon(Icons.upload),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF0E1116),
                          const Color(0xFF0E1116).withValues(alpha: 0.9),
                          const Color(0xFF101A2C),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'Game / Canvas Area',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                  ),
                ),
                VirtualControllerOverlay(
                  definition: definition,
                  state: _state,
                  onInputEvent: (e) {},
                  opacity: 1.0,
                  showLabels: true,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 360,
            child: _SidePanel(
              id: selected,
              count: _ids.length,
              onNew: () => _createNew(duplicate: false),
              onDuplicate: () => _createNew(duplicate: true),
              onRename: _renameCurrent,
              onDelete: _deleteCurrent,
              onEdit: _editCurrent,
            ),
          ),
        ],
      ),
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.id,
    required this.count,
    required this.onNew,
    required this.onDuplicate,
    required this.onRename,
    required this.onDelete,
    required this.onEdit,
  });

  final String id;
  final int count;
  final VoidCallback onNew;
  final VoidCallback onDuplicate;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0B0E12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('当前布局：$id', style: const TextStyle(color: Colors.white)),
            const SizedBox(height: 6),
            Text(
              '本地布局数量：$count',
              style: const TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onEdit,
              icon: const Icon(Icons.open_in_full),
              label: const Text('打开编辑器'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onNew,
              icon: const Icon(Icons.add),
              label: const Text('新建布局'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onDuplicate,
              icon: const Icon(Icons.copy),
              label: const Text('复制当前布局'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: onRename,
              icon: const Icon(Icons.drive_file_rename_outline),
              label: const Text('重命名'),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: count <= 1 ? null : onDelete,
              icon: const Icon(Icons.delete_outline),
              label: const Text('删除'),
            ),
            const Spacer(),
            const Text(
              '说明：编辑器只会保存 state（位置/大小/透明度）。\nbinding/style/回调等全部由代码控制。',
              style: TextStyle(color: Colors.white38, fontSize: 12),
            ),
          ],
        ),
      ),
    );
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

  Future<String> rename(String from, String to) async {
    final ids = await listIds();
    final sanitized = to.trim();
    final next = _uniqueId(
      sanitized,
      ids.where((e) => e != from).toList(),
      allowSame: true,
    );
    final state = await loadState(from);
    final nextIds = ids.map((e) => e == from ? next : e).toList();
    await _store.setString(_kIds, jsonEncode(nextIds));
    await saveState(next, state);
    if (next != from) {
      await _store.remove(_stateKey(from));
    }
    await setSelectedId(next);
    return next;
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
