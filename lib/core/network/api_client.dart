import 'dart:convert';
import 'dart:ui';

import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({
    required this.baseUrl,
    http.Client? httpClient,
  }) : _http = httpClient ?? http.Client();

  final String baseUrl;
  final http.Client _http;
  final Map<String, String> _cookies = <String, String>{};

  /// Called when a request fails with 401 and refresh also fails.
  /// Set this from the app to redirect to login.
  VoidCallback? onAuthFailed;

  bool _isRefreshing = false;

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () => _http.get(
        _uri(path, query),
        headers: _headers(),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> postJson(
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () => _http.post(
        _uri(path, query),
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> postForm(
    String path, {
    required Map<String, String> body,
    Map<String, String>? query,
  }) async {
    final headers = _headers();
    headers['Content-Type'] = 'application/x-www-form-urlencoded';
    final response = await _send(
      () => _http.post(
        _uri(path, query),
        headers: headers,
        body: body,
      ),
    );
    return _decode(response);
  }

  Future<dynamic> putJson(
    String path, {
    Object? body,
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () => _http.put(
        _uri(path, query),
        headers: _headers(),
        body: body == null ? null : jsonEncode(body),
      ),
    );
    return _decode(response);
  }

  Future<dynamic> deleteJson(
    String path, {
    Map<String, String>? query,
  }) async {
    final response = await _send(
      () => _http.delete(
        _uri(path, query),
        headers: _headers(),
      ),
    );
    return _decode(response);
  }

  Uri _uri(String path, Map<String, String>? query) {
    final sanitizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$sanitizedBase$normalizedPath').replace(
      queryParameters: query?.isEmpty ?? true ? null : query,
    );
  }

  Map<String, String> _headers() {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (_cookies.isNotEmpty) {
      headers['Cookie'] = _cookies.entries
          .map((entry) => '${entry.key}=${entry.value}')
          .join('; ');
    }
    return headers;
  }

  Future<http.Response> _send(
    Future<http.Response> Function() execute, {
    bool isRetry = false,
  }) async {
    final response = await execute();
    _captureCookies(response);

    // On 401, try refresh once
    if (response.statusCode == 401 && !isRetry && !_isRefreshing) {
      final refreshed = await _tryRefresh();
      if (refreshed) {
        // Retry the original request with new tokens
        return _send(execute, isRetry: true);
      }
      // Refresh failed — notify app
      onAuthFailed?.call();
    }

    return response;
  }

  Future<bool> _tryRefresh() async {
    _isRefreshing = true;
    try {
      final response = await _http.post(
        _uri('/auth/refresh', null),
        headers: _headers(),
      );
      _captureCookies(response);
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  void _captureCookies(http.Response response) {
    final setCookieHeader = response.headers['set-cookie'];
    if (setCookieHeader == null || setCookieHeader.isEmpty) return;

    for (final rawCookie in _splitSetCookieHeader(setCookieHeader)) {
      final firstPart = rawCookie.split(';').first.trim();
      final separator = firstPart.indexOf('=');
      if (separator <= 0) continue;
      final name = firstPart.substring(0, separator).trim();
      final value = firstPart.substring(separator + 1).trim();

      if (value.isEmpty) {
        _cookies.remove(name);
      } else {
        _cookies[name] = value;
      }
    }
  }

  List<String> _splitSetCookieHeader(String value) {
    final parts = <String>[];
    final buffer = StringBuffer();
    var inExpiresAttribute = false;

    for (var i = 0; i < value.length; i++) {
      final char = value[i];
      if (char == ',') {
        if (inExpiresAttribute) {
          buffer.write(char);
        } else {
          parts.add(buffer.toString().trim());
          buffer.clear();
        }
        continue;
      }

      buffer.write(char);

      final lower = buffer.toString().toLowerCase();
      if (lower.endsWith('expires=')) {
        inExpiresAttribute = true;
      } else if (inExpiresAttribute && char == ';') {
        inExpiresAttribute = false;
      }
    }

    final tail = buffer.toString().trim();
    if (tail.isNotEmpty) {
      parts.add(tail);
    }
    return parts;
  }

  dynamic _decode(http.Response response) {
    final rawBody = response.body.trim();
    final body = rawBody.isEmpty ? null : jsonDecode(rawBody);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw ApiException(
      statusCode: response.statusCode,
      message: _extractMessage(body) ?? 'Request failed',
      body: body,
    );
  }

  String? _extractMessage(dynamic body) {
    if (body is Map<String, dynamic>) {
      final detail = body['detail'];
      if (detail is String) return detail;
      final message = body['message'];
      if (message is String) return message;
    }
    return null;
  }
}

class ApiException implements Exception {
  const ApiException({
    required this.statusCode,
    required this.message,
    this.body,
  });

  final int statusCode;
  final String message;
  final dynamic body;

  @override
  String toString() => 'ApiException($statusCode): $message';
}
