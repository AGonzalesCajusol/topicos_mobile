import 'api_service.dart';

class ProgrammingService {
  static Future<Map<String, dynamic>> all() =>
      ApiService.get('conductor/programaciones');

  static Future<Map<String, dynamic>> today() =>
      ApiService.get('conductor/programaciones/hoy');
}
