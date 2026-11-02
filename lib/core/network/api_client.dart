import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? errors;

  ApiException({
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

  static const String _tokenKey = 'nexora_rider_auth_token';
  static const String _userRoleKey = 'nexora_rider_role';

  String? _cachedToken;
  http.Client _client = http.Client();

  /// Visible for testing to inject custom mock client
  void setMockClient(http.Client client) {
    _client = client;
  }

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
      return uri.replace(queryParameters: sanitizedParams);
    }
    return uri;
  }

  Map<String, String> _buildHeaders([Map<String, String>? extraHeaders]) {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (_cachedToken != null && _cachedToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_cachedToken';
    }

    if (extraHeaders != null) {
      headers.addAll(extraHeaders);
    }

    return headers;
  }

  ApiResponse<T> _handleResponse<T>(http.Response response) {
    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      decoded = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (decoded is Map<String, dynamic>) {
        final data = decoded.containsKey('data') ? decoded['data'] : decoded;
        final message = decoded['message']?.toString() ?? 'Success';
        final meta = decoded['meta'] is Map<String, dynamic> ? decoded['meta'] as Map<String, dynamic> : null;
        return ApiResponse<T>(
          data: data as T,
          message: message,
          pagination: meta,
          raw: decoded,
        );
      }
      return ApiResponse<T>(
        data: decoded as T,
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
        errors = decoded['errors'] as Map<String, dynamic>;
      }
    }

    throw ApiException(
      message: errorMessage,
      statusCode: response.statusCode,
      errors: errors,
    );
  }

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final response = await _client.get(uri, headers: _buildHeaders(headers));
    return _handleResponse<T>(response);
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final response = await _client.post(
      uri,
      headers: _buildHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse<T>(response);
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final response = await _client.put(
      uri,
      headers: _buildHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse<T>(response);
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final response = await _client.patch(
      uri,
      headers: _buildHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse<T>(response);
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    dynamic body,
    Map<String, dynamic>? queryParams,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path, queryParams);
    final response = await _client.delete(
      uri,
      headers: _buildHeaders(headers),
      body: body != null ? jsonEncode(body) : null,
    );
    return _handleResponse<T>(response);
  }

  Future<ApiResponse<T>> multipartPost<T>(
    String path, {
    Map<String, String>? fields,
    Map<String, http.MultipartFile>? files,
    Map<String, String>? headers,
  }) async {
    final uri = _buildUri(path);
    final request = http.MultipartRequest('POST', uri);

    final reqHeaders = _buildHeaders(headers);
    reqHeaders.remove('Content-Type'); // Let boundary header be generated
    request.headers.addAll(reqHeaders);

    if (fields != null) {
      request.fields.addAll(fields);
    }

    if (files != null) {
      files.forEach((_, file) {
        request.files.add(file);
      });
    }

    final streamedResponse = await _client.send(request);
    final response = await http.Response.fromStream(streamedResponse);
    return _handleResponse<T>(response);
  }
}

