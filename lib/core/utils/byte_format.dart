/// Formatea un tamaño en bytes a un texto legible (B / KB / MB). Compartido por
/// la galería de documentos y el indicador de espacio de Ajustes (RNF-06).
String formatBytes(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
