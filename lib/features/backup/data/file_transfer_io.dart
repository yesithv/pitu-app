import 'dart:io';

import 'file_transfer.dart';

/// Fábrica para plataformas con `dart:io` (móvil/escritorio). Guarda los
/// archivos en el directorio temporal del sistema; la selección para importar
/// llegará con un selector nativo (pendiente de validación en dispositivo).
FileTransfer makeFileTransfer() => const IoFileTransfer();

class IoFileTransfer implements FileTransfer {
  const IoFileTransfer();

  @override
  bool get canPickFile => false;

  @override
  Future<String?> saveText(String filename, String content,
      {String mime = 'application/json'}) async {
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsString(content);
    return file.path;
  }

  @override
  Future<String?> saveBytes(String filename, List<int> bytes,
      {String mime = 'application/octet-stream'}) async {
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsBytes(bytes);
    return file.path;
  }

  @override
  Future<PickedTextFile?> pickTextFile({String accept = ''}) async => null;
}
