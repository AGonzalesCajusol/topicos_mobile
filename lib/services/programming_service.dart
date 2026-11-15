import 'api_service.dart';

class ProgrammingService {
  static Future<Map<String, dynamic>> all() =>
      ApiService.get('conductor/programaciones');

  static Future<Map<String, dynamic>> today() =>
      ApiService.get('conductor/programaciones/hoy');

  static Future<Map<String, dynamic>> detail(int id) =>
      ApiService.get('conductor/programaciones/$id');

  static Future<Map<String, dynamic>> start(int id) =>
      ApiService.postAuthenticated('conductor/programaciones/$id/iniciar');

  static Future<Map<String, dynamic>> finish(int id) =>
      ApiService.postAuthenticated('conductor/programaciones/$id/finalizar');

  static Future<Map<String, dynamic>> sendLocation(
    int id, {
    required double latitude,
    required double longitude,
    double? accuracy,
  }) =>
      ApiService.postAuthenticated(
        'conductor/programaciones/$id/ubicacion',
        {
          'latitude': latitude,
          'longitude': longitude,
          'accuracy': accuracy,
        },
      );
}
