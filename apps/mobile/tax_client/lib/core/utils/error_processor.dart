import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class ErrorProcessor {
  /// Logs a non-fatal error to Firebase Crashlytics.
  /// Use this inside try-catch blocks to record caught exceptions.
  static void logError(dynamic exception, StackTrace? stack, {String? reason}) {
    if (kDebugMode) {
      print('Error Caught: $exception');
      if (stack != null) print(stack);
    }
    
    FirebaseCrashlytics.instance.recordError(
      exception,
      stack,
      reason: reason,
      fatal: false, // Caught exceptions are generally non-fatal
    );
  }

  /// Sets custom keys for additional context in Crashlytics reports.
  static void setCustomKey(String key, dynamic value) {
    FirebaseCrashlytics.instance.setCustomKey(key, value);
  }

  /// Sets the user ID for better tracking in Crashlytics.
  static void setUserId(String userId) {
    FirebaseCrashlytics.instance.setUserIdentifier(userId);
  }
}
