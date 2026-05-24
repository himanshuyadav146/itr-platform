import 'package:intl/intl.dart';
import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/constant/validation_constants.dart';

/// Legacy validator class - kept for backward compatibility
/// New code should use FieldValidators instead
class UtilValidators {
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterField.replaceAll('{field}', fieldName);
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterEmail;
    }
    return ValidationConstants.emailRegex.hasMatch(value.trim())
        ? null
        : AppStrings.invalidEmailFormat;
  }

  static String? validatePAN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterPanNumber;
    }
    return ValidationConstants.panRegex.hasMatch(value.trim())
        ? null
        : AppStrings.invalidPanFormat;
  }

  static String? validateAadhaar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterAadhaarNumber;
    }
    return ValidationConstants.aadhaarRegex.hasMatch(value.trim())
        ? null
        : AppStrings.aadhaarMustBe12Digits;
  }

  static String? validateDOB(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterDateOfBirth;
    }
    try {
      final date = DateFormat(ValidationConstants.dateFormat).parseStrict(value.trim());
      if (date.isAfter(DateTime.now())) {
        return AppStrings.dobCannotBeInFuture;
      }
      return null;
    } catch (_) {
      return AppStrings.invalidDateFormat;
    }
  }

  /// Validates if the provided string is a valid 6-digit Indian PIN code
  static bool isValidIndianPinCode(String pinCode) {
    return RegExp(r'^[1-9][0-9]{5}$').hasMatch(pinCode);
  }
}
