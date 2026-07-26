import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

import 'file_transfer.dart';

/// Fábrica para plataformas con `dart:io` (móvil/escritorio). Guarda los
/// archivos y los ofrece con la hoja de compartir del sistema (`share_plus`), y
/// permite seleccionar archivos para importar/adjuntar (`file_picker`).
FileTransfer makeFileTransfer() => const IoFileTransfer();

class IoFileTransfer implements FileTransfer {
  const IoFileTransfer();

  @override
  bool get canPickFile => true;

  @override
  Future<String?> saveText(String filename, String content,
      {String mime = 'application/json'}) async {
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsString(content);
    await Share.shareXFiles(
        [XFile(file.path, mimeType: mime, name: filename)]);
    return null;
  }

  @override
  Future<String?> saveBytes(String filename, List<int> bytes,
      {String mime = 'application/octet-stream'}) async {
    final file = File('${Directory.systemTemp.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles(
        [XFile(file.path, mimeType: mime, name: filename)]);
    return null;
  }

  @override
  Future<PickedTextFile?> pickTextFile({String accept = ''}) async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    final bytes = _firstBytes(result);
    if (bytes == null) return null;
    return PickedTextFile(
        result!.files.first.name, utf8.decode(bytes, allowMalformed: true));
  }

  @override
  Future<PickedBinaryFile?> pickBinaryFile({String accept = ''}) async {
    final result =
        await FilePicker.platform.pickFiles(type: FileType.any, withData: true);
    final bytes = _firstBytes(result);
    if (bytes == null) return null;
    final picked = result!.files.first;
    return PickedBinaryFile(
        picked.name, _guessMime(picked.name, picked.extension), bytes);
  }

  Uint8List? _firstBytes(FilePickerResult? result) {
    if (result == null || result.files.isEmpty) return null;
    return result.files.first.bytes;
  }

  String _guessMime(String name, String? ext) {
    final e = (ext ?? (name.contains('.') ? name.split('.').last : '')).toLowerCase();
    switch (e) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }
}
