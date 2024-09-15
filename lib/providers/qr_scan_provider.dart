import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constant/variables.dart';
import '../models/scan_response.dart';

class QRScanProvider with ChangeNotifier {
  ScanResponse? _scanResponse;
  bool _isLoading = false;

  ScanResponse? get scanResponse => _scanResponse;
  bool get isLoading => _isLoading;

  Future<void> scanQRCode(String idScan, String qrCode) async {
    final url = Uri.parse('${Variables.baseUrl}/api/scan');

    _isLoading = true;
    notifyListeners(); // Notifikasi perubahan state

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('token');

      if (token == null) {
        throw Exception('Token tidak ditemukan, silahkan login kembali');
      }
      print('Token ada: $token');

      // Siapkan data yang akan dikirim dalam bentuk JSON
      Map<String, dynamic> requestBody = {
        'id_scan': idScan.trim(),
        'qr_content': qrCode.trim(),
      };

      // Kirim permintaan HTTP POST ke API dengan content-type application/json
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        if (response.body.isNotEmpty) {
          final data = json.decode(response.body);

          // Log respons untuk debugging
          print('Respons dari API: $data');

          // Parse JSON ke dalam model ScanResponse
          _scanResponse = ScanResponse.fromJson(data);

          // Log hasil parsing
          print('Status: ${_scanResponse?.status}');
          print('Pesan: ${_scanResponse?.message}');
        } else {
          print('Respons dari API kosong.');
          throw Exception('Failed to scan QR: Empty response.');
        }
      } else {
        // Log status kode dan body jika gagal
        print('Status kode tidak 200: ${response.statusCode}');
        print('Respons dari API (error): ${response.body}');
        throw Exception('Failed to scan QR: Invalid response.');
      }
    } catch (e) {
      print('Error scanning QR: $e');
      throw Exception('Error scanning QR: $e');
    } finally {
      _isLoading = false;
      notifyListeners(); // Notifikasi bahwa state telah berubah
    }
  }
}
