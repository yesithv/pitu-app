/// Almacén clave→valor asíncrono para las credenciales de la cuenta local.
///
/// En móvil/escritorio la implementación usa el llavero del SO
/// (`flutter_secure_storage`, igual que [SecureKeyStore]); en web usa
/// `shared_preferences` (coherente con el snapshot en `localStorage`). La
/// elección la hace [createAuthStore] por *conditional import*.
abstract class AuthStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}
