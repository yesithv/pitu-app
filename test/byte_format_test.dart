import 'package:flutter_test/flutter_test.dart';
import 'package:pitu_app/core/utils/byte_format.dart';

/// Formato del indicador de espacio ocupado por documentos (RNF-06) y de la
/// galería.
void main() {
  test('bytes por debajo de 1 KB se muestran en B', () {
    expect(formatBytes(0), '0 B');
    expect(formatBytes(512), '512 B');
    expect(formatBytes(1023), '1023 B');
  });

  test('a partir de 1 KB usa KB sin decimales', () {
    expect(formatBytes(1024), '1 KB');
    expect(formatBytes(1536), '2 KB'); // redondeo
    expect(formatBytes(1024 * 1023), '1023 KB');
  });

  test('a partir de 1 MB usa MB con un decimal', () {
    expect(formatBytes(1024 * 1024), '1.0 MB');
    expect(formatBytes((1.5 * 1024 * 1024).round()), '1.5 MB');
  });
}
