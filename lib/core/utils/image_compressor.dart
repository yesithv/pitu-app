import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Imagen ya comprimida lista para almacenar.
class CompressedImage {
  const CompressedImage(this.bytes, this.mimeType);
  final Uint8List bytes;
  final String mimeType;
}

/// Comprime una imagen: la redimensiona a un máximo de [maxDim] px de lado y la
/// re-codifica como JPEG, apuntando a menos de ~500 KB (RF-28). Si los bytes no
/// son una imagen decodificable, o el resultado no es más pequeño, devuelve los
/// originales sin cambios.
CompressedImage compressImage(
  Uint8List bytes, {
  required String mimeType,
  int maxDim = 1280,
  int quality = 80,
}) {
  if (!mimeType.startsWith('image/')) return CompressedImage(bytes, mimeType);
  img.Image? decoded;
  try {
    decoded = img.decodeImage(bytes);
  } catch (_) {
    decoded = null;
  }
  if (decoded == null) return CompressedImage(bytes, mimeType);

  var image = decoded;
  if (image.width > maxDim || image.height > maxDim) {
    image = image.width >= image.height
        ? img.copyResize(image, width: maxDim)
        : img.copyResize(image, height: maxDim);
  }
  final out = img.encodeJpg(image, quality: quality);
  if (out.length >= bytes.length) return CompressedImage(bytes, mimeType);
  return CompressedImage(Uint8List.fromList(out), 'image/jpeg');
}
