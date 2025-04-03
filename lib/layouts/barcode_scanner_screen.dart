import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({Key? key}) : super(key: key);

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  MobileScannerController controller = MobileScannerController();
  bool isScanning = true;
  bool isFlashOn = false;
  bool isFrontCamera = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Barcode'),
        actions: [
          // Flash toggle button
          IconButton(
            icon: Icon(isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () async {
              setState(() {
                isFlashOn = !isFlashOn;
              });
              await controller.toggleTorch();
            },
          ),
          // Camera switch button
          IconButton(
            icon: Icon(isFrontCamera ? Icons.camera_front : Icons.camera_rear),
            onPressed: () async {
              setState(() {
                isFrontCamera = !isFrontCamera;
              });
              await controller.switchCamera();
            },
          ),
        ],
      ),
      body: MobileScanner(
        controller: controller,
        onDetect: (BarcodeCapture capture) {
          if (!isScanning) return;
          
          final List<Barcode> barcodes = capture.barcodes;
          if (barcodes.isNotEmpty) {
            setState(() {
              isScanning = false;
            });
            Navigator.of(context).pop(barcodes.first.rawValue);
          }
        },
      ),
    );
  }
}