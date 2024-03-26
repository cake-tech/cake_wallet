import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// For now, we can create a utility function to handle this.
//
// However, we could look into abstracting the entire FlutterSecureStorage package
// so the app doesn't depend on the package directly but an absraction.
// It'll make these kind of modifications to read/write come from a single point.

Future<String?> readSecureStorage(FlutterSecureStorage secureStorage, String key) async {
  String? result;
  const maxWait = Duration(seconds: 3);
  const checkInterval = Duration(milliseconds: 200);

  DateTime start = DateTime.now();

  while (result == null && DateTime.now().difference(start) < maxWait) {
    result = await secureStorage.read(key: key);

    if (result != null) {
      break;
    }

    await Future.delayed(checkInterval);
  }

  return result;
}
