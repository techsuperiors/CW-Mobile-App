import 'package:flutter/foundation.dart';

/// Application configuration
class AppConfig {
  // Base URLs
  static const String devBaseUrl = 'https://dev.collectivwork.com';
  static const String productionBaseUrl = 'https://app.collectivwork.com';

  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'production',
  );

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  static String get baseUrl {
    switch (environment) {
      case 'production':
        return productionBaseUrl;
      default:
        return devBaseUrl;
    }
  }

  static bool get enableLogging => !isProduction || kDebugMode;
  static bool get enableCrashReporting => isProduction;
}

