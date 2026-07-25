import 'dart:typed_data';

/// Archivo de texto seleccionado por el usuario para importar.
class PickedTextFile {
  const PickedTextFile(this.name, this.content);
  final String name;
  final String content;
}

/// Archivo binario seleccionado (por ejemplo, una foto o un PDF adjunto).
class PickedBinaryFile {
  const PickedBinaryFile(this.name, this.mimeType, this.bytes);
  final String name;
  final String mimeType;
  final Uint8List bytes;
}

/// Puente de plataforma para descargar/guardar archivos y seleccionarlos.
///
/// La implementación se elige en tiempo de compilación (ver
/// `file_transfer_factory.dart`): en **web** usa el DOM (descarga y selección
/// reales, plenamente probable en el navegador); en **móvil/escritorio** guarda
/// el archivo en el almacenamiento local y la selección para importar llega con
/// un selector nativo (pendiente de validación en dispositivo).
abstract interface class FileTransfer {
  /// Si la plataforma puede abrir un selector para importar archivos.
  bool get canPickFile;

  /// Guarda o descarga texto. Devuelve una descripción del destino (una ruta en
  /// móvil) o `null` cuando el navegador lo descarga sin una ruta accesible.
  Future<String?> saveText(String filename, String content,
      {String mime = 'application/json'});

  /// Guarda o descarga bytes (por ejemplo, un PDF).
  Future<String?> saveBytes(String filename, List<int> bytes,
      {String mime = 'application/octet-stream'});

  /// Abre un selector y devuelve el contenido de texto elegido, o `null` si se
  /// canceló o la plataforma no lo soporta.
  Future<PickedTextFile?> pickTextFile({String accept});

  /// Abre un selector y devuelve el archivo binario elegido (foto o PDF), o
  /// `null` si se canceló o la plataforma no lo soporta.
  Future<PickedBinaryFile?> pickBinaryFile({String accept});
}
