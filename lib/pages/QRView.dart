import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import '../providers/qr_scan_provider.dart';

class QRViewPage extends StatefulWidget {
  @override
  _QRViewPageState createState() => _QRViewPageState();
}

class _QRViewPageState extends State<QRViewPage>
    with SingleTickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String? qrText;
  bool isFlashOn = false;
  late AnimationController _animationController;

  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    controller?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double scanArea = 350.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code Scanner'),
        actions: [
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_off : Icons.flash_on),
            onPressed: () {
              setState(() {
                isFlashOn = !isFlashOn;
              });
              controller?.toggleFlash();
            },
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.red,
              borderRadius: 5,
              borderLength: 30,
              borderWidth: 2,
              cutOutSize: scanArea,
            ),
          ),
          Positioned.fill(
            child: CustomPaint(
              painter: _ScanLinePainter(
                animation: _animationController,
                cutOutSize: scanArea,
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                qrText ?? 'Scan a code',
                style: const TextStyle(fontSize: 18, color: Colors.grey),
              ),
            ),
          ),
          if (Provider.of<QRScanProvider>(context).isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        qrText = scanData.code;
      });
      controller.dispose(); // Berhenti setelah scan
      Navigator.pop(context, scanData.code); // Kembali ke HomePage dengan data
    });
  }
}

class _ScanLinePainter extends CustomPainter {
  final Animation<double> animation;
  final double cutOutSize;

  _ScanLinePainter({required this.animation, required this.cutOutSize})
      : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red
      ..strokeWidth = 1.0;

    final topOffset = (size.height - cutOutSize) / 2;
    final y = topOffset + cutOutSize * animation.value;

    canvas.drawLine(
      Offset((size.width - cutOutSize) / 2, y),
      Offset((size.width + cutOutSize) / 2, y),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
