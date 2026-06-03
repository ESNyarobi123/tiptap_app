class AppConfig {
  /// Override at build time, e.g. `--dart-define=API_BASE_URL=https://tiptapafrica.co.za/api`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://tiptapafrica.co.tz/api',
  );

  static const int statsPollIntervalSeconds = 30;
}
