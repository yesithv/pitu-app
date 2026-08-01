import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/data/db_codec.dart';
import 'package:pitu_app/core/data/in_memory_database.dart';
import 'package:pitu_app/core/domain/sync_metadata.dart';
import 'package:pitu_app/features/backup/application/backup_service.dart';
import 'package:pitu_app/features/backup/data/file_transfer.dart';
import 'package:pitu_app/features/pets/domain/entities/pet.dart';
import 'package:pitu_app/features/pets/domain/entities/species.dart';

/// Fake del puente de archivos: captura lo que se "guarda" y devuelve un
/// contenido predefinido al seleccionar para importar.
class _FakeFileTransfer implements FileTransfer {
  _FakeFileTransfer({this.pickContent});

  final String? pickContent;
  String? savedText;
  String? savedName;

  @override
  bool get canPickFile => true;

  @override
  Future<String?> saveText(String filename, String content,
      {String mime = 'application/json'}) async {
    savedName = filename;
    savedText = content;
    return '/tmp/$filename';
  }

  @override
  Future<String?> saveBytes(String filename, List<int> bytes,
          {String mime = 'application/octet-stream'}) async =>
      null;

  @override
  Future<PickedTextFile?> pickTextFile({String accept = ''}) async =>
      pickContent == null ? null : PickedTextFile('backup.json', pickContent!);

  @override
  Future<PickedBinaryFile?> pickBinaryFile({String accept = ''}) async => null;
}

Pet _pet(String id, String name) => Pet(
      meta: SyncMetadata.create(id: id, now: DateTime(2026, 7, 22)),
      name: name,
      species: Species.dog,
    );

void main() {
  group('BackupService.export', () {
    test('produce JSON versionado y registra la fecha de respaldo', () async {
      final db = InMemoryDatabase()..pets.add(_pet('a', 'Firulais'));
      final files = _FakeFileTransfer();
      final service = BackupService(db, files, null);

      final path = await service.export();

      expect(path, contains('pitu-respaldo-'));
      expect(files.savedText, isNotNull);
      final map = jsonDecode(files.savedText!) as Map<String, dynamic>;
      expect(map['schemaVersion'], DbCodec.schemaVersion);
      expect(map['exportedAt'], isNotNull);
      expect(db.lastBackupAt, isNotNull);
    });
  });

  group('BackupService.pickForImport', () {
    test('archivo no-JSON es inválido', () async {
      final service =
          BackupService(InMemoryDatabase(), _FakeFileTransfer(pickContent: 'xx'), null);
      final result = await service.pickForImport();
      expect(result.error, isNotNull);
      expect(result.preview, isNull);
    });

    test('respaldo de versión más nueva es inválido', () async {
      final future = {'schemaVersion': DbCodec.schemaVersion + 1};
      final service = BackupService(
          InMemoryDatabase(), _FakeFileTransfer(pickContent: jsonEncode(future)), null);
      final result = await service.pickForImport();
      expect(result.error, contains('más nueva'));
    });

    test('respaldo válido devuelve un resumen con conteos', () async {
      final source = InMemoryDatabase()
        ..pets.add(_pet('a', 'Firulais'))
        ..pets.add(_pet('b', 'Luna'));
      final json = jsonEncode(DbCodec.encode(source));
      final service =
          BackupService(InMemoryDatabase(), _FakeFileTransfer(pickContent: json), null);

      final result = await service.pickForImport();

      expect(result.error, isNull);
      expect(result.preview, isNotNull);
      expect(result.preview!.pets, 2);
    });
  });

  group('BackupService.apply', () {
    BackupPreview previewOf(InMemoryDatabase src) => BackupPreview(
          data: DbCodec.encode(src),
          pets: src.pets.length,
          records: 0,
          attachments: 0,
          exportedAt: null,
        );

    test('replace reemplaza el contenido actual', () {
      final current = InMemoryDatabase()..pets.add(_pet('x', 'Vieja'));
      final source = InMemoryDatabase()
        ..pets.add(_pet('a', 'Firulais'))
        ..pets.add(_pet('b', 'Luna'));
      final service = BackupService(current, _FakeFileTransfer(), null);

      service.apply(previewOf(source), BackupMode.replace);

      expect(current.pets.map((p) => p.id), unorderedEquals(['a', 'b']));
    });

    test('combine agrega por UUID sin duplicar', () {
      final current = InMemoryDatabase()..pets.add(_pet('a', 'Firulais'));
      final source = InMemoryDatabase()
        ..pets.add(_pet('a', 'Firulais')) // mismo UUID: no debe duplicar
        ..pets.add(_pet('b', 'Luna')); // nuevo: se agrega
      final service = BackupService(current, _FakeFileTransfer(), null);

      final result = service.apply(previewOf(source), BackupMode.combine);

      expect(current.pets.length, 2);
      expect(current.pets.map((p) => p.id), unorderedEquals(['a', 'b']));
      expect(result.isSuccess, isTrue);
    });
  });
}
