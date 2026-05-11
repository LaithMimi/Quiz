import 'package:flutter/foundation.dart';

class ApiConfig {
  ApiConfig._();

  static const String localhost = '185.140.181.252';
  static const int port = 5099;

  static String get baseUrl {
    if (kIsWeb) {
      return 'https://footboard-unexposed-parish.ngrok-free.dev';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        return 'http://$localhost:$port';
      default:
        return 'http://$localhost:$port';
    }
  }

  static String get signUpUrl => '$baseUrl/api/Auth/signup';
  static String get loginUrl  => '$baseUrl/api/Auth/login';
}