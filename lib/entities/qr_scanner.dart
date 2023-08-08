import 'package:cake_wallet/routes.dart';
import 'package:flutter/widgets.dart';

var isQrScannerShown = false;

Future<String> presentQRScanner(BuildContext context) async {
  try {
    return await Navigator.pushNamed(context, Routes.scanQr) as String;
  } catch (e) {
    return "";
  }
}
