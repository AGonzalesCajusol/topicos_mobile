import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../config/api_config.dart';

class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'driver_access_token';

  static Future<String?> readToken() => _storage.read(key: _tokenKey);

  static Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final response = await http
        .post(
          ApiConfig.endpoint(path),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 25));
    return _decode(response);
  }

  static Future<Map<String, dynamic>> postAuthenticated(
    String path, [
    Map<String, dynamic> body = const {},
  ]) async {
    final token = await readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException(
        'Tu sesión ha finalizado. Inicia sesión nuevamente.',
        statusCode: 401,
      );
    }

    final response = await http
        .post(
          ApiConfig.endpoint(path),
          headers: {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 401) {
      await clearToken();
    }
    return _decode(response);
  }

  static Future<Map<String, dynamic>> get(String path) async {
    final token = await readToken();
    if (token == null || token.isEmpty) {
      throw const ApiException('Tu sesión ha finalizado. Inicia sesión nuevamente.', statusCode: 401);
    }

    final response = await http
        .get(
          ApiConfig.endpoint(path),
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(const Duration(seconds: 25));

    if (response.statusCode == 401) {
      await clearToken();
    }
    return _decode(response);
  }

  static Map<String, dynamic> _decode(http.Response response) {
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) data = decoded;
    } on FormatException {
      throw ApiException(
        'El servidor devolvió una respuesta que no se pudo interpretar.',
        statusCode: response.statusCode,
      );
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = switch (response.statusCode) {
        401 => data['message']?.toString() ?? 'Tu sesión ha finalizado. Inicia sesión nuevamente.',
        403 => data['message']?.toString() ?? 'No tienes autorización para ingresar.',
        422 => data['message']?.toString() ?? 'No se pudo validar la operación.',
        409 => data['message']?.toString() ?? 'El recorrido ya no se encuentra disponible.',
        422 => data['message']?.toString() ?? 'No se pudo validar la operación.',
        429 => 'Has realizado demasiados intentos. Espera un momento antes de volver a intentarlo.',
        500 => 'Ocurrió un error en el servidor. Inténtalo más tarde.',
        _ => data['message']?.toString() ?? 'Ocurrió un error al comunicarse con el servidor.',
      };
      throw ApiException(message, statusCode: response.statusCode);
    }
    return data;
  }
}
