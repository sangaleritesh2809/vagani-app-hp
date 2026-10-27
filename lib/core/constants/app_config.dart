import 'package:flutter/foundation.dart';

/// Application configuration with support for `--dart-define` and environment separation.
class AppConfig {
  AppConfig._();

  /// Environment mode: 'dev' or 'prod'
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: kReleaseMode ? 'prod' : 'dev',
  );

  /// Whether current execution is in production mode
  static bool get isProduction => environment == 'prod' || kReleaseMode;

  /// Whether current execution is in development mode
  static bool get isDevelopment => !isProduction;

  /// Optional base URL passed via `--dart-define=API_BASE_URL=...`
  static const String _rawBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Default production API endpoint (MUST use HTTPS)
  static const String _defaultProdUrl = 'https://api.vargani.app/api/v1';

  /// Default development API endpoint
  static String get _defaultDevUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api/v1';
    }
    return 'http://127.0.0.1:8000/api/v1';
  }

  /// Configured API Base URL with separate Dev and Prod environments
  static String get apiBaseUrl {
    final url = _rawBaseUrl.isNotEmpty
        ? _rawBaseUrl
        : (isProduction ? _defaultProdUrl : _defaultDevUrl);

    // Enforce HTTPS for production
    if (isProduction && !url.toLowerCase().startsWith('https://')) {
      throw StateError(
        'Security Violation: Production API Base URL must use HTTPS. Configured: $url',
      );
    }

    return url;
  }
}
