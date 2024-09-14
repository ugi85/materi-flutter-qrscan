import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/auth_provider.dart';
import '../providers/participant_provider.dart';
import '../providers/qr_scan_provider.dart';
import 'QRView.dart';
import 'login.dart';

class HomePage extends StatefulWidget {
  final String? qrData;
  final String? userName;

  const HomePage({Key? key, this.qrData, this.userName}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _qrResult;

  @override
  @override
  void initState() {
    super.initState();
    Provider.of<ParticipantProvider>(context, listen: false)
        .fetchParticipants()
        .then((_) {
      // Setelah peserta di-fetch, tetapkan ID default jika ada
      final participantProvider =
          Provider.of<ParticipantProvider>(context, listen: false);
      if (participantProvider.participants.isNotEmpty) {
        participantProvider
            .selectParticipant(participantProvider.participants[0].idScan);
      }
    });
  }

  void _reset() {
    setState(() {
      _qrResult = null; // Mengatur hasil QR ke null
    });

    // Mengatur dropdown ke nilai default
    final participantProvider =
        Provider.of<ParticipantProvider>(context, listen: false);
    participantProvider
        .selectParticipant(null); // Mengatur peserta yang dipilih ke null

    // Jika Anda ingin mengatur ulang peserta ke peserta pertama (jika ada)
    if (participantProvider.participants.isNotEmpty) {
      participantProvider
          .selectParticipant(participantProvider.participants[0].idScan);
    }
  }

  void _onDropdownChanged(String? newValue) {
    final participantProvider =
        Provider.of<ParticipantProvider>(context, listen: false);
    participantProvider.selectParticipant(newValue);
  }

  void _scanQR() async {
    // Ambil id_user dan id_scan dari provider atau state yang sesuai
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String idUser = authProvider.user?.idUser ?? '';
    String idScan = Provider.of<ParticipantProvider>(context, listen: false)
            .selectedParticipant ??
        '';
    print('idUser: $idUser, idScan: $idScan'); // Tambahkan log

    // Validasi data
    if (idUser.isEmpty || idScan.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Data user atau id scan tidak ditemukan'),
        ),
      );
      return;
    }

    // Pindai QR code
    String? qrCode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => QRViewPage()),
    );

    if (qrCode != null) {
      setState(() {
        _qrResult = qrCode;
      });

      // Panggil fungsi scanQRCode dari QRScanProvider
      final qrScanProvider =
          Provider.of<QRScanProvider>(context, listen: false);
      await qrScanProvider.scanQRCode(idUser, idScan, qrCode);

      // Update _qrResult dengan pesan dari scanResponse
      setState(() {
        _qrResult = qrScanProvider.scanResponse?.pesan ?? '';
      });
    }
  }

  final String baseUrl = 'https://iacc.web.id/api/report';

  Future<void> _launchDownload(String userId) async {
    final String downloadUrl = '$baseUrl/$userId';
    final Uri url = Uri.parse(downloadUrl);

    if (!await launchUrl(
      url,
      mode: LaunchMode.externalApplication,
    )) {
      throw 'Could not launch $downloadUrl';
    }
  }

  void _logout() async {
    // Ambil instance AuthProvider
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Panggil fungsi logout dari AuthProvider
    authProvider.logout();

    // Navigasi ke halaman login
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Akses AuthProvider untuk mendapatkan userId
    final authProvider = Provider.of<AuthProvider>(context);
    final userId =
        authProvider.user?.idUser; // Mengambil userId dari AuthProvider

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello, ${widget.userName} !',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.lock_open),
            onPressed: _logout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          // padding: const EdgeInsets.all(16.0),
          padding: EdgeInsets.all(
              MediaQuery.of(context).size.width * 0.05), // Responsif
          child: Consumer<ParticipantProvider>(
            builder: (context, participantProvider, child) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(children: [
                      const Text(''),
                      Image.asset(
                        'assets/images/logo2.png',
                        height: MediaQuery.of(context).size.height *
                            0.2, // Responsif
                        width: MediaQuery.of(context).size.width *
                            0.8, // Responsif
                        // height: 150,
                        // width: 380,
                      ),
                    ]),
                  ),
                  if (_qrResult != null)
                    Padding(
                      padding: EdgeInsets.symmetric(
                          vertical: MediaQuery.of(context).size.height *
                              0.02), // Responsif
                      child: Center(
                        child: Text(
                          '$_qrResult',
                          textAlign: TextAlign.center, // Teks diatur ke tengah
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Center(
                    child: SizedBox(
                      width:
                          MediaQuery.of(context).size.width * 0.9, // Responsif
                      child: DropdownButtonFormField<String>(
                        value: participantProvider.selectedParticipant,
                        onChanged: _onDropdownChanged,
                        items:
                            participantProvider.participants.map((participant) {
                          return DropdownMenuItem<String>(
                            value: participant.idScan,
                            child: Text(participant.title),
                          );
                        }).toList(),
                        decoration: InputDecoration(
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width *
                                  0.03, // Responsif
                              vertical: MediaQuery.of(context).size.height *
                                  0.02), // Responsif
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _scanQR,
                          child: const Text('SCAN QR',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 25),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _reset,
                          child: const Text('RESET',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                vertical: 16, horizontal: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: ElevatedButton(
                      onPressed: () {
                        if (userId != null && userId.isNotEmpty) {
                          _launchDownload(userId);
                        } else {
                          // Tampilkan Snackbar jika userId tidak ditemukan
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                  'User ID tidak ditemukan, silakan login ulang.'),
                              action: SnackBarAction(
                                label: 'Login',
                                onPressed: () {
                                  // Arahkan pengguna ke halaman login
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => const LoginPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Download XLS',
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
