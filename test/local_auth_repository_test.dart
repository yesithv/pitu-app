import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/features/auth/data/auth_store.dart';
import 'package:pitu_app/features/auth/data/local_auth_repository.dart';

/// [AuthStore] en memoria para las pruebas (sin plugins de plataforma).
class _MemoryAuthStore implements AuthStore {
  final Map<String, String> _data = {};

  @override
  Future<String?> read(String key) async => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);
}

void main() {
  group('LocalAuthRepository', () {
    late LocalAuthRepository repo;

    setUp(() {
      repo = LocalAuthRepository(_MemoryAuthStore());
    });

    test('sin cuenta al inicio', () async {
      expect(await repo.hasAccount(), isFalse);
      expect(await repo.currentSession(), isNull);
    });

    test('registrar crea la cuenta y deja la sesión iniciada', () async {
      final result = await repo.register(
        name: 'Ana',
        email: 'Ana@Ejemplo.com',
        password: 'secreta1',
      );

      expect(result.ok, isTrue);
      expect(result.user!.name, 'Ana');
      // El correo se normaliza (trim + minúsculas).
      expect(result.user!.email, 'ana@ejemplo.com');
      expect(await repo.hasAccount(), isTrue);
      expect((await repo.currentSession())!.email, 'ana@ejemplo.com');
    });

    test('login con la contraseña correcta funciona', () async {
      await repo.register(name: 'Ana', email: 'ana@ejemplo.com', password: 'secreta1');
      await repo.logout();

      final result = await repo.login(email: 'ana@ejemplo.com', password: 'secreta1');
      expect(result.ok, isTrue);
      expect((await repo.currentSession())!.email, 'ana@ejemplo.com');
    });

    test('login con contraseña incorrecta falla', () async {
      await repo.register(name: 'Ana', email: 'ana@ejemplo.com', password: 'secreta1');
      await repo.logout();

      final result = await repo.login(email: 'ana@ejemplo.com', password: 'incorrecta');
      expect(result.ok, isFalse);
      expect(result.error, 'Correo o contraseña incorrectos.');
      expect(await repo.currentSession(), isNull);
    });

    test('registrar una segunda cuenta falla (una por dispositivo)', () async {
      await repo.register(name: 'Ana', email: 'ana@ejemplo.com', password: 'secreta1');

      final result = await repo.register(
        name: 'Beto',
        email: 'beto@ejemplo.com',
        password: 'otra1234',
      );
      expect(result.ok, isFalse);
      expect(result.error, contains('Ya hay una cuenta'));
    });

    test('contraseña demasiado corta se rechaza', () async {
      final result =
          await repo.register(name: 'Ana', email: 'ana@ejemplo.com', password: '123');
      expect(result.ok, isFalse);
      expect(await repo.hasAccount(), isFalse);
    });

    test('correo inválido se rechaza', () async {
      final result =
          await repo.register(name: 'Ana', email: 'no-es-correo', password: 'secreta1');
      expect(result.ok, isFalse);
      expect(await repo.hasAccount(), isFalse);
    });

    test('logout limpia la sesión pero conserva la cuenta', () async {
      await repo.register(name: 'Ana', email: 'ana@ejemplo.com', password: 'secreta1');
      await repo.logout();

      expect(await repo.currentSession(), isNull);
      expect(await repo.hasAccount(), isTrue);
    });
  });
}
