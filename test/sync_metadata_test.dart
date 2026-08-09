import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/domain/sync_metadata.dart';

/// Requisitos transversales de datos que habilitan la Fase 2 (RD-18): UUID de
/// cliente, created_at/updated_at, created_by reservado y borrado lógico.
void main() {
  final now = DateTime(2026, 7, 22, 10);

  test('create fija created_at/updated_at y el autor local por defecto', () {
    final m = SyncMetadata.create(id: 'x', now: now);
    expect(m.createdAt, now);
    expect(m.updatedAt, now);
    expect(m.createdBy, SyncMetadata.localAuthor);
    expect(m.isDeleted, isFalse);
  });

  test('touched avanza updated_at sin tocar created_at', () {
    final m = SyncMetadata.create(id: 'x', now: now);
    final later = DateTime(2026, 7, 23);
    final t = m.touched(later);
    expect(t.createdAt, now);
    expect(t.updatedAt, later);
  });

  test('deleted aplica borrado lógico (no físico)', () {
    final m = SyncMetadata.create(id: 'x', now: now);
    final d = m.deleted(DateTime(2026, 7, 24));
    expect(d.isDeleted, isTrue);
    expect(d.deletedAt, DateTime(2026, 7, 24));
    expect(d.id, 'x'); // el id se conserva
  });

  test('clearDeletedAt permite revertir el borrado', () {
    final d = SyncMetadata.create(id: 'x', now: now).deleted(now);
    final revived = d.copyWith(clearDeletedAt: true);
    expect(revived.isDeleted, isFalse);
  });

  test('json round-trip conserva todos los campos', () {
    final m = SyncMetadata.create(id: 'x', now: now).deleted(now);
    final restored = SyncMetadata.fromJson(m.toJson());
    expect(restored.id, m.id);
    expect(restored.createdAt, m.createdAt);
    expect(restored.updatedAt, m.updatedAt);
    expect(restored.createdBy, m.createdBy);
    expect(restored.deletedAt, m.deletedAt);
  });

  test('fromJson usa el autor local si falta created_by', () {
    final json = {
      'id': 'x',
      'createdAt': now.toIso8601String(),
      'updatedAt': now.toIso8601String(),
      'deletedAt': null,
    };
    expect(SyncMetadata.fromJson(json).createdBy, SyncMetadata.localAuthor);
  });
}
