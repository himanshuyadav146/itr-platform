class BaseResponse<T> {
  final int statusCode;
  final String status;
  final T data;

  BaseResponse({
    required this.statusCode,
    required this.status,
    required this.data,
  });

  factory BaseResponse.fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) create) {
    return BaseResponse(
      statusCode: json['statusCode'],
      status: json['status'],
      data: create(json['data']),
    );
  }
}
