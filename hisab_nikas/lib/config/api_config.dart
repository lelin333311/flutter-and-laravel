import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Custom LAN or Production Laravel API Base URL
  static String? _customBaseUrl;

  static void setCustomBaseUrl(String url) {
    _customBaseUrl = url.endsWith('/')
        ? url.substring(0, url.length - 1)
        : url;
  }

  /// Automatic Base URL selection depending on platform & emulator vs desktop/mobile
  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.isNotEmpty) {
      return _customBaseUrl!;
    }

    if (kIsWeb) {
      return 'http://localhost:8000/api/v1';
    }

    if (Platform.isAndroid) {
      // Android Emulator connects to host machine via 10.0.2.2
      return 'http://10.0.2.2:8000/api/v1';
    } else if (Platform.isIOS ||
        Platform.isMacOS ||
        Platform.isWindows ||
        Platform.isLinux) {
      // iOS Simulator / Desktop connects via 127.0.0.1 / localhost
      return 'http://127.0.0.1:8000/api/v1';
    }

    return 'http://127.0.0.1:8000/api/v1';
  }

  /// Mandatory HTTP Headers for Laravel REST API
  static Map<String, String> get headers => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };
}
