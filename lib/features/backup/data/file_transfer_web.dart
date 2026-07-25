import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'file_transfer.dart';

/// Fábrica para web: descarga y selección de archivos reales vía el DOM.
FileTransfer makeFileTransfer() => const WebFileTransfer();

class WebFileTransfer implements FileTransfer {
  const WebFileTransfer();

  @override
  bool get canPickFile => true;

  @override
  Future<String?> saveText(String filename, String content,
      {String mime = 'application/json'}) async {
    _download(html.Blob(<Object>[content], mime), filename);
    return null;
  }

  @override
  Future<String?> saveBytes(String filename, List<int> bytes,
      {String mime = 'application/octet-stream'}) async {
    _download(html.Blob(<Object>[Uint8List.fromList(bytes)], mime), filename);
    return null;
  }

  void _download(html.Blob blob, String filename) {
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body!.append(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Future<PickedTextFile?> pickTextFile(
      {String accept = '.json,application/json'}) {
    final completer = Completer<PickedTextFile?>();
    final input = html.FileUploadInputElement()..accept = accept;
    input.onChange.listen((_) {
      final files = input.files;
      if (files == null || files.isEmpty) {
        if (!completer.isCompleted) completer.complete(null);
        return;
      }
      final file = files.first;
      final reader = html.FileReader();
      reader.onError.listen((_) {
        if (!completer.isCompleted) completer.complete(null);
      });
      reader.onLoadEnd.listen((_) {
        if (completer.isCompleted) return;
        final result = reader.result;
        completer
            .complete(PickedTextFile(file.name, result is String ? result : ''));
      });
      reader.readAsText(file);
    });
    // Si el usuario cancela el diálogo nativo, `onChange` no se dispara; el
    // Future queda pendiente sin efectos, lo que es aceptable para el MVP.
    input.click();
    return completer.future;
  }
}
