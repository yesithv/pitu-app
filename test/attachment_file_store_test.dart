import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/attachment_file_store.dart';

/// Pruebas del almacén de adjuntos en el filesystem (RF-29).
void main() {
  AttachmentFileStore store() =>
      AttachmentFileStore(Directory.systemTemp.createTempSync('pitu_fs_'));

  test('write + readBytes: round-trip', () async {
    final s = store();
    final bytes = Uint8List.fromList([9, 8, 7, 6, 5]);
    final path = await s.write('a1', bytes);
    expect(await s.readBytes(path), bytes);
  });

  test('delete elimina el archivo', () async {
    final s = store();
    final path = await s.write('a1', Uint8List.fromList([1, 2]));
    await s.delete(path);
    expect(await s.readBytes(path), isNull);
  });

  test('totalBytes suma el tamaño de los archivos (RNF-06)', () async {
    final s = store();
    await s.write('a1', Uint8List.fromList(List.filled(10, 0)));
    await s.write('a2', Uint8List.fromList(List.filled(5, 0)));
    expect(await s.totalBytes(), 15);
  });

  test('retainOnly borra los adjuntos huérfanos', () async {
    final s = store();
    await s.write('keep', Uint8List.fromList([1]));
    await s.write('drop', Uint8List.fromList([2]));
    await s.retainOnly({'keep'});
    expect(await s.readBytes(s.pathFor('keep')), isNotNull);
    expect(await s.readBytes(s.pathFor('drop')), isNull);
  });

  test('deleteAll vacía la carpeta (RNF-13)', () async {
    final s = store();
    await s.write('a1', Uint8List.fromList([1]));
    await s.deleteAll();
    expect(await s.totalBytes(), 0);
  });
}
