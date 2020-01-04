import 'package:barcode_scan/barcode_scan.dart';

var isQrScannerShown = false;

Future<String> presentQRScanner() async {
  isQrScannerShown = true;
  try {
    final result = await BarcodeScanner.scan();
    isQrScannerShown = false;
    return result;
  } catch (e) {
    isQrScannerShown = false;
    throw e;
  }
}
