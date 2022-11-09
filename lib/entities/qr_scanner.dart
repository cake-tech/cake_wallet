import 'package:barcode_scan2/barcode_scan2.dart';

var isQrScannerShown = false;

Future<String> presentQRScanner() async {
  isQrScannerShown = true;
  try {
    final result = await BarcodeScanner.scan();
    isQrScannerShown = false;
    return result.rawContent;
  } catch (e) {
    isQrScannerShown = false;
    rethrow;
  }
}
