import 'package:tax_client/core/constant/api_constants.dart';

/// Utility class for building document file URLs.
class DocumentUrlHelper {
  DocumentUrlHelper._();

  /// Returns the full URL to a document file stored on the server.
  ///
  /// Pattern: `{baseUrl}/api/uploads/{panNumber}/{fileName}`
  ///
  /// Example:
  /// ```dart
  /// DocumentUrlHelper.getDocumentUrl(
  ///   panNumber: 'AKJPY7916U',
  ///   fileName: 'form16b_69cd40c0ecf8b5.75789514.jpg',
  /// );
  /// // → https://allindiaitr.in/api/uploads/AKJPY7916U/form16b_69cd40c0ecf8b5.75789514.jpg
  /// ```
  static String getDocumentUrl({
    required String panNumber,
    required String fileName,
  }) {
    return '${ApiConstants.baseUrl}/api/uploads/$panNumber/$fileName';
  }
}
