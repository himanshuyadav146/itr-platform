class ApiResponse<T> {
  final String status;
  final T? data;
  final String? message;
  final int? statusCode;

  ApiResponse({
    required this.status,
    this.data,
    this.message,
    this.statusCode,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? value) parser,
  ) {
    try {
      final success = (json['success'] as bool?) ?? (json['status'] == 'success');
      
      // If response has a 'data' key, use it. Otherwise, use the entire response.
      // This handles cases where the API returns data at the root level (e.g., auth endpoints)
      final T? parsedData;
      
      if (json.containsKey('data')) {
        // Response has nested data
        try {
          parsedData = parser(json['data']);
        } catch (e) {
          print('Error parsing nested data: $e');
          print('JSON data key: ${json['data']}');
          rethrow;
        }
      } else if (success) {
        // For successful responses without 'data' key, pass the entire JSON
        try {
          parsedData = parser(json);
        } catch (e) {
          print('Error parsing root-level data: $e');
          print('Full JSON: $json');
          rethrow;
        }
      } else {
        parsedData = null;
      }
      
      return ApiResponse<T>(
        status: success == true ? 'success' : 'error',
        data: parsedData,
        message: json['message'] as String?,
        statusCode: json['code'] as int?,
      );
    } catch (e) {
      print('ApiResponse.fromJson error: $e');
      print('JSON received: $json');
      rethrow;
    }
  }
}
