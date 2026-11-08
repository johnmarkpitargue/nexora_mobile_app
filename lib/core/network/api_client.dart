import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.errors,
  });

  @override
  String toString() => message;
}

class ApiResponse<T> {
  final T data;
  final String message;
  final Map<String, dynamic>? pagination;
  final Map<String, dynamic>? raw;

  ApiResponse({
    required this.data,
    required this.message,
    this.pagination,
    this.raw,
  });

  dynamic operator [](String key) {
    if (key == 'data') return data;
    if (key == 'message') return message;
    if (key == 'pagination') return pagination;
    if (raw != null && raw!.containsKey(key)) return raw![key];
    if (data is Map && (data as Map).containsKey(key)) return (data as Map)[key];
    return null;
  }
}

class ApiClient {
  static final ApiClient instance = ApiClient._internal();
  ApiClient._internal();

  static const String _tokenKey = 'nexora_auth_token';
  static const String _userRoleKey = 'nexora_auth_role';

  String? _cachedToken;
  http.Client _client = http.Client();

  /// Visible for testing to inject custom mock client
  void setMockClient(http.Client client) {
    _client = client;
  }

  set client(http.Client client) => _client = client;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString(_tokenKey);
  }

  String? get token => _cachedToken;
  bool get isAuthenticated => _cachedToken != null && _cachedToken!.isNotEmpty;
  bool get hasToken => isAuthenticated;

  Future<void> saveToken(String token, [String? role]) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (role != null) {
      await prefs.setString(_userRoleKey, role);
    }
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userRoleKey);
  }

  Uri _buildUri(String path, [Map<String, dynamic>? queryParams]) {
    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
    final cleanPath = path.startsWith('/') ? path : '/$path';
    final fullUrl = '$base$cleanPath';

    final uri = Uri.parse(fullUrl);
    if (queryParams != null && queryParams.isNotEmpty) {
      final sanitizedParams = <String, String>{};
      queryParams.forEach((key, value) {
        if (value != null) {
          sanitizedParams[key] = value.toString();
        }
      });
      return uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...sanitizedParams,
      });
    }
    return uri;
  }

  void _logRequest(String method, Uri uri, int statusCode, int elapsedMs) {
    if (kDebugMode) {
      final pathWithQuery = uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;
      debugPrint('[API] $method $pathWithQuery -> $statusCode (${elapsedMs}ms)');
    }
  }

  Map<String, String> _buildHeaders({
    String? idempotencyKey,
    Map<String, String>? extraHeaders,
  }) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_cachedToken';
    }

    if (idempotencyKey != null && idempotencyKey.isNotEmpty) {
      headers['Idempotency-Key'] = idempotencyKey;
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? extraHeaders,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final sw = Stopwatch()..start();
    final response = await _client.get(
      uri,
      headers: _buildHeaders(extraHeaders: headers ?? extraHeaders),
    );
    sw.stop();
    _logRequest('GET', uri, response.statusCode, sw.elapsedMilliseconds);
    return _handleResponse(response);
  }

  Future<ApiResponse<dynamic>> post(
    String path, {
    dynamic body,
    String? idempotencyKey,
    Map<String, String>? extraHeaders,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    return _postUri(
      uri,
      body: body,
      idempotencyKey: idempotencyKey,
      headers: headers ?? extraHeaders,
    );
  }

  Future<ApiResponse<dynamic>> _postUri(
    Uri uri, {
    dynamic body,
    String? idempotencyKey,
    Map<String, String>? headers,
  }) async {
    final sw = Stopwatch()..start();
    final response = await _client.post(
      uri,
      headers: _buildHeaders(
        idempotencyKey: idempotencyKey,
        extraHeaders: headers,
      ),
      body: body != null ? jsonEncode(body) : null,
    );
    sw.stop();
    _logRequest('POST', uri, response.statusCode, sw.elapsedMilliseconds);
    return _handleResponse(response);
  }

  Future<ApiResponse<dynamic>> put(
    String path, {
    dynamic body,
    Map<String, String>? extraHeaders,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final sw = Stopwatch()..start();
    final response = await _client.put(
      uri,
      headers: _buildHeaders(extraHeaders: headers ?? extraHeaders),
      body: body != null ? jsonEncode(body) : null,
    );
    sw.stop();
    _logRequest('PUT', uri, response.statusCode, sw.elapsedMilliseconds);
    return _handleResponse(response);
  }

  Future<ApiResponse<dynamic>> patch(
    String path, {
    dynamic body,
    Map<String, String>? extraHeaders,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final sw = Stopwatch()..start();
    final response = await _client.patch(
      uri,
      headers: _buildHeaders(extraHeaders: headers ?? extraHeaders),
      body: body != null ? jsonEncode(body) : null,
    );
    sw.stop();
    _logRequest('PATCH', uri, response.statusCode, sw.elapsedMilliseconds);
    return _handleResponse(response);
  }

  Future<ApiResponse<dynamic>> delete(
    String path, {
    dynamic body,
    Map<String, String>? extraHeaders,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final sw = Stopwatch()..start();
    final response = await _client.delete(
      uri,
      headers: _buildHeaders(extraHeaders: headers ?? extraHeaders),
      body: body != null ? jsonEncode(body) : null,
    );
    sw.stop();
    _logRequest('DELETE', uri, response.statusCode, sw.elapsedMilliseconds);
    return _handleResponse(response);
  }

  Future<ApiResponse<dynamic>> multipart(
    String method,
    String path, {
    Map<String, String>? fields,
    List<http.MultipartFile>? files,
    String? idempotencyKey,
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest(method, uri);

    final headers = _buildHeaders(idempotencyKey: idempotencyKey);
    headers.remove('Content-Type'); // Multipart sets its own boundary
    request.headers.addAll(headers);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (files != null) {
      request.files.addAll(files);
    }

    final sw = Stopwatch()..start();
    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    sw.stop();
    _logRequest(method.toUpperCase(), uri, response.statusCode, sw.elapsedMilliseconds);
    return _handleResponse(response);
  }

  ApiResponse<dynamic> _handleResponse(http.Response response) {
    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        return ApiResponse(
          data: decoded['data'] ?? decoded,
          message: decoded['message']?.toString() ?? 'Success',
          pagination: decoded['pagination'] is Map<String, dynamic>
              ? decoded['pagination']
              : null,
          raw: decoded,
        );
      }
      return ApiResponse(
        data: decoded,
        message: 'Success',
      );
    }

    String errorMessage = 'An unexpected error occurred (${response.statusCode})';
    Map<String, dynamic>? errors;

    if (decoded is Map<String, dynamic>) {
      if (decoded['message'] != null) {
        errorMessage = decoded['message'].toString();
      } else if (decoded['error'] != null) {
        errorMessage = decoded['error'].toString();
      }

      if (decoded['errors'] is Map<String, dynamic>) {
        errors = decoded['errors'];
        // Pick first validation error message if available
        final firstErrorList = errors!.values.firstWhere(
          (val) => val is List && val.isNotEmpty,
          orElse: () => null,
        );
        if (firstErrorList != null && firstErrorList is List && firstErrorList.isNotEmpty) {
          errorMessage = firstErrorList.first.toString();
        }
      }
    }

    throw ApiException(
      message: errorMessage,
      statusCode: response.statusCode,
      errors: errors,
    );
  }
}
