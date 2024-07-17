import 'package:fast_scanner/fast_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

var isQrScannerShown = false;

Future<String> presentQRScanner(BuildContext context) async {
  isQrScannerShown = true;
  try {
    final result = await Navigator.of(context).push<Barcode>(
      MaterialPageRoute(
        builder:(context) {
          return BarcodeScannerSimple();
        },
      ),
    );
    isQrScannerShown = false;
    return (result?.rawValue??'').trim();
  } catch (e) {
    isQrScannerShown = false;
    rethrow;
  }
}

// https://github.com/MrCyjaneK/fast_scanner/blob/master/example/lib/barcode_scanner_simple.dart
class BarcodeScannerSimple extends StatefulWidget {
  const BarcodeScannerSimple({super.key});

  @override
  State<BarcodeScannerSimple> createState() => _BarcodeScannerSimpleState();
}

class _BarcodeScannerSimpleState extends State<BarcodeScannerSimple> {
  Barcode? _barcode;
  bool popped = false;
  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
      });
      if (_barcode != null && popped != true) {
        setState(() {
          popped = true;
        });
        SchedulerBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pop(_barcode);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan')),
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
        ],
      ),
    );
  }
}
