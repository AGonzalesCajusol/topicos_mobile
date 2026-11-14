import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'api_service.dart';

class AuthService {
  static const _storage = FlutterSecureStorage();
  static const _employeeKey = 'driver_employee';

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await ApiService.post('conductor/login', {
      'email': email,
      'password': password,
    });

    if (response['success'] != true) {
      throw ApiException(
        response['message']?.toString() ?? 'No fue posible iniciar sesión.',
      );
    }

    final token = response['access_token']?.toString();
    final employee = response['employee'];

    if (token == null || token.isEmpty || employee is! Map) {
      throw const ApiException('La respuesta del servidor está incompleta.');
    }

    final user = Map<String, dynamic>.from(employee);
    await ApiService.saveToken(token);
    await _storage.write(key: _employeeKey, value: jsonEncode(user));
    return user;
  }

  static Future<Map<String, dynamic>?> restoreSession() async {
    final token = await ApiService.readToken();
    final saved = await _storage.read(key: _employeeKey);
    if (token == null || token.isEmpty || saved == null) return null;

    try {
      final decoded = jsonDecode(saved);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      await logout();
    }
    return null;
  }

  static Future<void> logout() async {
    await ApiService.clearToken();
    await _storage.delete(key: _employeeKey);
  }
}
