import 'file_transfer.dart';
// En web (sin `dart:io`) se usa la implementación con DOM; en móvil/escritorio
// (con `dart:io`) la que escribe en el sistema de archivos.
import 'file_transfer_web.dart' if (dart.library.io) 'file_transfer_io.dart';

FileTransfer createFileTransfer() => makeFileTransfer();
