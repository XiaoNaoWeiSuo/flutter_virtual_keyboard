import 'dart:html' as html;

import 'kv_store_stub.dart';
export 'kv_store_stub.dart' show KeyValueStore;

class _WebLocalStorageStore implements KeyValueStore {
  @override
  String? getString(String key) => html.window.localStorage[key];

  @override
  Future<void> setString(String key, String value) async {
    html.window.localStorage[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    html.window.localStorage.remove(key);
  }
}

KeyValueStore createStore() => _WebLocalStorageStore();
