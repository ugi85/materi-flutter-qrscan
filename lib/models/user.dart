class User {
  final String idUser;
  final String name;
  final String token;

  User({
    required this.idUser,
    required this.name,
    required this.token,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      idUser:
          json['id'].toString(), // Ubah sesuai dengan format ID yang diberikan
      name: json['nama'],
      token: json['token'],
    );
  }
}
