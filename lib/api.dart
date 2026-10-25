import 'dart:convert';

import 'package:http/http.dart' as http;

import 'config.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.statusCode]);

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class Api {
  Api._();
  static final instance = Api._();

  String? token;

  Map<String, String> get _headers => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> get(String path, [Map<String, String>? query]) => _send(() => http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Object? body]) => _send(() => http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> put(String path, [Object? body]) => _send(() => http.put(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> patch(String path, [Object? body]) =>
      _send(() => http.patch(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  /// Sube un archivo como multipart/form-data.
  Future<dynamic> upload(String path, String field, List<int> bytes, String filename) => _send(() async {
    final req = http.MultipartRequest('POST', _uri(path))
      ..headers.addAll({..._headers}..remove('Content-Type'))
      ..files.add(http.MultipartFile.fromBytes(field, bytes, filename: filename));
    return http.Response.fromStream(await req.send());
  });

  Future<dynamic> delete(String path) => _send(() => http.delete(_uri(path), headers: _headers));

  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${AppConfig.apiUrl}$path');
    return query == null ? uri : uri.replace(queryParameters: query);
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 30));
    } catch (_) {
      throw ApiException('No se pudo conectar con el servidor. Revisa tu conexión.');
    }

    final body = res.body.isEmpty ? null : jsonDecode(res.body);
    if (res.statusCode >= 200 && res.statusCode < 300) return body;

    var message = 'Ocurrió un error (${res.statusCode}).';
    if (body is Map) {
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        message = first is List ? first.first.toString() : first.toString();
      } else if (body['message'] != null) {
        message = body['message'].toString();
      }
    }
    if (res.statusCode == 401) message = 'Tu sesión expiró. Inicia sesión de nuevo.';
    throw ApiException(message, res.statusCode);
  }
}
