import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qrscan_gs/constant/variables.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  AuthProvider() {
    _loadUserFromPreferences();
  }

  Future<void> login(String username, String password) async {
    if (username.isEmpty || password.isEmpty) {
      _errorMessage = 'Username dan password tidak boleh kosong';
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    var url = Uri.parse('${Variables.baseUrl}/api/login');

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      final responseBody = response.body;

      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);

        if (data != null) {
          if (data['msg'] == 'ok') {
            _user = User(
              idUser: data['id'].toString(),
              name: data['nama'],
              token: data['token'],
            );

            if (_user != null && _user!.token.isNotEmpty) {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setBool('isLoggedIn', true);
              await prefs.setString('username', _user!.name);
              await prefs.setString('id', _user!.idUser);
              await prefs.setString('token', _user!.token);

              print('User logged in: ${_user!.name}');
            } else {
              _errorMessage = 'Login gagal: data pengguna tidak lengkap';
            }
          } else {
            _errorMessage =
                data['message'] ?? 'Terjadi kesalahan yang tidak diketahui';
          }
        } else {
          _errorMessage = 'Data respons null';
        }
      } else if (response.statusCode == 401) {
        _errorMessage = 'Username atau password salah';
      } else {
        _errorMessage =
            'Kesalahan server: ${response.statusCode} - ${responseBody}';
      }
    } catch (e) {
      _errorMessage = 'Gagal login: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn) {
      final idUser = prefs.getString('id');
      final name = prefs.getString('username');
      final token = prefs.getString('token');

      if (idUser != null && name != null && token != null) {
        _user = User(idUser: idUser, name: name, token: token);
        print('User load sesion: ${_user!.name}');
        notifyListeners();
      } else {
        print('Data pengguna tidak lengkap atau null');
      }
    }
  }

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;

    if (isLoggedIn && _user == null) {
      await _loadUserFromPreferences();
    } else {
      _user = null;
      print('User is not logged in');
      notifyListeners();
    }
  }

  void logout() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _user = null;
    notifyListeners();
  }
}
