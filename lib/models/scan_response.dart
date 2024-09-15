class ScanResponse {
  final String status;
  final String message;

  ScanResponse({
    required this.status,
    required this.message,
  });

  factory ScanResponse.fromJson(Map<String, dynamic> json) {
    return ScanResponse(
      status: json['status'] as String,
      message: json['message'] as String,
    );
  }
}
