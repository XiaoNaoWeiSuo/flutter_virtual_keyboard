import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:virtual_gamepad_pro/virtual_gamepad_pro.dart';

import '../platform/kv_store.dart';

class LayoutRepo {
  LayoutRepo(this._store);

  final KeyValueStore _store;

  static const _kIds = 'vkp_layout_ids';
  static const _kSelected = 'vkp_selected_id';
  static const _kPrefix = 'vkp_state_';
  static const _kSampleStateAssetPath = 'lib/PS.state.json';
  static const _kSeededSample = 'vkp_seeded_sample_v1';

  Future<void> init() async {
    final seeded = _store.getString(_kSeededSample) == '1';
    if (!seeded) {
      final existingIds = await listIds();
      final prevSelected = await getSelectedId();
      final sample = await _loadBundledSampleState();
      if (sample != null) {
        await importAs(sample.name ?? 'PS', sample);
        if (existingIds.isNotEmpty) {
          final keep = prevSelected ?? existingIds.first;
          await setSelectedId(keep);
        }
      }
      await _store.setString(_kSeededSample, '1');
    }

    final ids = await listIds();
    if (ids.isNotEmpty) return;
    await create();
  }

  Future<VirtualControllerState?> _loadBundledSampleState() async {
    try {
      final raw = await rootBundle.loadString(_kSampleStateAssetPath);
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return VirtualControllerState.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      return null;
    }
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
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newIds = [...ids, newId];
    await _store.setString(_kIds, jsonEncode(newIds));

    if (baseId != null) {
      final baseState = await loadState(baseId);
      final newState = VirtualControllerState(
        schemaVersion: baseState.schemaVersion,
        name: '${baseState.name ?? baseId} (Copy)',
        controls: baseState.controls,
      );
      await saveState(newId, newState);
    } else {
      await saveState(
        newId,
        const VirtualControllerState(
          schemaVersion: 1,
          name: 'unnamed',
          controls: [],
        ),
      );
    }
    return newId;
  }

  Future<String> importAs(String name, VirtualControllerState state) async {
    final ids = await listIds();
    final newId = DateTime.now().millisecondsSinceEpoch.toString();
    final newIds = [...ids, newId];
    await _store.setString(_kIds, jsonEncode(newIds));

    final newState = VirtualControllerState(
      schemaVersion: state.schemaVersion,
      name: name,
      controls: state.controls,
    );
    await saveState(newId, newState);
    return newId;
  }
}
