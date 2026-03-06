@TestOn('browser')
library;

import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:example/platform/web_interop.dart';
import 'package:flutter_test/flutter_test.dart';

@JS('window.addEventListener')
external void _addWindowEventListener(JSString type, JSFunction listener);

@JS('window.removeEventListener')
external void _removeWindowEventListener(JSString type, JSFunction listener);

@JS('window.postMessage')
external void _windowPostMessage(JSAny message, JSString targetOrigin);

@JS('window.parent')
external JSObject get _parent;

@JS('window.location.origin')
external JSString get _origin;

@JS('Object')
external JSFunction get _objectCtor;

JSObject _newObject() => _objectCtor.callAsConstructor() as JSObject;

class _CapturedMessage {
  _CapturedMessage({
    required this.channel,
    required this.type,
    required this.requestId,
    required this.ok,
    required this.error,
    required this.data,
  });

  final String? channel;
  final String? type;
  final String? requestId;
  final bool? ok;
  final String? error;
  final JSObject? data;
}

JSObject? _tryAsObject(JSAny? value) {
  if (value == null) return null;
  try {
    return value as JSObject;
  } catch (_) {
    return null;
  }
}

String? _getString(JSObject obj, String key) {
  return (obj[key] as JSString?)?.toDart;
}

bool? _getBool(JSObject obj, String key) {
  return (obj[key] as JSBoolean?)?.toDart;
}

_CapturedMessage _capture(JSObject msg) {
  return _CapturedMessage(
    channel: _getString(msg, 'channel'),
    type: _getString(msg, 'type'),
    requestId: _getString(msg, 'requestId'),
    ok: _getBool(msg, 'ok'),
    error: _getString(msg, 'error'),
    data: _tryAsObject(msg['data']),
  );
}

Future<_CapturedMessage> _nextMessage({
  required bool Function(JSObject msg) where,
  Duration timeout = const Duration(seconds: 2),
}) {
  final completer = Completer<_CapturedMessage>();
  late final JSFunction listener;

  listener = ((JSAny event) {
    final eventObj = event as JSObject;
    final msg = _tryAsObject(eventObj['data']);
    if (msg == null) return;
    if (!where(msg)) return;
    _removeWindowEventListener('message'.toJS, listener);
    completer.complete(_capture(msg));
  }).toJS;

  _addWindowEventListener('message'.toJS, listener);

  return completer.future.timeout(timeout, onTimeout: () {
    _removeWindowEventListener('message'.toJS, listener);
    throw TimeoutException('timeout waiting for message');
  });
}

Future<void> _initAndDrainReady({
  String Function()? onExport,
  void Function(String)? onImport,
  List<Map<String, String>> Function()? onList,
  void Function(String)? onSelect,
  void Function()? onToggleEdit,
  List<String> allowedOrigins = const ['*'],
}) async {
  initWebInterop(
    onExport: onExport ?? () => '',
    onImport: onImport ?? (_) {},
    onList: onList ?? () => const [],
    onSelect: onSelect ?? (_) {},
    onToggleEdit: onToggleEdit ?? () {},
    allowedOrigins: allowedOrigins,
    targetOrigin: '*',
    channel: 'layout_editor',
  );

  await _nextMessage(where: (msg) {
    return _getString(msg, 'channel') == 'layout_editor' &&
        _getString(msg, 'type') == 'sdk_ready';
  });
}

void _sendCommand({
  required String type,
  required String requestId,
  JSObject? data,
}) {
  final msg = _newObject();
  msg['channel'] = 'layout_editor'.toJS;
  msg['type'] = type.toJS;
  msg['requestId'] = requestId.toJS;
  if (data != null) {
    msg['data'] = data;
  }
  _windowPostMessage(msg, '*'.toJS);
}

JSObject? _arrayAt(JSObject arr, int index) {
  return _tryAsObject(arr['$index']);
}

void runWebInteropTests() {
  group('Web interop SDK', () {
    late final JSAny? originalParentPostMessage;

    setUpAll(() {
      originalParentPostMessage = _parent['postMessage'];
      _parent['postMessage'] =
          ((JSAny message, JSString targetOrigin) {
        _windowPostMessage(message, targetOrigin);
      }).toJS;
    });

    tearDownAll(() {
      if (originalParentPostMessage != null) {
        _parent['postMessage'] = originalParentPostMessage!;
      }
    });

    test('initWebInterop posts sdk_ready', () async {
      initWebInterop(
        onExport: () => '',
        onImport: (_) {},
        onList: () => const [],
        onSelect: (_) {},
        onToggleEdit: () {},
        allowedOrigins: const ['*'],
        targetOrigin: '*',
        channel: 'layout_editor',
      );
      final msg = await _nextMessage(where: (m) {
        return _getString(m, 'channel') == 'layout_editor' &&
            _getString(m, 'type') == 'sdk_ready';
      });

      expect(msg.channel, 'layout_editor');
      expect(msg.type, 'sdk_ready');
      expect(_getString(msg.data!, 'version'), isNotEmpty);
      expect(_getString(msg.data!, 'channel'), 'layout_editor');
    });

    test('notifyLayoutChanged posts layout_changed', () async {
      await _initAndDrainReady();

      notifyLayoutChanged('id1', 'name1');

      final msg = await _nextMessage(where: (m) {
        return _getString(m, 'channel') == 'layout_editor' &&
            _getString(m, 'type') == 'layout_changed';
      });
      expect(msg.channel, 'layout_editor');
      expect(msg.type, 'layout_changed');
      expect(_getString(msg.data!, 'id'), 'id1');
      expect(_getString(msg.data!, 'name'), 'name1');
    });

    test('export_layout returns json via response', () async {
      await _initAndDrainReady(onExport: () => '{"ok":true}');

      _sendCommand(type: 'export_layout', requestId: 'r1');

      final msg = await _nextMessage(where: (m) {
        return _getString(m, 'channel') == 'layout_editor' &&
            _getString(m, 'type') == 'response' &&
            _getString(m, 'requestId') == 'r1';
      });

      expect(msg.ok, true);
      expect(_getString(msg.data!, 'json'), '{"ok":true}');
    });

    test('import_layout calls handler and acks', () async {
      final imported = Completer<String>();
      await _initAndDrainReady(onImport: (json) => imported.complete(json));

      final data = _newObject();
      data['json'] = '{"x":1}'.toJS;
      _sendCommand(type: 'import_layout', requestId: 'r2', data: data);

      final msg = await _nextMessage(where: (m) {
        return _getString(m, 'channel') == 'layout_editor' &&
            _getString(m, 'type') == 'response' &&
            _getString(m, 'requestId') == 'r2';
      });

      expect(await imported.future.timeout(const Duration(seconds: 2)), '{"x":1}');
      expect(msg.ok, true);
    });

    test('list_layouts returns layouts', () async {
      await _initAndDrainReady(onList: () {
        return const [
          {'id': 'a', 'name': 'A'},
          {'id': 'b', 'name': 'B'},
        ];
      });

      _sendCommand(type: 'list_layouts', requestId: 'r3');

      final msg = await _nextMessage(where: (m) {
        return _getString(m, 'channel') == 'layout_editor' &&
            _getString(m, 'type') == 'response' &&
            _getString(m, 'requestId') == 'r3';
      });

      expect(msg.ok, true);
      final layouts = _tryAsObject(msg.data!['layouts']);
      expect(layouts, isNotNull);
      expect(_arrayAt(layouts!, 0), isNotNull);
      expect(_arrayAt(layouts, 1), isNotNull);
      expect(_arrayAt(layouts, 2), isNull);
      expect(_getString(_arrayAt(layouts, 0)!, 'id'), 'a');
      expect(_getString(_arrayAt(layouts, 0)!, 'name'), 'A');
      expect(_getString(_arrayAt(layouts, 1)!, 'id'), 'b');
      expect(_getString(_arrayAt(layouts, 1)!, 'name'), 'B');
    });

    test('select_layout calls handler and acks', () async {
      final selected = Completer<String>();
      await _initAndDrainReady(onSelect: (id) => selected.complete(id));

      final data = _newObject();
      data['id'] = 'layout-123'.toJS;
      _sendCommand(type: 'select_layout', requestId: 'r4', data: data);

      final msg = await _nextMessage(where: (m) {
        return _getString(m, 'channel') == 'layout_editor' &&
            _getString(m, 'type') == 'response' &&
            _getString(m, 'requestId') == 'r4';
      });

      expect(await selected.future.timeout(const Duration(seconds: 2)), 'layout-123');
      expect(msg.ok, true);
    });

    test('toggle_edit calls handler and acks', () async {
      var toggled = 0;
      await _initAndDrainReady(onToggleEdit: () => toggled++);

      _sendCommand(type: 'toggle_edit', requestId: 'r5');

      final msg = await _nextMessage(where: (m) {
        return _getString(m, 'channel') == 'layout_editor' &&
            _getString(m, 'type') == 'response' &&
            _getString(m, 'requestId') == 'r5';
      });

      expect(toggled, 1);
      expect(msg.ok, true);
    });

    test('allowedOrigins blocks commands from untrusted origins', () async {
      final currentOrigin = _origin.toDart;
      expect(currentOrigin, isNotEmpty);

      await _initAndDrainReady(allowedOrigins: const ['https://not-allowed.example']);

      _sendCommand(type: 'export_layout', requestId: 'blocked');

      await expectLater(
        _nextMessage(
          where: (m) =>
              _getString(m, 'channel') == 'layout_editor' &&
              _getString(m, 'type') == 'response' &&
              _getString(m, 'requestId') == 'blocked',
          timeout: const Duration(milliseconds: 400),
        ),
        throwsA(isA<TimeoutException>()),
      );
    });
  });
}
