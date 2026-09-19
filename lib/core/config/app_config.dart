/// Build-time configuration, supplied with `--dart-define` (or
/// `--dart-define-from-file=config/dev.json`). See `.env.example`.
///
/// `10.0.2.2` is the Android emulator's alias for the host machine's
/// loopback, which is where the FastAPI server listens during development.
class AppConfig {
  AppConfig._();

  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8080',
  );

  /// `ws://` twin of [apiBaseUrl], for the chat socket.
  static String get wsBaseUrl =>
      apiBaseUrl.replaceFirst(RegExp(r'^http'), 'ws');

  static const String environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static bool get isDev => environment == 'dev';
}
