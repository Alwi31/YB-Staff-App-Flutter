import 'dart:convert';
import 'dart:io';

import 'package:alice/alice.dart';
import 'package:alice_http/alice_http_adapter.dart';
import 'package:http/http.dart' as http;
import 'package:yb_staff_app/core/constants/api_constants.dart';
import 'package:yb_staff_app/core/network/api_exception.dart';
import 'package:yb_staff_app/core/storage/token_storage.dart';

class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    http.Client? httpClient,
    Alice? alice,
    void Function()? onUnauthorized,
  })  : _tokenStorage = tokenStorage,
        _httpClient = httpClient ?? http.Client(),
        _onUnauthorized = onUnauthorized {
    if (alice != null) {
      _aliceAdapter = AliceHttpAdapter();
      alice.addAdapter(_aliceAdapter!);
    }
  }

  final TokenStorage _tokenStorage;
  final http.Client _httpClient;
  final void Function()? _onUnauthorized;
  AliceHttpAdapter? _aliceAdapter;

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _buildHeaders(requiresAuth: requiresAuth);

    try {
      final response = await _httpClient.post(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      _aliceAdapter?.onResponse(response, body: body);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _buildHeaders(requiresAuth: true);
    try {
      final response = await _httpClient.patch(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      _aliceAdapter?.onResponse(response, body: body);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _buildHeaders(requiresAuth: true);
    try {
      final response = await _httpClient.put(
        uri,
        headers: headers,
        body: jsonEncode(body),
      );
      _aliceAdapter?.onResponse(response, body: body);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  /// Upload a single file via multipart/form-data POST.
  Future<Map<String, dynamic>> multipartPost(
    String endpoint, {
    required String fieldName,
    required File file,
    Map<String, String>? fields,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final token = await _tokenStorage.getToken();
    final request = http.MultipartRequest('POST', uri)
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer ${token ?? ''}';
    if (fields != null) request.fields.addAll(fields);
    request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
    try {
      final streamed = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamed);
      _aliceAdapter?.onResponse(response);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final headers = await _buildHeaders(requiresAuth: true);
    try {
      final request = http.Request('DELETE', uri)..headers.addAll(headers);
      if (body != null) request.body = jsonEncode(body);
      final streamed = await _httpClient.send(request);
      final response = await http.Response.fromStream(streamed);
      _aliceAdapter?.onResponse(response, body: body);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? queryParams,
  }) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint')
        .replace(queryParameters: queryParams);
    final headers = await _buildHeaders(requiresAuth: true);

    try {
      final response = await _httpClient.get(uri, headers: headers);
      _aliceAdapter?.onResponse(response);
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(
        message:
            'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }

  Future<Map<String, String>> _buildHeaders({bool requiresAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _tokenStorage.getToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    if (response.statusCode == 401) {
      _onUnauthorized?.call();
      throw const ApiException(
        message: 'Sesi berakhir. Silakan login kembali.',
        statusCode: 401,
      );
    }

    final message =
        body['message'] as String? ?? 'Terjadi kesalahan pada server.';
    throw ApiException(message: message, statusCode: response.statusCode);
  }
}
