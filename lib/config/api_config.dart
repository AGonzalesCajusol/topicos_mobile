class ApiConfig {
  // Dominio del backend Laravel en Render (sin agregar /api al final).
  // Puedes sobrescribirlo al ejecutar con --dart-define=API_BASE_URL=...
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://project-topicos-1.onrender.com',
  );

  static Uri endpoint(String path) {
    final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final route = path.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$base/api/$route');
  }
}
