import 'package:tax_client/core/config/strings/app_strings.dart';
import 'package:tax_client/core/constant/validation_constants.dart';

class FieldValidators {
  static String? validateFirstName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterFirstName;
    }
    return null;
  }
  
  static String? validateLastName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterLastName;
    }
    return null;
  }
  
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterPhoneNumber;
    }
    if (value.trim().length != ValidationConstants.phoneNumberLength) {
      return AppStrings.phoneNumberMustBe10Digits;
    }
    return null;
  }
  
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterEmail;
    }
    if (!ValidationConstants.emailRegex.hasMatch(value.trim())) {
      return AppStrings.pleaseEnterValidEmail;
    }
    return null;
  }
  
  static String? validatePAN(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterPanNumber;
    }
    if (value.trim().length != ValidationConstants.panNumberLength) {
      return AppStrings.panNumberMustBe10Characters;
    }
    return null;
  }
  
  static String? validateAadhaar(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterAadhaarNumber;
    }
    if (value.trim().length != ValidationConstants.aadhaarNumberLength) {
      return AppStrings.aadhaarNumberMustBe12Digits;
    }
    return null;
  }
  
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterAddress;
    }
    return null;
  }
  
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return AppStrings.pleaseEnterField.replaceAll('{field}', fieldName);
    }
    return null;
  }
}

