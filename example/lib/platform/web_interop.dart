import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS('window')
external JSObject get window;

@JS('window.addEventListener')
external void _addWindowEventListener(JSString type, JSFunction listener);

@JS('window.removeEventListener')
external void _removeWindowEventListener(JSString type, JSFunction listener);

@JS('window.parent.postMessage')
external void _parentPostMessage(JSAny message, JSString targetOrigin);

@JS('Object')
external JSFunction get _objectCtor;

JSObject _newObject() => _objectCtor.callAsConstructor() as JSObject;

const String _sdkVersion = '1.0.0';

String _channelName = 'layout_editor';
String _targetOrigin = '*';
List<String> _allowedOrigins = const ['*'];

String Function()? _onExport;
void Function(String)? _onImport;
List<Map<String, String>> Function()? _onList;
void Function(String)? _onSelect;
void Function()? _onToggleEdit;

JSFunction? _messageListener;

/// 初始化 Web 互操作
void initWebInterop({
  required String Function() onExport,
  required void Function(String) onImport,
  required List<Map<String, String>> Function() onList,
  required void Function(String) onSelect,
  required void Function() onToggleEdit,
  String channel = 'layout_editor',
  String targetOrigin = '*',
  List<String> allowedOrigins = const ['*'],
}) {
  _channelName = channel;
  _targetOrigin = targetOrigin;
  _allowedOrigins = allowedOrigins;

  _onExport = onExport;
  _onImport = onImport;
  _onList = onList;
  _onSelect = onSelect;
  _onToggleEdit = onToggleEdit;

  if (_messageListener != null) {
    _removeWindowEventListener('message'.toJS, _messageListener!);
  }

  _messageListener = ((JSAny event) {
    _handleMessageEvent(event);
  }).toJS;
  _addWindowEventListener('message'.toJS, _messageListener!);

  final api = _newObject();
  api['version'] = _sdkVersion.toJS;
  api['channel'] = _channelName.toJS;
  api['exportLayout'] = (() => onExport().toJS).toJS;
  api['importLayout'] = ((JSString json) => onImport(json.toDart)).toJS;
  api['listLayouts'] = (() {
    return onList().map((item) {
      final jsItem = _newObject();
      jsItem['id'] = item['id']!.toJS;
      jsItem['name'] = item['name']!.toJS;
      return jsItem;
    }).toList().toJS;
  }).toJS;
  api['selectLayout'] = ((JSString id) => onSelect(id.toDart)).toJS;
  api['toggleEdit'] = (() => onToggleEdit()).toJS;

  window['layoutEditor'] = api;

  final data = _newObject();
  data['version'] = _sdkVersion.toJS;
  data['channel'] = _channelName.toJS;
  _sendMessage(type: 'sdk_ready', data: data);
}

void notifyLayoutChanged(String id, String name) {
  final data = _newObject();
  data['id'] = id.toJS;
  data['name'] = name.toJS;
  _sendMessage(type: 'layout_changed', data: data);
}

void _sendMessage({
  required String type,
  JSAny? data,
  String? requestId,
  bool? ok,
  String? error,
}) {
  final message = _newObject();
  message['channel'] = _channelName.toJS;
  message['type'] = type.toJS;
  if (requestId != null) {
    message['requestId'] = requestId.toJS;
  }
  if (ok != null) {
    message['ok'] = ok.toJS;
  }
  if (error != null) {
    message['error'] = error.toJS;
  }
  if (data != null) {
    message['data'] = data;
  }
  _parentPostMessage(message, _targetOrigin.toJS);
}

void _handleMessageEvent(JSAny event) {
  final eventObj = event as JSObject;

  final origin = (eventObj['origin'] as JSString?)?.toDart;
  if (origin == null) return;
  if (!(_allowedOrigins.contains('*') || _allowedOrigins.contains(origin))) {
    return;
  }

  final dataAny = eventObj['data'];
  if (dataAny == null) return;
  final dataObj = _tryAsObject(dataAny);
  if (dataObj == null) return;

  final channel = (dataObj['channel'] as JSString?)?.toDart;
  if (channel != _channelName) return;

  final type = (dataObj['type'] as JSString?)?.toDart;
  if (type == null) return;

  final requestId = (dataObj['requestId'] as JSString?)?.toDart;
  final payloadAny = dataObj['data'];

  switch (type) {
    case 'export_layout':
      _handleExportLayout(requestId);
      return;
    case 'import_layout':
      _handleImportLayout(requestId, payloadAny);
      return;
    case 'list_layouts':
      _handleListLayouts(requestId);
      return;
    case 'select_layout':
      _handleSelectLayout(requestId, payloadAny);
      return;
    case 'toggle_edit':
      _handleToggleEdit(requestId);
      return;
  }
}

JSObject? _tryAsObject(JSAny? value) {
  if (value == null) return null;
  try {
    return value as JSObject;
  } catch (_) {
    return null;
  }
}

void _replyOk(String? requestId, {JSAny? data}) {
  _sendMessage(type: 'response', requestId: requestId, ok: true, data: data);
}

void _replyError(String? requestId, String error) {
  _sendMessage(type: 'response', requestId: requestId, ok: false, error: error);
}

void _handleExportLayout(String? requestId) {
  final f = _onExport;
  if (f == null) {
    _replyError(requestId, 'not_initialized');
    return;
  }
  try {
    final payload = _newObject();
    payload['json'] = f().toJS;
    _replyOk(requestId, data: payload);
  } catch (e) {
    _replyError(requestId, e.toString());
  }
}

void _handleImportLayout(String? requestId, JSAny? payloadAny) {
  final f = _onImport;
  if (f == null) {
    _replyError(requestId, 'not_initialized');
    return;
  }
  try {
    final payload = _tryAsObject(payloadAny);
    final json = (payload?['json'] as JSString?)?.toDart;
    if (json == null) {
      _replyError(requestId, 'missing_json');
      return;
    }
    f(json);
    _replyOk(requestId);
  } catch (e) {
    _replyError(requestId, e.toString());
  }
}

void _handleListLayouts(String? requestId) {
  final f = _onList;
  if (f == null) {
    _replyError(requestId, 'not_initialized');
    return;
  }
  try {
    final layouts = f().map((item) {
      final jsItem = _newObject();
      jsItem['id'] = item['id']!.toJS;
      jsItem['name'] = item['name']!.toJS;
      return jsItem;
    }).toList().toJS;
    final payload = _newObject();
    payload['layouts'] = layouts;
    _replyOk(requestId, data: payload);
  } catch (e) {
    _replyError(requestId, e.toString());
  }
}

void _handleSelectLayout(String? requestId, JSAny? payloadAny) {
  final f = _onSelect;
  if (f == null) {
    _replyError(requestId, 'not_initialized');
    return;
  }
  try {
    final payload = _tryAsObject(payloadAny);
    final id = (payload?['id'] as JSString?)?.toDart;
    if (id == null) {
      _replyError(requestId, 'missing_id');
      return;
    }
    f(id);
    _replyOk(requestId);
  } catch (e) {
    _replyError(requestId, e.toString());
  }
}

void _handleToggleEdit(String? requestId) {
  final f = _onToggleEdit;
  if (f == null) {
    _replyError(requestId, 'not_initialized');
    return;
  }
  try {
    f();
    _replyOk(requestId);
  } catch (e) {
    _replyError(requestId, e.toString());
  }
}
