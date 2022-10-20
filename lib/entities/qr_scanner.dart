// import 'package:barcode_scan/barcode_scan.dart';

var isQrScannerShown = false;

Future<String> presentQRScanner() async {
  isQrScannerShown = true;
  // FIX-ME: BarcodeScanner
  throw Exception('Unimplemented');
  // try {
  //   final result = await BarcodeScanner.scan();
  //   isQrScannerShown = false;
  //   return result.rawContent;
  // } catch (e) {
  //   isQrScannerShown = false;
  //   rethrow;
  // }
}
