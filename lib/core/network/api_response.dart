class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final int statusCode;

  const ApiResponse({
    required this.success,
    required this.statusCode,
    this.data,
    this.message,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(dynamic)? fromData,
  ) {
    final rawData = json['data'];
    return ApiResponse(
      success: json['success'] as bool? ?? true,
      statusCode: json['status_code'] as int? ?? 200,
      message: json['chat'] as String?,
      data: (fromData != null && rawData != null) ? fromData(rawData) : null,
    );
  }
}
