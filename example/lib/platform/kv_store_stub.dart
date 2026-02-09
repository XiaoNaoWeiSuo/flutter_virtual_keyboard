abstract interface class KeyValueStore {
  String? getString(String key);
  Future<void> setString(String key, String value);
  Future<void> remove(String key);
}

class _MemoryStore implements KeyValueStore {
  final Map<String, String> _map = {};

  @override
  String? getString(String key) => _map[key];

  @override
  Future<void> setString(String key, String value) async {
    _map[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _map.remove(key);
  }
}

KeyValueStore createStore() => _MemoryStore();
