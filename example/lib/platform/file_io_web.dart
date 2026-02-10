import 'dart:async';
import 'dart:html' as html;

Future<void> downloadTextFile(
  String filename,
  String content, {
  String mimeType = 'application/json',
}) async {
  final blob = html.Blob([content], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final a = html.AnchorElement(href: url)
    ..download = filename
    ..style.display = 'none';
  html.document.body?.children.add(a);
  a.click();
  a.remove();
  html.Url.revokeObjectUrl(url);
}

Future<PickedTextFile?> pickTextFile({
  String accept = '.json,application/json',
}) async {
  final input = html.FileUploadInputElement()..accept = accept;
  input.style.display = 'none';
  html.document.body?.children.add(input);

  final completer = Completer<PickedTextFile?>();
  input.onChange.first.then((_) async {
    final files = input.files;
    if (files == null || files.isEmpty) {
      input.remove();
      completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.readAsText(file);
    await reader.onLoad.first;
    final result = reader.result;
    input.remove();
    if (result is String) {
      completer.complete(PickedTextFile(file.name, result));
    } else {
      completer.complete(null);
    }
  });

  input.click();
  return completer.future;
}

class PickedTextFile {
  final String name;
  final String content;

  const PickedTextFile(this.name, this.content);
}
