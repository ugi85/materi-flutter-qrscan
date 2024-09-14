import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/scan_response.dart';

class QRScanProvider with ChangeNotifier {
  ScanResponse? _scanResponse;
  bool _isLoading = false;

  ScanResponse? get scanResponse => _scanResponse;
  bool get isLoading => _isLoading;

  Future<void> scanQRCode(String idUser, String idScan, String qrCode) async {
    const url = 'https://iacc.web.id/api/scan';

    _isLoading = true;
    notifyListeners(); // Notifikasi perubahan state

    try {
      // Siapkan request untuk multipart/form-data
      var request = http.MultipartRequest('POST', Uri.parse(url))
        ..fields['id_user'] = idUser.trim()
        ..fields['id_scan'] = idScan.trim()
        ..fields['qrcode'] = qrCode.trim();

      // Memformat QR Code sebelum dikirim
      String formattedQrCode = qrCode.split('-')[0].trim();
      request.fields['qrcode'] = formattedQrCode;

      // Kirim permintaan HTTP POST ke API
      final response = await request.send();

      // Ambil respons dari request
      final responseBody = await response.stream.bytesToString();

      // Jika response berhasil dan body tidak kosong
      if (response.statusCode == 200 && responseBody.isNotEmpty) {
        final data = json.decode(responseBody);

        // Parse JSON ke dalam model ScanResponse
        _scanResponse = ScanResponse.fromJson(data);
      } else {
        // Jika ada masalah dengan response
        print('Failed to scan QR: Empty or invalid response.');
        throw Exception('Failed to scan QR: Empty or invalid response.');
      }
    } catch (e) {
      // Tangkap dan tampilkan error jika terjadi
      print('Error scanning QR: $e');
      throw Exception('Error scanning QR: $e');
    } finally {
      // Reset status loading setelah proses selesai
      _isLoading = false;
      notifyListeners(); // Notifikasi bahwa state telah berubah
    }
  }
}
