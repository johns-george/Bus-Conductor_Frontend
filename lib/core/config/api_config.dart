class ApiConfig {
  const ApiConfig._();

  /// Override at build/run time:
  /// `--dart-define=API_BASE_URL=http://10.0.2.2:8000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// When true, the app uses in-memory mock repositories.
  static const bool useMocks = bool.fromEnvironment(
    'USE_MOCKS',
    defaultValue: false,
  );

  /// Google OAuth Web Client ID from Google Cloud Console.
  /// Run with:
  /// `--dart-define=GOOGLE_CLIENT_ID=xxxxx.apps.googleusercontent.com`
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '',
  );
}
