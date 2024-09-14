// models/participant.dart
class Participant {
  final String
      idScan; // Gunakan String jika Anda ingin menyimpan ID sebagai string
  final String title;

  Participant({required this.idScan, required this.title});

  factory Participant.fromJson(Map<String, dynamic> json) {
    return Participant(
      idScan:
          json['id_scan'].toString(), // Pastikan ini sesuai dengan tipe data
      title: json['title'],
    );
  }
}
