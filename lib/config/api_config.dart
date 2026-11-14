class ApiConfig {
  // Define la URL de tu servidor al ejecutar la app:
  // flutter run --dart-define=API_BASE_URL=https://tu-dominio.com
  // Escribe el dominio sin agregar /api al final.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000',
  );

  static Uri endpoint(String path) {
    final base = baseUrl.replaceFirst(RegExp(r'/+$'), '');
    final route = path.replaceFirst(RegExp(r'^/+'), '');
    return Uri.parse('$base/api/$route');
  }
}
