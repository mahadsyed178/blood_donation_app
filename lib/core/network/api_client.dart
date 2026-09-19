import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';

/// Called when the backend answers 401 to an authenticated request: the
/// session is gone (expired, or a password reset invalidated it), so the app
/// must log out. Wired up by the auth provider.
typedef UnauthorizedHandler = FutureOr<void> Function();

/// Thin Dio wrapper shared by every repository.
///
/// Responsibilities: base URL, timeouts, bearer attachment, one retry on
/// transient network failures for idempotent requests, and mapping every
/// failure into an [ApiException]. Nothing here knows about resources.
class ApiClient {
  final Dio _dio;
  final TokenStorage _tokenStorage;
  UnauthorizedHandler? onUnauthorized;

  ApiClient({required TokenStorage tokenStorage, Dio? dio})
      : _tokenStorage = tokenStorage,
        _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.apiBaseUrl,
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 20),
                sendTimeout: const Duration(seconds: 20),
                headers: {'Accept': 'application/json'},
                // Let every status through so the mapping below owns the
                // decision, rather than Dio throwing on 4xx/5xx.
                validateStatus: (_) => true,
              ),
            ) {
    _dio.interceptors.add(_AuthInterceptor(_tokenStorage));
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          // Match responses carry phone numbers; keep them out of logcat.
          responseHeader: false,
          logPrint: (o) => debugPrint('[api] $o'),
        ),
      );
    }
  }

  Dio get raw => _dio;

  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send<T>('GET', path, query: query, auth: auth, retryable: true);

  Future<T> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send<T>('POST', path, body: body, query: query, auth: auth);

  Future<T> patch<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
  }) =>
      _send<T>('PATCH', path, body: body, query: query, auth: auth);

  Future<T> delete<T>(String path, {bool auth = true}) =>
      _send<T>('DELETE', path, auth: auth);

  Future<T> _send<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? query,
    bool auth = true,
    bool retryable = false,
  }) async {
    Response<dynamic> response;
    try {
      response = await _request(method, path, body, query, auth);
    } on DioException catch (e) {
      final mapped = _mapTransport(e);
      if (retryable && mapped.kind == ApiErrorKind.network) {
        // One retry, short pause — enough to ride out a flaky emulator
        // network without turning a dead server into a 20-second hang.
        await Future<void>.delayed(const Duration(milliseconds: 600));
        try {
          response = await _request(method, path, body, query, auth);
        } on DioException catch (e2) {
          throw _mapTransport(e2);
        }
      } else {
        throw mapped;
      }
    }

    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) {
      return response.data as T;
    }

    final error = _mapStatus(status, response.data);
    if (error.kind == ApiErrorKind.unauthorized && auth) {
      await onUnauthorized?.call();
    }
    throw error;
  }

  Future<Response<dynamic>> _request(
    String method,
    String path,
    Object? body,
    Map<String, dynamic>? query,
    bool auth,
  ) {
    return _dio.request<dynamic>(
      path,
      data: body,
      queryParameters: query,
      options: Options(
        method: method,
        extra: {_AuthInterceptor.authFlag: auth},
      ),
    );
  }

  ApiException _mapTransport(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.transformTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return const ApiException(
          kind: ApiErrorKind.timeout,
          message: 'The server took too long to respond. Please try again.',
        );
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        final cause = e.error;
        if (cause is SocketException || cause is HandshakeException) {
          return const ApiException(
            kind: ApiErrorKind.network,
            message: 'Cannot reach the server. Check your connection.',
          );
        }
        return ApiException(
          kind: ApiErrorKind.network,
          message: 'Network error: ${e.message ?? 'unknown'}',
        );
      case DioExceptionType.cancel:
        return const ApiException(
          kind: ApiErrorKind.unknown,
          message: 'Request cancelled',
        );
      case DioExceptionType.badCertificate:
      case DioExceptionType.badResponse:
        return _mapStatus(e.response?.statusCode ?? 0, e.response?.data);
    }
  }

  static ApiException _mapStatus(int status, dynamic data) {
    final parsed = _parseDetail(data);
    ApiErrorKind kind;
    switch (status) {
      case 400:
        kind = ApiErrorKind.conflict;
      case 401:
        kind = ApiErrorKind.unauthorized;
      case 403:
        kind = ApiErrorKind.forbidden;
      case 404:
        kind = ApiErrorKind.notFound;
      case 422:
        kind = ApiErrorKind.validation;
      case 429:
        kind = ApiErrorKind.rateLimited;
      default:
        kind = status >= 500 ? ApiErrorKind.server : ApiErrorKind.unknown;
    }
    final fallback = switch (kind) {
      ApiErrorKind.unauthorized => 'Your session has expired. Please log in again.',
      ApiErrorKind.forbidden => 'You are not allowed to do that.',
      ApiErrorKind.notFound => 'Not found.',
      ApiErrorKind.validation => 'Please check the highlighted fields.',
      ApiErrorKind.rateLimited => 'Too many attempts. Please wait a minute and try again.',
      ApiErrorKind.server => 'The server hit an error. Please try again shortly.',
      _ => 'Request failed ($status).',
    };
    return ApiException(
      kind: kind,
      statusCode: status,
      message: parsed.message ?? fallback,
      fieldErrors: parsed.fieldErrors,
    );
  }

  /// Normalises FastAPI's two `detail` shapes.
  static ({String? message, Map<String, String> fieldErrors}) _parseDetail(
    dynamic data,
  ) {
    if (data is! Map) return (message: null, fieldErrors: const {});
    final detail = data['detail'];
    if (detail is String) return (message: detail, fieldErrors: const {});
    if (detail is List) {
      final fields = <String, String>{};
      final messages = <String>[];
      for (final item in detail) {
        if (item is! Map) continue;
        final loc = item['loc'];
        final rawMsg = item['msg']?.toString() ?? 'Invalid value';
        // Pydantic prefixes custom validator messages with "Value error, ".
        final msg = rawMsg.replaceFirst(RegExp(r'^Value error, '), '');
        final field = (loc is List && loc.isNotEmpty) ? loc.last.toString() : null;
        if (field != null && field != 'body') {
          fields.putIfAbsent(field, () => msg);
          messages.add('${_humanise(field)}: $msg');
        } else {
          messages.add(msg);
        }
      }
      return (
        message: messages.isEmpty ? null : messages.join('\n'),
        fieldErrors: fields,
      );
    }
    return (message: null, fieldErrors: const {});
  }

  static String _humanise(String field) {
    final words = field.split('_');
    return words
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }
}

/// Attaches `Authorization: Bearer` from secure storage to every request
/// flagged `auth: true` (the default).
class _AuthInterceptor extends Interceptor {
  static const authFlag = 'auth';
  final TokenStorage _storage;

  _AuthInterceptor(this._storage);

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final needsAuth = options.extra[authFlag] as bool? ?? true;
    if (needsAuth) {
      final session = await _storage.read();
      if (session != null) {
        options.headers['Authorization'] = 'Bearer ${session.token}';
      }
    }
    handler.next(options);
  }
}
