import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Shared device platform string for API payloads (auth login, FCM register, etc.).
String getDevicePlatform() {
  if (kIsWeb) return 'web';
  if (Platform.isAndroid) return 'android';
  if (Platform.isIOS) return 'ios';
  return 'unknown';
}
