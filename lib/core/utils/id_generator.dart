import 'package:uuid/uuid.dart';

/// Genera identificadores en el cliente (RD-18): UUID v4, no autoincremental.
/// Se define como contrato para poder inyectar generadores deterministas en test.
abstract class IdGenerator {
  String newId();
}

class UuidGenerator implements IdGenerator {
  const UuidGenerator();

  static const Uuid _uuid = Uuid();

  @override
  String newId() => _uuid.v4();
}
