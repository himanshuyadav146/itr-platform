class ValidationConstants {
  // Field Lengths
  static const int phoneNumberLength = 10;
  static const int panNumberLength = 10;
  static const int aadhaarNumberLength = 12;
  
  // Regular Expressions
  static final RegExp emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
  static final RegExp panRegex = RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]$');
  static final RegExp aadhaarRegex = RegExp(r'^\d{12}$');
  
  // Date Format
  static const String dateFormat = 'dd/MM/yyyy';
}

