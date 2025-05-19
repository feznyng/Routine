import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QrScannerPage extends StatefulWidget {
  final Function(String) onCodeScanned;

  const QrScannerPage({
    super.key,
    required this.onCodeScanned,
  });

  @override
  State<QrScannerPage> createState() => _QrScannerPageState();
}

class _QrScannerPageState extends State<QrScannerPage> {
  late final MobileScannerController controller;
  bool _hasScanned = false;
  bool? _isValidCode;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController(
      facing: CameraFacing.back,
      torchEnabled: false,
      returnImage: false,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan QR Code'),
        actions: [
          // Torch button
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, state, child) {
              return IconButton(
                icon: Icon(
                  state.torchState == TorchState.on
                      ? Icons.flash_on
                      : Icons.flash_off,
                ),
                onPressed: () => controller.toggleTorch(),
              );
            },
          ),
          // Camera switch button
          IconButton(
            icon: const Icon(Icons.flip_camera_ios),
            onPressed: () => controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: (BarcodeCapture capture) {
              if (_hasScanned) return; // Prevent multiple scans
              
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  setState(() {
                    _hasScanned = true;
                    _isValidCode = true;
                  });
                  // Show success feedback for a moment before closing
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) {
                      widget.onCodeScanned(code);
                      Navigator.pop(context);
                    }
                  });
                  break;
                }
              }
            },
          ),
          // Overlay with scanning instructions and feedback
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: Center(
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: _hasScanned
                          ? (_isValidCode == true ? Colors.green : Colors.red)
                          : Colors.white,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_hasScanned)
                          Icon(
                            _isValidCode == true
                                ? Icons.check_circle
                                : Icons.error,
                            color: _isValidCode == true
                                ? Colors.green
                                : Colors.red,
                            size: 48,
                          )
                        else
                          const Text(
                            'Position QR code within the frame',
                            style: TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
