Future<void> downloadTextFile(
  String filename,
  String content, {
  String mimeType = 'application/json',
}) async {
  throw UnsupportedError('downloadTextFile is only supported on web');
}

Future<PickedTextFile?> pickTextFile({
  String accept = '.json,application/json',
}) async {
  throw UnsupportedError('pickTextFile is only supported on web');
}

class PickedTextFile {
  final String name;
  final String content;

  const PickedTextFile(this.name, this.content);
}
