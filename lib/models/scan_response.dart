class ScanResponse {
  final String msg;
  final String pesan;

  ScanResponse({
    required this.msg,
    required this.pesan,
  });

  factory ScanResponse.fromJson(Map<String, dynamic> json) {
    return ScanResponse(
      msg: json['msg'] as String,
      pesan: json['pesan'] as String,
    );
  }
}
