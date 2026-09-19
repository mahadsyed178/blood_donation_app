/// One app-level exception for everything that can go wrong talking to the
/// backend, so screens branch on [kind] instead of on Dio internals.
///
/// FastAPI reports errors as `{"detail": "..."}`, and validation failures
/// (422) as `{"detail": [{"loc": [...], "msg": "..."}]}`; [ApiClient] maps
/// both shapes into [message] / [fieldErrors].
enum ApiErrorKind {
  network,
  timeout,
  unauthorized, // 401 — session is gone, caller should log out
  forbidden, // 403 — logged in, but not allowed
  notFound, // 404
  validation, // 422
  rateLimited, // 429
  conflict, // 400 business-rule rejections ("Email already registered")
  server, // 5xx
  unknown,
}

class ApiException implements Exception {
  final ApiErrorKind kind;
  final String message;
  final int? statusCode;

  /// Field-level messages from a 422, keyed by the last `loc` segment
  /// (e.g. `password`, `date_of_birth`).
  final Map<String, String> fieldErrors;

  const ApiException({
    required this.kind,
    required this.message,
    this.statusCode,
    this.fieldErrors = const {},
  });

  bool get isAuthError => kind == ApiErrorKind.unauthorized;

  @override
  String toString() => 'ApiException($kind, $statusCode): $message';
}
