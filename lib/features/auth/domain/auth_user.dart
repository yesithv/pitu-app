/// Usuario autenticado de la cuenta **local** (Fase 1). No representa una cuenta
/// en la nube: las credenciales viven solo en el dispositivo. En Fase 2, cuando
/// exista backend, esta misma entidad la poblará el `AuthRepository` remoto sin
/// que la presentación cambie.
class AuthUser {
  const AuthUser({required this.name, required this.email});

  final String name;
  final String email;
}
