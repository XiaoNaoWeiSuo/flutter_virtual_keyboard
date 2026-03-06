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
  // 非 Web 平台不做任何事
}

void notifyLayoutChanged(String id, String name) {
  // 非 Web 平台不做任何事
}
