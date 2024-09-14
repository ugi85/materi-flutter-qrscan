import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/variables.dart';
import '../models/participant.dart';

class ParticipantProvider with ChangeNotifier {
  List<Participant> _participants = [];
  String? _selectedParticipant;

  List<Participant> get participants => _participants;
  String? get selectedParticipant => _selectedParticipant;

  Future<void> fetchParticipants() async {
    final url =
        Uri.parse('${Variables.baseUrl}/api/list_scan'); // Sesuaikan URL

    try {
      // Ambil id_user dari SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? idUser = prefs.getString('id');
      String? token = prefs.getString('token');

      if (idUser == null) {
        throw Exception('ID User tidak ditemukan');
      }

      // Membuat permintaan POST untuk mendapatkan data list_scan
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        // Decode respons menjadi string
        final responseBody = response.body;

        // Decode JSON dari string
        List<dynamic> data = json.decode(responseBody);

        print('Data list_scan diterima: $data'); // Log untuk data list_scan

        // Ubah data list menjadi objek Participant
        _participants = data.map((item) => Participant.fromJson(item)).toList();

        // Pilih peserta pertama jika list tidak kosong
        if (_participants.isNotEmpty) {
          _selectedParticipant = _participants[0].idScan;
          print(
              'ID peserta default yang dipilih: $_selectedParticipant'); // Log untuk ID default
        }

        notifyListeners(); // Notifikasi perubahan state
      } else {
        throw Exception('Gagal memuat peserta: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching participants: $e');
      throw Exception('Error fetching participants: $e');
    }
  }

  void selectParticipant(String? participantId) {
    _selectedParticipant = participantId;
    notifyListeners(); // Notifikasi perubahan state
  }
}
