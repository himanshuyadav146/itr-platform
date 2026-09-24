import 'package:flutter/material.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';

class ErrorHandler {
  static void showError(BuildContext context, String message) {
    _showMessage(context, message: message, backgroundColor: Colors.red);
  }

  static void showSuccess(BuildContext context, String message) {
    _showMessage(context, message: message, backgroundColor: Colors.green);
  }

  static void showGenericError(BuildContext context) {
    showError(context, AppStrings.anErrorOccurred);
  }

  /// Uses [SnackBarBehavior.fixed] so messages stay visible above bottom nav.
  static void _showMessage(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) {
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.fixed,
      ),
    );
  }
}
