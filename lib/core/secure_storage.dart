import 'dart:async';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// For now, we can create a utility function to handle this.
//
// However, we could look into abstracting the entire FlutterSecureStorage package
// so the app doesn't depend on the package directly but an absraction.
// It'll make these kind of modifications to read/write come from a single point.

Future<String?> readSecureStorage(FlutterSecureStorage secureStorage, String key) async {
  const timeoutDurationInSeconds = 3;

  Completer<String?> completer = Completer<String?>();
  Stopwatch stopwatch = Stopwatch();
  stopwatch.start();
  bool isRetrying = false;
  late Timer retryTimer;

  void retry() {
    if (!isRetrying) {
      isRetrying = true;
      retryTimer = Timer.periodic(
        Duration(milliseconds: 100),
        (timer) async {
          String? result = await secureStorage.read(key: key);

          if (result != null) {
            timer.cancel();
            stopwatch.stop();
            print('We\'ve gotten a valid response from secure storage');
            completer.complete(result);
            isRetrying = false;
          }

          if (stopwatch.elapsed.inSeconds >= timeoutDurationInSeconds) {
            timer.cancel();
            stopwatch.stop();
            print('Timer cancelled due to timeout.');
            completer.complete(null);
            isRetrying = false;
          }
        },
      );
    }
  }

  retry(); // Start the first attempt

  return completer.future;
}
