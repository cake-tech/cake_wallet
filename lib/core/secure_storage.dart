import 'dart:async';
import 'dart:developer';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// For now, we can create a utility function to handle this.
//
// However, we could look into abstracting the entire FlutterSecureStorage package
// so the app doesn't depend on the package directly but an absraction.
// It'll make these kind of modifications to read/write come from a single point.
Future<String?> readSecureStorage(FlutterSecureStorage secureStorage, String key) async {
  const timeoutDurationInSeconds = 3;

  String? result;

  result = await secureStorage.read(key: key);

  if (result == null) {
    Stopwatch stopwatch = Stopwatch();

    stopwatch.start();

    await Timer.periodic(
      Duration(milliseconds: 100),
      (timer) async {
        print(timer.tick);

        result = await secureStorage.read(key: key);

        if (result != null) {
          timer.cancel();
          stopwatch.stop();
          log('We\'ve gotten a valid response from secure storage');
        }

        if (stopwatch.elapsed.inSeconds >= timeoutDurationInSeconds) {
          timer.cancel();
          stopwatch.stop();
          log('Timer cancelled due to timeout.');
        }
      },
    );
  }
  
  return result;
}
